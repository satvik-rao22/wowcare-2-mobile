import 'package:equatable/equatable.dart';

/// Domain entity representing user details from /api/v1/users/details.
class UserDetailsEntity extends Equatable {
  const UserDetailsEntity({
    required this.data,
  });

  final List<UserDetailEntity> data;

  @override
  List<Object?> get props => [data];
}

class UserDetailEntity extends Equatable {
  const UserDetailEntity({
    required this.userCode,
    required this.organizationCode,
    required this.organizationName,
    required this.schools,
  });

  final String userCode;
  final String organizationCode;
  final String organizationName;
  final List<SchoolDetailEntity> schools;

  @override
  List<Object?> get props =>
      [userCode, organizationCode, organizationName, schools];
}

class SchoolDetailEntity extends Equatable {
  const SchoolDetailEntity({
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
  final List<PermissionEntity> permissions;

  @override
  List<Object?> get props => [schoolCode, schoolName, status, role, permissions];
}

class PermissionEntity extends Equatable {
  const PermissionEntity({
    required this.module,
    required this.read,
    required this.write,
  });

  final String module;
  final bool read;
  final bool write;

  @override
  List<Object?> get props => [module, read, write];
}
