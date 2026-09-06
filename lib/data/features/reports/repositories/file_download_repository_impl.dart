import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/data/services/file_download_service.dart';
import 'package:wowcare/domain/features/reports/repositories/file_download_repository.dart';

class FileDownloadRepositoryImpl implements FileDownloadRepository {
  final FileDownloadService _fileDownloadService;

  FileDownloadRepositoryImpl(this._fileDownloadService);

  /// Download and save file to device storage
  @override
  Future<Either<Failure, String>> downloadAndSaveFile({
    required Uint8List fileData,
    required String fileName,
    required String assetCode,
  }) async {
    try {
      AppLogger.d('[REPO-FILE] Save started for $assetCode');

      if (fileData.isEmpty) {
        AppLogger.e('[REPO-FILE] Bytes empty for $assetCode');
        return const Left(FileDownloadFailure('File data is empty'));
      }

      final mimeType = _fileDownloadService.getMimeType(fileName);
      AppLogger.d(
        '[REPO-FILE] Detected mimeType for $assetCode:\n'
        '  fileName: $fileName\n'
        '  mimeType: $mimeType\n'
        '  bytesLength: ${fileData.length}',
      );

      final filePath = await _fileDownloadService.saveFile(
        fileData: fileData,
        fileName: fileName,
        assetCode: assetCode,
        mimeType: mimeType,
      );

      if (filePath != null) {
        AppLogger.i('[REPO-FILE] File saved: $filePath');
        return Right(filePath);
      } else {
        AppLogger.e('[REPO-FILE] Service returned null for $assetCode');
        return const Left(FileDownloadFailure('Failed to save file'));
      }
    } catch (e) {
      AppLogger.e('[REPO-FILE] Exception: $e');
      return Left(FileDownloadFailure('Error saving file: $e'));
    }
  }

  /// Open file with default application
  @override
  Future<Either<Failure, bool>> openFile({
    required String filePath,
    required String fileName,
    required String assetCode,
  }) async {
    try {
      AppLogger.d('[REPO-FILE] Open started for $assetCode');

      final mimeType = _fileDownloadService.getMimeType(fileName);
      AppLogger.d('[REPO-FILE] Opening with mimeType: $mimeType');

      final opened = await _fileDownloadService.openFile(
        filePath: filePath,
        fileName: fileName,
        assetCode: assetCode,
        mimeType: mimeType,
      );

      if (opened) {
        AppLogger.i('[REPO-FILE] File opened successfully: $fileName');
        return const Right(true);
      } else {
        AppLogger.w('[REPO-FILE] Could not open file: $fileName');
        return const Left(FileDownloadFailure('Could not open file'));
      }
    } catch (e) {
      AppLogger.e('[REPO-FILE] Exception opening: $e');
      return Left(FileDownloadFailure('Error opening file: $e'));
    }
  }
}
