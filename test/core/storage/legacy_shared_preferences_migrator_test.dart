import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wowcare/core/storage/in_memory_secure_storage_backend.dart';
import 'package:wowcare/core/storage/legacy_shared_preferences_migrator.dart';
import 'package:wowcare/core/storage/secure_storage.dart';
import 'package:wowcare/core/storage/secure_storage_backend.dart';
import 'package:wowcare/core/utils/storage_keys.dart';

/// Delegates to an in-memory backend but rejects writes to [rejectedKeys].
class _PartiallyBrokenBackend implements SecureStorageBackend {
  _PartiallyBrokenBackend(this.rejectedKeys);

  final Set<String> rejectedKeys;
  final InMemorySecureStorageBackend inner = InMemorySecureStorageBackend();

  @override
  Future<String?> read(String key) => inner.read(key);
  @override
  Future<void> write(String key, String value) {
    if (rejectedKeys.contains(key)) {
      throw SecureStorageException('write', key: key, cause: 'rejected');
    }
    return inner.write(key, value);
  }

  @override
  Future<void> delete(String key) => inner.delete(key);
  @override
  Future<Map<String, String>> readAll() => inner.readAll();
  @override
  Future<void> deleteAll() => inner.deleteAll();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemorySecureStorageBackend backend;
  late SecureStorage app;

  setUp(() {
    backend = InMemorySecureStorageBackend();
    app = SecureStorage(backend).namespaced(SecureStorage.appNamespace);
  });

  group('LegacySharedPreferencesMigrator', () {
    test(
      'promotes every legacy value with its type and empties the legacy store',
      () async {
        SharedPreferences.setMockInitialValues({
          'email': 'mohan@example.com',
          'tokenExpiresAt': 1700000000000,
          'rememberMe': true,
          'geofence_school_radius_m': 250.5,
          'allowedClassroomCodes': <String>['CLS_1', 'CLS_2'],
          StorageKeys.appInstalledMarker: true,
        });

        final report = await LegacySharedPreferencesMigrator(target: app).run();

        expect(report.loadFailed, isFalse);
        expect(report.hadLegacyData, isTrue);
        expect(report.hadInstallMarker, isTrue);
        expect(report.migrated, 5);
        expect(report.skipped, 0);
        expect(report.failed, 0);
        expect(report.legacyCleared, isTrue);

        expect(await app.readString('email'), 'mohan@example.com');
        expect(await app.readInt('tokenExpiresAt'), 1700000000000);
        expect(await app.readBool('rememberMe'), isTrue);
        expect(await app.readDouble('geofence_school_radius_m'), 250.5);
        expect(await app.readStringList('allowedClassroomCodes'), [
          'CLS_1',
          'CLS_2',
        ]);
        // Consumed into the file marker, never copied as a key.
        expect(await app.containsKey(StorageKeys.appInstalledMarker), isFalse);
        expect(backend.snapshot.keys, everyElement(startsWith('app.')));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getKeys(), isEmpty);
      },
    );

    test(
      'reports the install marker as absent when the legacy store lacked it',
      () async {
        SharedPreferences.setMockInitialValues({'email': 'x'});
        final report = await LegacySharedPreferencesMigrator(target: app).run();
        expect(report.hadLegacyData, isTrue);
        expect(report.hadInstallMarker, isFalse);
      },
    );

    test('is a no-op on an empty legacy store', () async {
      SharedPreferences.setMockInitialValues({});
      final report = await LegacySharedPreferencesMigrator(target: app).run();
      expect(report, same(LegacyMigrationReport.nothingToMigrate));
      expect(backend.snapshot, isEmpty);
    });

    test('never overwrites a value the secure store already has', () async {
      await app.writeString('email', 'newer@example.com');
      SharedPreferences.setMockInitialValues({
        'email': 'stale@example.com',
        'userCode': 'USR_1',
      });

      final report = await LegacySharedPreferencesMigrator(target: app).run();

      expect(await app.readString('email'), 'newer@example.com');
      expect(await app.readString('userCode'), 'USR_1');
      expect(report.migrated, 1);
      expect(report.skipped, 1);
      expect(report.legacyCleared, isTrue);
    });

    test(
      'keeps the legacy store when any key fails so the next launch retries',
      () async {
        final broken = _PartiallyBrokenBackend({'app.userCode'});
        final target = SecureStorage(
          broken,
        ).namespaced(SecureStorage.appNamespace);
        SharedPreferences.setMockInitialValues({
          'email': 'x',
          'userCode': 'USR_1',
        });

        final report = await LegacySharedPreferencesMigrator(
          target: target,
        ).run();

        expect(report.migrated, 1);
        expect(report.failed, 1);
        expect(report.legacyCleared, isFalse);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getKeys(), {'email', 'userCode'});
        expect(broken.inner.snapshot, {'app.email': 'x'});
      },
    );

    test(
      'a second run after a complete migration finds nothing to do',
      () async {
        SharedPreferences.setMockInitialValues({'email': 'x'});
        final migrator = LegacySharedPreferencesMigrator(target: app);
        await migrator.run();
        final again = await migrator.run();
        expect(again, same(LegacyMigrationReport.nothingToMigrate));
      },
    );

    test(
      'a legacy store that cannot be opened is reported, not treated as empty',
      () async {
        final report = await LegacySharedPreferencesMigrator(
          target: app,
          loadPreferences: () async => throw StateError('plugin missing'),
        ).run();
        expect(report, same(LegacyMigrationReport.loadFailure));
        expect(report.loadFailed, isTrue);
        expect(report.hadLegacyData, isFalse);
        expect(backend.snapshot, isEmpty);
      },
    );
  });
}
