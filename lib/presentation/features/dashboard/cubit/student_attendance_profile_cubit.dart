import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_attendance_custom_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_attendance_absent_toggle_view_usecase.dart';

part 'student_attendance_profile_state.dart';

class StudentAttendanceProfileCubit
    extends Cubit<StudentAttendanceProfileState> {
  StudentAttendanceProfileCubit({
    required GetStudentAttendanceCustomUseCase
        getStudentAttendanceCustomUseCase,
    required GetStudentAttendanceAbsentToggleViewUseCase
        getStudentAttendanceAbsentToggleViewUseCase,
  })  : _getStudentAttendanceCustomUseCase =
            getStudentAttendanceCustomUseCase,
        _getStudentAttendanceAbsentToggleViewUseCase =
            getStudentAttendanceAbsentToggleViewUseCase,
        super(const StudentAttendanceProfileState.initial());

  final GetStudentAttendanceCustomUseCase _getStudentAttendanceCustomUseCase;
  final GetStudentAttendanceAbsentToggleViewUseCase
      _getStudentAttendanceAbsentToggleViewUseCase;

  Future<void> loadAttendanceProfile({
    required String studentCode,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final code = studentCode.trim();
    if (code.isEmpty) {
      emit(const StudentAttendanceProfileState.initial());
      return;
    }

    if (state.studentCode == code && state.status == _Status.loaded) {
      return;
    }

    emit(state.copyWith(
      status: _Status.loading,
      studentCode: code,
      errorMessage: null,
    ));

    try {
      final fromDateString = _formatDate(fromDate);
      final toDateString = _formatDate(toDate);

      final attendancePage = await _getStudentAttendanceCustomUseCase(
        fromAttendanceDate: fromDateString,
        toAttendanceDate: toDateString,
        page: 0,
        size: 1,
      );

      int attendedDays = 0;
      int attendedHours = 0;
      int attendedMinutes = 0;
      String totalAttendedTime = '';

      if (attendancePage.items.isNotEmpty) {
        final item = attendancePage.items.first;
        attendedDays = item.attendedDays;
        attendedHours = item.attendedHours;
        attendedMinutes = item.attendedMinutes;
        totalAttendedTime = item.attendedTime;
      }

      final absentPage = await _getStudentAttendanceAbsentToggleViewUseCase(
        fromAbsenceDate: fromDateString,
        toAbsenceDate: toDateString,
        page: 0,
        size: 1,
      );

      int absentDays = 0;
      if (absentPage.items.isNotEmpty) {
        absentDays = absentPage.items.first.absentDays;
      }

      if (!isClosed) {
        emit(StudentAttendanceProfileState.loaded(
          studentCode: code,
          attendedDays: attendedDays,
          attendedHours: attendedHours,
          attendedMinutes: attendedMinutes,
          totalAttendedTime: totalAttendedTime,
          absentDays: absentDays,
          fromDate: fromDate,
          toDate: toDate,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: _Status.error,
          studentCode: code,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ));
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
