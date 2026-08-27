import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/domain/features/attendance/usecases/delete_student_attendance_record_usecase.dart';

import 'attendance_delete_state.dart';

/// Owns the student attendance-record delete call and its in-progress/success/
/// failure state, routing the mutation through
/// [DeleteStudentAttendanceRecordUseCase] instead of the View touching
/// `AttendanceRepository` directly.
///
/// [delete] intentionally RETHROWS on error so the view keeps its exact
/// success snackbar + reload and catch behaviour; this refactor only moves the
/// repository call behind the UseCase and centralises delete state.
class StudentAttendanceDeleteCubit extends Cubit<AttendanceDeleteState> {
  StudentAttendanceDeleteCubit(this._deleteStudentAttendanceRecord)
    : super(const AttendanceDeleteInitial());

  final DeleteStudentAttendanceRecordUseCase _deleteStudentAttendanceRecord;

  /// True while a delete is in flight.
  bool get isDeleting => state is AttendanceDeleteInProgress;

  Future<void> delete({
    required String attendanceRecordCode,
    required String staffCode,
  }) async {
    emit(const AttendanceDeleteInProgress());
    try {
      await _deleteStudentAttendanceRecord(
        attendanceRecordCode: attendanceRecordCode,
        staffCode: staffCode,
      );
      if (!isClosed) emit(const AttendanceDeleteSuccess());
    } catch (e) {
      if (!isClosed) {
        emit(AttendanceDeleteFailure(ApiErrorHandler.extractErrorMessage(e)));
      }
      rethrow;
    }
  }
}
