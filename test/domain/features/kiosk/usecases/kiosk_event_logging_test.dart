import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/domain/features/kiosk/entities/kiosk_attendance_entity.dart';
import 'package:wowcare/domain/features/kiosk/entities/kiosk_pin_result_entity.dart';
import 'package:wowcare/domain/features/kiosk/repositories/kiosk_attendance_repository.dart';
import 'package:wowcare/domain/features/kiosk/repositories/kiosk_repository.dart';
import 'package:wowcare/domain/features/kiosk/usecases/sign_in_staff_usecase.dart';
import 'package:wowcare/domain/features/kiosk/usecases/sign_out_staff_usecase.dart';
import 'package:wowcare/domain/features/kiosk/usecases/verify_kiosk_pin_usecase.dart';

/// Answers a PIN with [result], or fails with [error] when set.
class _FakeKioskRepository implements KioskRepository {
  KioskPinResultEntity result = const KioskPinResultEntity(
    persona: KioskPersona.staff,
    staffCode: 'STF-1',
    staffName: 'Asha Rao',
  );
  Object? error;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName != #verifyPin) {
      throw UnimplementedError('${invocation.memberName}');
    }
    return error == null
        ? Future<KioskPinResultEntity>.value(result)
        : Future<KioskPinResultEntity>.error(error!);
  }
}

/// Signs staff in and out, or fails with [error] when set.
class _FakeKioskAttendanceRepository implements KioskAttendanceRepository {
  Object? error;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (error != null) return Future<KioskStaffAttendanceEntity>.error(error!);
    return Future<KioskStaffAttendanceEntity>.value(
      KioskStaffAttendanceEntity(
        staffCode: 'STF-1',
        status: invocation.memberName == #signInStaff
            ? 'SIGNED_IN'
            : 'SIGNED_OUT',
      ),
    );
  }
}

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

  group('PIN verify', () {
    test('a recognised PIN logs success and never the PIN', () async {
      final result = await VerifyKioskPinUseCase(_FakeKioskRepository())(
        pin: '4831',
        schoolCode: 'SCH-1',
      );
      await settle();

      expect(result.isStaff, isTrue);
      expect(logs.single.body, 'kiosk.pin_verify.succeeded');
      _expectNothingFrom(logs, ['4831', 'SCH-1', 'STF-1', 'Asha']);
    });

    test('a rejected PIN is rethrown and bucketed from its status', () async {
      final request = RequestOptions(path: '/attendance/kiosk/verify-pin');
      final error = DioException.badResponse(
        statusCode: 400,
        requestOptions: request,
        response: Response<dynamic>(requestOptions: request, statusCode: 400),
      );
      final repository = _FakeKioskRepository()..error = error;

      await expectLater(
        VerifyKioskPinUseCase(repository)(pin: '0000', schoolCode: 'SCH-1'),
        throwsA(same(error)),
      );
      await settle();

      final log = logs.single;
      expect(log.body, 'kiosk.pin_verify.failed');
      expect(log.attributes['failure']!.value, 'validation');
      _expectNothingFrom(logs, ['0000', 'SCH-1', 'verify-pin']);
    });

    test(
      'a sign-in reply with no persona the kiosk can route is a failure',
      () async {
        final repository = _FakeKioskRepository()
          ..result = const KioskPinResultEntity(persona: KioskPersona.unknown);

        final result = await VerifyKioskPinUseCase(repository)(
          pin: '4831',
          schoolCode: 'SCH-1',
        );
        await VerifyKioskPinUseCase(repository)(
          pin: '4831',
          schoolCode: 'SCH-1',
          isLogout: true,
        );
        await settle();

        expect(result.persona, KioskPersona.unknown);
        expect(logs.map((log) => log.body), [
          'kiosk.pin_verify.failed',
          'kiosk.pin_verify.succeeded',
        ]);
        expect(logs.first.attributes['failure']!.value, 'server');
      },
    );
  });

  group('staff attendance', () {
    test('sign-in and sign-out log no code, PIN or coordinates', () async {
      final repository = _FakeKioskAttendanceRepository();

      await SignInStaffUseCase(repository)(
        staffCode: 'STF-1',
        schoolCode: 'SCH-1',
        timeZone: 'Asia/Kolkata',
        latitude: 12.9716,
        longitude: 77.5946,
        withinGeofence: true,
        pin: '4831',
      );
      await SignOutStaffUseCase(repository)(
        staffCode: 'STF-1',
        schoolCode: 'SCH-1',
        timeZone: 'Asia/Kolkata',
        latitude: 12.9716,
        longitude: 77.5946,
        withinGeofence: false,
        pin: '4831',
      );
      await settle();

      expect(logs.map((log) => log.body), [
        'kiosk.staff_sign_in.succeeded',
        'kiosk.staff_sign_out.succeeded',
      ]);
      _expectNothingFrom(logs, [
        'STF-1',
        'SCH-1',
        'Kolkata',
        '12.97',
        '77.59',
        '4831',
      ]);
    });

    test(
      'a sign-out that cannot reach the server is a network failure',
      () async {
        final repository = _FakeKioskAttendanceRepository()
          ..error = DioException.connectionError(
            requestOptions: RequestOptions(path: '/x'),
            reason: 'offline',
          );

        await expectLater(
          SignOutStaffUseCase(repository)(
            staffCode: 'STF-1',
            schoolCode: 'SCH-1',
            timeZone: 'UTC',
            latitude: 0,
            longitude: 0,
            withinGeofence: true,
          ),
          throwsA(isA<DioException>()),
        );
        await settle();

        expect(logs.single.body, 'kiosk.staff_sign_out.failed');
        expect(logs.single.attributes['failure']!.value, 'network');
      },
    );
  });
}

/// Fails when any identifier, PIN or coordinate passed in appears in a logged
/// line.
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
