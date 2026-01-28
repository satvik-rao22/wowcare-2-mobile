import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/staff/entities/staff_member.dart';
import '../../../../domain/features/staff/usecases/get_staff_page_usecase.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';

part 'staff_state.dart';

class StaffCubit extends Cubit<StaffState> {
  StaffCubit({
    required GetStaffPageUseCase getStaffPageUseCase,
    required StaffRepository repository,
    required StorageService storageService,
  })  : _getStaffPageUseCase = getStaffPageUseCase,
        _repository = repository,
        _storageService = storageService,
        super(const StaffState.initial());

  final GetStaffPageUseCase _getStaffPageUseCase;
  final StaffRepository _repository;
  final StorageService _storageService;
  String? _schoolCode;

  static const int _pageSize = 10;

  Future<String> _resolveSchoolCode() async {
    if (_schoolCode != null) return _schoolCode!;

    final stored =
        await _storageService.getString(StorageKeys.schoolCode);
    _schoolCode = stored?.isNotEmpty == true
        ? stored!
        : StorageKeys.defaultSchoolCode;
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
    }

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
      final page = await _getStaffPageUseCase(
        schoolCode: schoolCode,
        page: 0,
        size: _pageSize,
        status: state.statusFilter,
        designation: state.designationFilter,
        search: state.searchQuery,
      );

      if (isClosed) return;

      emit(
        state.copyWith(
          items: page.items,
          currentPage: page.page,
          hasMore: page.hasMore,
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


