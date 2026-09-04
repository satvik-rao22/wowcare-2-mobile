import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/classrooms/cubit/classroom_cubit.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/source/preview_classrooms_source.dart';

import 'harness.dart';

ClassroomCubit build({
  Persona persona = Persona.admin,
  String id = PreviewClassroomsSource.sunflowerId,
  bool isOwn = false,
}) => ClassroomCubit(
  source: const PreviewClassroomsSource(),
  classroomId: id,
  persona: persona,
  isOwnClassroom: isOwn,
);

void main() {
  group('ClassroomCubit', () {
    test('loads the roster, the staff and the notes', () async {
      final cubit = build();
      expect(cubit.state.status, ClassroomStatus.loading);

      await cubit.load();

      expect(cubit.state.status, ClassroomStatus.ready);
      expect(cubit.state.detail!.students.length, 14);
      expect(cubit.state.detail!.staff.length, 4);
      expect(cubit.state.detail!.notes.length, 5);
      expect(cubit.state.detail!.newNoteCount, 2);
      await cubit.close();
    });

    test('the ratio is arithmetic, and it is In Ratio here', () async {
      final cubit = build();
      await cubit.load();

      final summary = cubit.state.summary!;
      expect(summary.studentsPresent, 14);
      expect(summary.staffPresent, 3);
      expect(cubit.state.detail!.staffWanted, 2);
      expect(summary.staffNeeded, 0);
      expect(summary.isInRatio, isTrue);
      await cubit.close();
    });

    test('a short classroom names how many more staff it wants', () async {
      final cubit = build(id: PreviewClassroomsSource.bluebellId);
      await cubit.load();

      expect(cubit.state.summary!.staffNeeded, 1);
      expect(cubit.state.summary!.ratioState, ClassroomRatioState.short);
      await cubit.close();
    });

    test('the two roster toggles are exclusive', () async {
      final cubit = build();
      await cubit.load();

      cubit.toggleSignedInOnly();
      expect(cubit.state.studentFilters.signedInOnly, isTrue);
      expect(
        cubit.state.visibleStudents.every(
          (s) => s.attendance == AttendanceStatus.signedIn,
        ),
        isTrue,
      );

      cubit.toggleNappingOnly();
      expect(cubit.state.studentFilters.signedInOnly, isFalse);
      expect(cubit.state.studentFilters.nappingOnly, isTrue);
      expect(cubit.state.visibleStudents.every((s) => s.isNapping), isTrue);
      await cubit.close();
    });

    test(
      'search inside the classroom, and the empty state it leaves',
      () async {
        final cubit = build();
        await cubit.load();

        cubit.search('theo');
        expect(cubit.state.visibleStudents.length, 1);

        cubit.search('brennan');
        expect(cubit.state.hasNoStudentMatches, isTrue);
        expect(cubit.state.hasNoStudents, isFalse);

        cubit.clearSearch();
        expect(cubit.state.visibleStudents.length, 14);
        await cubit.close();
      },
    );

    test('one row opens at a time', () async {
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

    test('select mode picks, selects all and clears', () async {
      final cubit = build();
      await cubit.load();

      cubit.toggleSelectMode();
      expect(cubit.state.isSelectMode, isTrue);

      cubit.toggleSelected('aria');
      expect(cubit.state.selectedIds, <String>{'aria'});
      cubit.toggleSelected('aria');
      expect(cubit.state.selectedIds, isEmpty);

      cubit.selectAll();
      expect(cubit.state.selectedIds.length, 14);
      cubit.clearSelection();
      expect(cubit.state.selectedIds, isEmpty);
      await cubit.close();
    });

    test(
      'a teacher gets two tabs and a locked roster until they clock in',
      () async {
        final cubit = build(persona: Persona.staff, isOwn: true);
        await cubit.load();

        expect(cubit.state.isTeacherView, isTrue);
        expect(cubit.state.tabs, <ClassroomTab>[
          ClassroomTab.students,
          ClassroomTab.notes,
        ]);
        expect(cubit.state.isLocked, isTrue);
        expect(cubit.state.canEdit, isFalse);

        cubit.clockIn();
        expect(cubit.state.isLocked, isFalse);
        await cubit.close();
      },
    );

    test('a role that cannot change anything writes nothing', () async {
      final cubit = build(persona: Persona.guardian);
      await cubit.load();
      final before = cubit.state.detail!.students.length;

      await cubit.removeStudent('aria');

      expect(cubit.state.detail!.students.length, before);
      await cubit.close();
    });

    test('removing a student takes them off the roll and the roster', () async {
      final cubit = build();
      await cubit.load();

      await cubit.removeStudent('aria');

      expect(cubit.state.detail!.students.any((s) => s.id == 'aria'), isFalse);
      expect(cubit.state.detail!.summary.enrolled, 13);
      expect(cubit.state.isWorking, isFalse);
      await cubit.close();
    });

    test('a note lands at the end of the thread', () async {
      final cubit = build();
      await cubit.load();

      await cubit.postNote('  Water table is out until 11.  ');

      final note = cubit.state.detail!.notes.last;
      expect(note.text, 'Water table is out until 11.');
      expect(note.isMine, isTrue);
      await cubit.close();
    });

    test('nothing loaded and nothing reachable fails outright', () async {
      final cubit = ClassroomCubit(
        source: const FailingClassroomsSource(),
        classroomId: PreviewClassroomsSource.sunflowerId,
        persona: Persona.admin,
        isOwnClassroom: false,
      );
      await cubit.load();

      expect(cubit.state.status, ClassroomStatus.failed);
      await cubit.close();
    });

    test('a classroom with nobody on the roll is its own state', () async {
      final cubit = build(id: PreviewClassroomsSource.willowId);
      await cubit.load();

      expect(cubit.state.hasNoStudents, isTrue);
      expect(cubit.state.summary!.ratioState, ClassroomRatioState.empty);
      await cubit.close();
    });
  });
}
