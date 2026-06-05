import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/presentation/features/kiosk/widgets/kiosk_app_bar.dart';

/// Kiosk-specific Scaffold wrapper.
/// Handles:
/// - Custom kiosk AppBar
/// - Back button intercepting (redirects to /kiosk only)
/// - Prevents accidental exit from kiosk flow
/// - Consistent kiosk UI across all screens
class KioskScaffold extends StatelessWidget {
  const KioskScaffold({
    required this.title,
    required this.body,
    this.showBackButton = true,
    this.onBackPressed,
    this.bottomNavigationBar,
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final Widget body;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Intercept system back button (Android back, iOS swipe)
        AppLogger.d('[Kiosk] System back button pressed, returning to /kiosk');
        onBackPressed?.call();
        GoRouter.of(context).go('/kiosk');
      },
      child: Scaffold(
        appBar: KioskAppBar(
          title: title,
          showBackButton: showBackButton,
          onBackPressed: onBackPressed,
        ),
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
