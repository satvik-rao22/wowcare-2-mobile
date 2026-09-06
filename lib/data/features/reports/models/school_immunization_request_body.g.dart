// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'school_immunization_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$SchoolImmunizationRequestBodyToJson(
  SchoolImmunizationRequestBody instance,
) {
  final val = <String, dynamic>{
    'reportType': instance.reportType,
    'startDate': instance.startDate,
    'endDate': instance.endDate,
    'vaccineCodes': instance.vaccineCodes,
    'schoolName': instance.schoolName,
    'statusFilter': instance.statusFilter,
    'includeParentName': instance.includeParentName,
    'includeParentEmail': instance.includeParentEmail,
    'format': instance.format,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('roomCodes', instance.roomCodes);
  writeNotNull('tagCodes', instance.tagCodes);
  writeNotNull('schoolCode', instance.schoolCode);
  writeNotNull('organizationCode', instance.organizationCode);
  writeNotNull('generatedBy', instance.generatedBy);
  return val;
}
