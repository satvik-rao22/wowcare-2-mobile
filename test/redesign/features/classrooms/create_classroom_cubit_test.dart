import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/cubit/create_classroom_cubit.dart';
import 'package:wowcare/redesign/features/classrooms/source/preview_classrooms_source.dart';

import 'harness.dart';

CreateClassroomCubit build() =>
    CreateClassroomCubit(source: const PreviewClassroomsSource());

void fill(CreateClassroomCubit cubit) => cubit
  ..setName('Rosemary')
  ..setAgeFrom('24')
  ..setAgeTo('36')
  ..setCapacity('16')
  ..setStudentsPerStaff('8');

void main() {
  group('CreateClassroomCubit', () {
    test('an empty form names every field that is missing', () async {
      final cubit = build();

      await cubit.submit();

      expect(cubit.state.status, CreateClassroomStatus.editing);
      expect(
        cubit.state.errorFor(ClassroomField.name),
        ClassroomsStrings.nameRequired,
      );
      expect(
        cubit.state.errorFor(ClassroomField.capacity),
        ClassroomsStrings.capacityInvalid,
      );
      expect(
        cubit.state.errorFor(ClassroomField.studentsPerStaff),
        ClassroomsStrings.ratioInvalid,
      );
      await cubit.close();
    });

    test('an age band that runs backwards is refused', () async {
      final cubit = build();
      fill(cubit);
      cubit.setAgeTo('12');

      await cubit.submit();

      expect(
        cubit.state.errorFor(ClassroomField.ageTo),
        ClassroomsStrings.ageInvalid,
      );
      await cubit.close();
    });

    test('typing clears what the last submit complained about', () async {
      final cubit = build();
      await cubit.submit();
      expect(cubit.state.errors, isNotEmpty);

      cubit.setName('Rosemary');

      expect(cubit.state.errors, isEmpty);
      await cubit.close();
    });

    test('a filled form creates the classroom', () async {
      final cubit = build();
      fill(cubit);

      await cubit.submit();

      expect(cubit.state.status, CreateClassroomStatus.saved);
      expect(cubit.state.created!.name, 'Rosemary');
      expect(cubit.state.created!.id, 'rosemary');
      expect(cubit.state.created!.capacity, 16);
      expect(cubit.state.created!.allowedRatio, 8);
      expect(cubit.state.created!.enrolled, 0);
      await cubit.close();
    });

    test('a write that does not land says so', () async {
      final cubit = CreateClassroomCubit(
        source: const FailingClassroomsSource(),
      );
      fill(cubit);

      await cubit.submit();

      expect(cubit.state.status, CreateClassroomStatus.failed);
      await cubit.close();
    });
  });
}
