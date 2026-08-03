import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/logger_service.dart';

/// Custom AppBar for Kiosk screens.
/// Features:
/// - Simple, clean design for tablet kiosk
/// - Back button redirects to /kiosk dashboard only
/// - Prevents accidental navigation outside kiosk flow
/// - 3-dot overflow menu for logout (can be hidden with showLogoutMenu=false)
/// - Consistent branding across all kiosk screens
class KioskAppBar extends StatelessWidget implements PreferredSizeWidget {
  const KioskAppBar({
    required this.title,
    this.showBackButton = true,
    this.showLogoutMenu = true,
    this.onBackPressed,
    super.key,
  });

  final String title;
  final bool showBackButton;
  final bool showLogoutMenu;
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
      actions: [
        if (showLogoutMenu)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.primaryColor),
            onSelected: (value) {
              if (value == 'logout') {
                AppLogger.d('[Kiosk] Logout selected from menu');
                GoRouter.of(context).go('/kiosk/logout');
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout, size: 20, color: AppColors.primaryColor),
                    SizedBox(width: 12),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AppColors.themeColor),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}
