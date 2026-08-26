part of 'select_students_cubit.dart';

class SelectStudentsState extends Equatable {
  const SelectStudentsState({
    required this.students,
    required this.classroomNames,
    required this.classroomNameToCode,
    required this.tagNames,
    required this.tagNameToCode,
    required this.selectedClassroomNames,
    required this.selectedTagNames,
    required this.selectedStatus,
    required this.searchQuery,
    required this.selectedStudentCodes,
    required this.isLoading,
    this.isCheckingRecipients = false,
    this.errorMessage,
  });

  const SelectStudentsState.initial()
      : students = const <Student>[],
        classroomNames = const <String>[],
        classroomNameToCode = const <String, String>{},
        tagNames = const <String>[],
        tagNameToCode = const <String, String>{},
        selectedClassroomNames = const <String>[],
        selectedTagNames = const <String>[],
        selectedStatus = 'Active',
        searchQuery = '',
        selectedStudentCodes = const <String>{},
        isLoading = true,
        isCheckingRecipients = false,
        errorMessage = null;

  /// Server-filtered (ACTIVE + classroom + tag) student list for the page.
  final List<Student> students;

  /// Classroom filter options (display names) + name→code for the API query.
  final List<String> classroomNames;
  final Map<String, String> classroomNameToCode;

  /// Tag filter options (display names) + name→code for the API query.
  final List<String> tagNames;
  final Map<String, String> tagNameToCode;

  final List<String> selectedClassroomNames;
  final List<String> selectedTagNames;

  /// Single-select status filter (display name: Active / Inactive / Upcoming).
  final String selectedStatus;

  final String searchQuery;
  final Set<String> selectedStudentCodes;
  final bool isLoading;

  /// True while the check-recipients call triggered by "Next" is in flight.
  final bool isCheckingRecipients;
  final String? errorMessage;

  /// Client-side search over the server-filtered list (name contains query).
  List<Student> get filteredStudents {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return students;
    return students
        .where((s) => s.fullName.toLowerCase().contains(q))
        .toList();
  }

  SelectStudentsState copyWith({
    List<Student>? students,
    List<String>? classroomNames,
    Map<String, String>? classroomNameToCode,
    List<String>? tagNames,
    Map<String, String>? tagNameToCode,
    List<String>? selectedClassroomNames,
    List<String>? selectedTagNames,
    String? selectedStatus,
    String? searchQuery,
    Set<String>? selectedStudentCodes,
    bool? isLoading,
    bool? isCheckingRecipients,
    String? errorMessage,
  }) {
    return SelectStudentsState(
      students: students ?? this.students,
      classroomNames: classroomNames ?? this.classroomNames,
      classroomNameToCode: classroomNameToCode ?? this.classroomNameToCode,
      tagNames: tagNames ?? this.tagNames,
      tagNameToCode: tagNameToCode ?? this.tagNameToCode,
      selectedClassroomNames:
          selectedClassroomNames ?? this.selectedClassroomNames,
      selectedTagNames: selectedTagNames ?? this.selectedTagNames,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStudentCodes: selectedStudentCodes ?? this.selectedStudentCodes,
      isLoading: isLoading ?? this.isLoading,
      isCheckingRecipients: isCheckingRecipients ?? this.isCheckingRecipients,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        students,
        classroomNames,
        classroomNameToCode,
        tagNames,
        tagNameToCode,
        selectedClassroomNames,
        selectedTagNames,
        selectedStatus,
        searchQuery,
        selectedStudentCodes,
        isLoading,
        isCheckingRecipients,
        errorMessage,
      ];
}
