import 'dart:async';

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
/// `package:wowcare/presentation/features/students/module_access.dart` ([ModuleAccess])
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

  /// Monotonic query generation. Bumped whenever the logical query changes
  /// (a new refresh, a search/filter change, or a detected school switch) so a
  /// slower in-flight response for an older query/school is discarded instead
  /// of clobbering the current one.
  int _generation = 0;

  /// Debounce for search-as-you-type. Public so a test can shorten it.
  Duration searchDebounceDelay = const Duration(milliseconds: 300);
  Timer? _searchDebounce;

  // How many student records to load per page from the API
  static const int _pageSize = 15;

  /// Search-as-you-type entry point: updates the query immediately (so the field
  /// and the generation guard reflect the newest keystroke, superseding any
  /// in-flight request) but DEBOUNCES the network refresh so rapid typing fires
  /// a single settled request instead of one full load per keystroke.
  void onSearchChanged(String query) {
    updateSearch(query);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(searchDebounceDelay, () {
      refresh(ignoreRefreshingGuard: true);
    });
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  /// Appends [incoming] onto [existing], skipping any student whose code is
  /// already present (stable-identity dedup), so overlapping backend pages can't
  /// show the same student twice. Original order is preserved.
  static List<Student> _appendDedupedByCode(
    List<Student> existing,
    List<Student> incoming,
  ) {
    final seen = existing.map((s) => s.code).toSet();
    final result = List<Student>.from(existing);
    for (final s in incoming) {
      if (seen.add(s.code)) result.add(s);
    }
    return result;
  }

  Future<String> _resolveSchoolCode() async {
    // Always read the live school from storage (never a stale memoized value):
    // the cubit can outlive an in-place school switch (e.g. an FCM-driven
    // switch on a still-mounted screen). Fail closed on an empty value rather
    // than using any hard-coded fallback.
    final fresh =
        (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();
    if (fresh.isEmpty) {
      throw StateError(
        'School code is not set. Make sure login and school selection are completed.',
      );
    }
    if (_schoolCode != null && _schoolCode != fresh) {
      // School switched under a live cubit: drop the memoized persona scope so
      // it re-resolves for the new school, and supersede any in-flight response.
      _isScopedStaffPersona = null;
      _allowedClassroomCodes = null;
      _generation++;
    }
    _schoolCode = fresh;
    return fresh;
  }

  /// True when a response captured at [gen] under [schoolAtStart] is no longer
  /// the active one — the cubit closed, a newer query superseded it, or the
  /// active school changed while it was in flight. Callers must return without
  /// emitting when this is true.
  Future<bool> _isStaleResponse(int gen, String schoolAtStart) async {
    if (isClosed || gen != _generation) return true;
    final current =
        (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();
    return current != schoolAtStart;
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

    // Snapshot the status and search query this load is fetching. If either
    // changes while we're in flight (e.g. a deep-link resolves a deactivated
    // student and flips to Inactive while the route's default Active load is
    // still running — or rapid-fire search-as-you-type callers like
    // staff_messaging_tab.dart/admin_chat_host_screen.dart fire a fresh
    // refresh() on every keystroke with `ignoreRefreshingGuard: true`,
    // letting requests race), an older, slower response must NOT clobber a
    // newer one just because it happened to land last — drop it instead.
    final requestedStatus = state.statusFilter;
    final requestedSearch = state.searchQuery;
    // This refresh owns a fresh generation; capture the school it runs under so
    // a later school switch (or newer query) discards this response.
    final gen = ++_generation;
    final schoolAtStart = schoolCode;

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

        items = _appendDedupedByCode(items, secondPage.items);
        currentPage = secondPage.page;
        hasMore = secondPage.hasMore;
      }

      // Drop a stale result: a newer query/refresh or a school switch happened
      // while this load was in flight, so this response no longer owns the list.
      // (The legacy status/search checks are subsumed by the generation guard,
      // which also covers every other filter and the active school.)
      if (await _isStaleResponse(gen, schoolAtStart)) return;
      if (state.statusFilter != requestedStatus) return;
      if (state.searchQuery != requestedSearch) return;

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
      if (await _isStaleResponse(gen, schoolAtStart)) return;
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

    // load-more continues the CURRENT query — capture its generation (do not
    // bump) and school so a refresh/filter/school change mid-flight discards
    // this page instead of appending it into a now-different list.
    final gen = _generation;
    final schoolAtStart = schoolCode;

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

      if (await _isStaleResponse(gen, schoolAtStart)) return;

      emit(
        state.copyWith(
          items: _appendDedupedByCode(state.items, page.items),
          currentPage: page.page,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      if (await _isStaleResponse(gen, schoolAtStart)) return;
      emit(
        state.copyWith(
          isLoadingMore: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  void updateSearch(String query) {
    // A new search is a new logical query: supersede any in-flight response.
    _generation++;
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
    // Filter changes reset the logical query: supersede any in-flight response
    // so an older page/list can't append into or overwrite the new results.
    _generation++;
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

  /// In-flight roster mutations keyed by `action:studentCode`. A second call for
  /// the same action+student while the first is still running (a double-tap)
  /// returns the SAME future instead of issuing a duplicate request — the cubit
  /// enforces single-flight independently of any UI button-disabling.
  final Map<String, Future<String>> _inFlightMutations = {};

  Future<String> _singleFlightMutation(
    String key,
    Future<String> Function() operation,
  ) {
    final existing = _inFlightMutations[key];
    if (existing != null) return existing;
    final future = operation();
    _inFlightMutations[key] = future;
    future.whenComplete(() => _inFlightMutations.remove(key));
    return future;
  }

  /// Deactivates a student and refreshes the list. Returns backend message.
  Future<String> deactivateStudent(String code) {
    return _singleFlightMutation('deactivate:$code', () async {
      final schoolCode = await _resolveSchoolCode();
      final message = await _repository.deactivateStudent(
        code: code,
        schoolCode: schoolCode,
      );
      await refreshWithCacheReset();
      return message;
    });
  }

  /// Reactivates a student and refreshes the list. Returns backend message.
  Future<String> reactivateStudent(String code) {
    return _singleFlightMutation('reactivate:$code', () async {
      final schoolCode = await _resolveSchoolCode();
      final message = await _repository.reactivateStudent(
        code: code,
        schoolCode: schoolCode,
      );
      await refreshWithCacheReset();
      return message;
    });
  }

  Future<String> deleteStudent(String code) {
    return _singleFlightMutation('delete:$code', () async {
      final schoolCode = await _resolveSchoolCode();
      final message = await _repository.deleteStudent(
        code: code,
        schoolCode: schoolCode,
      );
      await refreshWithCacheReset();
      return message;
    });
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
