import 'package:equatable/equatable.dart';

class StaffClassroomItem extends Equatable {
  const StaffClassroomItem({
    required this.classroomCode,
    required this.staffCode,
    required this.firstName,
    required this.lastName,
    this.profilePictureUrl,
    required this.status,
    required this.designation,
    required this.expectedToday,
    required this.signedIn,
    required this.absent,
    required this.notMarked,
  });

  final String classroomCode;
  final String staffCode;
  final String firstName;
  final String lastName;
  final String? profilePictureUrl;
  final String status;
  final String designation;
  final bool expectedToday;
  final bool signedIn;
  final bool absent;
  final bool notMarked;

  String get fullName => ('$firstName $lastName').trim();

  @override
  List<Object?> get props => [
        classroomCode,
        staffCode,
        firstName,
        lastName,
        profilePictureUrl,
        status,
        designation,
        expectedToday,
        signedIn,
        absent,
        notMarked,
      ];
}

