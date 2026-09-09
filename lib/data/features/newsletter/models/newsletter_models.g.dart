// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'newsletter_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NewsletterComponentModel _$NewsletterComponentModelFromJson(
        Map<String, dynamic> json) =>
    NewsletterComponentModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      componentType: json['componentType'] == null
          ? ''
          : jsonTrimmedStringStrict(json['componentType']),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      contentJson: json['contentJson'] == null
          ? ''
          : jsonTrimmedStringStrict(json['contentJson']),
    );

Map<String, dynamic> _$NewsletterComponentModelToJson(
        NewsletterComponentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'componentType': instance.componentType,
      'sortOrder': instance.sortOrder,
      'contentJson': instance.contentJson,
    };

NewsletterAttachmentModel _$NewsletterAttachmentModelFromJson(
        Map<String, dynamic> json) =>
    NewsletterAttachmentModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      mediaCode: _readSentAttachmentMediaCode(json, 'mediaCode') == null
          ? ''
          : jsonTrimmedString(_readSentAttachmentMediaCode(json, 'mediaCode')),
      fileName: json['fileName'] == null
          ? ''
          : jsonTrimmedStringStrict(json['fileName']),
      mimeType: json['mimeType'] == null
          ? ''
          : jsonTrimmedStringStrict(json['mimeType']),
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      assetUrl: _readSentAttachmentAssetUrl(json, 'assetUrl') == null
          ? ''
          : jsonTrimmedString(_readSentAttachmentAssetUrl(json, 'assetUrl')),
    );

Map<String, dynamic> _$NewsletterAttachmentModelToJson(
        NewsletterAttachmentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mediaCode': instance.mediaCode,
      'fileName': instance.fileName,
      'mimeType': instance.mimeType,
      'fileSize': instance.fileSize,
      'sortOrder': instance.sortOrder,
      'assetUrl': instance.assetUrl,
    };

NewsletterRecipientModel _$NewsletterRecipientModelFromJson(
        Map<String, dynamic> json) =>
    NewsletterRecipientModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      classroomCode: json['classroomCode'] == null
          ? ''
          : jsonTrimmedStringStrict(json['classroomCode']),
      studentCode: _readRecipientStudentCode(json, 'studentCode') == null
          ? ''
          : jsonTrimmedString(_readRecipientStudentCode(json, 'studentCode')),
      userName: _readRecipientUserName(json, 'userName') == null
          ? ''
          : jsonTrimmedString(_readRecipientUserName(json, 'userName')),
    );

Map<String, dynamic> _$NewsletterRecipientModelToJson(
        NewsletterRecipientModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'classroomCode': instance.classroomCode,
      'studentCode': instance.studentCode,
      'userName': instance.userName,
    };

NewsletterModel _$NewsletterModelFromJson(Map<String, dynamic> json) =>
    NewsletterModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: jsonTrimmedStringStrict(json['code']),
      organizationCode: jsonTrimmedStringStrict(json['organizationCode']),
      schoolCode: jsonTrimmedStringStrict(json['schoolCode']),
      title: jsonTrimmedStringStrict(json['title']),
      subtitle: jsonTrimmedStringStrict(json['subtitle']),
      status: jsonTrimmedStringStrict(json['status']),
      scheduledAt: jsonDateTime(json['scheduledAt']),
      sentAt: jsonDateTime(json['sentAt']),
      createdAt: jsonDateTime(json['createdAt']),
      recipientCount: (json['recipientCount'] as num?)?.toInt() ?? 0,
      createdBy: json['createdBy'] == null
          ? ''
          : jsonTrimmedStringStrict(json['createdBy']),
      createdByName: json['createdByName'] == null
          ? ''
          : jsonTrimmedStringStrict(json['createdByName']),
      recipients: _sentRecipientsFromJson(json['recipients']),
      components: _sentComponentsFromJson(json['components']),
      attachments: _sentAttachmentsFromJson(json['attachments']),
      layoutJson: json['layoutJson'] == null
          ? ''
          : jsonTrimmedStringStrict(json['layoutJson']),
      colorTheme: json['colorTheme'] == null
          ? ''
          : jsonTrimmedStringStrict(json['colorTheme']),
      backgroundPattern: json['backgroundPattern'] == null
          ? 'plain'
          : _backgroundPatternFromJson(json['backgroundPattern']),
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
      'colorTheme': instance.colorTheme,
      'backgroundPattern': instance.backgroundPattern,
      'status': instance.status,
      'scheduledAt': instance.scheduledAt?.toIso8601String(),
      'sentAt': instance.sentAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'recipientCount': instance.recipientCount,
      'createdBy': instance.createdBy,
      'createdByName': instance.createdByName,
      'recipients': instance.recipients.map((e) => e.toJson()).toList(),
      'components': instance.components.map((e) => e.toJson()).toList(),
      'attachments': instance.attachments.map((e) => e.toJson()).toList(),
    };

NewsletterPageModel _$NewsletterPageModelFromJson(Map<String, dynamic> json) =>
    NewsletterPageModel(
      items: (json['items'] as List<dynamic>)
          .map((e) => NewsletterModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
    );

Map<String, dynamic> _$NewsletterPageModelToJson(
        NewsletterPageModel instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'page': instance.page,
      'size': instance.size,
      'totalPages': instance.totalPages,
      'totalElements': instance.totalElements,
      'hasMore': instance.hasMore,
    };
