import 'package:equatable/equatable.dart';

class StaffClassroomItem extends Equatable {
  const StaffClassroomItem({
    required this.classroomCode,
    required this.staffCode,
    this.userCode = '',
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
  /// User account code (USR_*) — the participant identifier for messaging.
  final String userCode;
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
        userCode,
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

