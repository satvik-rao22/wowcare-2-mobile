import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/data/services/file_download_service.dart';
import 'package:wowcare/domain/features/billing/entities/billing_statement_entity.dart';
import 'package:wowcare/domain/features/billing/repositories/billing_statements_repository.dart';
import 'package:wowcare/domain/features/billing/usecases/get_billing_statements_usecase.dart';

part 'admin_statements_state.dart';

class AdminStatementsCubit extends Cubit<AdminStatementsState> {
  AdminStatementsCubit({
    required GetBillingStatementsUseCase getStatements,
    required BillingStatementsRepository statementsRepository,
    required FileDownloadService fileDownloadService,
    required StorageService storageService,
  })  : _getStatements = getStatements,
        _repository = statementsRepository,
        _fileDownloadService = fileDownloadService,
        _storageService = storageService,
        super(const AdminStatementsState.initial());

  final GetBillingStatementsUseCase _getStatements;
  final BillingStatementsRepository _repository;
  final FileDownloadService _fileDownloadService;
  final StorageService _storageService;
  String _subscriberCode = '';

  Future<void> load(String subscriberCode) async {
    if (subscriberCode.trim().isEmpty) return;
    _subscriberCode = subscriberCode.trim();
    emit(state.copyWith(isLoading: true, errorMessage: ''));
    try {
      final statements =
          await _getStatements(subscriberCode: _subscriberCode);
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, statements: statements));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
    }
  }

  Future<void> refresh() => load(_subscriberCode);

  void applyDateRange(DateTime? start, DateTime? end) {
    emit(state.copyWith(
      customStartDate: () => start,
      customEndDate: () => end,
    ));
  }

  /// Generates a new statement via POST and refreshes the list on success.
  /// Returns an error message on failure, or null on success.
  Future<String?> generateStatement({
    required String ownerType,
    required String subscriberCode,
    required String statementType,
    required DateTime periodStart,
    required DateTime periodEnd,
    required bool includeDescription,
  }) async {
    emit(state.copyWith(isGenerating: true, generateError: ''));
    try {
      final organizationCode =
          (await _storageService.getString(StorageKeys.organizationCode) ?? '')
              .trim();
      final schoolCode =
          (await _storageService.getString(StorageKeys.schoolCode) ?? '')
              .trim();
      await _repository.generateStatement(
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        ownerType: ownerType,
        subscriberCode: subscriberCode,
        statementType: statementType,
        periodStart: periodStart,
        periodEnd: periodEnd,
        includeDescription: includeDescription,
      );
      if (isClosed) return null;
      // Refresh the list so the new statement appears.
      await load(_subscriberCode.isNotEmpty ? _subscriberCode : subscriberCode);
      if (isClosed) return null;
      emit(state.copyWith(isGenerating: false));
      return null;
    } catch (e) {
      if (isClosed) return null;
      final msg = ApiErrorHandler.extractErrorMessage(e);
      emit(state.copyWith(isGenerating: false, generateError: msg));
      return msg;
    }
  }

  /// Downloads the statement PDF and opens it.
  /// Returns an error message on failure, or null on success.
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
      AppLogger.e('[AdminStatementsCubit] Download failed for $code: $e');
      if (isClosed) return null;
      return ApiErrorHandler.extractErrorMessage(e);
    } finally {
      if (!isClosed) {
        final done = Set<String>.from(state.downloadingCodes)..remove(code);
        emit(state.copyWith(downloadingCodes: done));
      }
    }
  }

  /// Fetches the statement PDF's raw bytes for an in-app preview — unlike
  /// [downloadStatement], this never writes a file to disk or hands off to
  /// an external viewer. Returns the bytes on success, or an error message
  /// on failure.
  Future<({Uint8List? bytes, String? error})> fetchStatementForPreview(
    BillingStatementEntity statement,
  ) async {
    final code = statement.code;
    if (code.isEmpty) return (bytes: null, error: 'Invalid statement code.');

    final downloading = Set<String>.from(state.downloadingCodes)..add(code);
    emit(state.copyWith(downloadingCodes: downloading));

    try {
      final bytes = await _repository.downloadStatement(statementCode: code);
      return (bytes: bytes, error: null);
    } catch (e) {
      AppLogger.e('[AdminStatementsCubit] Preview fetch failed for $code: $e');
      return (bytes: null, error: ApiErrorHandler.extractErrorMessage(e));
    } finally {
      if (!isClosed) {
        final done = Set<String>.from(state.downloadingCodes)..remove(code);
        emit(state.copyWith(downloadingCodes: done));
      }
    }
  }
}
