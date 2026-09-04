import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/features/students/cubit/edit_student_cubit.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';

import 'students_test_doubles.dart';

void main() {
  late FakeStudentsSource source;

  EditStudentCubit build() => EditStudentCubit(
    source: source,
    studentId: 'aria',
    today: FakeStudentsSource.today,
  );

  setUp(() => source = FakeStudentsSource());

  group('EditStudentCubit', () {
    test('opens on the record as it stands', () async {
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, EditStudentStatus.ready);
      expect(cubit.state.draft.firstName, 'Aria');
      expect(cubit.state.draft.classroomName, 'Sunflower');
      expect(cubit.state.tagNames, <String>['Naps', 'Peanut allergy']);
      expect(cubit.state.canSave, isTrue);
      await cubit.close();
    });

    test('a failed load is a failed state', () async {
      source.throwsOnRead = true;
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, EditStudentStatus.failed);
      await cubit.close();
    });

    test(
      'the frame two problems: an empty name and a future birth date',
      () async {
        final cubit = build();
        await cubit.load();
        cubit.edit(
          cubit.state.draft.copyWith(
            firstName: '',
            dateOfBirth: DateTime(2027, 7, 12),
          ),
        );
        await cubit.save();

        expect(cubit.state.errors.length, 2);
        expect(cubit.state.errorFor(StudentField.firstName), isNotNull);
        expect(cubit.state.errorFor(StudentField.birthDate), isNotNull);
        expect(cubit.state.canSave, isFalse);
        expect(source.updated, isNull);
        await cubit.close();
      },
    );

    test('the messages clear as the fields are fixed', () async {
      final cubit = build();
      await cubit.load();
      cubit.edit(cubit.state.draft.copyWith(firstName: ''));
      await cubit.save();
      expect(cubit.state.hasProblems, isTrue);

      cubit.edit(cubit.state.draft.copyWith(firstName: 'Aria'));
      expect(cubit.state.hasProblems, isFalse);
      expect(cubit.state.canSave, isTrue);
      await cubit.close();
    });

    test('a clean save carries the draft and reports itself', () async {
      final cubit = build();
      await cubit.load();
      cubit.edit(
        cubit.state.draft.copyWith(
          classroomName: 'Bluebell',
          tags: const <StudentTag>[StudentTag(label: 'Naps')],
          notes: 'Collected on Fridays.',
        ),
      );
      await cubit.save();

      expect(cubit.state.status, EditStudentStatus.saved);
      expect(source.updated?.classroomName, 'Bluebell');
      expect(source.updated?.tags.single.label, 'Naps');
      await cubit.close();
    });

    test('a save that fails leaves the form open and says so', () async {
      source.throwsOnWrite = true;
      final cubit = build();
      await cubit.load();
      await cubit.save();

      expect(cubit.state.status, EditStudentStatus.ready);
      expect(cubit.state.hasSaveFailed, isTrue);

      cubit.clearFailure();
      expect(cubit.state.hasSaveFailed, isFalse);
      await cubit.close();
    });
  });
}
