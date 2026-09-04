import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/attendance/cubit/attendance_cubit.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/source/attendance_source.dart';

import 'attendance_test_doubles.dart';

void main() {
  late FakeAttendanceSource source;

  final today = DemoData.today;

  AttendanceCubit build({Persona persona = Persona.admin, String? scope}) =>
      AttendanceCubit(
        source: source,
        persona: persona,
        today: today,
        scopeClassroom: scope,
      );

  setUp(() => source = FakeAttendanceSource());

  group('AttendanceCubit', () {
    test('loads the day and groups it by classroom', () async {
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, AttendanceLoadStatus.ready);
      expect(cubit.state.groups.map((g) => g.title), <String>[
        'Sunflower',
        'Bluebell',
      ]);
      expect(cubit.state.groups.first.rows.length, 2);
      await cubit.close();
    });

    test('a classroom header counts the whole roll, not the filter', () async {
      final cubit = build();
      await cubit.load();
      cubit.setFilter(AttendanceFilter.absent);

      final bluebell = cubit.state.groups.single;
      expect(bluebell.title, 'Bluebell');
      expect(bluebell.rows.length, 1, reason: 'only the absent row is drawn');
      expect(bluebell.presentCount, 0, reason: 'nobody is signed in there');
      expect(bluebell.enrolled, 2);
      await cubit.close();
    });

    test('the ratio verdict is counts, worked out on the device', () async {
      final cubit = build();
      await cubit.load();

      final sunflower = cubit.state.groups.first;
      expect(sunflower.staffPresent, 1);
      expect(sunflower.staffNeeded, 0, reason: '1 in, 1 staff, limit 8');
      expect(sunflower.isShort, isFalse);
      await cubit.close();
    });

    test(
      'a classroom with students in and nobody on the clock is short',
      () async {
        source.dayResult = const AttendanceDayLoaded(
          AttendanceSnapshot(
            rows: <AttendanceRecord>[FakeAttendanceSource.aria],
            classroomNames: <String>['Sunflower'],
            enrolled: <String, int>{'Sunflower': 2},
            allowedRatio: <String, int>{'Sunflower': 8},
          ),
        );
        final cubit = build();
        await cubit.load();

        final group = cubit.state.groups.single;
        expect(group.hasNoStaff, isTrue);
        expect(group.isShort, isTrue);
        await cubit.close();
      },
    );

    test('a failed fetch is a failed state, not an empty one', () async {
      source.throwsOnRead = true;
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, AttendanceLoadStatus.failed);
      expect(cubit.state.isEmptyDay, isTrue);
      await cubit.close();
    });

    test('offline keeps the day and says when it is from', () async {
      source.dayResult = const AttendanceDayOffline(
        snapshot: FakeAttendanceSource.defaultSnapshot,
        asOfLabel: '8:02 this morning',
      );
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, AttendanceLoadStatus.offline);
      expect(cubit.state.asOfLabel, '8:02 this morning');
      expect(cubit.state.isReadOnly, isTrue);
      expect(cubit.state.canWrite, isFalse);
      await cubit.close();
    });

    test('the chips narrow the list and keep their own counts', () async {
      final cubit = build();
      await cubit.load();

      expect(cubit.state.countFor(AttendanceFilter.all), 4);
      expect(cubit.state.countFor(AttendanceFilter.signedIn), 1);
      expect(cubit.state.countFor(AttendanceFilter.absent), 1);

      cubit.setFilter(AttendanceFilter.signedIn);
      expect(cubit.state.visibleRows.single.id, 'aria');
      expect(cubit.state.countFor(AttendanceFilter.absent), 1);
      await cubit.close();
    });

    test('tapping the live chip clears it back to All', () async {
      final cubit = build();
      await cubit.load();

      cubit
        ..setFilter(AttendanceFilter.absent)
        ..setFilter(AttendanceFilter.absent);
      expect(cubit.state.filter, AttendanceFilter.all);
      await cubit.close();
    });

    test('the classroom filter hides a classroom outright', () async {
      final cubit = build();
      await cubit.load();
      cubit.setClassrooms(<String>{'Sunflower'});

      expect(
        cubit.state.visibleRows.map((r) => r.classroomName).toSet(),
        <String>{'Sunflower'},
      );
      expect(cubit.state.isNarrowed, isTrue);
      await cubit.close();
    });

    test('a search that matches nothing is no results, not empty', () async {
      final cubit = build();
      await cubit.load();
      await cubit.search('kowalski');

      expect(cubit.state.hasNoResults, isTrue);
      expect(cubit.state.isEmptyDay, isFalse);
      await cubit.close();
    });

    test('nobody absent is its own reassurance', () async {
      source.dayResult = const AttendanceDayLoaded(
        AttendanceSnapshot(
          rows: <AttendanceRecord>[FakeAttendanceSource.aria],
          classroomNames: <String>['Sunflower'],
        ),
      );
      final cubit = build();
      await cubit.load();
      cubit.setFilter(AttendanceFilter.absent);

      expect(cubit.state.isNobodyAbsent, isTrue);
      await cubit.close();
    });

    test(
      'a past day is read only and the forward step stops at today',
      () async {
        final cubit = build();
        await cubit.load();

        await cubit.stepDay(-1);
        expect(cubit.state.isToday, isFalse);
        expect(cubit.state.isReadOnly, isTrue);
        expect(cubit.state.canWrite, isFalse);

        await cubit.stepDay(1);
        expect(cubit.state.isToday, isTrue);

        await cubit.stepDay(1);
        expect(cubit.state.isToday, isTrue, reason: 'tomorrow is never a day');
        await cubit.close();
      },
    );

    test('a range choice never moves the day', () async {
      final cubit = build();
      await cubit.load();

      await cubit.chooseDay(
        DaySelection(
          choice: DayChoice.range,
          range: DateRange(from: today, to: today),
        ),
      );
      expect(cubit.state.isToday, isTrue);
      await cubit.close();
    });

    test('a staff member is locked until they sign themselves in', () async {
      final cubit = build(persona: Persona.staff, scope: 'Sunflower');
      source.dayResult = AttendanceDayLoaded(
        AttendanceSnapshot(
          rows: const <AttendanceRecord>[FakeAttendanceSource.aria],
          classroomNames: const <String>['Sunflower'],
          selfShift: source.selfShift,
        ),
      );
      await cubit.load();

      expect(cubit.state.isLocked, isTrue);
      expect(cubit.state.canWrite, isFalse);

      final done = await cubit.signSelfIn();
      expect(done, isTrue);
      expect(cubit.state.isLocked, isFalse);
      expect(cubit.state.canWrite, isTrue);
      await cubit.close();
    });

    test('outside the geofence their own sign-in is refused', () async {
      final shift = source.selfShift.copyWith(isInsideGeofence: false);
      source
        ..selfShift = shift
        ..dayResult = AttendanceDayLoaded(
          AttendanceSnapshot(
            rows: const <AttendanceRecord>[FakeAttendanceSource.aria],
            selfShift: shift,
          ),
        );
      final cubit = build(persona: Persona.staff, scope: 'Sunflower');
      await cubit.load();

      expect(await cubit.signSelfIn(), isFalse);
      expect(cubit.state.isLocked, isTrue);
      await cubit.close();
    });

    test('a guardian gets their own children and no write keys', () async {
      source.dayResult = const AttendanceDayLoaded(
        FakeAttendanceSource.guardianSnapshot,
      );
      final cubit = build(persona: Persona.guardian);
      await cubit.load();

      expect(cubit.state.snapshot.children, hasLength(1));
      expect(cubit.state.canWrite, isFalse);
      expect(cubit.state.showsAudienceSwitch, isFalse);
      await cubit.close();
    });

    test('marking absent writes a reason and reloads', () async {
      final cubit = build();
      await cubit.load();
      final before = source.loadDayCalls;

      final done = await cubit.markAbsent(id: 'jonah', reason: 'Sick');
      expect(done, isTrue);
      expect(source.lastReason, 'Sick');
      expect(source.loadDayCalls, before + 1);
      await cubit.close();
    });

    test('a failed write leaves the list alone', () async {
      final cubit = build();
      await cubit.load();
      source.throwsOnWrite = true;

      expect(
        await cubit.transfer(id: 'aria', toClassroom: 'Bluebell'),
        isFalse,
      );
      expect(cubit.state.isWorking, isFalse);
      expect(cubit.state.status, AttendanceLoadStatus.ready);
      await cubit.close();
    });

    test('select mode picks people and clears them again', () async {
      final cubit = build();
      await cubit.load();

      cubit
        ..startSelecting()
        ..toggleSelected('aria')
        ..toggleSelected('jonah');
      expect(cubit.state.selectedRows.map((r) => r.id), <String>[
        'aria',
        'jonah',
      ]);

      cubit.toggleSelected('aria');
      expect(cubit.state.selectedIds, <String>{'jonah'});

      cubit.clearSelection();
      expect(cubit.state.isSelectMode, isFalse);
      expect(cubit.state.selectedIds, isEmpty);
      await cubit.close();
    });

    test('only one row is open at a time', () async {
      final cubit = build();
      await cubit.load();

      cubit.toggleExpanded('aria');
      expect(cubit.state.expandedId, 'aria');
      cubit.toggleExpanded('jonah');
      expect(cubit.state.expandedId, 'jonah');
      cubit.toggleExpanded('jonah');
      expect(cubit.state.expandedId, isNull);
      await cubit.close();
    });

    test('the staff list is one group, and gets the cover card', () async {
      source.dayResult = const AttendanceDayLoaded(
        FakeAttendanceSource.staffSnapshot,
      );
      final cubit = build();
      await cubit.setAudience(AttendanceAudience.staff);

      expect(cubit.state.groups.single.isStaffGroup, isTrue);
      expect(cubit.state.snapshot.staffGap, isNotNull);
      await cubit.close();
    });

    test(
      'a signed-out record can be signed in again, and not marked absent',
      () {
        const record = FakeAttendanceSource.rumi;
        expect(record.canSignIn, isTrue);
        expect(record.canMarkAbsent, isFalse);
        expect(record.canEditTimes, isTrue);
        expect(record.canTransfer, isFalse);
      },
    );

    test('a signed-in record cannot be marked absent', () {
      expect(FakeAttendanceSource.aria.canMarkAbsent, isFalse);
      expect(FakeAttendanceSource.aria.canSignOut, isTrue);
      expect(FakeAttendanceSource.aria.canTransfer, isTrue);
    });

    test('an unmarked record has nothing to edit', () {
      expect(FakeAttendanceSource.jonah.canEditTimes, isFalse);
      expect(FakeAttendanceSource.jonah.canMarkAbsent, isTrue);
      expect(FakeAttendanceSource.jonah.status, AttendanceStatus.notMarked);
    });
  });
}
