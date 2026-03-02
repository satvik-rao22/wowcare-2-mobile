import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../domain/features/attendance/entities/staff_attendance_absent.dart';
import '../../../../domain/features/attendance/usecases/get_staff_attendance_absent_usecase.dart';

part 'staff_attendance_absent_state.dart';

class StaffAttendanceAbsentCubit extends Cubit<StaffAttendanceAbsentState> {
  StaffAttendanceAbsentCubit({
    required GetStaffAttendanceAbsentUseCase getStaffAttendanceAbsentUseCase,
  })  : _getStaffAttendanceAbsentUseCase = getStaffAttendanceAbsentUseCase,
        super(const StaffAttendanceAbsentState.initial());

  final GetStaffAttendanceAbsentUseCase _getStaffAttendanceAbsentUseCase;

  static const int _pageSize = 10;

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
    if (state.isRefreshing) return;

    final fromStr = _formatDate(fromDate);
    final toStr = _formatDate(toDate);

    emit(state.copyWith(
      isLoading: state.items.isEmpty,
      isRefreshing: true,
      errorMessage: null,
      fromDate: fromDate,
      toDate: toDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
    ));

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

      emit(StaffAttendanceAbsentState.loaded(
        items: firstPage.items,
        currentPage: firstPage.page,
        hasMore: firstPage.hasMore,
        fromDate: fromDate,
        toDate: toDate,
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

