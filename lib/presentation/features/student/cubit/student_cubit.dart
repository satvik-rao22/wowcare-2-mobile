import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/util/api_error_handler.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/attendance_classroom_scope.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/student/entities/student.dart';
import '../../../../domain/features/student/usecases/get_student_page_usecase.dart';
import '../../../../domain/features/student/repositories/student_repository.dart';

part 'student_state.dart';

/// List/pagination and mutations for the student roster.
///
/// Permission-aware screens should use [RoleCubit] with
/// `package:wowcare/presentation/features/student/module_access.dart` ([ModuleAccess])
/// so guardians, staff, and admins respect the same API module rows.
class StudentCubit extends Cubit<StudentState> {
  StudentCubit({
    required GetStudentPageUseCase getStudentPageUseCase,
    required StudentRepository repository,
    required StorageService storageService,
  }) : _getStudentPageUseCase = getStudentPageUseCase,
       _repository = repository,
       _storageService = storageService,
       super(const StudentState.initial());

  final GetStudentPageUseCase _getStudentPageUseCase;
  final StudentRepository _repository;
  final StorageService _storageService;
  String? _schoolCode;
  bool? _isScopedStaffPersona;
  List<String>? _allowedClassroomCodes;

  // How many student records to load per page from the API
  static const int _pageSize = 15;

  Future<String> _resolveSchoolCode() async {
    if (_schoolCode != null) return _schoolCode!;
    // Take school from login-context API (saved in storage) only.
    _schoolCode = await _storageService.getString(StorageKeys.schoolCode) ?? '';

    // If schoolCode is still empty, surface a clear error instead of using any
    // hard-coded fallback. Caller should ensure org/school selection is done.
    if (_schoolCode!.trim().isEmpty) {
      throw StateError(
        'School code is not set. Make sure login and school selection are completed.',
      );
    }

    return _schoolCode!;
  }

  Future<void> _ensureClassroomScopeResolved() async {
    if (_isScopedStaffPersona != null && _allowedClassroomCodes != null) return;
    final scoped = await isAttendanceScopedStaffPersona(
      storage: _storageService,
    );
    final allowed = await resolveAttendanceAllowedClassroomCodes(
      storage: _storageService,
    );
    _isScopedStaffPersona = scoped;
    _allowedClassroomCodes = allowed
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  List<String>? _effectiveClassroomCodesForRequest() {
    final scoped = _isScopedStaffPersona == true;
    final allowed = _allowedClassroomCodes ?? const <String>[];
    final selected =
        state.classroomCodesFilter
            ?.map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList() ??
        const <String>[];

    if (!scoped) {
      return selected.isEmpty ? null : selected;
    }

    final allowedSet = allowed.toSet();
    if (selected.isEmpty) {
      return List<String>.from(allowedSet);
    }

    return selected
        .where((c) => allowedSet.contains(c))
        .toList(growable: false);
  }

  /// Hard security scope for a restricted staff/teacher persona, sent as its
  /// own `allowedClassroomCodes` request param (distinct from the
  /// user-chosen `classroomCodes` filter above) so the backend enforces it
  /// regardless of what's selected — e.g. messaging's "start new chat"
  /// student search, which lets a staff persona search freely and must not
  /// surface students from classrooms they aren't assigned to.
  List<String>? _effectiveAllowedClassroomCodesForRequest() {
    if (_isScopedStaffPersona != true) return null;
    return _allowedClassroomCodes;
  }

  Future<void> loadInitial() async {
    final schoolCode = await _resolveSchoolCode();
    await _ensureClassroomScopeResolved();
    final effectiveClassroomCodes = _effectiveClassroomCodesForRequest();

    if (_isScopedStaffPersona == true &&
        (effectiveClassroomCodes == null || effectiveClassroomCodes.isEmpty)) {
      if (isClosed) return;
      emit(
        state.copyWith(
          items: const <Student>[],
          currentPage: 0,
          hasMore: false,
          isLoading: false,
          isRefreshing: false,
          isFromCache: false,
          errorMessage: null,
        ),
      );
      return;
    }

    // 1. Try cache first for immediate UI update
    final cached = await (_repository is StudentRepositoryWithCache
        ? (_repository as StudentRepositoryWithCache).loadCachedStudentPage(
            schoolCode,
            status: state.statusFilter,
            classroomCodes: effectiveClassroomCodes,
            tagCodes: state.tagCodesFilter,
            guardianCodes: state.guardianCodesFilter,
            attendanceStatuses: state.attendanceStatusesFilter,
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
      // We don't return here anymore; we trigger a background refresh
    }

    // 2. Load from API (background refresh if cache was present, or full load if not)
    await refresh();
  }

  Future<void> refresh({bool ignoreRefreshingGuard = false}) async {
    if (state.isRefreshing && !ignoreRefreshingGuard) return;

    final schoolCode = await _resolveSchoolCode();
    await _ensureClassroomScopeResolved();
    final effectiveClassroomCodes = _effectiveClassroomCodesForRequest();

    if (_isScopedStaffPersona == true &&
        (effectiveClassroomCodes == null || effectiveClassroomCodes.isEmpty)) {
      if (isClosed) return;
      emit(
        state.copyWith(
          items: const <Student>[],
          currentPage: 0,
          hasMore: false,
          isLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          isFromCache: false,
          errorMessage: null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isLoading: state.items.isEmpty,
        isRefreshing: true,
        errorMessage: null,
      ),
    );

    // Snapshot the status this load is fetching. If the filter changes while
    // we're in flight (e.g. a deep-link resolves a deactivated student and flips
    // to Inactive while the route's default Active load is still running), the
    // older result must NOT clobber the newer one — drop it before emitting.
    final requestedStatus = state.statusFilter;

    try {
      final firstPageFuture = _getStudentPageUseCase(
        schoolCode: schoolCode,
        page: 0,
        size: _pageSize,
        status: requestedStatus,
        classroomCodes: effectiveClassroomCodes,
        tagCodes: state.tagCodesFilter,
        guardianCodes: state.guardianCodesFilter,
        attendanceStatuses: state.attendanceStatusesFilter,
        search: state.searchQuery,
        firstName: state.firstNameFilter,
        lastName: state.lastNameFilter,
        code: state.codeFilter,
        allowedClassroomCodes: _effectiveAllowedClassroomCodesForRequest(),
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
          status: requestedStatus,
          classroomCodes: effectiveClassroomCodes,
          tagCodes: state.tagCodesFilter,
          guardianCodes: state.guardianCodesFilter,
          attendanceStatuses: state.attendanceStatusesFilter,
          search: state.searchQuery,
          firstName: state.firstNameFilter,
          lastName: state.lastNameFilter,
          code: state.codeFilter,
          allowedClassroomCodes: _effectiveAllowedClassroomCodesForRequest(),
        );

        if (isClosed) return;

        items.addAll(secondPage.items);
        currentPage = secondPage.page;
        hasMore = secondPage.hasMore;
      }

      if (isClosed) return;
      // Drop a stale result: the filter changed while this load was in flight,
      // so a newer refresh owns the list now.
      if (state.statusFilter != requestedStatus) return;

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
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  /// Invalidates the cached first-page for the *current* list query and refreshes from API.
  ///
  /// Use this after mutations (add/edit) and when filters change to ensure we don't
  /// re-hydrate stale cached results.
  Future<void> refreshWithCacheReset() async {
    final schoolCode = await _resolveSchoolCode();
    await _ensureClassroomScopeResolved();
    final effectiveClassroomCodes = _effectiveClassroomCodesForRequest();
    if (_repository is StudentRepositoryWithCache) {
      await (_repository as StudentRepositoryWithCache)
          .invalidateCachedStudentPage(
            schoolCode,
            status: state.statusFilter,
            classroomCodes: effectiveClassroomCodes,
            tagCodes: state.tagCodesFilter,
            guardianCodes: state.guardianCodesFilter,
            attendanceStatuses: state.attendanceStatusesFilter,
            search: state.searchQuery,
            code: state.codeFilter,
            firstName: state.firstNameFilter,
            lastName: state.lastNameFilter,
          );
    }
    // Force reload even if another refresh was triggered very recently.
    await refresh(ignoreRefreshingGuard: true);
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore) return;

    final schoolCode = await _resolveSchoolCode();
    await _ensureClassroomScopeResolved();
    final effectiveClassroomCodes = _effectiveClassroomCodesForRequest();

    if (_isScopedStaffPersona == true &&
        (effectiveClassroomCodes == null || effectiveClassroomCodes.isEmpty)) {
      if (isClosed) return;
      emit(
        state.copyWith(
          items: const <Student>[],
          currentPage: 0,
          hasMore: false,
          isLoadingMore: false,
          errorMessage: null,
        ),
      );
      return;
    }

    emit(state.copyWith(isLoadingMore: true, errorMessage: null));

    try {
      final nextPageIndex = state.currentPage + 1;
      final page = await _getStudentPageUseCase(
        schoolCode: schoolCode,
        page: nextPageIndex,
        size: _pageSize,
        status: state.statusFilter,
        classroomCodes: effectiveClassroomCodes,
        tagCodes: state.tagCodesFilter,
        guardianCodes: state.guardianCodesFilter,
        attendanceStatuses: state.attendanceStatusesFilter,
        search: state.searchQuery,
        firstName: state.firstNameFilter,
        lastName: state.lastNameFilter,
        code: state.codeFilter,
        allowedClassroomCodes: _effectiveAllowedClassroomCodesForRequest(),
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
      emit(state.copyWith(isLoadingMore: false, errorMessage: ApiErrorHandler.extractErrorMessage(e)));
    }
  }

  void updateSearch(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void updateFilters({
    String? status,
    String? code,
    String? firstName,
    String? lastName,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    List<String>? attendanceStatuses,
  }) {
    emit(
      state.copyWith(
        statusFilter: status,
        codeFilter: code,
        firstNameFilter: firstName,
        lastNameFilter: lastName,
        classroomCodesFilter: classroomCodes,
        tagCodesFilter: tagCodes,
        guardianCodesFilter: guardianCodes,
        attendanceStatusesFilter: attendanceStatuses,
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
    await refreshWithCacheReset();
    return message;
  }

  /// Reactivates a student and refreshes the list. Returns backend message.
  Future<String> reactivateStudent(String code) async {
    final schoolCode = await _resolveSchoolCode();
    final message = await _repository.reactivateStudent(
      code: code,
      schoolCode: schoolCode,
    );
    await refreshWithCacheReset();
    return message;
  }

  Future<String> deleteStudent(String code) async {
    final schoolCode = await _resolveSchoolCode();
    final message = await _repository.deleteStudent(
      code: code,
      schoolCode: schoolCode,
    );
    await refreshWithCacheReset();
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
    final updated = state.items
        .where((element) => element.code != code)
        .toList();
    emit(state.copyWith(items: updated));
  }
}
