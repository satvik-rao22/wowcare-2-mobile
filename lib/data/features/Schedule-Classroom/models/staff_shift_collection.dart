import 'package:isar/isar.dart';
import '../../../../core/util/isar_utils.dart';
import '../../../../domain/features/staff_scheduling/entities/staff_shift.dart';

part 'staff_shift_collection.g.dart';

@collection
class StaffShiftCollection {
  Id get isarId =>
      fastHash(shiftCode ?? '${staffCode}_${shiftDate}_${startTime}');

  String? shiftCode;
  late String staffCode;
  late String staffFirstName;
  late String staffLastName;
  late String classroomCode;
  late String schoolCode;
  late String organizationCode;
  late String shiftDate;
  late String startTime;
  late String endTime;
  String? breakStartTime;
  String? breakEndTime;
  late String shiftStatus;
  late bool publish;
  late bool repeat;
  late bool overrideConflicts;
  late bool forceAdd;
  String? notes;
  String? seriesCode;
  late double availableHours;
  late double scheduledHours;
  late double unscheduledHours;
  late String image;

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
