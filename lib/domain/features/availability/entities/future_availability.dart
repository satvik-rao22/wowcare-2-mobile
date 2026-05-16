enum FutureAvailabilityShift { fullDay, morning, afternoon, all }

class FutureAvailabilityGrid {
  const FutureAvailabilityGrid({
    required this.schoolCode,
    required this.startDate,
    required this.endDate,
    required this.classrooms,
    required this.availability,
  });

  final String schoolCode;
  final DateTime startDate;
  final DateTime endDate;
  final List<FutureAvailabilityClassroom> classrooms;
  final List<FutureAvailabilityEntry> availability;
}

class FutureAvailabilityClassroom {
  const FutureAvailabilityClassroom({
    required this.code,
    required this.name,
    required this.capacity,
  });

  final String code;
  final String name;
  final int capacity;
}

class FutureAvailabilityEntry {
  const FutureAvailabilityEntry({
    required this.classroomCode,
    required this.date,
    required this.shift,
    required this.availableSpots,
    required this.expectedStudentCount,
    required this.classroomCapacity,
    required this.confirmedMovementCount,
    required this.pendingMovementCount,
    required this.enrollmentCount,
  });

  final String classroomCode;
  final DateTime date;
  final FutureAvailabilityShift shift;
  final int availableSpots;
  final int expectedStudentCount;
  final int classroomCapacity;
  final int confirmedMovementCount;
  final int pendingMovementCount;
  final int enrollmentCount;
}
