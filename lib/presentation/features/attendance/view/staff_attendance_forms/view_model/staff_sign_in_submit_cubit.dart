import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/idempotency_key.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_attendance_absent.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_sign_in_request.dart';
import 'package:wowcare/domain/features/attendance/usecases/delete_staff_absence_record_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_absent_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_staff_sign_in_usecase.dart';

import 'staff_sign_in_submit_state.dart';

/// Owns the staff sign-in submit call and its in-progress/success/failure
/// state, routing the mutation through [SubmitStaffSignInUseCase] instead of
/// the View touching [AttendanceRepository] directly.
///
/// [submit] intentionally RETURNS the [AttendanceActionResult] and RETHROWS on
/// error: this refactor moves the repository call behind the UseCase and
/// centralises submit state, but the form keeps its exact success/navigation
/// and catch behaviour, so nothing the user sees changes.
class StaffSignInSubmitCubit extends Cubit<StaffSignInSubmitState> {
  StaffSignInSubmitCubit(
    this._submitStaffSignIn, {
    required GetStaffAbsentFormListUseCase getStaffAbsentFormListUseCase,
    required DeleteStaffAbsenceRecordUseCase deleteStaffAbsenceRecordUseCase,
  }) : _getStaffAbsentFormListUseCase = getStaffAbsentFormListUseCase,
       _deleteStaffAbsenceRecordUseCase = deleteStaffAbsenceRecordUseCase,
       super(const StaffSignInSubmitInitial());

  final SubmitStaffSignInUseCase _submitStaffSignIn;
  final GetStaffAbsentFormListUseCase _getStaffAbsentFormListUseCase;
  final DeleteStaffAbsenceRecordUseCase _deleteStaffAbsenceRecordUseCase;

  String? _idempotencyKey;

  // The request the current _idempotencyKey was minted for. A resubmit
  // with an UNCHANGED request reuses the key (protects a genuine retry,
  // e.g. after a timeout, from double-submitting); a DIFFERENT request
  // (corrected payload) gets a fresh key instead of silently replaying
  // whatever the backend's idempotency layer cached for the first one.
  Object? _idempotencyKeyRequest;

  /// True once [clearTodaysAbsenceRecordsBeforeSignIn] has actually deleted
  /// at least one absence record for the staff about to be signed in. See
  /// the student cubit's identical field for the full rationale.
  bool _absenceJustCleared = false;

  /// True while a submit is in flight.
  bool get isSubmitting => state is StaffSignInSubmitInProgress;

  bool _absenceDateMatchesCalendarDay(
    String absenceDateRaw,
    String targetYyyyMmDd,
  ) {
    final trimmed = absenceDateRaw.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length >= 10 && trimmed.substring(0, 10) == targetYyyyMmDd) {
      return true;
    }
    try {
      final dt = DateTime.parse(trimmed).toLocal();
      final norm =
          '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      return norm == targetYyyyMmDd;
    } catch (_) {
      return false;
    }
  }

  /// Admin override sign-in: for staff marked absent on
  /// [attendanceDateYyyyMmDd], delete their absence record first so the day
  /// isn't left with both an ABSENT record and a sign-in. Only ever called
  /// for the admin persona — self-service staff sign-in never reaches this,
  /// matching StaffAttendanceGate's rule that an absent staff member cannot
  /// recover their own day. Best-effort — if the absent-form-list lookup
  /// fails, skips deletion and lets the sign-in POST run.
  Future<void> clearTodaysAbsenceRecordsBeforeSignIn({
    required String attendanceDateYyyyMmDd,
    required String actingStaffCode,
    required List<({String staffCode, String classroomCode, String name})>
    targets,
  }) async {
    final allItems = <StaffAttendanceAbsentItem>[];

    try {
      var page = 0;
      const pageSize = 200;
      while (true) {
        final absentPage = await _getStaffAbsentFormListUseCase(
          fromAbsenceDate: attendanceDateYyyyMmDd,
          toAbsenceDate: attendanceDateYyyyMmDd,
          page: page,
          size: pageSize,
        );
        allItems.addAll(absentPage.items);
        if (!absentPage.hasMore) break;
        page++;
        if (page > 100) break;
      }
    } catch (e) {
      AppLogger.d(
        '[StaffSignIn] absent-form-list lookup failed ($e); '
        'proceeding to sign-in without clearing absence records',
      );
      return;
    }

    final processedStaffCodes = <String>{};
    for (final s in targets) {
      final sc = s.staffCode.trim();
      if (sc.isEmpty || processedStaffCodes.contains(sc)) continue;

      final matches = allItems.where((it) {
        if (it.staffCode.trim() != sc) return false;
        return _absenceDateMatchesCalendarDay(
          it.absenceDate,
          attendanceDateYyyyMmDd,
        );
      }).toList();

      if (matches.isEmpty) continue;

      final withCode = matches
          .where((it) => (it.absenceRecordCode ?? '').trim().isNotEmpty)
          .toList();
      if (withCode.isEmpty) {
        throw Exception(
          'Cannot sign in ${s.name}: marked absent for this day but the '
          'absence record could not be resolved. Refresh and try again.',
        );
      }

      final room = s.classroomCode.trim();
      var chosen = withCode.first;
      if (room.isNotEmpty) {
        final byRoom = withCode
            .where((it) => it.classroomCode.trim() == room)
            .toList();
        if (byRoom.isNotEmpty) {
          chosen = byRoom.first;
        }
      }

      await _deleteStaffAbsenceRecordUseCase(
        absenceRecordCode: chosen.absenceRecordCode!.trim(),
        staffCode: actingStaffCode,
      );
      _absenceJustCleared = true;
      processedStaffCodes.add(sc);
    }
  }

  Future<AttendanceActionResult> submit({
    required StaffSignInRequest request,
    required bool isSelf,
  }) async {
    emit(const StaffSignInSubmitInProgress());
    if (_idempotencyKey == null || _idempotencyKeyRequest != request) {
      _idempotencyKey = IdempotencyKey.generate();
      _idempotencyKeyRequest = request;
    }

    // See the student sign-in cubit's identical block for the full
    // rationale: retry (safely, via the stable key above) when the sign-in
    // POST fails right after an absence delete succeeded, since the two
    // calls have no shared backend transaction.
    final hadClearedAbsence = _absenceJustCleared;
    final maxAttempts = hadClearedAbsence ? 3 : 1;
    late Object lastError;
    late StackTrace lastStackTrace;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final result = await _submitStaffSignIn(
          request: request,
          isSelf: isSelf,
          idempotencyKey: _idempotencyKey,
        );
        if (!isClosed) emit(StaffSignInSubmitSuccess(result));
        _idempotencyKey = null;
        _idempotencyKeyRequest = null;
        _absenceJustCleared = false;
        return result;
      } catch (e, st) {
        lastError = e;
        lastStackTrace = st;
        if (attempt < maxAttempts) {
          await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
        }
      }
    }

    _absenceJustCleared = false;
    if (!isClosed) {
      final baseMessage = ApiErrorHandler.extractErrorMessage(lastError);
      final message = hadClearedAbsence
          ? 'Absence record was cleared, but sign-in failed after retrying '
                '($baseMessage). This staff member is now NEITHER marked '
                'absent nor signed in — please try signing them in again '
                'right away.'
          : baseMessage;
      emit(StaffSignInSubmitFailure(message));
    }
    AppLogger.recordError(
      lastError,
      lastStackTrace,
      reason: 'attendance.staff_sign_in.submit',
    );
    Error.throwWithStackTrace(lastError, lastStackTrace);
  }
}
