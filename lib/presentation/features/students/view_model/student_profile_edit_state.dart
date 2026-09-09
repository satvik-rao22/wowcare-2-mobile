part of 'student_profile_edit_cubit.dart';

class StudentProfileEditState extends Equatable {
  static const Object _unset = Object();

  const StudentProfileEditState({
    required this.mutationInProgress,
    this.errorMessage,
    // --- form model (dropdowns / dates) ---
    this.status,
    this.stateSubsidyOption,
    this.classroom,
    this.classroomChangedByUser = false,
    this.birthDate,
    this.stateName,
    this.country,
    this.gender,
    // --- multi-selects ---
    this.selectedSiblings = const <String>[],
    this.selectedTags = const <String>[],
    this.selectedChildCustody = const <String>[],
    // --- submit + attendance gate ---
    this.submitting = false,
    this.isTodayStatusLoading = true,
    this.isSignedInToday = false,
    // --- server-fetched options + code maps ---
    this.availableTagNames = const <String>[],
    this.tagNameToCode = const <String, String>{},
    this.availableStudentNames = const <String>[],
    this.studentNameToCode = const <String, String>{},
    this.availableGuardianNames = const <String>[],
    this.guardianNameToCode = const <String, String>{},
    this.guardianInitialCustody = const <String, bool>{},
    this.guardianRawByCode = const <String, StudentGuardian>{},
  });

  const StudentProfileEditState.initial()
    : mutationInProgress = false,
      errorMessage = null,
      status = null,
      stateSubsidyOption = null,
      classroom = null,
      classroomChangedByUser = false,
      birthDate = null,
      stateName = null,
      country = null,
      gender = null,
      selectedSiblings = const <String>[],
      selectedTags = const <String>[],
      selectedChildCustody = const <String>[],
      submitting = false,
      isTodayStatusLoading = true,
      isSignedInToday = false,
      availableTagNames = const <String>[],
      tagNameToCode = const <String, String>{},
      availableStudentNames = const <String>[],
      studentNameToCode = const <String, String>{},
      availableGuardianNames = const <String>[],
      guardianNameToCode = const <String, String>{},
      guardianInitialCustody = const <String, bool>{},
      guardianRawByCode = const <String, StudentGuardian>{};

  final bool mutationInProgress;
  final String? errorMessage;

  final String? status;
  final String? stateSubsidyOption;
  final String? classroom;

  /// True once the user picks a different classroom (gates the classroom-change
  /// side effects at submit).
  final bool classroomChangedByUser;
  final DateTime? birthDate;
  final String? stateName;
  final String? country;
  final String? gender;

  final List<String> selectedSiblings;
  final List<String> selectedTags;
  final List<String> selectedChildCustody;

  /// Flow-level submit flag (spans the profile/address/tags/siblings/guardian
  /// update sequence), distinct from the per-call [mutationInProgress].
  final bool submitting;

  /// Today's sign-in gate — while loading or signed-in the Classroom field is
  /// disabled (fails closed).
  final bool isTodayStatusLoading;
  final bool isSignedInToday;

  final List<String> availableTagNames;
  final Map<String, String> tagNameToCode;
  final List<String> availableStudentNames;
  final Map<String, String> studentNameToCode;
  final List<String> availableGuardianNames;
  final Map<String, String> guardianNameToCode;
  final Map<String, bool> guardianInitialCustody;
  final Map<String, StudentGuardian> guardianRawByCode;

  StudentProfileEditState copyWith({
    bool? mutationInProgress,
    String? errorMessage,
    Object? status = _unset,
    Object? stateSubsidyOption = _unset,
    Object? classroom = _unset,
    bool? classroomChangedByUser,
    Object? birthDate = _unset,
    Object? stateName = _unset,
    Object? country = _unset,
    Object? gender = _unset,
    List<String>? selectedSiblings,
    List<String>? selectedTags,
    List<String>? selectedChildCustody,
    bool? submitting,
    bool? isTodayStatusLoading,
    bool? isSignedInToday,
    List<String>? availableTagNames,
    Map<String, String>? tagNameToCode,
    List<String>? availableStudentNames,
    Map<String, String>? studentNameToCode,
    List<String>? availableGuardianNames,
    Map<String, String>? guardianNameToCode,
    Map<String, bool>? guardianInitialCustody,
    Map<String, StudentGuardian>? guardianRawByCode,
  }) {
    return StudentProfileEditState(
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
      errorMessage: errorMessage,
      status: status == _unset ? this.status : status as String?,
      stateSubsidyOption: stateSubsidyOption == _unset
          ? this.stateSubsidyOption
          : stateSubsidyOption as String?,
      classroom: classroom == _unset ? this.classroom : classroom as String?,
      classroomChangedByUser:
          classroomChangedByUser ?? this.classroomChangedByUser,
      birthDate: birthDate == _unset ? this.birthDate : birthDate as DateTime?,
      stateName: stateName == _unset ? this.stateName : stateName as String?,
      country: country == _unset ? this.country : country as String?,
      gender: gender == _unset ? this.gender : gender as String?,
      selectedSiblings: selectedSiblings ?? this.selectedSiblings,
      selectedTags: selectedTags ?? this.selectedTags,
      selectedChildCustody: selectedChildCustody ?? this.selectedChildCustody,
      submitting: submitting ?? this.submitting,
      isTodayStatusLoading: isTodayStatusLoading ?? this.isTodayStatusLoading,
      isSignedInToday: isSignedInToday ?? this.isSignedInToday,
      availableTagNames: availableTagNames ?? this.availableTagNames,
      tagNameToCode: tagNameToCode ?? this.tagNameToCode,
      availableStudentNames:
          availableStudentNames ?? this.availableStudentNames,
      studentNameToCode: studentNameToCode ?? this.studentNameToCode,
      availableGuardianNames:
          availableGuardianNames ?? this.availableGuardianNames,
      guardianNameToCode: guardianNameToCode ?? this.guardianNameToCode,
      guardianInitialCustody:
          guardianInitialCustody ?? this.guardianInitialCustody,
      guardianRawByCode: guardianRawByCode ?? this.guardianRawByCode,
    );
  }

  @override
  List<Object?> get props => [
    mutationInProgress,
    errorMessage,
    status,
    stateSubsidyOption,
    classroom,
    classroomChangedByUser,
    birthDate,
    stateName,
    country,
    gender,
    selectedSiblings,
    selectedTags,
    selectedChildCustody,
    submitting,
    isTodayStatusLoading,
    isSignedInToday,
    availableTagNames,
    tagNameToCode,
    availableStudentNames,
    studentNameToCode,
    availableGuardianNames,
    guardianNameToCode,
    guardianInitialCustody,
    guardianRawByCode,
  ];
}
