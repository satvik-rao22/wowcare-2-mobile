import 'package:equatable/equatable.dart';

class StaffMember extends Equatable {
  const StaffMember({
    required this.code,
    required this.name,
    required this.primaryClassroomCode,
    required this.allowedClassroomCodes,
    required this.designation,
    required this.phoneNumber,
    required this.status,
    required this.email,
  });

  final String code;
  final String name;
  final String primaryClassroomCode;
  final List<String> allowedClassroomCodes;
  final String designation;
  final String phoneNumber;
  final String status;
  final String email;

  /// Backward-compatible alias for older UI code.
  List<String> get classroomCodes => allowedClassroomCodes;

  /// Backward-compatible alias for older UI code.
  String get primaryClassroom => primaryClassroomOrFirstAllowed;

  /// Fallback helper when primary classroom isn't set but allowed classrooms exist.
  String get primaryClassroomOrFirstAllowed =>
      primaryClassroomCode.isNotEmpty
          ? primaryClassroomCode
          : (allowedClassroomCodes.isNotEmpty ? allowedClassroomCodes.first : '');

  @override
  List<Object?> get props =>
      [
        code,
        name,
        primaryClassroomCode,
        allowedClassroomCodes,
        designation,
        phoneNumber,
        status,
        email,
      ];
}

class StaffPage extends Equatable {
  const StaffPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<StaffMember> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  @override
  List<Object?> get props =>
      [items, page, size, totalPages, totalElements, hasMore];
}


