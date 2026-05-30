part of 'my_day_cubit.dart';

enum MyDayStatus { initial, loading, loaded, error }

class MyDayState extends Equatable {
  const MyDayState({
    this.status = MyDayStatus.initial,
    this.todaySchedule,
    this.schoolClosed = false,
    this.errorMessage,
  });

  final MyDayStatus status;

  /// The ACTIVE schedule entry for today, or null when [schoolClosed] is true.
  final SchoolRegularScheduleDay? todaySchedule;

  /// True when today has no schedule or the schedule is not ACTIVE.
  final bool schoolClosed;

  final String? errorMessage;

  bool get isInitial => status == MyDayStatus.initial;
  bool get isLoading => status == MyDayStatus.loading;
  bool get isLoaded => status == MyDayStatus.loaded;

  MyDayState copyWith({
    MyDayStatus? status,
    SchoolRegularScheduleDay? todaySchedule,
    bool? schoolClosed,
    String? errorMessage,
    bool clearTodaySchedule = false,
  }) {
    return MyDayState(
      status: status ?? this.status,
      todaySchedule:
          clearTodaySchedule ? null : (todaySchedule ?? this.todaySchedule),
      schoolClosed: schoolClosed ?? this.schoolClosed,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, todaySchedule, schoolClosed, errorMessage];
}
