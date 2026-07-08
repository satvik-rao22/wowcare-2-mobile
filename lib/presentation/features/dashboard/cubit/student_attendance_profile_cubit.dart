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
  }) : _getStudentAttendanceCustomUseCase = getStudentAttendanceCustomUseCase,
       _getStudentAttendanceAbsentToggleViewUseCase =
           getStudentAttendanceAbsentToggleViewUseCase,
       super(const StudentAttendanceProfileState.initial());

  final GetStudentAttendanceCustomUseCase _getStudentAttendanceCustomUseCase;
  final GetStudentAttendanceAbsentToggleViewUseCase
  _getStudentAttendanceAbsentToggleViewUseCase;

  bool _isFetching = false;
  DateTime? _cachedAt;
  static const _cacheTtl = Duration(minutes: 5);

  bool _isCacheValid() =>
      _cachedAt != null && DateTime.now().difference(_cachedAt!) < _cacheTtl;

  Future<void> loadAttendanceProfile({
    required String studentCode,
    required DateTime fromDate,
    required DateTime toDate,
    bool forceRefresh = false,
    bool background = false,
  }) async {
    final code = studentCode.trim();
    if (code.isEmpty) {
      emit(const StudentAttendanceProfileState.initial());
      return;
    }

    // Prevent concurrent requests
    if (_isFetching) {
      return;
    }

    // Guard: same data already loaded, within TTL, no force refresh
    if (!forceRefresh &&
        state.studentCode == code &&
        state.status == _Status.loaded &&
        state.fromDate?.isAtSameMomentAs(fromDate) == true &&
        state.toDate?.isAtSameMomentAs(toDate) == true &&
        _isCacheValid()) {
      return;
    }

    // During a background refresh keep the loaded data visible (no shimmer).
    final hasData = state.status == _Status.loaded && state.studentCode == code;
    _isFetching = true;
    if (!(background && hasData)) {
      emit(
        state.copyWith(
          status: _Status.loading,
          studentCode: code,
          errorMessage: null,
        ),
      );
    }

    try {
      final fromDateString = _formatDate(fromDate);
      final toDateString = _formatDate(toDate);

      final attendancePage = await _getStudentAttendanceCustomUseCase(
        fromAttendanceDate: fromDateString,
        toAttendanceDate: toDateString,
        page: 0,
        size: 200,
      );

      int attendedDays = 0;
      int attendedHours = 0;
      int attendedMinutes = 0;
      String totalAttendedTime = '';

      // Filter by studentCode instead of taking first item
      final attendedItem = attendancePage.items
          .where((item) => item.studentCode == code)
          .cast<dynamic>()
          .firstOrNull;

      if (attendedItem != null) {
        attendedDays = attendedItem.attendedDays;
        attendedHours = attendedItem.attendedHours;
        attendedMinutes = attendedItem.attendedMinutes;
        totalAttendedTime = attendedItem.attendedTime;
      }

      final absentPage = await _getStudentAttendanceAbsentToggleViewUseCase(
        fromAbsenceDate: fromDateString,
        toAbsenceDate: toDateString,
        page: 0,
        size: 200,
      );

      int absentDays = 0;
      // Filter by studentCode to find matching absence record
      final absentItem = absentPage.items
          .where((item) => item.studentCode == code)
          .cast<dynamic>()
          .firstOrNull;

      if (absentItem != null) {
        absentDays = absentItem.absentDays;
      }

      if (!isClosed) {
        _cachedAt = DateTime.now();
        emit(
          StudentAttendanceProfileState.loaded(
            studentCode: code,
            attendedDays: attendedDays,
            attendedHours: attendedHours,
            attendedMinutes: attendedMinutes,
            totalAttendedTime: totalAttendedTime,
            absentDays: absentDays,
            fromDate: fromDate,
            toDate: toDate,
          ),
        );
      }
    } catch (e) {
      // Keep the stale-but-valid data on a failed background refresh.
      if (!isClosed && !(background && hasData)) {
        emit(
          state.copyWith(
            status: _Status.error,
            studentCode: code,
            errorMessage: ApiErrorHandler.extractErrorMessage(e),
          ),
        );
      }
    } finally {
      _isFetching = false;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
