import 'package:equatable/equatable.dart';

enum KioskPersona {
  guardian,
  staff,
  kiosk,
  unknown,
}

class KioskStudent extends Equatable {
  const KioskStudent({
    required this.studentCode,
    required this.fullName,
    required this.classroomCode,
    required this.classroomName,
    required this.status,
    this.studentProfileAssetCode,
    this.expected = true,
  });

  final String studentCode;
  final String fullName;
  final String classroomCode;
  final String classroomName;
  final String status; // 'SIGNED_IN' or 'SIGNED_OUT'
  final String? studentProfileAssetCode;
  final bool expected;

  bool get isSignedIn => status.toUpperCase() == 'SIGNED_IN';

  @override
  List<Object?> get props => [
    studentCode,
    fullName,
    classroomCode,
    classroomName,
    status,
    studentProfileAssetCode,
    expected,
  ];
}

class KioskPinResultEntity extends Equatable {
  const KioskPinResultEntity({
    required this.persona,
    this.guardianCode,
    this.guardianName,
    this.students = const [],
    this.staffCode,
    this.staffName,
    this.staffStatus,
    this.classroomCode,
    this.classroomName,
    this.designation,
    this.role,
    this.staffProfileAssetCode,
    this.expected = true,
  });

  final KioskPersona persona;
  final String? guardianCode;
  final String? guardianName;
  final List<KioskStudent> students;
  final String? staffCode;
  final String? staffName;
  final String? staffStatus;
  final String? classroomCode;
  final String? classroomName;
  final String? designation;
  final String? role;
  final String? staffProfileAssetCode;
  final bool expected;

  bool get isGuardian => persona == KioskPersona.guardian;
  bool get isStaff => persona == KioskPersona.staff;

  List<KioskStudent> get signedInStudents =>
      students.where((s) => s.isSignedIn).toList();

  List<KioskStudent> get signedOutStudents =>
      students.where((s) => !s.isSignedIn).toList();

  @override
  List<Object?> get props => [
    persona,
    guardianCode,
    guardianName,
    students,
    staffCode,
    staffName,
    staffStatus,
    classroomCode,
    classroomName,
    designation,
    role,
    staffProfileAssetCode,
    expected,
  ];
}
