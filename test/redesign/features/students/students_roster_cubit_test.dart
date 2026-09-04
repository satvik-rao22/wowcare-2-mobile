import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/students/cubit/students_roster_cubit.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/source/students_source.dart';

import 'students_test_doubles.dart';

void main() {
  late FakeStudentsSource source;

  StudentsRosterCubit build({Persona persona = Persona.admin, String? scope}) =>
      StudentsRosterCubit(
        source: source,
        persona: persona,
        scopeClassroom: scope,
      );

  setUp(() => source = FakeStudentsSource());

  group('StudentsRosterCubit', () {
    test('loads the roster and groups it by classroom', () async {
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, RosterStatus.ready);
      expect(cubit.state.snapshot.activeCount, 3);
      expect(cubit.state.groups.map((g) => g.classroomName), <String>[
        'Sunflower',
        'Bluebell',
      ]);
      expect(cubit.state.groups.first.students.length, 2);
      await cubit.close();
    });

    test('a group counts today for its own header', () async {
      final cubit = build();
      await cubit.load();

      final sunflower = cubit.state.groups.first;
      expect(sunflower.signedIn, 1);
      expect(sunflower.notMarked, 1);
      expect(sunflower.absent, 0);
      await cubit.close();
    });

    test('a failed fetch is a failed state, not an empty one', () async {
      source.throwsOnRead = true;
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, RosterStatus.failed);
      expect(cubit.state.isEmptySchool, isTrue);
      await cubit.close();
    });

    test('a guardian is refused outright', () async {
      source.roster = const RosterRestricted();
      final cubit = build(persona: Persona.guardian);
      await cubit.load();

      expect(cubit.state.status, RosterStatus.restricted);
      expect(cubit.state.canWrite, isFalse);
      await cubit.close();
    });

    test('offline keeps the saved roster and says when it is from', () async {
      source.roster = RosterOffline(
        snapshot: FakeStudentsSource.defaultSnapshot,
        asOfLabel: '8:12 this morning',
      );
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, RosterStatus.offline);
      expect(cubit.state.asOfLabel, '8:12 this morning');
      expect(cubit.state.savedCount, 3);
      await cubit.close();
    });

    test('staff see one classroom and cannot write', () async {
      final cubit = build(persona: Persona.staff, scope: 'Sunflower');
      await cubit.load();

      expect(cubit.state.canWrite, isFalse);
      expect(cubit.state.scopeClassroom, 'Sunflower');
      await cubit.close();
    });

    test('search narrows on the name and on the parent', () async {
      final cubit = build();
      await cubit.load();

      await cubit.search('tanaka');
      expect(cubit.state.visibleStudents.single.firstName, 'Rumi');

      await cubit.search('nadia');
      expect(cubit.state.visibleStudents.single.firstName, 'Aria');
      await cubit.close();
    });

    test('a search that matches nobody is not an empty school', () async {
      final cubit = build();
      await cubit.load();
      await cubit.search('kowalski');

      expect(cubit.state.hasNoResults, isTrue);
      expect(cubit.state.isEmptySchool, isFalse);
      await cubit.close();
    });

    test('the filter narrows on classroom, tag and attendance', () async {
      final cubit = build();
      await cubit.load();

      cubit.applyFilter(const StudentFilter(classrooms: <String>{'Bluebell'}));
      expect(cubit.state.visibleStudents.single.firstName, 'Rumi');

      cubit.applyFilter(const StudentFilter(tags: <String>{'Naps'}));
      expect(cubit.state.visibleStudents.single.firstName, 'Rumi');

      cubit.applyFilter(
        const StudentFilter(
          attendance: <AttendanceStatus>{AttendanceStatus.notMarked},
        ),
      );
      expect(cubit.state.visibleStudents.single.firstName, 'Theo');
      await cubit.close();
    });

    test(
      'the Upcoming status shows the students who have not started',
      () async {
        final cubit = build();
        await cubit.load();
        cubit.applyFilter(const StudentFilter(status: StudentStatus.upcoming));

        expect(cubit.state.visibleStudents.single.firstName, 'Bo');
        await cubit.close();
      },
    );

    test('Clear all puts the roster back', () async {
      final cubit = build();
      await cubit.load();
      await cubit.search('kowalski');
      cubit.applyFilter(const StudentFilter(tags: <String>{'Naps'}));

      cubit.clearFilters();
      expect(cubit.state.isNarrowed, isFalse);
      expect(cubit.state.visibleStudents.length, 3);
      await cubit.close();
    });

    test(
      'Starting soon is a section of the roster, not a filter of it',
      () async {
        final cubit = build();
        await cubit.load();
        expect(cubit.state.startingSoon.length, 1);

        await cubit.search('aria');
        expect(cubit.state.startingSoon, isEmpty);
        await cubit.close();
      },
    );

    test('only one row is open at a time', () async {
      final cubit = build();
      await cubit.load();

      cubit.toggleExpanded('aria');
      expect(cubit.state.expandedId, 'aria');
      cubit.toggleExpanded('theo');
      expect(cubit.state.expandedId, 'theo');
      cubit.toggleExpanded('theo');
      expect(cubit.state.expandedId, isNull);
      await cubit.close();
    });

    test('select mode collects ids and clears them on the way out', () async {
      final cubit = build();
      await cubit.load();

      cubit.toggleSelectMode();
      cubit
        ..toggleSelected('aria')
        ..toggleSelected('theo')
        ..toggleSelected('aria');
      expect(cubit.state.selectedIds, <String>{'theo'});

      cubit.toggleSelectMode();
      expect(cubit.state.isSelectMode, isFalse);
      expect(cubit.state.selectedIds, isEmpty);
      await cubit.close();
    });

    test('deactivating reloads the roster', () async {
      final cubit = build();
      await cubit.load();
      final before = source.rosterCalls;

      final done = await cubit.deactivate('aria');
      expect(done, isTrue);
      expect(source.deactivated, 'aria');
      expect(source.rosterCalls, before + 1);
      await cubit.close();
    });

    test(
      'a deactivate that fails says so and leaves the roster alone',
      () async {
        source.throwsOnWrite = true;
        final cubit = build();
        await cubit.load();

        expect(await cubit.deactivate('aria'), isFalse);
        expect(cubit.state.isWorking, isFalse);
        await cubit.close();
      },
    );

    test('a silent refresh does not flash the loading state', () async {
      final cubit = build();
      await cubit.load();

      final statuses = <RosterStatus>[];
      final sub = cubit.stream.listen((s) => statuses.add(s.status));
      await cubit.refresh();
      await sub.cancel();

      expect(statuses, isNot(contains(RosterStatus.loading)));
      await cubit.close();
    });
  });
}
