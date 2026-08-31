import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement_board.dart';

class IndividualMovementBoardModel {
  const IndividualMovementBoardModel({
    required this.overdue,
    required this.upcoming,
    required this.confirmed,
    required this.rejected,
  });

  final List<IndividualMovementModel> overdue;
  final List<IndividualMovementModel> upcoming;
  final List<IndividualMovementModel> confirmed;
  final List<IndividualMovementModel> rejected;

  factory IndividualMovementBoardModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return IndividualMovementBoardModel(
      overdue: _readList(data['overdue']),
      upcoming: _readList(data['upcoming']),
      confirmed: _readList(data['confirmed']),
      rejected: _readList(data['rejected']),
    );
  }

  factory IndividualMovementBoardModel.fromCacheJson(Map<String, dynamic> json) {
    return IndividualMovementBoardModel(
      overdue: _readList(json['overdue']),
      upcoming: _readList(json['upcoming']),
      confirmed: _readList(json['confirmed']),
      rejected: _readList(json['rejected']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'overdue': overdue.map((e) => e.toJson()).toList(),
      'upcoming': upcoming.map((e) => e.toJson()).toList(),
      'confirmed': confirmed.map((e) => e.toJson()).toList(),
      'rejected': rejected.map((e) => e.toJson()).toList(),
    };
  }

  IndividualMovementBoard toEntity() {
    return IndividualMovementBoard(
      overdue: overdue.map((e) => e.toEntity()).toList(),
      upcoming: upcoming.map((e) => e.toEntity()).toList(),
      confirmed: confirmed.map((e) => e.toEntity()).toList(),
      rejected: rejected.map((e) => e.toEntity()).toList(),
    );
  }

  static List<IndividualMovementModel> _readList(dynamic value) {
    if (value is! List) return const <IndividualMovementModel>[];
    return value
        .whereType<Map<String, dynamic>>()
        .map(IndividualMovementModel.fromJson)
        .toList();
  }
}

class IndividualMovementModel {
  const IndividualMovementModel({
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
    this.profilePhotoAssetCode,
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
  final String? profilePhotoAssetCode;
  final DateTime? confirmedAt;
  final String? confirmedBy;
  final DateTime? rejectedAt;
  final String? rejectedBy;
  final String? rejectionComment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory IndividualMovementModel.fromJson(Map<String, dynamic> json) {
    return IndividualMovementModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: (json['code'] ?? '').toString(),
      movementType: _parseMovementType((json['movementType'] ?? '').toString()),
      studentCode: (json['studentCode'] ?? '').toString(),
      studentName: (json['studentName'] ?? '').toString(),
      studentAvatarInitials: (json['studentAvatarInitials'] ?? '').toString(),
      fromClassroomCode: (json['fromClassroomCode'] ?? '').toString(),
      fromClassroomName: (json['fromClassroomName'] ?? '').toString(),
      toClassroomCode: (json['toClassroomCode'] ?? '').toString(),
      toClassroomName: (json['toClassroomName'] ?? '').toString(),
      movementDate: _parseDateOnly((json['movementDate'] ?? '').toString()),
      status: _parseWorkflowStatus((json['status'] ?? '').toString()),
      source: (json['source'] ?? '').toString(),
      comment: (json['comment'] ?? '').toString(),
      bucket: (json['bucket'] ?? '').toString(),
      profilePhotoAssetCode: json['profilePhotoAssetCode']?.toString(),
      confirmedAt: _parseDateTime(json['confirmedAt']),
      confirmedBy: json['confirmedBy']?.toString(),
      rejectedAt: _parseDateTime(json['rejectedAt']),
      rejectedBy: json['rejectedBy']?.toString(),
      rejectionComment: json['rejectionComment']?.toString(),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'code': code,
      'movementType': _movementTypeToApi(movementType),
      'studentCode': studentCode,
      'studentName': studentName,
      'studentAvatarInitials': studentAvatarInitials,
      'fromClassroomCode': fromClassroomCode,
      'fromClassroomName': fromClassroomName,
      'toClassroomCode': toClassroomCode,
      'toClassroomName': toClassroomName,
      'movementDate': _formatDateOnly(movementDate),
      'status': _statusToApi(status),
      'source': source,
      'comment': comment,
      'bucket': bucket,
      'profilePhotoAssetCode': profilePhotoAssetCode,
      'confirmedAt': confirmedAt?.toIso8601String(),
      'confirmedBy': confirmedBy,
      'rejectedAt': rejectedAt?.toIso8601String(),
      'rejectedBy': rejectedBy,
      'rejectionComment': rejectionComment,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  IndividualMovement toEntity() {
    return IndividualMovement(
      id: id,
      code: code,
      movementType: movementType,
      studentCode: studentCode,
      studentName: studentName,
      studentAvatarInitials: studentAvatarInitials,
      fromClassroomCode: fromClassroomCode,
      fromClassroomName: fromClassroomName,
      toClassroomCode: toClassroomCode,
      toClassroomName: toClassroomName,
      movementDate: movementDate,
      status: status,
      source: source,
      comment: comment,
      bucket: bucket,
      profilePhotoAssetCode: profilePhotoAssetCode,
      confirmedAt: confirmedAt,
      confirmedBy: confirmedBy,
      rejectedAt: rejectedAt,
      rejectedBy: rejectedBy,
      rejectionComment: rejectionComment,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

IndividualMovementType _parseMovementType(String value) {
  switch (value.toUpperCase()) {
    case 'START_SCHOOL':
      return IndividualMovementType.startSchool;
    case 'LEAVE_SCHOOL':
      return IndividualMovementType.leaveSchool;
    case 'CLASSROOM_PROMOTION':
    case 'MOVE_TO_NEXT_CLASSROOM': // legacy backend value
    default:
      return IndividualMovementType.moveToNextClassroom;
  }
}

String _movementTypeToApi(IndividualMovementType value) {
  switch (value) {
    case IndividualMovementType.startSchool:
      return 'START_SCHOOL';
    case IndividualMovementType.leaveSchool:
      return 'LEAVE_SCHOOL';
    case IndividualMovementType.moveToNextClassroom:
      // Backend enum uses CLASSROOM_PROMOTION for "move to next classroom".
      return 'CLASSROOM_PROMOTION';
  }
}

IndividualMovementWorkflowStatus _parseWorkflowStatus(String value) {
  switch (value.toUpperCase()) {
    case 'CONFIRMED':
      return IndividualMovementWorkflowStatus.confirmed;
    case 'REJECTED':
      return IndividualMovementWorkflowStatus.rejected;
    case 'PENDING':
    default:
      return IndividualMovementWorkflowStatus.pending;
  }
}

String _statusToApi(IndividualMovementWorkflowStatus value) {
  switch (value) {
    case IndividualMovementWorkflowStatus.pending:
      return 'PENDING';
    case IndividualMovementWorkflowStatus.confirmed:
      return 'CONFIRMED';
    case IndividualMovementWorkflowStatus.rejected:
      return 'REJECTED';
  }
}

DateTime _parseDateOnly(String value) {
  if (value.trim().isEmpty) return AppTime.today();
  return DateTime.tryParse(value)?.toLocal() ?? AppTime.today();
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}

String _formatDateOnly(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

class MovementStatusCountsModel {
  const MovementStatusCountsModel({
    required this.overdueCount,
    required this.pendingCount,
  });

  final int overdueCount;
  final int pendingCount;

  factory MovementStatusCountsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    return MovementStatusCountsModel(
      overdueCount: (data['overdueCount'] as num?)?.toInt() ?? 0,
      pendingCount: (data['pendingCount'] as num?)?.toInt() ?? 0,
    );
  }
}
