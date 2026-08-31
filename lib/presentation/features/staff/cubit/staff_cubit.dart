import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/staff/entities/staff_count.dart';
import '../../../../domain/features/staff/entities/staff_member.dart';
import '../../../../domain/features/staff/usecases/get_staff_page_usecase.dart';
import '../../../../domain/features/staff/usecases/get_staff_count_usecase.dart';
import '../../../../domain/features/staff/usecases/get_staff_profile_usecase.dart';
import '../../../../domain/features/staff/usecases/activate_school_user_usecase.dart';
import '../../../../domain/features/staff/usecases/deactivate_school_user_usecase.dart';
import '../../../../domain/features/staff/usecases/activate_organization_admin_usecase.dart';
import '../../../../domain/features/staff/usecases/deactivate_organization_admin_usecase.dart';
import '../../../../domain/features/staff/usecases/delete_school_user_usecase.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../../scheduling/utils/scheduling_cache_gate.dart';

part 'staff_state.dart';

class StaffCubit extends Cubit<StaffState> {
  StaffCubit({
    required GetStaffPageUseCase getStaffPageUseCase,
    required GetStaffCountUseCase getStaffCountUseCase,
    required GetStaffProfileUseCase getStaffProfileUseCase,
    required ActivateSchoolUserUseCase activateSchoolUserUseCase,
    required DeactivateSchoolUserUseCase deactivateSchoolUserUseCase,
    required ActivateOrganizationAdminUseCase activateOrganizationAdminUseCase,
    required DeactivateOrganizationAdminUseCase
    deactivateOrganizationAdminUseCase,
    required DeleteSchoolUserUseCase deleteSchoolUserUseCase,
    required StaffRepository repository,
    required StorageService storageService,
  }) : _getStaffPageUseCase = getStaffPageUseCase,
       _getStaffCountUseCase = getStaffCountUseCase,
       _getStaffProfileUseCase = getStaffProfileUseCase,
       _activateSchoolUserUseCase = activateSchoolUserUseCase,
       _deactivateSchoolUserUseCase = deactivateSchoolUserUseCase,
       _activateOrganizationAdminUseCase = activateOrganizationAdminUseCase,
       _deactivateOrganizationAdminUseCase = deactivateOrganizationAdminUseCase,
       _deleteSchoolUserUseCase = deleteSchoolUserUseCase,
       _repository = repository,
       _storageService = storageService,
       super(const StaffState.initial());

  final GetStaffPageUseCase _getStaffPageUseCase;
  final GetStaffCountUseCase _getStaffCountUseCase;
  final GetStaffProfileUseCase _getStaffProfileUseCase;
  final ActivateSchoolUserUseCase _activateSchoolUserUseCase;
  final DeactivateSchoolUserUseCase _deactivateSchoolUserUseCase;
  final ActivateOrganizationAdminUseCase _activateOrganizationAdminUseCase;
  final DeactivateOrganizationAdminUseCase _deactivateOrganizationAdminUseCase;
  final DeleteSchoolUserUseCase _deleteSchoolUserUseCase;
  final StaffRepository _repository;
  final StorageService _storageService;
  String? _schoolCode;
  String? _organizationCode;

  /// Monotonic query generation. Bumped whenever the logical query changes
  /// (a new refresh, a search/filter change, or a detected school switch) so a
  /// slower in-flight response for an older query/school is discarded instead
  /// of clobbering the current one.
  int _generation = 0;

  // How many staff records to load per page from the API
  static const int _pageSize = 10;

  /// Appends [incoming] onto [existing], skipping any staff whose code is
  /// already present (stable-identity dedup), so overlapping backend pages can't
  /// show the same staff member twice. Original order is preserved.
  static List<StaffMember> _appendDedupedByCode(
    List<StaffMember> existing,
    List<StaffMember> incoming,
  ) {
    final seen = existing.map((s) => s.code).toSet();
    final result = List<StaffMember>.from(existing);
    for (final s in incoming) {
      if (seen.add(s.code)) result.add(s);
    }
    return result;
  }

  String? _effectiveStatusFilter() {
    final raw = state.statusFilter;
    if (raw == null || raw.isEmpty) return 'ACTIVE';
    return raw;
  }

  Future<String> _resolveSchoolCode() async {
    // Always read the live school from storage (never a stale memoized value):
    // the cubit can outlive an in-place school switch (e.g. an FCM-driven switch
    // on a still-mounted screen).
    final fresh = await _storageService.getString(StorageKeys.schoolCode) ?? '';
    if (_schoolCode != null && _schoolCode != fresh) {
      // School switched under a live cubit: drop the memoized org code so it
      // re-resolves for the new school, and supersede any in-flight response.
      _organizationCode = null;
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
    final current = await _storageService.getString(StorageKeys.schoolCode) ?? '';
    return current != schoolAtStart;
  }

  Future<String> _resolveOrganizationCode() async {
    if (_organizationCode != null) return _organizationCode!;
    _organizationCode =
        await _storageService.getString(StorageKeys.organizationCode) ?? '';
    return _organizationCode!;
  }

  Future<void> loadInitial() async {
    final schoolCode = await _resolveSchoolCode();

    // 1. Try cache first for immediate UI update
    final cached = await (_repository is StaffRepositoryWithCache
        ? (_repository as StaffRepositoryWithCache).loadCachedStaffPage(
            schoolCode,
            status: _effectiveStatusFilter(),
            designation: state.designationFilter,
            search: state.searchQuery,
            primaryClassroomCodes: state.primaryClassroomCodes,
            classCodes: state.classCodes,
            sortBy: state.sortBy,
            attendanceStatuses: state.attendanceStatuses,
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

    // Staff-side data may have just changed (profile edit, status toggle,
    // delete). Bump the scheduling cache gate so the classroom + staff
    // scheduling screens silently re-pull the staff list on their next view.
    SchedulingCacheGate.invalidate();

    final schoolCode = await _resolveSchoolCode();

    emit(
      state.copyWith(
        isLoading: state.items.isEmpty,
        isRefreshing: true,
        errorMessage: null,
      ),
    );

    // Snapshot the status and search query this refresh is fetching. If
    // either changes while we're in flight (e.g. a deep-link resolves a
    // deactivated staff and flips to INACTIVE while the route's default
    // ACTIVE load is still running — or [searchStaff]'s rapid-fire
    // per-keystroke calls let requests race), an older, slower response
    // must NOT clobber a newer one just because it happened to land last —
    // we drop it before emitting instead.
    final requestedStatus = _effectiveStatusFilter();
    final requestedSearch = state.searchQuery;
    // This refresh owns a fresh generation; capture the school it runs under so
    // a later school switch (or newer query) discards this response.
    final gen = ++_generation;
    final schoolAtStart = schoolCode;

    try {
      final organizationCode = await _resolveOrganizationCode();
      // Start both requests in parallel.
      final staffCountFuture = _getStaffCountUseCase(
        organizationCode: organizationCode,
        schoolCode: schoolCode,
      );
      final firstPageFuture = _getStaffPageUseCase(
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        page: 0,
        size: _pageSize,
        status: requestedStatus,
        designation: state.designationFilter,
        search: state.searchQuery,
        primaryClassroomCodes: state.primaryClassroomCodes,
        classCodes: state.classCodes,
        sortBy: state.sortBy,
        attendanceStatuses: state.attendanceStatuses,
      );

      if (isClosed) return;

      // Staff count is non-fatal: if it fails, use defaults so list still shows.
      // Error is already logged by API interceptor -> CoreUtils.
      StaffCount staffCount = const StaffCount(
        total: 0,
        active: 0,
        upcoming: 0,
      );
      try {
        staffCount = await staffCountFuture;
      } catch (_) {}

      final firstPage = await firstPageFuture;

      var items = List<StaffMember>.from(firstPage.items);
      var currentPage = firstPage.page;
      var hasMore = firstPage.hasMore;

      // Auto-load next page so that page 0 and 1 are both visible initially
      if (hasMore) {
        final secondPage = await _getStaffPageUseCase(
          organizationCode: organizationCode,
          schoolCode: schoolCode,
          page: 1,
          size: _pageSize,
          status: requestedStatus,
          designation: state.designationFilter,
          search: state.searchQuery,
          primaryClassroomCodes: state.primaryClassroomCodes,
          classCodes: state.classCodes,
          sortBy: state.sortBy,
          attendanceStatuses: state.attendanceStatuses,
        );

        items = _appendDedupedByCode(items, secondPage.items);
        currentPage = secondPage.page;
        hasMore = secondPage.hasMore;
      }

      // Drop a stale result: a newer query/refresh or a school switch happened
      // while this load was in flight. The legacy status/search checks are
      // subsumed by the generation guard, which also covers the active school.
      if (await _isStaleResponse(gen, schoolAtStart)) return;
      if (_effectiveStatusFilter() != requestedStatus) return;
      if (state.searchQuery != requestedSearch) return;
      emit(
        state.copyWith(
          items: items,
          currentPage: currentPage,
          hasMore: hasMore,
          staffCountTotal: staffCount.total,
          staffCountActive: staffCount.active,
          staffCountUpcoming: staffCount.upcoming,
          isLoading: false,
          isRefreshing: false,
          isFromCache: false,
        ),
      );
    } catch (e) {
      if (await _isStaleResponse(gen, schoolAtStart)) return;
      CoreUtils.logApiError(e.toString());
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  Future<void> refreshWithCacheReset() async {
    final schoolCode = await _resolveSchoolCode();
    if (_repository is StaffRepositoryWithCache) {
      await (_repository as StaffRepositoryWithCache).invalidateCachedStaffPage(
        schoolCode,
        status: _effectiveStatusFilter(),
        designation: state.designationFilter,
        search: state.searchQuery,
        primaryClassroomCodes: state.primaryClassroomCodes,
        classCodes: state.classCodes,
        sortBy: state.sortBy,
        attendanceStatuses: state.attendanceStatuses,
      );
    }
    await refresh(ignoreRefreshingGuard: true);
  }

  Future<void> loadNextPage() async {
    // ignore: avoid_print
    AppLogger.d(
      '[StaffCubit] loadNextPage called: '
      'isLoadingMore=${state.isLoadingMore}, '
      'hasMore=${state.hasMore}, '
      'currentPage=${state.currentPage}, '
      'items=${state.items.length}',
    );
    if (state.isLoadingMore || !state.hasMore) {
      // ignore: avoid_print
      AppLogger.d('[StaffCubit] loadNextPage aborted due to guard.');
      return;
    }

    final schoolCode = await _resolveSchoolCode();
    final organizationCode = await _resolveOrganizationCode();
    // load-more continues the CURRENT query — capture its generation (do not
    // bump) and school so a refresh/filter/school change mid-flight discards
    // this page instead of appending it into a now-different list.
    final gen = _generation;
    final schoolAtStart = schoolCode;

    emit(state.copyWith(isLoadingMore: true, errorMessage: null));

    try {
      final nextPageIndex = state.currentPage + 1;
      // ignore: avoid_print
      AppLogger.d(
        '[StaffCubit] requesting page=$nextPageIndex, size=$_pageSize',
      );
      final page = await _getStaffPageUseCase(
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        page: nextPageIndex,
        size: _pageSize,
        status: _effectiveStatusFilter(),
        designation: state.designationFilter,
        search: state.searchQuery,
        primaryClassroomCodes: state.primaryClassroomCodes,
        classCodes: state.classCodes,
        sortBy: state.sortBy,
        attendanceStatuses: state.attendanceStatuses,
      );

      if (await _isStaleResponse(gen, schoolAtStart)) return;

      // ignore: avoid_print
      AppLogger.d(
        '[StaffCubit] loaded page=${page.page}, '
        'itemsAdded=${page.items.length}, '
        'hasMore=${page.hasMore}',
      );
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

  /// In-flight staff mutations keyed by `action:staffCode`. A second call for
  /// the same action+staff while the first is still running (a double-tap)
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
    future.whenComplete(() => _inFlightMutations.remove(key)).ignore();
    return future;
  }

  /// Deactivates a staff member (via school user deactivate API) and refreshes the list.
  /// Returns the success message from the backend. Errors are rethrown for UI to handle.
  Future<String> deactivateStaff(String staffCode) {
    return _singleFlightMutation('deactivate:$staffCode', () async {
      // First, load the staff profile to resolve userCode, organizationCode, and schoolCode.
      final profile = await _getStaffProfileUseCase(
        staffCode: staffCode,
        forEditStaff: true,
      );

      final staffTypeUpper = profile.staffType.toUpperCase().trim();
      final schoolCode = profile.schoolCode.trim();
      final bool schoolCodeMissing = schoolCode.isEmpty || schoolCode == '-';
      final bool isOrganizationAdmin =
          staffTypeUpper.contains('ORGANIZATION') &&
          staffTypeUpper.contains('ADMIN');

      // Organization admins are deactivated via a different endpoint that
      // does not take `schoolCode` or `role`.
      if (isOrganizationAdmin || schoolCodeMissing) {
        final message = await _deactivateOrganizationAdminUseCase(
          userCode: profile.userCode,
          organizationCode: profile.organizationCode,
        );
        await refreshWithCacheReset();
        return message;
      }

      // Map staffType from profile to backend role expected by school-users APIs.
      // Backend role differs for school admins vs regular staff.
      final role =
          (staffTypeUpper == 'ADMIN' || staffTypeUpper == 'SCHOOL_ADMIN')
              ? 'SCHOOL_ADMIN'
              : 'STAFF';

      final message = await _deactivateSchoolUserUseCase(
        userCode: profile.userCode,
        organizationCode: profile.organizationCode,
        schoolCode: schoolCode,
        role: role,
      );

      // Refresh the list so UI and cache reflect the updated status.
      await refreshWithCacheReset();

      return message;
    });
  }

  /// Activates a staff member (via school user activate API) and refreshes the list.
  /// Returns the success message from the backend. Errors are rethrown for UI to handle.
  Future<String> activateStaff(String staffCode) {
    return _singleFlightMutation('activate:$staffCode', () async {
      // First, load the staff profile to resolve userCode, organizationCode, and schoolCode.
      final profile = await _getStaffProfileUseCase(
        staffCode: staffCode,
        forEditStaff: true,
      );

      final staffTypeUpper = profile.staffType.toUpperCase().trim();
      final schoolCode = profile.schoolCode.trim();
      final bool schoolCodeMissing = schoolCode.isEmpty || schoolCode == '-';
      final bool isOrganizationAdmin =
          staffTypeUpper.contains('ORGANIZATION') &&
          staffTypeUpper.contains('ADMIN');

      if (isOrganizationAdmin || schoolCodeMissing) {
        final message = await _activateOrganizationAdminUseCase(
          userCode: profile.userCode,
          organizationCode: profile.organizationCode,
        );

        await refreshWithCacheReset();
        return message;
      }

      final role =
          (staffTypeUpper == 'ADMIN' || staffTypeUpper == 'SCHOOL_ADMIN')
              ? 'SCHOOL_ADMIN'
              : 'STAFF';

      final message = await _activateSchoolUserUseCase(
        userCode: profile.userCode,
        organizationCode: profile.organizationCode,
        schoolCode: schoolCode,
        role: role,
      );

      // Refresh the list so UI and cache reflect the updated status.
      await refreshWithCacheReset();

      return message;
    });
  }

  /// Permanently deletes a (deactivated) staff member via the school-user
  /// delete API and refreshes the list. Returns the success message from the
  /// backend. Errors are rethrown for the UI to handle.
  Future<String> deleteStaff(String staffCode) {
    return _singleFlightMutation('delete:$staffCode', () async {
      // Resolve userCode, organizationCode, schoolCode and role from the profile.
      final profile = await _getStaffProfileUseCase(
        staffCode: staffCode,
        forEditStaff: true,
      );

      final staffTypeUpper = profile.staffType.toUpperCase().trim();
      final role =
          (staffTypeUpper == 'ADMIN' || staffTypeUpper == 'SCHOOL_ADMIN')
              ? 'SCHOOL_ADMIN'
              : 'STAFF';

      final message = await _deleteSchoolUserUseCase(
        userCode: profile.userCode,
        organizationCode: profile.organizationCode,
        schoolCode: profile.schoolCode.trim(),
        role: role,
      );

      // Refresh the list so UI and cache reflect the deletion.
      await refreshWithCacheReset();

      return message;
    });
  }

  /// Performs a lightweight search that only calls the staff list API (no count
  /// refresh or automatic second-page preloading). Intended for rapid typing.
  Future<void> searchStaff(String query) async {
    emit(state.copyWith(searchQuery: query));
    await refresh(ignoreRefreshingGuard: true);
  }

  void updateSearch(String query) {
    // A new search is a new logical query: supersede any in-flight response.
    _generation++;
    emit(state.copyWith(searchQuery: query));
  }

  void updateFilters({
    String? status,
    String? designation,
    List<String>? primaryClassroomCodes,
    List<String>? classCodes,
    String? sortBy,
    List<String>? attendanceStatuses,
  }) {
    // Normalize empty / null to empty-string so that copyWith can
    // clear filters instead of keeping the previous non-null value.
    final normalizedStatus = (status ?? '').trim();
    final normalizedDesignation = (designation ?? '').trim();
    final normalizedSortBy = (sortBy ?? '').trim().toLowerCase();

    // Filter changes reset the logical query: supersede any in-flight response
    // so an older page/list can't append into or overwrite the new results.
    _generation++;
    emit(
      state.copyWith(
        statusFilter: normalizedStatus.isEmpty ? '' : normalizedStatus,
        designationFilter: normalizedDesignation.isEmpty
            ? ''
            : normalizedDesignation,
        primaryClassroomCodes:
            primaryClassroomCodes ?? state.primaryClassroomCodes,
        classCodes: classCodes ?? state.classCodes,
        sortBy: normalizedSortBy.isEmpty
            ? state.sortBy
            : (normalizedSortBy == 'asc' ? 'asc' : 'desc'),
        attendanceStatuses: attendanceStatuses ?? state.attendanceStatuses,
      ),
    );
  }

  /// Clears all filters (search, status, designation, classroom) and refreshes the list.
  Future<void> clearAllFiltersAndRefresh() async {
    // Update state first to clear filters (use [] so copyWith clears classroom filters)
    emit(
      state.copyWith(
        searchQuery: '',
        statusFilter: 'ACTIVE',
        designationFilter: '',
        primaryClassroomCodes: const [],
        classCodes: const [],
        sortBy: 'desc',
        attendanceStatuses: const [],
        isRefreshing: true,
        errorMessage: null,
      ),
    );

    await refresh(ignoreRefreshingGuard: true);
  }

  // To be called by add/edit/delete flows to keep cache + UI in sync
  void upsertStaffMember(StaffMember member) {
    final updated = List<StaffMember>.from(state.items);
    final index = updated.indexWhere((e) => e.code == member.code);
    if (index >= 0) {
      updated[index] = member;
    } else {
      updated.insert(0, member);
    }
    emit(state.copyWith(items: updated));
  }

  void removeStaffMember(String code) {
    final updated = state.items
        .where((element) => element.code != code)
        .toList();
    emit(state.copyWith(items: updated));
  }
}
