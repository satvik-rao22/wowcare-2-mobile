import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_update_config_model.g.dart';

/// The build number read when a key is missing or unreadable. No real build
/// is below it, so a half-written config asks nothing of anyone.
const int _noBuild = 1;

/// The `app_update_config` Remote Config value: one JSON object carrying
/// the rule for both platforms.
///
/// ```json
/// {
///   "android_minimum_build_version": 20,
///   "android_latest_build_version": 26,
///   "android_latest_version_name": "2.3.0",
///   "android_update_url": "https://play.google.com/store/apps/details?id=com.wiseowl.wowcareapp",
///   "ios_minimum_build_version": 20,
///   "ios_latest_build_version": 26,
///   "ios_latest_version_name": "2.3.0",
///   "ios_update_url": "https://apps.apple.com/app/id6760719887"
/// }
/// ```
///
/// The key names are the ones `feature/app-update` shipped with, so a value
/// already published in the console keeps working. `*_latest_version_name`
/// is new: the banners name the version the store will install. The old
/// `*_update_features` list is not read, because the design shows no
/// what's-new list.
///
/// Every field is optional; a missing build number reads as [_noBuild].
/// Numbers typed into the console as strings (`"26"`) are accepted too,
/// since a quoted minimum that silently failed to apply would be the worst
/// outcome.
@JsonSerializable(fieldRename: FieldRename.snake)
class AppUpdateConfigModel extends Equatable {
  const AppUpdateConfigModel({
    this.androidMinimumBuildVersion = _noBuild,
    this.androidLatestBuildVersion = _noBuild,
    this.androidLatestVersionName = '',
    this.androidUpdateTitle = '',
    this.androidUpdateDescription = '',
    this.androidUpdateUrl = '',
    this.iosMinimumBuildVersion = _noBuild,
    this.iosLatestBuildVersion = _noBuild,
    this.iosLatestVersionName = '',
    this.iosUpdateTitle = '',
    this.iosUpdateDescription = '',
    this.iosUpdateUrl = '',
  });

  factory AppUpdateConfigModel.fromJson(Map<String, dynamic> json) =>
      _$AppUpdateConfigModelFromJson(json);

  /// The value read when the key is unset or unreadable.
  static const AppUpdateConfigModel empty = AppUpdateConfigModel();

  @JsonKey(fromJson: _buildNumber)
  final int androidMinimumBuildVersion;

  @JsonKey(fromJson: _buildNumber)
  final int androidLatestBuildVersion;

  @JsonKey(fromJson: _text)
  final String androidLatestVersionName;

  @JsonKey(fromJson: _text)
  final String androidUpdateTitle;

  @JsonKey(fromJson: _text)
  final String androidUpdateDescription;

  @JsonKey(fromJson: _text)
  final String androidUpdateUrl;

  @JsonKey(fromJson: _buildNumber)
  final int iosMinimumBuildVersion;

  @JsonKey(fromJson: _buildNumber)
  final int iosLatestBuildVersion;

  @JsonKey(fromJson: _text)
  final String iosLatestVersionName;

  @JsonKey(fromJson: _text)
  final String iosUpdateTitle;

  @JsonKey(fromJson: _text)
  final String iosUpdateDescription;

  @JsonKey(fromJson: _text)
  final String iosUpdateUrl;

  Map<String, dynamic> toJson() => _$AppUpdateConfigModelToJson(this);

  static int _buildNumber(Object? value) => switch (value) {
    final num n => n.toInt(),
    final String s => int.tryParse(s.trim()) ?? _noBuild,
    _ => _noBuild,
  };

  static String _text(Object? value) => value is String ? value.trim() : '';

  @override
  List<Object?> get props => [
    androidMinimumBuildVersion,
    androidLatestBuildVersion,
    androidLatestVersionName,
    androidUpdateTitle,
    androidUpdateDescription,
    androidUpdateUrl,
    iosMinimumBuildVersion,
    iosLatestBuildVersion,
    iosLatestVersionName,
    iosUpdateTitle,
    iosUpdateDescription,
    iosUpdateUrl,
  ];
}
