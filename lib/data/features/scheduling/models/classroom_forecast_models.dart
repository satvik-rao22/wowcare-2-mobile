import 'package:flutter/material.dart';

import '../../../../core/util/app_time.dart';
import '../../../../domain/features/scheduling/entities/classroom_forecast_block.dart';
import 'scheduling_json_parsing.dart';
import 'staff_shift_models.dart';

class ClassroomForecastBlockModel {
  const ClassroomForecastBlockModel({
    required this.blockDate,
    required this.blockStart,
    required this.blockEnd,
    required this.classroomCode,
    required this.blockStatus,
    this.expectedStudents = 0,
    this.ratioRule = 0,
    this.requiredStaff = 0,
    this.scheduledStaff = 0,
    this.withinMonitoringWindow = true,
    this.staffShiftCodes = const <String>[],
  });

  final String blockDate;
  final TimeOfDayModel blockStart;
  final TimeOfDayModel blockEnd;
  final String classroomCode;
  final String blockStatus;
  final int expectedStudents;
  final int ratioRule;
  final int requiredStaff;
  final int scheduledStaff;
  final bool withinMonitoringWindow;
  final List<String> staffShiftCodes;

  factory ClassroomForecastBlockModel.fromJson(Map<String, dynamic> json) {
    final start = TimeOfDayModel.tryParse(json['blockStart']);
    final end = TimeOfDayModel.tryParse(json['blockEnd']);
    if (start == null || end == null) {
      throw const FormatException('Forecast block missing blockStart/blockEnd');
    }
    final codesRaw = json['staffShiftCodes'];
    final codes = codesRaw is List
        ? codesRaw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : const <String>[];

    return ClassroomForecastBlockModel(
      blockDate: SchedulingJsonParsing.string(json['blockDate']),
      blockStart: start,
      blockEnd: end,
      classroomCode: SchedulingJsonParsing.string(json['classroomCode']),
      blockStatus: SchedulingJsonParsing.string(json['blockStatus']),
      expectedStudents: SchedulingJsonParsing.intValue(json['expectedStudents']),
      ratioRule: SchedulingJsonParsing.intValue(json['ratioRule']),
      requiredStaff: SchedulingJsonParsing.intValue(json['requiredStaff']),
      scheduledStaff: SchedulingJsonParsing.intValue(json['scheduledStaff']),
      withinMonitoringWindow: json['withinMonitoringWindow'] == true,
      staffShiftCodes: codes,
    );
  }

  ClassroomForecastBlock toEntity() {
    return ClassroomForecastBlock(
      blockDate: DateTime.tryParse(blockDate) ?? AppTime.today(),
      blockStart: blockStart.toTimeOfDay(),
      blockEnd: blockEnd.toTimeOfDay(),
      classroomCode: classroomCode,
      blockStatus: blockStatus,
      expectedStudents: expectedStudents,
      ratioRule: ratioRule,
      requiredStaff: requiredStaff,
      scheduledStaff: scheduledStaff,
      withinMonitoringWindow: withinMonitoringWindow,
      staffShiftCodes: staffShiftCodes,
    );
  }
}

/// Formats [TimeOfDay] as `HH:mm` for forecast request bodies.
String formatForecastClockTime(TimeOfDay time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

class ClassroomForecastRequestModel {
  ClassroomForecastRequestModel({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.classroomCodes,
  });

  final String date;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final List<String> classroomCodes;

  Map<String, dynamic> toJson() => {
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'durationMinutes': durationMinutes,
        'classroomCodes': classroomCodes,
      };
}

class ClassroomForecastRangeRequestModel {
  ClassroomForecastRangeRequestModel({
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.classroomCodes,
  });

  final String startDate;
  final String endDate;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final List<String> classroomCodes;

  Map<String, dynamic> toJson() => {
        'startDate': startDate,
        'endDate': endDate,
        'startTime': startTime,
        'endTime': endTime,
        'durationMinutes': durationMinutes,
        'classroomCodes': classroomCodes,
      };
}
