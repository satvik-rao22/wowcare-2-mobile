import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/logger_service.dart';

/// Custom AppBar for Kiosk screens.
/// Features:
/// - Simple, clean design for tablet kiosk
/// - Back button redirects to /kiosk dashboard only
/// - Prevents accidental navigation outside kiosk flow
/// - Consistent branding across all kiosk screens
class KioskAppBar extends StatelessWidget implements PreferredSizeWidget {
  const KioskAppBar({
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    super.key,
  });

  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
              onPressed: () {
                AppLogger.d('[Kiosk] Back button pressed, returning to /kiosk');
                onBackPressed?.call();
                // Always go back to kiosk dashboard, not normal back navigation
                GoRouter.of(context).go('/kiosk');
              },
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AppColors.themeColor),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}
