import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/messaging_staff_result.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/messaging_shimmer.dart';
import 'package:wowcare/presentation/features/communication/cubit/conversation_list_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/conversation_list_state.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/conversation_filter_sheet.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/conversation_tile.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/filter_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

import '../../../../../../../core/storage/storage_service.dart';
import '../../../../../../../core/util/storage_keys.dart';

/// Reusable conversation list for STAFF_DIRECT, ROOM_CHAT, and ADMIN_CHAT.
///
/// Accepts [conversationType] and self-provisions a [ConversationListCubit]
/// scoped to this screen's lifetime. The three thin wrapper screens
/// (StaffMessagingScreen, ParentMessagingScreen, AdminChatScreen) simply pass
/// the corresponding type — no business logic lives in those wrappers.
class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({
    super.key,
    required this.conversationType,
    required this.onConversationTap,
    this.onCreateTap,
    this.title,
  });

  /// Determines which conversations are loaded and how the UI is labelled.
  final ConversationType conversationType;

  /// Called when the user taps a conversation tile.
  final void Function(ConversationEntity conversation) onConversationTap;

  /// Called when the user taps the compose / create FAB.
  /// Pass null to hide the FAB.
  final VoidCallback? onCreateTap;

  /// AppBar title override. Defaults to the type label.
  final String? title;

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showUnreadOnly = false;
  late final ConversationListCubit _cubit;
  Timer? _searchDebounce;
  bool _isGuardian = false;

  @override
  void initState() {
    super.initState();
    _cubit = ConversationListCubit(
      conversationType: widget.conversationType,
      watchConversationsUseCase: serviceLocator(),
      getConversationsUseCase: serviceLocator(),
      getCachedConversationsUseCase: serviceLocator(),
      conversationRepository: serviceLocator(),
      storageService: serviceLocator(),
    );
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _initRole();
    unawaited(_cubit.startWatching());
  }

  Future<void> _initRole() async {
    final role = await serviceLocator<StorageService>().getString(
      StorageKeys.activeSchoolRole,
    );
    if (mounted) {
      setState(() {
        _isGuardian =
            role?.toUpperCase() == 'GUARDIAN' ||
            role?.toUpperCase() == 'PARENT';
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
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

  void _onSearchChanged() {
    setState(() {});
    // Only trigger staff directory search for STAFF_DIRECT conversations.
    if (widget.conversationType != ConversationType.staffDirect) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _cubit.searchStaffDirectory(_searchController.text);
    });
  }

  /// Show the filter bottom sheet for STAFF_DIRECT conversations.
  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ConversationFilterSheet(),
    );
  }

  // ─── Filter ──────────────────────────────────────────────────────────────────

  List<ConversationEntity> _filtered(List<ConversationEntity> all) {
    final q = _searchController.text.trim().toLowerCase();
    return all.where((c) {
      if (_showUnreadOnly && c.unreadCount == 0) return false;
      if (q.isNotEmpty && !c.title.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ConversationListCubit>.value(
      value: _cubit,
      child: BlocBuilder<ConversationListCubit, ConversationListState>(
        builder: (context, state) {
          return GlobalScaffold(
            hasBackButton: false,

            body: RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: () => context.read<ConversationListCubit>().refresh(),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Search + Unread toggle ────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0x33B1AFE9),
                            ),
                            child: CustomSearchBar(
                              controller: _searchController,
                              hintText: 'Search conversations',
                              searchBarColor: const WidgetStatePropertyAll(
                                Colors.transparent,
                              ),
                              borderColor: Colors.transparent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Switch(
                                    value: _showUnreadOnly,
                                    activeThumbColor: AppColors.primaryColor,
                                    onChanged: (v) =>
                                        setState(() => _showUnreadOnly = v),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Unread only',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF636E72),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  // Filter button (STAFF_DIRECT and ADMIN_CHAT for non-guardians)
                                  if (widget.conversationType ==
                                          ConversationType.staffDirect ||
                                      (widget.conversationType ==
                                              ConversationType.adminChat &&
                                          !_isGuardian))
                                    FilterIndicator(
                                      hasActiveFilters: state.hasActiveFilters,
                                      filterCount: [
                                        state.activeDesignation,
                                        state.activeStaffStatus,
                                        state.activeClassroom,
                                      ].where((f) => f != null).length,
                                      onTap: () => _showFilterSheet(context),
                                    ),
                                  _TypeChip(type: state.conversationType),
                                ],
                              ),
                            ],
                          ),
                          // Active filter chips
                          if (state.hasActiveFilters)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                              child: Wrap(
                                spacing: 6,
                                children: [
                                  if (state.activeDesignation != null)
                                    _FilterChip(
                                      label: state.activeDesignation!,
                                      onRemove: () {
                                        context
                                            .read<ConversationListCubit>()
                                            .applyFilters(
                                              designation: null,
                                              staffStatus:
                                                  state.activeStaffStatus,
                                              classroom: state.activeClassroom,
                                            );
                                      },
                                    ),
                                  if (state.activeStaffStatus != null)
                                    _FilterChip(
                                      label: state.activeStaffStatus!,
                                      onRemove: () {
                                        context
                                            .read<ConversationListCubit>()
                                            .applyFilters(
                                              designation:
                                                  state.activeDesignation,
                                              staffStatus: null,
                                              classroom: state.activeClassroom,
                                            );
                                      },
                                    ),
                                  if (state.activeClassroom != null)
                                    _FilterChip(
                                      label: state.activeClassroom!,
                                      onRemove: () {
                                        context
                                            .read<ConversationListCubit>()
                                            .applyFilters(
                                              designation:
                                                  state.activeDesignation,
                                              staffStatus:
                                                  state.activeStaffStatus,
                                              classroom: null,
                                            );
                                      },
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // ── Error banner ─────────────────────────────────────────
                  if (state.errorMessage != null && state.hasConversations)
                    SliverToBoxAdapter(
                      child: _ErrorBanner(message: state.errorMessage!),
                    ),

                  // ── Loading (first load, empty list) ─────────────────────
                  if (state.isLoading && !state.hasConversations)
                    const MessagingShimmer(),

                  // ── Full-screen error (no cached data) ───────────────────
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

                  // ── List ─────────────────────────────────────────────────
                  if (state.hasConversations || state.isFromCache)
                    _buildList(context, state),

                  // ── Empty state (no conversations and not loading) ────────
                  if (!state.isLoading &&
                      !state.hasConversations &&
                      state.errorMessage == null)
                    SliverFillRemaining(
                      child: _EmptyState(type: state.conversationType),
                    ),

                  // ── Load-more indicator ───────────────────────────────────
                  if (state.isLoading && state.hasConversations)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),

                  // ── Staff directory (STAFF_DIRECT + active search only) ───
                  if (widget.conversationType == ConversationType.staffDirect &&
                      _searchController.text.trim().isNotEmpty)
                    _buildStaffDirectory(context, state),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
            floatingActionButton: widget.onCreateTap != null
                ? FloatingActionButton(
                    onPressed: widget.onCreateTap,
                    backgroundColor: AppColors.primaryColor,
                    tooltip: 'New conversation',
                    child: const Icon(Icons.edit_outlined, color: Colors.white),
                  )
                : null,
          );
        },
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
        (context, index) => ConversationListTile(
          conversationCode: filtered[index].code,
          contentBuilder: (context, conversation) => _ConversationTileContent(
            conversation: conversation,
            onTap: () => widget.onConversationTap(conversation),
          ),
        ),
        childCount: filtered.length,
      ),
    );
  }

  /// Staff directory section — shown below conversations while search is active.
  /// Tapping a staff tile starts (or opens an existing) 1:1 conversation via
  /// the host screen's [onCreateTap] callback with the staff's userCode injected.
  ///
  /// Includes loading, error, and empty states with retry support.
  Widget _buildStaffDirectory(
    BuildContext context,
    ConversationListState state,
  ) {
    // Show error state with retry button
    if (state.hasStaffSearchError) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5E5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE57373), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.staffSearchErrorMessage ?? 'Failed to search staff',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFC62828),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () =>
                      context.read<ConversationListCubit>().retryStaffSearch(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show loading indicator
    if (state.isSearchingStaff) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    // Show empty state when no results
    if (state.staffSearchResults.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Text(
            'No staff found for "${_searchController.text}"',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF636E72),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    // Show staff directory list
    return SliverMainAxisGroup(
      slivers: [
        // Section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              'Staff Directory',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),

        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final staff = state.staffSearchResults[index];
            return _StaffDirectoryTile(
              staff: staff,
              isCreating:
                  state.isSearchingStaff &&
                  state.staffSearchErrorMessage == null,
              onTap: () async {
                // Create or get existing STAFF_DIRECT conversation
                await context
                    .read<ConversationListCubit>()
                    .createOrGetStaffDirectConversation(
                      staff.userCode,
                      staff.name,
                      staff.avatarAssetCode,
                    );
              },
            );
          }, childCount: state.staffSearchResults.length),
        ),
      ],
    );
  }
}

// ─── Staff directory tile ─────────────────────────────────────────────────────

class _StaffDirectoryTile extends StatelessWidget {
  const _StaffDirectoryTile({
    required this.staff,
    required this.onTap,
    this.isCreating = false,
  });

  final MessagingStaffResult staff;
  final VoidCallback onTap;
  final bool isCreating;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isCreating ? null : onTap,
      splashColor: const Color(0x1A6C5CE7),
      highlightColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFF),
          border: Border(
            bottom: BorderSide(color: Color(0xFFF1F3F5), width: 1),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          leading: DocumentImageWidget(
            fileUuid: staff.avatarAssetCode ?? '',
            name: staff.name,
            size: 46,
          ),
          title: CustomTextWidget(
            text: staff.name.isNotEmpty ? staff.name : 'Unknown',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            fontColor: AppColors.primaryColor,
          ),
          subtitle: Text(
            staff.designation.isNotEmpty ? staff.designation : staff.status,
            style: const TextStyle(fontSize: 12, color: Color(0xFF636E72)),
          ),
          trailing: isCreating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Message',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6C5CE7),
                    ),
                  ),
                ),
        ),
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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: const Color(0x1A6C5CE7),
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
                          : MessageContentProcessor.previewText(
                              conversation.lastMessagePreview,
                            ),
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
                          Icons.people_outline,
                          size: 12,
                          color: Color(0xFFB2BEC3),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${conversation.participantCount}',
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

// ─── Type indicator chip ──────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});
  final ConversationType type;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      ConversationType.staffDirect => ('Staff Direct', const Color(0xFF6C5CE7)),
      ConversationType.roomChat => ('Room Chat', const Color(0xFF00B894)),
      ConversationType.adminChat => ('Admin Chat', const Color(0xFF0984E3)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.type});
  final ConversationType type;

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      ConversationType.staffDirect => 'No staff conversations yet',
      ConversationType.roomChat => 'No parent conversations yet',
      ConversationType.adminChat => 'No admin chats yet',
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: AppColors.primaryColor.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the compose button to start one.',
            style: TextStyle(fontSize: 13, color: Color(0xFFB2BEC3)),
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

// ─── Filter chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.clear,
              size: 14,
              color: AppColors.primaryColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
