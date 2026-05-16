import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/util/api_error_handler.dart';

import '../../../../domain/features/attendance/entities/staff_attendance_daily.dart';
import '../../../../domain/features/attendance/usecases/get_staff_attendance_custom_usecase.dart';

part 'staff_attendance_custom_state.dart';

class StaffAttendanceCustomCubit extends Cubit<StaffAttendanceCustomState> {
  StaffAttendanceCustomCubit({
    required GetStaffAttendanceCustomUseCase getStaffAttendanceCustomUseCase,
  }) : _getStaffAttendanceCustomUseCase = getStaffAttendanceCustomUseCase,
       super(const StaffAttendanceCustomState.initial());

  final GetStaffAttendanceCustomUseCase _getStaffAttendanceCustomUseCase;

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

    final fromDateString = _formatDate(fromDate);
    final toDateString = _formatDate(toDate);

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
      final firstPage = await _getStaffAttendanceCustomUseCase(
        fromAttendanceDate: fromDateString,
        toAttendanceDate: toDateString,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        search: search,
        page: 0,
        size: _pageSize,
      );

      if (isClosed) return;

      emit(
        StaffAttendanceCustomState.loaded(
          items: firstPage.items,
          currentPage: firstPage.page,
          hasMore: firstPage.hasMore,
          isFromCache: false,
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
      final fromDateString = _formatDate(state.fromDate!);
      final toDateString = _formatDate(state.toDate!);

      final page = await _getStaffAttendanceCustomUseCase(
        fromAttendanceDate: fromDateString,
        toAttendanceDate: toDateString,
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
