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
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../../scheduling/utils/scheduling_cache_gate.dart';

part 'staff_state.dart';

class StaffCubit extends Cubit<StaffState> {
  StaffCubit({
    required GetStaffPageUseCase getStaffPageUseCase,
    required GetStaffCountUseCase getStaffCountUseCase,
    required StaffRepository repository,
    required StorageService storageService,
  }) : _getStaffPageUseCase = getStaffPageUseCase,
       _getStaffCountUseCase = getStaffCountUseCase,
       _repository = repository,
       _storageService = storageService,
       super(const StaffState.initial());

  final GetStaffPageUseCase _getStaffPageUseCase;
  final GetStaffCountUseCase _getStaffCountUseCase;
  final StaffRepository _repository;
  final StorageService _storageService;
  String? _schoolCode;
  String? _organizationCode;

  // How many staff records to load per page from the API. The staff list
  // screen scrolls, so it keeps this small default; a screen that needs the
  // whole roster in memory at once (the task assignee picker, which
  // multi-selects and searches locally over what it was given) raises it via
  // [setPageSize] so one round trip covers a whole school.
  static const int _defaultPageSize = 10;
  int _pageSize = _defaultPageSize;

  /// Overrides the API page size for this cubit instance. Call before the first
  /// load; non-positive values are ignored.
  void setPageSize(int size) {
    if (size > 0) _pageSize = size;
  }

  String? _effectiveStatusFilter() {
    final raw = state.statusFilter;
    if (raw == null || raw.isEmpty) return 'ACTIVE';
    return raw;
  }

  Future<String> _resolveSchoolCode() async {
    if (_schoolCode != null) return _schoolCode!;
    // Take school from login-context API (saved in storage) only.
    _schoolCode = await _storageService.getString(StorageKeys.schoolCode) ?? '';
    return _schoolCode!;
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

    // Snapshot the status this refresh is fetching. If the filter changes while
    // we're in flight (e.g. a deep-link resolves a deactivated staff and flips
    // to INACTIVE while the route's default ACTIVE load is still running), the
    // older result must NOT clobber the newer one — we drop it before emitting.
    final requestedStatus = _effectiveStatusFilter();

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

        items.addAll(secondPage.items);
        currentPage = secondPage.page;
        hasMore = secondPage.hasMore;
      }

      if (isClosed) return;
      // Drop a stale result: the filter changed while this load was in flight,
      // so a newer refresh owns the list now.
      if (_effectiveStatusFilter() != requestedStatus) return;
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
      if (isClosed) return;
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

      if (isClosed) return;

      // ignore: avoid_print
      AppLogger.d(
        '[StaffCubit] loaded page=${page.page}, '
        'itemsAdded=${page.items.length}, '
        'hasMore=${page.hasMore}',
      );
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

  /// Deactivates a staff member (via school user deactivate API) and refreshes the list.
  /// Returns the success message from the backend. Errors are rethrown for UI to handle.
  Future<String> deactivateStaff(String staffCode) async {
    // First, load the staff profile to resolve userCode, organizationCode, and schoolCode.
    final profile = await _repository.getStaffProfile(
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
      final message = await _repository.deactivateOrganizationAdmin(
        userCode: profile.userCode,
        organizationCode: profile.organizationCode,
      );
      await refreshWithCacheReset();
      return message;
    }

    // Map staffType from profile to backend role expected by school-users APIs.
    // Backend role differs for school admins vs regular staff.
    final role = (staffTypeUpper == 'ADMIN' || staffTypeUpper == 'SCHOOL_ADMIN')
        ? 'SCHOOL_ADMIN'
        : 'STAFF';

    final message = await _repository.deactivateSchoolUser(
      userCode: profile.userCode,
      organizationCode: profile.organizationCode,
      schoolCode: schoolCode,
      role: role,
    );

    // Refresh the list so UI and cache reflect the updated status.
    await refreshWithCacheReset();

    return message;
  }

  /// Activates a staff member (via school user activate API) and refreshes the list.
  /// Returns the success message from the backend. Errors are rethrown for UI to handle.
  Future<String> activateStaff(String staffCode) async {
    // First, load the staff profile to resolve userCode, organizationCode, and schoolCode.
    final profile = await _repository.getStaffProfile(
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
      final message = await _repository.activateOrganizationAdmin(
        userCode: profile.userCode,
        organizationCode: profile.organizationCode,
      );

      await refreshWithCacheReset();
      return message;
    }

    final role = (staffTypeUpper == 'ADMIN' || staffTypeUpper == 'SCHOOL_ADMIN')
        ? 'SCHOOL_ADMIN'
        : 'STAFF';

    final message = await _repository.activateSchoolUser(
      userCode: profile.userCode,
      organizationCode: profile.organizationCode,
      schoolCode: schoolCode,
      role: role,
    );

    // Refresh the list so UI and cache reflect the updated status.
    await refreshWithCacheReset();

    return message;
  }

  /// Permanently deletes a (deactivated) staff member via the school-user
  /// delete API and refreshes the list. Returns the success message from the
  /// backend. Errors are rethrown for the UI to handle.
  Future<String> deleteStaff(String staffCode) async {
    // Resolve userCode, organizationCode, schoolCode and role from the profile.
    final profile = await _repository.getStaffProfile(
      staffCode: staffCode,
      forEditStaff: true,
    );

    final staffTypeUpper = profile.staffType.toUpperCase().trim();
    final role = (staffTypeUpper == 'ADMIN' || staffTypeUpper == 'SCHOOL_ADMIN')
        ? 'SCHOOL_ADMIN'
        : 'STAFF';

    final message = await _repository.deleteSchoolUser(
      userCode: profile.userCode,
      organizationCode: profile.organizationCode,
      schoolCode: profile.schoolCode.trim(),
      role: role,
    );

    // Refresh the list so UI and cache reflect the deletion.
    await refreshWithCacheReset();

    return message;
  }

  /// Performs a lightweight search that only calls the staff list API (no count
  /// refresh or automatic second-page preloading). Intended for rapid typing.
  Future<void> searchStaff(String query) async {
    emit(state.copyWith(searchQuery: query));
    await refresh(ignoreRefreshingGuard: true);
  }

  void updateSearch(String query) {
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
