part of 'conversation_list_screen.dart';

// Staff-directory + conversation tile content widgets (Mandate 6 split from conversation_list_screen.dart). `part` file:
// library-private, shares the parent's imports, pure move, no behaviour change.

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
      splashColor: AppColors.messagingTileSplash,
      highlightColor: AppColors.transparentColor,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.messagingTileBg,
          border: Border(
            bottom: BorderSide(color: AppColors.messagingDividerLight, width: 1),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.xsPlus,
          ),
          leading: DocumentImageWidget(
            disableAttendanceStatusLookup: true,
            fileUuid: '',
            mediaAssetCode: staff.avatarAssetCode,
            name: staff.name,
            size: 46,
          ),
          title: CustomTextWidget(
            text: staff.name.isNotEmpty ? staff.name : AppStrings.unknown,
            fontWeight: FontWeight.w600,
            fontSize: 15,
            fontColor: AppColors.primaryColor,
          ),
          subtitle: Text(
            staff.designation.isNotEmpty ? staff.designation : staff.status,
            style: AppTextStyles.size14.copyWith(fontSize: 12, color: AppColors.messagingTextSecondary),
          ),
          trailing: isCreating
              ? const PrimaryCircularLoader(size: 20, strokeWidth: 2)
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.xsPlus,
                    vertical: AppSizes.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.messagingAccentPurple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppStrings.messageAction,
                    style: AppTextStyles.size14.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.messagingAccentPurple,
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
    required this.currentUserCode,
    required this.onTap,
  });

  final ConversationEntity conversation;
  final String currentUserCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 1:1 (STAFF_DIRECT) chats have no conversation-level avatar — resolve the other participant's
    // photo; group/room chats use the conversation (student) avatar. See displayAvatar/displayTitle.
    final avatar = conversation.displayAvatar(currentUserCode);
    final displayName = conversation.displayTitle(currentUserCode);
    return InkWell(
      onTap: onTap,
      splashColor: AppColors.messagingTileSplash,
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
          leading: Stack(
            children: [
              DocumentImageWidget(
                disableAttendanceStatusLookup: true,
                fileUuid: '',
                // `avatar` is either a resolved URL or a raw media-asset code depending on which
                // screen created the conversation — route to whichever matches the value's shape.
                // Also pass studentCode so a student-scoped (room/admin) chat can resolve the
                // student's photo via the profile-lookup endpoint when no URL/asset is stored.
                imageUrl: avatar.startsWith('http') ? avatar : null,
                mediaAssetCode: avatar.startsWith('http')
                    ? null
                    : (avatar.isNotEmpty ? avatar : null),
                studentCode: conversation.studentCode,
                name: displayName,
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
                      color: AppColors.messagingOnlineDot,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cardColor, width: 2.5),
                    ),
                  ),
                ),
            ],
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
                      conversation.lastMessagePreview.isEmpty
                          ? AppStrings.startANewConversation
                          : MessageContentProcessor.previewText(
                              conversation.lastMessagePreview,
                            ),
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
                        const Icon(
                          Icons.people_outline,
                          size: 12,
                          color: AppColors.messagingTextPlaceholder,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          // participantCount comes back null/0 from the list
                          // endpoint even when participants is fully
                          // populated — count active participants directly.
                          '${conversation.participants.where((p) => p.isActive).length}',
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

// ─── Type indicator chip ──────────────────────────────────────────────────────
