import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_classroom_by_code_usecase.dart';

import '../../../../domain/features/attendance/entities/staff_attendance_absent.dart';
import '../../../../domain/features/attendance/usecases/get_staff_attendance_absent_usecase.dart';

part 'staff_attendance_absent_state.dart';

class StaffAttendanceAbsentCubit extends Cubit<StaffAttendanceAbsentState> {
  StaffAttendanceAbsentCubit({
    required GetStaffAttendanceAbsentUseCase getStaffAttendanceAbsentUseCase,
    required GetClassroomByCodeUseCase getClassroomByCodeUseCase,
  }) : _getStaffAttendanceAbsentUseCase = getStaffAttendanceAbsentUseCase,
       _getClassroomByCodeUseCase = getClassroomByCodeUseCase,
       super(const StaffAttendanceAbsentState.initial());

  final GetStaffAttendanceAbsentUseCase _getStaffAttendanceAbsentUseCase;
  final GetClassroomByCodeUseCase _getClassroomByCodeUseCase;

  static const int _pageSize = 10;

  /// Resolves a classroom's display name from its code — used by the View's
  /// own on-demand name cache when a row's classroom name isn't already
  /// known. Returns null (rather than throwing) on failure, matching the
  /// View's previous "keep code when lookup fails" behavior.
  Future<String?> fetchClassroomName(String code) async {
    try {
      final details = await _getClassroomByCodeUseCase(code: code);
      final name = details.name.trim();
      return name.isNotEmpty ? name : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> loadInitial({
    required DateTime fromDate,
    required DateTime toDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  }) async {
    await refresh(
      fromDate: fromDate,
      toDate: toDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
    );
  }

  Future<void> refresh({
    required DateTime fromDate,
    required DateTime toDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  }) async {
    final filtersChanged =
        !listEquals(classroomCodes, state.classroomCodes) ||
        !listEquals(tagCodes, state.tagCodes) ||
        search != state.search ||
        state.fromDate != fromDate ||
        state.toDate != toDate;
    if (state.isRefreshing && !filtersChanged) return;

    final fromStr = _formatDate(fromDate);
    final toStr = _formatDate(toDate);

    emit(
      state.copyWith(
        isLoading: state.items.isEmpty,
        isRefreshing: true,
        errorMessage: null,
        fromDate: fromDate,
        toDate: toDate,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        search: search,
      ),
    );

    try {
      final firstPage = await _getStaffAttendanceAbsentUseCase(
        fromAbsenceDate: fromStr,
        toAbsenceDate: toStr,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        search: search,
        page: 0,
        size: _pageSize,
      );

      if (isClosed) return;

      emit(
        StaffAttendanceAbsentState.loaded(
          items: firstPage.items,
          currentPage: firstPage.page,
          hasMore: firstPage.hasMore,
          fromDate: fromDate,
          toDate: toDate,
          classroomCodes: classroomCodes,
          tagCodes: tagCodes,
          search: search,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    if (state.currentPage < 0) return;
    if (state.fromDate == null || state.toDate == null) return;

    emit(state.copyWith(isLoadingMore: true, errorMessage: null));

    try {
      final nextPageIndex = state.currentPage + 1;
      final fromStr = _formatDate(state.fromDate!);
      final toStr = _formatDate(state.toDate!);

      final page = await _getStaffAttendanceAbsentUseCase(
        fromAbsenceDate: fromStr,
        toAbsenceDate: toStr,
        classroomCodes: state.classroomCodes,
        tagCodes: state.tagCodes,
        search: state.search,
        page: nextPageIndex,
        size: _pageSize,
      );

      if (isClosed) return;

      emit(
        state.copyWith(
          items: [...state.items, ...page.items],
          currentPage: page.page,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoadingMore: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
