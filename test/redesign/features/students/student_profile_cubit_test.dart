import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/students/cubit/student_profile_cubit.dart';

import 'students_test_doubles.dart';

void main() {
  late FakeStudentsSource source;

  StudentProfileCubit build({Persona persona = Persona.admin}) =>
      StudentProfileCubit(source: source, studentId: 'aria', persona: persona);

  setUp(() => source = FakeStudentsSource());

  group('StudentProfileCubit', () {
    test('loads the whole record in one fetch', () async {
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, ProfileStatus.ready);
      expect(cubit.state.record?.student.firstName, 'Aria');
      expect(cubit.state.record?.guardians.length, 1);
      expect(cubit.state.record?.documents.length, 1);
      await cubit.close();
    });

    test('a failed fetch is a failed state', () async {
      source.throwsOnRead = true;
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, ProfileStatus.failed);
      expect(cubit.state.record, isNull);
      await cubit.close();
    });

    test('tabs and sections switch without fetching again', () async {
      final cubit = build();
      await cubit.load();

      cubit
        ..selectTab(ProfileTab.health)
        ..selectHealthSection(HealthSection.immunization);
      expect(cubit.state.tab, ProfileTab.health);
      expect(cubit.state.healthSection, HealthSection.immunization);
      expect(cubit.state.hasSections, isTrue);

      cubit.selectTab(ProfileTab.attendance);
      expect(cubit.state.hasSections, isFalse);
      await cubit.close();
    });

    test('an overdue vaccine is the one the tab warns about', () async {
      final cubit = build();
      await cubit.load();

      expect(cubit.state.record?.overdueImmunization?.name, 'Varicella');
      await cubit.close();
    });

    test('the emergency contact is who is called first', () async {
      final cubit = build();
      await cubit.load();

      expect(cubit.state.record?.emergencyContact?.name, 'Nadia Rowan');
      await cubit.close();
    });

    test('staff read the record; the family may still edit health', () async {
      final cubit = build(persona: Persona.staff);
      await cubit.load();

      expect(cubit.state.canWrite, isFalse);
      expect(cubit.state.canEditHealth, isTrue);
      await cubit.close();
    });
  });
}
