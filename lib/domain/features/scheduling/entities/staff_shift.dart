import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// A single staff shift returned by `GET /api/v1/staff/staff-shifts`.
class StaffShift extends Equatable {
  const StaffShift({
    required this.shiftCode,
    required this.staffCode,
    required this.classroomCode,
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
    this.breakStartTime,
    this.breakEndTime,
    this.classroomName = '',
    this.staffName = '',
    this.notes,
    this.isPublished = false,
    this.seriesCode,
    this.isRecurring = false,
  });

  final String shiftCode;
  final String staffCode;
  final String classroomCode;
  final String classroomName;
  final String staffName;
  final DateTime shiftDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final TimeOfDay? breakStartTime;
  final TimeOfDay? breakEndTime;
  final String? notes;
  final bool isPublished;
  final String? seriesCode;
  final bool isRecurring;

  @override
  List<Object?> get props => [
        shiftCode,
        staffCode,
        classroomCode,
        classroomName,
        staffName,
        shiftDate,
        startTime,
        endTime,
        breakStartTime,
        breakEndTime,
        notes,
        isPublished,
        seriesCode,
        isRecurring,
      ];
}

/// Request body for `POST /api/v1/staff-shifts`. Mirrors the swagger contract.
class StaffShiftCreateRequest extends Equatable {
  const StaffShiftCreateRequest({
    required this.staffCode,
    required this.classroomCode,
    required this.schoolCode,
    required this.organizationCode,
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
    this.breakStartTime,
    this.breakEndTime,
    this.publish = false,
    this.repeat = false,
    this.repeatDays = const <int>[],
    this.repeatUntilDate,
    this.overrideConflicts = false,
    this.forceAdd = false,
    this.notes,
  });

  final String staffCode;
  final String classroomCode;
  final String schoolCode;
  final String organizationCode;
  final DateTime shiftDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final TimeOfDay? breakStartTime;
  final TimeOfDay? breakEndTime;
  final bool publish;
  final bool repeat;
  /// 1=Monday … 7=Sunday (matches `java.time.DayOfWeek.getValue()`).
  final List<int> repeatDays;
  final DateTime? repeatUntilDate;
  final bool overrideConflicts;
  final bool forceAdd;
  final String? notes;

  StaffShiftCreateRequest copyWith({
    bool? overrideConflicts,
    bool? forceAdd,
    bool? publish,
  }) {
    return StaffShiftCreateRequest(
      staffCode: staffCode,
      classroomCode: classroomCode,
      schoolCode: schoolCode,
      organizationCode: organizationCode,
      shiftDate: shiftDate,
      startTime: startTime,
      endTime: endTime,
      breakStartTime: breakStartTime,
      breakEndTime: breakEndTime,
      publish: publish ?? this.publish,
      repeat: repeat,
      repeatDays: repeatDays,
      repeatUntilDate: repeatUntilDate,
      overrideConflicts: overrideConflicts ?? this.overrideConflicts,
      forceAdd: forceAdd ?? this.forceAdd,
      notes: notes,
    );
  }

  @override
  List<Object?> get props => [
        staffCode,
        classroomCode,
        schoolCode,
        organizationCode,
        shiftDate,
        startTime,
        endTime,
        breakStartTime,
        breakEndTime,
        publish,
        repeat,
        repeatDays,
        repeatUntilDate,
        overrideConflicts,
        forceAdd,
        notes,
      ];
}

/// Result returned by `POST /api/v1/staff-shifts`.
class StaffShiftCreateResult extends Equatable {
  const StaffShiftCreateResult({
    required this.createdCount,
    required this.skippedCount,
    required this.overriddenCount,
    this.seriesCode,
    this.createdShiftCodes = const <String>[],
    this.skippedDates = const <DateTime>[],
    this.overriddenDates = const <DateTime>[],
    this.warnings = const <String>[],
  });

  final int createdCount;
  final int skippedCount;
  final int overriddenCount;
  final String? seriesCode;
  final List<String> createdShiftCodes;
  final List<DateTime> skippedDates;
  final List<DateTime> overriddenDates;
  final List<String> warnings;

  @override
  List<Object?> get props => [
        createdCount,
        skippedCount,
        overriddenCount,
        seriesCode,
        createdShiftCodes,
        skippedDates,
        overriddenDates,
        warnings,
      ];
}
