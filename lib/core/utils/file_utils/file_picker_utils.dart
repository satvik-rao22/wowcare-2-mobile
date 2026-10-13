import 'dart:io';

import 'package:equatable/equatable.dart';
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
enum PickType {
  document,
  image,
  video,
  imageOrVideo,

  /// Documents and photos — the usual "attach a file" choice.
  documentOrImage,

  /// No type filter at all.
  any,
}

/// A file the user picked off the device, checked and ready to upload. It
/// carries no upload state — an uploaded file is a different thing.
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

  /// Lowercase, without the dot: `pdf`, `jpg`. Empty when there is none.
  final String extension;

  /// The real type (FileUtils.mimeTypeOfFile): photos and PDFs from their
  /// bytes, everything else from the name.
  final String mimeType;

  bool get isImage => mimeType.startsWith('image/');
  bool get isVideo => mimeType.startsWith('video/');
  bool get isPdf => mimeType == 'application/pdf';

  /// `1.4 MB`, `812 KB`.
  String get readableSize => FileUtils.formatBytes(sizeBytes);

  File get file => File(path);

  /// Identity is the on-disk path — the same file picked twice is one file.
  @override
  List<Object?> get props => [path];
}

/// What the Android recovery found: files a capture finished saving after
/// the OS had closed the app (see [FilePickerUtils.recoverLostMedia]).
typedef LostMedia = ({List<String> paths, bool isVideo, String? error});

/// One file as a picker handed it back, before any checks.
typedef _Picked = ({String? path, String name});

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
/// - re-checking every file's type rather than trusting the OS dialog filter
///   (some Android providers ignore it); a file whose name has no extension
///   is judged by its content,
/// - size limits, an attachment limit ([pick]'s `maxFiles`) and files that
///   are already attached,
/// - one standard message saying what was skipped and why,
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
/// | Open, share or save a file to the gallery   | FileActions                 |
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

  /// Attachments per item, matching the document service's `maxAssetCount`
  /// on the upload session it mints. When a caller has a session in hand it
  /// should pass that value instead, so a server-side change needs no release.
  static const int defaultMaxFiles = 5;

  /// Lets the user pick files and returns the ones that passed the checks.
  /// Empty when they cancel, nothing passed, or the picker failed.
  ///
  /// - [allowedExtensions] overrides the list [type] would allow.
  /// - [maxSizeMB] limits every file; [maxVideoSizeMB], when set, limits
  ///   videos instead.
  /// - [maxFiles] caps the total, counting [existing] (files already on the
  ///   form); a file in [existing] picked again is skipped, not duplicated.
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
    int? maxFiles,
    List<PickedFile> existing = const [],
    int? imageQuality,
    Duration? maxVideoDuration,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    final allowed = allowedExtensions ?? extensionsFor(type);
    if (maxFiles != null && existing.length >= maxFiles) {
      _show(_limitMessage(maxFiles));
      return const [];
    }

    final List<_Picked> picked;
    try {
      picked = switch (source) {
        PickSource.files => await _fromFiles(allowed, multiple),
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
      picked,
      allowed: allowed,
      maxBytes: _bytes(maxSizeMB),
      maxVideoBytes: _bytes(maxVideoSizeMB) ?? _bytes(maxSizeMB),
      maxFiles: maxFiles,
      existing: existing,
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

  /// The extensions [type] allows; empty means "no filter".
  static List<String> extensionsFor(PickType type) => switch (type) {
    PickType.document => allowedDocumentExtensions,
    PickType.image => allowedImageExtensions,
    PickType.video => allowedVideoExtensions,
    PickType.imageOrVideo => const [
      ...allowedImageExtensions,
      ...allowedVideoExtensions,
    ],
    PickType.documentOrImage => defaultAllowedExtensions,
    PickType.any => const [],
  };

  /// Allow-list entries that are MIME subtypes, not real file extensions. On
  /// Android file_picker turns each extension into a MIME type for the system
  /// dialog and, if even one has no mapping, drops the filter entirely and
  /// lists every file (zip, apk…). They stay allowed, but out of the dialog.
  static const Set<String> _nonDialogExtensions = {
    'heic-sequence',
    'heif-sequence',
  };

  /// [extensions] as the system file dialog should receive them.
  static List<String> dialogExtensions(List<String> extensions) =>
      extensions.where((e) => !_nonDialogExtensions.contains(e)).toList();

  /// Whether a picked file is one of [allowedExtensions].
  ///
  /// An allowed extension on the [name] (or the [path]) is enough. Otherwise
  /// the content decides: Android document providers can report a name with
  /// no usable extension (e.g. "IMG_1234") for a file whose content already
  /// matched the dialog filter, so a real JPEG or PDF is not rejected for its
  /// name alone — while archives, APKs and executables match nothing listed.
  static Future<bool> isAllowedType({
    required String name,
    required String path,
    required List<String> allowedExtensions,
  }) async {
    if (allowedExtensions.isEmpty) return true;
    if (allowedExtensions.contains(FileUtils.extension(name)) ||
        allowedExtensions.contains(FileUtils.extension(path))) {
      return true;
    }
    if (!await File(path).exists()) return false;
    final byContent = await FileUtils.mimeTypeOfFile(path);
    if (byContent == FileUtils.unknownMimeType) return false;
    return allowedExtensions.any(
      (ext) => FileUtils.mimeType('file.$ext') == byContent,
    );
  }

  // ── Pickers ───────────────────────────────────────────────────────────────

  static Future<List<_Picked>> _fromFiles(
    List<String> extensions,
    bool multiple,
  ) async {
    final result = await FilePicker.pickFiles(
      type: extensions.isEmpty ? FileType.any : FileType.custom,
      allowedExtensions: extensions.isEmpty
          ? null
          : dialogExtensions(extensions),
      allowMultiple: multiple,
    );
    return _picked(result);
  }

  static Future<List<_Picked>> _fromPhotos(PickType type, bool multiple) async {
    final result = await FilePicker.pickFiles(
      type: switch (type) {
        PickType.video => FileType.video,
        PickType.imageOrVideo => FileType.media,
        _ => FileType.image,
      },
      allowMultiple: multiple,
    );
    return _picked(result);
  }

  static Future<List<_Picked>> _fromCamera(
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
    return shot == null ? const [] : [(path: shot.path, name: shot.name)];
  }

  static List<_Picked> _picked(FilePickerResult? result) => [
    for (final f in result?.files ?? const <PlatformFile>[])
      (path: f.path, name: f.name),
  ];

  // ── Checks ────────────────────────────────────────────────────────────────

  static Future<List<PickedFile>> _check(
    List<_Picked> picked, {
    required List<String> allowed,
    required int? maxBytes,
    required int? maxVideoBytes,
    required int? maxFiles,
    required List<PickedFile> existing,
  }) async {
    final accepted = <PickedFile>[];
    final unsupported = <String>[];
    final unreadable = <String>[];
    final duplicates = <String>[];
    final oversized = <String, int>{}; // name → the limit it broke
    var overLimit = 0;
    // Seeded with what is already attached, so a file can't be added twice
    // across two separate picks, not just within one.
    final seenPaths = {for (final f in existing) f.path};
    final room = maxFiles == null ? null : maxFiles - existing.length;

    for (final p in picked) {
      final path = p.path;
      final name = p.name.isNotEmpty
          ? p.name
          : (path == null ? '' : FileUtils.fileName(path));
      if (path == null || path.trim().isEmpty) {
        unreadable.add(name);
        continue;
      }
      if (seenPaths.contains(path)) {
        duplicates.add(name);
        continue;
      }
      if (!await isAllowedType(
        name: name,
        path: path,
        allowedExtensions: allowed,
      )) {
        unsupported.add(name);
        continue;
      }
      final int size;
      try {
        size = await File(path).length();
      } catch (e, stackTrace) {
        AppLogger.e('[FilePicker] Cannot read $name', e, stackTrace);
        unreadable.add(name);
        continue;
      }
      final mimeType = await FileUtils.mimeTypeOfFile(path);
      final limit = mimeType.startsWith('video/') ? maxVideoBytes : maxBytes;
      if (limit != null && size > limit) {
        oversized[name] = limit;
        continue;
      }
      // Slots go in selection order, so what's over the limit is the tail.
      if (room != null && accepted.length >= room) {
        overLimit++;
        continue;
      }
      seenPaths.add(path);
      final ext = FileUtils.extension(name);
      accepted.add(
        PickedFile(
          path: path,
          name: name,
          sizeBytes: size,
          extension: ext.isNotEmpty ? ext : FileUtils.extension(path),
          mimeType: mimeType,
        ),
      );
    }

    final message = rejectionMessage(
      unsupported: unsupported,
      oversized: oversized,
      unreadable: unreadable,
      duplicates: duplicates,
      overLimit: overLimit,
      maxFiles: maxFiles,
    );
    if (message != null) _show(message);
    return accepted;
  }

  /// One sentence for the files that were skipped, or null when none were:
  /// "photo.png exceeds the 10 MB limit", "2 files are not a supported file
  /// type", "report.pdf is already attached", "3 files couldn't be
  /// attached"…
  static String? rejectionMessage({
    required List<String> unsupported,
    required Map<String, int> oversized,
    List<String> unreadable = const [],
    List<String> duplicates = const [],
    int overLimit = 0,
    int? maxFiles,
  }) {
    final total =
        unsupported.length +
        oversized.length +
        unreadable.length +
        duplicates.length +
        overLimit;
    if (total == 0) return null;
    String mb(int bytes) =>
        AppStrings.megabytes((bytes / (1024 * 1024)).round());

    // Only one kind of problem: name it precisely.
    if (unreadable.length == total) {
      return total == 1
          ? AppStrings.fileUnreadable(unreadable.first)
          : AppStrings.filesUnreadable(total);
    }
    if (duplicates.length == total) {
      return total == 1
          ? '${duplicates.first} is already attached'
          : '$total files are already attached';
    }
    if (overLimit == total) return _limitMessage(maxFiles);

    // Size and/or type problems only.
    if (unsupported.length + oversized.length == total) {
      if (unsupported.isEmpty) {
        if (oversized.length == 1) {
          final entry = oversized.entries.first;
          return AppStrings.fileExceedsLimit(entry.key, mb(entry.value));
        }
        final limits = oversized.values.toSet().toList()..sort();
        if (limits.length == 1) {
          return AppStrings.filesExceedLimit(
            oversized.length,
            mb(limits.first),
          );
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
        total,
        oversized.length,
        unsupported.length,
      );
    }
    return AppStrings.filesCouldNotBeAttached(total);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _limitMessage(int? maxFiles) => maxFiles == null
      ? 'Attachment limit reached'
      : 'You can attach up to $maxFiles files';

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
