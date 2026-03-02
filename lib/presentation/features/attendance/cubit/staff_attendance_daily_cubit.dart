import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../domain/features/attendance/entities/staff_attendance_daily.dart';
import '../../../../domain/features/attendance/usecases/get_staff_attendance_daily_usecase.dart';

part 'staff_attendance_daily_state.dart';

class StaffAttendanceDailyCubit extends Cubit<StaffAttendanceDailyState> {
  StaffAttendanceDailyCubit({
    required GetStaffAttendanceDailyUseCase getStaffAttendanceDailyUseCase,
  })  : _getStaffAttendanceDailyUseCase = getStaffAttendanceDailyUseCase,
        super(const StaffAttendanceDailyState.initial());

  final GetStaffAttendanceDailyUseCase _getStaffAttendanceDailyUseCase;

  static const int _pageSize = 10;

  Future<void> loadInitial({
    required DateTime attendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  }) async {
    await refresh(
      attendanceDate: attendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
    );
  }

  Future<void> refresh({
    required DateTime attendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  }) async {
    if (state.isRefreshing) return;

    final dateString = _formatDate(attendanceDate);

    emit(state.copyWith(
      isLoading: state.items.isEmpty,
      isRefreshing: true,
      errorMessage: null,
      attendanceDate: attendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
    ));

    try {
      final firstPage = await _getStaffAttendanceDailyUseCase(
        fromAttendanceDate: dateString,
        toAttendanceDate: dateString,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        search: search,
        page: 0,
        size: _pageSize,
      );

      if (isClosed) return;

      emit(StaffAttendanceDailyState.loaded(
        items: firstPage.items,
        currentPage: firstPage.page,
        hasMore: firstPage.hasMore,
        isFromCache: false,
        attendanceDate: attendanceDate,
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
    if (state.attendanceDate == null) return;

    emit(state.copyWith(isLoadingMore: true, errorMessage: null));

    try {
      final nextPageIndex = state.currentPage + 1;
      final dateString = _formatDate(state.attendanceDate!);

      final page = await _getStaffAttendanceDailyUseCase(
        fromAttendanceDate: dateString,
        toAttendanceDate: dateString,
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

