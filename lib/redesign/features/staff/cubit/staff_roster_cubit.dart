import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/source/staff_source.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';

part 'staff_roster_state.dart';

/// M06's roster (6a), its filter sheet (6b) and the three states 6e draws
/// when the list is not the viewer's to see.
///
/// The lens is a constructor argument rather than something the cubit reads
/// off a locator: a roster is built for one persona, and the read boundary is
/// then arithmetic on the state rather than a question the screen has to
/// remember to ask. Search and the filters live here too, so the chips over
/// the list and the rows under them can never disagree.
class StaffRosterCubit extends Cubit<StaffRosterState> {
  StaffRosterCubit({required StaffSource source, required StaffLens lens})
    : _source = source,
      super(StaffRosterState(lens: lens));

  final StaffSource _source;

  bool _isFetching = false;

  /// [isSilent] keeps the roster on screen while a revisit refetches behind
  /// it, so coming back from a profile never flashes empty.
  Future<void> load({bool isSilent = false}) async {
    if (!state.lens.canOpen) {
      emit(state.copyWith(status: StaffRosterStatus.denied));
      return;
    }
    if (_isFetching) return;
    _isFetching = true;
    if (!isSilent) emit(state.copyWith(status: StaffRosterStatus.loading));

    try {
      final roster = await _source.loadRoster();
      if (isClosed) return;
      emit(state.copyWith(status: StaffRosterStatus.ready, roster: roster));
    } on Exception catch (_) {
      if (isClosed) return;
      // A team we already have stays up and the banner says how old it is;
      // with nothing to show, the screen is the "Waiting for a signal" state.
      emit(
        state.copyWith(
          status: state.roster.isEmpty
              ? StaffRosterStatus.failed
              : StaffRosterStatus.cached,
        ),
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() => load(isSilent: true);

  void search(String query) => emit(state.copyWith(query: query));

  void clearSearch() => emit(state.copyWith(query: ''));

  void applyFilters(StaffFilters filters) =>
      emit(state.copyWith(filters: filters));

  void clearFilters() => emit(state.copyWith(filters: const StaffFilters()));

  /// Take one chip off the row over the roster.
  void removeChip(StaffChip chip) {
    final filters = state.filters;
    final next = switch (chip.group) {
      StaffChipGroup.status || StaffChipGroup.order => filters,
      StaffChipGroup.designation => filters.copyWith(
        designations: <String>{...filters.designations}..remove(chip.value),
      ),
      StaffChipGroup.primaryClassroom => filters.copyWith(
        primaryClassrooms: <String>{...filters.primaryClassrooms}
          ..remove(chip.value),
      ),
      StaffChipGroup.allowedIn => filters.copyWith(
        allowedIn: <String>{...filters.allowedIn}..remove(chip.value),
      ),
      StaffChipGroup.attendance => filters.copyWith(
        attendance: <AttendanceStatus>{...filters.attendance}
          ..remove(chip.value),
      ),
    };
    emit(state.copyWith(filters: next));
  }

  /// One row at a time is open, the way an accordion behaves.
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

  /// 6f, and the reactivate that undoes it. The roster is patched in place so
  /// the row's pill changes without a refetch.
  Future<bool> setActive({required String id, required bool isActive}) async {
    if (!state.lens.canWrite) return false;
    try {
      final updated = await _source.setActive(id: id, isActive: isActive);
      if (isClosed) return true;
      emit(state.copyWith(roster: state.roster.replacing(updated)));
      return true;
    } on Exception catch (_) {
      return false;
    }
  }
}
