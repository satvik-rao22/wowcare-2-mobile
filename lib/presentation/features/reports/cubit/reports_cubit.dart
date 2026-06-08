import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import 'dart:typed_data';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../core/util/logger_service.dart';
import '../../../../domain/features/reports/entities/report_metadata_entity.dart';
import '../../../../domain/features/reports/usecases/generate_report_usecase.dart';
import '../../../../domain/features/reports/usecases/get_recent_reports_usecase.dart';
import '../../../../domain/features/reports/usecases/get_student_tags_usecase.dart';
import '../../../../domain/features/reports/usecases/download_report_usecase.dart';
import '../../../../domain/features/reports/usecases/report_params.dart';
import '../../../../domain/features/student/usecases/get_tag_names_for_school_usecase.dart';
import '../../../../data/features/reports/repositories/file_download_repository.dart';

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
    required DownloadReportUseCase downloadReportUseCase,
    required FileDownloadRepository fileDownloadRepository,
  })  : _storageService = storageService,
        _getTagNamesForSchoolUseCase = getTagNamesForSchoolUseCase,
        _generateReportUseCase = generateReportUseCase,
        _getRecentReportsUseCase = getRecentReportsUseCase,
        _getStudentTagsUseCase = getStudentTagsUseCase,
        _downloadReportUseCase = downloadReportUseCase,
        _fileDownloadRepository = fileDownloadRepository,
        super(const ReportsState.initial());

  final StorageService _storageService;
  final GetTagNamesForSchoolUseCase _getTagNamesForSchoolUseCase;
  final GenerateReportUseCase _generateReportUseCase;
  final GetRecentReportsUseCase _getRecentReportsUseCase;
  final GetStudentTagsUseCase _getStudentTagsUseCase;
  final DownloadReportUseCase _downloadReportUseCase;
  final FileDownloadRepository _fileDownloadRepository;

  /// Prevent concurrent loadRecentReports calls
  bool _isLoadingRecentReports = false;

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

  void setClassroomNames(List<String> names, {Map<String, String>? nameToCodeMap}) {
    if (isClosed) return;
    emit(state.copyWith(
      classroomNames: names,
      classroomNameToCode: nameToCodeMap ?? state.classroomNameToCode,
    ));
  }

  void setStudentNames(List<String> names) {
    if (isClosed) return;
    emit(state.copyWith(studentNames: names));
  }

  void setStaffNames(List<String> names, {Map<String, String>? nameToCodeMap}) {
    if (isClosed) return;
    emit(state.copyWith(
      staffNames: names,
      staffNameToCode: nameToCodeMap ?? state.staffNameToCode,
    ));
  }

  /// Generate a report based on request params.
  /// Every call triggers a fresh API request - no caching or deduplication.
  Future<void> generateReport(ReportParams params) async {
    if (isClosed) return;

    AppLogger.d('[REPORTS-CUBIT] generateReport() entered: ${params.reportType.backendValue}');
    AppLogger.d('[REPORTS-CUBIT] Setting isGenerating=true, clearing previous errors/success');
    emit(state.copyWith(isGenerating: true, generationError: null, generationSuccess: null));

    AppLogger.d('[REPORTS-CUBIT] Calling usecase for fresh API call');
    final result = await _generateReportUseCase(params);

    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.e('[REPORTS-CUBIT] Report generation FAILED: ${failure.message}');
        emit(state.copyWith(
          isGenerating: false,
          generationError: failure.message,
          generationSuccess: null,
        ));
      },
      (report) {
        AppLogger.i('[REPORT_GENERATION_SUCCESS] ID: ${report.reportId}, Asset: ${report.assetCode}, File: ${report.fileName}');
        emit(state.copyWith(
          isGenerating: false,
          generatedReport: report,
          generationSuccess: 'Report generated successfully',
          generationError: null,
        ));
        AppLogger.d('[RECENT_REPORTS_BACKGROUND_REFRESH] Triggering silent background refresh');
        // Refresh recent reports after successful generation (background refresh - silent)
        unawaited(loadRecentReports(isRefresh: true));
      },
    );
  }

  /// Load recent reports from all sources (merged and deduplicated).
  ///
  /// [isRefresh]: If true, treats this as a background refresh and preserves
  /// existing data while loading. If false, treats as initial load and shows
  /// loading state.
  Future<void> loadRecentReports({bool isRefresh = false}) async {
    if (isClosed) return;

    // Prevent concurrent calls
    if (_isLoadingRecentReports) {
      AppLogger.d('[REPORTS-CUBIT] loadRecentReports() called while already loading - ignoring');
      return;
    }

    _isLoadingRecentReports = true;
    final loadingState = isRefresh
        ? GeneratedReportsLoadingState.refreshing
        : GeneratedReportsLoadingState.loading;

    AppLogger.d(
      '[REPORTS-CUBIT] loadRecentReports() called [isRefresh=$isRefresh, '
      'state=${state.generatedReportsState}, '
      'currentReportsCount=${state.recentReports.length}]',
    );

    emit(state.copyWith(
      generatedReportsState: loadingState,
      generatedReportsError: null,
    ));

    final result = await _getRecentReportsUseCase(NoParams());

    if (isClosed) {
      _isLoadingRecentReports = false;
      return;
    }

    result.fold(
      (failure) {
        AppLogger.e('[REPORTS-CUBIT] Failed to load recent reports: ${failure.message}');
        emit(state.copyWith(
          generatedReportsState: GeneratedReportsLoadingState.error,
          generatedReportsError: failure.message,
        ));
        _isLoadingRecentReports = false;
      },
      (reports) {
        AppLogger.i('[REPORTS-CUBIT] Successfully loaded recent reports: ${reports.length} reports');
        for (final report in reports.take(3)) {
          AppLogger.d('[REPORTS-CUBIT]   - ${report.fileName} (${report.reportType.backendValue})');
        }
        emit(state.copyWith(
          generatedReportsState: GeneratedReportsLoadingState.loaded,
          recentReports: reports,
          generatedReportsError: null,
        ));
        _isLoadingRecentReports = false;
      },
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

  /// Download a report file by asset code.
  Future<List<int>?> downloadReport(String assetCode) async {
    if (isClosed) return null;

    AppLogger.d('[DOWNLOAD-API] Downloading report: assetCode=$assetCode');
    final result = await _downloadReportUseCase(assetCode);

    return result.fold(
      (failure) {
        AppLogger.e(
          '[DOWNLOAD-API] Failed for $assetCode:\n'
          '  message: ${failure.message}',
        );
        return null;
      },
      (fileData) {
        AppLogger.i(
          '[DOWNLOAD-API] Success for $assetCode:\n'
          '  bytesLength: ${fileData.length}\n'
          '  isEmpty: ${fileData.isEmpty}\n'
          '  isValid: ${fileData.length > 0}',
        );
        return fileData;
      },
    );
  }

  /// Save file to device storage
  Future<String?> saveReportFile({
    required Uint8List fileData,
    required String fileName,
    required String assetCode,
  }) async {
    if (isClosed) return null;

    AppLogger.d('[CUBIT-SAVE] Saving file: $fileName for $assetCode');

    final result = await _fileDownloadRepository.downloadAndSaveFile(
      fileData: fileData,
      fileName: fileName,
      assetCode: assetCode,
    );

    return result.fold(
      (failure) {
        AppLogger.e('[CUBIT-SAVE] Failed: ${failure.message}');
        return null;
      },
      (filePath) {
        AppLogger.i('[CUBIT-SAVE] Success: $filePath');
        return filePath;
      },
    );
  }

  /// Open file with default application
  Future<bool> openReportFile({
    required String filePath,
    required String fileName,
    required String assetCode,
  }) async {
    if (isClosed) return false;

    AppLogger.d('[CUBIT] Opening report file: $fileName from $filePath');

    final result = await _fileDownloadRepository.openFile(
      filePath: filePath,
      fileName: fileName,
      assetCode: assetCode,
    );

    return result.fold(
      (failure) {
        AppLogger.e('[CUBIT] Failed to open file: ${failure.message}');
        return false;
      },
      (success) {
        AppLogger.i('[CUBIT] File opened successfully');
        return success;
      },
    );
  }
}

