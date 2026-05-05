import '../../../../domain/features/staff_scheduling/entities/staff_shift.dart';

class StaffShiftModel {
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

  StaffShiftModel({
    required this.shiftCode,
    required this.staffCode,
    required this.staffFirstName,
    required this.image,
    required this.staffLastName,
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

  factory StaffShiftModel.fromJson(Map<String, dynamic> json) {
    return StaffShiftModel(
      shiftCode: json['shiftCode'] as String? ?? '',
      image: json['image'] as String? ?? '',
      staffCode: json['staffCode'] as String? ?? '',
      staffFirstName: json['staffFirstName'] as String? ?? '',
      staffLastName: json['staffLastName'] as String? ?? '',
      classroomCode: json['classroomCode'] as String? ?? '',
      schoolCode: json['schoolCode'] as String? ?? '',
      organizationCode: json['organizationCode'] as String? ?? '',
      shiftDate: json['shiftDate'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      breakStartTime: json['breakStartTime'] as String?,
      breakEndTime: json['breakEndTime'] as String?,
      shiftStatus: json['shiftStatus'] as String? ?? 'PUBLISHED',
      forceAdded: json['forceAdded'] as bool? ?? false,
      seriesCode: json['seriesCode'] as String?,
      notes: json['notes'] as String?,
      availableHours: (json['availableHours'] as num?)?.toDouble() ?? 0.0,
      scheduledHours: (json['scheduledHours'] as num?)?.toDouble() ?? 0.0,
      unscheduledHours: (json['unscheduledHours'] as num?)?.toDouble() ?? 0.0,
    );
  }

  StaffShiftEntity toEntity() {
    return StaffShiftEntity(
      shiftCode: shiftCode,
      staffCode: staffCode,
      staffFirstName: staffFirstName,
      staffLastName: staffLastName,
      classroomCode: classroomCode,
      schoolCode: schoolCode,
      organizationCode: organizationCode,
      shiftDate: shiftDate,
      startTime: startTime,
      endTime: endTime,
      breakStartTime: breakStartTime,
      breakEndTime: breakEndTime,
      shiftStatus: shiftStatus,
      forceAdded: forceAdded,
      seriesCode: seriesCode,
      notes: notes,
      availableHours: availableHours,
      scheduledHours: scheduledHours,
      image: image,
      unscheduledHours: unscheduledHours,
    );
  }
}
