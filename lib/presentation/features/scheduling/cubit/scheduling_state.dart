part of 'scheduling_cubit.dart';

@immutable
class SchedulingState extends Equatable {
  const SchedulingState({
    required this.selectedDay,
    required this.classroomFilter,
    required this.classrooms,
    this.isLoading = false,
  });

  factory SchedulingState.initial() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    return SchedulingState(
      selectedDay: today,
      classroomFilter: null,
      classrooms: const <ClassroomDaySchedule>[],
      isLoading: true,
    );
  }

  final DateTime selectedDay;

  /// Selected classroom name from filter; null = all.
  final String? classroomFilter;

  /// All classroom schedules for [selectedDay]. Each entry carries its staff
  /// list so a row can expand inline.
  final List<ClassroomDaySchedule> classrooms;
  final bool isLoading;

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
    List<ClassroomDaySchedule>? classrooms,
    bool? isLoading,
  }) {
    return SchedulingState(
      selectedDay: selectedDay ?? this.selectedDay,
      classroomFilter: identical(classroomFilter, _noChange)
          ? this.classroomFilter
          : classroomFilter as String?,
      classrooms: classrooms ?? this.classrooms,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        selectedDay,
        classroomFilter,
        classrooms,
        isLoading,
      ];
}

const Object _noChange = Object();
