import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/features/profile/models/models.dart';
import 'package:wowcare/redesign/features/profile/source/profile_source.dart';

part 'change_password_state.dart';

/// Change Password, opened from the actions card on 13a and 13c.
///
/// Three wells and one key. The rules are the shipped screen's, in the same
/// order: the current password is required, the new one needs eight
/// characters and a special character, the confirmation has to match, and the
/// new one has to be different from the current one.
class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  ChangePasswordCubit({required ProfileSource source, required String userId})
    : _source = source,
      super(ChangePasswordState(userId: userId));

  final ProfileSource _source;

  /// Writes [form] and, once the key has been pressed once, re-checks it, so
  /// a message clears the moment the well is right.
  void edit(PasswordFormData form) {
    final errors = state.hasTriedSave
        ? PasswordFormValidator.validate(form)
        : state.errors;
    emit(state.copyWith(form: form, errors: errors));
  }

  Future<void> submit() async {
    if (state.isSaving) return;

    final errors = PasswordFormValidator.validate(state.form);
    if (!errors.isEmpty) {
      emit(state.copyWith(errors: errors, hasTriedSave: true));
      return;
    }

    emit(state.copyWith(status: ChangePasswordStatus.saving));
    try {
      await _source.changePassword(
        userId: state.userId,
        current: state.form.current.trim(),
        next: state.form.next.trim(),
      );
      if (isClosed) return;
      emit(state.copyWith(status: ChangePasswordStatus.saved));
    } on Exception catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: ChangePasswordStatus.editing,
            hasSaveFailed: true,
          ),
        );
      }
    }
  }

  /// The screen has shown the failure, so the next attempt starts clean.
  void clearFailure() => emit(state.copyWith(hasSaveFailed: false));
}
