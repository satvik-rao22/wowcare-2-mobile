part of 'admin_chat_host_screen.dart';

// Conversation sliver list, page header, tile content (Mandate 6 split from admin_chat_host_screen.dart). `part` file:
// library-private, shares the parent's imports, pure move, no behaviour change.

class _ConversationSliverList extends StatelessWidget {
  const _ConversationSliverList({
    required this.filtered,
    required this.showUnreadOnly,
    required this.searchText,
    required this.onOpenThread,
  });

  final List<ConversationEntity> filtered;
  final bool showUnreadOnly;
  final String searchText;
  final void Function(ConversationEntity conversation) onOpenThread;

  @override
  Widget build(BuildContext context) {
    if (filtered.isEmpty) {
      return SliverFillRemaining(
        key: const ValueKey('no_results'),
        child: Center(
          child: Text(
            showUnreadOnly
                ? AppStrings.noUnreadConversations
                : AppStrings.noResultsFor(searchText),
            style: const TextStyle(color: AppColors.messagingTextSecondary),
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
            onTap: () => onOpenThread(conversation),
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
      padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.md, AppSizes.md, AppSizes.sm),
      decoration: const BoxDecoration(
        color: AppColors.cardColor,
        border: Border(bottom: BorderSide(color: AppColors.messagingDividerLight, width: 1)),
      ),
      child: Row(
        children: [
          // Title + unread badge
          Expanded(
            child: Row(
              children: [
                CustomTextWidget(
                  text: AppStrings.typeAdminChat,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  fontColor: AppColors.primaryColor,
                ),
                if (totalUnread > 0) ...[
                  const SizedBox(width: AppSizes.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.xs,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.messagingTypeAdminChat,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      totalUnread > 99 ? AppStrings.unreadCountOverflow : '$totalUnread',
                      style: AppTextStyles.size14.copyWith(
                        color: AppColors.messagingOnAccent,
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
  ///
  /// Prefixed with the sender's name (`SenderName: message`) to match the
  /// web app's chat list — this was previously dropped entirely on mobile.
  /// The backend doesn't actually send a dedicated sender-name field, so
  /// `ConversationEntity.lastMessageSenderDisplayName` derives it from
  /// `lastMessageBy` + `participants` instead. Only the "no messages yet"
  /// placeholder stays sender-less, since there's no sender to attribute it
  /// to.
  String _lastMessagePreviewText(ConversationEntity conversation) {
    final body = conversation.lastMessagePreview.isNotEmpty
        ? conversation.lastMessagePreview
        : (conversation.lastMessageAt != null ? '📎 Attachment' : null);
    if (body == null) return AppStrings.startANewConversation;
    final senderName = conversation.lastMessageSenderDisplayName?.trim();
    if (senderName == null || senderName.isEmpty) return body;
    return '$senderName: $body';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: AppColors.messagingAdminChatSplash,
      highlightColor: AppColors.transparentColor,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardColor,
          border: Border(
            bottom: BorderSide(color: AppColors.messagingDividerLight, width: 1),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.sm,
          ),
          // `conversation.status` is the conversation's own archived/active
          // flag, not the student's actual attendance — showing a green
          // dot for any "active" admin chat was misleading. `studentCode`
          // is directly available on this v2 entity, so the avatar's
          // built-in attendance dot (real "signed in today" vs "absent"
          // vs nothing) is wired up properly instead.
          leading: DocumentImageWidget(
            disableAttendanceStatusLookup: true,
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
            padding: const EdgeInsets.only(bottom: AppSizes.xxs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomTextWidget(
                    text: conversation.title.isNotEmpty
                        ? conversation.title
                        : AppStrings.unnamedConversation,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    fontColor: AppColors.primaryColor,
                  ),
                ),
                Text(
                  _formatTime(conversation.lastMessageAt),
                  style: AppTextStyles.size14.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.messagingTimestamp,
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
                      style: AppTextStyles.size14.copyWith(
                        color: AppColors.messagingTextSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xxs),
                    Row(
                      children: [
                        // Private Mode indicator — a parent (or the room)
                        // currently has private mode on. Mirrors
                        // MessagingListTile's lock icon (Room Chat list),
                        // which this Admin Chat tile never had.
                        // `hasActivePrivateMode` covers both the room-wide
                        // flag and the per-parent state map.
                        if (conversation.hasActivePrivateMode) ...[
                          const Icon(
                            Icons.lock,
                            size: 12,
                            color: AppColors.messagingTextSecondary,
                          ),
                          const SizedBox(width: 3),
                        ],
                        const Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 12,
                          color: AppColors.messagingTypeAdminChat,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          // The list endpoint sends participantCount as null
                          // for ADMIN_CHAT (always parses to 0) even though
                          // it embeds the full participants array correctly —
                          // count active participants directly instead of
                          // trusting that separate, unpopulated field.
                          AppStrings.participantsCount(conversation.participants.where((p) => p.isActive).length),
                          style: AppTextStyles.size14.copyWith(
                            fontSize: 11,
                            color: AppColors.messagingTextPlaceholder,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (conversation.unreadCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: AppSizes.sm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.xs,
                      vertical: AppSizes.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.messagingUnreadBadge,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.messagingUnreadBadge.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      conversation.unreadCount > 99
                          ? AppStrings.unreadCountOverflow
                          : '${conversation.unreadCount}',
                      style: AppTextStyles.size14.copyWith(
                        color: AppColors.messagingOnAccent,
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
