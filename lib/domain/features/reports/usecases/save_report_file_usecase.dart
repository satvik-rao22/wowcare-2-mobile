import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/core/observability/app_events.dart';
import 'package:wowcare/domain/features/reports/repositories/file_download_repository.dart';

/// Saves a generated report's bytes to device storage.
class SaveReportFileUseCase {
  SaveReportFileUseCase(this._repository);

  final FileDownloadRepository _repository;

  Future<Either<Failure, String>> call({
    required Uint8List fileData,
    required String fileName,
    required String assetCode,
  }) {
    return AppEvents.track(
      AppEvent.reportSave,
      () => _repository.downloadAndSaveFile(
        fileData: fileData,
        fileName: fileName,
        assetCode: assetCode,
      ),
      failureOf: AppEvents.leftFailure,
    );
  }
}
