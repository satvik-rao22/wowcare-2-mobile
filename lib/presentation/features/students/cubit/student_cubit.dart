import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/util/api_error_handler.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/attendance_classroom_scope.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_page_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_counts_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_guardian_name_code_map_for_school_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_attendance_expected_summary_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_today_sign_in_status_map_usecase.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_classroom_by_code_usecase.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';

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
    GetStudentCountsUseCase? countsUseCase,
    GetStudentAttendanceExpectedSummaryUseCase? expectedSummaryUseCase,
    GetTagNameCodeMapForSchoolUseCase? tagNameCodeMapUseCase,
    GetGuardianNameCodeMapForSchoolUseCase? guardianNameCodeMapUseCase,
    GetStudentTodaySignInStatusMapUseCase? attendanceStatusUseCase,
    GetClassroomByCodeUseCase? classroomByCodeUseCase,
  }) : _getStudentPageUseCase = getStudentPageUseCase,
       _repository = repository,
       _storageService = storageService,
       _countsUseCase = countsUseCase,
       _expectedSummaryUseCase = expectedSummaryUseCase,
       _tagNameCodeMapUseCase = tagNameCodeMapUseCase,
       _guardianNameCodeMapUseCase = guardianNameCodeMapUseCase,
       _attendanceStatusUseCase = attendanceStatusUseCase,
       _classroomByCodeUseCase = classroomByCodeUseCase,
       super(const StudentState.initial());

  final GetStudentPageUseCase _getStudentPageUseCase;
  final StudentRepository _repository;
  final StorageService _storageService;

  /// Optional so tests can build the cubit without them (they exercise the
  /// list, not counts); production injects them via DI. If null, the loads no-op.
  final GetStudentCountsUseCase? _countsUseCase;
  final GetStudentAttendanceExpectedSummaryUseCase? _expectedSummaryUseCase;
  final GetTagNameCodeMapForSchoolUseCase? _tagNameCodeMapUseCase;
  final GetGuardianNameCodeMapForSchoolUseCase? _guardianNameCodeMapUseCase;
  final GetStudentTodaySignInStatusMapUseCase? _attendanceStatusUseCase;
  final GetClassroomByCodeUseCase? _classroomByCodeUseCase;

  /// Fetch-dedup bookkeeping for [ensureClassroomDetailNames] — not part of the
  /// emitted state (like [_inFlightMutations]): a per-code in-flight guard and
  /// the last student-roster fingerprint so an unchanged roster doesn't refetch.
  final Set<String> _classroomDetailFetchInFlight = <String>{};
  String _lastClassroomPrefetchFingerprint = '';
  String? _schoolCode;
  bool? _isScopedStaffPersona;
  List<String>? _allowedClassroomCodes;

  /// Monotonic query generation. Bumped whenever the logical query changes
  /// (a new refresh, a search/filter change, or a detected school switch) so a
  /// slower in-flight response for an older query/school is discarded instead
  /// of clobbering the current one.
  int _generation = 0;

  /// Set by [_resolveSchoolCode] when it detects the active school changed under
  /// a live cubit (e.g. an FCM-driven in-place switch). The next roster load
  /// reads and clears it so School A's rows are dropped from the screen
  /// immediately — a full loader for School B — instead of lingering as a
  /// background refresh over the previous school's data.
  bool _pendingSchoolSwitch = false;

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
      _pendingSchoolSwitch = true;
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
          status: StudentListStatus.loaded,
          isFromCache: false,
          errorMessage: null,
          noAccessibleClassrooms: true,
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
          status: StudentListStatus.loaded,
          isFromCache: true,
          noAccessibleClassrooms: false,
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
          status: StudentListStatus.loaded,
          isFromCache: false,
          errorMessage: null,
          noAccessibleClassrooms: true,
        ),
      );
      return;
    }

    // On an in-place school switch, drop School A's roster + row selection
    // immediately so it can't remain on screen under School B (a full loader
    // for the new school) rather than a background refresh over stale rows.
    final switchedSchool = _pendingSchoolSwitch;
    _pendingSchoolSwitch = false;
    emit(
      state.copyWith(
        items: switchedSchool ? const <Student>[] : state.items,
        selection: switchedSchool ? const <bool>[] : state.selection,
        // Empty list → full-screen loader; otherwise a background refresh over
        // the existing rows. The concurrency guard above keys on `refreshing`.
        status: (switchedSchool || state.items.isEmpty)
            ? StudentListStatus.loading
            : StudentListStatus.refreshing,
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
          status: StudentListStatus.loaded,
          isFromCache: false,
          noAccessibleClassrooms: false,
        ),
      );
    } catch (e) {
      if (await _isStaleResponse(gen, schoolAtStart)) return;
      emit(
        state.copyWith(
          status: StudentListStatus.error,
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
          status: StudentListStatus.loaded,
          errorMessage: null,
          noAccessibleClassrooms: true,
        ),
      );
      return;
    }

    // load-more continues the CURRENT query — capture its generation (do not
    // bump) and school so a refresh/filter/school change mid-flight discards
    // this page instead of appending it into a now-different list.
    final gen = _generation;
    final schoolAtStart = schoolCode;

    emit(
      state.copyWith(
        status: StudentListStatus.loadingMore,
        errorMessage: null,
      ),
    );

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
          status: StudentListStatus.loaded,
          noAccessibleClassrooms: false,
        ),
      );
    } catch (e) {
      if (await _isStaleResponse(gen, schoolAtStart)) return;
      emit(
        state.copyWith(
          status: StudentListStatus.error,
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
    Map<String, List<String>>? selection,
    bool? showInactive,
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
        // The cubit is the single owner of the UI filter SELECTION + the
        // Active/Inactive toggle; the widget no longer keeps its own copy.
        selectedFilters: selection,
        showInactive: showInactive,
      ),
    );
  }

  /// Update just the filter SELECTION + inactive toggle in state, WITHOUT
  /// re-resolving codes or refetching. Used for pre-load/display-only sets so
  /// the cubit stays the single owner of the selection (no widget-held copy).
  void setSelectedFilters(
    Map<String, List<String>> selection, {
    bool? showInactive,
  }) {
    emit(state.copyWith(selectedFilters: selection, showInactive: showInactive));
  }

  // ---- Multi-select (per-row selection). Single owner in state. ----

  /// Reset the per-row selection to match the current [items] (all cleared).
  /// Called when the visible list changes so indices stay aligned.
  void resizeSelection() {
    emit(
      state.copyWith(selection: List<bool>.filled(state.items.length, false)),
    );
  }

  /// Toggle a single row.
  void setRowSelected(int index, bool value) {
    if (index < 0 || index >= state.selection.length) return;
    final next = List<bool>.from(state.selection);
    next[index] = value;
    emit(state.copyWith(selection: next));
  }

  /// Select or clear every visible row.
  void setSelectAll(bool value) {
    emit(
      state.copyWith(selection: List<bool>.filled(state.items.length, value)),
    );
  }

  /// Clear all row selections (length preserved).
  void clearSelection() {
    emit(
      state.copyWith(selection: List<bool>.filled(state.items.length, false)),
    );
  }

  /// Load the Active/Upcoming roster counts (the first summary card). No-op when
  /// the use case wasn't injected (tests). Failures are non-fatal (keep prior).
  Future<void> loadCounts() async {
    final useCase = _countsUseCase;
    if (useCase == null) return;
    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) return;
      final counts = await useCase(schoolCode: schoolCode);
      if (isClosed) return;
      emit(state.copyWith(
        activeCount: counts.activeCount,
        upcomingCount: counts.upcomingCount,
      ));
    } catch (_) {
      // Non-critical; keep the previous counts.
    }
  }

  /// Load the expected-students attendance summary (the second summary card).
  /// No-op without the use case; on error the counters reset to 0 (as before).
  Future<void> loadExpectedSummary() async {
    final useCase = _expectedSummaryUseCase;
    if (useCase == null) return;
    try {
      final summary = await useCase();
      if (isClosed) return;
      emit(state.copyWith(
        expectedTotal: summary.expected,
        expectedSignedIn: summary.present,
        expectedAbsent: summary.absent,
        expectedSignedOut: summary.signOut,
        expectedNotMarked: summary.notMarked,
      ));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(
        expectedTotal: 0,
        expectedSignedIn: 0,
        expectedAbsent: 0,
        expectedSignedOut: 0,
        expectedNotMarked: 0,
      ));
    }
  }

  /// Load the tag name→code lookup for the current school (used to resolve the
  /// tag filter selection into API codes). No-op without the use case (tests);
  /// failures are non-fatal — the filter simply can't resolve tag codes.
  Future<void> loadTagNameCodeMap() async {
    final useCase = _tagNameCodeMapUseCase;
    if (useCase == null) return;
    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) return;
      final map = await useCase(schoolCode: schoolCode);
      if (isClosed) return;
      emit(state.copyWith(tagNameToCode: map));
    } catch (_) {
      // Non-critical for filters; keep the previous map.
    }
  }

  /// Load the guardian name→code lookup for the current school (used to resolve
  /// the guardian filter selection into API codes). No-op without the use case
  /// (tests); failures are non-fatal.
  Future<void> loadGuardianNameCodeMap() async {
    final useCase = _guardianNameCodeMapUseCase;
    if (useCase == null) return;
    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) return;
      final map = await useCase(schoolCode: schoolCode);
      if (isClosed) return;
      emit(state.copyWith(guardianNameToCode: map));
    } catch (_) {
      // Non-critical for filters; keep the previous map.
    }
  }

  /// Refresh today's sign-in status for the CURRENTLY SELECTED rows (drives the
  /// per-row attendance badges + gates the attendance/activities buttons). The
  /// selection is read from state ([selection] × [items]) so the widget doesn't
  /// pass it. No-op without the use case (tests). On no selection the map clears;
  /// on failure it clears and flags [attendanceStatusError].
  Future<void> refreshAttendanceStatusForSelection() async {
    final useCase = _attendanceStatusUseCase;
    if (useCase == null) return;

    final selection = state.selection;
    final items = state.items;
    final codes = <String>[];
    for (var i = 0; i < selection.length; i++) {
      if (selection[i] && i < items.length) {
        final code = items[i].code.trim();
        if (code.isNotEmpty) codes.add(code);
      }
    }

    if (codes.isEmpty) {
      if (isClosed) return;
      emit(state.copyWith(
        attendanceStatusByStudentCode: const {},
        attendanceStatusLoading: false,
        attendanceStatusError: false,
      ));
      return;
    }

    emit(state.copyWith(
      attendanceStatusLoading: true,
      attendanceStatusError: false,
    ));

    try {
      final map = await useCase(studentCodes: codes);
      if (isClosed) return;
      emit(state.copyWith(
        attendanceStatusByStudentCode: Map<String, String>.from(map),
        attendanceStatusLoading: false,
        attendanceStatusError: false,
      ));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(
        attendanceStatusByStudentCode: const {},
        attendanceStatusLoading: false,
        attendanceStatusError: true,
      ));
    }
  }

  /// Resolve classroom NAMES for the current roster that the [ClassroomCubit]
  /// roster ([cubitNameByCode]) didn't already name, via the per-code detail API.
  /// Guarded so an unchanged roster (same fingerprint) doesn't refetch, and each
  /// code is fetched at most once (in-flight + failed sets). No-op without the
  /// use case (tests). Safe to call from build: the sync portion only launches
  /// the async fetches — the first `emit` happens after the first `await`.
  Future<void> ensureClassroomDetailNames(
    List<Student> students,
    Map<String, String> cubitNameByCode,
  ) async {
    final useCase = _classroomByCodeUseCase;
    if (useCase == null) return;

    final parts = students.map((s) => s.classroom.trim()).toList()..sort();
    final fingerprint = parts.join('');
    if (fingerprint == _lastClassroomPrefetchFingerprint) return;
    _lastClassroomPrefetchFingerprint = fingerprint;

    final codes = <String>{};
    for (final s in students) {
      final c = s.classroom.trim();
      if (c.isEmpty) continue;
      if (!c.toUpperCase().startsWith('CLS_')) continue;
      if (state.classroomDetailFetchFailed.contains(c)) continue;
      if (state.classroomNameByDetailApi.containsKey(c)) continue;
      final cubitName = cubitNameByCode[c]?.trim() ?? '';
      if (cubitName.isNotEmpty) continue;
      if (_classroomDetailFetchInFlight.contains(c)) continue;
      codes.add(c);
    }
    if (codes.isEmpty) return;

    for (final code in codes) {
      _classroomDetailFetchInFlight.add(code);
      try {
        final details = await useCase(code: code);
        if (isClosed) return;
        final name = details.name.trim();
        if (name.isNotEmpty) {
          emit(state.copyWith(
            classroomNameByDetailApi: {
              ...state.classroomNameByDetailApi,
              code: name,
            },
          ));
        } else {
          emit(state.copyWith(
            classroomDetailFetchFailed: {
              ...state.classroomDetailFetchFailed,
              code,
            },
          ));
        }
      } catch (_) {
        if (isClosed) return;
        emit(state.copyWith(
          classroomDetailFetchFailed: {
            ...state.classroomDetailFetchFailed,
            code,
          },
        ));
      } finally {
        _classroomDetailFetchInFlight.remove(code);
      }
    }
  }

  /// Clear the classroom-detail failure cache + prefetch fingerprint so a manual
  /// refresh re-attempts previously-failed lookups. Keeps successfully-resolved
  /// names (they're re-validated against the fresh roster by fingerprint).
  void clearClassroomDetailCache() {
    _lastClassroomPrefetchFingerprint = '';
    emit(state.copyWith(classroomDetailFetchFailed: const {}));
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
