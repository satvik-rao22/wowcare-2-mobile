import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/source/staff_source.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';

part 'edit_staff_state.dart';

/// Added. 6c's fields card carries an Edit key and the frames stop there, so
/// this is the smallest screen it can lead to: the name, the contact and the
/// address, validated, then back to the record.
///
/// Deliberately narrow. Designation, role, classrooms and status decide what
/// a person can do, so they are set by an Admin elsewhere and are not on this
/// form at all — which is what lets a staff member keep their own details up
/// to date without being able to widen their own access.
class EditStaffCubit extends Cubit<EditStaffState> {
  EditStaffCubit({
    required StaffSource source,
    required String staffId,
    required StaffLens lens,
  }) : _source = source,
       super(EditStaffState(staffId: staffId, lens: lens));

  final StaffSource _source;

  bool _isFetching = false;

  Future<void> load() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final profile = await _source.loadProfile(state.staffId);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: EditStaffStatus.editing,
          profile: profile,
          draft: _draftOf(profile),
        ),
      );
    } on Exception catch (_) {
      if (isClosed) return;
      emit(state.copyWith(status: EditStaffStatus.failed));
    } finally {
      _isFetching = false;
    }
  }

  void setFirstName(String value) =>
      _edit(state.draft.copyWith(firstName: value));

  void setLastName(String value) =>
      _edit(state.draft.copyWith(lastName: value));

  void setEmail(String value) => _edit(state.draft.copyWith(email: value));

  void setPhone(String value) => _edit(state.draft.copyWith(phone: value));

  void setStreet(String value) => _edit(state.draft.copyWith(street: value));

  void setLine2(String value) => _edit(state.draft.copyWith(line2: value));

  void setCity(String value) => _edit(state.draft.copyWith(city: value));

  void setState(String value) => _edit(state.draft.copyWith(state: value));

  void setZipCode(String value) => _edit(state.draft.copyWith(zipCode: value));

  Future<void> submit() async {
    if (state.isSaving) return;

    final errors = _validate(state.draft);
    if (errors.isNotEmpty) {
      emit(state.copyWith(errors: errors));
      return;
    }

    emit(
      state.copyWith(
        status: EditStaffStatus.saving,
        errors: const <StaffField, String>{},
      ),
    );
    try {
      final saved = await _source.updateDetails(
        id: state.staffId,
        draft: state.draft,
      );
      if (isClosed) return;
      emit(state.copyWith(status: EditStaffStatus.saved, profile: saved));
    } on Exception catch (_) {
      if (isClosed) return;
      emit(state.copyWith(status: EditStaffStatus.failed));
    }
  }

  void _edit(StaffDetailsDraft draft) =>
      emit(state.copyWith(draft: draft).cleared());

  static StaffDetailsDraft _draftOf(StaffProfile profile) {
    final parts = profile.name.split(' ');
    return StaffDetailsDraft(
      firstName: parts.isEmpty ? '' : parts.first,
      lastName: parts.length < 2 ? '' : parts.sublist(1).join(' '),
      email: profile.member.email,
      phone: profile.member.phone,
      street: profile.address.street,
      line2: profile.address.line2,
      city: profile.address.city,
      state: profile.address.state,
      zipCode: profile.address.zipCode,
    );
  }

  static Map<StaffField, String> _validate(StaffDetailsDraft draft) {
    final errors = <StaffField, String>{};
    if (draft.firstName.trim().isEmpty) {
      errors[StaffField.firstName] = StaffStrings.nameRequired;
    }
    if (draft.lastName.trim().isEmpty) {
      errors[StaffField.lastName] = StaffStrings.nameRequired;
    }
    if (!draft.email.contains('@') || draft.email.trim().isEmpty) {
      errors[StaffField.email] = StaffStrings.invalidEmail;
    }
    if (draft.phone.replaceAll(RegExp(r'\D'), '').length != 10) {
      errors[StaffField.phone] = StaffStrings.invalidPhone;
    }
    return errors;
  }
}
