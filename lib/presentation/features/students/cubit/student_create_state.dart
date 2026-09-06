part of 'student_create_cubit.dart';

class StudentCreateState extends Equatable {
  static const Object _unset = Object();

  const StudentCreateState({
    required this.mutationInProgress,
    this.errorMessage,
    // Step 1 form model
    this.step1Status,
    this.step1Classroom,
    this.step1Birthdate,
    this.step1SchoolStartDate,
    this.step1ProfilePhoto,
    this.step1AgeLabel,
    this.step1Submitting = false,
    // Step 2 form model
    this.step2SelectFromExisting = false,
    this.step2SelectedExistingParents = const <String>[],
    this.step2Relation,
    this.step2IsEmergencyContact = true,
    this.step2IsChildCustody = true,
    this.step2ProfilePhoto,
    this.step2ExistingParents = const <String>[],
    this.step2Submitting = false,
  });

  const StudentCreateState.initial()
      : mutationInProgress = false,
        errorMessage = null,
        step1Status = null,
        step1Classroom = null,
        step1Birthdate = null,
        step1SchoolStartDate = null,
        step1ProfilePhoto = null,
        step1AgeLabel = null,
        step1Submitting = false,
        step2SelectFromExisting = false,
        step2SelectedExistingParents = const <String>[],
        step2Relation = null,
        step2IsEmergencyContact = true,
        step2IsChildCustody = true,
        step2ProfilePhoto = null,
        step2ExistingParents = const <String>[],
        step2Submitting = false;

  final bool mutationInProgress;
  final String? errorMessage;

  /// Step-1 (student details) form model — owned here so the wizard's first
  /// screen holds no competing `setState` copies. [step1Submitting] is a
  /// FLOW-level flag spanning the create → sibling-link → hand-off sequence
  /// (distinct from the per-call [mutationInProgress]); [step1AgeLabel] is
  /// derived from [step1Birthdate].
  final String? step1Status;
  final String? step1Classroom;
  final DateTime? step1Birthdate;
  final DateTime? step1SchoolStartDate;
  final File? step1ProfilePhoto;
  final String? step1AgeLabel;
  final bool step1Submitting;

  /// Step-2 (add-parent) form model. [step2Submitting] is a flow-level flag
  /// spanning the guardian create/link + background photo upload.
  final bool step2SelectFromExisting;
  final List<String> step2SelectedExistingParents;
  final String? step2Relation;
  final bool step2IsEmergencyContact;
  final bool step2IsChildCustody;
  final File? step2ProfilePhoto;
  final List<String> step2ExistingParents;
  final bool step2Submitting;

  StudentCreateState copyWith({
    bool? mutationInProgress,
    String? errorMessage,
    Object? step1Status = _unset,
    Object? step1Classroom = _unset,
    Object? step1Birthdate = _unset,
    Object? step1SchoolStartDate = _unset,
    Object? step1ProfilePhoto = _unset,
    Object? step1AgeLabel = _unset,
    bool? step1Submitting,
    bool? step2SelectFromExisting,
    List<String>? step2SelectedExistingParents,
    Object? step2Relation = _unset,
    bool? step2IsEmergencyContact,
    bool? step2IsChildCustody,
    Object? step2ProfilePhoto = _unset,
    List<String>? step2ExistingParents,
    bool? step2Submitting,
  }) {
    return StudentCreateState(
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
      errorMessage: errorMessage,
      step1Status:
          step1Status == _unset ? this.step1Status : step1Status as String?,
      step1Classroom: step1Classroom == _unset
          ? this.step1Classroom
          : step1Classroom as String?,
      step1Birthdate: step1Birthdate == _unset
          ? this.step1Birthdate
          : step1Birthdate as DateTime?,
      step1SchoolStartDate: step1SchoolStartDate == _unset
          ? this.step1SchoolStartDate
          : step1SchoolStartDate as DateTime?,
      step1ProfilePhoto: step1ProfilePhoto == _unset
          ? this.step1ProfilePhoto
          : step1ProfilePhoto as File?,
      step1AgeLabel: step1AgeLabel == _unset
          ? this.step1AgeLabel
          : step1AgeLabel as String?,
      step1Submitting: step1Submitting ?? this.step1Submitting,
      step2SelectFromExisting:
          step2SelectFromExisting ?? this.step2SelectFromExisting,
      step2SelectedExistingParents:
          step2SelectedExistingParents ?? this.step2SelectedExistingParents,
      step2Relation:
          step2Relation == _unset ? this.step2Relation : step2Relation as String?,
      step2IsEmergencyContact:
          step2IsEmergencyContact ?? this.step2IsEmergencyContact,
      step2IsChildCustody: step2IsChildCustody ?? this.step2IsChildCustody,
      step2ProfilePhoto: step2ProfilePhoto == _unset
          ? this.step2ProfilePhoto
          : step2ProfilePhoto as File?,
      step2ExistingParents: step2ExistingParents ?? this.step2ExistingParents,
      step2Submitting: step2Submitting ?? this.step2Submitting,
    );
  }

  @override
  List<Object?> get props => [
        mutationInProgress,
        errorMessage,
        step1Status,
        step1Classroom,
        step1Birthdate,
        step1SchoolStartDate,
        step1ProfilePhoto,
        step1AgeLabel,
        step1Submitting,
        step2SelectFromExisting,
        step2SelectedExistingParents,
        step2Relation,
        step2IsEmergencyContact,
        step2IsChildCustody,
        step2ProfilePhoto,
        step2ExistingParents,
        step2Submitting,
      ];
}
