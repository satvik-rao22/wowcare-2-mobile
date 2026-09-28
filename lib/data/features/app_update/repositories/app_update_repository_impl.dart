import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/data/features/app_update/datasources/app_update_local_data_source.dart';
import 'package:wowcare/data/features/app_update/datasources/app_update_platform_data_source.dart';
import 'package:wowcare/data/features/app_update/datasources/app_update_remote_data_source.dart';
import 'package:wowcare/data/features/app_update/mappers/app_update_config_mapper.dart';
import 'package:wowcare/domain/features/app_update/entities/app_update_policy.dart';
import 'package:wowcare/domain/features/app_update/entities/app_update_status.dart';
import 'package:wowcare/domain/features/app_update/entities/app_version.dart';
import 'package:wowcare/domain/features/app_update/repositories/app_update_repository.dart';

class AppUpdateRepositoryImpl implements AppUpdateRepository {
  AppUpdateRepositoryImpl({
    required AppUpdateRemoteDataSource remote,
    required AppUpdatePlatformDataSource platform,
    required AppUpdateLocalDataSource local,
  }) : _remote = remote,
       _platform = platform,
       _local = local;

  final AppUpdateRemoteDataSource _remote;
  final AppUpdatePlatformDataSource _platform;
  final AppUpdateLocalDataSource _local;

  /// WowCare 2 on the App Store, looked up by bundle id
  /// `com.wiseowl.wowcareapp`. Used when the config leaves `ios_update_url`
  /// blank; Android builds its listing from the package name instead.
  static const String _appStoreListing =
      'https://apps.apple.com/app/id6760719887';

  @override
  StorePlatform get store =>
      _platform.isIos ? StorePlatform.appStore : StorePlatform.playStore;

  @override
  Future<AppVersion> getInstalledVersion() async {
    try {
      final InstalledApp app = await _platform.readInstalledApp();
      return AppVersion(name: app.versionName, build: app.buildNumber);
    } catch (e) {
      AppLogger.w('[AppUpdate] installed version unreadable: $e');
      return const AppVersion(name: '', build: 0);
    }
  }

  @override
  Future<AppUpdatePolicy> getPolicy({required bool refresh}) async {
    try {
      final config = await _remote.getConfig(refresh: refresh);
      return config.toPolicy(store);
    } catch (e) {
      AppLogger.w('[AppUpdate] policy unreadable, asking nothing: $e');
      return AppUpdatePolicy.none;
    }
  }

  @override
  Future<DateTime?> optionalDismissedAt({required int latestBuild}) async {
    try {
      final dismissal = await _local.readDismissal();
      if (dismissal == null || dismissal.latestBuild != latestBuild) {
        return null;
      }
      return dismissal.at;
    } catch (e) {
      AppLogger.w('[AppUpdate] dismissal unreadable: $e');
      return null;
    }
  }

  @override
  Future<void> saveOptionalDismissal({
    required int latestBuild,
    required DateTime at,
  }) async {
    try {
      await _local.saveDismissal(latestBuild: latestBuild, at: at);
    } catch (e) {
      // The banner is already hidden for this session; only the week-long
      // memory of it is lost.
      AppLogger.w('[AppUpdate] dismissal not saved: $e');
    }
  }

  @override
  Future<bool> openStore(String? url) async {
    try {
      final Uri? uri = Uri.tryParse(url ?? await _ownListing());
      if (uri == null || !uri.hasScheme) return false;
      return await _platform.openExternal(uri);
    } catch (e) {
      AppLogger.w('[AppUpdate] store listing not opened: $e');
      return false;
    }
  }

  Future<String> _ownListing() async {
    if (_platform.isIos) return _appStoreListing;
    final InstalledApp app = await _platform.readInstalledApp();
    return 'https://play.google.com/store/apps/details?id=${app.packageName}';
  }
}
