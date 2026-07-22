import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/messaging_time_formatter.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/usecases/create_or_open_conversation_usecase.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/presentation/features/student/cubit/student_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/messaging_shimmer.dart';
import 'package:wowcare/presentation/features/communication/cubit/conversation_list_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/conversation_list_state.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/screens/conversation_thread_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/conversation_tile.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/filter_indicator.dart';
import 'package:wowcare/shared/common/views/filter_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/parent_direct_messaging_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import '../../../../../../../shared/common/widgets/custom_clear_all_chip.dart';
import '../../../../../../../shared/common/widgets/custom_toggle.dart';
import '../../../../../../../shared/common/widgets/gradient_add_button.dart';
import '../../../../../classroom/cubit/classroom_cubit.dart';
import '../../../../../staff/cubit/staff_cubit.dart';
import '../../../../bulk_messaging/view/staff_or_student_selection_bulk_messaging.dart';

/// Standalone full-page Admin Chat screen with GlobalScaffold.
///
/// Shows ADMIN_CHAT conversations with a custom header, unread filter pill,
/// clear-filters button, search, and new-message compose sheet.
class AdminChatHostScreen extends StatefulWidget {
  const AdminChatHostScreen({super.key});

  static const String routeName = '/admin-chat';

  @override
  State<AdminChatHostScreen> createState() => _AdminChatHostScreenState();
}

class _AdminChatHostScreenState extends State<AdminChatHostScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showUnreadOnly = false;
  late final ConversationListCubit _cubit;

  // Student-oriented filters (Classroom + Tag + Status), matched client-side
  // against each conversation's student (admin chats are student-scoped).
  Set<String> _selectedClassrooms = {};
  Set<String> _selectedTags = {};
  String? _selectedStatus;

  /// Backs the "Start new chat" section shown when searching matches a
  /// student who has no admin-chat conversation yet.
  late final StudentCubit _studentCubit;

  /// Student codes currently being created/opened — guards a double-tap
  /// from firing two create requests while the first is still in flight.
  final Set<String> _startingConversationWith = {};

  @override
  void initState() {
    super.initState();
    _cubit = ConversationListCubit(
      conversationType: ConversationType.adminChat,
      watchConversationsUseCase: serviceLocator(),
      getConversationsUseCase: serviceLocator(),
      getCachedConversationsUseCase: serviceLocator(),
      conversationRepository: serviceLocator(),
      storageService: serviceLocator(),
    );
    _studentCubit = serviceLocator<StudentCubit>()..loadInitial();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    unawaited(_cubit.startWatching());
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    unawaited(_studentCubit.close());
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    // Firestore stream auto-loads; no manual pagination needed.
  }

  void _onSearchChanged() => setState(() {});

  bool get _hasStudentFilters =>
      _selectedClassrooms.isNotEmpty ||
      _selectedTags.isNotEmpty ||
      _selectedStatus != null;

  bool get _hasActiveFilters =>
      _showUnreadOnly ||
      _searchController.text.trim().isNotEmpty ||
      _hasStudentFilters;

  /// The display classroom label a student is filtered by (name preferred).
  String _classroomLabel(Student s) =>
      (s.primaryClassroomName != null && s.primaryClassroomName!.trim().isNotEmpty)
          ? s.primaryClassroomName!.trim()
          : s.classroom.trim();

  /// Distinct classroom labels across the loaded students, for the filter sheet.
  List<String> _classroomOptions() {
    final set = <String>{};
    for (final s in _studentCubit.state.items) {
      final label = _classroomLabel(s);
      if (label.isNotEmpty) set.add(label);
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Distinct tag names across the loaded students, for the filter sheet.
  List<String> _tagOptions() {
    final set = <String>{};
    for (final s in _studentCubit.state.items) {
      set.addAll(s.tags.where((t) => t.trim().isNotEmpty));
    }
    final list = set.toList()..sort();
    return list;
  }

  bool _matchesStudentFilters(ConversationEntity c, Map<String, Student> byCode) {
    final code = c.studentCode;
    // Filtering is active but this conversation's student isn't loaded/known —
    // exclude it (we can't confirm a match).
    final s = (code == null || code.isEmpty) ? null : byCode[code];
    if (s == null) return false;
    if (_selectedStatus != null &&
        s.status.toUpperCase() != _selectedStatus!.toUpperCase()) {
      return false;
    }
    if (_selectedClassrooms.isNotEmpty) {
      final label = _classroomLabel(s).toLowerCase();
      if (!_selectedClassrooms.any((sel) => sel.toLowerCase() == label)) {
        return false;
      }
    }
    if (_selectedTags.isNotEmpty) {
      if (!s.tags.any((t) => _selectedTags.contains(t))) return false;
    }
    return true;
  }

  List<ConversationEntity> _filtered(List<ConversationEntity> all) {
    final q = _searchController.text.trim().toLowerCase();
    final hasStudentFilters = _hasStudentFilters;
    final Map<String, Student> byCode = hasStudentFilters
        ? {for (final s in _studentCubit.state.items) s.code: s}
        : const {};
    return all.where((c) {
      if (_showUnreadOnly && c.unreadCount == 0) return false;
      if (q.isNotEmpty && !c.title.toLowerCase().contains(q)) return false;
      if (hasStudentFilters && !_matchesStudentFilters(c, byCode)) return false;
      return true;
    }).toList();
  }

  /// Opens the same full-screen Filter UI used by Parent Messaging (Room Chat)
  /// — Classroom + Status + Tags — instead of a bottom sheet, so both screens
  /// share one filter experience.
  void _showFilterSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FilterScreen(
          sections: [
            FilerSection(
              label: 'Classroom',
              hintText: 'Select classroom',
              items: _classroomOptions(),
              initialSelected: _selectedClassrooms.toList(),
              isMultiSelectDropDown: true,
            ),
            FilerSection(
              label: 'Status',
              hintText: 'Select status',
              items: const ['Active', 'Upcoming', 'Inactive'],
              initialSelected:
                  _selectedStatus != null ? [_selectedStatus!] : const [],
              isSingleSelect: true,
            ),
            FilerSection(
              label: 'Tags',
              hintText: 'Select tags',
              items: _tagOptions(),
              initialSelected: _selectedTags.toList(),
              isMultiSelectDropDown: true,
            ),
          ],
          onApply: (filters) {
            if (!mounted) return;
            setState(() {
              _selectedClassrooms = (filters['Classroom'] ?? const []).toSet();
              _selectedTags = (filters['Tags'] ?? const []).toSet();
              final status = filters['Status'] ?? const [];
              _selectedStatus = status.isEmpty ? null : status.first;
            });
          },
        ),
      ),
    );
  }

  void _openThread(ConversationEntity conversation) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ConversationThreadScreen(conversation: conversation),
      ),
    );
  }

  /// Students matching the search query who don't already have an
  /// admin-chat conversation — searching for someone with no chat yet
  /// should surface them here instead of just coming up empty.
  List<Student> _filteredStudentContacts(
    List<Student> students,
    List<ConversationEntity> allConversations,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    final existingStudentCodes = allConversations
        .map((c) => c.studentCode)
        .whereType<String>()
        .toSet();
    return students.where((s) {
      if (existingStudentCodes.contains(s.code)) return false;
      final name = '${s.firstName} ${s.lastName}'.trim().toLowerCase();
      return name.contains(query);
    }).toList();
  }

  /// Creates (or finds) an admin-chat conversation with [student] and opens
  /// it directly — runs as a background request with a "Creating…" notice,
  /// then either a success notice (and opens the thread) or a failure
  /// notice, matching the same pattern used for Staff/Parent messaging.
  Future<void> _startConversationWithStudent(Student student) async {
    final code = student.code;
    if (_startingConversationWith.contains(code)) return;
    _startingConversationWith.add(code);

    final name = '${student.firstName} ${student.lastName}'.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Creating conversation with $name…'),
        duration: const Duration(seconds: 2),
      ),
    );

    final storage = serviceLocator<StorageService>();
    final adminCode = await storage.getString(StorageKeys.userCode) ?? '';

    final result = await serviceLocator<CreateOrOpenConversationUseCase>()(
      type: ConversationType.adminChat,
      studentCode: code,
      participantCodes: adminCode.isNotEmpty ? [adminCode] : null,
      title: name,
      avatarUrl: student.profileImage ?? '',
    );

    _startingConversationWith.remove(code);
    if (!mounted) return;
    final conversation = result.fold((_) => null, (c) => c);
    if (conversation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start a conversation with $name')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chat with $name created successfully')),
    );
    unawaited(_cubit.refresh());
    _openThread(conversation);
  }

  Future<void> _showGroupChatSheet() async {
    // A parent/guardian starting an Admin Chat is choosing which admin or
    // director to talk to — not a student, and the Classroom/Status/Tags
    // filters built for staff picking a student don't apply here.
    final isGuardian = context.read<RoleCubit>().isParent;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => serviceLocator<StaffCubit>()),
            BlocProvider(create: (_) => serviceLocator<ClassroomCubit>()),
            BlocProvider(create: (_) => serviceLocator<StudentCubit>()),
          ],
          child: isGuardian
              ? const StaffOrStudentSelectionBulkMessaging(
                  isStaffSelection: true,
                  conversationType: 'ADMIN_CHAT',
                  restrictToDesignationCodes: ['ADMIN', 'DIRECTOR'],
                  hideFilters: true,
                )
              : const StaffOrStudentSelectionBulkMessaging(
                  isStaffSelection: false,
                  conversationType: 'ADMIN_CHAT',
                ),
        ),
      ),
    );
    if (mounted) unawaited(_cubit.refresh());
  }

  @override
  Widget build(BuildContext context) {
    // Parents see the Admin Chat as a direct per-child thread (draft + create-on-first-send),
    // mirroring their Room Chat — admins resolve server-side from the child's studentCode. Admins
    // and directors get the conversation list below.
    if (context.watch<RoleCubit>().isParent) {
      return const GlobalScaffold(
        hasBackButton: false,
        bodyPadding: EdgeInsets.fromLTRB(12, 8, 12, 8),
        body: ParentDirectMessagingScreen(
          conversationType: ConversationType.adminChat,
          notCreatedLabel: 'Start Conversation with Admin',
        ),
      );
    }
    return GlobalScaffold(
      hasBackButton: false,
      bodyPadding: EdgeInsets.zero,
      body: BlocProvider<ConversationListCubit>.value(
        value: _cubit,
        child: BlocProvider<StudentCubit>.value(
          value: _studentCubit,
          child: BlocBuilder<StudentCubit, StudentState>(
            builder: (context, studentState) {
              return BlocBuilder<ConversationListCubit, ConversationListState>(
                builder: (context, state) {
                  final totalUnread = state.conversations.fold<int>(
                    0,
                    (sum, c) => sum + c.unreadCount,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Page header ───────────────────────────────────────────
                      _PageHeader(
                        totalUnread: totalUnread,
                        onComposeTap: _showGroupChatSheet,
                        onFabTap: _showGroupChatSheet,
                      ),

                      // ── Search + filter bar ───────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: const Color(0x33B1AFE9),
                                ),
                                child: CustomSearchBar(
                                  controller: _searchController,
                                  hintText: 'Search conversations…',
                                  searchBarColor: const WidgetStatePropertyAll(
                                    Colors.transparent,
                                  ),
                                  borderColor: Colors.transparent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Non-parents only (the parent branch returns early above).
                            FilterIndicator(
                              hasActiveFilters: _hasStudentFilters,
                              filterCount: (_selectedClassrooms.isNotEmpty ? 1 : 0) +
                                  (_selectedTags.isNotEmpty ? 1 : 0) +
                                  (_selectedStatus != null ? 1 : 0),
                              onTap: _showFilterSheet,
                            ),
                          ],
                        ),
                      ),

                      // ── Unread toggle + clear chip ────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          children: [
                            CustomToggle(
                              label: 'Show Only Unread',
                              isToggled: _showUnreadOnly,
                              onToggle: (v) =>
                                  setState(() => _showUnreadOnly = v),
                              labelOnLeftSide: true,
                            ),
                            const Spacer(),
                            CustomClearAllChip(
                              label: 'Clear All',
                              onTap: () => setState(() {
                                _showUnreadOnly = false;
                                _searchController.clear();
                                _selectedClassrooms = {};
                                _selectedTags = {};
                                _selectedStatus = null;
                              }),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 4),

                      // ── Error banner ──────────────────────────────────────────
                      if (state.errorMessage != null && state.hasConversations)
                        _ErrorBanner(message: state.errorMessage!),

                      // ── List / loading / empty ────────────────────────────────
                      Expanded(
                        child: RefreshIndicator(
                          color: AppColors.primaryColor,
                          onRefresh: () =>
                              context.read<ConversationListCubit>().refresh(),
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            // Every conditional sliver below carries a
                            // stable Key — without one, Flutter matches
                            // old/new children in this list by position,
                            // and as the list's shape changes (loading →
                            // loaded, search results appearing/
                            // disappearing) a gesture detector can get
                            // reparented onto the wrong child mid-rebuild,
                            // corrupting the element tree.
                            slivers: [
                              if (state.isLoading && !state.hasConversations)
                                const MessagingShimmer(
                                  key: ValueKey('loading_shimmer'),
                                ),

                              if (!state.isLoading &&
                                  state.errorMessage != null &&
                                  !state.hasConversations)
                                SliverFillRemaining(
                                  key: const ValueKey('error_state'),
                                  child: _FullScreenError(
                                    message: state.errorMessage!,
                                    onRetry: () => context
                                        .read<ConversationListCubit>()
                                        .startWatching(),
                                  ),
                                ),

                              if (state.hasConversations || state.isFromCache)
                                KeyedSubtree(
                                  key: const ValueKey('conversations_list'),
                                  child: _buildList(context, state),
                                ),

                              if (!state.isLoading &&
                                  !state.hasConversations &&
                                  state.errorMessage == null)
                                SliverFillRemaining(
                                  key: const ValueKey('empty_state'),
                                  child: _EmptyState(
                                    hasFilters: _hasActiveFilters,
                                  ),
                                ),

                              if (state.isLoading && state.hasConversations)
                                const SliverToBoxAdapter(
                                  key: ValueKey('loading_more_indicator'),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              if (_searchController.text.trim().isNotEmpty)
                                ..._buildStartNewChatSlivers(
                                  studentState,
                                  state.conversations,
                                ),

                              const SliverToBoxAdapter(
                                key: ValueKey('bottom_spacer'),
                                child: SizedBox(height: 80),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  /// "START NEW CHAT" header + rows for students matching the current
  /// search who don't already have an admin-chat conversation.
  List<Widget> _buildStartNewChatSlivers(
    StudentState studentState,
    List<ConversationEntity> allConversations,
  ) {
    final contacts = _filteredStudentContacts(
      studentState.items,
      allConversations,
    );
    if (contacts.isEmpty) return const [];
    return [
      SliverToBoxAdapter(
        key: const ValueKey('start_new_chat_header'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(
            'START NEW CHAT (${contacts.length})',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: Color(0xFF9B96B0),
            ),
          ),
        ),
      ),
      SliverList(
        key: const ValueKey('start_new_chat_list'),
        delegate: SliverChildBuilderDelegate((context, index) {
          final student = contacts[index];
          final name = '${student.firstName} ${student.lastName}'.trim();
          return InkWell(
            key: ValueKey('student_contact_${student.code}'),
            onTap: () => _startConversationWithStudent(student),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F3F5), width: 1),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  DocumentImageWidget(
                    fileUuid: '',
                    imageUrl: student.profileImage,
                    studentCode: student.code,
                    name: name,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff573353),
                          ),
                        ),
                        if ((student.primaryClassroomName ?? '').isNotEmpty)
                          Text(
                            student.primaryClassroomName!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF636E72),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Color(0xFF6C5CE7),
                  ),
                ],
              ),
            ),
          );
        }, childCount: contacts.length),
      ),
    ];
  }

  Widget _buildList(BuildContext context, ConversationListState state) {
    final filtered = _filtered(state.conversations);

    if (filtered.isEmpty) {
      return SliverFillRemaining(
        key: const ValueKey('no_results'),
        child: Center(
          child: Text(
            _showUnreadOnly
                ? 'No unread conversations'
                : 'No results for "${_searchController.text}"',
            style: const TextStyle(color: Color(0xFF636E72)),
          ),
        ),
      );
    }

    return SliverList(
      key: const ValueKey('conversation_tiles'),
      delegate: SliverChildBuilderDelegate(
        (context, index) => ConversationListTile(
          key: ValueKey('conversation_${filtered[index].code}'),
          conversationCode: filtered[index].code,
          contentBuilder: (context, conversation) => _ConversationTileContent(
            conversation: conversation,
            onTap: () => _openThread(conversation),
          ),
        ),
        childCount: filtered.length,
      ),
    );
  }
}

// ─── Page header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.totalUnread,
    required this.onComposeTap,
    required this.onFabTap,
  });

  final int totalUnread;
  final VoidCallback onComposeTap;
  final VoidCallback onFabTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F3F5), width: 1)),
      ),
      child: Row(
        children: [
          // Title + unread badge
          Expanded(
            child: Row(
              children: [
                CustomTextWidget(
                  text: 'Admin Chat',
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  fontColor: AppColors.primaryColor,
                ),
                if (totalUnread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0984E3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      totalUnread > 99 ? '99+' : '$totalUnread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Compose FAB-style button in header row
          GradientAddButton(onTap: onFabTap),
        ],
      ),
    );
  }
}

// ─── Conversation tile ────────────────────────────────────────────────────────

class _ConversationTileContent extends StatelessWidget {
  const _ConversationTileContent({
    required this.conversation,
    required this.onTap,
  });

  final ConversationEntity conversation;
  final VoidCallback onTap;

  /// The conversation-list summary only carries a plain-text
  /// `lastMessagePreview` — empty for an attachment-only last message, with
  /// no field at all for attachment name/type or reactions (those only
  /// exist on the full message entity inside a thread, not this list-level
  /// summary). `lastMessageAt` is what actually distinguishes "no messages
  /// yet" from "the last message just had no text".
  String _lastMessagePreviewText(ConversationEntity conversation) {
    if (conversation.lastMessagePreview.isNotEmpty) {
      return conversation.lastMessagePreview;
    }
    if (conversation.lastMessageAt != null) {
      return '📎 Attachment';
    }
    return 'Start a new conversation';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: const Color(0x1A0984E3),
      highlightColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFF1F3F5), width: 1),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          // `conversation.status` is the conversation's own archived/active
          // flag, not the student's actual attendance — showing a green
          // dot for any "active" admin chat was misleading. `studentCode`
          // is directly available on this v2 entity, so the avatar's
          // built-in attendance dot (real "signed in today" vs "absent"
          // vs nothing) is wired up properly instead.
          leading: DocumentImageWidget(
            fileUuid: '',
            imageUrl: conversation.avatarUrl.startsWith('http')
                ? conversation.avatarUrl
                : null,
            mediaAssetCode: conversation.avatarUrl.startsWith('http')
                ? null
                : conversation.avatarUrl,
            name: conversation.title,
            size: 52,
            studentCode: conversation.studentCode,
          ),
          title: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomTextWidget(
                    text: conversation.title.isNotEmpty
                        ? conversation.title
                        : 'Unnamed Conversation',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    fontColor: AppColors.primaryColor,
                  ),
                ),
                Text(
                  _formatTime(conversation.lastMessageAt),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFA0A0A0),
                  ),
                ),
              ],
            ),
          ),
          subtitle: Row(
            children: [
              Flexible(
                fit: FlexFit.tight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lastMessagePreviewText(conversation),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF636E72),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 12,
                          color: Color(0xFF0984E3),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${conversation.participantCount} participants',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFB2BEC3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (conversation.unreadCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B894),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00B894).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      conversation.unreadCount > 99
                          ? '99+'
                          : '${conversation.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) =>
      MessagingTimeFormatter.conversationTime(dt);
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilters});

  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilters
                ? Icons.search_off_rounded
                : Icons.admin_panel_settings_outlined,
            size: 64,
            color: AppColors.primaryColor.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters
                ? 'No conversations match your filters'
                : 'No admin chats yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Try clearing your filters'
                : 'Tap the compose button to start one.',
            style: const TextStyle(fontSize: 13, color: Color(0xFFB2BEC3)),
          ),
        ],
      ),
    );
  }
}

// ─── Error states ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFEBA0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: Color(0xFF856404),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFF856404)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenError extends StatelessWidget {
  const _FullScreenError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: AppColors.primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF636E72)),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
                side: BorderSide(
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
