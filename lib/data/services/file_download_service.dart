import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart' as open_filex;
import 'package:path_provider/path_provider.dart';
import 'package:wowcare/core/utils/logger_service.dart';

/// Hands [filePath] to the OS. Defaults to open_filex; a seam so the
/// hand-off's outcome can be exercised in a test, where the plugin would
/// otherwise shell out to the host desktop and always succeed.
typedef FileOpener =
    Future<open_filex.OpenResult> Function(String filePath, {String? type});

Future<open_filex.OpenResult> _openWithOpenFilex(
  String filePath, {
  String? type,
}) => open_filex.OpenFilex.open(filePath, type: type);

class FileDownloadService {
  const FileDownloadService({FileOpener opener = _openWithOpenFilex})
    : _opener = opener;

  final FileOpener _opener;

  /// Returns the deterministic local cache location for [fileName] without
  /// touching the filesystem — callers check `await file.exists()` to decide
  /// whether a download is still needed. Uses the exact same path/sanitizing
  /// rules as [saveFile] so a previously saved file is always found again.
  Future<File> resolveCacheFile(String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/${_sanitizeFileName(fileName)}');
  }

  /// Save file to device storage with validation
  Future<String?> saveFile({
    required Uint8List fileData,
    required String fileName,
    required String assetCode,
    required String mimeType,
  }) async {
    try {
      AppLogger.d(
        '[FILE-SAVE] Starting save:\n'
        '  assetCode: $assetCode\n'
        '  fileName: $fileName\n'
        '  mimeType: $mimeType\n'
        '  bytesLength: ${fileData.length}',
      );

      // Validate bytes
      if (fileData.isEmpty) {
        AppLogger.e(
          '[FILE-SAVE] Failed - bytes are empty for $assetCode\n'
          '  bytesLength: 0\n'
          '  fileName: $fileName',
        );
        return null;
      }

      if (fileData.length > 500 * 1024 * 1024) {
        AppLogger.e(
          '[FILE-SAVE] Failed - file too large for $assetCode\n'
          '  bytesLength: ${fileData.length} (> 500MB)',
        );
        return null;
      }

      // Get app documents directory for reliable storage
      final appDir = await getApplicationDocumentsDirectory();
      final fileName_safe = _sanitizeFileName(fileName);
      final targetPath = '${appDir.path}/$fileName_safe';

      AppLogger.d(
        '[FILE-SAVE] Saving to explicit path:\n'
        '  assetCode: $assetCode\n'
        '  targetPath: $targetPath\n'
        '  bytesLength: ${fileData.length}',
      );

      // Write file
      final file = File(targetPath);
      await file.writeAsBytes(fileData);

      // Verify file was actually written
      final savedFile = File(targetPath);
      final exists = await savedFile.exists();
      final stat = await savedFile.stat();

      if (!exists) {
        AppLogger.e(
          '[FILE-SAVE] File verification failed - file does not exist:\n'
          '  assetCode: $assetCode\n'
          '  targetPath: $targetPath',
        );
        return null;
      }

      if (stat.size == 0) {
        AppLogger.e(
          '[FILE-SAVE] File verification failed - file size is 0:\n'
          '  assetCode: $assetCode\n'
          '  targetPath: $targetPath',
        );
        return null;
      }

      if (stat.size != fileData.length) {
        AppLogger.w(
          '[FILE-SAVE] File size mismatch:\n'
          '  assetCode: $assetCode\n'
          '  expectedSize: ${fileData.length}\n'
          '  actualSize: ${stat.size}\n'
          '  targetPath: $targetPath',
        );
      }

      AppLogger.i(
        '[FILE-SAVE] Success:\n'
        '  assetCode: $assetCode\n'
        '  fileName: $fileName\n'
        '  savedPath: $targetPath\n'
        '  savedSize: ${stat.size} bytes\n'
        '  bytesLength: ${fileData.length}',
      );

      return targetPath;
    } catch (e, stackTrace) {
      AppLogger.e(
        '[FILE-SAVE] Exception for $assetCode:\n'
        '  error: $e\n'
        '  fileName: $fileName\n'
        '  stackTrace: $stackTrace',
      );
      return null;
    }
  }

  /// Open file with default application
  Future<bool> openFile({
    required String filePath,
    required String fileName,
    required String assetCode,
    required String mimeType,
  }) async {
    try {
      AppLogger.d(
        '[FILE-OPEN] Attempting to open:\n'
        '  assetCode: $assetCode\n'
        '  fileName: $fileName\n'
        '  filePath: $filePath\n'
        '  mimeType: $mimeType',
      );

      // Verify file exists before opening
      final file = File(filePath);
      final exists = await file.exists();

      if (!exists) {
        AppLogger.e(
          '[FILE-OPEN] File not found:\n'
          '  assetCode: $assetCode\n'
          '  filePath: $filePath',
        );
        return false;
      }

      // Check file size
      final stat = await file.stat();
      AppLogger.d(
        '[FILE-OPEN] File validated:\n'
        '  assetCode: $assetCode\n'
        '  fileExists: true\n'
        '  fileSize: ${stat.size} bytes\n'
        '  isReadable: true',
      );

      // Use open_filex to open file
      try {
        AppLogger.d(
          '[FILE-OPEN] Calling open_filex:\n'
          '  filePath: $filePath\n'
          '  mimeType: $mimeType',
        );

        // OpenFilex reports a failed hand-off through the returned
        // OpenResult, not by throwing: on Android an ActivityNotFoundException
        // (no installed app declares the mime type — routine for XLSX) is
        // caught inside the plugin and comes back as
        // ResultType.noAppToOpen. Discarding the result reported every one of
        // those as a success, so the caller's "couldn't open" fallback never
        // ran and the file silently went nowhere.
        final openResult = await _opener(filePath, type: mimeType);

        if (openResult.type != open_filex.ResultType.done) {
          AppLogger.w(
            '[FILE-OPEN] Handler declined:\n'
            '  assetCode: $assetCode\n'
            '  fileName: $fileName\n'
            '  filePath: $filePath\n'
            '  mimeType: $mimeType\n'
            '  resultType: ${openResult.type}\n'
            '  resultMessage: ${openResult.message}',
          );
          return false;
        }

        AppLogger.i(
          '[FILE-OPEN] Success:\n'
          '  assetCode: $assetCode\n'
          '  fileName: $fileName\n'
          '  filePath: $filePath',
        );
        return true;
      } catch (openError) {
        AppLogger.w(
          '[FILE-OPEN] Exception:\n'
          '  assetCode: $assetCode\n'
          '  fileName: $fileName\n'
          '  error: $openError\n'
          '  mimeType: $mimeType',
        );
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        '[FILE-OPEN] Exception for $assetCode:\n'
        '  error: $e\n'
        '  fileName: $fileName\n'
        '  filePath: $filePath\n'
        '  stackTrace: $stackTrace',
      );
      return false;
    }
  }

  /// Get MIME type from file extension
  String getMimeType(String fileName) {
    final ext = _getExtension(fileName).toLowerCase();

    return switch (ext) {
      'pdf' => 'application/pdf',
      'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'xls' => 'application/vnd.ms-excel',
      'csv' => 'text/csv',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'doc' => 'application/msword',
      'ppt' => 'application/vnd.ms-powerpoint',
      'pptx' =>
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt' => 'text/plain',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'heic' => 'image/heic',
      _ => 'application/octet-stream',
    };
  }

  /// Sanitize filename to prevent path traversal
  String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  /// Get file extension
  String _getExtension(String fileName) {
    if (!fileName.contains('.')) return '';
    return fileName.split('.').last;
  }
}
