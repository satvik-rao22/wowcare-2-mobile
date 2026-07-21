import 'package:equatable/equatable.dart';

/// Lifecycle of a single materialized occurrence (Tasks API `TaskOccurrenceStatus`).
/// [cancelled] is the one-way transition from §11d; [skipped] is produced by the
/// holiday policy (§1 `holidayPolicy: SKIP`).
enum TaskOccurrenceStatus {
  scheduled('SCHEDULED'),
  active('ACTIVE'),
  cancelled('CANCELLED'),
  skipped('SKIPPED');

  const TaskOccurrenceStatus(this.value);

  final String value;

  static TaskOccurrenceStatus fromValue(String? raw) {
    final normalized = (raw ?? '').trim().toUpperCase();
    return TaskOccurrenceStatus.values.firstWhere(
      (s) => s.value == normalized,
      orElse: () => TaskOccurrenceStatus.scheduled,
    );
  }
}

/// One occurrence of a task series (Tasks API §11 `TaskOccurrenceController`).
///
/// [originalStartDate] is the occurrence's permanent identity and never moves,
/// even after a reschedule; the `scheduled*` fields are the reschedulable
/// window. Occurrence-scoped edits (§11c) touch only this row — never the
/// series, other occurrences, or other assignees.
class TaskOccurrence extends Equatable {
  const TaskOccurrence({
    required this.code,
    required this.taskCode,
    this.sequenceNumber = 0,
    required this.originalStartDate,
    this.scheduledStartDate,
    this.scheduledStartTime = '',
    this.scheduledEndTime = '',
    this.overrideTitle,
    this.overrideDescription,
    this.isModified = false,
    this.status = TaskOccurrenceStatus.scheduled,
    this.statusReason,
    this.assignmentTotal = 0,
    this.assignmentInProgress = 0,
    this.assignmentCompleted = 0,
    this.version = 0,
  });

  final String code;
  final String taskCode;
  final int sequenceNumber;

  /// Permanent identity of the occurrence — never changes on reschedule.
  final DateTime originalStartDate;

  /// The reschedulable window (defaults to the original when unmodified).
  final DateTime? scheduledStartDate;
  final String scheduledStartTime;
  final String scheduledEndTime;

  final String? overrideTitle;
  final String? overrideDescription;

  /// Flips to true the first time anything on this occurrence is overridden.
  final bool isModified;

  final TaskOccurrenceStatus status;
  final String? statusReason;

  final int assignmentTotal;
  final int assignmentInProgress;
  final int assignmentCompleted;

  final int version;

  @override
  List<Object?> get props => [
        code,
        taskCode,
        sequenceNumber,
        originalStartDate,
        scheduledStartDate,
        scheduledStartTime,
        scheduledEndTime,
        overrideTitle,
        overrideDescription,
        isModified,
        status,
        statusReason,
        assignmentTotal,
        assignmentInProgress,
        assignmentCompleted,
        version,
      ];
}
