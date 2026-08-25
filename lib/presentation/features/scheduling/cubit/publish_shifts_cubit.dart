import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_error_handler.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/scheduling/usecases/publish_staff_shifts_usecase.dart';

part 'publish_shifts_state.dart';

/// Backs the Publish Shifts screen — single-shot POST to
/// `/api/v1/staff-shifts/publish`. Resolves school/org context from storage so
/// the screen only deals with user input (staff codes + mode + date).
class PublishShiftsCubit extends Cubit<PublishShiftsState> {
  PublishShiftsCubit({
    required PublishStaffShiftsUseCase publishStaffShiftsUseCase,
    required StorageService storageService,
  }) : _publishStaffShiftsUseCase = publishStaffShiftsUseCase,
       _storageService = storageService,
       super(const PublishShiftsState());

  final PublishStaffShiftsUseCase _publishStaffShiftsUseCase;
  final StorageService _storageService;

  Future<void> publish({
    required DateTime dateRangeStart,
    required bool publishAll,
    required bool publishAllStaff,
    DateTime? publishUntilDate,
    List<String> selectedStaffCodes = const <String>[],
  }) async {
    emit(
      state.copyWith(status: PublishShiftsStatus.submitting, clearError: true),
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
        publishAll: publishAll,
        publishAllStaff: publishAllStaff,
        publishUntilDate: publishUntilDate,
        selectedStaffCodes: selectedStaffCodes,
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
