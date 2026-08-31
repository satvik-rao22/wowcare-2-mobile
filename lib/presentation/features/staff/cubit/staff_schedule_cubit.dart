import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../domain/features/staff/entities/school_regular_schedule_day.dart';
import '../../../../domain/features/staff/entities/staff_schedule_entry.dart';
import '../../../../domain/features/staff/usecases/get_school_regular_schedules_usecase.dart';
import '../../../../domain/features/staff/usecases/update_staff_schedules_usecase.dart';

part 'staff_schedule_state.dart';

/// Read + mutation for a staff member's work/break schedule.
///
/// Screens route the school-regular-schedule read and the schedule save
/// through this cubit → use case → repository so no view depends on
/// [StaffRepository] directly.
class StaffScheduleCubit extends Cubit<StaffScheduleState> {
  StaffScheduleCubit({
    required GetSchoolRegularSchedulesUseCase getSchoolRegularSchedulesUseCase,
    required UpdateStaffSchedulesUseCase updateStaffSchedulesUseCase,
  })  : _getSchoolRegularSchedulesUseCase = getSchoolRegularSchedulesUseCase,
        _updateStaffSchedulesUseCase = updateStaffSchedulesUseCase,
        super(const StaffScheduleState.initial());

  final GetSchoolRegularSchedulesUseCase _getSchoolRegularSchedulesUseCase;
  final UpdateStaffSchedulesUseCase _updateStaffSchedulesUseCase;

  /// Thin Future-based read for callers that still drive their own
  /// `FutureBuilder`/`setState` (edit-schedule screen, profile tab, staff
  /// card) — same data SOURCE as before, without a state machine.
  Future<List<SchoolRegularScheduleDay>> fetchSchoolRegularSchedules(
    String schoolCode,
  ) {
    return _getSchoolRegularSchedulesUseCase(schoolCode: schoolCode);
  }

  /// In-flight mutations keyed by `action:code`. A second identical call while
  /// the first is still running returns the SAME future instead of issuing a
  /// duplicate request — single-flight independent of any UI button-disabling.
  final Map<String, Future<Object?>> _inFlightMutations = {};

  Future<T> _singleFlightMutation<T>(
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

  /// Saves the staff member's work & break schedules. Single-flight per
  /// [staffCode]; RETHROWS on error so the caller keeps its existing
  /// `await` + snackbar + pop + try/catch.
  Future<String> updateSchedules({
    required String staffCode,
    required List<StaffWorkScheduleEntry> workSchedules,
    required List<StaffBreakScheduleEntry> breakSchedules,
  }) {
    return _singleFlightMutation<String>('updateSchedules:$staffCode', () async {
      if (!isClosed) emit(state.copyWith(mutationInProgress: true));
      try {
        return await _updateStaffSchedulesUseCase(
          staffCode: staffCode,
          workSchedules: workSchedules,
          breakSchedules: breakSchedules,
        );
      } finally {
        if (!isClosed) emit(state.copyWith(mutationInProgress: false));
      }
    });
  }
}
