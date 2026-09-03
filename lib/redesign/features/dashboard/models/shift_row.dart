import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// One classroom's shift today (3A2's Classroom shifts).
@immutable
class ShiftRow extends Equatable {
  const ShiftRow({
    required this.classroomName,
    required this.window,
    required this.staffNeeded,
    required this.staffScheduled,
    this.staffNames,
  });

  final String classroomName;

  /// "7:30 – 16:00".
  final String window;

  final int staffNeeded;
  final int staffScheduled;

  /// "Dana W., Ravi S.". Null on an open shift.
  final String? staffNames;

  bool get isFilled => staffScheduled >= staffNeeded;

  @override
  List<Object?> get props => [
    classroomName,
    window,
    staffNeeded,
    staffScheduled,
    staffNames,
  ];
}
