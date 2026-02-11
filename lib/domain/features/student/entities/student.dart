import 'package:equatable/equatable.dart';

class Student extends Equatable {
  const Student({
    required this.code,
    required this.firstName,
    required this.lastName,
    required this.status,
    this.classroom = '',
    this.dob = '',
    this.movementDate = '',
  });

  final String code;
  final String firstName;
  final String lastName;
  final String status;
  final String classroom;
  final String dob;
  final String movementDate;

  String get fullName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [
        code,
        firstName,
        lastName,
        status,
        classroom,
        dob,
        movementDate,
      ];
}

class StudentPage extends Equatable {
  const StudentPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<Student> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  @override
  List<Object?> get props =>
      [items, page, size, totalPages, totalElements, hasMore];
}

