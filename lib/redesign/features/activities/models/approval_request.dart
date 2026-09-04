import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/activities/models/activity_kind.dart';

/// What a director did with one card in the queue (8e).
enum ApprovalDecision {
  approved,
  rejected;

  bool get isApproved => this == ApprovalDecision.approved;
}

/// One card waiting for a signature (8e).
///
/// The same filtered feed call the pink banner counts, drawn as rows with
/// the two keys under each. Nothing is deleted here: rejecting keeps the
/// card and locks it.
@immutable
class ApprovalRequest extends Equatable {
  const ApprovalRequest({
    required this.id,
    required this.kind,
    required this.studentName,
    required this.timeLabel,
    required this.loggedBy,
    required this.body,
    this.decision,
  });

  final String id;
  final ActivityKind kind;
  final String studentName;

  /// "1:10 pm".
  final String timeLabel;
  final String loggedBy;
  final String body;

  /// Null until the director has decided. The row keeps its place either
  /// way, so the queue never jumps under a thumb.
  final ApprovalDecision? decision;

  bool get isDone => decision != null;

  /// "Micah Bell · 1:10 pm · Dana Whitfield".
  String get metaLine => '$studentName · $timeLabel · $loggedBy';

  ApprovalRequest decided(ApprovalDecision decision) => ApprovalRequest(
    id: id,
    kind: kind,
    studentName: studentName,
    timeLabel: timeLabel,
    loggedBy: loggedBy,
    body: body,
    decision: decision,
  );

  @override
  List<Object?> get props => <Object?>[
    id,
    kind,
    studentName,
    timeLabel,
    loggedBy,
    body,
    decision,
  ];
}
