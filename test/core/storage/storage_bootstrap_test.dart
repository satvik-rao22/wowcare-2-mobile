import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wowcare/core/security/install_marker.dart';
import 'package:wowcare/core/storage/in_memory_secure_storage_backend.dart';
import 'package:wowcare/core/storage/legacy_shared_preferences_migrator.dart';
import 'package:wowcare/core/storage/secure_storage.dart';
import 'package:wowcare/core/storage/storage_bootstrap.dart';
import 'package:wowcare/core/utils/storage_keys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late InstallMarker marker;
  late InMemorySecureStorageBackend backend;
  late SecureStorage root;
  late SecureStorage app;
  var credentialClears = 0;
  var rememberMeClears = 0;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wowcare_bootstrap_');
    marker = InstallMarker(directory: () async => tempDir);
    backend = InMemorySecureStorageBackend();
    root = SecureStorage(backend);
    app = root.namespaced(SecureStorage.appNamespace);
    credentialClears = 0;
    rememberMeClears = 0;
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  StorageBootstrap bootstrap({Future<SharedPreferences> Function()? load}) {
    return StorageBootstrap(
      migrator: LegacySharedPreferencesMigrator(
        target: app,
        loadPreferences: load,
      ),
      installMarker: marker,
      secureStorage: root,
      clearSecureCredentials: () async {
        credentialClears++;
        await root.delete('auth_access_token');
        await root.delete('remember_me_password_v1');
      },
      clearRememberMe: () async {
        rememberMeClears++;
        await root.delete('remember_me_password_v1');
      },
    );
  }

  Future<void> seedPreviousSession() async {
    await root.writeString('auth_access_token', 'jwt');
    await root.writeString('remember_me_password_v1', 'pw');
  }

  group('StorageBootstrap', () {
    test(
      'upgrade with the legacy marker: migrates, writes the file, clears nothing',
      () async {
        SharedPreferences.setMockInitialValues({
          'email': 'x',
          StorageKeys.appInstalledMarker: true,
        });
        await seedPreviousSession();

        final outcome = await bootstrap().run();

        expect(outcome, StorageBootstrapOutcome.migrated);
        expect(await marker.exists(), isTrue);
        expect(await app.readString('email'), 'x');
        expect(await root.readString('auth_access_token'), 'jwt');
        expect(await root.readString('remember_me_password_v1'), 'pw');
        expect(credentialClears, 0);
        expect(rememberMeClears, 0);
      },
    );

    test(
      'upgrade without the legacy marker: clears the remembered credentials, as the old check did',
      () async {
        SharedPreferences.setMockInitialValues({'email': 'x'});
        await seedPreviousSession();

        final outcome = await bootstrap().run();

        expect(outcome, StorageBootstrapOutcome.migrated);
        expect(await marker.exists(), isTrue);
        expect(rememberMeClears, 1);
        expect(credentialClears, 0);
        expect(
          await root.readString('auth_access_token'),
          'jwt',
          reason: 'the session itself was never part of that reset',
        );
        expect(await root.readString('remember_me_password_v1'), isNull);
      },
    );

    test(
      'fresh install: wipes the whole secure store and writes the marker',
      () async {
        SharedPreferences.setMockInitialValues({});
        await seedPreviousSession();
        await app.writeString('email', 'previous-owner@example.com');
        await root.namespaced('kiosk').writeString('locked', 'true');

        final outcome = await bootstrap().run();

        expect(outcome, StorageBootstrapOutcome.freshInstall);
        expect(credentialClears, 1);
        expect(backend.snapshot, isEmpty);
        expect(await app.readString('email'), isNull);
        expect(await marker.exists(), isTrue);
      },
    );

    test(
      'existing install with nothing to migrate: leaves everything alone',
      () async {
        SharedPreferences.setMockInitialValues({});
        await marker.create();
        await seedPreviousSession();
        await app.writeString('email', 'x');
        final before = Map<String, String>.of(backend.snapshot);

        final outcome = await bootstrap().run();

        expect(outcome, StorageBootstrapOutcome.existingInstall);
        expect(backend.snapshot, before);
        expect(credentialClears, 0);
        expect(rememberMeClears, 0);
      },
    );

    test(
      'legacy store unavailable: defers, wipes nothing, writes no marker',
      () async {
        await seedPreviousSession();
        final before = Map<String, String>.of(backend.snapshot);

        final outcome = await bootstrap(
          load: () async => throw StateError('plugin missing'),
        ).run();

        expect(outcome, StorageBootstrapOutcome.deferred);
        expect(backend.snapshot, before);
        expect(await marker.exists(), isFalse);
        expect(credentialClears, 0);
        expect(rememberMeClears, 0);
      },
    );

    test(
      'the launch after a migration is an ordinary existing install',
      () async {
        SharedPreferences.setMockInitialValues({
          'email': 'x',
          StorageKeys.appInstalledMarker: true,
        });

        expect(await bootstrap().run(), StorageBootstrapOutcome.migrated);
        expect(
          await bootstrap().run(),
          StorageBootstrapOutcome.existingInstall,
        );
        expect(await app.readString('email'), 'x');
        expect(credentialClears, 0);
      },
    );
  });
}
