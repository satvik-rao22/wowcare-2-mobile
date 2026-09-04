import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/source/staff_source.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';

part 'staff_schedule_state.dart';

/// The working week behind 6c's "Edit the week" key.
///
/// **A work schedule is Admin-only.** A staff member reads their week on the
/// profile and gets the refusal here, because the hours they are contracted
/// to are not theirs to set. The cubit refuses before it fetches, so a route
/// reached by hand is refused too.
class StaffScheduleCubit extends Cubit<StaffScheduleState> {
  StaffScheduleCubit({
    required StaffSource source,
    required String staffId,
    required StaffLens lens,
  }) : _source = source,
       super(StaffScheduleState(staffId: staffId, lens: lens));

  final StaffSource _source;

  bool _isFetching = false;

  Future<void> load() async {
    if (!state.lens.canWrite) {
      emit(state.copyWith(status: StaffScheduleStatus.denied));
      return;
    }
    if (_isFetching) return;
    _isFetching = true;
    try {
      final profile = await _source.loadProfile(state.staffId);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: StaffScheduleStatus.editing,
          name: profile.firstName,
          week: profile.week,
        ),
      );
    } on Exception catch (_) {
      if (isClosed) return;
      emit(state.copyWith(status: StaffScheduleStatus.failed));
    } finally {
      _isFetching = false;
    }
  }

  void setShift(StaffShift shift) => emit(
    state
        .copyWith(
          week: <StaffShift>[
            for (final day in state.week)
              if (day.weekday == shift.weekday) shift else day,
          ],
        )
        .cleared(),
  );

  /// One day's times across the whole week.
  void copyToAllDays(int weekday) {
    final source = state.week.firstWhere(
      (day) => day.weekday == weekday,
      orElse: () => state.week.first,
    );
    emit(
      state
          .copyWith(
            week: <StaffShift>[
              for (final day in state.week)
                source.copyOnto(day.weekday).copyWith(date: day.date),
            ],
          )
          .cleared(),
    );
  }

  Future<void> submit() async {
    if (!state.lens.canWrite || state.isSaving) return;

    final error = _validate(state.week);
    if (error != null) {
      emit(state.copyWith(error: error));
      return;
    }

    emit(state.copyWith(status: StaffScheduleStatus.saving, clearError: true));
    try {
      final saved = await _source.updateSchedule(
        id: state.staffId,
        week: state.week,
      );
      if (isClosed) return;
      emit(state.copyWith(status: StaffScheduleStatus.saved, week: saved.week));
    } on Exception catch (_) {
      if (isClosed) return;
      emit(state.copyWith(status: StaffScheduleStatus.failed));
    }
  }

  static String? _validate(List<StaffShift> week) {
    for (final shift in week) {
      if (!shift.isOrderValid) return StaffStrings.shiftOrderError;
      if (!shift.isBreakInsideShift) return StaffStrings.breakOutsideError;
    }
    return null;
  }
}
