import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/attendance_classroom_scope.dart';
import 'package:wowcare/core/util/idempotency_key.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/entities/student_transfer_request.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_student_transfer_usecase.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';

import 'student_transfer_submit_state.dart';

/// Owns the student transfer submit call and its in-progress/success/failure
/// state, routing the mutation through [SubmitStudentTransferUseCase] instead of
/// the View touching [AttendanceRepository] directly.
///
/// [submit] intentionally RETURNS the [AttendanceActionResult] and RETHROWS on
/// error: this refactor moves the repository call behind the UseCase and
/// centralises submit state, but the form keeps its exact success/navigation
/// and catch behaviour, so nothing the user sees changes.
class StudentTransferSubmitCubit extends Cubit<StudentTransferSubmitState> {
  StudentTransferSubmitCubit(
    this._submitStudentTransfer, {
    required GetActiveClassroomsUseCase getActiveClassroomsUseCase,
    required StorageService storageService,
    required ApiClient apiClient,
  }) : _getActiveClassroomsUseCase = getActiveClassroomsUseCase,
       _storage = storageService,
       _apiClient = apiClient,
       super(const StudentTransferSubmitInitial());

  final SubmitStudentTransferUseCase _submitStudentTransfer;
  final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  final StorageService _storage;
  final ApiClient _apiClient;

  String? _idempotencyKey;

  // The request the current _idempotencyKey was minted for. A resubmit
  // with an UNCHANGED request reuses the key (protects a genuine retry,
  // e.g. after a timeout, from double-submitting); a DIFFERENT request
  // (corrected payload) gets a fresh key instead of silently replaying
  // whatever the backend's idempotency layer cached for the first one.
  Object? _idempotencyKeyRequest;

  /// Fresh school-timezone resolution — re-syncs the server clock at the
  /// moment it's called, per [SchoolTimezoneResolver]'s own "fetch fresh"
  /// contract.
  Future<String> resolveFreshSchoolTimeZone() {
    return SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: _storage,
      apiClient: _apiClient,
    );
  }

  /// Delegates to [GetActiveClassroomsUseCase] — used by the View to populate
  /// the transfer-target classroom dropdown.
  Future<List<Classroom>> fetchActiveClassrooms({
    required String schoolCode,
    bool onlyTypeClassroom = true,
  }) {
    return _getActiveClassroomsUseCase(
      schoolCode: schoolCode,
      onlyTypeClassroom: onlyTypeClassroom,
    );
  }

  /// True for any staff-side login (school/org admin or regular staff);
  /// false for guardian/parent and kiosk-PIN access. Gates date/time editing.
  Future<bool> resolveIsStaffPersona() =>
      resolveIsStaffPersonaFromStorage(_storage);

  /// Resolves the transfer-target classroom options for the current school,
  /// scoped by the caller's staff-persona classroom allowlist when
  /// applicable. Mirrors the View's previous inline storage reads.
  Future<
    ({
      String schoolCode,
      bool isScopedStaff,
      Set<String> allowedClassroomCodes,
      List<Classroom> classrooms,
    })
  >
  resolveTransferClassroomOptions() async {
    final schoolCode = (await _storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    if (schoolCode.isEmpty) {
      return (
        schoolCode: '',
        isScopedStaff: false,
        allowedClassroomCodes: const <String>{},
        classrooms: const <Classroom>[],
      );
    }
    final isScopedStaff = await isStudentAttendanceScopedStaffPersona(
      storage: _storage,
    );
    final allowedClassroomCodes = isScopedStaff
        ? (await resolveStudentAttendanceAllowedClassroomCodes(
            storage: _storage,
          )).map((e) => e.trim()).where((e) => e.isNotEmpty).toSet()
        : const <String>{};
    final classrooms = await fetchActiveClassrooms(
      schoolCode: schoolCode,
      onlyTypeClassroom: true,
    );
    return (
      schoolCode: schoolCode,
      isScopedStaff: isScopedStaff,
      allowedClassroomCodes: allowedClassroomCodes,
      classrooms: classrooms,
    );
  }

  /// True while a submit is in flight.
  bool get isSubmitting => state is StudentTransferSubmitInProgress;

  Future<AttendanceActionResult> submit({
    required StudentTransferRequest request,
  }) async {
    emit(const StudentTransferSubmitInProgress());
    try {
      if (_idempotencyKey == null || _idempotencyKeyRequest != request) {
        _idempotencyKey = IdempotencyKey.generate();
        _idempotencyKeyRequest = request;
      }
      final result = await _submitStudentTransfer(
        request: request,
        idempotencyKey: _idempotencyKey,
      );
      if (!isClosed) emit(StudentTransferSubmitSuccess(result));
      _idempotencyKey = null;
      _idempotencyKeyRequest = null;
      return result;
    } catch (e) {
      if (!isClosed) {
        emit(
          StudentTransferSubmitFailure(ApiErrorHandler.extractErrorMessage(e)),
        );
      }
      rethrow;
    }
  }
}
