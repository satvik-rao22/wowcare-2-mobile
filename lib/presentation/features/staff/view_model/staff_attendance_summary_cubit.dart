import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../domain/features/attendance/usecases/get_staff_attendance_expected_summary_usecase.dart';
import '../../../../domain/features/attendance/usecases/get_staff_today_sign_in_status_map_usecase.dart';

/// Owns the two attendance-derived data fetches [StaffScreen] shows in its
/// header (expected/present/absent/signed-out/not-marked counts) and per-row
/// dots (today's sign-in status for the currently selected staff codes).
/// Previously run inline in the View via direct `serviceLocator<UseCase>()`
/// calls with the results cached in local `setState` fields.
class StaffAttendanceSummaryCubit extends Cubit<StaffAttendanceSummaryState> {
  StaffAttendanceSummaryCubit({
    required GetStaffAttendanceExpectedSummaryUseCase
    getStaffAttendanceExpectedSummaryUseCase,
    required GetStaffTodaySignInStatusMapUseCase
    getStaffTodaySignInStatusMapUseCase,
  }) : _getStaffAttendanceExpectedSummaryUseCase =
           getStaffAttendanceExpectedSummaryUseCase,
       _getStaffTodaySignInStatusMapUseCase =
           getStaffTodaySignInStatusMapUseCase,
       super(const StaffAttendanceSummaryState());

  final GetStaffAttendanceExpectedSummaryUseCase
  _getStaffAttendanceExpectedSummaryUseCase;
  final GetStaffTodaySignInStatusMapUseCase
  _getStaffTodaySignInStatusMapUseCase;

  Future<void> loadExpectedSummary({String? classroomCode}) async {
    try {
      final summary = await _getStaffAttendanceExpectedSummaryUseCase(
        classroomCode: classroomCode,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          expectedTotal: summary.expected,
          expectedSignedIn: summary.present,
          expectedAbsent: summary.absent,
          expectedSignedOut: summary.signOut,
          expectedNotMarked: summary.notMarked,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          expectedTotal: 0,
          expectedSignedIn: 0,
          expectedAbsent: 0,
          expectedSignedOut: 0,
          expectedNotMarked: 0,
        ),
      );
    }
  }

  Future<void> loadAttendanceStatusForSelection(List<String> staffCodes) async {
    if (staffCodes.isEmpty) {
      emit(
        state.copyWith(
          attendanceStatusByStaffCode: const {},
          attendanceStatusLoading: false,
          attendanceStatusError: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        attendanceStatusLoading: true,
        attendanceStatusError: false,
      ),
    );
    try {
      final map = await _getStaffTodaySignInStatusMapUseCase(
        staffCodes: staffCodes,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          attendanceStatusByStaffCode: map,
          attendanceStatusLoading: false,
          attendanceStatusError: false,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          attendanceStatusByStaffCode: const {},
          attendanceStatusLoading: false,
          attendanceStatusError: true,
        ),
      );
    }
  }
}

class StaffAttendanceSummaryState extends Equatable {
  const StaffAttendanceSummaryState({
    this.expectedTotal = 0,
    this.expectedSignedIn = 0,
    this.expectedAbsent = 0,
    this.expectedSignedOut = 0,
    this.expectedNotMarked = 0,
    this.attendanceStatusByStaffCode = const {},
    this.attendanceStatusLoading = false,
    this.attendanceStatusError = false,
  });

  final int expectedTotal;
  final int expectedSignedIn;
  final int expectedAbsent;
  final int expectedSignedOut;
  final int expectedNotMarked;
  final Map<String, String> attendanceStatusByStaffCode;
  final bool attendanceStatusLoading;
  final bool attendanceStatusError;

  StaffAttendanceSummaryState copyWith({
    int? expectedTotal,
    int? expectedSignedIn,
    int? expectedAbsent,
    int? expectedSignedOut,
    int? expectedNotMarked,
    Map<String, String>? attendanceStatusByStaffCode,
    bool? attendanceStatusLoading,
    bool? attendanceStatusError,
  }) {
    return StaffAttendanceSummaryState(
      expectedTotal: expectedTotal ?? this.expectedTotal,
      expectedSignedIn: expectedSignedIn ?? this.expectedSignedIn,
      expectedAbsent: expectedAbsent ?? this.expectedAbsent,
      expectedSignedOut: expectedSignedOut ?? this.expectedSignedOut,
      expectedNotMarked: expectedNotMarked ?? this.expectedNotMarked,
      attendanceStatusByStaffCode:
          attendanceStatusByStaffCode ?? this.attendanceStatusByStaffCode,
      attendanceStatusLoading:
          attendanceStatusLoading ?? this.attendanceStatusLoading,
      attendanceStatusError:
          attendanceStatusError ?? this.attendanceStatusError,
    );
  }

  @override
  List<Object?> get props => [
    expectedTotal,
    expectedSignedIn,
    expectedAbsent,
    expectedSignedOut,
    expectedNotMarked,
    attendanceStatusByStaffCode,
    attendanceStatusLoading,
    attendanceStatusError,
  ];
}
