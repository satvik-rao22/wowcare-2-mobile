import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/attendance/cubit/sign_attendance_cubit.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';

import 'attendance_test_doubles.dart';

void main() {
  late FakeAttendanceSource source;

  final today = DemoData.today;

  SignAttendanceCubit build({
    SignKind kind = SignKind.signIn,
    List<String> ids = const <String>['aria'],
  }) => SignAttendanceCubit(
    source: source,
    args: SignAttendanceArgs(
      kind: kind,
      audience: AttendanceAudience.students,
      ids: ids,
    ),
    persona: Persona.admin,
    today: today,
  );

  setUp(() => source = FakeAttendanceSource());

  group('SignAttendanceCubit', () {
    test('picks up the records behind the ids it was handed', () async {
      final cubit = build(ids: <String>['aria', 'jonah']);
      await cubit.load();

      expect(cubit.state.status, SignStatus.editing);
      expect(cubit.state.people.map((p) => p.fullName), <String>[
        'Aria Rowan',
        'Jonah Park',
      ]);
      await cubit.close();
    });

    test(
      'a sign-in with somebody unexpected waits to be acknowledged',
      () async {
        final cubit = build(ids: <String>['aria', 'jonah']);
        await cubit.load();

        expect(cubit.state.unexpected.single.fullName, 'Jonah Park');
        expect(cubit.state.needsAcknowledgement, isTrue);
        expect(cubit.state.canSubmit, isFalse);

        cubit.acknowledgeUnexpected();
        expect(cubit.state.canSubmit, isTrue);
        await cubit.close();
      },
    );

    test('a sign-out never asks: they are already in the building', () async {
      final cubit = build(kind: SignKind.signOut, ids: <String>['jonah']);
      await cubit.load();

      expect(cubit.state.needsAcknowledgement, isFalse);
      expect(cubit.state.canSubmit, isTrue);
      await cubit.close();
    });

    test('outside the geofence the key is off', () async {
      source.insideGeofence = false;
      final cubit = build();
      await cubit.load();

      expect(cubit.state.isInsideGeofence, isFalse);
      expect(cubit.state.canSubmit, isFalse);
      await cubit.close();
    });

    test('the two fields make one instant, and that is what is sent', () async {
      final cubit = build();
      await cubit.load();

      cubit
        ..setDate(DateTime(2026, 8, 19))
        ..setTime(hour: 9, minute: 5);
      expect(cubit.state.at, DateTime(2026, 8, 19, 9, 5));

      expect(await cubit.submit(), isTrue);
      expect(source.lastSignedAt, DateTime(2026, 8, 19, 9, 5));
      expect(source.lastIds, <String>['aria']);
      expect(cubit.state.status, SignStatus.done);
      await cubit.close();
    });

    test('a tile can be taken off, and the last one cannot', () async {
      final cubit = build(ids: <String>['aria', 'jonah']);
      await cubit.load();

      cubit.removePerson('jonah');
      expect(cubit.state.people, hasLength(1));
      expect(cubit.state.needsAcknowledgement, isFalse);

      cubit.removePerson('aria');
      expect(cubit.state.people, hasLength(1), reason: 'the last one stays');
      await cubit.close();
    });

    test('removing somebody puts the acknowledgement back', () async {
      final cubit = build(ids: <String>['aria', 'jonah']);
      await cubit.load();
      cubit
        ..acknowledgeUnexpected()
        ..removePerson('aria');

      expect(cubit.state.isAcknowledged, isFalse);
      await cubit.close();
    });

    test(
      'a form nobody was handed to says so rather than submitting',
      () async {
        final cubit = build(ids: const <String>[]);
        await cubit.load();

        expect(cubit.state.isEmpty, isTrue);
        expect(cubit.state.canSubmit, isFalse);
        await cubit.close();
      },
    );

    test('a failed write is a failed state, and nothing is queued', () async {
      final cubit = build();
      await cubit.load();
      source.throwsOnWrite = true;

      expect(await cubit.submit(), isFalse);
      expect(cubit.state.status, SignStatus.failed);
      await cubit.close();
    });
  });
}
