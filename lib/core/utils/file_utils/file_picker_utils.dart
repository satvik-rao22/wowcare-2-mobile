import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/file_utils/file_utils.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/permission_manager.dart';

/// Where [FilePickerUtils.pick] picks from.
enum PickSource {
  /// The Files browser, limited to the allowed extensions.
  files,

  /// The photo / video library.
  photos,

  /// Take a new photo or record a video (asks for camera access first).
  camera,
}

/// What kind of file [FilePickerUtils.pick] accepts. Sets the default allowed
/// extensions and, for [PickSource.photos] / [PickSource.camera], whether
/// photos or videos are offered.
enum PickType { document, image, video, imageOrVideo }

/// A file the user picked, already checked against the allowed types and
/// size limit.
class PickedFile {
  const PickedFile({
    required this.path,
    required this.name,
    required this.size,
    required this.mimeType,
  });

  final String path;
  final String name;

  /// Size in bytes.
  final int size;

  /// Real type for uploads (see FileUtils.mimeTypeOfFile).
  final String mimeType;

  /// Lowercase, without the dot: `pdf`, `jpg`. Empty when there is none.
  String get extension => FileUtils.extension(name);

  File get file => File(path);

  bool get isImage =>
      FilePickerUtils.allowedImageExtensions.contains(extension);
  bool get isVideo =>
      FilePickerUtils.allowedVideoExtensions.contains(extension);
}

/// What the Android recovery found: files a capture finished saving after
/// the OS had closed the app (see [FilePickerUtils.recoverLostMedia]).
typedef LostMedia = ({List<String> paths, bool isVideo, String? error});

/// The one place the user picks files: from the Files browser, the photo
/// library or the camera.
///
/// ```dart
/// final files = await FilePickerUtils.pick(
///   type: PickType.document,
///   multiple: true,
///   maxSizeMB: 10,
/// );
/// for (final f in files) upload(f.path, f.mimeType);
/// ```
///
/// It handles everything about picking, so callers don't:
/// - camera access via PermissionManager (Settings steps when blocked),
/// - dropping files with a type outside the allowed extensions or over the
///   size limit, with one standard message saying what was skipped and why,
/// - the real MIME type of every file,
/// - cancelling and picker errors: both return an empty list.
///
/// Messages and permission sheets use the app's root navigator, so it can be
/// called after the calling sheet or screen has closed.
///
/// Which file util?
/// | Need                                        | Use                         |
/// |---------------------------------------------|-----------------------------|
/// | Name, extension, MIME type, app folders     | FileUtils                   |
/// | Let the user pick a file / photo / video    | FilePickerUtils (this file) |
/// | Download a URL into a file                  | FileDownloadService         |
///
/// The file_picker and image_picker plugins stay inside this file.
abstract final class FilePickerUtils {
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

  /// Lets the user pick files and returns the ones that passed the checks.
  /// Empty when they cancel, nothing passed, or the picker failed.
  ///
  /// - [allowedExtensions] overrides the list [type] would allow.
  /// - [maxSizeMB] limits every file; [maxVideoSizeMB], when set, limits
  ///   videos instead.
  /// - [imageQuality] (1–100) and [maxVideoDuration] apply to the camera.
  /// - [onError] replaces the standard "couldn't open" message when the
  ///   picker itself fails (cancelling is not an error).
  static Future<List<PickedFile>> pick({
    PickType type = PickType.document,
    PickSource source = PickSource.files,
    bool multiple = false,
    List<String>? allowedExtensions,
    int? maxSizeMB,
    int? maxVideoSizeMB,
    int? imageQuality,
    Duration? maxVideoDuration,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    final List<String> paths;
    try {
      paths = switch (source) {
        PickSource.files => await _fromFiles(
          allowedExtensions ?? _extensionsFor(type),
          multiple,
        ),
        PickSource.photos => await _fromPhotos(type, multiple),
        PickSource.camera => await _fromCamera(
          type,
          imageQuality,
          maxVideoDuration,
        ),
      };
    } catch (e, stackTrace) {
      AppLogger.e('[FilePicker] $source picker failed', e, stackTrace);
      if (onError != null) {
        onError(e, stackTrace);
      } else {
        _show(_couldNotOpen(source), isError: true);
      }
      return const [];
    }

    return _check(
      paths,
      allowed: allowedExtensions ?? _extensionsFor(type),
      maxBytes: _bytes(maxSizeMB),
      maxVideoBytes: _bytes(maxVideoSizeMB) ?? _bytes(maxSizeMB),
    );
  }

  /// [pick] for a single file: the picked file, or null.
  static Future<PickedFile?> pickOne({
    PickType type = PickType.document,
    PickSource source = PickSource.files,
    List<String>? allowedExtensions,
    int? maxSizeMB,
    int? imageQuality,
    Duration? maxVideoDuration,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    final files = await pick(
      type: type,
      source: source,
      allowedExtensions: allowedExtensions,
      maxSizeMB: maxSizeMB,
      imageQuality: imageQuality,
      maxVideoDuration: maxVideoDuration,
      onError: onError,
    );
    return files.isEmpty ? null : files.first;
  }

  /// Picks one file from the Files browser; [allowedExtensions] defaults to
  /// [defaultAllowedExtensions].
  static Future<PickedFile?> pickFile({List<String>? allowedExtensions}) =>
      pickOne(allowedExtensions: allowedExtensions ?? defaultAllowedExtensions);

  /// Android only: a photo or video the camera finished saving after the OS
  /// had closed the app, so the result never arrived. Null when there is
  /// nothing to recover.
  static Future<LostMedia?> recoverLostMedia() async {
    final response = await ImagePicker().retrieveLostData();
    if (response.isEmpty) return null;
    final isVideo = response.type == RetrieveType.video;
    final error = response.exception;
    if (error != null) {
      return (
        paths: const <String>[],
        isVideo: isVideo,
        error: error.message ?? error.code,
      );
    }
    // `files` covers a multi-image pick, `file` a single one.
    final paths = <String>[...?response.files?.map((f) => f.path)];
    if (paths.isEmpty && response.file != null) paths.add(response.file!.path);
    if (paths.isEmpty) return null;
    return (paths: paths, isVideo: isVideo, error: null);
  }

  // ── Pickers ───────────────────────────────────────────────────────────────

  static Future<List<String>> _fromFiles(
    List<String> extensions,
    bool multiple,
  ) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      allowMultiple: multiple,
    );
    return _paths(result);
  }

  static Future<List<String>> _fromPhotos(PickType type, bool multiple) async {
    final result = await FilePicker.pickFiles(
      type: switch (type) {
        PickType.video => FileType.video,
        PickType.imageOrVideo => FileType.media,
        PickType.image || PickType.document => FileType.image,
      },
      allowMultiple: multiple,
    );
    return _paths(result);
  }

  static Future<List<String>> _fromCamera(
    PickType type,
    int? imageQuality,
    Duration? maxVideoDuration,
  ) async {
    final context = _uiContext;
    if (context == null) return const [];
    final allowed = await PermissionManager.ensure(
      context,
      AppPermission.camera,
      reason: type == PickType.video ? 'to record a video' : 'to take a photo',
    );
    if (!allowed) return const [];

    final picker = ImagePicker();
    final shot = type == PickType.video
        ? await picker.pickVideo(
            source: ImageSource.camera,
            maxDuration: maxVideoDuration,
          )
        : await picker.pickImage(
            source: ImageSource.camera,
            imageQuality: imageQuality,
          );
    return shot == null ? const [] : [shot.path];
  }

  static List<String> _paths(FilePickerResult? result) => [
    for (final f in result?.files ?? const <PlatformFile>[])
      if (f.path != null && f.path!.trim().isNotEmpty) f.path!,
  ];

  // ── Checks ────────────────────────────────────────────────────────────────

  static Future<List<PickedFile>> _check(
    List<String> paths, {
    required List<String> allowed,
    required int? maxBytes,
    required int? maxVideoBytes,
  }) async {
    final accepted = <PickedFile>[];
    final unsupported = <String>[];
    final oversized = <String, int>{}; // name → the limit it broke

    for (final path in paths) {
      final name = FileUtils.fileName(path);
      final ext = FileUtils.extension(path);
      if (!allowed.contains(ext)) {
        unsupported.add(name);
        continue;
      }
      final int size;
      try {
        size = await File(path).length();
      } catch (e, stackTrace) {
        AppLogger.e('[FilePicker] Cannot read $name', e, stackTrace);
        unsupported.add(name);
        continue;
      }
      final limit = allowedVideoExtensions.contains(ext)
          ? maxVideoBytes
          : maxBytes;
      if (limit != null && size > limit) {
        oversized[name] = limit;
        continue;
      }
      accepted.add(
        PickedFile(
          path: path,
          name: name,
          size: size,
          mimeType: await FileUtils.mimeTypeOfFile(path),
        ),
      );
    }

    final message = rejectionMessage(
      unsupported: unsupported,
      oversized: oversized,
    );
    if (message != null) _show(message);
    return accepted;
  }

  /// One sentence for the files that were skipped, or null when none were:
  /// "photo.png exceeds the 10 MB limit", "2 files are not a supported file
  /// type", "3 files couldn't be attached: …".
  static String? rejectionMessage({
    required List<String> unsupported,
    required Map<String, int> oversized,
  }) {
    if (oversized.isEmpty && unsupported.isEmpty) return null;
    String mb(int bytes) =>
        AppStrings.megabytes((bytes / (1024 * 1024)).round());

    if (unsupported.isEmpty) {
      if (oversized.length == 1) {
        final entry = oversized.entries.first;
        return AppStrings.fileExceedsLimit(entry.key, mb(entry.value));
      }
      final limits = oversized.values.toSet().toList()..sort();
      if (limits.length == 1) {
        return AppStrings.filesExceedLimit(oversized.length, mb(limits.first));
      }
      return AppStrings.filesExceedMixedLimits(
        oversized.length,
        mb(limits.first),
        mb(limits.last),
      );
    }
    if (oversized.isEmpty) {
      return unsupported.length == 1
          ? AppStrings.fileUnsupportedType(unsupported.first)
          : AppStrings.filesUnsupportedType(unsupported.length);
    }
    return AppStrings.filesPartiallyRejected(
      oversized.length + unsupported.length,
      oversized.length,
      unsupported.length,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static List<String> _extensionsFor(PickType type) => switch (type) {
    PickType.document => allowedDocumentExtensions,
    PickType.image => allowedImageExtensions,
    PickType.video => allowedVideoExtensions,
    PickType.imageOrVideo => [
      ...allowedImageExtensions,
      ...allowedVideoExtensions,
    ],
  };

  static int? _bytes(int? mb) => mb == null ? null : mb * 1024 * 1024;

  static String _couldNotOpen(PickSource source) => switch (source) {
    PickSource.camera => "Couldn't open the camera. Please try again.",
    PickSource.photos => "Couldn't open your photos. Please try again.",
    PickSource.files => "Couldn't open your files. Please try again.",
  };

  /// A context inside the root navigator — still valid after the sheet or
  /// screen that started the pick has closed.
  static BuildContext? get _uiContext =>
      CoreUtils.rootNavigatorKey.currentState?.overlay?.context;

  static void _show(String message, {bool isError = false}) {
    final context = _uiContext;
    if (context == null) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: message,
      isError: isError,
      isWarning: !isError,
    );
  }
}
