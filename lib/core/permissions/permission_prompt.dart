import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';

import 'app_permission.dart';
import 'permission_manager.dart';

/// The user-facing permission flow: explain, ask the OS, or walk the user
/// through Settings — whichever the current state calls for.
///
/// ```dart
/// onTap: () async {
///   final ok = await PermissionPrompt.ensure(
///     context,
///     AppPermission.camera,
///     reason: 'to scan the QR code at your school',
///   );
///   if (ok) openScanner();
/// }
/// ```
///
/// Use it both before a feature that needs the permission and as the tap
/// handler of a control you greyed out because the permission is missing
/// (see `PermissionBuilder`).
abstract final class PermissionPrompt {
  /// Returns true when [permission] is usable, asking for it if needed.
  ///
  /// [reason] finishes the sentence "WowCare needs camera access …", e.g.
  /// `'to scan the QR code at your school'`. It is shown only in our own
  /// sheets — the OS dialog always shows the Info.plist / system text.
  ///
  /// Flow:
  /// - granted → true, no UI.
  /// - restricted → explains it is blocked by the device owner; false.
  /// - can still ask → (Android, after one refusal) explains why first, then
  ///   shows the OS dialog; returns its answer. A "Don't allow" given just
  ///   now is respected silently.
  /// - OS will not ask again → shows numbered Settings steps with an
  ///   "Open Settings" button; false.
  static Future<bool> ensure(
    BuildContext context,
    AppPermission permission, {
    String? reason,
  }) async {
    final status = await PermissionManager.status(permission);
    if (status.isGranted) return true;
    if (!context.mounted) return false;

    if (status == AppPermissionStatus.restricted) {
      await _showSheet(context, _restrictedCopy(permission));
      return false;
    }

    if (status == AppPermissionStatus.denied) {
      if (await PermissionManager.shouldExplainBeforeAsking(permission)) {
        if (!context.mounted) return false;
        final proceed = await _showSheet(
          context,
          _rationaleCopy(permission, reason),
        );
        if (proceed != true) return false;
      }

      // The user is answering the OS dialog right now, so whatever they pick
      // is final for this tap — don't follow a "Don't allow" with our own
      // sheet. The Settings steps show on their *next* attempt, once the OS
      // reports permanentlyDenied (both platforms do so reliably on check).
      return (await PermissionManager.request(permission)).isGranted;
    }

    if (!context.mounted) return false;
    final openSettings = await _showSheet(
      context,
      _settingsCopy(permission, reason),
    );
    if (openSettings == true) await PermissionManager.openSettings();
    return false;
  }

  // ── Copy ──────────────────────────────────────────────────────────────────

  static String _needs(AppPermission p, String? reason) {
    final name = p.label.toLowerCase();
    return reason == null
        ? 'WowCare needs $name access for this feature.'
        : 'WowCare needs $name access $reason.';
  }

  static _SheetCopy _rationaleCopy(AppPermission p, String? reason) =>
      _SheetCopy(
        icon: p.icon,
        title: 'Allow ${p.label.toLowerCase()} access',
        message:
            '${_needs(p, reason)} You can change this any time in Settings.',
        confirmLabel: 'Continue',
      );

  static _SheetCopy _settingsCopy(AppPermission p, String? reason) =>
      _SheetCopy(
        icon: p.icon,
        title: '${p.label} access is off',
        message: '${_needs(p, reason)} Turn it on in Settings:',
        steps: [..._settingsSteps(p), 'Come back to WowCare and try again.'],
        confirmLabel: 'Open Settings',
      );

  static _SheetCopy _restrictedCopy(AppPermission p) => _SheetCopy(
    icon: p.icon,
    title: '${p.label} is blocked on this device',
    message:
        'Screen Time or your organisation\'s device policy is blocking '
        '${p.label.toLowerCase()} access, so it can\'t be turned on from '
        'WowCare. Ask whoever manages this device to allow it.',
    confirmLabel: 'OK',
    showCancel: false,
  );

  /// What the user taps after "Open Settings" lands them on WowCare's page.
  /// Android wording is the stock (Pixel) wording; most OEMs match it.
  static List<String> _settingsSteps(AppPermission p) {
    const open = 'Tap “Open Settings” below.';
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      switch (p) {
        case AppPermission.camera:
          return const [open, 'Turn on “Camera”.'];
        case AppPermission.location:
          return const [
            open,
            'Tap “Location”.',
            'Choose “While Using the App”.',
          ];
        case AppPermission.notifications:
          return const [
            open,
            'Tap “Notifications”.',
            'Turn on “Allow Notifications”.',
          ];
      }
    }
    switch (p) {
      case AppPermission.camera:
        return const [
          open,
          'Tap “Permissions”, then “Camera”.',
          'Choose “Allow only while using the app”.',
        ];
      case AppPermission.location:
        return const [
          open,
          'Tap “Permissions”, then “Location”.',
          'Choose “Allow only while using the app”.',
        ];
      case AppPermission.notifications:
        return const [open, 'Tap “Notifications”.', 'Turn notifications on.'];
    }
  }

  // ── Sheet ─────────────────────────────────────────────────────────────────

  static Future<bool?> _showSheet(BuildContext context, _SheetCopy copy) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      // Ground and corners come from ThemeData.bottomSheetTheme.
      builder: (sheetContext) => _PermissionSheet(
        copy: copy,
        onConfirm: () => Navigator.pop(sheetContext, true),
        onCancel: () => Navigator.pop(sheetContext, false),
      ),
    );
  }
}

class _SheetCopy {
  const _SheetCopy({
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.steps = const [],
    this.showCancel = true,
  });

  final IconData icon;
  final String title;
  final String message;
  final List<String> steps;
  final String confirmLabel;
  final bool showCancel;
}

class _PermissionSheet extends StatelessWidget {
  const _PermissionSheet({
    required this.copy,
    required this.onConfirm,
    required this.onCancel,
  });

  final _SheetCopy copy;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    // Colours come from the theme, so the sheet follows whichever app skin is
    // active without importing it.
    final colors = Theme.of(context).colorScheme;
    final badge = BoxDecoration(
      color: colors.primary.withValues(alpha: 0.1),
      shape: BoxShape.circle,
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: badge,
                  child: Icon(copy.icon, size: 20, color: colors.primary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(copy.title, style: AppTextStyles.title)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(copy.message, style: AppTextStyles.body),
            if (copy.steps.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < copy.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: badge,
                        child: Text(
                          '${i + 1}',
                          style: AppTextStyles.small.copyWith(
                            color: colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(copy.steps[i], style: AppTextStyles.body),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.lg),
            CustomButtonLayout(
              isForm: false,
              confirmButtonLabel: copy.confirmLabel,
              cancelButtonLabel: 'Not now',
              showCancelButton: copy.showCancel,
              onPressedConfirm: onConfirm,
              onPressedCancel: onCancel,
            ),
          ],
        ),
      ),
    );
  }
}
