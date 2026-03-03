import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../domain/features/attendance/entities/staff_attendance_absent.dart';
import '../../../../domain/features/attendance/usecases/get_staff_attendance_absent_toggle_view_usecase.dart';

part 'staff_attendance_absent_toggle_state.dart';

class StaffAttendanceAbsentToggleCubit
    extends Cubit<StaffAttendanceAbsentToggleState> {
  StaffAttendanceAbsentToggleCubit({
    required GetStaffAttendanceAbsentToggleViewUseCase
        getStaffAttendanceAbsentToggleViewUseCase,
  })  : _getStaffAttendanceAbsentToggleViewUseCase =
            getStaffAttendanceAbsentToggleViewUseCase,
        super(const StaffAttendanceAbsentToggleState.initial());

  final GetStaffAttendanceAbsentToggleViewUseCase
      _getStaffAttendanceAbsentToggleViewUseCase;

  static const int _pageSize = 10;

  Future<void> loadInitial({
    required DateTime absenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  }) async {
    await refresh(
      absenceDate: absenceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
    );
  }

  Future<void> refresh({
    required DateTime absenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  }) async {
    if (state.isRefreshing) return;

    emit(state.copyWith(
      isLoading: state.items.isEmpty,
      isRefreshing: true,
      errorMessage: null,
      absenceDate: absenceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      currentPage: 0,
      hasMore: false,
    ));

    try {
      final dateString = _formatDate(absenceDate);
      final firstPage = await _getStaffAttendanceAbsentToggleViewUseCase(
        fromAbsenceDate: dateString,
        toAbsenceDate: dateString,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        search: search,
        page: 0,
        size: _pageSize,
      );

      if (isClosed) return;

      emit(StaffAttendanceAbsentToggleState.loaded(
        items: firstPage.items,
        currentPage: firstPage.page,
        hasMore: firstPage.hasMore,
        absenceDate: absenceDate,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        search: search,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    if (state.currentPage < 0) return;
    if (state.absenceDate == null) return;

    emit(state.copyWith(isLoadingMore: true, errorMessage: null));

    try {
      final nextPageIndex = state.currentPage + 1;
      final dateString = _formatDate(state.absenceDate!);

      final page = await _getStaffAttendanceAbsentToggleViewUseCase(
        fromAbsenceDate: dateString,
        toAbsenceDate: dateString,
        classroomCodes: state.classroomCodes,
        tagCodes: state.tagCodes,
        search: state.search,
        page: nextPageIndex,
        size: _pageSize,
      );

      if (isClosed) return;

      emit(state.copyWith(
        items: [...state.items, ...page.items],
        currentPage: page.page,
        hasMore: page.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      ));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

