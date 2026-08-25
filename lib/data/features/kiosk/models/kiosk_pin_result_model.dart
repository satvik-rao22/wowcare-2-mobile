import 'package:wowcare/domain/features/kiosk/entities/kiosk_pin_result_entity.dart';

class KioskStudentModel extends KioskStudent {
  const KioskStudentModel({
    required super.studentCode,
    required super.fullName,
    required super.classroomCode,
    required super.classroomName,
    required super.status,
    super.studentProfileAssetCode,
    super.expected,
  });

  factory KioskStudentModel.fromJson(Map<String, dynamic> json) {
    return KioskStudentModel(
      studentCode: json['studentCode'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      classroomCode: json['classroomCode'] as String? ?? '',
      classroomName: json['classroomName'] as String? ?? '',
      status: json['status'] as String? ?? 'SIGNED_OUT',
      studentProfileAssetCode: json['studentProfileAssetCode'] as String?,
      expected: json['expected'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'studentCode': studentCode,
    'fullName': fullName,
    'classroomCode': classroomCode,
    'classroomName': classroomName,
    'status': status,
    'studentProfileAssetCode': studentProfileAssetCode,
    'expected': expected,
  };
}

class KioskPinResultModel extends KioskPinResultEntity {
  const KioskPinResultModel({
    required super.persona,
    super.guardianCode,
    super.guardianName,
    super.students = const [],
    super.staffCode,
    super.staffName,
    super.staffStatus,
    super.classroomCode,
    super.classroomName,
    super.designation,
    super.role,
    super.staffProfileAssetCode,
    super.expected,
  });

  factory KioskPinResultModel.fromJson(Map<String, dynamic> json) {
    final personaStr = (json['persona'] as String? ?? '').toLowerCase();

    // Defensive persona mapping: handle typos (KIOSK/KOISK), aliases (PICKUP), and standard values
    final persona = personaStr.contains('staff')
        ? KioskPersona.staff
        : (personaStr.contains('guardian') || personaStr.contains('pickup'))
        ? KioskPersona.guardian
        : (personaStr.contains('kiosk') || personaStr.contains('koisk'))
        ? KioskPersona.kiosk
        : KioskPersona.unknown;

    final studentsList = <KioskStudentModel>[];
    final studentsJson = json['students'] as List?;
    if (studentsJson != null) {
      for (final studentJson in studentsJson) {
        if (studentJson is Map<String, dynamic>) {
          studentsList.add(KioskStudentModel.fromJson(studentJson));
        }
      }
    }

    return KioskPinResultModel(
      persona: persona,
      guardianCode: json['guardianCode'] as String?,
      guardianName: json['guardianName'] as String?,
      students: studentsList,
      staffCode: json['staffCode'] as String?,
      staffName: json['staffName'] as String?,
      staffStatus: json['status'] as String?,
      classroomCode: json['classroomCode'] as String?,
      classroomName: json['classroomName'] as String?,
      designation: json['designation'] as String?,
      role: json['role'] as String?,
      staffProfileAssetCode: json['staffProfileAssetCode'] as String?,
      expected: json['expected'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'persona': persona.toString().split('.').last,
    'guardianCode': guardianCode,
    'guardianName': guardianName,
    'students': students
        .map(
          (s) => s is KioskStudentModel
              ? s.toJson()
              : {
                  'studentCode': s.studentCode,
                  'fullName': s.fullName,
                  'classroomCode': s.classroomCode,
                  'classroomName': s.classroomName,
                  'status': s.status,
                  'studentProfileAssetCode': s.studentProfileAssetCode,
                  'expected': s.expected,
                },
        )
        .toList(),
    'staffCode': staffCode,
    'staffName': staffName,
    'status': staffStatus,
    'classroomCode': classroomCode,
    'classroomName': classroomName,
    'designation': designation,
    'role': role,
    'staffProfileAssetCode': staffProfileAssetCode,
    'expected': expected,
  };
}
