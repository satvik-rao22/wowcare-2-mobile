// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'annual_state_immunization_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$AnnualStateImmunizationRequestBodyToJson(
  AnnualStateImmunizationRequestBody instance,
) {
  final val = <String, dynamic>{
    'reportType': instance.reportType,
    'startDate': instance.startDate,
    'endDate': instance.endDate,
    'format': instance.format,
    'schoolName': instance.schoolName,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('schoolCode', instance.schoolCode);
  writeNotNull('organizationCode', instance.organizationCode);
  writeNotNull('generatedBy', instance.generatedBy);
  return val;
}
