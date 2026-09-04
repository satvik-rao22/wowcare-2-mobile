import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/features/classrooms/cubit/assign_cubit.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/source/preview_classrooms_source.dart';

import 'harness.dart';

AssignCubit build({
  AssignKind kind = AssignKind.students,
  String id = PreviewClassroomsSource.sunflowerId,
}) => AssignCubit(
  source: const PreviewClassroomsSource(),
  classroomId: id,
  kind: kind,
);

void main() {
  group('AssignCubit', () {
    test('loads the classroom and everybody who could join it', () async {
      final cubit = build();
      expect(cubit.state.status, AssignStatus.loading);

      await cubit.load();

      expect(cubit.state.status, AssignStatus.ready);
      expect(cubit.state.classroomName, 'Sunflower');
      expect(cubit.state.candidates, isNotEmpty);
      expect(
        cubit.state.candidates.any((c) => c.id == 'aria'),
        isFalse,
        reason: 'somebody already on this roster is not a candidate',
      );
      await cubit.close();
    });

    test('candidates group by where they are now', () async {
      final cubit = build();
      await cubit.load();

      expect(cubit.state.groups.keys, contains('Bluebell'));
      expect(cubit.state.groups.keys, contains('Unassigned'));

      cubit.selectGroup('Unassigned');
      expect(cubit.state.visible.every((c) => c.group == 'Unassigned'), isTrue);
      await cubit.close();
    });

    test('the age band warns rather than blocks', () async {
      final cubit = build();
      await cubit.load();

      final outside = cubit.state.candidates.where((c) => c.isOutsideAgeRange);
      expect(outside, isNotEmpty);

      cubit.toggle(outside.first.id);
      expect(cubit.state.pickedOutsideAgeRange.length, 1);

      cubit.toReview();
      expect(cubit.state.isReview, isTrue, reason: 'a warning is not a block');
      await cubit.close();
    });

    test('review needs at least one pick', () async {
      final cubit = build();
      await cubit.load();

      cubit.toReview();
      expect(cubit.state.step, AssignStep.pick);

      cubit
        ..toggle('rumi')
        ..toReview();
      expect(cubit.state.step, AssignStep.review);

      cubit.toPick();
      expect(cubit.state.step, AssignStep.pick);
      await cubit.close();
    });

    test('the review step says what the roll becomes', () async {
      final cubit = build();
      await cubit.load();

      cubit
        ..toggle('rumi')
        ..toggle('beau');

      expect(cubit.state.enrolledAfter, 25);
      expect(cubit.state.classroom!.capacity, 26);
      await cubit.close();
    });

    test('assigning staff counts staff, not students', () async {
      final cubit = build(kind: AssignKind.staff);
      await cubit.load();

      expect(cubit.state.isStudents, isFalse);
      expect(cubit.state.candidates.any((c) => c.id == 'dana'), isFalse);

      cubit.toggle('priya');
      expect(cubit.state.staffAfter, 4);
      expect(cubit.state.classroom!.holdsWithStaff(4), 32);
      await cubit.close();
    });

    test('submitting applies and finishes', () async {
      final cubit = build();
      await cubit.load();
      cubit
        ..toggle('rumi')
        ..toReview();

      final pending = cubit.submit();
      expect(cubit.state.isSubmitting, isTrue);
      await pending;

      expect(cubit.state.status, AssignStatus.done);
      await cubit.close();
    });

    test('nothing reachable fails outright', () async {
      final cubit = AssignCubit(
        source: const FailingClassroomsSource(),
        classroomId: PreviewClassroomsSource.sunflowerId,
        kind: AssignKind.students,
      );
      await cubit.load();

      expect(cubit.state.status, AssignStatus.failed);
      await cubit.close();
    });
  });
}
