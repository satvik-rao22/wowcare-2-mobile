import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/data/services/file_download_service.dart';
import 'package:wowcare/domain/features/billing/entities/billing_statement_entity.dart';
import 'package:wowcare/domain/features/billing/repositories/billing_statements_repository.dart';
import 'package:wowcare/domain/features/billing/usecases/get_billing_statements_usecase.dart';

part 'parent_statements_state.dart';

/// Drives the parent Statements tab: loads the guardian's real statements
/// (`GET /billing/statements`), filters them by the selected date range, and
/// downloads a statement PDF (`GET /billing/statements/{code}/download`) to
/// open it on the device. Mirrors [AdminStatementsCubit] but keeps the parent
/// tab's client-side pagination.
class ParentStatementsCubit extends Cubit<ParentStatementsState> {
  ParentStatementsCubit({
    required GetBillingStatementsUseCase getStatements,
    required BillingStatementsRepository statementsRepository,
    required FileDownloadService fileDownloadService,
  })  : _getStatements = getStatements,
        _repository = statementsRepository,
        _fileDownloadService = fileDownloadService,
        super(const ParentStatementsState.initial());

  final GetBillingStatementsUseCase _getStatements;
  final BillingStatementsRepository _repository;
  final FileDownloadService _fileDownloadService;

  static const int _pageSize = 10;

  String _subscriberCode = '';

  void initialize(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      final now = DateTime.now();
      emit(state.copyWith(
        customStartDate: () => DateTime(now.year, now.month, 1),
        customEndDate: () => DateTime(now.year, now.month + 1, 0),
        displayCount: _pageSize,
      ));
    } else {
      emit(state.copyWith(
        customStartDate: () => start,
        customEndDate: () => end,
        displayCount: _pageSize,
      ));
    }
  }

  /// Fetches the statement list for [subscriberCode] (the guardian's owner code).
  Future<void> load(String subscriberCode) async {
    if (subscriberCode.trim().isEmpty) return;
    _subscriberCode = subscriberCode.trim();
    emit(state.copyWith(isStatementsLoading: true, errorMessage: () => ''));
    try {
      final statements = await _getStatements(subscriberCode: _subscriberCode);
      if (isClosed) return;
      emit(state.copyWith(
        isStatementsLoading: false,
        statements: statements,
        displayCount: _pageSize,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isStatementsLoading: false,
        errorMessage: () => ApiErrorHandler.extractErrorMessage(e),
      ));
    }
  }

  void syncDates(DateTime? start, DateTime? end) {
    emit(state.copyWith(
      customStartDate: () => start,
      customEndDate: () => end,
      displayCount: _pageSize, // reset page on date change
    ));
  }

  Future<void> refresh() => load(_subscriberCode);

  Future<void> applyDateRange(DateTime startDate, DateTime? endDate) async {
    emit(state.copyWith(
      customStartDate: () => startDate,
      customEndDate: () => endDate ??
          DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59),
      displayCount: _pageSize, // reset page on filter change
    ));
  }

  /// Shows the next page of statements (client-side pagination).
  void loadNextPage() {
    if (!state.hasMoreStatements) return;
    emit(state.copyWith(displayCount: state.displayCount + _pageSize));
  }

  /// Downloads the statement PDF and opens it. Returns an error message on
  /// failure, or null on success.
  Future<String?> downloadStatement(BillingStatementEntity statement) async {
    final code = statement.code;
    if (code.isEmpty) return 'Invalid statement code.';

    final downloading = Set<String>.from(state.downloadingCodes)..add(code);
    emit(state.copyWith(downloadingCodes: downloading));

    try {
      final bytes = await _repository.downloadStatement(statementCode: code);

      final fileName = 'statement-$code.pdf';
      final savedPath = await _fileDownloadService.saveFile(
        fileData: bytes,
        fileName: fileName,
        assetCode: code,
        mimeType: 'application/pdf',
      );

      if (isClosed) return null;

      if (savedPath == null) {
        return 'Failed to save statement PDF.';
      }

      await _fileDownloadService.openFile(
        filePath: savedPath,
        fileName: fileName,
        assetCode: code,
        mimeType: 'application/pdf',
      );

      return null;
    } catch (e) {
      AppLogger.e('[ParentStatementsCubit] Download failed for $code: $e');
      if (isClosed) return null;
      return ApiErrorHandler.extractErrorMessage(e);
    } finally {
      if (!isClosed) {
        final done = Set<String>.from(state.downloadingCodes)..remove(code);
        emit(state.copyWith(downloadingCodes: done));
      }
    }
  }
}
