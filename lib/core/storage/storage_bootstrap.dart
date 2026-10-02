import 'package:wowcare/core/security/fresh_install_reset_service.dart';
import 'package:wowcare/core/security/install_marker.dart';
import 'package:wowcare/core/storage/legacy_shared_preferences_migrator.dart';
import 'package:wowcare/core/storage/secure_storage.dart';
import 'package:wowcare/core/utils/logger_service.dart';

enum StorageBootstrapOutcome {
  /// Legacy SharedPreferences data was promoted into the secure store.
  migrated,

  /// Nothing to migrate and the install marker exists: a normal launch.
  existingInstall,

  /// No install marker and no legacy data: a fresh install. The secure store
  /// was wiped so nothing from a previous install can leak into this one.
  freshInstall,

  /// The legacy store could not be opened. Nothing was changed, no marker was
  /// written, and the next launch runs the whole sequence again.
  deferred,

  /// An unexpected error. Logged; startup continues.
  failed,
}

/// Runs once per launch, before anything else touches storage, and settles
/// two questions the rest of the app must not have to think about.
///
/// **Is there legacy data to migrate?** Older builds kept everything in
/// `SharedPreferences`. If any of it is still there, it is promoted into the
/// secure store and this launch is, by definition, an upgrade of an existing
/// install — so the install marker is created and no wipe happens. The old
/// `app_installed_marker_v1` flag is honoured on the way: when it was absent,
/// the old code treated the launch as a fresh install and cleared the
/// "Remember me" credentials, and that is reproduced exactly.
///
/// **Is this a fresh install?** With no legacy data, [FreshInstallResetService]
/// decides from the [InstallMarker] file and wipes the secure store when the
/// marker is missing.
///
/// If the legacy store cannot be opened the launch is treated as unknown and
/// nothing is wiped — a transient plugin failure must never cost the user
/// their session.
class StorageBootstrap {
  StorageBootstrap({
    required LegacySharedPreferencesMigrator migrator,
    required InstallMarker installMarker,
    required SecureStorage secureStorage,
    required Future<void> Function() clearSecureCredentials,
    required Future<void> Function() clearRememberMe,
  }) : _migrator = migrator,
       _installMarker = installMarker,
       _clearRememberMe = clearRememberMe,
       _freshInstall = FreshInstallResetService(
         installMarker: installMarker,
         secureStorage: secureStorage,
         clearSecureCredentials: clearSecureCredentials,
       );

  final LegacySharedPreferencesMigrator _migrator;
  final InstallMarker _installMarker;
  final FreshInstallResetService _freshInstall;

  /// Clears only the "Remember me" credentials.
  final Future<void> Function() _clearRememberMe;

  Future<StorageBootstrapOutcome> run() async {
    try {
      final report = await _migrator.run();
      if (report.loadFailed) {
        AppLogger.w('[StorageBootstrap] legacy store unavailable; deferred');
        return StorageBootstrapOutcome.deferred;
      }

      if (report.hadLegacyData) {
        if (!report.hadInstallMarker) {
          // Exactly what the old marker check did on a launch without it.
          await _clearRememberMe();
        }
        await _installMarker.create();
        AppLogger.i(
          '[StorageBootstrap] upgraded existing install '
          '(migrated=${report.migrated}, failed=${report.failed})',
        );
        return StorageBootstrapOutcome.migrated;
      }

      return await _freshInstall.runIfFreshInstall()
          ? StorageBootstrapOutcome.freshInstall
          : StorageBootstrapOutcome.existingInstall;
    } catch (e, stackTrace) {
      AppLogger.e('[StorageBootstrap] failed (non-fatal)', e, stackTrace);
      return StorageBootstrapOutcome.failed;
    }
  }
}
