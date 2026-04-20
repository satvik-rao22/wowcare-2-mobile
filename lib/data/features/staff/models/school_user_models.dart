class CreateSchoolUserRequestModel {
  const CreateSchoolUserRequestModel({
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.mobile,
    required this.email,
    required this.organizationCode,
    required this.schoolCode,
    required this.role,
    required this.designation,
    this.userCode,
  });

  final String? userCode;
  final String firstName;
  final String lastName;
  final String displayName;
  final String mobile;
  final String email;
  final String organizationCode;
  final String schoolCode;
  final String role;
  final String designation;

  Map<String, dynamic> toJson() {
    return {
      if (userCode != null) 'userCode': userCode,
      'firstName': firstName,
      'lastName': lastName,
      'displayName': displayName,
      'mobile': mobile,
      'email': email,
      'organizationCode': organizationCode,
      'schoolCode': schoolCode,
      'role': role,
      'designation': designation,
    };
  }
}

class CreateStaffUserRequestModel {
  const CreateStaffUserRequestModel({
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.mobile,
    required this.email,
    required this.organizationCode,
    required this.schoolCode,
    required this.role,
    required this.designation,
    required this.status,
    required this.primaryClassroomCode,
    required this.allowedClassroomCodes,
    this.userCode,
  });

  final String? userCode;
  final String firstName;
  final String lastName;
  final String displayName;
  final String mobile;
  final String email;
  final String organizationCode;
  final String schoolCode;
  final String role;
  final String designation;
  final String status;
  final String primaryClassroomCode;
  final List<String> allowedClassroomCodes;

  Map<String, dynamic> toJson() {
    return {
      if (userCode != null) 'userCode': userCode,
      'firstName': firstName,
      'lastName': lastName,
      'displayName': displayName,
      'mobile': mobile,
      'email': email,
      'organizationCode': organizationCode,
      'schoolCode': schoolCode,
      'role': role,
      'designation': designation,
      'status': status,
      'primaryClassroomCode': primaryClassroomCode,
      'allowedClassroomCodes': allowedClassroomCodes,
    };
  }
}

class SchoolUserModel {
  const SchoolUserModel({
    required this.userCode,
    this.staffCode,
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
  final String? staffCode;
  final String firstName;
  final String lastName;
  final String displayName;
  final String mobile;
  final String email;
  final String organizationCode;
  final String schoolCode;
  final String role;
  final String designation;

  // Staff-only fields (present only for /school-users/staff)
  final String? status;
  final String? primaryClassroomCode;
  final List<String>? allowedClassroomCodes;

  factory SchoolUserModel.fromJson(Map<String, dynamic> json) {
    return SchoolUserModel(
      userCode: json['userCode'] as String? ?? '',
      staffCode: json['staffCode'] as String?,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      email: json['email'] as String? ?? '',
      organizationCode: json['organizationCode'] as String? ?? '',
      schoolCode: json['schoolCode'] as String? ?? '',
      role: json['role'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      status: json['status'] as String?,
      primaryClassroomCode: json['primaryClassroomCode'] as String?,
      allowedClassroomCodes: (json['allowedClassroomCodes'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }
}

class CreateSchoolUserResponseModel {
  const CreateSchoolUserResponseModel({
    required this.success,
    required this.message,
    required this.data,
    required this.timestamp,
  });

  final bool success;
  final String message;
  final SchoolUserModel? data;
  final String? timestamp;

  factory CreateSchoolUserResponseModel.fromJson(Map<String, dynamic> json) {
    return CreateSchoolUserResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] is Map<String, dynamic>
          ? SchoolUserModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      timestamp: json['timestamp']?.toString(),
    );
  }
}


