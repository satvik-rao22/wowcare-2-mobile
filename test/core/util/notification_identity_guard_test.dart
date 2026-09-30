import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/notification_identity_guard.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/notifications/entities/push_notification.dart';

class _FakeStorageService implements StorageService {
  final Map<String, String> _strings = {};

  @override
  Future<void> saveString(String key, String value) async {
    _strings[key] = value;
  }

  @override
  Future<String?> getString(String key) async => _strings[key];

  @override
  Future<void> remove(String key) async => _strings.remove(key);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PushNotification _link({String? userCode}) => PushNotification(
  title: null,
  body: null,
  action: 'INVOICE_GENERATED',
  type: null,
  data: {if (userCode != null) 'userCode': userCode},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeStorageService storage;

  setUp(() async {
    await serviceLocator.reset();
    storage = _FakeStorageService();
    serviceLocator.registerSingleton<StorageService>(storage);
  });

  tearDown(() async => serviceLocator.reset());

  test(
    'is a no-op when the link carries no userCode — every real FCM push '
    'today has no such field',
    () async {
      await storage.saveString(StorageKeys.userCode, 'USR-logged-in');

      final blocked = await blockIfWrongAccount(_link());

      expect(blocked, isFalse);
    },
  );

  test('proceeds when the link userCode matches the logged-in account', () async {
    await storage.saveString(StorageKeys.userCode, 'USR-abc');

    final blocked = await blockIfWrongAccount(_link(userCode: 'USR-abc'));

    expect(blocked, isFalse);
  });

  test(
    'blocks when the link userCode belongs to a different account than '
    'whoever is logged in on this device',
    () async {
      await storage.saveString(StorageKeys.userCode, 'USR-logged-in');

      final blocked = await blockIfWrongAccount(_link(userCode: 'USR-someone-else'));

      expect(blocked, isTrue);
    },
  );

  test('is a no-op when there is no logged-in userCode to compare against', () async {
    final blocked = await blockIfWrongAccount(_link(userCode: 'USR-someone-else'));

    expect(blocked, isFalse);
  });
}
