part of 'reports_cubit.dart';

class ReportsState extends Equatable {
  const ReportsState({
    required this.classroomNames,
    required this.studentNames,
    required this.staffNames,
    required this.tagNames,
    this.generatedReport,
    this.recentReports = const <dynamic>[],
    this.dynamicTagNames = const <String>[],
    this.isGenerating = false,
    this.isLoadingRecent = false,
    this.generationError,
    this.recentError,
  });

  const ReportsState.initial()
      : classroomNames = const <String>[],
        studentNames = const <String>[],
        staffNames = const <String>[],
        tagNames = const <String>[],
        generatedReport = null,
        recentReports = const <dynamic>[],
        dynamicTagNames = const <String>[],
        isGenerating = false,
        isLoadingRecent = false,
        generationError = null,
        recentError = null;

  final List<String> classroomNames;
  final List<String> studentNames;
  final List<String> staffNames;
  final List<String> tagNames;
  final dynamic generatedReport;
  final List<dynamic> recentReports;
  final List<String> dynamicTagNames;
  final bool isGenerating;
  final bool isLoadingRecent;
  final String? generationError;
  final String? recentError;

  ReportsState copyWith({
    List<String>? classroomNames,
    List<String>? studentNames,
    List<String>? staffNames,
    List<String>? tagNames,
    dynamic generatedReport,
    List<dynamic>? recentReports,
    List<String>? dynamicTagNames,
    bool? isGenerating,
    bool? isLoadingRecent,
    String? generationError,
    String? recentError,
  }) {
    return ReportsState(
      classroomNames: classroomNames ?? this.classroomNames,
      studentNames: studentNames ?? this.studentNames,
      staffNames: staffNames ?? this.staffNames,
      tagNames: tagNames ?? this.tagNames,
      generatedReport: generatedReport ?? this.generatedReport,
      recentReports: recentReports ?? this.recentReports,
      dynamicTagNames: dynamicTagNames ?? this.dynamicTagNames,
      isGenerating: isGenerating ?? this.isGenerating,
      isLoadingRecent: isLoadingRecent ?? this.isLoadingRecent,
      generationError: generationError ?? this.generationError,
      recentError: recentError ?? this.recentError,
    );
  }

  @override
  List<Object?> get props => [
        classroomNames,
        studentNames,
        staffNames,
        tagNames,
        generatedReport,
        recentReports,
        dynamicTagNames,
        isGenerating,
        isLoadingRecent,
        generationError,
        recentError,
      ];
}
