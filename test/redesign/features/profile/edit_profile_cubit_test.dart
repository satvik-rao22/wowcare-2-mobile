import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/features/profile/cubit/edit_profile_cubit.dart';
import 'package:wowcare/redesign/features/profile/models/models.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';

import 'profile_test_doubles.dart';

void main() {
  late FakeProfileSource source;

  EditProfileCubit build({String id = 'marcus'}) =>
      EditProfileCubit(source: source, userId: id);

  setUp(() => source = FakeProfileSource());

  group('EditProfileCubit', () {
    test('13b: the form opens on the record as it stands', () async {
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, EditProfileStatus.ready);
      expect(cubit.state.form.firstName, 'Marcus');
      expect(cubit.state.form.city, 'Nashua');
      expect(cubit.state.email, 'marcus.whitfield@mapleview.school');
      expect(cubit.state.country, 'United States');
      expect(cubit.state.stateNames, contains('New Hampshire'));
      expect(cubit.state.canSave, isTrue);
      await cubit.close();
    });

    test('a failed load is a failed state', () async {
      source.throwsOnRead = true;
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, EditProfileStatus.failed);
      await cubit.close();
    });

    test('13b: the frame four refusals, each on its own field', () async {
      final cubit = build();
      await cubit.load();
      cubit.edit(
        cubit.state.form.copyWith(
          firstName: 'Marcus1',
          phone: '(615) 442-908',
          city: '',
          zipCode: '',
        ),
      );
      await cubit.save();

      expect(cubit.state.errors.firstName, ProfileStrings.firstNameInvalid);
      expect(cubit.state.errors.phone, ProfileStrings.phoneInvalid);
      expect(cubit.state.errors.city, ProfileStrings.cityRequired);
      expect(cubit.state.errors.zipCode, ProfileStrings.zipRequired);
      expect(cubit.state.canSave, isFalse);
      expect(source.saved, isNull);
      await cubit.close();
    });

    test('a message clears the moment the field is right', () async {
      final cubit = build();
      await cubit.load();
      cubit.edit(cubit.state.form.copyWith(firstName: ''));
      await cubit.save();
      expect(cubit.state.hasProblems, isTrue);

      cubit.edit(cubit.state.form.copyWith(firstName: 'Marcus'));
      expect(cubit.state.hasProblems, isFalse);
      expect(cubit.state.canSave, isTrue);
      await cubit.close();
    });

    test("a guardian's address is optional; a staff member's is not", () async {
      source.snapshot = const ProfileSnapshot(
        record: FakeProfileSource.guardianRecord,
      );
      final cubit = build(id: 'ngozi');
      await cubit.load();
      expect(cubit.state.isAddressRequired, isFalse);

      cubit.edit(
        cubit.state.form.copyWith(street: '', city: '', zipCode: '', state: ''),
      );
      await cubit.save();

      expect(cubit.state.status, EditProfileStatus.saved);
      await cubit.close();
    });

    test('a clean save carries the form and reports itself', () async {
      final cubit = build();
      await cubit.load();
      cubit.edit(cubit.state.form.copyWith(city: 'Manchester'));
      await cubit.save();

      expect(cubit.state.status, EditProfileStatus.saved);
      expect(source.saved?.city, 'Manchester');
      await cubit.close();
    });

    test('a save that fails leaves the form open and says so', () async {
      source.throwsOnWrite = true;
      final cubit = build();
      await cubit.load();
      await cubit.save();

      expect(cubit.state.status, EditProfileStatus.ready);
      expect(cubit.state.hasSaveFailed, isTrue);

      cubit.clearFailure();
      expect(cubit.state.hasSaveFailed, isFalse);
      await cubit.close();
    });
  });
}
