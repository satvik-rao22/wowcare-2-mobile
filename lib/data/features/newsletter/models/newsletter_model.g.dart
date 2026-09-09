// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'newsletter_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NewsletterModel _$NewsletterModelFromJson(Map<String, dynamic> json) =>
    NewsletterModel(
      id: (json['id'] as num?)?.toInt(),
      code: jsonTrimmedString(json['code']),
      organizationCode: jsonTrimmedString(json['organizationCode']),
      schoolCode: jsonTrimmedString(json['schoolCode']),
      title: jsonTrimmedString(json['title']),
      subtitle: jsonTrimmedString(json['subtitle']),
      layoutJson: _layoutJsonFromJson(json['layoutJson']),
      backgroundPattern: jsonTrimmedString(json['backgroundPattern']),
      colorTheme: jsonTrimmedString(json['colorTheme']),
      assetCode: jsonTrimmedStringOrNull(json['assetCode']),
      status: jsonTrimmedString(json['status']),
      createdBy: jsonTrimmedString(json['createdBy']),
      createdByName: jsonTrimmedString(json['createdByName']),
      createdAt: jsonDateTimeNoTrim(json['createdAt']),
      updatedAt: jsonDateTimeNoTrim(json['updatedAt']),
      components: _componentsFromJson(json['components']),
      attachments: _attachmentsFromJson(json['attachments']),
      recipients: _recipientsFromJson(json['recipients']),
      recipientCount:
          (_readRecipientCount(json, 'recipientCount') as num).toInt(),
    );

Map<String, dynamic> _$NewsletterModelToJson(NewsletterModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'organizationCode': instance.organizationCode,
      'schoolCode': instance.schoolCode,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'layoutJson': instance.layoutJson,
      'backgroundPattern': instance.backgroundPattern,
      'colorTheme': instance.colorTheme,
      'assetCode': instance.assetCode,
      'status': instance.status,
      'createdBy': instance.createdBy,
      'createdByName': instance.createdByName,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'components': instance.components.map((e) => e.toJson()).toList(),
      'attachments': instance.attachments.map((e) => e.toJson()).toList(),
      'recipients': instance.recipients.map((e) => e.toJson()).toList(),
      'recipientCount': instance.recipientCount,
    };
