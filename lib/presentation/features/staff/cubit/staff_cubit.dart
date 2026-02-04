import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/staff/entities/staff_member.dart';
import '../../../../domain/features/staff/usecases/get_staff_page_usecase.dart';
import '../../../../domain/features/staff/usecases/get_staff_count_usecase.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';

part 'staff_state.dart';

class StaffCubit extends Cubit<StaffState> {
  StaffCubit({
    required GetStaffPageUseCase getStaffPageUseCase,
    required GetStaffCountUseCase getStaffCountUseCase,
    required StaffRepository repository,
    required StorageService storageService,
  })  : _getStaffPageUseCase = getStaffPageUseCase,
        _getStaffCountUseCase = getStaffCountUseCase,
        _repository = repository,
        super(const StaffState.initial());

  final GetStaffPageUseCase _getStaffPageUseCase;
  final GetStaffCountUseCase _getStaffCountUseCase;
  final StaffRepository _repository;
  String? _schoolCode;

  // How many staff records to load per page from the API
  static const int _pageSize = 15;

  Future<String> _resolveSchoolCode() async {
    if (_schoolCode != null) return _schoolCode!;
    // TEMP: Always use default school code from StorageKeys (ignore stored prefs).
    _schoolCode = StorageKeys.defaultSchoolCode;
    return _schoolCode!;
  }

  Future<void> loadInitial() async {
    final schoolCode = await _resolveSchoolCode();

    // Try cache first
    final cached =
        await (_repository is StaffRepositoryWithCache
            ? (_repository as StaffRepositoryWithCache)
                .loadCachedStaffPage(schoolCode)
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
      // Still load staff count so stat cards are accurate.
      await _refreshStaffCountOnly();
      return;
    }

    // No cache (or expired) – load from API.
    await refresh();
  }

  Future<void> _refreshStaffCountOnly() async {
    try {
      final schoolCode = await _resolveSchoolCode();
      final staffCount = await _getStaffCountUseCase(schoolCode: schoolCode);
      if (isClosed) return;
      emit(
        state.copyWith(
          staffCountTotal: staffCount.total,
          staffCountActive: staffCount.active,
          staffCountUpcoming: staffCount.upcoming,
        ),
      );
    } catch (_) {
      // Non-fatal: staff list can still work even if count endpoint fails.
    }
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
      // Start both requests in parallel.
      final staffCountFuture = _getStaffCountUseCase(schoolCode: schoolCode);
      final firstPageFuture = _getStaffPageUseCase(
        schoolCode: schoolCode,
        page: 0,
        size: _pageSize,
        status: state.statusFilter,
        designation: state.designationFilter,
        search: state.searchQuery,
      );

      if (isClosed) return;

      final staffCount = await staffCountFuture;
      final firstPage = await firstPageFuture;

      var items = List<StaffMember>.from(firstPage.items);
      var currentPage = firstPage.page;
      var hasMore = firstPage.hasMore;

      // Auto-load next page so that page 0 and 1 are both visible initially
      if (hasMore) {
        final secondPage = await _getStaffPageUseCase(
          schoolCode: schoolCode,
          page: 1,
          size: _pageSize,
          status: state.statusFilter,
          designation: state.designationFilter,
          search: state.searchQuery,
        );

        items.addAll(secondPage.items);
        currentPage = secondPage.page;
        hasMore = secondPage.hasMore;
      }

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
      final page = await _getStaffPageUseCase(
        schoolCode: schoolCode,
        page: nextPageIndex,
        size: _pageSize,
        status: state.statusFilter,
        designation: state.designationFilter,
        search: state.searchQuery,
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

  /// Deactivates a staff member (via school user deactivate API) and refreshes the list.
  /// Returns the success message from the backend. Errors are rethrown for UI to handle.
  Future<String> deactivateStaff(String staffCode) async {
    // First, load the staff profile to resolve userCode, organizationCode, and schoolCode.
    final profile = await _repository.getStaffProfile(staffCode: staffCode);

    // Map staffType from profile to backend role expected by deactivate API
    // Example: admins should use SCHOOL_ADMIN instead of STAFF.
    final staffTypeUpper = profile.staffType.toUpperCase();
    final role = staffTypeUpper == 'ADMIN' ? 'SCHOOL_ADMIN' : 'STAFF';

    final message = await _repository.deactivateSchoolUser(
      userCode: profile.userCode,
      organizationCode: profile.organizationCode,
      schoolCode: profile.schoolCode,
      role: role,
    );

    // Refresh the list so UI and cache reflect the updated status.
    await refresh();

    return message;
  }

   /// Activates a staff member (via school user activate API) and refreshes the list.
   /// Returns the success message from the backend. Errors are rethrown for UI to handle.
  Future<String> activateStaff(String staffCode) async {
    // First, load the staff profile to resolve userCode, organizationCode, and schoolCode.
    final profile = await _repository.getStaffProfile(staffCode: staffCode);

    // Map staffType from profile to backend role expected by activate API
    final staffTypeUpper = profile.staffType.toUpperCase();
    final role = staffTypeUpper == 'ADMIN' ? 'SCHOOL_ADMIN' : 'STAFF';

    final message = await _repository.activateSchoolUser(
      userCode: profile.userCode,
      organizationCode: profile.organizationCode,
      schoolCode: profile.schoolCode,
      role: role,
    );

    // Refresh the list so UI and cache reflect the updated status.
    await refresh();

    return message;
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
    String? designation,
  }) {
    emit(
      state.copyWith(
        statusFilter: status,
        designationFilter: designation,
      ),
    );
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
    final updated =
        state.items.where((element) => element.code != code).toList();
    emit(state.copyWith(items: updated));
  }
}


