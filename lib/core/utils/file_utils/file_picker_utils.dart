import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/core/utils/core_utils.dart';

/// Lets the user pick a file from the device (documents, photos, videos).
///
/// Which file util?
/// | Need                                        | Use                         |
/// |---------------------------------------------|-----------------------------|
/// | Name, extension, MIME type, app folders     | FileUtils                   |
/// | Let the user pick a file / photo / video    | FilePickerUtils (this file) |
/// | Download a URL into a file                  | FileDownloadService         |
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
}
