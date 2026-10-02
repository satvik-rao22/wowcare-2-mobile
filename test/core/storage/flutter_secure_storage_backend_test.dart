import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/flutter_secure_storage_backend.dart';
import 'package:wowcare/core/storage/secure_storage_backend.dart';

/// The plugin picks its option set from the HOST platform (`dart:io`), so a
/// unit test cannot observe the iOS/Android options on the wire. The option
/// objects are asserted directly instead, and the method channel is mocked
/// only to pin the operation mapping and the error wrapping.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('options', () {
    test(
      'Android: EncryptedSharedPreferences, self-healing on Keystore errors',
      () {
        final map = FlutterSecureStorageBackend.androidOptions.toMap();
        expect(map['encryptedSharedPreferences'], 'true');
        expect(map['resetOnError'], 'true');
      },
    );

    test('iOS writes: first_unlock_this_device, never synced to iCloud', () {
      final map = FlutterSecureStorageBackend.iosWriteOptions.toMap();
      expect(map['accessibility'], 'first_unlock_this_device');
      expect(map['synchronizable'], 'false');
    });

    test(
      'iOS reads and deletes: no accessibility class, so every class matches',
      () {
        final map = FlutterSecureStorageBackend.iosReadOptions.toMap();
        expect(map.containsKey('accessibility'), isFalse);
        expect(map['synchronizable'], 'false');
      },
    );

    test(
      'writer and reader share the Android options (same preferences file)',
      () {
        expect(
          FlutterSecureStorageBackend.defaultWriter.aOptions.toMap(),
          FlutterSecureStorageBackend.defaultReader.aOptions.toMap(),
        );
        expect(
          FlutterSecureStorageBackend.defaultWriter.iOptions.toMap(),
          isNot(FlutterSecureStorageBackend.defaultReader.iOptions.toMap()),
        );
      },
    );
  });

  group('operations over the method channel', () {
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    const backend = FlutterSecureStorageBackend();

    final calls = <MethodCall>[];
    final store = <String, String>{};
    PlatformException? failWith;

    setUp(() {
      calls.clear();
      store.clear();
      failWith = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (failWith != null) throw failWith!;
            final args = (call.arguments as Map?)?.cast<String, Object?>();
            switch (call.method) {
              case 'read':
                return store[args!['key']];
              case 'write':
                store[args!['key']! as String] = args['value']! as String;
                return null;
              case 'delete':
                store.remove(args!['key']);
                return null;
              case 'readAll':
                return Map<String, String>.of(store);
              case 'deleteAll':
                store.clear();
                return null;
              case 'containsKey':
                return store.containsKey(args!['key']);
            }
            throw UnimplementedError(call.method);
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('read, write, delete, readAll and deleteAll map one-to-one', () async {
      await backend.write('k', 'v');
      expect(store, {'k': 'v'});
      expect(await backend.read('k'), 'v');
      expect(await backend.read('missing'), isNull);

      await backend.write('k2', 'v2');
      expect(await backend.readAll(), {'k': 'v', 'k2': 'v2'});

      await backend.delete('k');
      expect(store, {'k2': 'v2'});

      await backend.deleteAll();
      expect(store, isEmpty);

      expect(calls.map((c) => c.method).toList(), [
        'write',
        'read',
        'read',
        'write',
        'readAll',
        'delete',
        'deleteAll',
      ]);
      final write = calls.first.arguments as Map;
      expect(write['key'], 'k');
      expect(write['value'], 'v');
      expect(write['options'], isA<Map>());
    });

    test(
      'a platform failure is wrapped with the operation, key and cause',
      () async {
        failWith = PlatformException(code: 'keystore', message: 'bad padding');

        await expectLater(
          backend.read('token'),
          throwsA(
            isA<SecureStorageException>()
                .having((e) => e.operation, 'operation', 'read')
                .having((e) => e.key, 'key', 'token')
                .having((e) => e.cause, 'cause', isA<PlatformException>()),
          ),
        );
        await expectLater(
          backend.write('token', 'x'),
          throwsA(
            isA<SecureStorageException>().having(
              (e) => e.operation,
              'operation',
              'write',
            ),
          ),
        );
        await expectLater(
          backend.readAll(),
          throwsA(
            isA<SecureStorageException>()
                .having((e) => e.operation, 'operation', 'readAll')
                .having((e) => e.key, 'key', isNull),
          ),
        );
        await expectLater(
          backend.delete('token'),
          throwsA(
            isA<SecureStorageException>().having(
              (e) => e.operation,
              'operation',
              'delete',
            ),
          ),
        );
        await expectLater(
          backend.deleteAll(),
          throwsA(
            isA<SecureStorageException>().having(
              (e) => e.operation,
              'operation',
              'deleteAll',
            ),
          ),
        );
      },
    );

    test('toString names the operation and key for the logs', () {
      const e = SecureStorageException('write', key: 'k', cause: 'boom');
      expect(e.toString(), 'SecureStorageException(write key=k): boom');
      const noKey = SecureStorageException('readAll', cause: 'boom');
      expect(noKey.toString(), 'SecureStorageException(readAll): boom');
    });
  });
}
