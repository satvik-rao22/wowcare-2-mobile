import 'package:wowcare/domain/features/availability/entities/future_availability.dart';

class FutureAvailabilityGridModel {
  const FutureAvailabilityGridModel({
    required this.schoolCode,
    required this.startDate,
    required this.endDate,
    required this.classrooms,
    required this.availability,
  });

  final String schoolCode;
  final DateTime startDate;
  final DateTime endDate;
  final List<FutureAvailabilityClassroomModel> classrooms;
  final List<FutureAvailabilityEntryModel> availability;

  factory FutureAvailabilityGridModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    return FutureAvailabilityGridModel(
      schoolCode: (data['schoolCode'] ?? '').toString(),
      startDate: _parseDate(data['startDate']),
      endDate: _parseDate(data['endDate']),
      classrooms: ((data['classrooms'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(FutureAvailabilityClassroomModel.fromJson)
          .toList(),
      availability: ((data['availability'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(FutureAvailabilityEntryModel.fromJson)
          .toList(),
    );
  }

  factory FutureAvailabilityGridModel.fromCacheJson(Map<String, dynamic> json) {
    return FutureAvailabilityGridModel(
      schoolCode: (json['schoolCode'] ?? '').toString(),
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      classrooms: ((json['classrooms'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(FutureAvailabilityClassroomModel.fromJson)
          .toList(),
      availability: ((json['availability'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(FutureAvailabilityEntryModel.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schoolCode': schoolCode,
      'startDate': _formatDateOnly(startDate),
      'endDate': _formatDateOnly(endDate),
      'classrooms': classrooms.map((e) => e.toJson()).toList(),
      'availability': availability.map((e) => e.toJson()).toList(),
    };
  }

  FutureAvailabilityGrid toEntity() {
    return FutureAvailabilityGrid(
      schoolCode: schoolCode,
      startDate: startDate,
      endDate: endDate,
      classrooms: classrooms.map((e) => e.toEntity()).toList(),
      availability: availability.map((e) => e.toEntity()).toList(),
    );
  }
}

class FutureAvailabilityClassroomModel {
  const FutureAvailabilityClassroomModel({
    required this.code,
    required this.name,
    required this.capacity,
  });

  final String code;
  final String name;
  final int capacity;

  factory FutureAvailabilityClassroomModel.fromJson(Map<String, dynamic> json) {
    return FutureAvailabilityClassroomModel(
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      capacity: _toInt(json['capacity']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'code': code, 'name': name, 'capacity': capacity};

  FutureAvailabilityClassroom toEntity() {
    return FutureAvailabilityClassroom(code: code, name: name, capacity: capacity);
  }
}

class FutureAvailabilityEntryModel {
  const FutureAvailabilityEntryModel({
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

  factory FutureAvailabilityEntryModel.fromJson(Map<String, dynamic> json) {
    return FutureAvailabilityEntryModel(
      classroomCode: (json['classroomCode'] ?? '').toString(),
      date: _parseDate(json['date']),
      shift: _shiftFromApi((json['shift'] ?? '').toString()),
      availableSpots: _toInt(json['availableSpots']),
      expectedStudentCount: _toInt(json['expectedStudentCount']),
      classroomCapacity: _toInt(json['classroomCapacity']),
      confirmedMovementCount: _toInt(json['confirmedMovementCount']),
      pendingMovementCount: _toInt(json['pendingMovementCount']),
      enrollmentCount: _toInt(json['enrollmentCount']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'classroomCode': classroomCode,
        'date': _formatDateOnly(date),
        'shift': _shiftToApi(shift),
        'availableSpots': availableSpots,
        'expectedStudentCount': expectedStudentCount,
        'classroomCapacity': classroomCapacity,
        'confirmedMovementCount': confirmedMovementCount,
        'pendingMovementCount': pendingMovementCount,
        'enrollmentCount': enrollmentCount,
      };

  FutureAvailabilityEntry toEntity() {
    return FutureAvailabilityEntry(
      classroomCode: classroomCode,
      date: date,
      shift: shift,
      availableSpots: availableSpots,
      expectedStudentCount: expectedStudentCount,
      classroomCapacity: classroomCapacity,
      confirmedMovementCount: confirmedMovementCount,
      pendingMovementCount: pendingMovementCount,
      enrollmentCount: enrollmentCount,
    );
  }
}

DateTime _parseDate(dynamic raw) {
  final dateString = (raw ?? '').toString().trim();
  if (dateString.isEmpty) return DateTime.now();
  return DateTime.tryParse(dateString) ?? DateTime.now();
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse((value ?? '').toString()) ?? 0;
}

FutureAvailabilityShift _shiftFromApi(String shift) {
  switch (shift.trim().toUpperCase()) {
    case 'MORNING':
      return FutureAvailabilityShift.morning;
    case 'AFTERNOON':
      return FutureAvailabilityShift.afternoon;
    case 'ALL':
      return FutureAvailabilityShift.all;
    case 'FULL_DAY':
    default:
      return FutureAvailabilityShift.fullDay;
  }
}

String _shiftToApi(FutureAvailabilityShift shift) {
  switch (shift) {
    case FutureAvailabilityShift.morning:
      return 'MORNING';
    case FutureAvailabilityShift.afternoon:
      return 'AFTERNOON';
    case FutureAvailabilityShift.all:
      return 'ALL';
    case FutureAvailabilityShift.fullDay:
      return 'FULL_DAY';
  }
}

String _formatDateOnly(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
