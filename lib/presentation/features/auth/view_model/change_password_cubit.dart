import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/validators/app_validators.dart';

part 'change_password_state.dart';

/// Owns the "Change Password" bottom sheet's submit flow. The view only
/// ever reads this cubit's state and calls [submit].
///
/// NOTE: there is no change-password endpoint/usecase anywhere in this
/// codebase yet (confirmed repo-wide — this screen isn't wired to a
/// backend call site at all today). [submit] therefore validates and
/// reports success the same way the screen's previous inline stub did;
/// wire a real usecase into this method once the backend contract exists.
class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  ChangePasswordCubit() : super(const ChangePasswordInitial());

  Future<void> submit({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (currentPassword.isEmpty) {
      emit(
        const ChangePasswordFailure('Please enter your current password'),
      );
      return;
    }
    if (newPassword.isEmpty) {
      emit(const ChangePasswordFailure('Please enter a new password'));
      return;
    }
    if (!AppValidators.isStrongPassword(newPassword)) {
      emit(
        const ChangePasswordFailure(
          'Password must contain at least 8 characters and one special character',
        ),
      );
      return;
    }
    if (newPassword != confirmPassword) {
      emit(
        const ChangePasswordFailure(
          'New password and confirm password do not match',
        ),
      );
      return;
    }
    if (currentPassword == newPassword) {
      emit(
        const ChangePasswordFailure(
          'New password must be different from current password',
        ),
      );
      return;
    }

    emit(const ChangePasswordLoading());

    // TODO: replace with the real change-password usecase once one exists.
    await Future<void>.delayed(const Duration(seconds: 1));
    if (isClosed) return;

    emit(const ChangePasswordSuccess('Password changed successfully'));
  }

  void reset() => emit(const ChangePasswordInitial());
}
