import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/features/students/cubit/add_student_cubit.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';

import 'students_test_doubles.dart';

void main() {
  late FakeStudentsSource source;

  AddStudentCubit build() =>
      AddStudentCubit(source: source, today: FakeStudentsSource.today);

  StudentDraft validStep1(StudentDraft draft) => draft.copyWith(
    firstName: 'Bo',
    lastName: 'Chen',
    classroomName: 'Bluebell',
    dateOfBirth: DateTime(2025, 2, 14),
  );

  setUp(() => source = FakeStudentsSource());

  group('AddStudentCubit', () {
    test('loads the pickers and seeds the week', () async {
      final cubit = build();
      await cubit.load();

      expect(cubit.state.isLoadingOptions, isFalse);
      expect(cubit.state.classrooms, <String>['Sunflower', 'Bluebell']);
      expect(cubit.state.draft.week.length, 5);
      await cubit.close();
    });

    test('step one will not be left with fields missing', () async {
      final cubit = build();
      await cubit.load();
      await cubit.next();

      expect(cubit.state.step, 1);
      expect(cubit.state.errorFor(StudentField.firstName), isNotNull);
      expect(cubit.state.errorFor(StudentField.classroom), isNotNull);
      await cubit.close();
    });

    test('a birth date in the future is refused', () async {
      final cubit = build();
      await cubit.load();
      cubit.edit(
        validStep1(cubit.state.draft).copyWith(dateOfBirth: DateTime(2027, 7)),
      );
      await cubit.next();

      expect(cubit.state.step, 1);
      expect(cubit.state.errorFor(StudentField.birthDate), isNotNull);
      await cubit.close();
    });

    test(
      'an upcoming student needs a school start date in the future',
      () async {
        final cubit = build();
        await cubit.load();
        cubit.edit(
          validStep1(cubit.state.draft).copyWith(
            status: StudentStatus.upcoming,
            schoolStartDate: DateTime(2020),
          ),
        );
        await cubit.next();

        expect(cubit.state.errorFor(StudentField.schoolStartDate), isNotNull);
        await cubit.close();
      },
    );

    test(
      'a fixed field goes quiet without waiting for the next attempt',
      () async {
        final cubit = build();
        await cubit.load();
        await cubit.next();
        expect(cubit.state.errorFor(StudentField.firstName), isNotNull);

        cubit.edit(cubit.state.draft.copyWith(firstName: 'Bo'));
        expect(cubit.state.errorFor(StudentField.firstName), isNull);
        await cubit.close();
      },
    );

    test(
      'the same last name is offered as a sibling before the save',
      () async {
        source.siblings = <StudentSummary>[
          FakeStudentsSource.student(id: 'ivy', first: 'Ivy', last: 'Chen'),
        ];
        final cubit = build();
        await cubit.load();
        cubit.edit(validStep1(cubit.state.draft));
        await cubit.next();

        expect(cubit.state.siblings.length, 1);
        expect(cubit.state.step, 1, reason: 'the question is asked in place');

        cubit.linkSibling(cubit.state.siblings.first);
        expect(cubit.state.draft.siblingId, 'ivy');
        expect(cubit.state.step, 2);
        await cubit.close();
      },
    );

    test('saying no to the sibling still moves on', () async {
      source.siblings = <StudentSummary>[
        FakeStudentsSource.student(id: 'ivy', first: 'Ivy', last: 'Chen'),
      ];
      final cubit = build();
      await cubit.load();
      cubit.edit(validStep1(cubit.state.draft));
      await cubit.next();
      cubit.dismissSiblings();

      expect(cubit.state.draft.siblingId, isNull);
      expect(cubit.state.step, 2);
      await cubit.close();
    });

    test('step two is checked when taken and skipped when skipped', () async {
      final cubit = build();
      await cubit.load();
      cubit.edit(validStep1(cubit.state.draft));
      await cubit.next();

      await cubit.next();
      expect(cubit.state.step, 2);
      expect(cubit.state.errorFor(StudentField.guardian), isNotNull);

      await cubit.skip();
      expect(cubit.state.step, 3);
      await cubit.close();
    });

    test('the last step saves, and the save carries the draft', () async {
      final cubit = build();
      await cubit.load();
      cubit.edit(validStep1(cubit.state.draft));
      await cubit.next();
      await cubit.skip();
      await cubit.next();

      expect(cubit.state.status, AddStudentStatus.saved);
      expect(cubit.state.saved?.fullName, 'Bo Chen');
      expect(source.created?.classroomName, 'Bluebell');
      await cubit.close();
    });

    test('a failed save says so and leaves the answers alone', () async {
      source.throwsOnWrite = true;
      final cubit = build();
      await cubit.load();
      cubit.edit(validStep1(cubit.state.draft));
      await cubit.save();

      expect(cubit.state.status, AddStudentStatus.failed);
      expect(cubit.state.draft.firstName, 'Bo');

      cubit.clearFailure();
      expect(cubit.state.status, AddStudentStatus.editing);
      await cubit.close();
    });

    test('Copy to all days puts Monday on every day', () async {
      final cubit = build();
      await cubit.load();
      final monday = cubit.state.draft.week.first.copyWith(
        startMinutes: 8 * 60,
        endMinutes: 15 * 60,
      );
      cubit.edit(
        cubit.state.draft.copyWith(
          week: <ScheduleEntry>[monday, ...cubit.state.draft.week.skip(1)],
        ),
      );
      cubit.copyTimesToAllDays();

      expect(
        cubit.state.draft.week.every((d) => d.startMinutes == 8 * 60),
        isTrue,
      );
      await cubit.close();
    });

    test('a step ahead cannot be jumped to; one behind can', () async {
      final cubit = build();
      await cubit.load();

      cubit.goToStep(3);
      expect(cubit.state.step, 1);

      cubit.edit(validStep1(cubit.state.draft));
      await cubit.next();
      cubit.goToStep(1);
      expect(cubit.state.step, 1);
      await cubit.close();
    });
  });
}
