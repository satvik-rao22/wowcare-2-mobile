import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/in_memory_secure_storage_backend.dart';
import 'package:wowcare/core/storage/secure_storage.dart';
import 'package:wowcare/core/storage/secure_storage_backend.dart';
import 'package:wowcare/core/storage/storage_service.dart';

/// Every operation fails the way a broken Keystore / Keychain would.
class _BrokenBackend implements SecureStorageBackend {
  @override
  Future<String?> read(String key) async =>
      throw SecureStorageException('read', key: key, cause: 'broken');
  @override
  Future<void> write(String key, String value) async =>
      throw SecureStorageException('write', key: key, cause: 'broken');
  @override
  Future<void> delete(String key) async =>
      throw SecureStorageException('delete', key: key, cause: 'broken');
  @override
  Future<Map<String, String>> readAll() async =>
      throw const SecureStorageException('readAll', cause: 'broken');
  @override
  Future<void> deleteAll() async =>
      throw const SecureStorageException('deleteAll', cause: 'broken');
}

void main() {
  late InMemorySecureStorageBackend backend;
  late SecureStorage root;
  late StorageService storage;

  setUp(() {
    backend = InMemorySecureStorageBackend();
    root = SecureStorage(backend);
    storage = StorageServiceImpl(root.namespaced(SecureStorage.appNamespace));
  });

  group('StorageServiceImpl', () {
    test('round-trips every type through the app namespace', () async {
      await storage.saveString('s', 'v');
      await storage.saveInt('i', 7);
      await storage.saveBool('b', true);
      await storage.saveDouble('d', 2.5);
      await storage.saveJson('j', {'k': 'v'});

      expect(await storage.getString('s'), 'v');
      expect(await storage.getInt('i'), 7);
      expect(await storage.getBool('b'), isTrue);
      expect(await storage.getDouble('d'), 2.5);
      expect(await storage.getJson('j'), {'k': 'v'});
      expect(await storage.getKeys(), {'s', 'i', 'b', 'd', 'j'});
      expect(backend.snapshot.keys, everyElement(startsWith('app.')));

      await storage.remove('s');
      expect(await storage.getString('s'), isNull);
      expect(await storage.getKeys(), {'i', 'b', 'd', 'j'});
    });

    test(
      'a wrong-type or malformed value reads as null instead of throwing',
      () async {
        await storage.saveString('n', 'abc');
        expect(await storage.getInt('n'), isNull);
        expect(await storage.getBool('n'), isNull);
        expect(await storage.getDouble('n'), isNull);
        await storage.saveString('j', '{not json');
        expect(await storage.getJson('j'), isNull);
      },
    );

    test(
      'clear() empties this store and leaves the auth and remember-me keys',
      () async {
        await root.writeString('auth_access_token', 'jwt');
        await root.writeString('auth_refresh_token', 'rt');
        await root.writeString('remember_me_password_v1', 'pw');
        await storage.saveString('email', 'x');
        await storage.saveJson('login_cache', {'userCode': 'U1'});

        await storage.clear();

        expect(await storage.getKeys(), isEmpty);
        expect(await storage.getString('email'), isNull);
        expect(backend.snapshot, {
          'auth_access_token': 'jwt',
          'auth_refresh_token': 'rt',
          'remember_me_password_v1': 'pw',
        });
      },
    );

    test(
      'getKeys() lists only this store, never the root-level secrets',
      () async {
        await root.writeString('auth_access_token', 'jwt');
        await storage.saveString('email', 'x');
        expect(await storage.getKeys(), {'email'});
      },
    );

    test(
      'a platform failure is swallowed: reads are null, writes are no-ops',
      () async {
        final broken = StorageServiceImpl(
          SecureStorage(
            _BrokenBackend(),
          ).namespaced(SecureStorage.appNamespace),
        );

        await expectLater(broken.saveString('k', 'v'), completes);
        await expectLater(broken.saveInt('k', 1), completes);
        await expectLater(broken.saveBool('k', true), completes);
        await expectLater(broken.saveDouble('k', 1.0), completes);
        await expectLater(broken.saveJson('k', {}), completes);
        await expectLater(broken.remove('k'), completes);
        await expectLater(broken.clear(), completes);

        expect(await broken.getString('k'), isNull);
        expect(await broken.getInt('k'), isNull);
        expect(await broken.getBool('k'), isNull);
        expect(await broken.getDouble('k'), isNull);
        expect(await broken.getJson('k'), isNull);
        expect(await broken.getKeys(), isEmpty);
      },
    );
  });
}
