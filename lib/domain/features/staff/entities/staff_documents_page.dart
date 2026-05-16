import 'package:equatable/equatable.dart';
import 'staff_document.dart';

class StaffDocumentsPage extends Equatable {
  const StaffDocumentsPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<StaffDocument> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  @override
  List<Object?> get props => [
    items,
    page,
    size,
    totalPages,
    totalElements,
    hasMore,
  ];
}
