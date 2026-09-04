import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/source/students_source.dart';

part 'students_roster_state.dart';

/// 5a, 5b and 5g. The roster, what narrows it, and what it says when there is
/// nothing to show.
///
/// The persona and the classroom a staff member is rostered to are passed in
/// rather than read off a locator, so the screen never asks who is looking:
/// it draws the groups the state carries and hides the write keys the state
/// says are not there.
class StudentsRosterCubit extends Cubit<StudentsRosterState> {
  StudentsRosterCubit({
    required StudentsSource source,
    required Persona persona,
    String? scopeClassroom,
  }) : _source = source,
       super(
         StudentsRosterState(persona: persona, scopeClassroom: scopeClassroom),
       );

  final StudentsSource _source;

  bool _isFetching = false;

  /// [isSilent] keeps the roster on screen while a navigation revisit
  /// refetches behind it, so coming back from a profile never flashes empty.
  Future<void> load({bool isSilent = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!isSilent) emit(state.copyWith(status: RosterStatus.loading));

    try {
      final result = await _source.loadRoster(
        persona: state.persona,
        scopeClassroom: state.scopeClassroom,
        query: state.query,
      );
      if (isClosed) return;

      switch (result) {
        case RosterLoaded(:final snapshot):
          emit(
            state.copyWith(
              status: RosterStatus.ready,
              snapshot: snapshot,
              clearAsOfLabel: true,
            ),
          );
        case RosterOffline(:final snapshot, :final asOfLabel):
          emit(
            state.copyWith(
              status: RosterStatus.offline,
              snapshot: snapshot,
              asOfLabel: asOfLabel,
            ),
          );
        case RosterRestricted():
          emit(
            state.copyWith(
              status: RosterStatus.restricted,
              snapshot: const RosterSnapshot(),
            ),
          );
      }
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(status: RosterStatus.failed));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() => load(isSilent: true);

  /// The search field. Debounced by the screen, so this fires once a name has
  /// stopped being typed.
  Future<void> search(String query) async {
    if (query == state.query) return;
    emit(state.copyWith(query: query, clearExpanded: true));
    await load(isSilent: true);
  }

  void applyFilter(StudentFilter filter) =>
      emit(state.copyWith(filter: filter, clearExpanded: true));

  /// 5g's "Clear the filters", and the sheet's own Clear all.
  void clearFilters() => emit(
    state.copyWith(
      filter: const StudentFilter(),
      query: '',
      clearExpanded: true,
    ),
  );

  /// A row opens to show today's attendance, the tags and the schedule. Only
  /// one is open at a time, which is what makes the list readable.
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

  void toggleSelected(String id) {
    final next = <String>{...state.selectedIds};
    if (!next.remove(id)) next.add(id);
    emit(state.copyWith(selectedIds: next));
  }

  void clearSelection() => emit(state.copyWith(selectedIds: const <String>{}));

  /// 5h, taken from the roster's own actions sheet. Nothing is deleted: the
  /// student leaves the active list and the roster reloads without them.
  ///
  /// Returns whether it went through, so the screen knows which toast to put
  /// up.
  Future<bool> deactivate(String id) async {
    if (state.isWorking) return false;
    emit(state.copyWith(isWorking: true));
    try {
      await _source.deactivateStudent(id);
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
