import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

class RemoteConfigUtil {
  // ----- Singleton -----
  RemoteConfigUtil._internal();
  static final RemoteConfigUtil instance = RemoteConfigUtil._internal();

  final FirebaseRemoteConfig _rc = FirebaseRemoteConfig.instance;

  // ----- Keys + Defaults -----
  static const String _kAppUpdateConfig = 'app_update_config';

  static const Map<String, dynamic> _defaults = {
    _kAppUpdateConfig: '{}', // JSON object
  };

  // ----- Init -----
  Future<void> init() async {
    try {
      await _rc.setDefaults(_defaults);

      await _rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(minutes: 15),
        ),
      );

      await _rc.fetchAndActivate();
    } on Exception catch (e) {
      debugPrint('RemoteConfig init failed: $e');
    }
  }

  // ----- Public Getters  -----

  AppUpdateConfig get appUpdateConfig {
    // MOCK VALUES FOR TESTING
    // return AppUpdateConfig(
    //   androidMinimumBuildVersion: 53,
    //   androidLatestBuildVersion: 56,
    //   iosMinimumBuildVersion: 53,
    //   iosLatestBuildVersion: 56,
    // );

    final raw = _rc.getString(_kAppUpdateConfig);
    try {
      print('<<<<<<<<<<<<<<<<<<<<<object ${jsonDecode(raw)}>>>>>>>>>>>>>>>>>>>>>');
      return AppUpdateConfig.fromJson(jsonDecode(raw));
    } catch (e, s) {
      return AppUpdateConfig();
    }
  }
}
class AppUpdateConfig {
  int androidMinimumBuildVersion;
  int androidLatestBuildVersion;
  String androidUpdateTitle;
  String androidUpdateDescription;
  List<String> androidUpdateFeatures;
  String androidUpdateUrl;

  int iosMinimumBuildVersion;
  int iosLatestBuildVersion;
  String iosUpdateTitle;
  String iosUpdateDescription;
  List<String> iosUpdateFeatures;
  String iosUpdateUrl;

  AppUpdateConfig({
    this.androidMinimumBuildVersion = 1,
    this.androidLatestBuildVersion = 1,
    this.androidUpdateTitle = '',
    this.androidUpdateDescription = '',
    this.androidUpdateFeatures = const [],
    this.androidUpdateUrl = '',
    this.iosMinimumBuildVersion = 1,
    this.iosLatestBuildVersion = 1,
    this.iosUpdateTitle = '',
    this.iosUpdateDescription = '',
    this.iosUpdateFeatures = const [],
    this.iosUpdateUrl = '',
  });

  factory AppUpdateConfig.fromJson(Map<String, dynamic> json) =>
      AppUpdateConfig(
        androidMinimumBuildVersion:
        json["android_minimum_build_version"] ?? 1,
        androidLatestBuildVersion:
        json["android_latest_build_version"] ?? 1,
        androidUpdateTitle:
        json["android_update_title"] ?? '',
        androidUpdateDescription:
        json["android_update_description"] ?? '',
        androidUpdateFeatures:
        List<String>.from(json["android_update_features"] ?? []),
        androidUpdateUrl:
        json["android_update_url"] ?? '',

        iosMinimumBuildVersion:
        json["ios_minimum_build_version"] ?? 1,
        iosLatestBuildVersion:
        json["ios_latest_build_version"] ?? 1,
        iosUpdateTitle:
        json["ios_update_title"] ?? '',
        iosUpdateDescription:
        json["ios_update_description"] ?? '',
        iosUpdateFeatures:
        List<String>.from(json["ios_update_features"] ?? []),
        iosUpdateUrl:
        json["ios_update_url"] ?? '',
      );
}
