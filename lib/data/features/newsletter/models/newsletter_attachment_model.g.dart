// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'newsletter_attachment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NewsletterAttachmentModel _$NewsletterAttachmentModelFromJson(
        Map<String, dynamic> json) =>
    NewsletterAttachmentModel(
      id: (json['id'] as num?)?.toInt(),
      code: jsonTrimmedString(_readAttachmentCode(json, 'code')),
      name: jsonTrimmedString(_readAttachmentName(json, 'name')),
      url: jsonTrimmedString(_readAttachmentUrl(json, 'url')),
      mimeType: jsonTrimmedString(_readAttachmentMimeType(json, 'mimeType')),
      sizeBytes: (_readAttachmentSize(json, 'sizeBytes') as num?)?.toInt(),
    );

Map<String, dynamic> _$NewsletterAttachmentModelToJson(
        NewsletterAttachmentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'url': instance.url,
      'mimeType': instance.mimeType,
      'sizeBytes': instance.sizeBytes,
    };
