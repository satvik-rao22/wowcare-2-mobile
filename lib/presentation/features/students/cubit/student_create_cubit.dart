import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/util/app_time.dart';
import '../../../../domain/features/student/entities/student.dart';
import '../../../../domain/features/student/entities/student_regular_schedule_input.dart';
import '../../../../domain/features/student/entities/update_guardian_request.dart';
import '../../../../domain/features/student/entities/student_profile.dart';
import '../../../../domain/features/student/usecases/add_student_sibling_usecase.dart';
import '../../../../domain/features/student/usecases/create_guardian_user_usecase.dart';
import '../../../../domain/features/student/usecases/create_student_usecase.dart';
import '../../../../domain/features/student/usecases/get_guardian_name_code_map_for_school_usecase.dart';
import '../../../../domain/features/student/usecases/get_student_page_usecase.dart';
import '../../../../domain/features/student/usecases/get_student_profile_usecase.dart';
import '../../../../domain/features/student/usecases/link_existing_guardian_usecase.dart';
import '../../../../domain/features/student/usecases/update_guardian_usecase.dart';
import '../../../../domain/features/student/usecases/update_student_regular_schedules_usecase.dart';

part 'student_create_state.dart';

/// Reads + mutations backing the Add Student wizard (Step 1 + Step 2).
///
/// The wizard routes every read/write through this cubit → use case →
/// repository so no view depends on [StudentRepository] or
/// [StudentRemoteDataSource] directly. The create ORCHESTRATION (the
/// createStudent call, the background photo uploads, the per-parent guardian
/// loop with its selectFromExisting/create branches, the sibling loop, the
/// schedule save) stays in the views; this cubit only owns the individual call
/// targets.
class StudentCreateCubit extends Cubit<StudentCreateState> {
  StudentCreateCubit({
    required GetStudentPageUseCase getStudentPageUseCase,
    required GetStudentProfileUseCase getStudentProfileUseCase,
    required GetGuardianNameCodeMapForSchoolUseCase
        getGuardianNameCodeMapForSchoolUseCase,
    required CreateStudentUseCase createStudentUseCase,
    required CreateGuardianUserUseCase createGuardianUserUseCase,
    required LinkExistingGuardianUseCase linkExistingGuardianUseCase,
    required AddStudentSiblingUseCase addStudentSiblingUseCase,
    required UpdateGuardianUseCase updateGuardianUseCase,
    required UpdateStudentRegularSchedulesUseCase
        updateStudentRegularSchedulesUseCase,
  })  : _getStudentPageUseCase = getStudentPageUseCase,
        _getStudentProfileUseCase = getStudentProfileUseCase,
        _getGuardianNameCodeMapForSchoolUseCase =
            getGuardianNameCodeMapForSchoolUseCase,
        _createStudentUseCase = createStudentUseCase,
        _createGuardianUserUseCase = createGuardianUserUseCase,
        _linkExistingGuardianUseCase = linkExistingGuardianUseCase,
        _addStudentSiblingUseCase = addStudentSiblingUseCase,
        _updateGuardianUseCase = updateGuardianUseCase,
        _updateStudentRegularSchedulesUseCase =
            updateStudentRegularSchedulesUseCase,
        super(const StudentCreateState.initial());

  final GetStudentPageUseCase _getStudentPageUseCase;
  final GetStudentProfileUseCase _getStudentProfileUseCase;
  final GetGuardianNameCodeMapForSchoolUseCase
      _getGuardianNameCodeMapForSchoolUseCase;
  final CreateStudentUseCase _createStudentUseCase;
  final CreateGuardianUserUseCase _createGuardianUserUseCase;
  final LinkExistingGuardianUseCase _linkExistingGuardianUseCase;
  final AddStudentSiblingUseCase _addStudentSiblingUseCase;
  final UpdateGuardianUseCase _updateGuardianUseCase;
  final UpdateStudentRegularSchedulesUseCase
      _updateStudentRegularSchedulesUseCase;

  // --- Reads (thin; return the future so the views keep their control flow) ---

  /// Fetches a page of students, mirroring the params the views currently pass
  /// (used for the duplicate-name check and the same-last-name sibling lookup).
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

  /// Fetches a single student profile by code.
  Future<StudentProfile> fetchStudentProfile(String code) {
    return _getStudentProfileUseCase(code: code);
  }

  /// Loads the guardian display-name → guardian-code map for a school (used to
  /// resolve selected existing-parent names back to guardian codes).
  Future<Map<String, String>> fetchGuardianNameCodeMapForSchool({
    required String schoolCode,
  }) {
    return _getGuardianNameCodeMapForSchoolUseCase(schoolCode: schoolCode);
  }

  // --- Step 1 form model ---

  /// Seed step 1 from the caller's initial values (status defaults to 'Active').
  void initializeStep1({
    String? status,
    String? classroom,
    DateTime? birthdate,
    DateTime? schoolStartDate,
    File? profilePhoto,
  }) {
    emit(state.copyWith(
      step1Status: status ?? 'Active',
      step1Classroom: classroom,
      step1Birthdate: birthdate,
      step1SchoolStartDate: schoolStartDate,
      step1ProfilePhoto: profilePhoto,
      step1AgeLabel: birthdate != null ? ageLabelFor(birthdate) : null,
    ));
  }

  void setStep1Status(String? status) {
    emit(state.copyWith(step1Status: status));
  }

  void setStep1Classroom(String? classroom) {
    emit(state.copyWith(step1Classroom: classroom));
  }

  /// Sets the birthdate AND its derived age label together.
  void setStep1Birthdate(DateTime? birthdate) {
    emit(state.copyWith(
      step1Birthdate: birthdate,
      step1AgeLabel: birthdate != null ? ageLabelFor(birthdate) : null,
    ));
  }

  void setStep1SchoolStartDate(DateTime? date) {
    emit(state.copyWith(step1SchoolStartDate: date));
  }

  void setStep1ProfilePhoto(File? photo) {
    emit(state.copyWith(step1ProfilePhoto: photo));
  }

  /// Flow-level submit flag spanning create → sibling-link → hand-off.
  void setStep1Submitting(bool value) {
    emit(state.copyWith(step1Submitting: value));
  }

  /// "Xy Zm" age label from a birthdate, relative to the school clock (AppTime).
  static String ageLabelFor(DateTime birthdate) {
    final now = AppTime.now();
    var years = now.year - birthdate.year;
    var months = now.month - birthdate.month;
    if (now.day < birthdate.day) months--;
    if (months < 0) {
      years--;
      months += 12;
    }
    final yearPart = '$years ${years == 1 ? 'year' : 'years'}';
    final monthPart = '$months ${months == 1 ? 'month' : 'months'}';
    return years <= 0 ? monthPart : '$yearPart $monthPart';
  }

  // --- Step 2 (add-parent) form model ---

  void initializeStep2({
    bool? selectFromExisting,
    List<String>? selectedExistingParents,
    String? relation,
    bool? isEmergencyContact,
    bool? isChildCustody,
    File? profilePhoto,
  }) {
    emit(state.copyWith(
      step2SelectFromExisting: selectFromExisting,
      step2SelectedExistingParents: selectedExistingParents,
      step2Relation: relation,
      step2IsEmergencyContact: isEmergencyContact,
      step2IsChildCustody: isChildCustody,
      step2ProfilePhoto: profilePhoto,
    ));
  }

  void setStep2SelectFromExisting(bool value) {
    emit(state.copyWith(step2SelectFromExisting: value));
  }

  void setStep2SelectedExistingParents(List<String> parents) {
    emit(state.copyWith(step2SelectedExistingParents: parents));
  }

  void setStep2Relation(String? relation) {
    emit(state.copyWith(step2Relation: relation));
  }

  void setStep2IsEmergencyContact(bool value) {
    emit(state.copyWith(step2IsEmergencyContact: value));
  }

  void setStep2IsChildCustody(bool value) {
    emit(state.copyWith(step2IsChildCustody: value));
  }

  void setStep2ProfilePhoto(File? photo) {
    emit(state.copyWith(step2ProfilePhoto: photo));
  }

  void setStep2Submitting(bool value) {
    emit(state.copyWith(step2Submitting: value));
  }

  /// Store the fetched existing-parent [names] and prune any selected parents
  /// that no longer exist in the latest list.
  void setStep2ExistingParents(List<String> names) {
    final pruned = state.step2SelectedExistingParents
        .where(names.contains)
        .toList();
    emit(state.copyWith(
      step2ExistingParents: names,
      step2SelectedExistingParents: pruned,
    ));
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

  Future<Student> createStudent({
    required String schoolCode,
    required String firstName,
    required String lastName,
    required String status,
    required String classroom,
    String? profilePhotoUrl,
    DateTime? dob,
    DateTime? schoolStartDate,
  }) {
    return _singleFlight<Student>(
      'createStudent:$schoolCode:$firstName:$lastName',
      () async {
        if (!isClosed) emit(state.copyWith(mutationInProgress: true));
        try {
          return await _createStudentUseCase(
            schoolCode: schoolCode,
            firstName: firstName,
            lastName: lastName,
            status: status,
            classroom: classroom,
            profilePhotoUrl: profilePhotoUrl,
            dob: dob,
            schoolStartDate: schoolStartDate,
          );
        } finally {
          if (!isClosed) emit(state.copyWith(mutationInProgress: false));
        }
      },
    );
  }

  Future<({String message, String? guardianCode})> createGuardianUser({
    required String schoolCode,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String relationToStudent,
    required bool primaryContact,
    required bool legalCustody,
    String? profilePhotoUrl,
    String? userCode,
    String? organizationCode,
  }) {
    return _singleFlight<({String message, String? guardianCode})>(
      'createGuardian:$studentCode:$email',
      () async {
        if (!isClosed) emit(state.copyWith(mutationInProgress: true));
        try {
          return await _createGuardianUserUseCase(
            schoolCode: schoolCode,
            studentCode: studentCode,
            firstName: firstName,
            lastName: lastName,
            email: email,
            mobile: mobile,
            relationToStudent: relationToStudent,
            primaryContact: primaryContact,
            legalCustody: legalCustody,
            profilePhotoUrl: profilePhotoUrl,
            userCode: userCode,
            organizationCode: organizationCode,
          );
        } finally {
          if (!isClosed) emit(state.copyWith(mutationInProgress: false));
        }
      },
    );
  }

  Future<String> linkExistingGuardian({
    required String guardianCode,
    required String studentCode,
    String? relation,
    String? relationDescription,
  }) {
    return _singleFlight<String>(
      'linkGuardian:$guardianCode:$studentCode',
      () async {
        if (!isClosed) emit(state.copyWith(mutationInProgress: true));
        try {
          return await _linkExistingGuardianUseCase(
            guardianCode: guardianCode,
            studentCode: studentCode,
            relation: relation,
            relationDescription: relationDescription,
          );
        } finally {
          if (!isClosed) emit(state.copyWith(mutationInProgress: false));
        }
      },
    );
  }

  Future<String> addStudentSibling({
    required String studentCode,
    required List<String> siblingCodes,
  }) {
    return _singleFlight<String>('addSibling:$studentCode', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _addStudentSiblingUseCase(
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
    required UpdateGuardianRequest request,
  }) {
    return _singleFlight<String>('updateGuardian:$code', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _updateGuardianUseCase(
          code: code,
          studentCode: studentCode,
          request: request,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }

  Future<String> updateStudentRegularSchedules({
    required String schoolCode,
    required String studentCode,
    required List<StudentRegularScheduleInput> schedule,
  }) {
    return _singleFlight<String>('updateSchedule:$studentCode', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _updateStudentRegularSchedulesUseCase(
          schoolCode: schoolCode,
          studentCode: studentCode,
          schedule: schedule,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }
}
