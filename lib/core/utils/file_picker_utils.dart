import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/core/utils/core_utils.dart';

class FilePickerUtils {
  const FilePickerUtils._();

  /// Allowed document formats:
  /// application/pdf,
  /// application/msword,
  /// application/vnd.openxmlformats-officedocument.wordprocessingml.document,
  /// application/vnd.ms-excel,
  /// application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,
  /// application/vnd.ms-powerpoint,
  /// application/vnd.openxmlformats-officedocument.presentationml.presentation,
  /// text/csv
  static const List<String> allowedDocumentExtensions = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'csv',
  ];

  /// Allowed video formats: video/mp4, video/quicktime, video/webm
  static const List<String> allowedVideoExtensions = [
    'mp4',
    'mov', // QuickTime
    'webm',
  ];

  /// Allowed image formats:
  /// image/jpeg,image/jpg,image/png,image/webp,image/heic,image/heif,
  /// image/heic-sequence,image/heif-sequence,image/avif,image/gif,
  /// image/bmp,image/tiff
  static const List<String> allowedImageExtensions = [
    'jpeg',
    'jpg',
    'png',
    'webp',
    'heic',
    'heif',
    'heic-sequence',
    'heif-sequence',
    'avif',
    'gif',
    'bmp',
    'tiff',
    'tif',
  ];

  static const List<String> defaultAllowedExtensions = [
    ...allowedDocumentExtensions,
    ...allowedImageExtensions,
  ];

  /// Picks a single file from the device storage.
  ///
  /// [allowedExtensions] defaults to [defaultAllowedExtensions] if not provided.
  /// [context] is optional but recommended for showing error feedback.
  static Future<PlatformFile?> pickFile({
    List<String>? allowedExtensions,
    BuildContext? context,
  }) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions ?? defaultAllowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (context != null) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Error selecting file. Please try again.',
          isWarning: true,
        );
      }
    }
    return null;
  }

  /// Returns the mime type based on the file extension.
  static String getMimeType(String? extension) {
    if (extension == null) return 'application/octet-stream';

    final ext = extension.toLowerCase().replaceAll('.', '');

    const mimeTypes = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'jpeg': 'image/jpeg',
      'jpg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
      'heic': 'image/heic',
      'heif': 'image/heif',
      'heic-sequence': 'image/heic-sequence',
      'heif-sequence': 'image/heif-sequence',
      'avif': 'image/avif',
      'gif': 'image/gif',
      'bmp': 'image/bmp',
      'tif': 'image/tiff',
      'tiff': 'image/tiff',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'webm': 'video/webm',
      'csv': 'text/csv',
      // Not accepted as a DOCUMENT/IMAGE/VIDEO by the backend, but real
      // extensions a device file picker can still hand back (e.g. Android's
      // "Files"/WhatsApp pickers ignore allowedExtensions on some OEMs) -
      // mapping them to their real audio/* type lets the backend's own
      // "Content type 'audio/mpeg' is not allowed for ..." message reach the
      // user instead of a meaningless "'application/octet-stream' is not
      // allowed" fallback.
      'mp3': 'audio/mpeg',
      'm4a': 'audio/mp4',
      'wav': 'audio/x-wav',
      'aac': 'audio/aac',
      'ogg': 'audio/ogg',
      'opus': 'audio/opus',
    };

    return mimeTypes[ext] ?? 'application/octet-stream';
  }
}
