import 'package:equatable/equatable.dart';

class ClassroomCount extends Equatable {
  const ClassroomCount({
    required this.total,
    required this.adminCount,
    required this.classroomCount,
  });

  final int total;
  final int adminCount;
  final int classroomCount;

  @override
  List<Object?> get props => [total, adminCount, classroomCount];
}
