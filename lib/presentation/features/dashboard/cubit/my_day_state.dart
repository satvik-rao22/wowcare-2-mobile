part of 'my_day_cubit.dart';

enum MyDayStatus { initial, loading, loaded, error }

class MyDayState extends Equatable {
  const MyDayState({
    this.status = MyDayStatus.initial,
    this.todaySchedule,
    this.todayWorkSchedule,
    this.todayBreakSchedule,
    this.schoolClosed = false,
    this.errorMessage,
  });

  final MyDayStatus status;

  /// The ACTIVE school schedule entry for today, or null when [schoolClosed] is true.
  final SchoolRegularScheduleDay? todaySchedule;

  /// The staff member's own work schedule for today (from their profile).
  /// When non-null, the countdown uses this instead of [todaySchedule].
  final StaffProfileWorkSchedule? todayWorkSchedule;

  /// The staff member's break schedule for today (from their profile).
  final StaffProfileBreakSchedule? todayBreakSchedule;

  /// True when today has no school schedule or the schedule is not ACTIVE.
  final bool schoolClosed;

  final String? errorMessage;

  bool get isInitial => status == MyDayStatus.initial;
  bool get isLoading => status == MyDayStatus.loading;
  bool get isLoaded => status == MyDayStatus.loaded;

  MyDayState copyWith({
    MyDayStatus? status,
    SchoolRegularScheduleDay? todaySchedule,
    StaffProfileWorkSchedule? todayWorkSchedule,
    StaffProfileBreakSchedule? todayBreakSchedule,
    bool? schoolClosed,
    String? errorMessage,
    bool clearTodaySchedule = false,
    bool clearWorkSchedule = false,
    bool clearBreakSchedule = false,
  }) {
    return MyDayState(
      status: status ?? this.status,
      todaySchedule:
          clearTodaySchedule ? null : (todaySchedule ?? this.todaySchedule),
      todayWorkSchedule: clearWorkSchedule
          ? null
          : (todayWorkSchedule ?? this.todayWorkSchedule),
      todayBreakSchedule: clearBreakSchedule
          ? null
          : (todayBreakSchedule ?? this.todayBreakSchedule),
      schoolClosed: schoolClosed ?? this.schoolClosed,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        todaySchedule,
        todayWorkSchedule,
        todayBreakSchedule,
        schoolClosed,
        errorMessage,
      ];
}
