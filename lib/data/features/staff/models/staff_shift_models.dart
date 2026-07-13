import 'package:equatable/equatable.dart';

import 'staff_models.dart';

int _jsonToInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is num) return value.round();
  return int.tryParse(value.toString()) ?? 0;
}

class StaffShiftItemModel extends Equatable {
  const StaffShiftItemModel({
    required this.shiftCode,
    required this.staffCode,
    required this.staffFirstName,
    required this.staffLastName,
    required this.classroomCode,
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
    this.breakStartTime,
    this.breakEndTime,
    required this.availableHours,
    required this.scheduledHours,
    required this.unscheduledHours,
  });

  final String shiftCode;
  final String staffCode;
  final String staffFirstName;
  final String staffLastName;
  final String classroomCode;
  final String shiftDate;
  final StaffProfileTimeModel startTime;
  final StaffProfileTimeModel endTime;
  final StaffProfileTimeModel? breakStartTime;
  final StaffProfileTimeModel? breakEndTime;
  final int availableHours;
  final int scheduledHours;
  final int unscheduledHours;

  factory StaffShiftItemModel.fromJson(Map<String, dynamic> json) {
    return StaffShiftItemModel(
      shiftCode: json['shiftCode'] as String? ?? '',
      staffCode: json['staffCode'] as String? ?? '',
      staffFirstName: json['staffFirstName'] as String? ?? '',
      staffLastName: json['staffLastName'] as String? ?? '',
      classroomCode: json['classroomCode'] as String? ?? '',
      shiftDate: json['shiftDate'] as String? ?? '',
      startTime: StaffProfileTimeModel.fromJson(json['startTime']),
      endTime: StaffProfileTimeModel.fromJson(json['endTime']),
      breakStartTime: json['breakStartTime'] != null
          ? StaffProfileTimeModel.fromJson(json['breakStartTime'])
          : null,
      breakEndTime: json['breakEndTime'] != null
          ? StaffProfileTimeModel.fromJson(json['breakEndTime'])
          : null,
      availableHours: _jsonToInt(json['availableHours']),
      scheduledHours: _jsonToInt(json['scheduledHours']),
      unscheduledHours: _jsonToInt(json['unscheduledHours']),
    );
  }

  @override
  List<Object?> get props => [
        shiftCode,
        staffCode,
        staffFirstName,
        staffLastName,
        classroomCode,
        shiftDate,
        startTime,
        endTime,
        breakStartTime,
        breakEndTime,
        availableHours,
        scheduledHours,
        unscheduledHours,
      ];
}

class StaffShiftsPageModel extends Equatable {
  const StaffShiftsPageModel({required this.items});

  final List<StaffShiftItemModel> items;

  factory StaffShiftsPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final content = data['content'] as List<dynamic>? ?? const [];
    final items = content
        .map((e) => StaffShiftItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return StaffShiftsPageModel(items: items);
  }

  @override
  List<Object?> get props => [items];
}
