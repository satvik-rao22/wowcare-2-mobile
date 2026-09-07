// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'newsletter_component_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NewsletterComponentModel _$NewsletterComponentModelFromJson(
        Map<String, dynamic> json) =>
    NewsletterComponentModel(
      id: (json['id'] as num?)?.toInt(),
      type: jsonTrimmedString(_readComponentType(json, 'type')),
      data: _readComponentData(json, 'data') as Map<String, dynamic>,
      order: (_readComponentOrder(json, 'order') as num?)?.toInt(),
    );

Map<String, dynamic> _$NewsletterComponentModelToJson(
        NewsletterComponentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'data': instance.data,
      'order': instance.order,
    };
