part of 'select_students_cubit.dart';

class SelectStudentsState extends Equatable {
  const SelectStudentsState({
    required this.students,
    required this.classrooms,
    required this.tags,
    required this.selectedClassroom,
    required this.selectedTag,
    required this.searchQuery,
    required this.selectedStudentIds,
    required this.isLoading,
  });

  const SelectStudentsState.initial()
      : students = const [],
        classrooms = const ['Select Classroom'],
        tags = const ['Select Tags'],
        selectedClassroom = 'Select Classroom',
        selectedTag = 'Select Tags',
        searchQuery = '',
        selectedStudentIds = const <int>{},
        isLoading = true;

  final List<Student> students;
  final List<String> classrooms;
  final List<String> tags;
  final String selectedClassroom;
  final String selectedTag;
  final String searchQuery;
  final Set<int> selectedStudentIds;
  final bool isLoading;

  List<Student> get filteredStudents {
    return students.where((student) {
      final matchesSearch =
          student.fullName.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesClassroom = selectedClassroom == 'Select Classroom' ||
          student.roomName == selectedClassroom;
      final matchesTag = selectedTag == 'Select Tags' ||
          student.tags.any((tag) => tag.name == selectedTag);
      return matchesSearch && matchesClassroom && matchesTag;
    }).toList();
  }

  SelectStudentsState copyWith({
    List<Student>? students,
    List<String>? classrooms,
    List<String>? tags,
    String? selectedClassroom,
    String? selectedTag,
    String? searchQuery,
    Set<int>? selectedStudentIds,
    bool? isLoading,
  }) {
    return SelectStudentsState(
      students: students ?? this.students,
      classrooms: classrooms ?? this.classrooms,
      tags: tags ?? this.tags,
      selectedClassroom: selectedClassroom ?? this.selectedClassroom,
      selectedTag: selectedTag ?? this.selectedTag,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStudentIds: selectedStudentIds ?? this.selectedStudentIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        students,
        classrooms,
        tags,
        selectedClassroom,
        selectedTag,
        searchQuery,
        selectedStudentIds,
        isLoading,
      ];
}
