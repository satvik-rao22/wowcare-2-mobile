import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// One monitoring block from the classroom forecast APIs.
class ClassroomForecastBlock extends Equatable {
  const ClassroomForecastBlock({
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

  final DateTime blockDate;
  final TimeOfDay blockStart;
  final TimeOfDay blockEnd;
  final String classroomCode;
  final String blockStatus;
  final int expectedStudents;
  final int ratioRule;
  final int requiredStaff;
  final int scheduledStaff;
  final bool withinMonitoringWindow;
  final List<String> staffShiftCodes;

  @override
  List<Object?> get props => [
    blockDate,
    blockStart,
    blockEnd,
    classroomCode,
    blockStatus,
    expectedStudents,
    ratioRule,
    requiredStaff,
    scheduledStaff,
    withinMonitoringWindow,
    staffShiftCodes,
  ];
}
