import 'package:equatable/equatable.dart';

/// How strongly this install is asked to update.
enum AppUpdateRequirement {
  /// On the latest build, or the rule could not be read.
  none,

  /// A newer build exists. The banner can be dismissed.
  optional,

  /// Below the minimum build. The app is covered until it is updated.
  required,
}

/// The update rule Remote Config publishes for this platform.
class AppUpdatePolicy extends Equatable {
  const AppUpdatePolicy({
    required this.minimumBuild,
    required this.latestBuild,
    this.latestVersionName,
    this.storeUrl,
    this.title,
    this.message,
  });

  /// A policy that asks nothing of anyone. Used whenever the rule is
  /// missing or unreadable, so a broken config can never lock people out.
  static const AppUpdatePolicy none = AppUpdatePolicy(
    minimumBuild: 0,
    latestBuild: 0,
  );

  /// Builds below this cannot keep running.
  final int minimumBuild;

  /// Builds below this are offered the update.
  final int latestBuild;

  /// The marketing version the store will install, e.g. `2.3.0`.
  final String? latestVersionName;

  /// The store listing. Null when the config leaves it blank.
  final String? storeUrl;

  /// Replaces the banner's designed headline when set.
  final String? title;

  /// Replaces the banner's designed supporting line when set.
  final String? message;

  /// A build number of zero means the installed build could not be read.
  /// That is treated as up to date: failing closed would lock out every
  /// install whose platform plugin misbehaved.
  AppUpdateRequirement requirementFor(int installedBuild) {
    if (installedBuild <= 0) return AppUpdateRequirement.none;
    if (installedBuild < minimumBuild) return AppUpdateRequirement.required;
    if (installedBuild < latestBuild) return AppUpdateRequirement.optional;
    return AppUpdateRequirement.none;
  }

  @override
  List<Object?> get props => [
    minimumBuild,
    latestBuild,
    latestVersionName,
    storeUrl,
    title,
    message,
  ];
}
