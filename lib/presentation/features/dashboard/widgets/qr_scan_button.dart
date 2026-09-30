import 'package:flutter/material.dart';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:wowcare/core/theme/app_media_res.dart';

/// Tappable icon that opens the full-screen QR scanner.
///
/// Role detection, sign-in status, and useCase resolution are handled
/// internally by [QrValidationCubit] — no args needed here.
class QrScanButton extends StatelessWidget {
  const QrScanButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        // Registered with `fullscreenDialog: true` on its MaterialPage, so
        // the bottom-up transition and × leading icon are unchanged.
        unawaited(context.push<void>(DashboardRoutes.qrScanner));
      },
      icon: AppIcon(MediaRes.scannerGradientIcon),
    );
  }
}
