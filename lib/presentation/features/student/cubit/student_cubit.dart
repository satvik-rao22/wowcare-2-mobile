import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/student/entities/student.dart';
import '../../../../domain/features/student/usecases/get_student_page_usecase.dart';
import '../../../../domain/features/student/repositories/student_repository.dart';

part 'student_state.dart';

class StudentCubit extends Cubit<StudentState> {
  StudentCubit({
    required GetStudentPageUseCase getStudentPageUseCase,
    required StudentRepository repository,
    required StorageService storageService,
  })  : _getStudentPageUseCase = getStudentPageUseCase,
        _repository = repository,
        _storageService = storageService,
        super(const StudentState.initial());

  final GetStudentPageUseCase _getStudentPageUseCase;
  final StudentRepository _repository;
  final StorageService _storageService;
  String? _schoolCode;

  // How many student records to load per page from the API
  static const int _pageSize = 15;

  Future<String> _resolveSchoolCode() async {
    if (_schoolCode != null) return _schoolCode!;
    // Take school from login-context API (saved in storage) only.
    _schoolCode = await _storageService.getString(StorageKeys.schoolCode) ?? '';
    return _schoolCode!;
  }

  Future<void> loadInitial() async {
    final schoolCode = await _resolveSchoolCode();

    // Try cache first
    final cached =
        await (_repository is StudentRepositoryWithCache
            ? (_repository as StudentRepositoryWithCache).loadCachedStudentPage(
                schoolCode,
                status: state.statusFilter,
                search: state.searchQuery,
                code: state.codeFilter,
                firstName: state.firstNameFilter,
                lastName: state.lastNameFilter,
              )
            : Future.value(null));
    if (cached != null && !isClosed) {
      emit(
        state.copyWith(
          items: cached.items,
          currentPage: cached.page,
          hasMore: cached.hasMore,
          isLoading: false,
          isRefreshing: false,
          isFromCache: true,
        ),
      );
      return;
    }

    // No cache (or expired) – load from API.
    await refresh();
  }

  Future<void> refresh() async {
    if (state.isRefreshing) return;

    final schoolCode = await _resolveSchoolCode();

    emit(
      state.copyWith(
        isLoading: state.items.isEmpty,
        isRefreshing: true,
        errorMessage: null,
      ),
    );

    try {
      final firstPageFuture = _getStudentPageUseCase(
        schoolCode: schoolCode,
        page: 0,
        size: _pageSize,
        status: state.statusFilter,
        search: state.searchQuery,
        firstName: state.firstNameFilter,
        lastName: state.lastNameFilter,
        code: state.codeFilter,
      );

      if (isClosed) return;

      final firstPage = await firstPageFuture;

      var items = List<Student>.from(firstPage.items);
      var currentPage = firstPage.page;
      var hasMore = firstPage.hasMore;

      // Auto-load next page so that page 0 and 1 are both visible initially
      if (hasMore) {
        final secondPage = await _getStudentPageUseCase(
          schoolCode: schoolCode,
          page: 1,
          size: _pageSize,
          status: state.statusFilter,
          search: state.searchQuery,
          firstName: state.firstNameFilter,
          lastName: state.lastNameFilter,
          code: state.codeFilter,
        );

        if (isClosed) return;

        items.addAll(secondPage.items);
        currentPage = secondPage.page;
        hasMore = secondPage.hasMore;
      }

      if (isClosed) return;

      emit(
        state.copyWith(
          items: items,
          currentPage: currentPage,
          hasMore: hasMore,
          isLoading: false,
          isRefreshing: false,
          isFromCache: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore) return;

    final schoolCode = await _resolveSchoolCode();

    emit(state.copyWith(isLoadingMore: true, errorMessage: null));

    try {
      final nextPageIndex = state.currentPage + 1;
      final page = await _getStudentPageUseCase(
        schoolCode: schoolCode,
        page: nextPageIndex,
        size: _pageSize,
        status: state.statusFilter,
        search: state.searchQuery,
        firstName: state.firstNameFilter,
        lastName: state.lastNameFilter,
        code: state.codeFilter,
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
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void updateSearch(String query) {
    emit(
      state.copyWith(
        searchQuery: query,
      ),
    );
  }

  void updateFilters({
    String? status,
    String? code,
    String? firstName,
    String? lastName,
  }) {
    emit(
      state.copyWith(
        statusFilter: status,
        codeFilter: code,
        firstNameFilter: firstName,
        lastNameFilter: lastName,
      ),
    );
  }

  /// Deactivates a student and refreshes the list. Returns backend message.
  Future<String> deactivateStudent(String code) async {
    final schoolCode = await _resolveSchoolCode();
    final message = await _repository.deactivateStudent(
      code: code,
      schoolCode: schoolCode,
    );
    await refresh();
    return message;
  }

  /// Reactivates a student and refreshes the list. Returns backend message.
  Future<String> reactivateStudent(String code) async {
    final schoolCode = await _resolveSchoolCode();
    final message = await _repository.reactivateStudent(
      code: code,
      schoolCode: schoolCode,
    );
    await refresh();
    return message;
  }

  // To be called by add/edit/delete flows to keep cache + UI in sync
  void upsertStudent(Student student) {
    final updated = List<Student>.from(state.items);
    final index = updated.indexWhere((e) => e.code == student.code);
    if (index >= 0) {
      updated[index] = student;
    } else {
      updated.insert(0, student);
    }
    emit(state.copyWith(items: updated));
  }

  void removeStudent(String code) {
    final updated =
        state.items.where((element) => element.code != code).toList();
    emit(state.copyWith(items: updated));
  }
}

