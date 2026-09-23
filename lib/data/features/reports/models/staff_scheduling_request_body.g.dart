// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_scheduling_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$StaffSchedulingRequestBodyToJson(
    StaffSchedulingRequestBody instance) {
  final val = <String, dynamic>{
    'reportType': instance.reportType,
    'startDate': instance.startDate,
    'endDate': instance.endDate,
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
  writeNotNull('schoolTimeZone', instance.schoolTimeZone);
  return val;
}
