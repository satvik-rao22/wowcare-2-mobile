import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/school_switch_events.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';

import '../../../../presentation/features/events/helpers/event_test_fakes.dart';

/// RoleCubit keeps Sentry's user and session tags in step with the signed-in
/// context: set on every persona change, refreshed on a school switch that
/// leaves the persona alone, cleared on logout.
void main() {
  late FakeStorageService storage;

  setUp(() async {
    storage = FakeStorageService({
      StorageKeys.userCode: 'USR-1',
      StorageKeys.organizationCode: 'ORG-1',
      StorageKeys.schoolCode: 'SCH-1',
    });
    serviceLocator.registerSingleton<StorageService>(storage);
    await Sentry.init((options) {
      options
        ..dsn = 'https://key@o1.ingest.sentry.io/1'
        ..transport = _DiscardingTransport();
    });
  });

  tearDown(() async {
    await Sentry.close();
    await serviceLocator.unregister<StorageService>();
  });

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  Future<(SentryUser?, Map<String, String>)> scope() async {
    late SentryUser? user;
    late Map<String, String> tags;
    await Sentry.configureScope((scope) {
      user = scope.user;
      tags = Map.of(scope.tags);
    });
    return (user, tags);
  }

  test(
    'labels the session on a persona change and clears it on logout',
    () async {
      final cubit = RoleCubit();
      addTearDown(cubit.close);
      await settle();
      await cubit.setRole('staff');
      await settle();

      var (user, tags) = await scope();
      expect(user!.id, 'USR-1');
      expect(tags, {
        'persona': 'staff',
        'org_code': 'ORG-1',
        'school_code': 'SCH-1',
        'kiosk': 'false',
      });

      storage.values.remove(StorageKeys.userCode);
      cubit.resetSessionForLogout();
      await settle();

      (user, tags) = await scope();
      expect(user, isNull);
      expect(tags, isEmpty);
    },
  );

  test(
    'a school switch updates the school tag without a state change',
    () async {
      final cubit = RoleCubit();
      addTearDown(cubit.close);
      await settle();
      await cubit.setRole('staff');
      await settle();

      storage.values[StorageKeys.schoolCode] = 'SCH-2';
      SchoolSwitchEvents.notifySwitched();
      await settle();

      final (_, tags) = await scope();
      expect(tags['school_code'], 'SCH-2');
    },
  );
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
