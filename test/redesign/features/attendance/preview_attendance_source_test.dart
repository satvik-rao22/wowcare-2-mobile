import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/source/attendance_source.dart';
import 'package:wowcare/redesign/features/attendance/source/preview_attendance_source.dart';

/// The fixtures the app actually runs on. A day here has to agree with the
/// roster the rest of the demo world shows, kid for kid.
void main() {
  late PreviewAttendanceSource source;

  final today = DemoData.today;

  Future<AttendanceSnapshot> loadStudents({
    Persona persona = Persona.admin,
    String query = '',
    String? scope,
  }) async {
    final result = await source.loadDay(
      persona: persona,
      audience: AttendanceAudience.students,
      day: today,
      scopeClassroom: scope,
      query: query,
    );
    return switch (result) {
      AttendanceDayLoaded(:final snapshot) => snapshot,
      AttendanceDayOffline(:final snapshot) => snapshot,
    };
  }

  setUp(() => source = PreviewAttendanceSource());

  group('PreviewAttendanceSource', () {
    test('the day is the demo roster, status for status', () async {
      final snapshot = await loadStudents();

      expect(snapshot.rows, hasLength(DemoData.students.length));
      for (final demo in DemoData.students) {
        final row = snapshot.rows.firstWhere((r) => r.id == demo.id);
        expect(
          row.status.name,
          demo.attendance.name,
          reason: '${demo.name} must read the same here as on the roster',
        );
        expect(row.classroomName, demo.classroom);
      }
    });

    test(
      'a signed-in row carries its time, its method and who took it',
      () async {
        final snapshot = await loadStudents();
        final aria = snapshot.rows.firstWhere((r) => r.id == 'aria');

        expect(aria.signedInTime, const ClockTime(8, 12));
        expect(aria.signedInMethod, isNotNull);
        expect(aria.signedInBy, 'Dana Whitfield');
      },
    );

    test(
      'a signed-out row has both times, so a duration can be worked out',
      () async {
        final snapshot = await loadStudents();
        final sam = snapshot.rows.firstWhere((r) => r.id == 'sam');

        expect(sam.status, AttendanceStatus.signedOut);
        expect(sam.signedInTime, const ClockTime(8, 6));
        expect(sam.signedOutTime, const ClockTime(9, 20));
      },
    );

    test('isExpectedToday is false for somebody who is not', () async {
      final snapshot = await loadStudents();

      expect(
        snapshot.rows.firstWhere((r) => r.id == 'elias').isExpectedToday,
        isFalse,
      );
      expect(
        snapshot.rows.firstWhere((r) => r.id == 'aria').isExpectedToday,
        isTrue,
      );
    });

    test('the transfer trail is whole', () async {
      final snapshot = await loadStudents();
      final trail = snapshot.rows.firstWhere((r) => r.id == 'omar').transfer;

      expect(trail, isNotNull);
      expect(trail!.fromClassroom, 'Sunflower');
      expect(trail.toClassroom, 'Acorn');
      expect(trail.sequenceNumber, 1);
      expect(trail.totalSequenceCount, 2);
      expect(trail.nextActionTime, const ClockTime(11, 30));
      expect(trail.transferredBy, isNotEmpty);
      expect(trail.reason, isNotEmpty);
    });

    test(
      'the two head counts are both there whichever list was asked for',
      () async {
        final snapshot = await loadStudents();

        expect(snapshot.studentsTotal, 23);
        expect(snapshot.studentsSignedIn, 15);
        expect(snapshot.staffTotal, 10);
        expect(snapshot.staffSignedIn, 7);
      },
    );

    test('searching offline returns the saved day, read only', () async {
      final result = await source.loadDay(
        persona: Persona.admin,
        audience: AttendanceAudience.students,
        day: today,
        query: 'offline',
      );

      expect(result, isA<AttendanceDayOffline>());
      expect((result as AttendanceDayOffline).asOfLabel, isNotEmpty);
    });

    test('searching empty returns a school with nobody on the roll', () async {
      final snapshot = await loadStudents(query: 'empty');
      expect(snapshot.isEmpty, isTrue);
    });

    test('searching outside puts the staff member off site', () async {
      await loadStudents(persona: Persona.staff, query: 'outside');
      expect(await source.isInsideGeofence(), isFalse);
    });

    test('a staff member sees their classroom and their own shift', () async {
      final snapshot = await loadStudents(
        persona: Persona.staff,
        scope: 'Sunflower',
      );

      expect(
        snapshot.rows.every((r) => r.classroomName == 'Sunflower'),
        isTrue,
      );
      expect(snapshot.selfShift, isNotNull);
      expect(snapshot.selfShift!.isSignedIn, isFalse);
    });

    test('a guardian sees their own children and nobody else', () async {
      final snapshot = await loadStudents(persona: Persona.guardian);

      expect(snapshot.children, hasLength(DemoData.guardianChildren.length));
      expect(snapshot.rows, hasLength(DemoData.guardianChildren.length));
    });

    test('signing somebody in changes the list behind the form', () async {
      await source.signIn(
        ids: <String>['jonah'],
        audience: AttendanceAudience.students,
        at: DateTime(2026, 8, 20, 9, 5),
      );
      final snapshot = await loadStudents();
      final jonah = snapshot.rows.firstWhere((r) => r.id == 'jonah');

      expect(jonah.status, AttendanceStatus.signedIn);
      expect(jonah.signedInTime, const ClockTime(9, 5));
      expect(jonah.signedInBy, isNotEmpty);
    });

    test(
      'an absence can be undone, which is what an override leans on',
      () async {
        await source.undoAbsence('lila');
        final snapshot = await loadStudents();
        final lila = snapshot.rows.firstWhere((r) => r.id == 'lila');

        expect(lila.status, AttendanceStatus.notMarked);
        expect(lila.absenceReason, isNull);
      },
    );

    test('a transfer writes the trail it just made', () async {
      await source.transfer(id: 'aria', toClassroom: 'Bluebell');
      final snapshot = await loadStudents();
      final aria = snapshot.rows.firstWhere((r) => r.id == 'aria');

      expect(aria.classroomName, 'Bluebell');
      expect(aria.transfer?.fromClassroom, 'Sunflower');
      expect(aria.transfer?.toClassroom, 'Bluebell');
    });

    test('the range pages, and its totals come back with it', () async {
      final range = DateRange(from: DateTime(2026, 8), to: today);
      final first = await source.loadRange(
        audience: AttendanceAudience.staff,
        range: range,
      );

      expect(first.entries, hasLength(6));
      expect(first.hasMore, isTrue);
      expect(first.totalElements, DemoData.staffMembers.length);

      final dana = first.entries.firstWhere((e) => e.id == 'dana');
      expect(dana.attendedHours, 128);
      expect(dana.attendedMinutes, 40);
      expect(dana.attendedDays, 16);

      final second = await source.loadRange(
        audience: AttendanceAudience.staff,
        range: range,
        page: 1,
      );
      expect(second.entries, hasLength(4));
      expect(second.hasMore, isFalse);
    });
  });
}
