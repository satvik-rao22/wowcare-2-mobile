// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_update_config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppUpdateConfigModel _$AppUpdateConfigModelFromJson(
  Map<String, dynamic> json,
) => AppUpdateConfigModel(
  androidMinimumBuildVersion: json['android_minimum_build_version'] == null
      ? _noBuild
      : AppUpdateConfigModel._buildNumber(
          json['android_minimum_build_version'],
        ),
  androidLatestBuildVersion: json['android_latest_build_version'] == null
      ? _noBuild
      : AppUpdateConfigModel._buildNumber(json['android_latest_build_version']),
  androidLatestVersionName: json['android_latest_version_name'] == null
      ? ''
      : AppUpdateConfigModel._text(json['android_latest_version_name']),
  androidUpdateTitle: json['android_update_title'] == null
      ? ''
      : AppUpdateConfigModel._text(json['android_update_title']),
  androidUpdateDescription: json['android_update_description'] == null
      ? ''
      : AppUpdateConfigModel._text(json['android_update_description']),
  androidUpdateUrl: json['android_update_url'] == null
      ? ''
      : AppUpdateConfigModel._text(json['android_update_url']),
  iosMinimumBuildVersion: json['ios_minimum_build_version'] == null
      ? _noBuild
      : AppUpdateConfigModel._buildNumber(json['ios_minimum_build_version']),
  iosLatestBuildVersion: json['ios_latest_build_version'] == null
      ? _noBuild
      : AppUpdateConfigModel._buildNumber(json['ios_latest_build_version']),
  iosLatestVersionName: json['ios_latest_version_name'] == null
      ? ''
      : AppUpdateConfigModel._text(json['ios_latest_version_name']),
  iosUpdateTitle: json['ios_update_title'] == null
      ? ''
      : AppUpdateConfigModel._text(json['ios_update_title']),
  iosUpdateDescription: json['ios_update_description'] == null
      ? ''
      : AppUpdateConfigModel._text(json['ios_update_description']),
  iosUpdateUrl: json['ios_update_url'] == null
      ? ''
      : AppUpdateConfigModel._text(json['ios_update_url']),
);

Map<String, dynamic> _$AppUpdateConfigModelToJson(
  AppUpdateConfigModel instance,
) => <String, dynamic>{
  'android_minimum_build_version': instance.androidMinimumBuildVersion,
  'android_latest_build_version': instance.androidLatestBuildVersion,
  'android_latest_version_name': instance.androidLatestVersionName,
  'android_update_title': instance.androidUpdateTitle,
  'android_update_description': instance.androidUpdateDescription,
  'android_update_url': instance.androidUpdateUrl,
  'ios_minimum_build_version': instance.iosMinimumBuildVersion,
  'ios_latest_build_version': instance.iosLatestBuildVersion,
  'ios_latest_version_name': instance.iosLatestVersionName,
  'ios_update_title': instance.iosUpdateTitle,
  'ios_update_description': instance.iosUpdateDescription,
  'ios_update_url': instance.iosUpdateUrl,
};
