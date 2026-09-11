import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';

/// Saving a generated report to device storage and handing it to the OS.
///
/// The implementation lives in
/// `data/features/reports/repositories/file_download_repository_impl.dart`;
/// this contract exists so the presentation layer reaches it through use
/// cases rather than importing the data layer directly (§5).
abstract class FileDownloadRepository {
  /// Persist [fileData] to device storage under [fileName].
  ///
  /// Returns the saved file's path, or a [FileDownloadFailure].
  Future<Either<Failure, String>> downloadAndSaveFile({
    required Uint8List fileData,
    required String fileName,
    required String assetCode,
  });

  /// Open an already-saved file with the OS's default handler.
  Future<Either<Failure, bool>> openFile({
    required String filePath,
    required String fileName,
    required String assetCode,
  });
}
