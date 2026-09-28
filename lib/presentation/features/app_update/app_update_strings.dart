import 'package:wowcare/domain/features/app_update/entities/app_update_status.dart';

/// User-visible copy for the two update banners, from *WowCare System
/// Messages* S1 (optional) and S2 (required).
///
/// Both keys name the store they open rather than saying "Update", so nobody
/// wonders where they are about to be sent. Remote Config's
/// `*_update_title` and `*_update_description` replace [optionalTitle] /
/// [requiredTitle] and [optionalFoot] / [requiredBody] when they are set.
class AppUpdateStrings {
  const AppUpdateStrings._();

  // ── Optional (S1) ──────────────────────────────────────────────────────────

  static const String optionalEyebrow = 'A new one is on the shelf';

  static String optionalTitle(String? version) => version == null
      ? 'A new WowCare is waiting'
      : 'WowCare $version is waiting';

  static String youAreOn(String version) => 'You are on $version';

  static const String optionalFoot = 'About a minute on the school wifi.';

  static const String notNow = 'Not now';

  static const String dismiss = 'Dismiss the update banner';

  static String updateIn(StorePlatform store) => switch (store) {
    StorePlatform.appStore => 'Update in the App Store',
    StorePlatform.playStore => 'Update in Google Play',
  };

  // ── Required (S2) ──────────────────────────────────────────────────────────

  static const String requiredEyebrow = 'This one has clocked off';

  static String requiredTitle(String? version) => version == null
      ? 'Time to swap it for the new WowCare'
      : 'Time to swap it for WowCare $version';

  static const String requiredBody =
      'The school cannot hear this version any more.';

  /// The version the store will install, when the config does not name it.
  static const String latestVersion = 'Latest';

  static String getFrom(StorePlatform store, String? version) {
    final String app = version == null ? 'the new WowCare' : 'WowCare $version';
    return switch (store) {
      StorePlatform.appStore => 'Get $app from the App Store',
      StorePlatform.playStore => 'Get $app from Google Play',
    };
  }

  // ── Both ───────────────────────────────────────────────────────────────────

  static String storeUnavailable(StorePlatform store) => switch (store) {
    StorePlatform.appStore =>
      "Couldn't open the App Store. Open it and search for WowCare.",
    StorePlatform.playStore =>
      "Couldn't open Google Play. Open it and search for WowCare.",
  };
}
