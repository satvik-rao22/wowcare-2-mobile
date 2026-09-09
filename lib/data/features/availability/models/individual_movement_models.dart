import 'package:json_annotation/json_annotation.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement_board.dart';

part 'individual_movement_models.g.dart';

// explicitToJson: nested movement lists must be deep-serialized to maps —
// otherwise toJson() emits raw model objects for `overdue`/`upcoming`/etc.,
// which then fail to parse back via fromCacheJson (the cache round-trip).
@JsonSerializable(explicitToJson: true)
class IndividualMovementBoardModel {
  const IndividualMovementBoardModel({
    this.overdue = const <IndividualMovementModel>[],
    this.upcoming = const <IndividualMovementModel>[],
    this.confirmed = const <IndividualMovementModel>[],
    this.rejected = const <IndividualMovementModel>[],
  });

  @JsonKey(fromJson: _readMovementList)
  final List<IndividualMovementModel> overdue;
  @JsonKey(fromJson: _readMovementList)
  final List<IndividualMovementModel> upcoming;
  @JsonKey(fromJson: _readMovementList)
  final List<IndividualMovementModel> confirmed;
  @JsonKey(fromJson: _readMovementList)
  final List<IndividualMovementModel> rejected;

  /// The API wraps the board in a `data` envelope; the cache copy (written by
  /// [toJson]) does not, so both factories delegate to the same generated
  /// field mapping — just with a different (already-unwrapped) input map.
  factory IndividualMovementBoardModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return _$IndividualMovementBoardModelFromJson(data);
  }

  factory IndividualMovementBoardModel.fromCacheJson(Map<String, dynamic> json) =>
      _$IndividualMovementBoardModelFromJson(json);

  Map<String, dynamic> toJson() => _$IndividualMovementBoardModelToJson(this);

  IndividualMovementBoard toEntity() {
    return IndividualMovementBoard(
      overdue: overdue.map((e) => e.toEntity()).toList(),
      upcoming: upcoming.map((e) => e.toEntity()).toList(),
      confirmed: confirmed.map((e) => e.toEntity()).toList(),
      rejected: rejected.map((e) => e.toEntity()).toList(),
    );
  }
}

@JsonSerializable()
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

  @JsonKey(fromJson: _toIntOrZero)
  final int id;
  @JsonKey(fromJson: _toStringOrEmpty)
  final String code;
  @JsonKey(fromJson: _parseMovementType, toJson: _movementTypeToApi)
  final IndividualMovementType movementType;
  @JsonKey(fromJson: _toStringOrEmpty)
  final String studentCode;
  @JsonKey(fromJson: _toStringOrEmpty)
  final String studentName;
  @JsonKey(fromJson: _toStringOrEmpty)
  final String studentAvatarInitials;
  @JsonKey(fromJson: _toStringOrEmpty)
  final String fromClassroomCode;
  @JsonKey(fromJson: _toStringOrEmpty)
  final String fromClassroomName;
  @JsonKey(fromJson: _toStringOrEmpty)
  final String toClassroomCode;
  @JsonKey(fromJson: _toStringOrEmpty)
  final String toClassroomName;
  @JsonKey(fromJson: _parseDateOnly, toJson: _formatDateOnly)
  final DateTime movementDate;
  @JsonKey(fromJson: _parseWorkflowStatus, toJson: _statusToApi)
  final IndividualMovementWorkflowStatus status;
  @JsonKey(fromJson: _toStringOrEmpty)
  final String source;
  @JsonKey(fromJson: _toStringOrEmpty)
  final String comment;
  @JsonKey(fromJson: _toStringOrEmpty)
  final String bucket;
  final String? profilePhotoAssetCode;
  @JsonKey(fromJson: _parseDateTime, toJson: _formatDateTime)
  final DateTime? confirmedAt;
  final String? confirmedBy;
  @JsonKey(fromJson: _parseDateTime, toJson: _formatDateTime)
  final DateTime? rejectedAt;
  final String? rejectedBy;
  final String? rejectionComment;
  @JsonKey(fromJson: _parseDateTime, toJson: _formatDateTime)
  final DateTime? createdAt;
  @JsonKey(fromJson: _parseDateTime, toJson: _formatDateTime)
  final DateTime? updatedAt;

  factory IndividualMovementModel.fromJson(Map<String, dynamic> json) =>
      _$IndividualMovementModelFromJson(json);

  Map<String, dynamic> toJson() => _$IndividualMovementModelToJson(this);

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

List<IndividualMovementModel> _readMovementList(dynamic value) {
  if (value is! List) return const <IndividualMovementModel>[];
  return value
      .whereType<Map<String, dynamic>>()
      .map(IndividualMovementModel.fromJson)
      .toList();
}

int _toIntOrZero(dynamic value) => (value as num?)?.toInt() ?? 0;

String _toStringOrEmpty(dynamic value) => (value ?? '').toString();

IndividualMovementType _parseMovementType(dynamic value) {
  switch (value.toString().toUpperCase()) {
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

IndividualMovementWorkflowStatus _parseWorkflowStatus(dynamic value) {
  switch (value.toString().toUpperCase()) {
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

DateTime _parseDateOnly(dynamic value) {
  final raw = (value ?? '').toString();
  if (raw.trim().isEmpty) return AppTime.today();
  return DateTime.tryParse(raw)?.toLocal() ?? AppTime.today();
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}

String? _formatDateTime(DateTime? value) => value?.toIso8601String();

String _formatDateOnly(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

@JsonSerializable()
class MovementStatusCountsModel {
  const MovementStatusCountsModel({
    required this.overdueCount,
    required this.pendingCount,
  });

  @JsonKey(fromJson: _toIntOrZero)
  final int overdueCount;
  @JsonKey(fromJson: _toIntOrZero)
  final int pendingCount;

  factory MovementStatusCountsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return _$MovementStatusCountsModelFromJson(data);
  }

  Map<String, dynamic> toJson() => _$MovementStatusCountsModelToJson(this);
}
