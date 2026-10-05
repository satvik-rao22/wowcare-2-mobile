import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:wowcare/core/utils/core_utils.dart';

/// What kind of files a picker call should offer.
///
/// Each kind maps to a concrete extension allow-list; the platform picker is
/// filtered by it *and* every returned file is re-validated against it, because
/// some Android providers ignore the requested filter.
enum FilePickerKind { image, document, video, imageAndDocument, media, any }

/// Why a selected file did not make it into the result.
enum FileRejectionReason {
  tooLarge,
  unsupportedType,
  limitReached,
  duplicate,
  unreadable,
}

/// A file the user picked off the device, validated and ready to upload.
///
/// This is the hand-off type between the picker and the upload layer: the
/// picker produces it, the upload manager consumes it. It deliberately carries
/// no upload state — an uploaded file is a different thing entirely.
class PickedFile extends Equatable {
  const PickedFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.extension,
    required this.mimeType,
  });

  final String path;
  final String name;
  final int sizeBytes;

  /// Lower-case, dot-free (`pdf`, not `.PDF`). Empty when the file has none.
  final String extension;
  final String mimeType;

  bool get isImage => mimeType.startsWith('image/');
  bool get isVideo => mimeType.startsWith('video/');
  bool get isPdf => mimeType == 'application/pdf';

  /// `IMAGE` / `VIDEO` / `DOCUMENT` — the document service's `mediaType`.
  String get mediaType {
    if (isImage) return 'IMAGE';
    if (isVideo) return 'VIDEO';
    return 'DOCUMENT';
  }

  String get readableSize => FilePickerUtils.formatBytes(sizeBytes);

  File get file => File(path);

  /// Identity is the on-disk path — the same file picked twice is one file.
  @override
  List<Object?> get props => [path];
}

/// A file the user chose that was dropped, with a reason the UI can show.
class FileRejection extends Equatable {
  const FileRejection({
    required this.name,
    required this.reason,
    required this.message,
  });

  final String name;
  final FileRejectionReason reason;

  /// Ready to show, e.g. `report.pdf is larger than 10 MB`.
  final String message;

  @override
  List<Object?> get props => [name, reason, message];
}

/// Outcome of a pick: what was accepted, and what was dropped and why.
///
/// Rejections are returned rather than silently swallowed so the UI can tell
/// the user that 2 of their 5 files did not make it, instead of leaving them to
/// notice the missing ones themselves.
class FilePickResult extends Equatable {
  const FilePickResult({this.files = const [], this.rejected = const []});

  final List<PickedFile> files;
  final List<FileRejection> rejected;

  bool get isEmpty => files.isEmpty;
  bool get hasRejections => rejected.isNotEmpty;

  /// One-line summary of everything that was dropped, or null when nothing was.
  ///
  /// A single rejection reads as its own message; several collapse into a count
  /// so the snackbar stays one line.
  String? get rejectionSummary {
    if (rejected.isEmpty) return null;
    if (rejected.length == 1) return rejected.first.message;

    final reasons = rejected.map((r) => r.reason).toSet();
    if (reasons.length == 1) {
      final noun = rejected.length == 1 ? 'file' : 'files';
      switch (reasons.first) {
        case FileRejectionReason.tooLarge:
          return '${rejected.length} $noun skipped — too large';
        case FileRejectionReason.unsupportedType:
          return '${rejected.length} $noun skipped — unsupported type';
        case FileRejectionReason.limitReached:
          return '${rejected.length} $noun skipped — attachment limit reached';
        case FileRejectionReason.duplicate:
          return '${rejected.length} $noun skipped — already added';
        case FileRejectionReason.unreadable:
          return '${rejected.length} $noun skipped — could not be read';
      }
    }
    return '${rejected.length} files were skipped';
  }

  @override
  List<Object?> get props => [files, rejected];
}

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

  /// Per-file ceiling applied when a caller does not set its own.
  static const int defaultMaxFileSizeBytes = 10 * 1024 * 1024;

  /// Attachments per item, matching the document service's `maxAssetCount` on
  /// the upload session it mints.
  ///
  /// The session is authoritative — when a caller has one in hand it should
  /// pass that value through instead of relying on this default, so a
  /// server-side limit change does not need an app release.
  static const int defaultMaxFiles = 5;

  /// Extension allow-list for [kind]; empty means "no filter".
  static List<String> extensionsFor(FilePickerKind kind) {
    switch (kind) {
      case FilePickerKind.image:
        return allowedImageExtensions;
      case FilePickerKind.document:
        return allowedDocumentExtensions;
      case FilePickerKind.video:
        return allowedVideoExtensions;
      case FilePickerKind.imageAndDocument:
        return defaultAllowedExtensions;
      case FilePickerKind.media:
        return const [...allowedImageExtensions, ...allowedVideoExtensions];
      case FilePickerKind.any:
        return const [];
    }
  }

  /// Picks one file, validated against [kind] and [maxSizeBytes].
  ///
  /// Returns null when the user cancels, when the pick fails, or when the file
  /// fails validation — in the last two cases an explanatory snackbar is shown
  /// if [context] is supplied and still mounted.
  static Future<PickedFile?> pickSingleFile({
    FilePickerKind kind = FilePickerKind.imageAndDocument,
    List<String>? allowedExtensions,
    int maxSizeBytes = defaultMaxFileSizeBytes,
    BuildContext? context,
  }) async {
    final result = await pickMultipleFiles(
      kind: kind,
      allowedExtensions: allowedExtensions,
      maxSizeBytes: maxSizeBytes,
      maxFiles: 1,
      allowMultiple: false,
      context: context,
    );
    return result.files.isEmpty ? null : result.files.first;
  }

  /// Picks up to [maxFiles] files, minus whatever is [existing] already.
  ///
  /// [existing] is used both to work out how many slots are left and to drop
  /// files that are already on the list, so re-picking the same file is a
  /// no-op rather than a duplicate row. Anything dropped comes back in
  /// [FilePickResult.rejected]; when [context] is supplied a one-line summary
  /// is shown automatically.
  static Future<FilePickResult> pickMultipleFiles({
    FilePickerKind kind = FilePickerKind.imageAndDocument,
    List<String>? allowedExtensions,
    int maxSizeBytes = defaultMaxFileSizeBytes,
    int maxFiles = defaultMaxFiles,
    List<PickedFile> existing = const [],
    bool allowMultiple = true,
    BuildContext? context,
  }) async {
    final extensions = allowedExtensions ?? extensionsFor(kind);
    final remaining = maxFiles - existing.length;

    if (remaining <= 0) {
      final result = FilePickResult(
        rejected: [
          FileRejection(
            name: '',
            reason: FileRejectionReason.limitReached,
            message: 'You can attach up to $maxFiles files',
          ),
        ],
      );
      _reportRejections(context, result);
      return result;
    }

    final FilePickerResult? picked;
    try {
      picked = await FilePicker.pickFiles(
        type: extensions.isEmpty ? FileType.any : FileType.custom,
        allowedExtensions: extensions.isEmpty ? null : extensions,
        allowMultiple: allowMultiple,
      );
    } catch (e) {
      debugPrint('Error picking files: $e');
      if (context != null && context.mounted) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Error selecting files. Please try again.',
          isWarning: true,
        );
      }
      return const FilePickResult();
    }

    if (picked == null || picked.files.isEmpty) return const FilePickResult();

    final accepted = <PickedFile>[];
    final rejected = <FileRejection>[];
    // Seeded with what is already on the list so a file cannot be added twice
    // across two separate picks, not just within one.
    final seenPaths = existing.map((f) => f.path).toSet();

    for (final platformFile in picked.files) {
      final name = platformFile.name;
      final path = platformFile.path;

      if (path == null || path.isEmpty) {
        rejected.add(
          FileRejection(
            name: name,
            reason: FileRejectionReason.unreadable,
            message: '$name could not be read',
          ),
        );
        continue;
      }

      if (seenPaths.contains(path)) {
        rejected.add(
          FileRejection(
            name: name,
            reason: FileRejectionReason.duplicate,
            message: '$name is already attached',
          ),
        );
        continue;
      }

      final extension = _normalizedExtension(platformFile.extension, name);
      // Re-checked here rather than trusting the dialog filter: several Android
      // document providers hand back whatever the user tapped.
      if (extensions.isNotEmpty && !extensions.contains(extension)) {
        rejected.add(
          FileRejection(
            name: name,
            reason: FileRejectionReason.unsupportedType,
            message: '$name is not a supported file type',
          ),
        );
        continue;
      }

      final sizeBytes = platformFile.size;
      if (sizeBytes > maxSizeBytes) {
        rejected.add(
          FileRejection(
            name: name,
            reason: FileRejectionReason.tooLarge,
            message: '$name is larger than ${formatBytes(maxSizeBytes)}',
          ),
        );
        continue;
      }

      // Slots are consumed in selection order, so the overflow the user sees
      // rejected is the tail of what they picked.
      if (accepted.length >= remaining) {
        rejected.add(
          FileRejection(
            name: name,
            reason: FileRejectionReason.limitReached,
            message: 'You can attach up to $maxFiles files',
          ),
        );
        continue;
      }

      seenPaths.add(path);
      accepted.add(
        PickedFile(
          path: path,
          name: name,
          sizeBytes: sizeBytes,
          extension: extension,
          mimeType: resolveMimeType(path: path, extension: extension),
        ),
      );
    }

    final result = FilePickResult(files: accepted, rejected: rejected);
    _reportRejections(context, result);
    return result;
  }

  /// Best-effort mime type: the `mime` package first (it reads the name), then
  /// the extension table, which still covers HEIC/AVIF variants the package can
  /// miss.
  static String resolveMimeType({required String path, String? extension}) {
    final looked = lookupMimeType(path);
    if (looked != null && looked.isNotEmpty) return looked;
    return getMimeType(extension ?? _extensionFromName(path));
  }

  /// `1.4 MB`, `812 KB`, `— ` for nothing.
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes >= mb) {
      final value = bytes / mb;
      // 10 MB reads better than 10.0 MB; 1.4 MB needs the decimal.
      return '${value >= 10 ? value.toStringAsFixed(0) : value.toStringAsFixed(1)} MB';
    }
    final value = bytes / kb;
    return '${value < 10 ? value.toStringAsFixed(1) : value.toStringAsFixed(0)} KB';
  }

  static void _reportRejections(BuildContext? context, FilePickResult result) {
    if (context == null || !context.mounted || !result.hasRejections) return;
    final summary = result.rejectionSummary;
    if (summary == null) return;
    CoreUtils.showTopSnackBar(context: context, message: summary, isWarning: true);
  }

  static String _normalizedExtension(String? extension, String name) {
    final fromPicker = (extension ?? '').toLowerCase().replaceAll('.', '');
    if (fromPicker.isNotEmpty) return fromPicker;
    return _extensionFromName(name);
  }

  static String _extensionFromName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  /// Picks a single file from the device storage.
  ///
  /// [allowedExtensions] defaults to [defaultAllowedExtensions] if not provided.
  /// The pick is re-checked against that list (and for a readable local path)
  /// rather than trusting the dialog filter, which some document providers
  /// ignore; a rejected file returns null with an error snackbar when
  /// [context] is supplied.
  static Future<PlatformFile?> pickFile({
    List<String>? allowedExtensions,
    BuildContext? context,
  }) async {
    final extensions = allowedExtensions ?? defaultAllowedExtensions;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final String? rejection;
        if (file.path == null || file.path!.isEmpty) {
          rejection = '${file.name} could not be read';
        } else if (!extensions.contains(
          _normalizedExtension(file.extension, file.name),
        )) {
          rejection = '${file.name} is not a supported file type';
        } else {
          return file;
        }
        if (context != null && context.mounted) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: rejection,
            isError: true,
          );
        }
        return null;
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (context != null && context.mounted) {
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
