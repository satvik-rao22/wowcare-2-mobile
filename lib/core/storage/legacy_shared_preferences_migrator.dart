import 'package:shared_preferences/shared_preferences.dart';
import 'package:wowcare/core/storage/secure_storage.dart';
import 'package:wowcare/core/storage/secure_storage_backend.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';

/// What [LegacySharedPreferencesMigrator.run] found and did.
class LegacyMigrationReport {
  const LegacyMigrationReport({
    required this.loadFailed,
    required this.hadLegacyData,
    required this.hadInstallMarker,
    this.migrated = 0,
    this.skipped = 0,
    this.failed = 0,
    this.legacyCleared = false,
  });

  static const LegacyMigrationReport nothingToMigrate = LegacyMigrationReport(
    loadFailed: false,
    hadLegacyData: false,
    hadInstallMarker: false,
  );

  static const LegacyMigrationReport loadFailure = LegacyMigrationReport(
    loadFailed: true,
    hadLegacyData: false,
    hadInstallMarker: false,
  );

  /// The legacy store could not be opened at all. Nothing was read or
  /// changed; the caller should treat the launch as "unknown" and retry next
  /// time rather than conclude anything from the absence of data.
  final bool loadFailed;

  /// The legacy store held at least one key — i.e. this is an existing
  /// install upgrading, not a fresh one.
  final bool hadLegacyData;

  /// The legacy `app_installed_marker_v1` flag was set.
  final bool hadInstallMarker;

  /// Keys written into the secure store.
  final int migrated;

  /// Keys left alone: already present in the secure store (a previous run
  /// got that far) or of a type the store does not model.
  final int skipped;

  /// Keys the secure store rejected. When non-zero the legacy store is kept
  /// so the next launch can try again.
  final int failed;

  /// The legacy store was emptied after a complete migration.
  final bool legacyCleared;
}

/// One-time promotion of everything older builds kept in `SharedPreferences`
/// into the secure store, so an upgrade keeps the user signed in and keeps
/// every other preference exactly as it was.
///
/// This is the only file in the app that imports `shared_preferences`. Once
/// every install in the field has run it, the migrator and the dependency can
/// both be deleted.
///
/// Rules:
///  * Values keep their type: a `bool` becomes a `bool`, a `List<String>` a
///    string list, and so on, via [SecureStorage]'s canonical encodings.
///  * **The secure store wins.** A key already present there is never
///    overwritten — if a previous launch migrated but failed to clear the
///    legacy store, the app has since written newer values, and the stale
///    legacy copy must not clobber them.
///  * The legacy install marker is consumed, not migrated: fresh-install
///    detection moved to a file (see `InstallMarker`), and
///    [LegacyMigrationReport.hadInstallMarker] carries the old value to
///    whoever creates that file.
///  * The legacy store is cleared only when every key made it across, so a
///    partial failure can be retried on the next launch.
class LegacySharedPreferencesMigrator {
  LegacySharedPreferencesMigrator({
    required SecureStorage target,
    Future<SharedPreferences> Function()? loadPreferences,
  }) : _target = target,
       _load = loadPreferences ?? SharedPreferences.getInstance;

  /// The namespaced view the migrated keys go into — the same one
  /// `StorageService` reads from.
  final SecureStorage _target;
  final Future<SharedPreferences> Function() _load;

  Future<LegacyMigrationReport> run() async {
    final SharedPreferences prefs;
    try {
      prefs = await _load();
    } catch (e, stackTrace) {
      AppLogger.e(
        '[LegacyPrefs] could not open the legacy store; nothing changed, '
        'will retry next launch',
        e,
        stackTrace,
      );
      return LegacyMigrationReport.loadFailure;
    }

    final keys = prefs.getKeys();
    if (keys.isEmpty) return LegacyMigrationReport.nothingToMigrate;

    final hadInstallMarker = prefs.get(StorageKeys.appInstalledMarker) == true;
    var migrated = 0;
    var skipped = 0;
    var failed = 0;

    for (final key in keys) {
      if (key == StorageKeys.appInstalledMarker) continue;
      try {
        if (await _target.containsKey(key)) {
          skipped++;
          continue;
        }
        if (await _write(key, prefs.get(key))) {
          migrated++;
        } else {
          skipped++;
        }
      } on SecureStorageException catch (e, stackTrace) {
        failed++;
        AppLogger.e('[LegacyPrefs] could not migrate "$key"', e, stackTrace);
      }
    }

    var legacyCleared = false;
    if (failed == 0) {
      try {
        legacyCleared = await prefs.clear();
      } catch (e, stackTrace) {
        AppLogger.e(
          '[LegacyPrefs] migrated but could not clear the legacy store',
          e,
          stackTrace,
        );
      }
    }

    AppLogger.i(
      '[LegacyPrefs] migrated=$migrated skipped=$skipped failed=$failed '
      'legacyCleared=$legacyCleared hadInstallMarker=$hadInstallMarker',
    );
    return LegacyMigrationReport(
      loadFailed: false,
      hadLegacyData: true,
      hadInstallMarker: hadInstallMarker,
      migrated: migrated,
      skipped: skipped,
      failed: failed,
      legacyCleared: legacyCleared,
    );
  }

  /// Writes [value] under [key] with the matching typed encoding. Returns
  /// false for a type the secure store does not model (nothing written).
  Future<bool> _write(String key, Object? value) async {
    switch (value) {
      case String v:
        await _target.writeString(key, v);
      case bool v:
        await _target.writeBool(key, v);
      case int v:
        await _target.writeInt(key, v);
      case double v:
        await _target.writeDouble(key, v);
      case List<Object?> v:
        await _target.writeStringList(key, v.whereType<String>().toList());
      default:
        return false;
    }
    return true;
  }
}
