import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum ShiftValidationErrorCode {
  requiredFieldMissing,
  invalidShiftRange,
  invalidBreakRange,
  repeatUntilMissing,
  repeatUntilBeforeStart,
  absentStaff,
  outsideAvailability,
  conflictsDetected,
}

class ShiftValidationError extends Equatable {
  const ShiftValidationError({
    required this.code,
    required this.message,
    this.meta = const <String, Object?>{},
  });

  final ShiftValidationErrorCode code;
  final String message;
  final Map<String, Object?> meta;

  @override
  List<Object?> get props => [code, message, meta];
}

class ShiftConflict extends Equatable {
  const ShiftConflict({
    required this.shiftCode,
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
    required this.classroomCode,
    required this.type,
  });

  final String shiftCode;
  final DateTime shiftDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String classroomCode;
  final ShiftConflictType type;

  @override
  List<Object?> get props => [
    shiftCode,
    shiftDate,
    startTime,
    endTime,
    classroomCode,
    type,
  ];
}

enum ShiftConflictType { duplicate, overlapSameClassroom, overbooking }

class ShiftValidationResult extends Equatable {
  const ShiftValidationResult({
    required this.errors,
    required this.conflicts,
    required this.requiresForceAddConfirmation,
    required this.requiresOverrideConfirmation,
    required this.affectedDates,
  });

  final List<ShiftValidationError> errors;
  final List<ShiftConflict> conflicts;

  /// Single-shift only: outside availability is allowed only after explicit confirm.
  final bool requiresForceAddConfirmation;

  /// Conflicts exist and require explicit override confirm.
  final bool requiresOverrideConfirmation;

  /// Dates that the validation ran for (single: 1 date, recurring: N dates).
  final List<DateTime> affectedDates;

  bool get isValid => errors.isEmpty;

  @override
  List<Object?> get props => [
    errors,
    conflicts,
    requiresForceAddConfirmation,
    requiresOverrideConfirmation,
    affectedDates,
  ];
}

class ShiftDraft extends Equatable {
  const ShiftDraft({
    required this.staffCode,
    required this.classroomCode,
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
    this.breakStartTime,
    this.breakEndTime,
    this.repeatDayCodes = const [],
    this.repeatUntilDate,
    required this.isRecurring,
    required this.isSingleShift,
  });

  final String staffCode;
  final String classroomCode;
  final DateTime shiftDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final TimeOfDay? breakStartTime;
  final TimeOfDay? breakEndTime;

  /// ISO weekday codes (1=Mon..7=Sun) for recurring series.
  final List<int> repeatDayCodes;
  final DateTime? repeatUntilDate;

  final bool isRecurring;
  final bool isSingleShift;

  @override
  List<Object?> get props => [
    staffCode,
    classroomCode,
    shiftDate,
    startTime,
    endTime,
    breakStartTime,
    breakEndTime,
    repeatDayCodes,
    repeatUntilDate,
    isRecurring,
    isSingleShift,
  ];
}

