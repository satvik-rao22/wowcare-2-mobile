import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/utils/school_switch_events.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/shared/common/model/bottom_navigation_item.dart';
import 'package:wowcare/core/extensions/messaging_time_formatter.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/presentation/features/students/view_model/student_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/messaging_shimmer.dart';
import 'package:wowcare/presentation/features/communication/view_model/conversation_list_cubit.dart';
import 'package:wowcare/presentation/features/communication/view_model/conversation_list_state.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:wowcare/presentation/features/communication/model/communication_route_args.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/conversation_tile.dart';
import 'package:wowcare/shared/common/view/filter_screen.dart';
import 'package:wowcare/shared/common/widgets/app_error_state.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/parent_direct_messaging_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/filter_icon_button.dart';
part 'admin_chat_host_lists.dart';
part 'admin_chat_host_states.dart';

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

class _AdminChatHostScreenState extends State<AdminChatHostScreen>
    with SchoolSwitchReloadMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // UI-only view state (Mandate 2): the client-side unread toggle and the
  // applied classroom/tag/status filters (matched client-side, and also pushed
  // to the cubit for the server query). ValueNotifiers rather than `setState`
  // so the body rebuilds off one merged listenable (with the search
  // controller) — the same triggers the removed setStates fired on. Sets are
  // reassigned, not mutated, so the notifier fires.
  final ValueNotifier<bool> _showUnreadOnly = ValueNotifier<bool>(false);
  late final ConversationListCubit _cubit;

  // Student-oriented filters (Classroom + Tag + Status), matched client-side
  // against each conversation's student (admin chats are student-scoped).
  final ValueNotifier<Set<String>> _selectedClassrooms =
      ValueNotifier<Set<String>>({});
  final ValueNotifier<Set<String>> _selectedTags = ValueNotifier<Set<String>>(
    {},
  );
  // Defaults to Active — the list only shows active students unless the
  // user explicitly picks a different status via the filter sheet. Stored
  // in the same Title Case as the filter sheet's own item strings (see
  // _showFilterSheet's `items: const ['Active', 'Upcoming', 'Inactive']`)
  // so this value round-trips correctly as the sheet's initialSelected.
  final ValueNotifier<String?> _selectedStatus = ValueNotifier<String?>(
    'Active',
  );

  /// All tag names for the school (full list from the tags API) so the filter
  /// shows EVERY tag — not only those on the currently-loaded (paginated)
  /// students, which was dropping most tags from the Admin filter.
  List<String> _schoolTagNames = [];

  /// Tag display name -> tag code, from the same school-tags fetch as
  /// [_schoolTagNames]. The filter sheet works in display names (what the
  /// user picks), but the backend's `tagCodes` query param needs codes.
  Map<String, String> _tagNameToCode = {};

  /// Backs the "Start new chat" section shown when searching matches a
  /// student who has no admin-chat conversation yet.
  late final StudentCubit _studentCubit;

  /// Student codes currently being created/opened — guards a double-tap
  /// from firing two create requests while the first is still in flight.
  final Set<String> _startingConversationWith = {};

  @override
  void initState() {
    super.initState();
    // Both cubits are constructed by the route's MultiBlocProvider (Mandate 5)
    // and read here — same instances, same creation moment. StudentCubit's
    // loadInitial() runs in the provider's create closure. BlocProvider owns
    // their lifecycles, so this State no longer closes them.
    _cubit = context.read<ConversationListCubit>();
    _studentCubit = context.read<StudentCubit>();
    unawaited(_loadSchoolTags());
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    unawaited(_cubit.startWatching());
  }

  @override
  void dispose() {
    // _cubit and _studentCubit are owned by the route's MultiBlocProvider.
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _showUnreadOnly.dispose();
    _selectedClassrooms.dispose();
    _selectedTags.dispose();
    _selectedStatus.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Firestore stream auto-loads; no manual pagination needed.
  }

  /// This screen (branch 3 / Communication) is kept alive in the shell's
  /// IndexedStack across a persona switch (e.g. admin <-> guardian for the
  /// same account/school) — it never re-mounts on its own, so [_cubit]'s
  /// Firestore subscription, opened once in [initState], would otherwise
  /// keep resolving unread counts under the persona active when this screen
  /// was FIRST built rather than the one now active. Restarting it re-reads
  /// the current persona (see ConversationEntityRepositoryImpl's
  /// `_unreadRoleBucket`) so an ADMIN_CHAT conversation's unreadByRole-based
  /// count updates for the persona actually looking at it now.
  @override
  void onSchoolSwitched() {
    if (!mounted) return;
    unawaited(_cubit.startWatching());
  }

  /// Rapid search: hits the student list API on every keystroke, mirroring
  /// staff_messaging_tab.dart's Room Chat search — without this, `_studentCubit`
  /// only ever held whatever page `loadInitial()` happened to load once at
  /// mount, so "START NEW CHAT" silently found nothing for anyone outside
  /// that first page and never actually queried the backend as you typed.
  void _onSearchChanged() {
    // The body rebuilds via the merged ListenableBuilder (which listens to
    // _searchController); this handler only drives the student directory search.
    final query = _searchController.text.trim();
    _studentCubit.updateSearch(query);
    unawaited(_studentCubit.refresh(ignoreRefreshingGuard: true));
  }

  bool get _hasStudentFilters =>
      _selectedClassrooms.value.isNotEmpty ||
      _selectedTags.value.isNotEmpty ||
      _selectedStatus.value != null;

  bool get _hasActiveFilters =>
      _showUnreadOnly.value ||
      _searchController.text.trim().isNotEmpty ||
      _hasStudentFilters;

  /// Whether the user has manually diverged from the silent default
  /// (Active status only) — used to decide whether to show the "a filter
  /// is applied" indicator dot on the funnel icon. The default Active
  /// status by itself doesn't count as a user-applied filter; only an
  /// explicit classroom/tag pick, or picking a status OTHER than Active,
  /// does.
  bool get _hasVisibleFilters =>
      _selectedClassrooms.value.isNotEmpty ||
      _selectedTags.value.isNotEmpty ||
      (_selectedStatus.value != null && _selectedStatus.value != 'Active');

  /// The display classroom label a student is filtered by (name preferred).
  String _classroomLabel(Student s) =>
      (s.primaryClassroomName != null &&
          s.primaryClassroomName!.trim().isNotEmpty)
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

  /// Load the FULL school tag-name list for the filter sheet (same source Room
  /// Chat uses) so every tag is selectable, not just tags on loaded students.
  Future<void> _loadSchoolTags() async {
    final schoolCode = await _cubit.readActiveSchoolCode() ?? '';
    if (schoolCode.isEmpty) return;
    final map = await _cubit.loadSchoolTagNameCodeMap(schoolCode);
    if (!mounted) return;
    // Not rendered in build() — read lazily only when the filter sheet opens
    // (_tagOptions) and on apply (_applyServerFilters), so no rebuild needed.
    _schoolTagNames = map.keys.toList();
    _tagNameToCode = map;
  }

  /// Classroom display label -> classroom code, built from the currently
  /// loaded students (same source as [_classroomOptions]). The filter sheet
  /// works in display labels; the backend's `classroomCodes` query param
  /// needs codes.
  Map<String, String> _classroomLabelToCode() {
    final map = <String, String>{};
    for (final s in _studentCubit.state.items) {
      final label = _classroomLabel(s);
      if (label.isNotEmpty && s.classroomCode.isNotEmpty) {
        map[label] = s.classroomCode;
      }
    }
    return map;
  }

  /// Pushes the current classroom/tag/status selection to the server via
  /// [_cubit] — this is what actually narrows the conversation list now,
  /// replacing the old approach of fetching everything and cross-matching
  /// client-side against a separately-filtered student roster (which never
  /// touched the conversations endpoint's own query params).
  Future<void> _applyServerFilters() async {
    if (!_hasStudentFilters) {
      await _cubit.clearFilters();
      return;
    }
    final classroomCodes = _classroomLabelToCode();
    final tagCodes = _tagNameToCode;
    // Passed through as studentStatuses so ConversationListCubit.applyFilters
    // can resolve the conversation-level `status` param from it — that
    // method is also responsible for NOT forwarding ACTIVE/INACTIVE values
    // as a separate studentStatuses query param (see its own doc for why).
    await _cubit.applyFilters(
      classroomCodes: _selectedClassrooms.value
          .map((label) => classroomCodes[label])
          .whereType<String>()
          .toList(),
      tagCodes: _selectedTags.value
          .map((name) => tagCodes[name])
          .whereType<String>()
          .toList(),
      studentStatuses: _selectedStatus.value != null
          ? [_selectedStatus.value!.toUpperCase()]
          : const [],
    );
  }

  /// Tag names for the filter sheet — the full school tag list, unioned with any
  /// tag present on a loaded student (covers a stray tag not in the school list).
  List<String> _tagOptions() {
    final set = <String>{..._schoolTagNames};
    for (final s in _studentCubit.state.items) {
      set.addAll(s.tags.where((t) => t.trim().isNotEmpty));
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Classroom/tag/status narrowing now happens server-side (see
  /// [_applyServerFilters] — the conversations the cubit holds are already
  /// filtered by the time they get here). This only applies the two
  /// filters that stay client-side by nature: the unread toggle (cheap to
  /// check on the already-loaded page) and the live search-as-you-type text.
  List<ConversationEntity> _filtered(List<ConversationEntity> all) {
    final q = _searchController.text.trim().toLowerCase();
    final status = _selectedStatus.value?.trim().toUpperCase();
    return all.where((c) {
      if (_showUnreadOnly.value && c.unreadCount == 0) return false;
      if (q.isNotEmpty && !c.title.toLowerCase().contains(q)) return false;
      // Enforced client-side rather than relying solely on the one-off
      // server-side studentStatuses query in [_applyServerFilters] — this
      // screen's Firestore subscription keeps pushing unfiltered updates
      // on top of state.conversations, so without this the very next
      // realtime snapshot would silently undo whichever status was
      // picked. [_selectedStatus] defaults to 'ACTIVE'. Fails OPEN when
      // studentStatus itself is missing — a conversation must never be
      // hidden just because this field wasn't sent. (Admin Chat is
      // student-scoped — the STAFF_DIRECT `status`-param fix doesn't
      // apply here.)
      final conversationStatus = c.studentStatus?.trim().toUpperCase();
      if (status != null &&
          conversationStatus != null &&
          conversationStatus != status) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Opens the same full-screen Filter UI used by Parent Messaging (Room Chat)
  /// — Classroom + Status + Tags — instead of a bottom sheet, so both screens
  /// share one filter experience.
  void _showFilterSheet() {
    context.push(
      CommunicationRoutes.filter,
      extra: MessagingFilterArgs(
        sections: [
          FilerSection(
            label: 'Classroom',
            hintText: 'Select classroom',
            items: _classroomOptions(),
            initialSelected: _selectedClassrooms.value.toList(),
            isMultiSelectDropDown: true,
          ),
          FilerSection(
            label: 'Status',
            hintText: 'Select status',
            items: const ['Active', 'Upcoming', 'Inactive'],
            initialSelected: _selectedStatus.value != null
                ? [_selectedStatus.value!]
                : const [],
            isSingleSelect: true,
          ),
          FilerSection(
            label: 'Tags',
            hintText: 'Select tags',
            items: _tagOptions(),
            initialSelected: _selectedTags.value.toList(),
            isMultiSelectDropDown: true,
          ),
        ],
        onApply: (filters) {
          if (!mounted) return;
          _selectedClassrooms.value = (filters['Classroom'] ?? const [])
              .toSet();
          _selectedTags.value = (filters['Tags'] ?? const []).toSet();
          final status = filters['Status'] ?? const [];
          _selectedStatus.value = status.isEmpty ? null : status.first;
          unawaited(_applyServerFilters());
        },
      ),
    );
  }

  void _openThread(ConversationEntity conversation) {
    context.push(
      CommunicationRoutes.conversationThread,
      extra: ConversationThreadArgs(conversation: conversation),
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
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Creating conversation with $name…',
    );

    final adminCode = await _cubit.readCurrentUserCode() ?? '';

    final result = await _cubit.createOrOpenConversation(
      type: ConversationType.adminChat,
      studentCode: code,
      classroomCode: student.classroomCode,
      participantCodes: adminCode.isNotEmpty ? [adminCode] : null,
      title: name,
      avatarUrl: student.profileImage ?? '',
    );

    _startingConversationWith.remove(code);
    if (!mounted) return;
    final conversation = result.fold((_) => null, (c) => c);
    if (conversation == null) {
      final failureMessage = result.fold((f) => f.message, (_) => null);
      CoreUtils.showTopSnackBar(
        context: context,
        message: (failureMessage != null && failureMessage.trim().isNotEmpty)
            ? failureMessage
            : AppStrings.couldNotStartConversation(name),
        isError: true,
      );
      return;
    }
    CoreUtils.showTopSnackBar(
      context: context,
      message: AppStrings.chatCreatedSuccessfully(name),
      isSuccess: true,
    );
    unawaited(_cubit.refresh());
    _openThread(conversation);
  }

  Future<void> _showGroupChatSheet() async {
    // A parent/guardian starting an Admin Chat is choosing which admin or
    // director to talk to — not a student, and the Classroom/Status/Tags
    // filters built for staff picking a student don't apply here.
    final isGuardian = context.read<RoleCubit>().isParent;

    await context.push(
      CommunicationRoutes.recipientSelection,
      extra: isGuardian
          ? const RecipientSelectionArgs(
              isStaffSelection: true,
              conversationType: 'ADMIN_CHAT',
              restrictToDesignationCodes: ['ADMIN', 'DIRECTOR'],
              hideFilters: true,
            )
          : const RecipientSelectionArgs(
              isStaffSelection: false,
              conversationType: 'ADMIN_CHAT',
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
        bodyPadding: EdgeInsets.fromLTRB(AppSizes.sm, AppSizes.xs, AppSizes.sm, AppSizes.xs),
        // This route (/admin-chat) is registered OUTSIDE the shell's
        // StatefulShellRoute, so the nav bar's own route-derived resolution
        // can't find a shell ancestor and would otherwise show nothing (or,
        // before that fallback was fixed, incorrectly Dashboard) — force
        // the correct Communication/Messages tab highlighted explicitly.
        activeItemOverride: BottomNavigationItem.communication,
        body: ParentDirectMessagingScreen(
          conversationType: ConversationType.adminChat,
          notCreatedLabel: AppStrings.startConversationWithAdmin,
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
                  return ListenableBuilder(
                    // Rebuild the body when the search text, unread toggle, or
                    // applied filters change — the same triggers the removed
                    // setStates fired on (cubit state stays on the BlocBuilders
                    // above).
                    listenable: Listenable.merge([
                      _searchController,
                      _showUnreadOnly,
                      _selectedClassrooms,
                      _selectedTags,
                      _selectedStatus,
                    ]),
                    builder: (context, _) {
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
                            padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.xs, AppSizes.md, 0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: AppColors.messagingSearchFieldBg,
                                    ),
                                    child: CustomSearchBar(
                                      controller: _searchController,
                                      hintText: AppStrings.searchConversationsEllipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSizes.xs),
                                // Discoverable manual refresh — mirrors the pull-to-refresh
                                // (ConversationListCubit.refresh) so users aren't limited to
                                // the pull gesture, which isn't obvious and can't be
                                // triggered on a short/empty list. Matches Staff/Parent
                                // Messaging's search bar.
                                Material(
                                  color: AppColors.transparentColor,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      context
                                          .read<ConversationListCubit>()
                                          .refresh();
                                      CoreUtils.showTopSnackBar(
                                        context: context,
                                        message: AppStrings.refreshingConversations,
                                        duration: const Duration(
                                          milliseconds: 1200,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(AppSizes.xsPlus),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: AppColors.messagingSearchFieldBg,
                                      ),
                                      child: Icon(
                                        Icons.refresh,
                                        color: AppColors.primaryColor,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSizes.xs),
                                // Non-parents only (the parent branch returns early above).
                                // Same SVG icon + active-filter dot used by Staff/Parent
                                // Messaging's filter button, instead of FilterIndicator's
                                // generic Icons.tune, which didn't match the rest of the
                                // messaging tabs.
                                Material(
                                  color: AppColors.transparentColor,
                                  child: InkWell(
                                    onTap: _showFilterSheet,
                                    borderRadius: BorderRadius.circular(100),
                                    child: Padding(
                                      padding: const EdgeInsets.all(AppSizes.xs),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          FilterGlyph(size: 20),
                                          if (_hasVisibleFilters)
                                            Positioned(
                                              top: -2,
                                              right: -2,
                                              child: Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.messagingNotificationDot,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Unread toggle + clear chip ────────────────────────────
                          Padding(
                            padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.xs, AppSizes.md, 0),
                            child: Row(
                              children: [
                                CustomToggle(
                                  label: AppStrings.showOnlyUnread,
                                  isToggled: _showUnreadOnly.value,
                                  onToggle: (v) => _showUnreadOnly.value = v,
                                  labelOnLeftSide: true,
                                ),
                                const Spacer(),
                                CustomClearAllChip(
                                  label: AppStrings.clearAll,
                                  onTap: () {
                                    _showUnreadOnly.value = false;
                                    _searchController.clear();
                                    _selectedClassrooms.value = {};
                                    _selectedTags.value = {};
                                    // Resets to Active rather than no filter
                                    // at all — matches this screen's default.
                                    _selectedStatus.value = 'Active';
                                    unawaited(_applyServerFilters());
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSizes.xxs),

                          // ── Error banner ──────────────────────────────────────────
                          if (state.errorMessage != null &&
                              state.hasConversations)
                            _ErrorBanner(message: state.errorMessage!),

                          // ── List / loading / empty ────────────────────────────────
                          Expanded(
                            child: CustomRefreshIndicator(
                              onRefresh: () => context
                                  .read<ConversationListCubit>()
                                  .refresh(),
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
                                  if (state.isLoading &&
                                      !state.hasConversations)
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

                                  if (state.hasConversations ||
                                      state.isFromCache)
                                    KeyedSubtree(
                                      key: const ValueKey('conversations_list'),
                                      child: _ConversationSliverList(
                                        filtered: _filtered(state.conversations),
                                        showUnreadOnly: _showUnreadOnly.value,
                                        searchText: _searchController.text,
                                        onOpenThread: _openThread,
                                      ),
                                    ),

                                  if (!state.isLoading &&
                                      !state.hasConversations &&
                                      state.errorMessage == null)
                                    // While actively searching, the "START NEW
                                    // CHAT" section (below) can still have
                                    // content even with zero conversation
                                    // matches — SliverFillRemaining would
                                    // stretch this empty state to fill the
                                    // whole viewport and shove that section
                                    // far off-screen. Only fill-remaining when
                                    // nothing else is going to follow.
                                    _searchController.text.trim().isNotEmpty
                                        ? SliverToBoxAdapter(
                                            key: const ValueKey('empty_state'),
                                            child: _EmptyState(
                                              hasFilters: _hasActiveFilters,
                                            ),
                                          )
                                        : SliverFillRemaining(
                                            key: const ValueKey('empty_state'),
                                            child: _EmptyState(
                                              hasFilters: _hasActiveFilters,
                                            ),
                                          ),

                                  if (state.isLoading && state.hasConversations)
                                    const SliverToBoxAdapter(
                                      key: ValueKey('loading_more_indicator'),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: AppSizes.md,
                                        ),
                                        child: Center(
                                          child: PrimaryCircularLoader(
                                            size: 24,
                                            strokeWidth: 2,
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
          padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.md, AppSizes.lg, AppSizes.xxs),
          child: Text(
            AppStrings.startNewChat(contacts.length),
            style: AppTextStyles.size14.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: AppColors.messagingMutedPurple,
            ),
          ),
        ),
      ),
      SliverList(
        key: const ValueKey('start_new_chat_list'),
        delegate: SliverChildBuilderDelegate((context, index) {
          final student = contacts[index];
          final name = '${student.firstName} ${student.lastName}'.trim();
          // A student with no guardian linked can't be messaged (no one to
          // receive it) — disable the row, matching web.
          final bool isDisabled = !student.hasGuardian;
          return InkWell(
            key: ValueKey('student_contact_${student.code}'),
            onTap: isDisabled
                ? null
                : () => _startConversationWithStudent(student),
            child: Opacity(
              opacity: isDisabled ? 0.5 : 1,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.cardColor,
                  border: Border(
                    bottom: BorderSide(color: AppColors.messagingDividerLight, width: 1),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.xsPlus,
                ),
                child: Row(
                  children: [
                    DocumentImageWidget(
                      disableAttendanceStatusLookup: true,
                      fileUuid: '',
                      imageUrl: student.profileImage,
                      studentCode: student.code,
                      name: name,
                      size: 44,
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTextStyles.size16.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.messagingHeadingPlum,
                            ),
                          ),
                          if (isDisabled)
                            Text(
                              AppStrings.noParentLinked,
                              style: AppTextStyles.size14.copyWith(
                                fontSize: 12,
                                color: AppColors.messagingTextSecondary,
                              ),
                            )
                          else if ((student.primaryClassroomName ?? '')
                              .isNotEmpty)
                            Text(
                              student.primaryClassroomName!,
                              style: AppTextStyles.size14.copyWith(
                                fontSize: 13,
                                color: AppColors.messagingTextSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isDisabled)
                      const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColors.messagingAccentPurple,
                      ),
                  ],
                ),
              ),
            ),
          );
        }, childCount: contacts.length),
      ),
    ];
  }

}
