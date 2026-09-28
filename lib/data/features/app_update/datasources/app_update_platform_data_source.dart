import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wowcare/core/utils/logger_service.dart';

/// The installed app, as the platform reports it.
typedef InstalledApp = ({
  String versionName,
  int buildNumber,
  String packageName,
});

/// The device side of the update check: what is installed, and a way out to
/// the store.
abstract interface class AppUpdatePlatformDataSource {
  bool get isIos;

  /// Build number 0 when the platform reports something unparseable.
  Future<InstalledApp> readInstalledApp();

  /// False when nothing could handle [uri].
  Future<bool> openExternal(Uri uri);
}

class AppUpdatePlatformDataSourceImpl implements AppUpdatePlatformDataSource {
  InstalledApp? _installed;

  @override
  bool get isIos => Platform.isIOS;

  @override
  Future<InstalledApp> readInstalledApp() async {
    final InstalledApp? cached = _installed;
    if (cached != null) return cached;
    final PackageInfo info = await PackageInfo.fromPlatform();
    return _installed = (
      versionName: info.version,
      buildNumber: int.tryParse(info.buildNumber) ?? 0,
      packageName: info.packageName,
    );
  }

  @override
  Future<bool> openExternal(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      AppLogger.w('[AppUpdate] could not open $uri: $e');
      return false;
    }
  }
}
