import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:wowcare/core/utils/logger_service.dart';

import 'app_permission.dart';

/// The one place the app talks to the OS about runtime permissions.
///
/// No setup and no BuildContext — call it from a widget, cubit or repository:
///
/// ```dart
/// if (await PermissionManager.isGranted(AppPermission.camera)) { ... }
/// final status = await PermissionManager.request(AppPermission.notifications);
/// ```
///
/// This class never shows app UI. When a screen wants the full "explain, ask,
/// or send to Settings" flow, use `PermissionPrompt.ensure` instead.
///
/// The plugins behind it (permission_handler, Geolocator) are hidden here, so
/// swapping or upgrading one only touches this file.
///
/// Not covered: whether the device's location *service* (GPS) is on — that is
/// a device setting, not a permission; ask Geolocator.isLocationServiceEnabled.
abstract final class PermissionManager {
  /// Fires after every [request], so a `PermissionBuilder` showing the same
  /// permission elsewhere on screen can re-check.
  static Listenable get changes => _changes;
  static final _ChangeSignal _changes = _ChangeSignal();

  /// Reads the current status. Never shows a dialog.
  ///
  /// Never throws: a plugin failure is logged and reported as
  /// [AppPermissionStatus.denied], so callers stay on their "not allowed"
  /// path instead of crashing.
  static Future<AppPermissionStatus> status(AppPermission permission) async {
    try {
      return await _adjustForPlatform(permission, await _check(permission));
    } catch (e, s) {
      AppLogger.e('[Permission] status($permission) failed', e, s);
      return AppPermissionStatus.denied;
    }
  }

  static Future<bool> isGranted(AppPermission permission) async =>
      (await status(permission)).isGranted;

  /// Shows the OS dialog if the OS still allows it, and returns the outcome.
  ///
  /// Already granted → returns immediately without a dialog. Requests are
  /// queued: two screens asking at once would otherwise make the plugin throw
  /// "a request is already running".
  static Future<AppPermissionStatus> request(AppPermission permission) {
    return _serialized(() async {
      try {
        final current = await status(permission);
        if (current.isGranted || current == AppPermissionStatus.restricted) {
          return current;
        }
        final result = await _adjustForPlatform(
          permission,
          await _request(permission),
        );
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

  /// Android only: true when the user has refused once and the OS recommends
  /// explaining why before asking again. Always false on iOS, where one
  /// refusal is already final.
  static Future<bool> shouldExplainBeforeAsking(
    AppPermission permission,
  ) async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _handlerPermission(permission).shouldShowRequestRationale;
    } catch (e, s) {
      AppLogger.e('[Permission] rationale($permission) failed', e, s);
      return false;
    }
  }

  /// Opens this app's page in the system Settings. Returns false if the OS
  /// could not open it.
  static Future<bool> openSettings() async {
    try {
      return await ph.openAppSettings();
    } catch (e, s) {
      AppLogger.e('[Permission] openSettings failed', e, s);
      return false;
    }
  }

  // ── OS mapping ────────────────────────────────────────────────────────────
  // Everything below is plugin-specific. Keep plugin types from leaking out.

  // iOS location goes through Geolocator, not permission_handler: the Podfile
  // deliberately leaves PERMISSION_LOCATION unset (it would link the "Always"
  // API App Review rejected), and without it permission_handler reports
  // location as denied on iOS. Same split as GeofencingLocalDataSource.
  static bool get _useGeolocator => defaultTargetPlatform == TargetPlatform.iOS;

  static Future<AppPermissionStatus> _check(AppPermission permission) async {
    if (permission == AppPermission.location && _useGeolocator) {
      return _fromGeolocator(await Geolocator.checkPermission());
    }
    return _fromHandler(await _handlerPermission(permission).status);
  }

  static Future<AppPermissionStatus> _request(AppPermission permission) async {
    if (permission == AppPermission.location && _useGeolocator) {
      return _fromGeolocator(await Geolocator.requestPermission());
    }
    return _fromHandler(await _handlerPermission(permission).request());
  }

  static ph.Permission _handlerPermission(AppPermission permission) {
    switch (permission) {
      case AppPermission.camera:
        return ph.Permission.camera;
      case AppPermission.location:
        return ph.Permission.locationWhenInUse;
      case AppPermission.notifications:
        return ph.Permission.notification;
    }
  }

  static AppPermissionStatus _fromHandler(ph.PermissionStatus status) {
    switch (status) {
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

  static AppPermissionStatus _fromGeolocator(LocationPermission permission) {
    switch (permission) {
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

  /// OS quirks the plugins report literally but a feature should not.
  static Future<AppPermissionStatus> _adjustForPlatform(
    AppPermission permission,
    AppPermissionStatus status,
  ) async {
    // Android 12 and below have no notification dialog: notifications are on
    // unless the user switched them off in Settings, and only Settings can
    // switch them back on. The plugin calls that "denied", which would make
    // us keep asking with a dialog that never appears.
    if (permission == AppPermission.notifications &&
        status == AppPermissionStatus.denied &&
        defaultTargetPlatform == TargetPlatform.android &&
        await _androidSdk() < 33) {
      return AppPermissionStatus.permanentlyDenied;
    }
    return status;
  }

  static Future<int>? _androidSdkFuture;

  /// Overrides the Android API level in tests (the real one needs a device).
  @visibleForTesting
  static int? debugAndroidSdkOverride;

  static Future<int> _androidSdk() {
    final override = debugAndroidSdkOverride;
    if (override != null) return Future.value(override);
    return _androidSdkFuture ??= DeviceInfoPlugin().androidInfo.then(
      (info) => info.version.sdkInt,
    );
  }

  static Future<void>? _inFlight;

  /// Runs [task] once no other request is in flight. The lock is released in
  /// `finally`, so one failed request can never block the ones after it.
  static Future<T> _serialized<T>(Future<T> Function() task) async {
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
}

/// [ChangeNotifier.notifyListeners] is protected; this exposes it to the
/// manager only.
class _ChangeSignal extends ChangeNotifier {
  void notify() => notifyListeners();
}
