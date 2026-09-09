part of 'reports_lookup_cubit.dart';

/// Load state of the classroom list a report *form* shows in its dropdown,
/// fetched by [ReportsCubit.loadFormClassrooms].
///
/// Before this existed the fetch was duplicated in seven view files and its
/// failure was swallowed, so a failed fetch left the form showing a reduced
/// (or empty) list with no indication anything had gone wrong.
enum FormClassroomsStatus { initial, loading, loaded, failure }

enum GeneratedReportsLoadingState {
  initial,
  loading,
  refreshing,
  loaded,
  error,
}

class ReportsState extends Equatable {
  const ReportsState({
    required this.classroomNames,
    required this.studentNames,
    required this.staffNames,
    required this.tagNames,
    this.classroomNameToCode = const <String, String>{},
    this.staffNameToCode = const <String, String>{},
    this.studentNameToCode = const <String, String>{},
    this.tagNameToCode = const <String, String>{},
    this.generatedReport,
    this.recentReports = const <ReportMetadataEntity>[],
    this.dynamicTagNames = const <String>[],
    this.isGenerating = false,
    this.generationError,
    this.generationSuccess,
    this.generatedReportsState = GeneratedReportsLoadingState.initial,
    this.generatedReportsError,
    this.allClassroomNames = const <String>[],
    this.allClassroomNameToCode = const <String, String>{},
    this.formClassroomsStatus = FormClassroomsStatus.initial,
    this.formClassroomsError,
    this.formStudentsLoading = false,
    this.vaccineNames = const <String>[],
    this.vaccineNameToCode = const <String, String>{},
    this.vaccinesLoading = false,
  });

  const ReportsState.initial()
    : classroomNames = const <String>[],
      studentNames = const <String>[],
      staffNames = const <String>[],
      tagNames = const <String>[],
      classroomNameToCode = const <String, String>{},
      staffNameToCode = const <String, String>{},
      studentNameToCode = const <String, String>{},
      tagNameToCode = const <String, String>{},
      generatedReport = null,
      recentReports = const <ReportMetadataEntity>[],
      dynamicTagNames = const <String>[],
      isGenerating = false,
      generationError = null,
      generationSuccess = null,
      generatedReportsState = GeneratedReportsLoadingState.initial,
      generatedReportsError = null,
      allClassroomNames = const <String>[],
      allClassroomNameToCode = const <String, String>{},
      formClassroomsStatus = FormClassroomsStatus.initial,
      formClassroomsError = null,
      formStudentsLoading = false,
      vaccineNames = const <String>[],
      vaccineNameToCode = const <String, String>{},
      vaccinesLoading = false;

  final List<String> classroomNames;
  final List<String> studentNames;
  final List<String> staffNames;
  final List<String> tagNames;
  final Map<String, String> classroomNameToCode;
  final Map<String, String> staffNameToCode;
  final Map<String, String> studentNameToCode;
  final Map<String, String> tagNameToCode;
  final dynamic generatedReport;
  final List<ReportMetadataEntity> recentReports;
  final List<String> dynamicTagNames;
  final bool isGenerating;
  final String? generationError;
  final String? generationSuccess;
  final GeneratedReportsLoadingState generatedReportsState;
  final String? generatedReportsError;

  /// Classrooms including non-classroom types (Office, primary rooms) — the
  /// `onlyTypeClassroom: false` set the staff and billing-transaction forms
  /// need. Deliberately separate from [classroomNames], which is the
  /// `onlyTypeClassroom: true` set the hub shows.
  final List<String> allClassroomNames;
  final Map<String, String> allClassroomNameToCode;

  final FormClassroomsStatus formClassroomsStatus;
  final String? formClassroomsError;

  /// True while a report form is fetching the students of its selected
  /// classrooms. Owned here rather than in the form's widget state because it
  /// is a loading flag over an API call (§2.2 bucket A).
  final bool formStudentsLoading;

  /// The school's configured vaccines, for the immunization report form.
  /// API-owned, so it lives here rather than in widget state (§2.2 bucket A).
  final List<String> vaccineNames;
  final Map<String, String> vaccineNameToCode;
  final bool vaccinesLoading;

  /// Backwards compatibility: returns true if loading or refreshing
  bool get isLoadingRecent =>
      generatedReportsState == GeneratedReportsLoadingState.loading ||
      generatedReportsState == GeneratedReportsLoadingState.initial;

  /// Backwards compatibility: returns error message
  String? get recentError => generatedReportsError;

  ReportsState copyWith({
    List<String>? classroomNames,
    List<String>? studentNames,
    List<String>? staffNames,
    List<String>? tagNames,
    Map<String, String>? classroomNameToCode,
    Map<String, String>? staffNameToCode,
    Map<String, String>? studentNameToCode,
    Map<String, String>? tagNameToCode,
    dynamic generatedReport,
    List<ReportMetadataEntity>? recentReports,
    List<String>? dynamicTagNames,
    bool? isGenerating,
    String? generationError,
    String? generationSuccess,
    GeneratedReportsLoadingState? generatedReportsState,
    String? generatedReportsError,
    List<String>? allClassroomNames,
    Map<String, String>? allClassroomNameToCode,
    FormClassroomsStatus? formClassroomsStatus,
    String? formClassroomsError,
    bool clearFormClassroomsError = false,
    bool? formStudentsLoading,
    List<String>? vaccineNames,
    Map<String, String>? vaccineNameToCode,
    bool? vaccinesLoading,
  }) {
    return ReportsState(
      classroomNames: classroomNames ?? this.classroomNames,
      studentNames: studentNames ?? this.studentNames,
      staffNames: staffNames ?? this.staffNames,
      tagNames: tagNames ?? this.tagNames,
      classroomNameToCode: classroomNameToCode ?? this.classroomNameToCode,
      staffNameToCode: staffNameToCode ?? this.staffNameToCode,
      studentNameToCode: studentNameToCode ?? this.studentNameToCode,
      tagNameToCode: tagNameToCode ?? this.tagNameToCode,
      generatedReport: generatedReport ?? this.generatedReport,
      recentReports: recentReports ?? this.recentReports,
      dynamicTagNames: dynamicTagNames ?? this.dynamicTagNames,
      isGenerating: isGenerating ?? this.isGenerating,
      generationError: generationError ?? this.generationError,
      generationSuccess: generationSuccess ?? this.generationSuccess,
      generatedReportsState:
          generatedReportsState ?? this.generatedReportsState,
      generatedReportsError:
          generatedReportsError ?? this.generatedReportsError,
      allClassroomNames: allClassroomNames ?? this.allClassroomNames,
      allClassroomNameToCode:
          allClassroomNameToCode ?? this.allClassroomNameToCode,
      formClassroomsStatus: formClassroomsStatus ?? this.formClassroomsStatus,
      formClassroomsError: clearFormClassroomsError
          ? null
          : (formClassroomsError ?? this.formClassroomsError),
      formStudentsLoading: formStudentsLoading ?? this.formStudentsLoading,
      vaccineNames: vaccineNames ?? this.vaccineNames,
      vaccineNameToCode: vaccineNameToCode ?? this.vaccineNameToCode,
      vaccinesLoading: vaccinesLoading ?? this.vaccinesLoading,
    );
  }

  @override
  List<Object?> get props => [
    classroomNames,
    studentNames,
    staffNames,
    tagNames,
    classroomNameToCode,
    staffNameToCode,
    studentNameToCode,
    tagNameToCode,
    generatedReport,
    recentReports,
    dynamicTagNames,
    isGenerating,
    generationError,
    generationSuccess,
    generatedReportsState,
    generatedReportsError,
    allClassroomNames,
    allClassroomNameToCode,
    formClassroomsStatus,
    formClassroomsError,
    formStudentsLoading,
    vaccineNames,
    vaccineNameToCode,
    vaccinesLoading,
  ];
}
