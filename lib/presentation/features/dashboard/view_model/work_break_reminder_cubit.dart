import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';

part 'work_break_reminder_state.dart';

/// Manages work break reminder toggle state and API calls.
///
/// State transitions:
/// - [initial] → [loading] → [success] or [failure]
/// - [success] or [failure] → [loading] → [success] or [failure] (on retry)
class WorkBreakReminderCubit extends Cubit<WorkBreakReminderState> {
  WorkBreakReminderCubit({required StaffRepository staffRepository})
    : _staffRepository = staffRepository,
      super(const WorkBreakReminderState());

  final StaffRepository _staffRepository;
  bool _isProcessing = false;

  /// Toggles the work break reminder for the logged-in staff member.
  ///
  /// [currentEnabled] is the current toggle state; the API call inverts it.
  /// [staffCode] is the logged-in staff member's code.
  Future<void> toggleReminder({
    required String staffCode,
    required bool currentEnabled,
  }) async {
    if (_isProcessing) return;
    _isProcessing = true;

    final newEnabled = !currentEnabled;

    emit(state.copyWith(status: WorkBreakReminderStatus.loading));

    try {
      final result = await _staffRepository.updateWorkBreakReminder(
        staffCode: staffCode,
        enabled: newEnabled,
      );

      AppLogger.d('[WorkBreakReminderCubit] Reminder toggled: enabled=$result');

      emit(
        state.copyWith(
          status: WorkBreakReminderStatus.success,
          enabled: result,
          message: 'Reminder preference updated',
        ),
      );
    } catch (e) {
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);
      AppLogger.e('[WorkBreakReminderCubit] Toggle failed: $e');

      emit(
        state.copyWith(
          status: WorkBreakReminderStatus.failure,
          message: errorMessage,
          enabled: currentEnabled,
        ),
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// Resets state to initial.
  void reset() {
    emit(const WorkBreakReminderState());
  }
}
