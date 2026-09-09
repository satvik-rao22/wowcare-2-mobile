import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/domain/features/communication/services/messaging_session.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/domain/features/messaging/usecases/get_filtered_staff_usecase.dart';
import 'staff_messaging_filter_state.dart';

class StaffMessagingFilterCubit extends Cubit<StaffMessagingFilterState> {
  final GetFilteredStaffUseCase _getFilteredStaffUseCase;
  final MessagingSession _session;

  static const int _pageSize = 20;
  Timer? _debounceTimer;
  String? _schoolCode;
  String? _organizationCode;

  StaffMessagingFilterCubit({
    required GetFilteredStaffUseCase getFilteredStaffUseCase,
    required MessagingSession session,
  }) : _getFilteredStaffUseCase = getFilteredStaffUseCase,
       _session = session,
       super(const StaffMessagingFilterState.initial());

  Future<String> _resolveSchoolCode() async {
    if (_schoolCode != null) return _schoolCode!;
    _schoolCode = await _session.schoolCode() ?? '';
    return _schoolCode!;
  }

  Future<String> _resolveOrganizationCode() async {
    if (_organizationCode != null) return _organizationCode!;
    _organizationCode =
        await _session.organizationCode() ?? '';
    return _organizationCode!;
  }

  Future<void> loadInitial() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    await refresh();
  }

  Future<void> refresh() async {
    final schoolCode = await _resolveSchoolCode();
    final organizationCode = await _resolveOrganizationCode();

    emit(state.copyWith(isRefreshing: true, errorMessage: null));

    try {
      final staffPage = await _getFilteredStaffUseCase(
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        page: 0,
        size:
            state.selectedStaffStatus != null &&
                state.selectedStaffStatus!.isNotEmpty
            ? 50
            : _pageSize,
        status: 'ACTIVE',
        designation: state.selectedDesignation,
        search: state.searchQuery,
        classCode: state.selectedClassroomCode,
        staffStatus: state.selectedStaffStatus,
      );

      if (isClosed) return;

      emit(
        state.copyWith(
          items: staffPage.items,
          currentPage: 0,
          hasMore: staffPage.hasMore,
          isLoading: false,
          isRefreshing: false,
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
    if (state.isLoadingMore || !state.hasMore) return;

    final schoolCode = await _resolveSchoolCode();
    final organizationCode = await _resolveOrganizationCode();

    emit(state.copyWith(isLoadingMore: true, errorMessage: null));

    try {
      final nextPage = state.currentPage + 1;
      final staffPage = await _getFilteredStaffUseCase(
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        page: nextPage,
        size:
            state.selectedStaffStatus != null &&
                state.selectedStaffStatus!.isNotEmpty
            ? 50
            : _pageSize,
        status: 'ACTIVE',
        designation: state.selectedDesignation,
        search: state.searchQuery,
        classCode: state.selectedClassroomCode,
        staffStatus: state.selectedStaffStatus,
      );

      if (isClosed) return;

      emit(
        state.copyWith(
          items: [...state.items, ...staffPage.items],
          currentPage: nextPage,
          hasMore: staffPage.hasMore,
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

  void updateSearch(String query) {
    emit(state.copyWith(searchQuery: query));
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      refresh();
    });
  }

  void updateFilters({
    String? classroomCode,
    String? classroomName,
    String? designation,
    String? staffStatus,
  }) {
    emit(
      state.copyWith(
        selectedClassroomCode: classroomCode,
        selectedClassroomName: classroomName,
        selectedDesignation: designation,
        selectedStaffStatus: staffStatus,
        clearClassroom: classroomCode == null,
        clearDesignation: designation == null,
        clearStaffStatus: staffStatus == null,
      ),
    );
    refresh();
  }

  void clearFilters() {
    emit(
      state.copyWith(
        searchQuery: '',
        clearClassroom: true,
        clearDesignation: true,
        clearStaffStatus: true,
      ),
    );
    refresh();
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
