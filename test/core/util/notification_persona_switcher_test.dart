import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/notification_persona_switcher.dart';
import 'package:wowcare/core/utils/storage_keys.dart';

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

void main() {
  late _FakeStorageService storage;

  setUp(() async {
    await serviceLocator.reset();
    storage = _FakeStorageService();
    serviceLocator.registerSingleton<StorageService>(storage);
  });

  tearDown(() async => serviceLocator.reset());

  // These two guards run entirely off storage, before anything touches
  // RoleCubit/UserProfileCubit — safe to exercise with a plain unattached
  // BuildContext. The full switch sequence (persist → refresh → prefetch)
  // is a near-verbatim mirror of custom_app_bar.dart's already-relied-upon
  // manual "Switch Profile" flow and isn't re-tested here.
  testWidgets('is a no-op when the link carries no role', (tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    final context = tester.element(find.byType(SizedBox));

    final blocked = await switchActiveSchoolPersonaIfNeeded(
      context: context,
      targetRole: null,
    );

    expect(blocked, isFalse);
  });

  testWidgets(
    'is a no-op when the account is already on the linked persona',
    (tester) async {
      await storage.saveString(StorageKeys.activeSchoolRole, 'GUARDIAN');
      await tester.pumpWidget(const SizedBox.shrink());
      final context = tester.element(find.byType(SizedBox));

      final blocked = await switchActiveSchoolPersonaIfNeeded(
        context: context,
        targetRole: 'guardian',
      );

      expect(blocked, isFalse);
    },
  );
}
