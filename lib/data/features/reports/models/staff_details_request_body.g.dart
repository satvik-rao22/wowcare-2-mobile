// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_details_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$StaffDetailsRequestBodyToJson(
    StaffDetailsRequestBody instance) {
  final val = <String, dynamic>{
    'reportType': instance.reportType,
    'status': instance.status,
    'includeName': instance.includeName,
    'includeDateOfBirth': instance.includeDateOfBirth,
    'includeEmailId': instance.includeEmailId,
    'includePhoneNumber': instance.includePhoneNumber,
    'includeAddress': instance.includeAddress,
    'includePrimaryClassroom': instance.includePrimaryClassroom,
    'includeClockInOutPin': instance.includeClockInOutPin,
    'includeHireDate': instance.includeHireDate,
    'includeDesignation': instance.includeDesignation,
    'includeCdaExpirationDate': instance.includeCdaExpirationDate,
    'includeCprExpirationDate': instance.includeCprExpirationDate,
    'includeLastPhysicalDate': instance.includeLastPhysicalDate,
    'includeIsActive': instance.includeIsActive,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('classroomCodes', instance.classroomCodes);
  val['format'] = instance.format;
  val['schoolName'] = instance.schoolName;
  writeNotNull('schoolCode', instance.schoolCode);
  writeNotNull('organizationCode', instance.organizationCode);
  writeNotNull('generatedBy', instance.generatedBy);
  return val;
}
