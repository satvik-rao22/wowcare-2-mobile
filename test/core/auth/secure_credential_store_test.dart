import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/auth/secure_credential_store.dart';
import 'package:wowcare/core/storage/in_memory_secure_storage_backend.dart';
import 'package:wowcare/core/storage/secure_storage.dart';

/// The biometric gate is exercised against the real local_auth plugin and is
/// out of reach here; these tests pin the storage contract underneath it.
void main() {
  late InMemorySecureStorageBackend backend;
  late SecureStorage root;
  late SecureCredentialStore store;

  setUp(() {
    backend = InMemorySecureStorageBackend();
    root = SecureStorage(backend);
    store = SecureCredentialStore(storage: root);
  });

  group('SecureCredentialStore', () {
    test(
      'keeps the credentials under root-level keys, outside the app store',
      () async {
        await store.save(username: 'mohan', password: 's3cret');

        expect(backend.snapshot, {
          'remember_me_username_v1': 'mohan',
          'remember_me_password_v1': 's3cret',
        });
        expect(await store.hasSavedPassword(), isTrue);
        expect(
          await root.namespaced(SecureStorage.appNamespace).keys(),
          isEmpty,
        );
      },
    );

    test('survives a logout clear of the app store', () async {
      await store.save(username: 'mohan', password: 's3cret');
      final app = root.namespaced(SecureStorage.appNamespace);
      await app.writeString('login_cache', '{}');

      await app.clear();

      expect(await store.hasSavedPassword(), isTrue);
      expect(await app.keys(), isEmpty);
    });

    test('clear() removes both keys', () async {
      await store.save(username: 'mohan', password: 's3cret');
      await store.clear();
      expect(backend.snapshot, isEmpty);
      expect(await store.hasSavedPassword(), isFalse);
    });

    test(
      'hasSavedPassword is false when nothing or an empty password is stored',
      () async {
        expect(await store.hasSavedPassword(), isFalse);
        await store.save(username: 'mohan', password: '');
        expect(await store.hasSavedPassword(), isFalse);
      },
    );
  });
}
