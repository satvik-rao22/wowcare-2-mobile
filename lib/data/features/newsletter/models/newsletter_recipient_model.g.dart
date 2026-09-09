// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'newsletter_recipient_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NewsletterRecipientModel _$NewsletterRecipientModelFromJson(
        Map<String, dynamic> json) =>
    NewsletterRecipientModel(
      id: (json['id'] as num?)?.toInt(),
      code: jsonTrimmedString(json['code']),
      userCode: jsonTrimmedString(json['userCode']),
      userName: jsonTrimmedString(json['userName']),
      status: jsonTrimmedString(json['status']),
    );

Map<String, dynamic> _$NewsletterRecipientModelToJson(
        NewsletterRecipientModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'userCode': instance.userCode,
      'userName': instance.userName,
      'status': instance.status,
    };
