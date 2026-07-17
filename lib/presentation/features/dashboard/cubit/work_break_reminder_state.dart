part of 'work_break_reminder_cubit.dart';

enum WorkBreakReminderStatus { initial, loading, success, failure }

class WorkBreakReminderState extends Equatable {
  const WorkBreakReminderState({
    this.status = WorkBreakReminderStatus.initial,
    this.enabled = false,
    this.message,
  });

  final WorkBreakReminderStatus status;
  final bool enabled;
  final String? message;

  bool get isInitial => status == WorkBreakReminderStatus.initial;
  bool get isLoading => status == WorkBreakReminderStatus.loading;
  bool get isSuccess => status == WorkBreakReminderStatus.success;
  bool get isFailure => status == WorkBreakReminderStatus.failure;

  WorkBreakReminderState copyWith({
    WorkBreakReminderStatus? status,
    bool? enabled,
    String? message,
  }) {
    return WorkBreakReminderState(
      status: status ?? this.status,
      enabled: enabled ?? this.enabled,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, enabled, message];
}
