import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/features/profile/cubit/change_password_cubit.dart';
import 'package:wowcare/redesign/features/profile/models/models.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';

import 'profile_test_doubles.dart';

void main() {
  late FakeProfileSource source;

  ChangePasswordCubit build() =>
      ChangePasswordCubit(source: source, userId: 'marcus');

  setUp(() => source = FakeProfileSource());

  group('ChangePasswordCubit', () {
    test('an empty form is refused on the first press', () async {
      final cubit = build();
      await cubit.submit();

      expect(
        cubit.state.errors.current,
        ProfileStrings.currentPasswordRequired,
      );
      expect(cubit.state.errors.next, ProfileStrings.newPasswordRequired);
      expect(cubit.state.canSubmit, isFalse);
      expect(source.changedTo, isNull);
      await cubit.close();
    });

    test('a new password without a special character is refused', () async {
      final cubit = build();
      cubit.edit(
        const PasswordFormData(
          current: 'oldpass!1',
          next: 'plainpassword',
          confirm: 'plainpassword',
        ),
      );
      await cubit.submit();

      expect(cubit.state.errors.next, ProfileStrings.newPasswordInvalid);
      await cubit.close();
    });

    test('a confirmation that does not match is refused', () async {
      final cubit = build();
      cubit.edit(
        const PasswordFormData(
          current: 'oldpass!1',
          next: 'newpass!1',
          confirm: 'newpass!2',
        ),
      );
      await cubit.submit();

      expect(cubit.state.errors.confirm, ProfileStrings.confirmMismatch);
      await cubit.close();
    });

    test('a new password the same as the current one is refused', () async {
      final cubit = build();
      cubit.edit(
        const PasswordFormData(
          current: 'samepass!1',
          next: 'samepass!1',
          confirm: 'samepass!1',
        ),
      );
      await cubit.submit();

      expect(cubit.state.errors.next, ProfileStrings.newSameAsCurrent);
      await cubit.close();
    });

    test('a message clears the moment the well is right', () async {
      final cubit = build();
      await cubit.submit();
      expect(cubit.state.hasProblems, isTrue);

      cubit.edit(
        const PasswordFormData(
          current: 'oldpass!1',
          next: 'newpass!1',
          confirm: 'newpass!1',
        ),
      );
      expect(cubit.state.hasProblems, isFalse);
      expect(cubit.state.canSubmit, isTrue);
      await cubit.close();
    });

    test('a clean change is sent and reported', () async {
      final cubit = build();
      cubit.edit(
        const PasswordFormData(
          current: 'oldpass!1',
          next: 'newpass!1',
          confirm: 'newpass!1',
        ),
      );
      await cubit.submit();

      expect(cubit.state.status, ChangePasswordStatus.saved);
      expect(source.changedFrom, 'oldpass!1');
      expect(source.changedTo, 'newpass!1');
      await cubit.close();
    });

    test('a change that fails leaves the form open and says so', () async {
      source.throwsOnWrite = true;
      final cubit = build();
      cubit.edit(
        const PasswordFormData(
          current: 'oldpass!1',
          next: 'newpass!1',
          confirm: 'newpass!1',
        ),
      );
      await cubit.submit();

      expect(cubit.state.status, ChangePasswordStatus.editing);
      expect(cubit.state.hasSaveFailed, isTrue);

      cubit.clearFailure();
      expect(cubit.state.hasSaveFailed, isFalse);
      await cubit.close();
    });
  });
}
