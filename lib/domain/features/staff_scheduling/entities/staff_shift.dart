import 'package:equatable/equatable.dart';

class StaffShiftEntity extends Equatable {
  final String shiftCode;
  final String staffCode;
  final String staffFirstName;
  final String staffLastName;
  final String classroomCode;
  final String schoolCode;
  final String organizationCode;
  final String shiftDate;
  final String startTime;
  final String endTime;
  final String? breakStartTime;
  final String? breakEndTime;
  final String shiftStatus;
  final bool forceAdded;
  final String? seriesCode;
  final String? notes;
  final double availableHours;
  final double scheduledHours;
  final String image;
  final double unscheduledHours;

  const StaffShiftEntity({
    required this.shiftCode,
    required this.staffCode,
    required this.staffFirstName,
    required this.staffLastName,
    required this.image,
    required this.classroomCode,
    required this.schoolCode,
    required this.organizationCode,
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
    this.breakStartTime,
    this.breakEndTime,
    required this.shiftStatus,
    required this.forceAdded,
    this.seriesCode,
    this.notes,
    required this.availableHours,
    required this.scheduledHours,
    required this.unscheduledHours,
  });

  String get staffFullName => '$staffFirstName $staffLastName'.trim();

  @override
  List<Object?> get props => [
    shiftCode,
    staffCode,
    staffFirstName,
    staffLastName,
    classroomCode,
    schoolCode,
    organizationCode,
    shiftDate,
    startTime,
    endTime,
    breakStartTime,
    breakEndTime,
    shiftStatus,
    forceAdded,
    seriesCode,
    notes,
    availableHours,
    scheduledHours,
    unscheduledHours,
  ];
}
