import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/presentation/features/communication/cubit/create_conversation_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/create_conversation_state.dart';
import 'package:wowcare/presentation/features/student/cubit/student_cubit.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/messaging_shimmer.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/conversation_list_cubit.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/conversation_list_state.dart';
import 'package:wowcare/presentation/features/communication/v2/screens/conversation_thread_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

import '../../../../../shared/common/widgets/custom_clear_all_chip.dart';
import '../../../../../shared/common/widgets/custom_toggle.dart';
import '../../../../../shared/common/widgets/gradient_add_button.dart';
import '../../../classroom/cubit/classroom_cubit.dart';
import '../../../staff/cubit/staff_cubit.dart';
import '../../cubit/communication_cubit.dart';
import '../../presentation/messaging/view/staff_or_student_selection_bulk_messaging.dart';

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

  @override
  void initState() {
    super.initState();
    _cubit = ConversationListCubit(
      conversationType: ConversationType.adminChat,
      watchConversationsUseCase: serviceLocator(),
      getConversationsUseCase: serviceLocator(),
      getCachedConversationsUseCase: serviceLocator(),
    );
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    unawaited(_cubit.startWatching());
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
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

  bool get _hasActiveFilters =>
      _showUnreadOnly || _searchController.text.trim().isNotEmpty;

  List<ConversationEntity> _filtered(List<ConversationEntity> all) {
    final q = _searchController.text.trim().toLowerCase();
    return all.where((c) {
      if (_showUnreadOnly && c.unreadCount == 0) return false;
      if (q.isNotEmpty && !c.title.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  void _openThread(ConversationEntity conversation) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ConversationThreadScreen(conversation: conversation),
      ),
    );
  }

  void _showFilterSheet() {
    // Use a local copy so we can preview changes before applying.
    bool pendingUnread = _showUnreadOnly;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 16),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFE6E9),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: AppColors.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Filter Conversations',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF636E72),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 20, color: Color(0xFFF1F3F5)),

                  // ── Unread only filter ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: pendingUnread
                          ? AppColors.primaryColor.withValues(alpha: 0.06)
                          : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: pendingUnread
                            ? AppColors.primaryColor.withValues(alpha: 0.3)
                            : const Color(0xFFDFE6E9),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.mark_chat_unread_outlined,
                          size: 20,
                          color: pendingUnread
                              ? AppColors.primaryColor
                              : const Color(0xFF636E72),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unread only',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D3436),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Show only conversations with unread messages',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF636E72),
                                ),
                              ),
                            ],
                          ),
                        ),
                        CustomToggle(
                          label: '',
                          isToggled: pendingUnread,
                          onToggle: (v) => setSheet(() => pendingUnread = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Action buttons ────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: CustomClearAllChip(
                          label: 'Clear All',
                          onTap: () {
                            setSheet(() => pendingUnread = false);
                            setState(() {
                              _showUnreadOnly = false;
                              _searchController.clear();
                            });
                            Navigator.of(ctx).pop();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => _showUnreadOnly = pendingUnread);
                              Navigator.of(ctx).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showGroupChatSheet() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => serviceLocator<StaffCubit>()),
            BlocProvider(create: (_) => serviceLocator<ClassroomCubit>()),
            BlocProvider(create: (_) => serviceLocator<StudentCubit>()),
          ],
          child: const StaffOrStudentSelectionBulkMessaging(
            isStaffSelection: false,
            conversationType: 'ADMIN_CHAT',
          ),
        ),
      ),
    );
    if (mounted) unawaited(_cubit.refresh());
  }

  void _showNewMessageSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider<CreateConversationCubit>(
            create: (_) => serviceLocator<CreateConversationCubit>(),
          ),
          BlocProvider<StudentCubit>(
            create: (_) => serviceLocator<StudentCubit>()..loadInitial(),
          ),
        ],
        child: _AdminChatStudentSheet(
          onCreated: () {
            Navigator.of(context).pop();
            unawaited(_cubit.refresh());
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      hasBackButton: false,
      bodyPadding: EdgeInsets.zero,
      body: BlocProvider<ConversationListCubit>.value(
        value: _cubit,
        child: BlocBuilder<ConversationListCubit, ConversationListState>(
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
                  onComposeTap: _showNewMessageSheet,
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
                      // Filter icon — always visible, highlights when active
                      // GestureDetector(
                      //   onTap: _showFilterSheet,
                      //   child: Stack(
                      //     clipBehavior: Clip.none,
                      //     children: [
                      //       Container(
                      //         height: 44,
                      //         width: 44,
                      //         decoration: BoxDecoration(
                      //           borderRadius: BorderRadius.circular(12),
                      //           color: _hasActiveFilters
                      //               ? AppColors.primaryColor.withValues(
                      //                   alpha: 0.15,
                      //                 )
                      //               : const Color(0x33B1AFE9),
                      //           border: Border.all(
                      //             color: _hasActiveFilters
                      //                 ? AppColors.primaryColor.withValues(
                      //                     alpha: 0.5,
                      //                   )
                      //                 : Colors.transparent,
                      //           ),
                      //         ),
                      //         child: Icon(
                      //           Icons.tune_rounded,
                      //           color: _hasActiveFilters
                      //               ? AppColors.primaryColor
                      //               : AppColors.primaryColor.withValues(
                      //                   alpha: 0.5,
                      //                 ),
                      //           size: 22,
                      //         ),
                      //       ),
                      //       if (_hasActiveFilters)
                      //         Positioned(
                      //           top: -3,
                      //           right: -3,
                      //           child: Container(
                      //             width: 10,
                      //             height: 10,
                      //             decoration: BoxDecoration(
                      //               color: AppColors.primaryColor,
                      //               shape: BoxShape.circle,
                      //               border: Border.all(
                      //                 color: Colors.white,
                      //                 width: 1.5,
                      //               ),
                      //             ),
                      //           ),
                      //         ),
                      //     ],
                      //   ),
                      // ),
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
                        onToggle: (v) => setState(() => _showUnreadOnly = v),
                        labelOnLeftSide: true,
                      ),
                      const Spacer(),
                      CustomClearAllChip(
                        label: 'Clear All',
                        onTap: () => setState(() {
                          _showUnreadOnly = false;
                          _searchController.clear();
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
                      slivers: [
                        if (state.isLoading && !state.hasConversations)
                          const MessagingShimmer(),

                        if (!state.isLoading &&
                            state.errorMessage != null &&
                            !state.hasConversations)
                          SliverFillRemaining(
                            child: _FullScreenError(
                              message: state.errorMessage!,
                              onRetry: () => context
                                  .read<ConversationListCubit>()
                                  .startWatching(),
                            ),
                          ),

                        if (state.hasConversations || state.isFromCache)
                          _buildList(context, state),

                        if (!state.isLoading &&
                            !state.hasConversations &&
                            state.errorMessage == null)
                          SliverFillRemaining(
                            child: _EmptyState(hasFilters: _hasActiveFilters),
                          ),

                        if (state.isLoading && state.hasConversations)
                          const SliverToBoxAdapter(
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

                        const SliverToBoxAdapter(child: SizedBox(height: 80)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, ConversationListState state) {
    final filtered = _filtered(state.conversations);

    if (filtered.isEmpty) {
      return SliverFillRemaining(
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
      delegate: SliverChildBuilderDelegate(
        (context, index) => _ConversationTile(
          conversation: filtered[index],
          onTap: () => _openThread(filtered[index]),
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

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final ConversationEntity conversation;
  final VoidCallback onTap;

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
          leading: Stack(
            children: [
              DocumentImageWidget(
                fileUuid: conversation.avatarUrl,
                name: conversation.title,
                size: 52,
              ),
              if (conversation.status == 'ACTIVE')
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B115),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                  ),
                ),
            ],
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.lastMessagePreview.isEmpty
                          ? 'Start a new conversation'
                          : conversation.lastMessagePreview,
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
                Container(
                  margin: const EdgeInsets.only(left: 12),
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
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '—';
    final tz = SchoolTimezoneResolver.lastKnownTimeZone;
    final local = SchoolZoneDateTime.dateTimeFromInstantInSchool(dt, tz);
    final now = SchoolZoneDateTime.dateTimeFromInstantInSchool(
      DateTime.now().toUtc(),
      tz,
    );
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(local.year, local.month, local.day);
    final diff = today.difference(msgDay).inDays;
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final time = '$hh:$mm';

    if (diff == 0) return 'Today | $time';
    if (diff == 1) return 'Yesterday | $time';
    if (diff < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${days[local.weekday - 1]} | $time';
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year} | $time';
  }
}

// ─── New admin chat compose sheet ─────────────────────────────────────────────

class _NewAdminChatSheet extends StatefulWidget {
  const _NewAdminChatSheet({required this.onCreated});

  final VoidCallback onCreated;

  @override
  State<_NewAdminChatSheet> createState() => _NewAdminChatSheetState();
}

class _NewAdminChatSheetState extends State<_NewAdminChatSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    final storage = serviceLocator<StorageService>();
    final orgCode = await storage.getString(StorageKeys.organizationCode) ?? '';
    final schoolCode = await storage.getString(StorageKeys.schoolCode) ?? '';
    final adminCode = await storage.getString(StorageKeys.userCode) ?? '';

    await context.read<CreateConversationCubit>().createConversation(
      title: _titleController.text.trim(),
      organizationCode: orgCode,
      schoolCode: schoolCode,
      participantUserCodes: const [],
      participants: adminCode.isNotEmpty
          ? [
              {'userCode': adminCode, 'participantType': 'ADMIN'},
            ]
          : null,
      type: 'ADMIN_CHAT',
      description: _descController.text.trim(),
      avatarUrl: '',
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final state = context.read<CreateConversationCubit>().state;
    if (state is CreateConversationSuccess) {
      widget.onCreated();
    } else if (state is CreateConversationError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDFE6E9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0984E3).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: Color(0xFF0984E3),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Admin Chat',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D3436),
                        ),
                      ),
                      Text(
                        'Start a conversation with admin',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF636E72),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF636E72),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F3F5)),

          // Form
          Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Subject *',
                      hintText: 'e.g. Question about my child\'s progress',
                      prefixIcon: const Icon(Icons.subject_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDFE6E9)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDFE6E9)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF0984E3),
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Subject is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Initial message (optional)',
                      hintText: 'Describe what you\'d like to discuss…',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDFE6E9)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDFE6E9)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF0984E3),
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        _isSubmitting ? 'Starting…' : 'Start Conversation',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0984E3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Admin Chat student-picker sheet ─────────────────────────────────────────
/// Shows a searchable list of students. Tapping a student creates an
/// ADMIN_CHAT conversation scoped to that student (admin as sole participant)
/// and calls [onCreated] with the created [ConversationEntity].

class _AdminChatStudentSheet extends StatefulWidget {
  const _AdminChatStudentSheet({required this.onCreated});

  final VoidCallback onCreated;

  @override
  State<_AdminChatStudentSheet> createState() => _AdminChatStudentSheetState();
}

class _AdminChatStudentSheetState extends State<_AdminChatStudentSheet> {
  final TextEditingController _searchController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createChat(Student student) async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    final storage = serviceLocator<StorageService>();
    final orgCode = await storage.getString(StorageKeys.organizationCode) ?? '';
    final schoolCode = await storage.getString(StorageKeys.schoolCode) ?? '';
    final adminCode = await storage.getString(StorageKeys.userCode) ?? '';

    if (!mounted) return;

    await context.read<CreateConversationCubit>().createConversation(
      title: '${student.firstName} ${student.lastName}'.trim(),
      type: 'ADMIN_CHAT',
      organizationCode: orgCode,
      schoolCode: schoolCode,
      studentCode: student.code,
      participantUserCodes: const [],
      participants: adminCode.isNotEmpty
          ? [
              {'userCode': adminCode, 'participantType': 'ADMIN'},
            ]
          : null,
      description: '',
      avatarUrl: student.profileImage ?? '',
    );

    if (!mounted) return;
    setState(() => _isCreating = false);

    final state = context.read<CreateConversationCubit>().state;
    if (state is CreateConversationSuccess) {
      widget.onCreated();
    } else if (state is CreateConversationError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── Handle + header ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDFE6E9),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0984E3,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_outlined,
                            color: Color(0xFF0984E3),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'New Admin Chat',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF636E72),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // ── Search ───────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0x22B1AFE9),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search students…',
                          hintStyle: const TextStyle(
                            color: Color(0xFFB2BEC3),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFFB2BEC3),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F3F5)),

              // ── Student list ─────────────────────────────────────────────
              Expanded(
                child: BlocBuilder<StudentCubit, StudentState>(
                  builder: (context, state) {
                    if (state.isLoading && state.items.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final query = _searchController.text.trim().toLowerCase();
                    final students = state.items.where((s) {
                      if (query.isEmpty) return true;
                      return s.fullName.toLowerCase().contains(query);
                    }).toList();

                    if (students.isEmpty) {
                      return Center(
                        child: Text(
                          query.isEmpty
                              ? 'No students found'
                              : 'No results for "$query"',
                          style: const TextStyle(
                            color: Color(0xFF636E72),
                            fontSize: 14,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: students.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFF1F3F5)),
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryColor.withValues(
                              alpha: 0.12,
                            ),
                            backgroundImage:
                                student.profileImage != null &&
                                    student.profileImage!.isNotEmpty
                                ? NetworkImage(student.profileImage!)
                                : null,
                            child:
                                student.profileImage == null ||
                                    student.profileImage!.isEmpty
                                ? Text(
                                    student.firstName.isNotEmpty
                                        ? student.firstName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            student.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                          subtitle: Text(
                            student.code,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF636E72),
                            ),
                          ),
                          trailing: _isCreating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: Color(0xFF0984E3),
                                  size: 20,
                                ),
                          onTap: _isCreating
                              ? null
                              : () => _createChat(student),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
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
