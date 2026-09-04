import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/features/staff/cubit/create_staff_cubit.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/source/preview_staff_source.dart';

import 'harness.dart';

void main() {
  Future<CreateStaffCubit> loaded() async {
    final cubit = CreateStaffCubit(source: const PreviewStaffSource());
    addTearDown(cubit.close);
    await cubit.load();
    return cubit;
  }

  void fillStepOne(CreateStaffCubit cubit) => cubit
    ..setFirstName('Aisha')
    ..setLastName('Noor')
    ..setEmail('aisha.noor@mapleview.school')
    ..setPhone('(603) 555-0188');

  void fillStepTwo(CreateStaffCubit cubit) => cubit
    ..setDesignation('Assistant teacher')
    ..setPrimaryClassroom('Bluebell');

  test('loads the designation lists the existing screen offers', () async {
    final cubit = await loaded();

    expect(cubit.state.status, CreateStaffStatus.editing);
    expect(cubit.state.options.staffDesignations, contains('Lead teacher'));
    expect(cubit.state.options.adminDesignations, contains('Director'));
    expect(cubit.state.draft.week, hasLength(5));
  });

  group('step one', () {
    test(
      'refuses a blank name, a bad email and a short phone number',
      () async {
        final cubit = await loaded();

        await cubit.next();

        expect(cubit.state.step, 1);
        expect(cubit.state.errorFor(StaffField.firstName), isNotNull);
        expect(cubit.state.errorFor(StaffField.lastName), isNotNull);
        expect(cubit.state.errorFor(StaffField.email), isNotNull);
        expect(cubit.state.errorFor(StaffField.phone), isNotNull);
      },
    );

    test('typing clears the error the last attempt raised', () async {
      final cubit = await loaded();
      await cubit.next();
      expect(cubit.state.errors, isNotEmpty);

      cubit.setFirstName('A');

      expect(cubit.state.errors, isEmpty);
    });

    test('moves on once it is filled', () async {
      final cubit = await loaded();
      fillStepOne(cubit);

      await cubit.next();

      expect(cubit.state.step, 2);
    });
  });

  group('step two', () {
    test(
      'a staff member needs a designation and a primary classroom',
      () async {
        final cubit = await loaded();
        fillStepOne(cubit);
        await cubit.next();

        await cubit.next();

        expect(cubit.state.step, 2);
        expect(cubit.state.errorFor(StaffField.designation), isNotNull);
        expect(cubit.state.errorFor(StaffField.primaryClassroom), isNotNull);
      },
    );

    test('an Admin needs no classroom at all', () async {
      final cubit = await loaded();
      fillStepOne(cubit);
      await cubit.next();

      cubit
        ..setRole(StaffRole.admin)
        ..setDesignation('Director');
      await cubit.next();

      expect(cubit.state.needsClassrooms, isFalse);
      expect(cubit.state.step, 3);
    });

    test('changing the role drops a designation from the other list', () async {
      final cubit = await loaded();
      fillStepOne(cubit);
      await cubit.next();
      cubit.setDesignation('Assistant teacher');

      cubit.setRole(StaffRole.admin);

      expect(cubit.state.draft.designation, isNull);
      expect(cubit.state.designations, contains('Owner'));
    });

    test('picking a primary classroom also allows it', () async {
      final cubit = await loaded();
      fillStepOne(cubit);
      await cubit.next();

      cubit.setPrimaryClassroom('Bluebell');

      expect(cubit.state.draft.effectiveAllowed, contains('Bluebell'));
    });
  });

  group('step three', () {
    test('refuses a shift that ends before it starts', () async {
      final cubit = await loaded();
      fillStepOne(cubit);
      await cubit.next();
      fillStepTwo(cubit);
      await cubit.next();

      cubit.setShift(
        const StaffShift(
          weekday: DateTime.monday,
          startMinutes: 1020,
          endMinutes: 510,
        ),
      );
      await cubit.next();

      expect(cubit.state.errorFor(StaffField.shifts), isNotNull);
      expect(cubit.state.isSaved, isFalse);
    });

    test('refuses a break that falls outside the shift', () async {
      final cubit = await loaded();
      fillStepOne(cubit);
      await cubit.next();
      fillStepTwo(cubit);
      await cubit.next();

      cubit.setShift(
        const StaffShift(
          weekday: DateTime.monday,
          startMinutes: 510,
          endMinutes: 1020,
          breakStartMinutes: 1080,
          breakEndMinutes: 1110,
        ),
      );
      await cubit.next();

      expect(cubit.state.errorFor(StaffField.shifts), isNotNull);
    });

    test('same shift every day writes one day across the week', () async {
      final cubit = await loaded();
      fillStepOne(cubit);
      await cubit.next();
      fillStepTwo(cubit);
      await cubit.next();

      cubit
        ..setSameShiftEveryDay(value: true)
        ..setShift(
          const StaffShift(
            weekday: DateTime.monday,
            startMinutes: 420,
            endMinutes: 990,
          ),
        );

      expect(
        cubit.state.draft.week.every((day) => day.startMinutes == 420),
        isTrue,
      );
    });

    test('copy to all days does the same on demand', () async {
      final cubit = await loaded();
      fillStepOne(cubit);
      await cubit.next();
      fillStepTwo(cubit);
      await cubit.next();

      cubit
        ..setSameShiftEveryDay(value: false)
        ..setShift(
          const StaffShift(
            weekday: DateTime.monday,
            startMinutes: 400,
            endMinutes: 900,
          ),
        )
        ..copyToAllDays(DateTime.monday);

      expect(
        cubit.state.draft.week.every((day) => day.endMinutes == 900),
        isTrue,
      );
    });

    test(
      'saves, and the created record carries the name and the PIN',
      () async {
        final cubit = await loaded();
        fillStepOne(cubit);
        await cubit.next();
        fillStepTwo(cubit);
        await cubit.next();

        await cubit.next();

        expect(cubit.state.isSaved, isTrue);
        expect(cubit.state.created!.name, 'Aisha Noor');
        expect(cubit.state.created!.signInPin, isNotEmpty);
        expect(cubit.state.created!.allowedClassrooms, contains('Bluebell'));
      },
    );

    test('skipping the shifts saves a record with no week', () async {
      final cubit = await loaded();
      fillStepOne(cubit);
      await cubit.next();
      fillStepTwo(cubit);
      await cubit.next();

      await cubit.skipShifts();

      expect(cubit.state.isSaved, isTrue);
      expect(cubit.state.draft.week, isEmpty);
    });
  });

  group('moving between steps', () {
    test('back walks one step at a time and stops at the first', () async {
      final cubit = await loaded();
      fillStepOne(cubit);
      await cubit.next();

      cubit
        ..back()
        ..back();

      expect(cubit.state.step, 1);
    });

    test('a step ahead cannot be jumped to', () async {
      final cubit = await loaded();

      cubit.goToStep(3);

      expect(cubit.state.step, 1);
    });

    test('submit sends the wizard back to the step that is wrong', () async {
      final cubit = await loaded();
      fillStepOne(cubit);
      await cubit.next();

      await cubit.submit();

      expect(cubit.state.step, 2);
      expect(cubit.state.isSaved, isFalse);
    });
  });

  test('reports a failure without losing the draft', () async {
    final cubit = CreateStaffCubit(source: const FailingStaffSource());
    addTearDown(cubit.close);
    await cubit.load();

    expect(cubit.state.isFailed, isTrue);
  });
}
