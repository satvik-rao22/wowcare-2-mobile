import 'package:wowcare/data/features/app_update/models/app_update_config_model.dart';
import 'package:wowcare/domain/features/app_update/entities/app_update_policy.dart';
import 'package:wowcare/domain/features/app_update/entities/app_update_status.dart';

extension AppUpdateConfigMapper on AppUpdateConfigModel {
  /// The half of the config that applies to [store]. Blank strings become
  /// null, so the banner falls back to its designed copy.
  AppUpdatePolicy toPolicy(StorePlatform store) => switch (store) {
    StorePlatform.appStore => AppUpdatePolicy(
      minimumBuild: iosMinimumBuildVersion,
      latestBuild: iosLatestBuildVersion,
      latestVersionName: _orNull(iosLatestVersionName),
      storeUrl: _orNull(iosUpdateUrl),
      title: _orNull(iosUpdateTitle),
      message: _orNull(iosUpdateDescription),
    ),
    StorePlatform.playStore => AppUpdatePolicy(
      minimumBuild: androidMinimumBuildVersion,
      latestBuild: androidLatestBuildVersion,
      latestVersionName: _orNull(androidLatestVersionName),
      storeUrl: _orNull(androidUpdateUrl),
      title: _orNull(androidUpdateTitle),
      message: _orNull(androidUpdateDescription),
    ),
  };
}

String? _orNull(String value) => value.isEmpty ? null : value;
