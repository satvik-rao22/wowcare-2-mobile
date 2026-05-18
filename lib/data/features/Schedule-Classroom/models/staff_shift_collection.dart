import '../../../../domain/features/staff_scheduling/entities/staff_shift.dart';

class StaffShiftCollection {
  String? shiftCode;
  String staffCode = '';
  String staffFirstName = '';
  String staffLastName = '';
  String classroomCode = '';
  String schoolCode = '';
  String organizationCode = '';
  String shiftDate = '';
  String startTime = '';
  String endTime = '';
  String? breakStartTime;
  String? breakEndTime;
  String shiftStatus = 'PUBLISHED';
  bool publish = true;
  bool repeat = false;
  bool overrideConflicts = true;
  bool forceAdd = true;
  String? notes;
  String? seriesCode;
  double availableHours = 0.0;
  double scheduledHours = 0.0;
  double unscheduledHours = 0.0;
  String image = '';

  StaffShiftCollection();

  factory StaffShiftCollection.fromMap(
    Map<String, dynamic> map, {
    String? code,
  }) {
    return StaffShiftCollection()
      ..shiftCode = code ?? map['shiftCode'] as String?
      ..staffCode = map['staffCode'] as String? ?? ''
      ..staffFirstName = map['staffFirstName'] as String? ?? ''
      ..staffLastName = map['staffLastName'] as String? ?? ''
      ..classroomCode = map['classroomCode'] as String? ?? ''
      ..schoolCode = map['schoolCode'] as String? ?? ''
      ..organizationCode = map['organizationCode'] as String? ?? ''
      ..shiftDate = map['shiftDate'] as String? ?? ''
      ..startTime = map['startTime'] as String? ?? ''
      ..endTime = map['endTime'] as String? ?? ''
      ..breakStartTime = map['breakStartTime'] as String?
      ..breakEndTime = map['breakEndTime'] as String?
      ..shiftStatus = map['shiftStatus'] as String? ?? 'PUBLISHED'
      ..publish = map['publish'] as bool? ?? true
      ..repeat = map['repeat'] as bool? ?? false
      ..overrideConflicts = map['overrideConflicts'] as bool? ?? true
      ..forceAdd =
          map['forceAdd'] as bool? ?? map['forceAdded'] as bool? ?? true
      ..notes = map['notes'] as String?
      ..seriesCode = map['seriesCode'] as String?
      ..availableHours = (map['availableHours'] as num?)?.toDouble() ?? 0.0
      ..scheduledHours = (map['scheduledHours'] as num?)?.toDouble() ?? 0.0
      ..unscheduledHours = (map['unscheduledHours'] as num?)?.toDouble() ?? 0.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'shiftCode': shiftCode,
      'staffCode': staffCode,
      'staffFirstName': staffFirstName,
      'staffLastName': staffLastName,
      'classroomCode': classroomCode,
      'schoolCode': schoolCode,
      'organizationCode': organizationCode,
      'shiftDate': shiftDate,
      'startTime': startTime,
      'endTime': endTime,
      'breakStartTime': breakStartTime,
      'breakEndTime': breakEndTime,
      'shiftStatus': shiftStatus,
      'publish': publish,
      'repeat': repeat,
      'overrideConflicts': overrideConflicts,
      'forceAdded': forceAdd,
      'notes': notes,
      'seriesCode': seriesCode,
      'availableHours': availableHours,
      'scheduledHours': scheduledHours,
      'unscheduledHours': unscheduledHours,
    };
  }

  StaffShiftEntity toEntity() {
    return StaffShiftEntity(
      shiftCode: shiftCode ?? '',
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
      forceAdded: forceAdd,
      seriesCode: seriesCode,
      notes: notes,
      availableHours: availableHours,
      scheduledHours: scheduledHours,
      unscheduledHours: unscheduledHours,
      image: image,
    );
  }
}
