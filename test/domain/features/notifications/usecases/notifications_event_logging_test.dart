import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/data/features/notifications/datasources/fcm_registration_remote_data_source.dart';
import 'package:wowcare/data/features/notifications/models/notification_preference_group_model.dart';
import 'package:wowcare/data/features/notifications/services/fcm_token_registration_service.dart';
import 'package:wowcare/domain/features/notifications/repositories/notification_center_repository.dart';
import 'package:wowcare/domain/features/notifications/repositories/notification_preference_groups_repository.dart';
import 'package:wowcare/domain/features/notifications/usecases/mark_all_notifications_read_usecase.dart';
import 'package:wowcare/domain/features/notifications/usecases/update_notification_preference_groups_usecase.dart';

/// Every call completes with nothing, or fails with [error] when set, and is
/// counted.
mixin _Scripted {
  Object? error;
  int calls = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    return error == null ? Future<void>.value() : Future<Never>.error(error!);
  }
}

class _FakeFcmRemote
    with _Scripted
    implements FcmRegistrationRemoteDataSource {}

class _FakeNotificationCenterRepository
    with _Scripted
    implements NotificationCenterRepository {}

class _FakePreferenceGroupsRepository
    with _Scripted
    implements NotificationPreferenceGroupsRepository {}

/// A signed-in session when [session] is true, an empty store otherwise.
class _FakeStorage implements StorageService {
  _FakeStorage({required this.session});

  final bool session;

  @override
  Future<String?> getString(String key) async => session
      ? switch (key) {
          StorageKeys.userCode => 'USR-1',
          StorageKeys.organizationCode => 'ORG-1',
          StorageKeys.schoolCode => 'SCH-1',
          StorageKeys.activeSchoolRole => 'STAFF',
          _ => null,
        }
      : null;

  @override
  Future<bool?> getBool(String key) async => session;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

FcmTokenRegistrationService _service(
  FcmRegistrationRemoteDataSource remote, {
  bool session = true,
}) => FcmTokenRegistrationService(
  remote: remote,
  storage: _FakeStorage(session: session),
);

void main() {
  final logs = <SentryLog>[];

  setUp(() async {
    logs.clear();
    await Sentry.init((options) {
      options
        ..dsn = 'https://key@o1.ingest.sentry.io/1'
        ..enableLogs = true
        ..transport = _DiscardingTransport()
        ..beforeSendLog = (log) {
          logs.add(log);
          return log;
        };
    });
  });

  tearDown(() => Sentry.close());

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  // Logged by the registration service, which swallows its own errors so a
  // push failure never breaks login or logout.
  group('push token', () {
    test('an unregister logs its outcome, never the token', () async {
      final remote = _FakeFcmRemote();

      await _service(remote).unregisterToken('fcm-token-abc123');
      await settle();

      expect(remote.calls, 1);
      expect(logs.single.body, 'notification.push_unregister.succeeded');
      _expectNothingFrom(logs, ['fcm-token', 'abc123']);
    });

    test('a failed unregister is logged failed and still swallowed', () async {
      final request = RequestOptions(path: '/notification/fcm/unregister');
      final remote = _FakeFcmRemote()
        ..error = DioException.badResponse(
          statusCode: 401,
          requestOptions: request,
          response: Response<dynamic>(requestOptions: request, statusCode: 401),
        );

      await _service(remote).unregisterToken('fcm-token-abc123');
      await settle();

      expect(logs.single.body, 'notification.push_unregister.failed');
      expect(logs.single.attributes['failure']!.value, 'unauthorized');
      _expectNothingFrom(logs, ['fcm-token', '/notification']);
    });

    test('no session or no token means no call and no event', () async {
      final remote = _FakeFcmRemote();
      final service = _service(remote, session: false);

      await service.registerToken('fcm-token-abc123');
      await service.registerToken('  ');
      await service.unregisterToken('');
      await settle();

      expect(remote.calls, 0);
      expect(logs, isEmpty);
    });
  });

  test('mark all read logs its outcome', () async {
    await MarkAllNotificationsReadUseCase(
      _FakeNotificationCenterRepository(),
    )();
    await settle();

    expect(logs.single.body, 'notification.mark_all_read.succeeded');
  });

  test('a refused preferences update logs no user or group code', () async {
    final request = RequestOptions(path: '/notification/preferences/groups');
    final repository = _FakePreferenceGroupsRepository()
      ..error = DioException.badResponse(
        statusCode: 422,
        requestOptions: request,
        response: Response<dynamic>(requestOptions: request, statusCode: 422),
      );

    await expectLater(
      UpdateNotificationPreferenceGroupsUseCase(repository)(
        userCode: 'USR-1',
        request: const UpdateNotificationPreferenceGroupsRequest(
          preferences: [
            NotificationPreferenceGroupUpdate(
              groupCode: 'GRP-ATTENDANCE',
              channels: {'PUSH': false},
            ),
          ],
        ),
      ),
      throwsA(isA<DioException>()),
    );
    await settle();

    expect(logs.single.body, 'notification.preferences_update.failed');
    expect(logs.single.attributes['failure']!.value, 'validation');
    _expectNothingFrom(logs, ['USR-1', 'GRP-ATTENDANCE', 'PUSH']);
  });
}

/// Fails when any identifier or token passed in appears in a logged line.
void _expectNothingFrom(List<SentryLog> logs, List<String> passedIn) {
  final logged = [
    for (final log in logs) ...[
      log.body,
      for (final attribute in log.attributes.values) '${attribute.value}',
    ],
  ].join(' ');
  for (final value in passedIn) {
    expect(logged, isNot(contains(value)));
  }
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
