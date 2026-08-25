import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement.dart';

/// PRD: Pending | Approved (confirmed) | Rejected.
enum MovementWorkflowStatus { pending, confirmed, rejected }

/// Movement kinds (UI currently implements [moveToNextClassroom] only).
enum MovementType { startSchool, moveToNextClassroom, leaveSchool }

/// Column buckets on the overview (not stored on the row — derived).
enum MovementBucket { overdue, upcoming, confirmed, rejected }

class MovementItem {
  const MovementItem({
    required this.id,
    required this.name,
    this.studentCode = '',
    this.profilePhotoAssetCode,
    required this.fromClassroom,
    required this.toClassroom,
    required this.movementDate,
    this.comment = '',
    required this.workflowStatus,
    this.movementType = MovementType.moveToNextClassroom,
  });

  final int id;
  final String name;
  final String studentCode;
  final String? profilePhotoAssetCode;
  final String fromClassroom;
  final String toClassroom;
  final DateTime movementDate;
  final String comment;
  final MovementWorkflowStatus workflowStatus;
  final MovementType movementType;

  factory MovementItem.fromEntity(IndividualMovement movement) {
    return MovementItem(
      id: movement.id,
      name: movement.studentName,
      studentCode: movement.studentCode,
      profilePhotoAssetCode: movement.profilePhotoAssetCode,
      fromClassroom: movement.fromClassroomName,
      toClassroom: movement.toClassroomName,
      movementDate: movement.movementDate,
      comment: movement.comment,
      workflowStatus: _workflowStatusFromEntity(movement.status),
      movementType: _movementTypeFromEntity(movement.movementType),
    );
  }

  /// PRD buckets: Overdue/Upcoming = pending + date vs today; Confirmed/Rejected = workflow.
  MovementBucket bucketFor(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(movementDate.year, movementDate.month, movementDate.day);
    switch (workflowStatus) {
      case MovementWorkflowStatus.confirmed:
        return MovementBucket.confirmed;
      case MovementWorkflowStatus.rejected:
        return MovementBucket.rejected;
      case MovementWorkflowStatus.pending:
        if (d.isBefore(today)) return MovementBucket.overdue;
        return MovementBucket.upcoming;
    }
  }

  String get movementTypeLabel {
    switch (movementType) {
      case MovementType.startSchool:
        return 'Start School';
      case MovementType.moveToNextClassroom:
        return 'Move to Next Classroom';
      case MovementType.leaveSchool:
        return 'Leave the School';
    }
  }

  MovementItem copyWith({
    String? name,
    String? fromClassroom,
    String? toClassroom,
    DateTime? movementDate,
    String? comment,
    MovementWorkflowStatus? workflowStatus,
    MovementType? movementType,
  }) {
    return MovementItem(
      id: id,
      name: name ?? this.name,
      studentCode: studentCode,
      profilePhotoAssetCode: profilePhotoAssetCode,
      fromClassroom: fromClassroom ?? this.fromClassroom,
      toClassroom: toClassroom ?? this.toClassroom,
      movementDate: movementDate ?? this.movementDate,
      comment: comment ?? this.comment,
      workflowStatus: workflowStatus ?? this.workflowStatus,
      movementType: movementType ?? this.movementType,
    );
  }
}

MovementWorkflowStatus _workflowStatusFromEntity(
  IndividualMovementWorkflowStatus status,
) {
  switch (status) {
    case IndividualMovementWorkflowStatus.confirmed:
      return MovementWorkflowStatus.confirmed;
    case IndividualMovementWorkflowStatus.rejected:
      return MovementWorkflowStatus.rejected;
    case IndividualMovementWorkflowStatus.pending:
      return MovementWorkflowStatus.pending;
  }
}

MovementType _movementTypeFromEntity(IndividualMovementType type) {
  switch (type) {
    case IndividualMovementType.startSchool:
      return MovementType.startSchool;
    case IndividualMovementType.leaveSchool:
      return MovementType.leaveSchool;
    case IndividualMovementType.moveToNextClassroom:
      return MovementType.moveToNextClassroom;
  }
}

class MovementSection {
  const MovementSection({
    required this.title,
    required this.backgroundColor,
    required this.bucket,
    required this.items,
  });

  final String title;
  final Color backgroundColor;
  final MovementBucket bucket;
  final List<MovementItem> items;
}

class MovementFormResult {
  const MovementFormResult({
    required this.student,
    required this.currentClassroom,
    required this.nextClassroom,
    required this.movementDate,
    required this.comment,
  });

  final String student;
  final String currentClassroom;
  final String nextClassroom;
  final DateTime movementDate;
  final String comment;
}
