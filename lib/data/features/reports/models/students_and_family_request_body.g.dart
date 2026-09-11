// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'students_and_family_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$StudentsAndFamilyRequestBodyToJson(
    StudentsAndFamilyRequestBody instance) {
  final val = <String, dynamic>{
    'reportType': instance.reportType,
    'startDate': instance.startDate,
    'endDate': instance.endDate,
    'fullName': instance.fullName,
    'dob': instance.dob,
    'classroom': instance.classroom,
    'address': instance.address,
    'allergies': instance.allergies,
    'dietRestriction': instance.dietRestriction,
    'enrollDate': instance.enrollDate,
    'medications': instance.medications,
    'note': instance.note,
    'schedule': instance.schedule,
    'schoolLeavingDate': instance.schoolLeavingDate,
    'status': instance.status,
    'tags': instance.tags,
    'guardianFirstName': instance.guardianFirstName,
    'guardianLastName': instance.guardianLastName,
    'guardianRelation': instance.guardianRelation,
    'guardianEmail': instance.guardianEmail,
    'guardianPhoneNumber': instance.guardianPhoneNumber,
    'guardianEmergencyContact': instance.guardianEmergencyContact,
    'guardianSignInPin': instance.guardianSignInPin,
    'pickupFirstName': instance.pickupFirstName,
    'pickupLastName': instance.pickupLastName,
    'pickupRelation': instance.pickupRelation,
    'pickupEmail': instance.pickupEmail,
    'pickupPhoneNumber': instance.pickupPhoneNumber,
    'pickupEmergencyContact': instance.pickupEmergencyContact,
    'pickupSignInPin': instance.pickupSignInPin,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('roomCodes', instance.roomCodes);
  writeNotNull('tagCodes', instance.tagCodes);
  val['statusFilter'] = instance.statusFilter;
  val['format'] = instance.format;
  val['schoolName'] = instance.schoolName;
  writeNotNull('schoolCode', instance.schoolCode);
  writeNotNull('organizationCode', instance.organizationCode);
  writeNotNull('generatedBy', instance.generatedBy);
  return val;
}
