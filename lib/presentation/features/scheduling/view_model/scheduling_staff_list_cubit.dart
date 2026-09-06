import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_error_handler.dart';
import '../../../../domain/features/staff/entities/staff_member.dart';
import '../../../../domain/features/staff/usecases/get_all_staff_usecase.dart';
import 'scheduling_school_scope_mixin.dart';

part 'scheduling_staff_list_state.dart';

/// Loads the full staff roster for the scheduling feature in a single API
/// call — no pagination — using repeated `status` query keys (defaults to
/// `ACTIVE` + `UPCOMING`). Kept separate from `StaffCubit` so the staff list
/// screen continues to paginate while scheduling fetches everything at once.
class SchedulingStaffListCubit extends Cubit<SchedulingStaffListState>
    with SchedulingSchoolScopeMixin {
  SchedulingStaffListCubit({
    required GetAllStaffUseCase getAllStaffUseCase,
    required StorageService storageService,
  }) : _getAllStaffUseCase = getAllStaffUseCase,
       _storageService = storageService,
       super(SchedulingStaffListState.initial());

  static const List<String> _defaultStatuses = ['ACTIVE', 'UPCOMING'];

  final GetAllStaffUseCase _getAllStaffUseCase;
  final StorageService _storageService;

  @override
  StorageService get storageService => _storageService;

  /// Loads the staff list. No-op if already loaded or a load is in flight
  /// (the cubit is a session-wide singleton so callers can safely invoke
  /// this on every screen entry — only the first one triggers the API).
  /// Pass `force: true` to bypass the cache and refetch.
  Future<List<StaffMember>> load({
    List<String> statuses = _defaultStatuses,
    bool force = false,
  }) async {
    if (!force) {
      if (state.isLoading) return state.staff;
      if (state.staff.isNotEmpty) return state.staff;
    }
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final organizationCode = await resolveOrganizationCode();
      final schoolCode = await resolveSchoolCode();

      if (organizationCode.isEmpty || schoolCode.isEmpty) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'School context is missing. Please sign in again.',
          ),
        );
        return const [];
      }

      final staff = await _getAllStaffUseCase(
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        statuses: statuses,
      );

      final sorted = List<StaffMember>.from(staff)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (isClosed) return sorted;
      emit(state.copyWith(staff: sorted, isLoading: false));
      return sorted;
    } catch (e) {
      if (isClosed) return const [];
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
      rethrow;
    }
  }
}
