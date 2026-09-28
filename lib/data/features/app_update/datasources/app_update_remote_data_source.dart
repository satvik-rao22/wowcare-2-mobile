import 'dart:convert';

import 'package:wowcare/core/firebase/remote_config_service.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/data/features/app_update/models/app_update_config_model.dart';

/// Reads the update rule. Never throws: an unset or malformed value reads as
/// [AppUpdateConfigModel.empty], which asks nothing of anyone.
abstract interface class AppUpdateRemoteDataSource {
  Future<AppUpdateConfigModel> getConfig({required bool refresh});
}

class AppUpdateRemoteDataSourceImpl implements AppUpdateRemoteDataSource {
  AppUpdateRemoteDataSourceImpl(this._remoteConfig);

  final RemoteConfigService _remoteConfig;

  /// The Remote Config parameter, as `feature/app-update` named it.
  static const String configKey = 'app_update_config';

  @override
  Future<AppUpdateConfigModel> getConfig({required bool refresh}) async {
    await (refresh
        ? _remoteConfig.fetchAndActivate()
        : _remoteConfig.activateCached());
    return parse(_remoteConfig.getString(configKey));
  }

  /// Public for the parsing tests.
  static AppUpdateConfigModel parse(String raw) {
    if (raw.trim().isEmpty) return AppUpdateConfigModel.empty;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AppUpdateConfigModel.fromJson(decoded);
      }
      AppLogger.w('[AppUpdate] $configKey is not a JSON object; ignoring it');
    } on FormatException catch (e) {
      AppLogger.w('[AppUpdate] $configKey is not valid JSON; ignoring it: $e');
    }
    return AppUpdateConfigModel.empty;
  }
}
