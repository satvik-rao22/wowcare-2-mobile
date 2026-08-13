part of 'student_transfer_selection_cubit.dart';

class StudentTransferSelectionState extends Equatable {
  const StudentTransferSelectionState({
    this.isLoadingFilters = false,
    this.filtersReady = false,
    this.isLoadingStudents = false,
    this.studentsError,
    this.filtersMessage,
    this.classroomOptions = const <String>[],
    this.classroomCodeByName = const <String, String>{},
    this.classroomNameByCode = const <String, String>{},
    this.tagOptions = const <String>[],
    this.tagCodeByName = const <String, String>{},
    this.students = const <StudentAttendanceCustomItem>[],
  });

  final bool isLoadingFilters;
  final bool filtersReady;
  final bool isLoadingStudents;
  final String? studentsError;
  final String? filtersMessage;

  final List<String> classroomOptions;
  final Map<String, String> classroomCodeByName;
  final Map<String, String> classroomNameByCode;
  final List<String> tagOptions;
  final Map<String, String> tagCodeByName;
  final List<StudentAttendanceCustomItem> students;

  StudentTransferSelectionState copyWith({
    bool? isLoadingFilters,
    bool? filtersReady,
    bool? isLoadingStudents,
    String? studentsError,
    bool clearStudentsError = false,
    String? filtersMessage,
    bool clearFiltersMessage = false,
    List<String>? classroomOptions,
    Map<String, String>? classroomCodeByName,
    Map<String, String>? classroomNameByCode,
    List<String>? tagOptions,
    Map<String, String>? tagCodeByName,
    List<StudentAttendanceCustomItem>? students,
  }) {
    return StudentTransferSelectionState(
      isLoadingFilters: isLoadingFilters ?? this.isLoadingFilters,
      filtersReady: filtersReady ?? this.filtersReady,
      isLoadingStudents: isLoadingStudents ?? this.isLoadingStudents,
      studentsError: clearStudentsError
          ? null
          : (studentsError ?? this.studentsError),
      filtersMessage: clearFiltersMessage
          ? null
          : (filtersMessage ?? this.filtersMessage),
      classroomOptions: classroomOptions ?? this.classroomOptions,
      classroomCodeByName: classroomCodeByName ?? this.classroomCodeByName,
      classroomNameByCode: classroomNameByCode ?? this.classroomNameByCode,
      tagOptions: tagOptions ?? this.tagOptions,
      tagCodeByName: tagCodeByName ?? this.tagCodeByName,
      students: students ?? this.students,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    isLoadingFilters,
    filtersReady,
    isLoadingStudents,
    studentsError,
    filtersMessage,
    classroomOptions,
    classroomCodeByName,
    classroomNameByCode,
    tagOptions,
    tagCodeByName,
    students,
  ];
}
