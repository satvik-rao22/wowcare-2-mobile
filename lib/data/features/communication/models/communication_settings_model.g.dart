// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'communication_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommunicationSettingsModel _$CommunicationSettingsModelFromJson(
        Map<String, dynamic> json) =>
    CommunicationSettingsModel(
      schoolCode: json['schoolCode'] as String? ?? '',
      adminCanDeleteAny: json['adminCanDeleteAny'] as bool? ?? false,
      deleteTimeLimitMinutes: (json['deleteTimeLimitMinutes'] as num?)?.toInt(),
      notifyStaffToParent: json['notifyStaffToParent'] as bool? ?? true,
      notifyStaffToStaff: json['notifyStaffToStaff'] as bool? ?? true,
      notifyParentToStaff: json['notifyParentToStaff'] as bool? ?? true,
    );

Map<String, dynamic> _$CommunicationSettingsModelToJson(
        CommunicationSettingsModel instance) =>
    <String, dynamic>{
      'schoolCode': instance.schoolCode,
      'adminCanDeleteAny': instance.adminCanDeleteAny,
      'deleteTimeLimitMinutes': instance.deleteTimeLimitMinutes,
      'notifyStaffToParent': instance.notifyStaffToParent,
      'notifyStaffToStaff': instance.notifyStaffToStaff,
      'notifyParentToStaff': instance.notifyParentToStaff,
    };
