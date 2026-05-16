import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/util/api_error_handler.dart';

import '../../../../domain/features/attendance/entities/student_attendance_custom.dart';
import '../../../../domain/features/attendance/repositories/attendance_repository.dart';
import '../../../../domain/features/attendance/usecases/get_student_attendance_custom_usecase.dart';

part 'student_attendance_custom_state.dart';

class StudentAttendanceCustomCubit extends Cubit<StudentAttendanceCustomState> {
  StudentAttendanceCustomCubit({
    required GetStudentAttendanceCustomUseCase
    getStudentAttendanceCustomUseCase,
    required AttendanceRepository repository,
  }) : _getStudentAttendanceCustomUseCase = getStudentAttendanceCustomUseCase,
       _repository = repository,
       super(const StudentAttendanceCustomState.initial());

  final GetStudentAttendanceCustomUseCase _getStudentAttendanceCustomUseCase;
  final AttendanceRepository _repository;

  static const int _pageSize = 10;

  Future<void> loadInitial({
    required DateTime fromDate,
    required DateTime toDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  }) async {
    final fromDateString = _formatDate(fromDate);
    final toDateString = _formatDate(toDate);

    final cached = await (_repository is AttendanceRepositoryWithCache
        ? (_repository as AttendanceRepositoryWithCache)
              .loadCachedStudentAttendanceCustom(
                fromDateString,
                toDateString,
                classroomCodes: classroomCodes,
                tagCodes: tagCodes,
                search: search,
              )
        : Future.value(null));

    if (cached != null && !isClosed) {
      emit(
        StudentAttendanceCustomState.loaded(
          items: cached.items,
          currentPage: 0,
          hasMore: cached.hasMore,
          isFromCache: true,
          fromDate: fromDate,
          toDate: toDate,
          classroomCodes: classroomCodes,
          tagCodes: tagCodes,
          search: search,
        ),
      );
      return;
    }

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
      final firstPage = await _getStudentAttendanceCustomUseCase(
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
        StudentAttendanceCustomState.loaded(
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

      final page = await _getStudentAttendanceCustomUseCase(
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
