enum IndividualMovementWorkflowStatus { pending, confirmed, rejected }

enum IndividualMovementType { startSchool, moveToNextClassroom, leaveSchool }

class IndividualMovement {
  const IndividualMovement({
    required this.id,
    required this.code,
    required this.movementType,
    required this.studentCode,
    required this.studentName,
    required this.studentAvatarInitials,
    required this.fromClassroomCode,
    required this.fromClassroomName,
    required this.toClassroomCode,
    required this.toClassroomName,
    required this.movementDate,
    required this.status,
    required this.source,
    required this.comment,
    required this.bucket,
    this.confirmedAt,
    this.confirmedBy,
    this.rejectedAt,
    this.rejectedBy,
    this.rejectionComment,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String code;
  final IndividualMovementType movementType;
  final String studentCode;
  final String studentName;
  final String studentAvatarInitials;
  final String fromClassroomCode;
  final String fromClassroomName;
  final String toClassroomCode;
  final String toClassroomName;
  final DateTime movementDate;
  final IndividualMovementWorkflowStatus status;
  final String source;
  final String comment;
  final String bucket;
  final DateTime? confirmedAt;
  final String? confirmedBy;
  final DateTime? rejectedAt;
  final String? rejectedBy;
  final String? rejectionComment;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
