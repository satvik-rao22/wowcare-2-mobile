import 'package:wowcare/domain/features/app_update/entities/app_update_policy.dart';
import 'package:wowcare/domain/features/app_update/entities/app_update_status.dart';
import 'package:wowcare/domain/features/app_update/entities/app_version.dart';

/// Everything the update check needs from outside the domain. No method
/// throws: each one falls back to the answer that never blocks the user.
abstract interface class AppUpdateRepository {
  /// The store this build belongs to.
  StorePlatform get store;

  /// The installed version. Build 0 when it cannot be read.
  Future<AppVersion> getInstalledVersion();

  /// The published rule. [refresh] fetches from the network first; without
  /// it the last fetched rule is used, which needs no network at all.
  /// [AppUpdatePolicy.none] when the rule is missing or unreadable.
  Future<AppUpdatePolicy> getPolicy({required bool refresh});

  /// When the optional update to [latestBuild] was last dismissed, or null
  /// if it never was. A dismissal of an older build does not count.
  Future<DateTime?> optionalDismissedAt({required int latestBuild});

  /// Remembers that the optional update to [latestBuild] was dismissed.
  Future<void> saveOptionalDismissal({
    required int latestBuild,
    required DateTime at,
  });

  /// Opens the store listing at [url], or this app's own listing when [url]
  /// is null. False when nothing could be opened.
  Future<bool> openStore(String? url);
}
