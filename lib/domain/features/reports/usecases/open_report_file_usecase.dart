import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/reports/repositories/file_download_repository.dart';

/// Opens a saved report file with the OS's default handler.
class OpenReportFileUseCase {
  OpenReportFileUseCase(this._repository);

  final FileDownloadRepository _repository;

  Future<Either<Failure, bool>> call({
    required String filePath,
    required String fileName,
    required String assetCode,
  }) {
    return _repository.openFile(
      filePath: filePath,
      fileName: fileName,
      assetCode: assetCode,
    );
  }
}
