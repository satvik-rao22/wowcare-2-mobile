part of 'reports_cubit.dart';

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
      generatedReportsError = null;

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
  ];
}
