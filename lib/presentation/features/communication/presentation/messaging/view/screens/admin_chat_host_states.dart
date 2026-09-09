part of 'admin_chat_host_screen.dart';

// Empty/error state widgets (Mandate 6 split from admin_chat_host_screen.dart). `part` file:
// library-private, shares the parent's imports, pure move, no behaviour change.

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
          const SizedBox(height: AppSizes.md),
          Text(
            hasFilters
                ? AppStrings.noConversationsMatchFilters
                : AppStrings.emptyAdminChats,
            style: AppTextStyles.size16.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            hasFilters
                ? AppStrings.tryClearingFilters
                : AppStrings.tapComposeToStart,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: AppColors.primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.size14.copyWith(fontSize: 14, color: AppColors.messagingTextSecondary),
            ),
            const SizedBox(height: AppSizes.lg),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(AppStrings.tryAgain),
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
