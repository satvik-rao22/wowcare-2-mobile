import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/attendance/models/clock_time.dart';

/// The whole trail a transfer leaves on a row: where it came from, where it
/// went, which stint of the day this is, when the next one is due, who moved
/// them and why.
///
/// Every field is already on `StudentAttendanceDailyItem` and
/// `StaffAttendanceDailyItem`, and no screen has ever drawn any of it.
@immutable
class TransferTrail extends Equatable {
  const TransferTrail({
    required this.fromClassroom,
    required this.toClassroom,
    required this.sequenceNumber,
    required this.totalSequenceCount,
    required this.transferTime,
    required this.transferredBy,
    required this.reason,
    this.nextActionTime,
  });

  final String fromClassroom;
  final String toClassroom;

  /// Which stint of the day this row is, and how many there are.
  final int sequenceNumber;
  final int totalSequenceCount;

  final ClockTime transferTime;

  /// When the next move is due, when there is one.
  final ClockTime? nextActionTime;

  final String transferredBy;
  final String reason;

  bool get hasNextTransfer => nextActionTime != null;

  @override
  List<Object?> get props => <Object?>[
    fromClassroom,
    toClassroom,
    sequenceNumber,
    totalSequenceCount,
    transferTime,
    nextActionTime,
    transferredBy,
    reason,
  ];
}
