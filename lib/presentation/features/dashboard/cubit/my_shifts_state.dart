part of 'my_shifts_cubit.dart';

enum _Status { initial, loading, loaded, empty, error }

class MyShiftsState extends Equatable {
  const MyShiftsState({
    this.status = _Status.initial,
    this.staffCode = '',
    this.staffName = '',
    this.designation = '',
    this.classroomLabel = '',
    this.classroomNames = const <String, String>{},
    this.shifts = const <StaffShift>[],
    this.todayShifts = const <StaffShift>[],
    this.availableHours = 0,
    this.scheduledHours = 0,
    this.unscheduledHours = 0,
    this.weekFrom,
    this.weekTo,
    this.errorMessage = '',
  });

  final _Status status;
  final String staffCode;
  final String staffName;
  final String designation;
  final String classroomLabel;

  /// Classroom code → display name, resolved from the classroom list API.
  final Map<String, String> classroomNames;

  final List<StaffShift> shifts;
  final List<StaffShift> todayShifts;

  final int availableHours;
  final int scheduledHours;
  final int unscheduledHours;

  final DateTime? weekFrom;
  final DateTime? weekTo;

  final String errorMessage;

  bool get isInitial => status == _Status.initial;
  bool get isLoading => status == _Status.loading;
  bool get isLoaded => status == _Status.loaded || status == _Status.empty;
  bool get isEmpty => status == _Status.empty;
  bool get isError => status == _Status.error;

  MyShiftsState copyWith({
    _Status? status,
    String? staffCode,
    String? staffName,
    String? designation,
    String? classroomLabel,
    Map<String, String>? classroomNames,
    List<StaffShift>? shifts,
    List<StaffShift>? todayShifts,
    int? availableHours,
    int? scheduledHours,
    int? unscheduledHours,
    DateTime? weekFrom,
    DateTime? weekTo,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MyShiftsState(
      status: status ?? this.status,
      staffCode: staffCode ?? this.staffCode,
      staffName: staffName ?? this.staffName,
      designation: designation ?? this.designation,
      classroomLabel: classroomLabel ?? this.classroomLabel,
      classroomNames: classroomNames ?? this.classroomNames,
      shifts: shifts ?? this.shifts,
      todayShifts: todayShifts ?? this.todayShifts,
      availableHours: availableHours ?? this.availableHours,
      scheduledHours: scheduledHours ?? this.scheduledHours,
      unscheduledHours: unscheduledHours ?? this.unscheduledHours,
      weekFrom: weekFrom ?? this.weekFrom,
      weekTo: weekTo ?? this.weekTo,
      errorMessage: clearError ? '' : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    staffCode,
    staffName,
    designation,
    classroomLabel,
    classroomNames,
    shifts,
    todayShifts,
    availableHours,
    scheduledHours,
    unscheduledHours,
    weekFrom,
    weekTo,
    errorMessage,
  ];
}
