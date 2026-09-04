import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/attendance/attendance_formats.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/source/attendance_source.dart';

part 'attendance_state.dart';

/// 4a, 4c, 4d and 4e. One day, three lenses, and what the screen says when
/// there is nothing to show.
///
/// The persona and the classroom a staff member is rostered to are passed in
/// rather than read off a locator, so the screen never asks who is looking:
/// it draws the groups the state carries and hides the write keys the state
/// says are not there.
class AttendanceCubit extends Cubit<AttendanceState> {
  AttendanceCubit({
    required AttendanceSource source,
    required Persona persona,
    required DateTime today,
    String? scopeClassroom,
  }) : _source = source,
       super(
         AttendanceState(
           persona: persona,
           today: today,
           day: today,
           scopeClassroom: scopeClassroom,
         ),
       );

  final AttendanceSource _source;

  bool _isFetching = false;

  /// [isSilent] keeps the list on screen while a navigation revisit refetches
  /// behind it, so coming back from the sign-in form never flashes empty.
  Future<void> load({bool isSilent = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!isSilent) {
      emit(state.copyWith(status: AttendanceLoadStatus.loading));
    }

    try {
      final result = await _source.loadDay(
        persona: state.persona,
        audience: state.audience,
        day: state.day,
        scopeClassroom: state.scopeClassroom,
        query: state.query,
      );
      if (isClosed) return;

      switch (result) {
        case AttendanceDayLoaded(:final snapshot):
          emit(
            state.copyWith(
              status: AttendanceLoadStatus.ready,
              snapshot: snapshot,
              clearAsOfLabel: true,
            ),
          );
        case AttendanceDayOffline(:final snapshot, :final asOfLabel):
          emit(
            state.copyWith(
              status: AttendanceLoadStatus.offline,
              snapshot: snapshot,
              asOfLabel: asOfLabel,
            ),
          );
      }
    } on Exception catch (_) {
      if (!isClosed) {
        emit(state.copyWith(status: AttendanceLoadStatus.failed));
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() => load(isSilent: true);

  // --- What the list is showing --------------------------------------------

  Future<void> setAudience(AttendanceAudience audience) async {
    if (audience == state.audience) return;
    emit(
      state.copyWith(
        audience: audience,
        filter: AttendanceFilter.all,
        selectedIds: const <String>{},
        isSelectMode: false,
        clearExpanded: true,
      ),
    );
    await load(isSilent: true);
  }

  /// Tapping the live chip clears it back to All, the way the frame does.
  void setFilter(AttendanceFilter filter) => emit(
    state.copyWith(
      filter: state.filter == filter ? AttendanceFilter.all : filter,
      clearExpanded: true,
    ),
  );

  /// The header's filter key. Which classrooms are on the list, which is
  /// what 4e's hidden-by-the-filter state is about.
  void setClassrooms(Set<String> classrooms) =>
      emit(state.copyWith(classrooms: classrooms, clearExpanded: true));

  void openSearch() => emit(state.copyWith(isSearching: true));

  Future<void> closeSearch() async {
    if (!state.isSearching && state.query.isEmpty) return;
    emit(state.copyWith(isSearching: false, query: '', clearExpanded: true));
    await load(isSilent: true);
  }

  /// Debounced by the screen, so this fires once a name has stopped being
  /// typed. The two fixture literals reach 4e's states through it.
  Future<void> search(String query) async {
    if (query == state.query) return;
    emit(state.copyWith(query: query, clearExpanded: true));
    await load(isSilent: true);
  }

  /// 4e's "Clear filter": back to every classroom, every status.
  Future<void> clearNarrowing() async {
    emit(
      state.copyWith(
        query: '',
        filter: AttendanceFilter.all,
        classrooms: const <String>{},
        isSearching: false,
        clearExpanded: true,
      ),
    );
    await load(isSilent: true);
  }

  // --- Which day ------------------------------------------------------------

  Future<void> chooseDay(DaySelection selection) async {
    final day = switch (selection.choice) {
      DayChoice.today => state.today,
      DayChoice.yesterday => state.today.subtract(const Duration(days: 1)),
      DayChoice.pickADay => selection.day ?? state.day,
      DayChoice.range => state.day,
    };
    if (selection.choice == DayChoice.range) return;
    await _goToDay(day);
  }

  /// The two arrows either side of the date. Tomorrow is never a day.
  Future<void> stepDay(int days) async {
    final next = state.day.add(Duration(days: days));
    if (AttendanceFormats.daysBetween(next, state.today) < 0) return;
    await _goToDay(next);
  }

  Future<void> _goToDay(DateTime day) async {
    if (AttendanceFormats.isSameDay(day, state.day)) return;
    emit(
      state.copyWith(
        day: day,
        isSelectMode: false,
        selectedIds: const <String>{},
        clearExpanded: true,
      ),
    );
    await load();
  }

  // --- Rows -----------------------------------------------------------------

  /// A row opens where it stands to show the whole record. Only one is open
  /// at a time, which is what makes the list readable.
  void toggleExpanded(String id) => emit(
    state.expandedId == id
        ? state.copyWith(clearExpanded: true)
        : state.copyWith(expandedId: id),
  );

  void toggleSelectMode() => emit(
    state.copyWith(
      isSelectMode: !state.isSelectMode,
      selectedIds: const <String>{},
      clearExpanded: true,
    ),
  );

  /// The FAB. It does not open a form: there is no create-attendance
  /// endpoint, so a record starts by picking who arrived.
  void startSelecting() => emit(
    state.copyWith(
      isSelectMode: true,
      selectedIds: const <String>{},
      clearExpanded: true,
    ),
  );

  void toggleSelected(String id) {
    final next = <String>{...state.selectedIds};
    if (!next.remove(id)) next.add(id);
    emit(state.copyWith(selectedIds: next));
  }

  void clearSelection() =>
      emit(state.copyWith(selectedIds: const <String>{}, isSelectMode: false));

  // --- Writes ---------------------------------------------------------------

  /// 4d. A staff member's own sign-in is the only geofenced one, and until it
  /// lands the classroom below is read only.
  Future<bool> signSelfIn() async {
    final shift = state.snapshot.selfShift;
    if (state.isWorking || shift == null || !shift.canSignSelfIn) return false;
    emit(state.copyWith(isWorking: true));
    try {
      final signed = await _source.signSelfIn();
      if (isClosed) return true;
      emit(state.copyWith(isWorking: false, snapshot: _withSelfShift(signed)));
      return true;
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(isWorking: false));
      return false;
    }
  }

  /// The end of their own shift. The classroom below locks back up, which
  /// is the same rule read the other way round.
  Future<bool> signSelfOut() async {
    final shift = state.snapshot.selfShift;
    if (state.isWorking || shift == null || !shift.isSignedIn) return false;
    emit(state.copyWith(isWorking: true));
    try {
      final signed = await _source.signSelfOut();
      if (isClosed) return true;
      emit(state.copyWith(isWorking: false, snapshot: _withSelfShift(signed)));
      return true;
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(isWorking: false));
      return false;
    }
  }

  AttendanceSnapshot _withSelfShift(SelfShift shift) => AttendanceSnapshot(
    rows: state.snapshot.rows,
    classroomNames: state.snapshot.classroomNames,
    enrolled: state.snapshot.enrolled,
    allowedRatio: state.snapshot.allowedRatio,
    staffPresent: state.snapshot.staffPresent,
    schoolClassroomCount: state.snapshot.schoolClassroomCount,
    studentsTotal: state.snapshot.studentsTotal,
    studentsSignedIn: state.snapshot.studentsSignedIn,
    staffTotal: state.snapshot.staffTotal,
    staffSignedIn: state.snapshot.staffSignedIn,
    staffMinutesToday: state.snapshot.staffMinutesToday,
    selfShift: shift,
    staffGap: state.snapshot.staffGap,
    children: state.snapshot.children,
  );

  /// The one action that takes a reason.
  Future<bool> markAbsent({required String id, required String reason}) =>
      _write(
        () => _source.markAbsent(
          ids: <String>[id],
          date: state.day,
          reason: reason,
        ),
      );

  /// Override Sign In leans on this: the absence record is deleted first.
  Future<bool> undoAbsence(String id) => _write(() => _source.undoAbsence(id));

  Future<bool> transfer({required String id, required String toClassroom}) =>
      _write(() => _source.transfer(id: id, toClassroom: toClassroom));

  Future<bool> editTimes({
    required String id,
    required DateTime at,
    required bool isSignOut,
  }) => _write(() => _source.editTimes(id: id, at: at, isSignOut: isSignOut));

  Future<bool> _write(Future<void> Function() action) async {
    if (state.isWorking) return false;
    emit(state.copyWith(isWorking: true));
    try {
      await action();
      if (isClosed) return true;
      emit(state.copyWith(isWorking: false, clearExpanded: true));
      await load(isSilent: true);
      return true;
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(isWorking: false));
      return false;
    }
  }
}
