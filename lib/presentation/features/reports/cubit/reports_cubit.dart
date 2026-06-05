import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/reports/usecases/generate_report_usecase.dart';
import '../../../../domain/features/reports/usecases/get_recent_reports_usecase.dart';
import '../../../../domain/features/reports/usecases/get_student_tags_usecase.dart';
import '../../../../domain/features/reports/usecases/report_params.dart';
import '../../../../domain/features/student/usecases/get_tag_names_for_school_usecase.dart';

part 'reports_state.dart';

/// Owns the lookup data (classroom / student / staff / tag names) the report
/// forms need, so the reports screen no longer juggles these lists in
/// `setState`.
///
/// The classroom/student/staff names are fed in from their respective cubits
/// via [setClassroomNames] / [setStudentNames] / [setStaffNames]; tag names are
/// loaded directly here since no dedicated cubit owns them.
///
/// Also handles report generation and retrieval of recent reports.
class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit({
    required StorageService storageService,
    required GetTagNamesForSchoolUseCase getTagNamesForSchoolUseCase,
    required GenerateReportUseCase generateReportUseCase,
    required GetRecentReportsUseCase getRecentReportsUseCase,
    required GetStudentTagsUseCase getStudentTagsUseCase,
  })  : _storageService = storageService,
        _getTagNamesForSchoolUseCase = getTagNamesForSchoolUseCase,
        _generateReportUseCase = generateReportUseCase,
        _getRecentReportsUseCase = getRecentReportsUseCase,
        _getStudentTagsUseCase = getStudentTagsUseCase,
        super(const ReportsState.initial());

  final StorageService _storageService;
  final GetTagNamesForSchoolUseCase _getTagNamesForSchoolUseCase;
  final GenerateReportUseCase _generateReportUseCase;
  final GetRecentReportsUseCase _getRecentReportsUseCase;
  final GetStudentTagsUseCase _getStudentTagsUseCase;

  /// Loads the school's tag names. Tags are optional metadata, so failures are
  /// swallowed and the rest of the screen keeps working.
  Future<void> loadTags() async {
    try {
      final schoolCode =
          (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();
      if (schoolCode.isEmpty) return;
      final tags = await _getTagNamesForSchoolUseCase(schoolCode: schoolCode);
      if (isClosed) return;
      emit(state.copyWith(tagNames: tags));
    } catch (_) {
      // Tags are optional; ignore failures.
    }
  }

  void setClassroomNames(List<String> names) {
    if (isClosed) return;
    emit(state.copyWith(classroomNames: names));
  }

  void setStudentNames(List<String> names) {
    if (isClosed) return;
    emit(state.copyWith(studentNames: names));
  }

  void setStaffNames(List<String> names) {
    if (isClosed) return;
    emit(state.copyWith(staffNames: names));
  }

  /// Generate a report based on request params.
  Future<void> generateReport(ReportParams params) async {
    if (isClosed) return;
    emit(state.copyWith(isGenerating: true, generationError: null));

    final result = await _generateReportUseCase(params);

    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        isGenerating: false,
        generationError: failure.message,
      )),
      (report) {
        emit(state.copyWith(
          isGenerating: false,
          generatedReport: report,
        ));
        // Refresh recent reports after successful generation
        unawaited(loadRecentReports());
      },
    );
  }

  /// Load recent reports from all sources (merged and deduplicated).
  Future<void> loadRecentReports() async {
    if (isClosed) return;
    emit(state.copyWith(isLoadingRecent: true, recentError: null));

    final result = await _getRecentReportsUseCase(NoParams());

    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingRecent: false,
        recentError: failure.message,
      )),
      (reports) => emit(state.copyWith(
        isLoadingRecent: false,
        recentReports: reports,
      )),
    );
  }

  /// Load dynamic student tags for filtering.
  /// Tags are optional; failures are silently ignored.
  Future<void> loadDynamicTags() async {
    if (isClosed) return;

    final result = await _getStudentTagsUseCase(NoParams());

    if (isClosed) return;
    result.fold(
      (failure) => null, // Silently ignore tag loading failures
      (tags) => emit(state.copyWith(dynamicTagNames: tags)),
    );
  }

  /// Clear the generated report from state.
  void clearGeneratedReport() {
    if (isClosed) return;
    emit(state.copyWith(generatedReport: null, generationError: null));
  }
}

