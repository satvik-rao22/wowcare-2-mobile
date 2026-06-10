import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/messaging_shimmer.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/conversation_list_cubit.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/conversation_list_state.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _cubit = ConversationListCubit(
      conversationType: widget.conversationType,
      getConversationsUseCase: serviceLocator(),
      getCachedConversationsUseCase: serviceLocator(),
    );
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    unawaited(_cubit.loadInitial());
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
    if (!_scrollController.hasClients) return;
    final threshold =
        _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.offset >= threshold) {
      unawaited(context.read<ConversationListCubit>().loadNextPage());
    }
  }

  void _onSearchChanged() => setState(() {});

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
        final title = widget.title ?? _typeLabel(state.conversationType);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: CustomTextWidget(
              text: title,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              fontColor: AppColors.primaryColor,
            ),
            actions: [
              if (widget.onCreateTap != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: AppColors.primaryColor,
                  onPressed: widget.onCreateTap,
                  tooltip: 'New conversation',
                ),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.primaryColor,
            onRefresh: () =>
                context.read<ConversationListCubit>().refresh(),
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
                            searchBarColor:
                                const WidgetStatePropertyAll(Colors.transparent),
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
                            _TypeChip(type: state.conversationType),
                          ],
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
                      onRetry: () =>
                          context.read<ConversationListCubit>().loadInitial(),
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
        (context, index) => _ConversationTile(
          conversation: filtered[index],
          onTap: () => widget.onConversationTap(filtered[index]),
        ),
        childCount: filtered.length,
      ),
    );
  }

  String _typeLabel(ConversationType type) {
    switch (type) {
      case ConversationType.staffDirect:
        return 'Staff Messaging';
      case ConversationType.roomChat:
        return 'Parent Messaging';
      case ConversationType.adminChat:
        return 'Admin Chat';
    }
  }
}

// ─── Conversation tile ────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    color: const Color(0xFF6C5CE7),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
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
    final local =
        SchoolZoneDateTime.dateTimeFromInstantInSchool(dt, tz);
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
      const days = [
        'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
      ];
      return '${days[local.weekday - 1]} | $time';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
          const Icon(Icons.warning_amber_rounded,
              size: 16, color: Color(0xFF856404)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF856404),
              ),
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
            Icon(Icons.cloud_off_rounded,
                size: 56,
                color: AppColors.primaryColor.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF636E72)),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
                side: BorderSide(
                    color: AppColors.primaryColor.withValues(alpha: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
