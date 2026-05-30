part of 'reports_cubit.dart';

class ReportsState extends Equatable {
  const ReportsState({
    required this.classroomNames,
    required this.studentNames,
    required this.staffNames,
    required this.tagNames,
  });

  const ReportsState.initial()
      : classroomNames = const <String>[],
        studentNames = const <String>[],
        staffNames = const <String>[],
        tagNames = const <String>[];

  final List<String> classroomNames;
  final List<String> studentNames;
  final List<String> staffNames;
  final List<String> tagNames;

  ReportsState copyWith({
    List<String>? classroomNames,
    List<String>? studentNames,
    List<String>? staffNames,
    List<String>? tagNames,
  }) {
    return ReportsState(
      classroomNames: classroomNames ?? this.classroomNames,
      studentNames: studentNames ?? this.studentNames,
      staffNames: staffNames ?? this.staffNames,
      tagNames: tagNames ?? this.tagNames,
    );
  }

  @override
  List<Object?> get props => [
        classroomNames,
        studentNames,
        staffNames,
        tagNames,
      ];
}
