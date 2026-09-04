import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/features/profile/models/models.dart';
import 'package:wowcare/redesign/features/profile/source/profile_source.dart';

part 'edit_profile_state.dart';

/// 13b. The eight fields a person may change about themselves.
///
/// Email and country are shown and refused rather than hidden: the frame
/// draws both in a deeper well with a "Cannot be edited" tag, because knowing
/// what your sign-in is matters more than a tidier form.
///
/// Validation runs on the first attempt to save and stays live afterwards, so
/// a message clears the moment the field is right. Address is required for a
/// staff member and optional for a guardian, which is the rule the shipped
/// screen applies.
class EditProfileCubit extends Cubit<EditProfileState> {
  EditProfileCubit({required ProfileSource source, required String userId})
    : _source = source,
      super(EditProfileState(userId: userId));

  final ProfileSource _source;

  bool _isFetching = false;

  Future<void> load({bool isSilent = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!isSilent) emit(state.copyWith(status: EditProfileStatus.loading));

    try {
      final snapshot = await _source.fetchProfile(state.userId);
      final states = await _source.stateNames();
      if (isClosed) return;

      emit(
        state.copyWith(
          status: EditProfileStatus.ready,
          record: snapshot.record,
          form: ProfileFormData.fromRecord(snapshot.record),
          stateNames: states,
        ),
      );
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(status: EditProfileStatus.failed));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() => load(isSilent: true);

  /// Writes [form] and, once Save has been tried, re-checks it.
  void edit(ProfileFormData form) {
    final errors = state.hasTriedSave ? state.checked(form) : state.errors;
    emit(state.copyWith(form: form, errors: errors));
  }

  Future<void> save() async {
    if (state.isSaving) return;

    final errors = state.checked(state.form);
    if (!errors.isEmpty) {
      emit(state.copyWith(errors: errors, hasTriedSave: true));
      return;
    }

    emit(state.copyWith(status: EditProfileStatus.saving));
    try {
      final saved = await _source.saveProfile(state.userId, state.form);
      if (isClosed) return;
      emit(state.copyWith(status: EditProfileStatus.saved, record: saved));
    } on Exception catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(status: EditProfileStatus.ready, hasSaveFailed: true),
        );
      }
    }
  }

  /// The screen has shown the failure, so the next attempt starts clean.
  void clearFailure() => emit(state.copyWith(hasSaveFailed: false));
}
