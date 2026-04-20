import 'package:equatable/equatable.dart';

class ClassroomDetails extends Equatable {
  const ClassroomDetails({
    required this.code,
    required this.name,
    required this.capacity,
    required this.studentsPerTeacher,
    required this.minAgeYear,
    required this.minAgeMonths,
    required this.maxAgeYear,
    required this.maxAgeMonths,
    required this.type,
    required this.school,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedBy,
    required this.updatedAt,
  });

  final String code;
  final String name;
  final int capacity;
  final int studentsPerTeacher;
  final int minAgeYear;
  final int minAgeMonths;
  final int maxAgeYear;
  final int maxAgeMonths;
  final String type;
  final String school;
  final String status;
  final String createdBy;
  final DateTime? createdAt;
  final String updatedBy;
  final DateTime? updatedAt;

  String get ageRangeLabel =>
      '$minAgeYear y $minAgeMonths m - $maxAgeYear y $maxAgeMonths m';

  @override
  List<Object?> get props => [
        code,
        name,
        capacity,
        studentsPerTeacher,
        minAgeYear,
        minAgeMonths,
        maxAgeYear,
        maxAgeMonths,
        type,
        school,
        status,
        createdBy,
        createdAt,
        updatedBy,
        updatedAt,
      ];
}
