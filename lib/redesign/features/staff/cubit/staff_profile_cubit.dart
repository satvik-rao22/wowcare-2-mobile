import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/source/staff_source.dart';

part 'staff_profile_state.dart';

/// One staff record and its five tabs (6c), plus the deactivate 6f confirms.
///
/// The lens comes in with the id, so what the record shows is decided once:
/// an Admin reads it whole, a staff member reads their own whole and a
/// colleague's down to the name, the classroom and a way to call.
class StaffProfileCubit extends Cubit<StaffProfileState> {
  StaffProfileCubit({
    required StaffSource source,
    required String staffId,
    required StaffLens lens,
  }) : _source = source,
       super(StaffProfileState(staffId: staffId, lens: lens));

  final StaffSource _source;

  bool _isFetching = false;

  Future<void> load({bool isSilent = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!isSilent) emit(state.copyWith(status: StaffProfileStatus.loading));

    try {
      final profile = await _source.loadProfile(state.staffId);
      if (isClosed) return;
      emit(state.copyWith(status: StaffProfileStatus.ready, profile: profile));
    } on Exception catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: state.profile == null
              ? StaffProfileStatus.failed
              : StaffProfileStatus.ready,
        ),
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() => load(isSilent: true);

  void selectTab(StaffProfileTab tab) => emit(state.copyWith(tab: tab));

  /// 6f's key, and the reactivate that undoes it. Admin only: a staff member
  /// never reaches the sheet that calls this.
  Future<void> setActive({required bool isActive}) async {
    if (!state.lens.canWrite || state.isSaving) return;
    final profile = state.profile;
    if (profile == null) return;

    emit(state.copyWith(status: StaffProfileStatus.saving));
    try {
      final member = await _source.setActive(
        id: state.staffId,
        isActive: isActive,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: StaffProfileStatus.saved,
          profile: profile.copyWith(member: member),
        ),
      );
    } on Exception catch (_) {
      if (isClosed) return;
      emit(state.copyWith(status: StaffProfileStatus.failed));
    }
  }

  /// Put a file on the record. The frame draws the key; this is what it does.
  Future<void> addDocument({
    required String name,
    required String type,
    DateTime? expiresOn,
  }) async {
    final profile = state.profile;
    if (profile == null || state.isSaving) return;

    emit(state.copyWith(status: StaffProfileStatus.saving));
    try {
      final document = await _source.addDocument(
        staffId: state.staffId,
        name: name,
        type: type,
        expiresOn: expiresOn,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: StaffProfileStatus.saved,
          profile: profile.copyWith(
            documents: <StaffDocument>[document, ...profile.documents],
          ),
        ),
      );
    } on Exception catch (_) {
      if (isClosed) return;
      emit(state.copyWith(status: StaffProfileStatus.failed));
    }
  }

  /// Take the record back from a form that changed it, so returning to the
  /// profile does not have to refetch to look right.
  void applySaved(StaffProfile profile) =>
      emit(state.copyWith(status: StaffProfileStatus.ready, profile: profile));
}
