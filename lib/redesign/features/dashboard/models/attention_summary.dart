import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;

/// The six (or seven) cards the attention deck can carry, in deck order.
enum AttentionKind {
  incidents,
  ratio,
  shifts,
  movements,
  documents,
  checkups,
  billing,
}

/// A classroom short of staff right now (the Ratio card's wells).
@immutable
class RatioShortfall extends Equatable {
  const RatioShortfall({
    required this.classroomCode,
    required this.classroomName,
    required this.staffPresent,
    required this.staffNeeded,
  });

  final String classroomCode;
  final String classroomName;
  final int staffPresent;

  /// How many more staff the ratio requires, not the total.
  final int staffNeeded;

  @override
  List<Object?> get props => [
    classroomCode,
    classroomName,
    staffPresent,
    staffNeeded,
  ];
}

/// A shift block that still needs staff (the Shifts card).
@immutable
class OpenShiftGap extends Equatable {
  const OpenShiftGap({
    required this.classroomCode,
    required this.classroomName,
    required this.start,
    required this.end,
    required this.staffNeeded,
    required this.staffScheduled,
  });

  final String classroomCode;
  final String classroomName;
  final TimeOfDay start;
  final TimeOfDay end;
  final int staffNeeded;
  final int staffScheduled;

  int get shortfall => staffNeeded - staffScheduled;

  @override
  List<Object?> get props => [
    classroomCode,
    classroomName,
    start,
    end,
    staffNeeded,
    staffScheduled,
  ];
}

/// Everything the "Needs your attention" deck draws, mirroring
/// `DashboardAttentionState` field for field (incidents, movements, documents,
/// checkups) plus the ratio, shift and billing figures the old attention grid
/// pulled from its sibling cubits.
///
/// The four checkup counts are the rule-0 "free" item: fetched today, drawn
/// nowhere. They get a card here.
@immutable
class AttentionSummary extends Equatable {
  const AttentionSummary({
    this.pendingIncidents = 0,
    this.ratioShortfalls = const <RatioShortfall>[],
    this.openShift,
    this.pendingMovements = 0,
    this.overdueMovements = 0,
    this.expiredStudentDocuments = 0,
    this.expiringStudentDocuments = 0,
    this.expiredStaffDocuments = 0,
    this.expiringStaffDocuments = 0,
    this.overdueStudentCheckups = 0,
    this.missingStudentCheckups = 0,
    this.overdueStaffCheckups = 0,
    this.missingStaffCheckups = 0,
    this.outstandingAmount = 0,
    this.outstandingPercent = 0,
  });

  final int pendingIncidents;
  final List<RatioShortfall> ratioShortfalls;
  final OpenShiftGap? openShift;
  final int pendingMovements;
  final int overdueMovements;
  final int expiredStudentDocuments;
  final int expiringStudentDocuments;
  final int expiredStaffDocuments;
  final int expiringStaffDocuments;
  final int overdueStudentCheckups;
  final int missingStudentCheckups;
  final int overdueStaffCheckups;
  final int missingStaffCheckups;

  /// This month's outstanding balance, and its share of what was invoiced.
  final double outstandingAmount;
  final int outstandingPercent;

  int get expiredDocuments => expiredStudentDocuments + expiredStaffDocuments;
  int get expiringDocuments =>
      expiringStudentDocuments + expiringStaffDocuments;
  int get overdueCheckups => overdueStudentCheckups + overdueStaffCheckups;
  int get missingCheckups => missingStudentCheckups + missingStaffCheckups;

  /// The cards worth showing. A card with nothing behind it is left out
  /// rather than drawn at zero; nothing is ever dismissed by the user.
  List<AttentionKind> get kinds => <AttentionKind>[
    if (pendingIncidents > 0) AttentionKind.incidents,
    if (ratioShortfalls.isNotEmpty) AttentionKind.ratio,
    if (openShift != null) AttentionKind.shifts,
    if (pendingMovements + overdueMovements > 0) AttentionKind.movements,
    if (expiredDocuments + expiringDocuments > 0) AttentionKind.documents,
    if (overdueCheckups + missingCheckups > 0) AttentionKind.checkups,
    if (outstandingAmount > 0) AttentionKind.billing,
  ];

  bool get isEmpty => kinds.isEmpty;

  @override
  List<Object?> get props => [
    pendingIncidents,
    ratioShortfalls,
    openShift,
    pendingMovements,
    overdueMovements,
    expiredStudentDocuments,
    expiringStudentDocuments,
    expiredStaffDocuments,
    expiringStaffDocuments,
    overdueStudentCheckups,
    missingStudentCheckups,
    overdueStaffCheckups,
    missingStaffCheckups,
    outstandingAmount,
    outstandingPercent,
  ];
}
