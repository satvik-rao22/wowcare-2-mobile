import 'package:equatable/equatable.dart';
import 'student_document.dart';

class StudentDocumentsPage extends Equatable {
  const StudentDocumentsPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<StudentDocument> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  @override
  List<Object?> get props => [items, page, size, totalPages, totalElements, hasMore];
}
