import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement.dart';

/// PRD: Pending | Approved (confirmed) | Rejected.
enum MovementWorkflowStatus { pending, confirmed, rejected }

/// Movement kinds (UI currently implements [moveToNextClassroom] only).
enum MovementType {
  startSchool,
  moveToNextClassroom,
  leaveSchool,
}

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
      movementType: movementTypeFromEntity(movement.movementType),
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

MovementWorkflowStatus _workflowStatusFromEntity(IndividualMovementWorkflowStatus status) {
  switch (status) {
    case IndividualMovementWorkflowStatus.confirmed:
      return MovementWorkflowStatus.confirmed;
    case IndividualMovementWorkflowStatus.rejected:
      return MovementWorkflowStatus.rejected;
    case IndividualMovementWorkflowStatus.pending:
      return MovementWorkflowStatus.pending;
  }
}

/// Public so the screen/cubit layer can map API entities without redefining
/// this switch a second time (see [MovementItem.fromEntity]).
MovementType movementTypeFromEntity(IndividualMovementType type) {
  switch (type) {
    case IndividualMovementType.startSchool:
      return MovementType.startSchool;
    case IndividualMovementType.leaveSchool:
      return MovementType.leaveSchool;
    case IndividualMovementType.moveToNextClassroom:
      return MovementType.moveToNextClassroom;
  }
}

/// Single source of truth for how a board bucket is labelled and coloured,
/// shared by the board columns ([IndividualMovementPager]) and the dashboard
/// summary ([MovementsCard]) — previously each redefined its own mapping.
extension MovementBucketPresentation on MovementBucket {
  String get label {
    switch (this) {
      case MovementBucket.overdue:
        return 'Overdue';
      case MovementBucket.upcoming:
        return 'Upcoming';
      case MovementBucket.confirmed:
        return 'Confirmed';
      case MovementBucket.rejected:
        return 'Rejected';
    }
  }

  /// Background tint for the full board column/card.
  Color get sectionBackgroundColor {
    switch (this) {
      case MovementBucket.overdue:
        return AppColors.movementOverdueBackground;
      case MovementBucket.upcoming:
        return AppColors.movementUpcomingBackground;
      case MovementBucket.confirmed:
        return AppColors.movementConfirmedBackground;
      case MovementBucket.rejected:
        return AppColors.movementRejectedBackground;
    }
  }

  /// Foreground colour for the small status pill badge.
  Color get badgeColor {
    switch (this) {
      case MovementBucket.overdue:
        return AppColors.errorColor;
      case MovementBucket.upcoming:
        return AppColors.warningColor;
      case MovementBucket.confirmed:
        return AppColors.successColor;
      case MovementBucket.rejected:
        return AppColors.errorColor.withValues(alpha: 0.7);
    }
  }

  /// Background tint for the small status pill badge.
  Color get badgeBackgroundColor {
    switch (this) {
      case MovementBucket.rejected:
        return badgeColor.withValues(alpha: 0.20);
      case MovementBucket.overdue:
      case MovementBucket.upcoming:
      case MovementBucket.confirmed:
        return badgeColor.withValues(alpha: 0.25);
    }
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

/// Builds display-only names (no codes) while maintaining a stable mapping
/// from display string -> code. If multiple items share the same name,
/// suffix them as "Name (2)", "Name (3)", etc.
///
/// Shared by [IndividualMovementScreen] (filter dropdowns) and
/// [AddEditIndividualMovementScreen] (student/classroom pickers) — both
/// previously carried an identical private copy of this method.
({
  List<String> items,
  Map<String, String> displayToCode,
  Map<String, String> codeToDisplay,
}) buildDisplayOnlyOptions({
  required List<String> codes,
  required String Function(String code) nameForCode,
}) {
  final counts = <String, int>{};
  final items = <String>[];
  final displayToCode = <String, String>{};
  final codeToDisplay = <String, String>{};

  for (final codeRaw in codes) {
    final code = codeRaw.trim();
    if (code.isEmpty) continue;
    final baseName = nameForCode(code).trim();
    final name = baseName.isNotEmpty ? baseName : code;

    final next = (counts[name] ?? 0) + 1;
    counts[name] = next;

    final display = next == 1 ? name : '$name ($next)';
    items.add(display);
    displayToCode[display] = code;
    codeToDisplay[code] = display;
  }

  return (
    items: items,
    displayToCode: displayToCode,
    codeToDisplay: codeToDisplay,
  );
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

/// Typed navigation args for the add/edit movement route — carried through
/// GoRouter's `extra` in place of an untyped `Map<String, dynamic>`.
class AddEditMovementArgs {
  const AddEditMovementArgs({
    required this.students,
    required this.classrooms,
    required this.existingMovements,
    this.studentNamesByCode = const <String, String>{},
    this.classroomNamesByCode = const <String, String>{},
    this.movementType = MovementType.moveToNextClassroom,
    this.initialData,
    this.isEditing = false,
    this.editingMovementId,
    this.disablePastDates = false,
    this.lockClassroomSelection = false,
  });

  final List<String> students;
  final List<String> classrooms;
  final List<MovementItem> existingMovements;
  final Map<String, String> studentNamesByCode;
  final Map<String, String> classroomNamesByCode;
  final MovementType movementType;
  final MovementFormResult? initialData;
  final bool isEditing;
  final int? editingMovementId;
  final bool disablePastDates;
  final bool lockClassroomSelection;
}
