import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/in_memory_secure_storage_backend.dart';
import 'package:wowcare/core/storage/secure_storage.dart';
import 'package:wowcare/core/storage/secure_storage_backend.dart';

/// Wraps an in-memory backend, counting every call and letting a test fail,
/// hold or hide individual operations, so the assertions can say exactly when
/// [SecureStorage] went to the platform and when it answered from memory.
class _ProbeBackend implements SecureStorageBackend {
  _ProbeBackend([Map<String, String>? seed])
    : inner = InMemorySecureStorageBackend(seed);

  final InMemorySecureStorageBackend inner;

  int reads = 0;
  int writes = 0;
  int deletes = 0;
  int readAlls = 0;
  int deleteAlls = 0;

  final Set<String> failWrites = <String>{};
  final Set<String> failDeletes = <String>{};
  bool failReadAll = false;

  /// When set, `readAll` takes its snapshot and then waits here before
  /// returning it — the snapshot is deliberately stale by the time it lands.
  Completer<void>? holdReadAll;

  /// When set, `write` waits here before persisting.
  Completer<void>? holdWrite;

  /// Values `read` can see but `readAll` cannot: the iOS accessibility-class
  /// gap for items written by older code.
  final Map<String, String> hiddenFromReadAll = <String, String>{};

  @override
  Future<String?> read(String key) async {
    reads++;
    return hiddenFromReadAll[key] ?? await inner.read(key);
  }

  @override
  Future<void> write(String key, String value) async {
    writes++;
    if (failWrites.contains(key)) {
      throw SecureStorageException('write', key: key, cause: 'rejected');
    }
    if (holdWrite != null) await holdWrite!.future;
    await inner.write(key, value);
  }

  @override
  Future<void> delete(String key) async {
    deletes++;
    if (failDeletes.contains(key)) {
      throw SecureStorageException('delete', key: key, cause: 'rejected');
    }
    await inner.delete(key);
  }

  @override
  Future<Map<String, String>> readAll() async {
    readAlls++;
    final snapshot = await inner.readAll();
    if (holdReadAll != null) await holdReadAll!.future;
    if (failReadAll) {
      throw const SecureStorageException('readAll', cause: 'rejected');
    }
    return snapshot;
  }

  @override
  Future<void> deleteAll() async {
    deleteAlls++;
    hiddenFromReadAll.clear();
    await inner.deleteAll();
  }
}

void main() {
  late _ProbeBackend backend;
  late SecureStorage root;
  late SecureStorage app;

  setUp(() {
    backend = _ProbeBackend();
    root = SecureStorage(backend);
    app = root.namespaced(SecureStorage.appNamespace);
  });

  group('typed values', () {
    test(
      'round-trips every supported type and reads a missing key as null',
      () async {
        await app.writeString('s', 'hello');
        await app.writeInt('i', -42);
        await app.writeBool('b', true);
        await app.writeDouble('d', 250.5);
        await app.writeJson('j', {
          'a': 1,
          'b': <String>['x'],
        });
        await app.writeStringList('l', ['x', 'y']);

        expect(await app.readString('s'), 'hello');
        expect(await app.readInt('i'), -42);
        expect(await app.readBool('b'), isTrue);
        expect(await app.readDouble('d'), 250.5);
        expect(await app.readJson('j'), {
          'a': 1,
          'b': <String>['x'],
        });
        expect(await app.readStringList('l'), ['x', 'y']);

        expect(await app.readString('missing'), isNull);
        expect(await app.readInt('missing'), isNull);
        expect(await app.readBool('missing'), isNull);
        expect(await app.readDouble('missing'), isNull);
        expect(await app.readJson('missing'), isNull);
        expect(await app.readStringList('missing'), isNull);
        expect(await app.containsKey('missing'), isFalse);
        expect(await app.containsKey('s'), isTrue);
      },
    );

    test('stores typed values in one canonical string form', () async {
      await app.writeInt('i', 42);
      await app.writeBool('b', false);
      await app.writeDouble('d', 1.5);
      expect(await app.readString('i'), '42');
      expect(await app.readString('b'), 'false');
      expect(await app.readString('d'), '1.5');
      // An int-shaped double reads back as a double too.
      expect(await app.readDouble('i'), 42.0);
    });

    test(
      'decodes leniently: a value of the wrong type reads as null',
      () async {
        await app.writeString('text', 'abc');
        expect(await app.readInt('text'), isNull);
        expect(await app.readBool('text'), isNull);
        expect(await app.readDouble('text'), isNull);
        expect(await app.readJson('text'), isNull);
        expect(await app.readStringList('text'), isNull);

        await app.writeString('shouty', 'TRUE');
        expect(await app.readBool('shouty'), isNull);

        await app.writeJson('map', {'k': 'v'});
        expect(await app.readStringList('map'), isNull);

        await app.writeString('ints', '[1, 2]');
        expect(await app.readStringList('ints'), isNull);
      },
    );

    test(
      'a raw string written by older code reads back unchanged at the root',
      () async {
        backend = _ProbeBackend({
          'auth_access_token': 'eyJhbGciOi.payload.sig',
        });
        root = SecureStorage(backend);
        expect(
          await root.readString('auth_access_token'),
          'eyJhbGciOi.payload.sig',
        );
      },
    );

    test('rejects an empty key', () {
      expect(() => app.readString(''), throwsArgumentError);
      expect(() => app.writeString('', 'x'), throwsArgumentError);
      expect(() => app.delete(''), throwsArgumentError);
    });
  });

  group('namespaces', () {
    test(
      'prefixes keys in the backend and strips the prefix in keys()',
      () async {
        await app.writeString('email', 'a@b.c');
        expect(backend.inner.snapshot, {'app.email': 'a@b.c'});
        expect(await app.keys(), {'email'});
        expect(await root.keys(), {'app.email'});
      },
    );

    test(
      'keys() of one namespace shows neither root keys nor other namespaces',
      () async {
        await root.writeString('auth_refresh_token', 'rt');
        await root.namespaced('kiosk').writeString('locked', 'true');
        await app.writeString('email', 'x');
        expect(await app.keys(), {'email'});
        expect(await root.namespaced('kiosk').keys(), {'locked'});
      },
    );

    test('clear() empties only its own namespace', () async {
      await root.writeString('auth_refresh_token', 'rt');
      await root.writeString('remember_me_password_v1', 'pw');
      await root.namespaced('kiosk').writeString('locked', 'true');
      await app.writeString('email', 'x');
      await app.writeString('login_cache', '{}');

      await app.clear();

      expect(await app.keys(), isEmpty);
      expect(backend.inner.snapshot, {
        'auth_refresh_token': 'rt',
        'remember_me_password_v1': 'pw',
        'kiosk.locked': 'true',
      });
    });

    test('clear() is refused on the root view and deletes nothing', () async {
      await root.writeString('k', 'v');
      expect(root.clear, throwsUnsupportedError);
      expect(backend.inner.snapshot, {'k': 'v'});
    });

    test('namespace names are validated', () {
      expect(() => root.namespaced(''), throwsArgumentError);
      expect(() => root.namespaced('a.b'), throwsArgumentError);
    });

    test('views created from the same root share one cache', () async {
      await app.writeString('k', 'v');
      expect(await root.readString('app.k'), 'v');
      expect(backend.reads, 0, reason: 'answered from the shared cache');
      expect(app.root.isRoot, isTrue);
      expect(root.root, same(root));
    });
  });

  group('cache', () {
    test(
      'primes once from readAll and serves repeated reads from memory',
      () async {
        backend = _ProbeBackend({'app.a': '1', 'app.b': '2', 'app.c': '3'});
        app = SecureStorage(backend).namespaced(SecureStorage.appNamespace);

        for (var i = 0; i < 2; i++) {
          expect(await app.readString('a'), '1');
          expect(await app.readString('b'), '2');
          expect(await app.readString('c'), '3');
        }
        expect(backend.readAlls, 1);
        expect(backend.reads, 0);
      },
    );

    test(
      'remembers that a key is absent so a hot path never asks twice',
      () async {
        expect(await app.readString('optional'), isNull);
        expect(await app.readString('optional'), isNull);
        expect(backend.reads, 1);
      },
    );

    test(
      'a key the snapshot could not see is fetched once and then cached',
      () async {
        backend.hiddenFromReadAll['auth_access_token'] = 'legacy-class-item';
        root = SecureStorage(backend);

        expect(await root.readString('auth_access_token'), 'legacy-class-item');
        expect(await root.readString('auth_access_token'), 'legacy-class-item');
        expect(backend.readAlls, 1);
        expect(backend.reads, 1);
      },
    );

    test(
      'a write is visible to readers before the backend has confirmed it',
      () async {
        await app.writeString('k', 'old');
        backend.holdWrite = Completer<void>();

        final pending = app.writeString('k', 'new');
        expect(await app.readString('k'), 'new');
        expect(
          backend.inner.snapshot['app.k'],
          'old',
          reason: 'the platform has not been told yet',
        );

        backend.holdWrite!.complete();
        await pending;
        expect(backend.inner.snapshot['app.k'], 'new');
      },
    );

    test(
      'a failed write is rolled back and surfaces as SecureStorageException',
      () async {
        await app.writeString('k', 'old');
        backend.failWrites.add('app.k');

        await expectLater(
          app.writeString('k', 'new'),
          throwsA(
            isA<SecureStorageException>()
                .having((e) => e.operation, 'operation', 'write')
                .having((e) => e.key, 'key', 'app.k'),
          ),
        );
        expect(await app.readString('k'), 'old');
        expect(backend.inner.snapshot['app.k'], 'old');
      },
    );

    test('a failed delete is rolled back', () async {
      await app.writeString('k', 'v');
      backend.failDeletes.add('app.k');

      await expectLater(
        app.delete('k'),
        throwsA(isA<SecureStorageException>()),
      );
      expect(await app.readString('k'), 'v');
      expect(await app.keys(), {'k'});
    });

    test(
      'a write that lands while the snapshot loads beats the stale snapshot',
      () async {
        backend = _ProbeBackend({'app.k': 'old'});
        app = SecureStorage(backend).namespaced(SecureStorage.appNamespace);
        backend.holdReadAll = Completer<void>();

        final primingRead = app.readString('other'); // starts the snapshot
        await app.writeString('k', 'new'); // lands while it is in flight
        backend.holdReadAll!.complete();
        await primingRead;

        expect(await app.readString('k'), 'new');
        expect(backend.inner.snapshot['app.k'], 'new');
      },
    );

    test('wipeAll empties every namespace and the cache', () async {
      await root.writeString('auth_refresh_token', 'rt');
      await root.namespaced('kiosk').writeString('locked', 'true');
      await app.writeString('email', 'x');

      await root.wipeAll();

      expect(backend.deleteAlls, 1);
      expect(backend.inner.snapshot, isEmpty);
      expect(await root.readString('auth_refresh_token'), isNull);
      expect(await root.namespaced('kiosk').readString('locked'), isNull);
      expect(await app.readString('email'), isNull);
      expect(await root.keys(), isEmpty);
    });

    test(
      'a snapshot still loading when wipeAll runs cannot resurrect values',
      () async {
        backend = _ProbeBackend({'app.k': 'stale'});
        root = SecureStorage(backend);
        app = root.namespaced(SecureStorage.appNamespace);
        backend.holdReadAll = Completer<void>();

        final primingRead = app.readString(
          'k',
        ); // snapshot taken: {app.k: stale}
        await root.wipeAll();
        backend.holdReadAll!.complete(); // stale snapshot lands after the wipe

        expect(await primingRead, isNull);
        expect(await app.readString('k'), isNull);
        expect(await app.keys(), isEmpty);
      },
    );

    test(
      'a failed snapshot load is reported and retried on the next access',
      () async {
        backend.failReadAll = true;
        await expectLater(
          app.readString('k'),
          throwsA(isA<SecureStorageException>()),
        );

        backend.failReadAll = false;
        await app.writeString('k', 'v');
        expect(await app.readString('k'), 'v');
        expect(backend.readAlls, 2);
      },
    );
  });
}
