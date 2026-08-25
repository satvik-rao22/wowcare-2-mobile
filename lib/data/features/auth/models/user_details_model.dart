import 'package:equatable/equatable.dart';

/// DTO for the /api/v1/users/details API response.
///
/// Maps the API response structure:
/// {
///   "success": true,
///   "data": [
///     {
///       "userCode": "string",
///       "organizationCode": "string",
///       "organizationName": "string",
///       "schools": [
///         {
///           "schoolCode": "string",
///           "schoolName": "string",
///           "status": "string",
///           "role": "string",
///           "permissions": [
///             {
///               "module": "string",
///               "read": true,
///               "write": true
///             }
///           ]
///         }
///       ]
///     }
///   ]
/// }
class UserDetailsResponseModel extends Equatable {
  const UserDetailsResponseModel({required this.data});

  final List<UserDetailModel> data;

  factory UserDetailsResponseModel.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    return UserDetailsResponseModel(
      data: dataList
          .whereType<Map<String, dynamic>>()
          .map(UserDetailModel.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [data];
}

class UserDetailModel extends Equatable {
  const UserDetailModel({
    required this.userCode,
    required this.organizationCode,
    required this.organizationName,
    required this.schools,
  });

  final String userCode;
  final String organizationCode;
  final String organizationName;
  final List<SchoolDetailModel> schools;

  factory UserDetailModel.fromJson(Map<String, dynamic> json) {
    final schoolsList = json['schools'] as List<dynamic>? ?? [];
    return UserDetailModel(
      userCode: (json['userCode'] as String?) ?? '',
      organizationCode: (json['organizationCode'] as String?) ?? '',
      organizationName: (json['organizationName'] as String?) ?? '',
      schools: schoolsList
          .whereType<Map<String, dynamic>>()
          .map(SchoolDetailModel.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    userCode,
    organizationCode,
    organizationName,
    schools,
  ];
}

class SchoolDetailModel extends Equatable {
  const SchoolDetailModel({
    required this.schoolCode,
    required this.schoolName,
    required this.status,
    required this.role,
    required this.permissions,
  });

  final String schoolCode;
  final String schoolName;
  final String status;
  final String role;
  final List<PermissionModel> permissions;

  factory SchoolDetailModel.fromJson(Map<String, dynamic> json) {
    final permissionsList = json['permissions'] as List<dynamic>? ?? [];
    return SchoolDetailModel(
      schoolCode: (json['schoolCode'] as String?) ?? '',
      schoolName: (json['schoolName'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      role: (json['role'] as String?) ?? '',
      permissions: permissionsList
          .whereType<Map<String, dynamic>>()
          .map(PermissionModel.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    schoolCode,
    schoolName,
    status,
    role,
    permissions,
  ];
}

class PermissionModel extends Equatable {
  const PermissionModel({
    required this.module,
    required this.read,
    required this.write,
  });

  final String module;
  final bool read;
  final bool write;

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      module: (json['module'] as String?) ?? '',
      read: (json['read'] as bool?) ?? false,
      write: (json['write'] as bool?) ?? false,
    );
  }

  @override
  List<Object?> get props => [module, read, write];
}
