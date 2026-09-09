import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/usecases/delete_staff_attendance_record_usecase.dart';

import 'attendance_delete_state.dart';

/// Owns the staff attendance-record delete call and its in-progress/success/
/// failure state, routing the mutation through
/// [DeleteStaffAttendanceRecordUseCase] instead of the View touching
/// `AttendanceRepository` directly.
///
/// [delete] intentionally RETHROWS on error so the view keeps its exact
/// success snackbar + reload and catch behaviour; this refactor only moves the
/// repository call behind the UseCase and centralises delete state.
class StaffAttendanceDeleteCubit extends Cubit<AttendanceDeleteState> {
  StaffAttendanceDeleteCubit(
    this._deleteStaffAttendanceRecord, {
    required StorageService storageService,
  }) : _storageService = storageService,
       super(const AttendanceDeleteInitial());

  final DeleteStaffAttendanceRecordUseCase _deleteStaffAttendanceRecord;
  final StorageService _storageService;

  /// True while a delete is in flight.
  bool get isDeleting => state is AttendanceDeleteInProgress;

  /// Resolves the logged-in user's staffCode from storage. The caller (View)
  /// should check for empty and show its own re-login prompt BEFORE calling
  /// [delete] — kept as a separate step (not folded into [delete]'s
  /// try/catch) so that specific message stays distinct from delete()'s
  /// generic API-error handling.
  Future<String> resolveStaffCode() async {
    return (await _storageService.getString(StorageKeys.staffCode) ?? '')
        .trim();
  }

  Future<void> delete({
    required String attendanceRecordCode,
    required String staffCode,
  }) async {
    emit(const AttendanceDeleteInProgress());
    try {
      await _deleteStaffAttendanceRecord(
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
