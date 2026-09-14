part of 'scheduling_cubit.dart';

// `schedulingSchoolToday()` is imported via `scheduling_cubit.dart`.

@immutable
class SchedulingState extends Equatable {
  const SchedulingState({
    required this.selectedDay,
    required this.classroomFilter,
    required this.viewMode,
    required this.classrooms,
    this.isLoading = false,
    this.errorMessage,
    this.staffSignInStatusByCode = const <String, String>{},
  });

  factory SchedulingState.initial() {
    return SchedulingState(
      selectedDay: schedulingSchoolToday(),
      classroomFilter: null,
      viewMode: SchedulingViewMode.week,
      classrooms: const <ClassroomDaySchedule>[],
      isLoading: true,
    );
  }

  final DateTime selectedDay;
  final SchedulingViewMode viewMode;

  /// Selected classroom name from filter; null = all.
  final String? classroomFilter;

  /// All classroom schedules for [selectedDay]. Each entry carries its staff
  /// list so a row can expand inline.
  final List<ClassroomDaySchedule> classrooms;
  final bool isLoading;
  final String? errorMessage;

  /// Today's sign-in status keyed by staffCode, resolved via the bulk POST
  /// `/staff-attendance/sign-in/status`. Used to colour the avatar dot on
  /// each staff row (SIGNED_IN → green, ABSENT → red).
  final Map<String, String> staffSignInStatusByCode;

  List<ClassroomDaySchedule> get filteredClassrooms {
    final String? f = classroomFilter;
    if (f == null || f.isEmpty) return classrooms;
    return classrooms
        .where((c) => c.classroomName.toLowerCase() == f.toLowerCase())
        .toList(growable: false);
  }

  SchedulingState copyWith({
    DateTime? selectedDay,
    Object? classroomFilter = _noChange,
    SchedulingViewMode? viewMode,
    List<ClassroomDaySchedule>? classrooms,
    bool? isLoading,
    String? errorMessage,
    Map<String, String>? staffSignInStatusByCode,
  }) {
    return SchedulingState(
      selectedDay: selectedDay ?? this.selectedDay,
      classroomFilter: identical(classroomFilter, _noChange)
          ? this.classroomFilter
          : classroomFilter as String?,
      viewMode: viewMode ?? this.viewMode,
      classrooms: classrooms ?? this.classrooms,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      staffSignInStatusByCode:
          staffSignInStatusByCode ?? this.staffSignInStatusByCode,
    );
  }

  @override
  List<Object?> get props => [
    selectedDay,
    classroomFilter,
    viewMode,
    classrooms,
    isLoading,
    errorMessage,
    staffSignInStatusByCode,
  ];
}

const Object _noChange = Object();
