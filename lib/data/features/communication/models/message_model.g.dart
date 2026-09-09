// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatAttachmentModel _$ChatAttachmentModelFromJson(Map<String, dynamic> json) =>
    ChatAttachmentModel(
      name: _readAttName(json, 'name') as String,
      type: _readAttType(json, 'type') as String,
      sizeBytes: (_readAttSize(json, 'size_bytes') as num).toInt(),
      mimeType: _readAttMime(json, 'mime_type') as String,
      remoteUrl: _readAttRemote(json, 'remote_url') as String,
      localPath: _readAttLocal(json, 'local_path') as String?,
      code: _readAttCode(json, 'code') as String?,
      attachmentId: (_readAttId(json, 'attachmentId') as num?)?.toInt(),
    );

Map<String, dynamic> _$ChatAttachmentModelToJson(
        ChatAttachmentModel instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'size_bytes': instance.sizeBytes,
      'mime_type': instance.mimeType,
      'remote_url': instance.remoteUrl,
      'local_path': instance.localPath,
      'code': instance.code,
      'attachmentId': instance.attachmentId,
    };
