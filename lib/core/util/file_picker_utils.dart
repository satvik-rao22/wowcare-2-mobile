import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/core/util/core_utils.dart';

class FilePickerUtils {
  const FilePickerUtils._();

  static const List<String> defaultAllowedExtensions = [
    'pdf',
    'doc',
    'docx',
    'jpg',
    'jpeg',
    'png',
    'heic',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
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
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'heic': 'image/heic',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    };
    
    return mimeTypes[ext] ?? 'application/octet-stream';
  }
}
