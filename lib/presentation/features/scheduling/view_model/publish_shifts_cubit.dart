import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/utils/api_error_handler.dart';
import '../../../../core/utils/storage_keys.dart';
import '../../../../domain/features/scheduling/usecases/bootstrap_scheduling_school_timezone_usecase.dart';
import '../../../../domain/features/scheduling/usecases/publish_staff_shifts_usecase.dart';

part 'publish_shifts_state.dart';

/// Backs the Publish Shifts screen — single-shot POST to
/// `/api/v1/staff-shifts/publish`. Owns all form state (mode, staff
/// selection, until-date) so the view is a pure display over this cubit,
/// matching [AddShiftCubit] / [EditShiftCubit] in the same feature.
class PublishShiftsCubit extends Cubit<PublishShiftsState> {
  PublishShiftsCubit({
    required PublishStaffShiftsUseCase publishStaffShiftsUseCase,
    required StorageService storageService,
    required BootstrapSchedulingSchoolTimezoneUseCase
        bootstrapSchedulingSchoolTimezoneUseCase,
  })  : _publishStaffShiftsUseCase = publishStaffShiftsUseCase,
        _storageService = storageService,
        _bootstrapSchedulingSchoolTimezoneUseCase =
            bootstrapSchedulingSchoolTimezoneUseCase,
        super(const PublishShiftsState());

  final PublishStaffShiftsUseCase _publishStaffShiftsUseCase;
  final StorageService _storageService;
  final BootstrapSchedulingSchoolTimezoneUseCase
      _bootstrapSchedulingSchoolTimezoneUseCase;

  /// Seeds the form. The staff selection is intentionally NOT seeded — the
  /// Publish screen always opens with no staff picked so the user makes that
  /// choice explicitly (this cubit is registered as a factory, so each screen
  /// entry starts from the empty [PublishShiftsState]).
  void init({DateTime? initialUntilDate}) {
    emit(state.copyWith(untilDate: initialUntilDate));
    // ignore: discarded_futures
    _bootstrapSchedulingSchoolTimezoneUseCase();
  }

  void selectMode(PublishMode mode) {
    emit(state.copyWith(mode: mode));
  }

  void setSelectedStaffCodes(List<String> codes) {
    emit(state.copyWith(selectedStaffCodes: codes));
  }

  void setUntilDate(DateTime? date) {
    emit(state.copyWith(untilDate: date, clearUntilDate: date == null));
  }

  /// [totalEligibleStaffCount] is the size of the full staff roster offered
  /// by the multi-select (display-name mapping is a view concern; the cubit
  /// only needs the count to decide whether the selection amounts to "all").
  Future<void> publish({
    required DateTime dateRangeStart,
    required int totalEligibleStaffCount,
  }) async {
    if (!state.isFormValid) return;
    final mode = state.mode!;
    final selectedCodes = state.selectedStaffCodes;
    final isAllStaff = totalEligibleStaffCount > 0 &&
        selectedCodes.length == totalEligibleStaffCount;

    emit(
      state.copyWith(
        status: PublishShiftsStatus.submitting,
        clearError: true,
      ),
    );

    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';
      final organizationCode =
          await _storageService.getString(StorageKeys.organizationCode) ?? '';

      if (schoolCode.isEmpty || organizationCode.isEmpty) {
        emit(
          state.copyWith(
            status: PublishShiftsStatus.error,
            errorMessage: 'School context is missing. Please sign in again.',
          ),
        );
        return;
      }

      await _publishStaffShiftsUseCase(
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        dateRangeStart: dateRangeStart,
        publishAll: mode == PublishMode.all,
        publishAllStaff: isAllStaff,
        publishUntilDate: mode == PublishMode.untilDate ? state.untilDate : null,
        selectedStaffCodes: isAllStaff ? const <String>[] : selectedCodes,
      );

      if (isClosed) return;
      emit(state.copyWith(status: PublishShiftsStatus.success));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: PublishShiftsStatus.error,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  void reset() {
    emit(const PublishShiftsState());
  }
}
