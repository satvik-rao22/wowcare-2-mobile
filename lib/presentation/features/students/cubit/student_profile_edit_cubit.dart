import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../domain/features/student/entities/student.dart';
import '../../../../domain/features/student/entities/student_guardian.dart';
import '../../../../domain/features/student/entities/update_student_address_request.dart';
import '../../../../domain/features/student/usecases/get_student_guardians_usecase.dart';
import '../../../../domain/features/student/usecases/get_student_page_usecase.dart';
import '../../../../domain/features/student/usecases/update_guardian_usecase.dart';
import '../../../../domain/features/student/usecases/update_student_address_usecase.dart';
import '../../../../domain/features/student/usecases/update_student_profile_usecase.dart';
import '../../../../domain/features/student/usecases/update_student_siblings_usecase.dart';
import '../../../../domain/features/student/usecases/update_student_tags_usecase.dart';

part 'student_profile_edit_state.dart';

/// Reads + mutations backing the Edit Student Profile screen.
///
/// The screen routes every read/write for the multi-step save through this
/// cubit → use case → repository so no view depends on [StudentRepository] or
/// [StudentRemoteDataSource] directly. The save ORCHESTRATION (sequence,
/// conditionals, per-guardian custody loop) stays in the view; this cubit only
/// owns the individual call targets.
class StudentProfileEditCubit extends Cubit<StudentProfileEditState> {
  StudentProfileEditCubit({
    required GetStudentPageUseCase getStudentPageUseCase,
    required GetStudentGuardiansUseCase getStudentGuardiansUseCase,
    required UpdateStudentProfileUseCase updateStudentProfileUseCase,
    required UpdateStudentAddressUseCase updateStudentAddressUseCase,
    required UpdateStudentTagsUseCase updateStudentTagsUseCase,
    required UpdateStudentSiblingsUseCase updateStudentSiblingsUseCase,
    required UpdateGuardianUseCase updateGuardianUseCase,
  })  : _getStudentPageUseCase = getStudentPageUseCase,
        _getStudentGuardiansUseCase = getStudentGuardiansUseCase,
        _updateStudentProfileUseCase = updateStudentProfileUseCase,
        _updateStudentAddressUseCase = updateStudentAddressUseCase,
        _updateStudentTagsUseCase = updateStudentTagsUseCase,
        _updateStudentSiblingsUseCase = updateStudentSiblingsUseCase,
        _updateGuardianUseCase = updateGuardianUseCase,
        super(const StudentProfileEditState.initial());

  final GetStudentPageUseCase _getStudentPageUseCase;
  final GetStudentGuardiansUseCase _getStudentGuardiansUseCase;
  final UpdateStudentProfileUseCase _updateStudentProfileUseCase;
  final UpdateStudentAddressUseCase _updateStudentAddressUseCase;
  final UpdateStudentTagsUseCase _updateStudentTagsUseCase;
  final UpdateStudentSiblingsUseCase _updateStudentSiblingsUseCase;
  final UpdateGuardianUseCase _updateGuardianUseCase;

  // --- Form model (owned here; the view fetches + maps, then applies via these) ---

  /// Seed the simple form fields from the caller's initial values.
  void initialize({
    String? status,
    String? stateSubsidyOption,
    String? classroom,
    DateTime? birthDate,
    String? stateName,
    String? country,
    String? gender,
    List<String>? selectedTags,
    List<String>? selectedSiblings,
    List<String>? selectedChildCustody,
  }) {
    emit(state.copyWith(
      status: status,
      stateSubsidyOption: stateSubsidyOption,
      classroom: classroom,
      birthDate: birthDate,
      stateName: stateName,
      country: country,
      gender: gender,
      selectedTags: selectedTags,
      selectedSiblings: selectedSiblings,
      selectedChildCustody: selectedChildCustody,
    ));
  }

  void setStatus(String? value) => emit(state.copyWith(status: value));
  void setStateSubsidyOption(String? value) =>
      emit(state.copyWith(stateSubsidyOption: value));
  void setBirthDate(DateTime? value) => emit(state.copyWith(birthDate: value));
  void setStateName(String? value) => emit(state.copyWith(stateName: value));
  void setCountry(String? value) => emit(state.copyWith(country: value));
  void setGender(String? value) => emit(state.copyWith(gender: value));
  void setSelectedTags(List<String> value) =>
      emit(state.copyWith(selectedTags: value));
  void setSelectedSiblings(List<String> value) =>
      emit(state.copyWith(selectedSiblings: value));
  void setSelectedChildCustody(List<String> value) =>
      emit(state.copyWith(selectedChildCustody: value));
  void setSubmitting(bool value) => emit(state.copyWith(submitting: value));

  /// A user-driven classroom change (records the "changed by user" flag).
  void setClassroom(String? value) => emit(state.copyWith(
        classroom: value,
        classroomChangedByUser: true,
      ));

  /// Result of the today's-sign-in lookup (loading flips to false).
  void setTodayStatus({required bool isSignedInToday}) => emit(state.copyWith(
        isSignedInToday: isSignedInToday,
        isTodayStatusLoading: false,
      ));

  /// Apply the loaded tag options + name→code map (+ pruned selection).
  void applyTagsLoaded({
    required List<String> names,
    required Map<String, String> nameToCode,
    required List<String> selectedTags,
  }) {
    emit(state.copyWith(
      availableTagNames: names,
      tagNameToCode: nameToCode,
      selectedTags: selectedTags,
    ));
  }

  /// Apply the loaded sibling options + name→code map (+ mapped/pruned selection).
  void applyStudentsLoaded({
    required List<String> names,
    required Map<String, String> nameToCode,
    required List<String> selectedSiblings,
  }) {
    emit(state.copyWith(
      availableStudentNames: names,
      studentNameToCode: nameToCode,
      selectedSiblings: selectedSiblings,
    ));
  }

  /// Apply the loaded guardian options + custody lookups (+ pruned selection).
  void applyGuardiansLoaded({
    required List<String> names,
    required Map<String, String> nameToCode,
    required Map<String, bool> initialCustody,
    required Map<String, StudentGuardian> rawByCode,
    required List<String> selectedChildCustody,
  }) {
    emit(state.copyWith(
      availableGuardianNames: names,
      guardianNameToCode: nameToCode,
      guardianInitialCustody: initialCustody,
      guardianRawByCode: rawByCode,
      selectedChildCustody: selectedChildCustody,
    ));
  }

  // --- Reads (thin; return the future so the view keeps its control flow) ---

  /// Fetches a page of students, mirroring the params the view currently passes
  /// to [GetStudentPageUseCase] (used to populate the Siblings dropdown).
  Future<StudentPage> fetchStudentPage({
    required String schoolCode,
    String? code,
    String? firstName,
    String? lastName,
    String? status,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    List<String>? attendanceStatuses,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? allowedClassroomCodes,
  }) {
    return _getStudentPageUseCase(
      schoolCode: schoolCode,
      code: code,
      firstName: firstName,
      lastName: lastName,
      status: status,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      guardianCodes: guardianCodes,
      attendanceStatuses: attendanceStatuses,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: allowedClassroomCodes,
    );
  }

  /// Fetches a student's guardians (used to seed the Child Custody dropdown).
  Future<List<StudentGuardian>> fetchGuardians(String studentCode) {
    return _getStudentGuardiansUseCase(studentCode: studentCode);
  }

  // --- Mutations (each keyed single-flight; rethrow) ---

  /// In-flight mutations keyed by `action:code`. A second identical call while
  /// the first is still running returns the SAME future instead of issuing a
  /// duplicate request — single-flight independent of any UI button-disabling.
  final Map<String, Future<Object?>> _inFlightMutations = {};

  Future<T> _singleFlight<T>(
    String key,
    Future<T> Function() operation,
  ) {
    final existing = _inFlightMutations[key];
    if (existing != null) return existing as Future<T>;
    final future = operation();
    _inFlightMutations[key] = future;
    // Clear the in-flight entry on completion. `whenComplete` returns a new
    // future that mirrors any error; ignore it so a rethrown mutation error
    // surfaces only through the caller's `future` and isn't double-reported as
    // an unhandled async error.
    future.whenComplete(() => _inFlightMutations.remove(key)).ignore();
    return future;
  }

  Future<String> updateProfile({
    required String code,
    required Map<String, dynamic> fields,
  }) {
    return _singleFlight<String>('updateProfile:$code', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _updateStudentProfileUseCase(code: code, fields: fields);
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }

  Future<String> updateAddress({
    required String studentCode,
    required UpdateStudentAddressRequest request,
  }) {
    return _singleFlight<String>('updateAddress:$studentCode', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _updateStudentAddressUseCase(
          studentCode: studentCode,
          request: request,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }

  Future<String> updateTags({
    required String studentCode,
    required String schoolCode,
    required List<String> tagCodes,
  }) {
    return _singleFlight<String>('updateTags:$studentCode', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _updateStudentTagsUseCase(
          studentCode: studentCode,
          schoolCode: schoolCode,
          tagCodes: tagCodes,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }

  Future<String> updateSiblings({
    required String studentCode,
    required List<String> siblingCodes,
  }) {
    return _singleFlight<String>('updateSiblings:$studentCode', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _updateStudentSiblingsUseCase(
          studentCode: studentCode,
          siblingCodes: siblingCodes,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }

  Future<String> updateGuardian({
    required String code,
    required String studentCode,
    required Map<String, dynamic> fields,
  }) {
    return _singleFlight<String>('updateGuardian:$code', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _updateGuardianUseCase(
          code: code,
          studentCode: studentCode,
          fields: fields,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }
}
