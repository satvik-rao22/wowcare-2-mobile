import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';

/// The one place the app checks and asks for runtime permissions.
///
/// No setup — import this file and call it:
///
/// ```dart
/// // From a screen: explains, asks, or shows Settings steps. True = allowed.
/// if (await PermissionManager.ensure(
///   context,
///   AppPermission.camera,
///   reason: 'to scan the QR code at your school',
/// )) {
///   openScanner();
/// }
///
/// // From a cubit or repository (no UI):
/// await PermissionManager.request(AppPermission.notifications);
/// final allowed = await PermissionManager.isGranted(AppPermission.location);
/// ```
///
/// For UI that should look disabled until a permission is granted, see
/// [PermissionBuilder] below.
///
/// The plugins (permission_handler, Geolocator) stay inside this file, so
/// upgrading or swapping one changes nothing at the call sites.
abstract final class PermissionManager {
  /// Returns true when [permission] is usable, asking for it if needed.
  ///
  /// [reason] finishes the sentence "WowCare needs camera access …", e.g.
  /// `'to scan the QR code at your school'`. It only appears in our own
  /// sheets; the OS dialog shows the Info.plist / system text.
  ///
  /// - granted → true, no UI.
  /// - restricted → explains it is blocked by the device owner; false.
  /// - can still ask → shows the OS dialog (on Android, after one refusal,
  ///   explains why first) and returns its answer. A "Don't allow" given just
  ///   now is respected — no extra sheet.
  /// - OS won't ask again → shows numbered Settings steps with an
  ///   "Open Settings" button; false.
  static Future<bool> ensure(
    BuildContext context,
    AppPermission permission, {
    String? reason,
  }) async {
    final current = await status(permission);
    if (!context.mounted) return current.isGranted;

    switch (current) {
      case AppPermissionStatus.granted:
        return true;

      case AppPermissionStatus.restricted:
        await _showSheet(context, _Copy.restricted(permission));
        return false;

      case AppPermissionStatus.denied:
        if (await _shouldExplainFirst(permission)) {
          if (!context.mounted) return false;
          final proceed = await _showSheet(
            context,
            _Copy.rationale(permission, reason),
          );
          if (proceed != true) return false;
        }
        // Whatever the user picks in the OS dialog is final for this tap.
        // If it was "Don't allow", the Settings steps show on their next try.
        return (await request(permission)).isGranted;

      case AppPermissionStatus.permanentlyDenied:
        final open = await _showSheet(
          context,
          _Copy.settings(permission, reason),
        );
        if (open == true) await openSettings();
        return false;
    }
  }

  /// Reads the current status. Never shows a dialog, never throws (a plugin
  /// failure is logged and reported as denied).
  static Future<AppPermissionStatus> status(AppPermission permission) async {
    try {
      return await _adjust(permission, await _osCheck(permission));
    } catch (e, s) {
      AppLogger.e('[Permission] status($permission) failed', e, s);
      return AppPermissionStatus.denied;
    }
  }

  static Future<bool> isGranted(AppPermission permission) async =>
      (await status(permission)).isGranted;

  /// Shows the OS dialog if the OS still allows it, and returns the result.
  /// No UI of our own — use [ensure] from screens.
  ///
  /// Requests run one at a time: two at once make the plugin throw.
  static Future<AppPermissionStatus> request(AppPermission permission) {
    return _oneAtATime(() async {
      try {
        final current = await status(permission);
        if (current.isGranted || current == AppPermissionStatus.restricted) {
          return current;
        }
        final result = await _adjust(permission, await _osRequest(permission));
        AppLogger.d('[Permission] request($permission) → $result');
        return result;
      } catch (e, s) {
        AppLogger.e('[Permission] request($permission) failed', e, s);
        return AppPermissionStatus.denied;
      } finally {
        _changes.notify();
      }
    });
  }

  /// Opens this app's page in system Settings. False if the OS couldn't.
  static Future<bool> openSettings() async {
    try {
      return await ph.openAppSettings();
    } catch (e, s) {
      AppLogger.e('[Permission] openSettings failed', e, s);
      return false;
    }
  }

  /// Whether the device's location service (GPS) is switched on. This is a
  /// device setting, separate from the app's location permission.
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e, s) {
      AppLogger.e('[Permission] isLocationServiceEnabled failed', e, s);
      return false;
    }
  }

  /// Fires after every [request], so [PermissionBuilder]s re-check.
  static Listenable get changes => _changes;
  static final _ChangeSignal _changes = _ChangeSignal();

  /// Overrides the Android API level in tests (the real one needs a device).
  @visibleForTesting
  static int? debugAndroidSdkOverride;

  // ── OS mapping (plugin details stay below this line) ─────────────────────

  // iOS location uses Geolocator: the Podfile deliberately leaves
  // PERMISSION_LOCATION unset (it would link the "Always" API App Review
  // rejected), and without it permission_handler reports location as denied.
  static bool _useGeolocator(AppPermission p) =>
      p == AppPermission.location &&
      defaultTargetPlatform == TargetPlatform.iOS;

  static Future<AppPermissionStatus> _osCheck(AppPermission p) async =>
      _useGeolocator(p)
      ? _fromGeolocator(await Geolocator.checkPermission())
      : _fromHandler(await _handlerPermission(p).status);

  static Future<AppPermissionStatus> _osRequest(AppPermission p) async =>
      _useGeolocator(p)
      ? _fromGeolocator(await Geolocator.requestPermission())
      : _fromHandler(await _handlerPermission(p).request());

  /// Android only: the user refused once, so explain before asking again.
  /// iOS never needs it — one refusal there is already final.
  static Future<bool> _shouldExplainFirst(AppPermission p) async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _handlerPermission(p).shouldShowRequestRationale;
    } catch (_) {
      return false;
    }
  }

  static ph.Permission _handlerPermission(AppPermission p) {
    switch (p) {
      case AppPermission.camera:
        return ph.Permission.camera;
      case AppPermission.location:
        return ph.Permission.locationWhenInUse;
      case AppPermission.notifications:
        return ph.Permission.notification;
    }
  }

  static AppPermissionStatus _fromHandler(ph.PermissionStatus s) {
    switch (s) {
      case ph.PermissionStatus.granted:
      case ph.PermissionStatus.limited:
      case ph.PermissionStatus.provisional:
        return AppPermissionStatus.granted;
      case ph.PermissionStatus.denied:
        return AppPermissionStatus.denied;
      case ph.PermissionStatus.permanentlyDenied:
        return AppPermissionStatus.permanentlyDenied;
      case ph.PermissionStatus.restricted:
        return AppPermissionStatus.restricted;
    }
  }

  static AppPermissionStatus _fromGeolocator(LocationPermission s) {
    switch (s) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return AppPermissionStatus.granted;
      case LocationPermission.deniedForever:
        return AppPermissionStatus.permanentlyDenied;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return AppPermissionStatus.denied;
    }
  }

  /// Android 12 and below have no notification dialog: notifications are on
  /// unless switched off in Settings, and only Settings can switch them back.
  /// The plugin calls that "denied", which would make us ask with a dialog
  /// that never appears.
  static Future<AppPermissionStatus> _adjust(
    AppPermission p,
    AppPermissionStatus s,
  ) async {
    if (p == AppPermission.notifications &&
        s == AppPermissionStatus.denied &&
        defaultTargetPlatform == TargetPlatform.android &&
        await _androidSdk() < 33) {
      return AppPermissionStatus.permanentlyDenied;
    }
    return s;
  }

  static Future<int>? _androidSdkFuture;

  static Future<int> _androidSdk() {
    final override = debugAndroidSdkOverride;
    if (override != null) return Future.value(override);
    return _androidSdkFuture ??= DeviceInfoPlugin().androidInfo.then(
      (info) => info.version.sdkInt,
    );
  }

  static Future<void>? _inFlight;

  /// Lock released in `finally`, so one failed request never blocks the next.
  static Future<T> _oneAtATime<T>(Future<T> Function() task) async {
    while (_inFlight != null) {
      await _inFlight;
    }
    final done = Completer<void>();
    _inFlight = done.future;
    try {
      return await task();
    } finally {
      _inFlight = null;
      done.complete();
    }
  }

  static Future<bool?> _showSheet(BuildContext context, _Copy copy) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _PermissionSheet(
        copy: copy,
        onConfirm: () => Navigator.pop(sheetContext, true),
        onCancel: () => Navigator.pop(sheetContext, false),
      ),
    );
  }
}

/// The permissions the app knows how to ask for.
///
/// Each one also needs native setup, or the OS reports it as denied forever:
///
/// | Permission      | Android (AndroidManifest.xml)        | iOS                                                 |
/// |-----------------|--------------------------------------|-----------------------------------------------------|
/// | [camera]        | CAMERA (merged in by the QR plugin)  | NSCameraUsageDescription + Podfile `PERMISSION_CAMERA=1` |
/// | [location]      | ACCESS_FINE/COARSE_LOCATION          | NSLocationWhenInUseUsageDescription (no Podfile flag) |
/// | [notifications] | POST_NOTIFICATIONS                   | Podfile `PERMISSION_NOTIFICATIONS=1`                |
///
/// To add one: add it here (with its native setup), then fix the compile
/// errors — the `switch`es in this file are exhaustive, so the compiler
/// points at each line that needs adding.
enum AppPermission {
  camera('Camera', Icons.photo_camera_outlined),

  /// Foreground ("While using the app") only — enough to check the user is
  /// at school when they sign in. Background location is not used.
  location('Location', Icons.location_on_outlined),

  notifications('Notifications', Icons.notifications_outlined);

  const AppPermission(this.label, this.icon);

  /// The name the OS uses in Settings, so our steps match what users see.
  final String label;
  final IconData icon;
}

enum AppPermissionStatus {
  /// Usable (includes iOS "limited" / "provisional").
  granted,

  /// Not granted yet; asking again shows the OS dialog.
  denied,

  /// The OS won't show its dialog again — only Settings can fix it.
  permanentlyDenied,

  /// Blocked by the device owner (Screen Time, company MDM). The user can't
  /// change it, so don't send them to Settings.
  restricted;

  bool get isGranted => this == granted;
}

/// Rebuilds with the live status of [permission] — for UI that should look
/// disabled until it is granted. Re-checks when the app returns from
/// Settings and after any [PermissionManager.request].
///
/// ```dart
/// PermissionBuilder(
///   permission: AppPermission.camera,
///   builder: (context, status) {
///     final allowed = status?.isGranted ?? false;
///     return Opacity(
///       opacity: allowed ? 1 : 0.5, // looks disabled…
///       child: ListTile(
///         title: const Text('Scan QR code'),
///         // …but stays tappable, to explain why and offer the fix.
///         onTap: allowed
///             ? openScanner
///             : () => PermissionManager.ensure(context, AppPermission.camera),
///       ),
///     );
///   },
/// )
/// ```
class PermissionBuilder extends StatefulWidget {
  const PermissionBuilder({
    required this.permission,
    required this.builder,
    super.key,
  });

  final AppPermission permission;

  /// `status` is null only during the first check (a few ms).
  final Widget Function(BuildContext context, AppPermissionStatus? status)
  builder;

  @override
  State<PermissionBuilder> createState() => _PermissionBuilderState();
}

class _PermissionBuilderState extends State<PermissionBuilder> {
  AppPermissionStatus? _status;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    PermissionManager.changes.addListener(_refresh);
    _refresh();
  }

  @override
  void didUpdateWidget(PermissionBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.permission != widget.permission) _refresh();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    PermissionManager.changes.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _refresh() async {
    final permission = widget.permission;
    final status = await PermissionManager.status(permission);
    // Drop a stale answer if the widget moved on while we waited.
    if (!mounted || permission != widget.permission || status == _status) {
      return;
    }
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _status);
}

// ── Private: sheet copy and UI ──────────────────────────────────────────────

class _ChangeSignal extends ChangeNotifier {
  void notify() => notifyListeners();
}

class _Copy {
  const _Copy({
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.steps = const [],
    this.showCancel = true,
  });

  factory _Copy.rationale(AppPermission p, String? reason) => _Copy(
    icon: p.icon,
    title: 'Allow ${p.label.toLowerCase()} access',
    message: '${_needs(p, reason)} You can change this any time in Settings.',
    confirmLabel: 'Continue',
  );

  factory _Copy.settings(AppPermission p, String? reason) => _Copy(
    icon: p.icon,
    title: '${p.label} access is off',
    message: '${_needs(p, reason)} Turn it on in Settings:',
    steps: [..._steps(p), 'Come back to WowCare and try again.'],
    confirmLabel: 'Open Settings',
  );

  factory _Copy.restricted(AppPermission p) => _Copy(
    icon: p.icon,
    title: '${p.label} is blocked on this device',
    message:
        'Screen Time or your organisation\'s device policy is blocking '
        '${p.label.toLowerCase()} access, so it can\'t be turned on from '
        'WowCare. Ask whoever manages this device to allow it.',
    confirmLabel: 'OK',
    showCancel: false,
  );

  final IconData icon;
  final String title;
  final String message;
  final List<String> steps;
  final String confirmLabel;
  final bool showCancel;

  static String _needs(AppPermission p, String? reason) {
    final name = p.label.toLowerCase();
    return reason == null
        ? 'WowCare needs $name access for this feature.'
        : 'WowCare needs $name access $reason.';
  }

  /// What to tap once "Open Settings" lands on WowCare's page. Android
  /// wording is stock (Pixel); most manufacturers match it.
  static List<String> _steps(AppPermission p) {
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
}

class _PermissionSheet extends StatelessWidget {
  const _PermissionSheet({
    required this.copy,
    required this.onConfirm,
    required this.onCancel,
  });

  final _Copy copy;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    // Colours come from the theme, so the sheet follows the active app skin.
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
