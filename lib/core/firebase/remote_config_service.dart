import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/core/utils/logger_service.dart';

/// Firebase Remote Config behind an interface, so a feature reads its key
/// without knowing about Firebase and a test can hand in fixed values.
///
/// Neither method throws. A failed fetch leaves the last activated values in
/// place, which is what a caller wants on a bad network: yesterday's rule,
/// not no rule.
abstract interface class RemoteConfigService {
  /// Activates the values from the last successful fetch. No network, so it
  /// is safe on the startup path.
  Future<void> activateCached();

  /// Fetches fresh values and activates them. The SDK drops a fetch made
  /// within the minimum fetch interval, so calling this on every app resume
  /// costs nothing past the first.
  Future<void> fetchAndActivate();

  /// The activated value for [key], or an empty string when it is unset.
  String getString(String key);
}

class FirebaseRemoteConfigService implements RemoteConfigService {
  FirebaseRemoteConfigService(this._remoteConfig);

  final FirebaseRemoteConfig _remoteConfig;

  /// Debug builds fetch on every call, so a value changed in the console
  /// shows up on the next resume. Release builds wait 15 minutes between
  /// fetches, which bounds how long a new minimum version takes to land.
  static final Duration _minimumFetchInterval = kDebugMode
      ? Duration.zero
      : const Duration(minutes: 15);

  static const Duration _fetchTimeout = Duration(seconds: 10);

  Future<void>? _settings;

  Future<void> _applySettings() => _settings ??= _remoteConfig
      .setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: _fetchTimeout,
          minimumFetchInterval: _minimumFetchInterval,
        ),
      )
      .catchError((Object e) {
        // A failed settings call is retried on the next use.
        _settings = null;
        AppLogger.w('[RemoteConfig] settings not applied: $e');
      });

  @override
  Future<void> activateCached() async {
    try {
      await _applySettings();
      await _remoteConfig.activate();
    } catch (e) {
      AppLogger.w('[RemoteConfig] activate failed: $e');
    }
  }

  @override
  Future<void> fetchAndActivate() async {
    try {
      await _applySettings();
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      AppLogger.w('[RemoteConfig] fetch failed, keeping last values: $e');
    }
  }

  @override
  String getString(String key) => _remoteConfig.getString(key);
}
