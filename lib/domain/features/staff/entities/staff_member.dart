import 'package:equatable/equatable.dart';

class StaffMember extends Equatable {
  const StaffMember({
    required this.code,
    required this.name,
    required this.classroomCodes,
    required this.designation,
    required this.phoneNumber,
    required this.status,
  });

  final String code;
  final String name;
  final List<String> classroomCodes;
  final String designation;
  final String phoneNumber;
  final String status;

  String get primaryClassroom =>
      classroomCodes.isNotEmpty ? classroomCodes.first : '';

  @override
  List<Object?> get props =>
      [code, name, classroomCodes, designation, phoneNumber, status];
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


