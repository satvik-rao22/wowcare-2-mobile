// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_entity_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttachmentEntityDto _$AttachmentEntityDtoFromJson(Map<String, dynamic> json) =>
    AttachmentEntityDto(
      code: json['code'] as String? ?? '',
      messageCode: json['messageCode'] as String? ?? '',
      conversationCode: json['conversationCode'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      uploadedBy: json['uploadedBy'] as String? ?? '',
      uploadedAt: _parseDateOrNow(json['uploadedAt']),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      attachmentId: (_readAttachmentId(json, 'attachmentId') as num?)?.toInt(),
    );

Map<String, dynamic> _$AttachmentEntityDtoToJson(AttachmentEntityDto instance) {
  final val = <String, dynamic>{
    'code': instance.code,
    'messageCode': instance.messageCode,
    'conversationCode': instance.conversationCode,
    'fileName': instance.fileName,
    'fileUrl': instance.fileUrl,
    'mimeType': instance.mimeType,
    'fileSizeBytes': instance.fileSizeBytes,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('thumbnailUrl', instance.thumbnailUrl);
  val['uploadedBy'] = instance.uploadedBy;
  val['uploadedAt'] = instance.uploadedAt.toIso8601String();
  writeNotNull('attachmentId', instance.attachmentId);
  return val;
}

ReactionDto _$ReactionDtoFromJson(Map<String, dynamic> json) => ReactionDto(
      messageCode: json['messageCode'] as String? ?? '',
      userCode: json['userCode'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '',
      createdAt: _parseDateOrNow(json['createdAt']),
      role: _readReactionRole(json, 'role') as String?,
    );

Map<String, dynamic> _$ReactionDtoToJson(ReactionDto instance) =>
    <String, dynamic>{
      'messageCode': instance.messageCode,
      'userCode': instance.userCode,
      'userName': instance.userName,
      'emoji': instance.emoji,
      'createdAt': instance.createdAt.toIso8601String(),
      'role': instance.role,
    };
