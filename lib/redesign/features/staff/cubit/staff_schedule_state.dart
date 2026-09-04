part of 'staff_schedule_cubit.dart';

/// [denied] is what a staff member gets: a work schedule is Admin-only.
enum StaffScheduleStatus { loading, editing, saving, saved, failed, denied }

@immutable
class StaffScheduleState extends Equatable {
  const StaffScheduleState({
    required this.staffId,
    required this.lens,
    this.status = StaffScheduleStatus.loading,
    this.name = '',
    this.week = const <StaffShift>[],
    this.error,
  });

  final String staffId;
  final StaffLens lens;
  final StaffScheduleStatus status;

  /// Whose week it is, for the header and the toast.
  final String name;

  final List<StaffShift> week;

  /// The one thing that can be wrong with a week: the order of a shift, or a
  /// break that falls outside it.
  final String? error;

  bool get isLoading => status == StaffScheduleStatus.loading;
  bool get isSaving => status == StaffScheduleStatus.saving;
  bool get isSaved => status == StaffScheduleStatus.saved;
  bool get isDenied => status == StaffScheduleStatus.denied;
  bool get isFailed => status == StaffScheduleStatus.failed;

  /// What the week adds up to, breaks taken out.
  int get workedMinutes =>
      week.fold(0, (total, shift) => total + shift.workedMinutes);

  StaffScheduleState copyWith({
    StaffScheduleStatus? status,
    String? name,
    List<StaffShift>? week,
    String? error,
    bool clearError = false,
  }) => StaffScheduleState(
    staffId: staffId,
    lens: lens,
    status: status ?? this.status,
    name: name ?? this.name,
    week: week ?? this.week,
    error: clearError ? null : error ?? this.error,
  );

  StaffScheduleState cleared() =>
      error == null ? this : copyWith(clearError: true);

  @override
  List<Object?> get props => [staffId, lens, status, name, week, error];
}
