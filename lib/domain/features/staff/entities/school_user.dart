class SchoolUser {
  const SchoolUser({
    required this.userCode,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.mobile,
    required this.email,
    required this.organizationCode,
    required this.schoolCode,
    required this.role,
    required this.designation,
    this.status,
    this.primaryClassroomCode,
    this.allowedClassroomCodes,
  });

  final String userCode;
  final String firstName;
  final String lastName;
  final String displayName;
  final String mobile;
  final String email;
  final String organizationCode;
  final String schoolCode;
  final String role;
  final String designation;

  // Staff-only fields
  final String? status;
  final String? primaryClassroomCode;
  final List<String>? allowedClassroomCodes;
}


