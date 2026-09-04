import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/source/students_source.dart';

part 'student_profile_state.dart';

/// 5c. One student's record and its five tabs.
///
/// The whole record arrives in one fetch and the tabs switch locally, which
/// is how the existing profile screen behaves: its tab cards read a record
/// the cubit already holds rather than each fetching again.
///
/// Deactivating is deliberately not here. 5h opens over the roster, because
/// taking a student off the list is a thing you do to the list.
class StudentProfileCubit extends Cubit<StudentProfileState> {
  StudentProfileCubit({
    required StudentsSource source,
    required String studentId,
    required Persona persona,
  }) : _source = source,
       super(StudentProfileState(studentId: studentId, persona: persona));

  final StudentsSource _source;

  bool _isFetching = false;

  Future<void> load({bool isSilent = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!isSilent) emit(state.copyWith(status: ProfileStatus.loading));

    try {
      final record = await _source.loadProfile(state.studentId);
      if (isClosed) return;
      emit(state.copyWith(status: ProfileStatus.ready, record: record));
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(status: ProfileStatus.failed));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() => load(isSilent: true);

  void selectTab(ProfileTab tab) => emit(state.copyWith(tab: tab));

  void selectProfileSection(ProfileSection section) =>
      emit(state.copyWith(profileSection: section));

  void selectHealthSection(HealthSection section) =>
      emit(state.copyWith(healthSection: section));
}
