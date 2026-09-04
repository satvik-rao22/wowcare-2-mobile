part of 'edit_student_cubit.dart';

enum EditStudentStatus { loading, ready, saving, saved, failed }

@immutable
class EditStudentState extends Equatable {
  const EditStudentState({
    required this.studentId,
    this.status = EditStudentStatus.loading,
    this.draft = const StudentDraft(),
    this.original,
    this.errors = const <StudentField, String>{},
    this.hasTriedSave = false,
    this.hasSaveFailed = false,
    this.classrooms = const <String>[],
    this.tagNames = const <String>[],
  });

  final String studentId;
  final EditStudentStatus status;
  final StudentDraft draft;

  /// The record as it was, so the header can name the student even while a
  /// field is being emptied.
  final StudentSummary? original;

  final Map<StudentField, String> errors;
  final bool hasTriedSave;
  final bool hasSaveFailed;

  final List<String> classrooms;
  final List<String> tagNames;

  bool get isLoading => status == EditStudentStatus.loading;
  bool get isSaving => status == EditStudentStatus.saving;
  bool get isSaved => status == EditStudentStatus.saved;
  bool get isFailed => status == EditStudentStatus.failed;

  /// The one thing the frame's disabled Save key is saying.
  bool get hasProblems => errors.isNotEmpty;

  /// Save is off while anything is wrong, and while a save is in flight.
  bool get canSave => !hasProblems && !isSaving;

  String get firstName => original?.firstName ?? draft.firstName;

  String? errorFor(StudentField field) => errors[field];

  EditStudentState copyWith({
    EditStudentStatus? status,
    StudentDraft? draft,
    StudentSummary? original,
    Map<StudentField, String>? errors,
    bool? hasTriedSave,
    bool? hasSaveFailed,
    List<String>? classrooms,
    List<String>? tagNames,
  }) => EditStudentState(
    studentId: studentId,
    status: status ?? this.status,
    draft: draft ?? this.draft,
    original: original ?? this.original,
    errors: errors ?? this.errors,
    hasTriedSave: hasTriedSave ?? this.hasTriedSave,
    hasSaveFailed: hasSaveFailed ?? this.hasSaveFailed,
    classrooms: classrooms ?? this.classrooms,
    tagNames: tagNames ?? this.tagNames,
  );

  @override
  List<Object?> get props => [
    studentId,
    status,
    draft,
    original,
    errors,
    hasTriedSave,
    hasSaveFailed,
    classrooms,
    tagNames,
  ];
}
