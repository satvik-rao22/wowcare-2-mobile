part of 'conversation_list_screen.dart';

// Type/filter chips, empty/error state widgets (Mandate 6 split from conversation_list_screen.dart). `part` file:
// library-private, shares the parent's imports, pure move, no behaviour change.

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});
  final ConversationType type;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      ConversationType.staffDirect => (
        AppStrings.typeStaffDirect,
        AppColors.messagingAccentPurple,
      ),
      ConversationType.roomChat => (
        AppStrings.typeRoomChat,
        AppColors.messagingTypeRoomChat,
      ),
      ConversationType.adminChat => (
        AppStrings.typeAdminChat,
        AppColors.messagingTypeAdminChat,
      ),
      ConversationType.classroomChat => (
        AppStrings.classroom,
        AppColors.messagingTypeClassroom,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xsPlus, vertical: AppSizes.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.size14.copyWith(
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
      ConversationType.staffDirect => AppStrings.emptyStaffConversations,
      ConversationType.roomChat => AppStrings.emptyParentConversations,
      ConversationType.adminChat => AppStrings.emptyAdminChats,
      ConversationType.classroomChat => AppStrings.emptyClassroomConversations,
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
          const SizedBox(height: AppSizes.md),
          Text(
            label,
            style: AppTextStyles.size16.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            AppStrings.tapComposeToStart,
            style: AppTextStyles.size14.copyWith(fontSize: 13, color: AppColors.messagingTextPlaceholder),
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
      margin: const EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, AppSizes.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.xs),
      decoration: BoxDecoration(
        color: AppColors.messagingWarningBannerBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.messagingWarningBannerBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: AppColors.messagingWarningBannerText,
          ),
          const SizedBox(width: AppSizes.xs),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.size14.copyWith(fontSize: 12, color: AppColors.messagingWarningBannerText),
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
    return AppErrorState(
      title: message,
      onRetry: onRetry,
      retryLabel: AppStrings.tryAgain,
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
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xs, vertical: AppSizes.xxs),
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
            style: AppTextStyles.size14.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(width: AppSizes.xxs),
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
