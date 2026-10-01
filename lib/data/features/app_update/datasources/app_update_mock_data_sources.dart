import 'package:flutter/foundation.dart';
import 'package:wowcare/core/utils/api_constants.dart';
import 'package:wowcare/data/features/app_update/datasources/app_update_local_data_source.dart';
import 'package:wowcare/data/features/app_update/datasources/app_update_platform_data_source.dart';
import 'package:wowcare/data/features/app_update/datasources/app_update_remote_data_source.dart';
import 'package:wowcare/data/features/app_update/models/app_update_config_model.dart';

/// Test switch for the two update banners. No Firebase console needed.
///
/// Either flip [inCode] below and hot restart, or leave it alone and pass
/// the mode at launch, which wins over [inCode]:
///
/// ```sh
/// flutter run --dart-define=APP_UPDATE_MOCK=optional
/// flutter run --dart-define=APP_UPDATE_MOCK=required
/// ```
///
/// While a mock is on, Remote Config is not read at all: the rule is made up
/// against whatever build is installed, one build ahead of it. "Not now" on
/// the optional banner is remembered for the session only, so it is back on
/// the next launch and can be tested again. Real dismissals are untouched.
///
/// A PROD release build ignores this switch, so a mode left on by accident
/// cannot reach the store.
enum AppUpdateMock {
  off,

  /// The dismissible banner, inside the dashboard.
  optional,

  /// The blocking overlay, over every screen.
  required;

  /// Flip this to test in code. Keep it [off] in commits.
  static const AppUpdateMock inCode = AppUpdateMock.off;

  static const String _fromDefine = String.fromEnvironment('APP_UPDATE_MOCK');

  static AppUpdateMock get active {
    if (kReleaseMode && ApiConstants.isProd) return off;
    return values.asNameMap()[_fromDefine] ?? inCode;
  }
}

/// Stands in for Remote Config while [AppUpdateMock] is on.
class MockAppUpdateRemoteDataSource implements AppUpdateRemoteDataSource {
  MockAppUpdateRemoteDataSource(this._mode, this._platform)
    : assert(_mode != AppUpdateMock.off, 'Use the real data source when off');

  final AppUpdateMock _mode;
  final AppUpdatePlatformDataSource _platform;

  @override
  Future<AppUpdateConfigModel> getConfig({required bool refresh}) async {
    final InstalledApp app = await _platform.readInstalledApp();
    final bool required = _mode == AppUpdateMock.required;
    final int next = app.buildNumber + 1;
    final int minimum = required ? next : app.buildNumber;
    final String name = _nextVersionName(app.versionName, major: required);
    // Store URLs are left blank on purpose, so the key exercises the same
    // own-listing fallback a half-written config would.
    return AppUpdateConfigModel(
      androidMinimumBuildVersion: minimum,
      androidLatestBuildVersion: next,
      androidLatestVersionName: name,
      iosMinimumBuildVersion: minimum,
      iosLatestBuildVersion: next,
      iosLatestVersionName: name,
    );
  }

  /// `2.2.21` becomes `2.3.0`, or `3.0.0` for the required banner, so each
  /// mock reads like the release it pretends to be.
  static String _nextVersionName(String current, {required bool major}) {
    final List<int> parts = current
        .split('.')
        .map((String p) => int.tryParse(p) ?? 0)
        .toList();
    final int maj = parts.isNotEmpty ? parts[0] : 0;
    final int min = parts.length > 1 ? parts[1] : 0;
    return major ? '${maj + 1}.0.0' : '$maj.${min + 1}.0';
  }
}

/// Session-only dismissals while [AppUpdateMock] is on.
class InMemoryAppUpdateLocalDataSource implements AppUpdateLocalDataSource {
  ({int latestBuild, DateTime at})? _dismissal;

  @override
  Future<({int latestBuild, DateTime at})?> readDismissal() async => _dismissal;

  @override
  Future<void> saveDismissal({
    required int latestBuild,
    required DateTime at,
  }) async => _dismissal = (latestBuild: latestBuild, at: at);
}
