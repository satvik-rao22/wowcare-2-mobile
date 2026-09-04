part of 'add_student_cubit.dart';

enum AddStudentStatus { editing, saving, saved, failed }

@immutable
class AddStudentState extends Equatable {
  const AddStudentState({
    this.status = AddStudentStatus.editing,
    this.step = 1,
    this.draft = const StudentDraft(),
    this.errors = const <StudentField, String>{},
    this.hasTriedStep = false,
    this.isLoadingOptions = true,
    this.classrooms = const <String>[],
    this.guardians = const <GuardianOption>[],
    this.siblings = const <StudentSummary>[],
    this.isCheckingSiblings = false,
    this.hasCheckedSiblings = false,
    this.saved,
  });

  final AddStudentStatus status;

  /// 1 the student, 2 a parent, 3 the schedule.
  final int step;

  final StudentDraft draft;

  /// What is wrong right now. Empty until the step is tried, then live.
  final Map<StudentField, String> errors;
  final bool hasTriedStep;

  final bool isLoadingOptions;
  final List<String> classrooms;
  final List<GuardianOption> guardians;

  /// Students already enrolled with the same last name. Non-empty puts the
  /// sibling question in front of step two.
  final List<StudentSummary> siblings;
  final bool isCheckingSiblings;
  final bool hasCheckedSiblings;

  /// The student that was written. Set once, when [status] is saved.
  final StudentSummary? saved;

  bool get isSaving => status == AddStudentStatus.saving;
  bool get isSaved => status == AddStudentStatus.saved;
  bool get hasFailed => status == AddStudentStatus.failed;

  bool get isBusy => isSaving || isCheckingSiblings;

  bool get canGoBack => step > 1;

  /// Steps two and three carry an Optional badge and a quiet skip key.
  bool get canSkip => step > 1;

  /// The pink key's label: the next step, or the save.
  String get primaryLabel => switch (step) {
    1 => StudentsStrings.nextGuardian,
    2 => StudentsStrings.nextSchedule,
    _ => StudentsStrings.saveStudent(draft.fullName),
  };

  String get skipLabel =>
      step == 2 ? StudentsStrings.skipGuardian : StudentsStrings.skipSchedule;

  String? errorFor(StudentField field) => errors[field];

  AddStudentState copyWith({
    AddStudentStatus? status,
    int? step,
    StudentDraft? draft,
    Map<StudentField, String>? errors,
    bool? hasTriedStep,
    bool? isLoadingOptions,
    List<String>? classrooms,
    List<GuardianOption>? guardians,
    List<StudentSummary>? siblings,
    bool? isCheckingSiblings,
    bool? hasCheckedSiblings,
    StudentSummary? saved,
  }) => AddStudentState(
    status: status ?? this.status,
    step: step ?? this.step,
    draft: draft ?? this.draft,
    errors: errors ?? this.errors,
    hasTriedStep: hasTriedStep ?? this.hasTriedStep,
    isLoadingOptions: isLoadingOptions ?? this.isLoadingOptions,
    classrooms: classrooms ?? this.classrooms,
    guardians: guardians ?? this.guardians,
    siblings: siblings ?? this.siblings,
    isCheckingSiblings: isCheckingSiblings ?? this.isCheckingSiblings,
    hasCheckedSiblings: hasCheckedSiblings ?? this.hasCheckedSiblings,
    saved: saved ?? this.saved,
  );

  @override
  List<Object?> get props => [
    status,
    step,
    draft,
    errors,
    hasTriedStep,
    isLoadingOptions,
    classrooms,
    guardians,
    siblings,
    isCheckingSiblings,
    hasCheckedSiblings,
    saved,
  ];
}
