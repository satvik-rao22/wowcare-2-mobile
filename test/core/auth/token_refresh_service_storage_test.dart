import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/auth/token_refresh_service.dart';
import 'package:wowcare/core/storage/in_memory_secure_storage_backend.dart';
import 'package:wowcare/core/storage/secure_storage.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';

/// Pins where the tokens live relative to the general store. The refresh
/// network path is not exercised here.
void main() {
  late InMemorySecureStorageBackend backend;
  late SecureStorage root;
  late StorageService storage;
  final service = TokenRefreshService.instance;

  void register<T extends Object>(T instance) {
    if (serviceLocator.isRegistered<T>()) serviceLocator.unregister<T>();
    serviceLocator.registerSingleton<T>(instance);
  }

  setUp(() {
    backend = InMemorySecureStorageBackend();
    root = SecureStorage(backend);
    storage = StorageServiceImpl(root.namespaced(SecureStorage.appNamespace));
    register<SecureStorage>(root);
    register<StorageService>(storage);
  });

  tearDown(() {
    serviceLocator.unregister<SecureStorage>();
    serviceLocator.unregister<StorageService>();
  });

  group('TokenRefreshService storage', () {
    test('tokens live under root keys the app store cannot see', () async {
      await service.saveAccessToken('jwt');
      await service.saveRefreshToken('rt');

      expect(await service.readAccessToken(), 'jwt');
      expect(await service.readRefreshToken(), 'rt');
      expect(backend.snapshot, {
        'auth_access_token': 'jwt',
        'auth_refresh_token': 'rt',
      });
      expect(await storage.getKeys(), isEmpty);
    });

    test('blank tokens are never persisted', () async {
      await service.saveAccessToken('   ');
      await service.saveRefreshToken('');
      expect(backend.snapshot, isEmpty);
      expect(await service.readAccessToken(), '');
    });

    test(
      'a token left under the legacy StorageService key is promoted once',
      () async {
        await storage.saveString(StorageKeys.accessToken, 'legacy-jwt');
        await storage.saveString(StorageKeys.refreshToken, 'legacy-rt');

        expect(await service.readAccessToken(), 'legacy-jwt');
        expect(await service.readRefreshToken(), 'legacy-rt');
        expect(backend.snapshot['auth_access_token'], 'legacy-jwt');
        expect(backend.snapshot['auth_refresh_token'], 'legacy-rt');
        expect(await storage.getString(StorageKeys.accessToken), isNull);
        expect(await storage.getString(StorageKeys.refreshToken), isNull);
      },
    );

    test(
      'clear() removes the tokens and their expiry but nothing else',
      () async {
        await service.saveAccessToken('jwt');
        await service.saveRefreshToken('rt');
        await service.saveAccessTokenExpiry(3600);
        await storage.saveString(StorageKeys.email, 'mohan@example.com');

        await service.clear();

        expect(await service.readAccessToken(), '');
        expect(await service.readRefreshToken(), '');
        expect(await storage.getInt(StorageKeys.tokenExpiresAt), isNull);
        expect(await storage.getString(StorageKeys.email), 'mohan@example.com');
      },
    );

    test(
      'a logout clear of the app store leaves the tokens for clear() to own',
      () async {
        await service.saveAccessToken('jwt');
        await storage.saveString(StorageKeys.email, 'x');

        await storage.clear();

        expect(await storage.getKeys(), isEmpty);
        expect(await service.readAccessToken(), 'jwt');
      },
    );
  });
}
