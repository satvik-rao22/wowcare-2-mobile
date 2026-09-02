import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/attendance_cross_class_resolver.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_classroom_by_code_usecase.dart';

import '../../../../domain/features/attendance/entities/student_attendance_custom.dart';
import '../../../../domain/features/attendance/repositories/attendance_repository.dart';
import '../../../../domain/features/attendance/usecases/get_student_attendance_custom_usecase.dart';

part 'student_attendance_custom_state.dart';

class StudentAttendanceCustomCubit extends Cubit<StudentAttendanceCustomState> {
  StudentAttendanceCustomCubit({
    required GetStudentAttendanceCustomUseCase
    getStudentAttendanceCustomUseCase,
    required AttendanceRepository repository,
    required GetClassroomByCodeUseCase getClassroomByCodeUseCase,
    required StorageService storageService,
  }) : _getStudentAttendanceCustomUseCase = getStudentAttendanceCustomUseCase,
       _repository = repository,
       _getClassroomByCodeUseCase = getClassroomByCodeUseCase,
       _storage = storageService,
       super(const StudentAttendanceCustomState.initial());

  final GetStudentAttendanceCustomUseCase _getStudentAttendanceCustomUseCase;
  final AttendanceRepository _repository;
  final GetClassroomByCodeUseCase _getClassroomByCodeUseCase;
  final StorageService _storage;

  /// Resolves the school's teacher cross-class flag; when enabled, teachers
  /// see every classroom in the filter (like an admin) instead of just
  /// their own.
  Future<bool> resolveCrossClassEnabled() {
    return AttendanceCrossClassResolver.isEnabledForCurrentSchool(
      storage: _storage,
    );
  }

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

    final hasActiveFilters =
        (classroomCodes != null && classroomCodes.isNotEmpty) ||
        (tagCodes != null && tagCodes.isNotEmpty) ||
        (search != null && search.trim().isNotEmpty);

    if (cached != null && !isClosed && !hasActiveFilters) {
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
    final filtersChanged =
        !listEquals(classroomCodes, state.classroomCodes) ||
        !listEquals(tagCodes, state.tagCodes) ||
        search != state.search ||
        state.fromDate != fromDate ||
        state.toDate != toDate;
    if (state.isRefreshing && !filtersChanged) return;

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
