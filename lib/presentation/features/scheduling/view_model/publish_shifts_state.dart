part of 'publish_shifts_cubit.dart';

enum PublishMode { untilDate, all }

enum PublishShiftsStatus { idle, submitting, success, error }

class PublishShiftsState extends Equatable {
  const PublishShiftsState({
    this.status = PublishShiftsStatus.idle,
    this.errorMessage,
    this.mode,
    this.selectedStaffCodes = const <String>[],
    this.untilDate,
  });

  final PublishShiftsStatus status;
  final String? errorMessage;
  final PublishMode? mode;
  final List<String> selectedStaffCodes;
  final DateTime? untilDate;

  bool get isSubmitting => status == PublishShiftsStatus.submitting;

  // Publish stays disabled until at least one staff is picked, a mode is
  // chosen, and (for "Until Date") a date is set.
  bool get isFormValid {
    if (selectedStaffCodes.isEmpty) return false;
    if (mode == null) return false;
    if (mode == PublishMode.untilDate && untilDate == null) return false;
    return true;
  }

  PublishShiftsState copyWith({
    PublishShiftsStatus? status,
    String? errorMessage,
    bool clearError = false,
    PublishMode? mode,
    List<String>? selectedStaffCodes,
    DateTime? untilDate,
    bool clearUntilDate = false,
  }) {
    return PublishShiftsState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      mode: mode ?? this.mode,
      selectedStaffCodes: selectedStaffCodes ?? this.selectedStaffCodes,
      untilDate: clearUntilDate ? null : (untilDate ?? this.untilDate),
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        mode,
        selectedStaffCodes,
        untilDate,
      ];
}
