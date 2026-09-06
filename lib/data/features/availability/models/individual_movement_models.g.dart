// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'individual_movement_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IndividualMovementBoardModel _$IndividualMovementBoardModelFromJson(
        Map<String, dynamic> json) =>
    IndividualMovementBoardModel(
      overdue: json['overdue'] == null
          ? const <IndividualMovementModel>[]
          : _readMovementList(json['overdue']),
      upcoming: json['upcoming'] == null
          ? const <IndividualMovementModel>[]
          : _readMovementList(json['upcoming']),
      confirmed: json['confirmed'] == null
          ? const <IndividualMovementModel>[]
          : _readMovementList(json['confirmed']),
      rejected: json['rejected'] == null
          ? const <IndividualMovementModel>[]
          : _readMovementList(json['rejected']),
    );

Map<String, dynamic> _$IndividualMovementBoardModelToJson(
        IndividualMovementBoardModel instance) =>
    <String, dynamic>{
      'overdue': instance.overdue.map((e) => e.toJson()).toList(),
      'upcoming': instance.upcoming.map((e) => e.toJson()).toList(),
      'confirmed': instance.confirmed.map((e) => e.toJson()).toList(),
      'rejected': instance.rejected.map((e) => e.toJson()).toList(),
    };

IndividualMovementModel _$IndividualMovementModelFromJson(
        Map<String, dynamic> json) =>
    IndividualMovementModel(
      id: _toIntOrZero(json['id']),
      code: _toStringOrEmpty(json['code']),
      movementType: _parseMovementType(json['movementType']),
      studentCode: _toStringOrEmpty(json['studentCode']),
      studentName: _toStringOrEmpty(json['studentName']),
      studentAvatarInitials: _toStringOrEmpty(json['studentAvatarInitials']),
      fromClassroomCode: _toStringOrEmpty(json['fromClassroomCode']),
      fromClassroomName: _toStringOrEmpty(json['fromClassroomName']),
      toClassroomCode: _toStringOrEmpty(json['toClassroomCode']),
      toClassroomName: _toStringOrEmpty(json['toClassroomName']),
      movementDate: _parseDateOnly(json['movementDate']),
      status: _parseWorkflowStatus(json['status']),
      source: _toStringOrEmpty(json['source']),
      comment: _toStringOrEmpty(json['comment']),
      bucket: _toStringOrEmpty(json['bucket']),
      profilePhotoAssetCode: json['profilePhotoAssetCode'] as String?,
      confirmedAt: _parseDateTime(json['confirmedAt']),
      confirmedBy: json['confirmedBy'] as String?,
      rejectedAt: _parseDateTime(json['rejectedAt']),
      rejectedBy: json['rejectedBy'] as String?,
      rejectionComment: json['rejectionComment'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );

Map<String, dynamic> _$IndividualMovementModelToJson(
        IndividualMovementModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'movementType': _movementTypeToApi(instance.movementType),
      'studentCode': instance.studentCode,
      'studentName': instance.studentName,
      'studentAvatarInitials': instance.studentAvatarInitials,
      'fromClassroomCode': instance.fromClassroomCode,
      'fromClassroomName': instance.fromClassroomName,
      'toClassroomCode': instance.toClassroomCode,
      'toClassroomName': instance.toClassroomName,
      'movementDate': _formatDateOnly(instance.movementDate),
      'status': _statusToApi(instance.status),
      'source': instance.source,
      'comment': instance.comment,
      'bucket': instance.bucket,
      'profilePhotoAssetCode': instance.profilePhotoAssetCode,
      'confirmedAt': _formatDateTime(instance.confirmedAt),
      'confirmedBy': instance.confirmedBy,
      'rejectedAt': _formatDateTime(instance.rejectedAt),
      'rejectedBy': instance.rejectedBy,
      'rejectionComment': instance.rejectionComment,
      'createdAt': _formatDateTime(instance.createdAt),
      'updatedAt': _formatDateTime(instance.updatedAt),
    };

MovementStatusCountsModel _$MovementStatusCountsModelFromJson(
        Map<String, dynamic> json) =>
    MovementStatusCountsModel(
      overdueCount: _toIntOrZero(json['overdueCount']),
      pendingCount: _toIntOrZero(json['pendingCount']),
    );

Map<String, dynamic> _$MovementStatusCountsModelToJson(
        MovementStatusCountsModel instance) =>
    <String, dynamic>{
      'overdueCount': instance.overdueCount,
      'pendingCount': instance.pendingCount,
    };
