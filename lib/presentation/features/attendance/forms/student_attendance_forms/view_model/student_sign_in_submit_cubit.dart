import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/idempotency_key.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_absent_form.dart';
import 'package:wowcare/domain/features/attendance/entities/student_sign_in_request.dart';
import 'package:wowcare/domain/features/attendance/usecases/delete_student_absence_record_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_absent_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_student_sign_in_usecase.dart';

import 'student_sign_in_submit_state.dart';

/// Owns the student sign-in submit call and its in-progress/success/failure
/// state, routing the mutation through [SubmitStudentSignInUseCase] instead of
/// the View touching [AttendanceRepository] directly.
///
/// [submit] intentionally RETURNS the [AttendanceActionResult] and RETHROWS on
/// error: this refactor moves the repository call behind the UseCase and
/// centralises submit state, but the form keeps its exact success/navigation
/// and catch behaviour, so nothing the user sees changes.
class StudentSignInSubmitCubit extends Cubit<StudentSignInSubmitState> {
  StudentSignInSubmitCubit(
    this._submitStudentSignIn, {
    required GetStudentAbsentFormListUseCase getStudentAbsentFormListUseCase,
    required DeleteStudentAbsenceRecordUseCase
    deleteStudentAbsenceRecordUseCase,
  }) : _getStudentAbsentFormListUseCase = getStudentAbsentFormListUseCase,
       _deleteStudentAbsenceRecordUseCase = deleteStudentAbsenceRecordUseCase,
       super(const StudentSignInSubmitInitial());

  final SubmitStudentSignInUseCase _submitStudentSignIn;
  final GetStudentAbsentFormListUseCase _getStudentAbsentFormListUseCase;
  final DeleteStudentAbsenceRecordUseCase _deleteStudentAbsenceRecordUseCase;

  String? _idempotencyKey;

  /// True while a submit is in flight.
  bool get isSubmitting => state is StudentSignInSubmitInProgress;

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

  /// Staff sign-in: for students marked absent on [attendanceDateYyyyMmDd],
  /// delete absence records first (override sign-in). Best-effort — if the
  /// absent-form-list lookup fails, skips deletion and lets the sign-in POST
  /// run rather than blocking the whole sign-in on this pre-step.
  Future<void> clearTodaysAbsenceRecordsBeforeSignIn({
    required String attendanceDateYyyyMmDd,
    required String staffCode,
    required List<({String studentCode, String classroomCode, String fullName})>
    students,
  }) async {
    final allItems = <StudentAttendanceAbsentFormItem>[];

    try {
      var page = 0;
      const pageSize = 200;
      while (true) {
        final absentPage = await _getStudentAbsentFormListUseCase(
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
        '[StudentSignIn] absent-form-list lookup failed ($e); '
        'proceeding to sign-in without clearing absence records',
      );
      return; // skip deletion, caller continues to the sign-in POST
    }

    final processedStudentCodes = <String>{};
    for (final s in students) {
      final sc = s.studentCode.trim();
      if (sc.isEmpty || processedStudentCodes.contains(sc)) continue;

      final matches = allItems.where((it) {
        if (it.studentCode.trim() != sc) return false;
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
          'Cannot sign in ${s.fullName}: marked absent for '
          'this day but the absence record could not be resolved. Refresh and try again.',
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

      await _deleteStudentAbsenceRecordUseCase(
        absenceRecordCode: chosen.absenceRecordCode!.trim(),
        staffCode: staffCode,
      );
      processedStudentCodes.add(sc);
    }
  }

  Future<AttendanceActionResult> submit({
    required StudentSignInRequest request,
    required bool isParent,
  }) async {
    emit(const StudentSignInSubmitInProgress());
    try {
      _idempotencyKey ??= IdempotencyKey.generate();
      final result = await _submitStudentSignIn(
        request: request,
        isParent: isParent,
        idempotencyKey: _idempotencyKey,
      );
      if (!isClosed) emit(StudentSignInSubmitSuccess(result));
      _idempotencyKey = null;
      return result;
    } catch (e) {
      if (!isClosed) {
        emit(
          StudentSignInSubmitFailure(ApiErrorHandler.extractErrorMessage(e)),
        );
      }
      rethrow;
    }
  }
}
