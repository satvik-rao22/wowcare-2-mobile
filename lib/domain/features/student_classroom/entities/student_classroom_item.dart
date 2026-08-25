import 'package:equatable/equatable.dart';

class StudentClassroomItem extends Equatable {
  const StudentClassroomItem({
    required this.classroomCode,
    required this.studentCode,
    required this.firstName,
    required this.lastName,
    this.profilePictureUrl,
    required this.status,
    required this.expectedToday,
    required this.signedIn,
    required this.absent,
    required this.notMarked,
    required this.nap,
    required this.photoPermission,
    required this.notes,
    required this.medication,
    required this.allergies,
    required this.dietaryRestriction,
  });

  final String classroomCode;
  final String studentCode;
  final String firstName;
  final String lastName;
  final String? profilePictureUrl;
  final String status;
  final bool expectedToday;
  final bool signedIn;
  final bool absent;
  final bool notMarked;
  final bool nap;
  final bool photoPermission;
  final bool notes;
  final bool medication;
  final bool allergies;
  final bool dietaryRestriction;

  String get fullName => ('$firstName $lastName').trim();

  @override
  List<Object?> get props => [
    classroomCode,
    studentCode,
    firstName,
    lastName,
    profilePictureUrl,
    status,
    expectedToday,
    signedIn,
    absent,
    notMarked,
    nap,
    photoPermission,
    notes,
    medication,
    allergies,
    dietaryRestriction,
  ];
}
