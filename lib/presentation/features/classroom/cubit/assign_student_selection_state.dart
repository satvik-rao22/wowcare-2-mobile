import 'package:equatable/equatable.dart';

import '../../../../domain/features/student/entities/student.dart';
import '../../students/widgets/student_attendance_action_availability.dart';

class AssignStudentSelectionState extends Equatable {
  const AssignStudentSelectionState({
    this.allStudents = const [],
    this.rooms = const [],
    this.tags = const [],
    this.selectedClassroom,
    this.selectedTags = const [],
    this.searchText = '',
    this.selectedStudents = const {},
    this.todayStatusByCode = const {},
    this.isLoading = false,
    this.errorMessage,
    this.excludeClassroomCode = '',
  });

  final List<Student> allStudents;

  /// Classroom display names for the Classroom filter dropdown.
  final List<String> rooms;

  /// Tag display names for the Tags multi-select.
  final List<String> tags;

  final String? selectedClassroom;
  final List<String> selectedTags;
  final String searchText;
  final Set<Student> selectedStudents;

  /// Today's sign-in status per student code.
  final Map<String, String> todayStatusByCode;

  final bool isLoading;
  final String? errorMessage;

  /// The target classroom — a student currently assigned there is excluded
  /// from the pickable roster.
  final String excludeClassroomCode;

  /// [allStudents] is already scoped server-side by Classroom/Tags; this
  /// applies the target-classroom exclusion and the client-side free-text
  /// search.
  List<Student> get visibleStudents {
    final query = searchText.trim().toLowerCase();
    final excludeCode = excludeClassroomCode.trim().toUpperCase();
    return allStudents.where((student) {
      if (excludeCode.isNotEmpty &&
          student.classroomCode.trim().toUpperCase() == excludeCode) {
        return false;
      }
      if (query.isEmpty) return true;
      return student.fullName.toLowerCase().contains(query);
    }).toList();
  }

  bool isStudentSignedIn(String studentCode) {
    final gate = studentAttendanceGateFromTodayStatus(
      isActiveProfile: true,
      todayStatusRaw: todayStatusByCode[studentCode],
    );
    return gate.isSignedInToday;
  }

  bool get isSelectAllChecked {
    final selectable = visibleStudents.where(
      (s) => !isStudentSignedIn(s.code),
    );
    return selectable.isNotEmpty &&
        selectable.every((s) => selectedStudents.contains(s));
  }

  AssignStudentSelectionState copyWith({
    List<Student>? allStudents,
    List<String>? rooms,
    List<String>? tags,
    String? selectedClassroom,
    List<String>? selectedTags,
    String? searchText,
    Set<Student>? selectedStudents,
    Map<String, String>? todayStatusByCode,
    bool? isLoading,
    String? errorMessage,
    String? excludeClassroomCode,
  }) {
    return AssignStudentSelectionState(
      allStudents: allStudents ?? this.allStudents,
      rooms: rooms ?? this.rooms,
      tags: tags ?? this.tags,
      selectedClassroom: selectedClassroom ?? this.selectedClassroom,
      selectedTags: selectedTags ?? this.selectedTags,
      searchText: searchText ?? this.searchText,
      selectedStudents: selectedStudents ?? this.selectedStudents,
      todayStatusByCode: todayStatusByCode ?? this.todayStatusByCode,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      excludeClassroomCode: excludeClassroomCode ?? this.excludeClassroomCode,
    );
  }

  @override
  List<Object?> get props => [
    allStudents,
    rooms,
    tags,
    selectedClassroom,
    selectedTags,
    searchText,
    selectedStudents,
    todayStatusByCode,
    isLoading,
    errorMessage,
    excludeClassroomCode,
  ];
}
