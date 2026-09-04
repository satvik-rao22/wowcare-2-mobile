import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/source/attendance_source.dart';

part 'attendance_range_state.dart';

/// 4f. A range of days instead of one, so the list stops being sign in keys
/// and becomes two totals per person.
///
/// Both totals come back on the range call the app already makes, and the
/// list pages as it is scrolled the way that call does.
class AttendanceRangeCubit extends Cubit<AttendanceRangeState> {
  AttendanceRangeCubit({
    required AttendanceSource source,
    required DateRange range,
  }) : _source = source,
       super(AttendanceRangeState(range: range));

  final AttendanceSource _source;

  bool _isFetching = false;

  Future<void> load({bool isSilent = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!isSilent) emit(state.copyWith(status: RangeStatus.loading));

    try {
      final page = await _source.loadRange(
        audience: state.audience,
        range: state.range,
        classrooms: state.classrooms,
        query: state.query,
      );
      final classrooms = state.classroomOptions.isEmpty
          ? await _source.classroomNames()
          : state.classroomOptions;
      if (isClosed) return;

      emit(
        state.copyWith(
          status: RangeStatus.ready,
          entries: page.entries,
          page: page.page,
          totalElements: page.totalElements,
          hasMore: page.hasMore,
          classroomOptions: classrooms,
          isLoadingMore: false,
          clearExpanded: true,
        ),
      );
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(status: RangeStatus.failed));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() => load(isSilent: true);

  /// The foot of the list came into view.
  Future<void> loadMore() async {
    if (_isFetching || state.isLoadingMore || !state.hasMore) return;
    _isFetching = true;
    emit(state.copyWith(isLoadingMore: true));

    try {
      final next = await _source.loadRange(
        audience: state.audience,
        range: state.range,
        classrooms: state.classrooms,
        query: state.query,
        page: state.page + 1,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          entries: <RangeEntry>[...state.entries, ...next.entries],
          page: next.page,
          totalElements: next.totalElements,
          hasMore: next.hasMore,
          isLoadingMore: false,
        ),
      );
    } on Exception catch (_) {
      if (!isClosed) emit(state.copyWith(isLoadingMore: false, hasMore: false));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> setAudience(AttendanceAudience audience) async {
    if (audience == state.audience) return;
    emit(state.copyWith(audience: audience, clearExpanded: true));
    await load();
  }

  Future<void> setRange(DateRange range) async {
    if (range == state.range) return;
    emit(state.copyWith(range: range, clearExpanded: true));
    await load();
  }

  Future<void> setClassrooms(Set<String> classrooms) async {
    emit(state.copyWith(classrooms: classrooms, clearExpanded: true));
    await load();
  }

  void openSearch() => emit(state.copyWith(isSearching: true));

  Future<void> closeSearch() async {
    emit(state.copyWith(isSearching: false, query: ''));
    await load(isSilent: true);
  }

  Future<void> search(String query) async {
    if (query == state.query) return;
    emit(state.copyWith(query: query));
    await load(isSilent: true);
  }

  /// The strip's own Clear all: every classroom, every name.
  Future<void> clearAll() async {
    emit(
      state.copyWith(
        classrooms: const <String>{},
        query: '',
        isSearching: false,
        clearExpanded: true,
      ),
    );
    await load();
  }

  void toggleExpanded(String id) => emit(
    state.expandedId == id
        ? state.copyWith(clearExpanded: true)
        : state.copyWith(expandedId: id),
  );
}
