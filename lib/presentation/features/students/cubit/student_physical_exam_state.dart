part of 'student_physical_exam_cubit.dart';

class StudentPhysicalExamState extends Equatable {
  static const Object _unset = Object();

  const StudentPhysicalExamState({
    required this.mutationInProgress,
    this.exams = const [],
    this.isLoading = false,
    this.errorMessage,
    this.formExamDate,
    this.formStatus,
  });

  const StudentPhysicalExamState.initial()
      : mutationInProgress = false,
        exams = const [],
        isLoading = false,
        errorMessage = null,
        formExamDate = null,
        formStatus = null;

  final bool mutationInProgress;

  /// The cubit owns the physical-exam list (single source of truth for the card).
  final List<StudentPhysicalExam> exams;
  final bool isLoading;
  final String? errorMessage;

  /// The add/edit form model — the exam date + display status being composed.
  /// Owned here so the editor screen no longer keeps competing `setState` copies.
  final DateTime? formExamDate;
  final String? formStatus;

  StudentPhysicalExamState copyWith({
    bool? mutationInProgress,
    List<StudentPhysicalExam>? exams,
    bool? isLoading,
    String? errorMessage,
    Object? formExamDate = _unset,
    Object? formStatus = _unset,
  }) {
    return StudentPhysicalExamState(
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
      exams: exams ?? this.exams,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      formExamDate:
          formExamDate == _unset ? this.formExamDate : formExamDate as DateTime?,
      formStatus:
          formStatus == _unset ? this.formStatus : formStatus as String?,
    );
  }

  @override
  List<Object?> get props =>
      [mutationInProgress, exams, isLoading, errorMessage, formExamDate, formStatus];
}
