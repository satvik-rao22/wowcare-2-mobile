// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentImportantDatesModel _$StudentImportantDatesModelFromJson(
        Map<String, dynamic> json) =>
    StudentImportantDatesModel(
      enrollDate: json['enrollDate'] as String?,
      schoolStartDate: json['schoolStartDate'] as String?,
      currentClassroomStartDate: json['currentClassroomStartDate'] as String?,
      upcomingMoveDate: json['upcomingMoveDate'] as String?,
      schoolLeavingDate: json['schoolLeavingDate'] as String?,
    );

Map<String, dynamic> _$StudentImportantDatesModelToJson(
    StudentImportantDatesModel instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('enrollDate', instance.enrollDate);
  writeNotNull('schoolStartDate', instance.schoolStartDate);
  writeNotNull('currentClassroomStartDate', instance.currentClassroomStartDate);
  writeNotNull('upcomingMoveDate', instance.upcomingMoveDate);
  writeNotNull('schoolLeavingDate', instance.schoolLeavingDate);
  return val;
}

StudentHealthModel _$StudentHealthModelFromJson(Map<String, dynamic> json) =>
    StudentHealthModel(
      allergy: json['allergy'] as String?,
      medications: json['medications'] as String?,
      dietRestrictions: json['dietRestrictions'] as String?,
      photoPermission: _photoPermissionFromJson(json['photoPermission']),
    );

Map<String, dynamic> _$StudentHealthModelToJson(StudentHealthModel instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('allergy', instance.allergy);
  writeNotNull('medications', instance.medications);
  writeNotNull('dietRestrictions', instance.dietRestrictions);
  writeNotNull('photoPermission', instance.photoPermission);
  return val;
}

StudentPhysicalExamModel _$StudentPhysicalExamModelFromJson(
        Map<String, dynamic> json) =>
    StudentPhysicalExamModel(
      code: json['code'] as String? ?? '',
      examDate: json['examDate'] as String?,
      status: json['status'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$StudentPhysicalExamModelToJson(
    StudentPhysicalExamModel instance) {
  final val = <String, dynamic>{
    'code': instance.code,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('examDate', instance.examDate);
  writeNotNull('status', instance.status);
  writeNotNull('notes', instance.notes);
  return val;
}

StudentImmunizationModel _$StudentImmunizationModelFromJson(
        Map<String, dynamic> json) =>
    StudentImmunizationModel(
      code: json['code'] as String? ?? '',
      studentCode: json['studentCode'] as String? ?? '',
      vaccineName: json['vaccineName'] as String? ?? '',
      vaccineDoseCode: json['vaccineDoseCode'] as String? ?? '',
      doseNumber: (json['doseNumber'] as num?)?.toInt() ?? 0,
      dueDate: json['dueDate'] as String?,
      administeredDate: json['administeredDate'] as String?,
      status: json['status'] as String? ?? '',
      exemptionReason: json['exemptionReason'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$StudentImmunizationModelToJson(
    StudentImmunizationModel instance) {
  final val = <String, dynamic>{
    'code': instance.code,
    'studentCode': instance.studentCode,
    'vaccineName': instance.vaccineName,
    'vaccineDoseCode': instance.vaccineDoseCode,
    'doseNumber': instance.doseNumber,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('dueDate', instance.dueDate);
  writeNotNull('administeredDate', instance.administeredDate);
  val['status'] = instance.status;
  writeNotNull('exemptionReason', instance.exemptionReason);
  writeNotNull('notes', instance.notes);
  return val;
}
