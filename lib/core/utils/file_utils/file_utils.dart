import 'dart:io';

import 'package:mime/mime.dart' as mime;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:wowcare/core/utils/app_time.dart';

/// The one place the app works out file names, extensions, MIME types and
/// app folders.
///
/// No setup — import this file and call it:
///
/// ```dart
/// FileUtils.extension('https://cdn/x/Report.PDF?sig=1');   // 'pdf'
/// FileUtils.mimeType(file.path);                          // 'image/heic'
/// final out = await FileUtils.tempPathForDownload(
///   url,
///   name: doc.documentName,
///   fallbackExtension: 'jpg',
/// );
/// ```
///
/// Which file util?
/// | Need                                        | Use                    |
/// |---------------------------------------------|------------------------|
/// | Name, extension, MIME type, app folders     | FileUtils (this file)  |
/// | Let the user pick a file / photo / video    | FilePickerUtils        |
/// | Download a URL into a file                  | FileDownloadService    |
///
/// The mime, path and path_provider plugins stay inside this file, so
/// upgrading or swapping one changes nothing at the call sites. Plain
/// `dart:io` File / Directory reads and writes are used directly.
abstract final class FileUtils {
  static const String unknownMimeType = 'application/octet-stream';

  // ── App folders ───────────────────────────────────────────────────────────

  /// Scratch space the OS may clear at any time: downloads on their way to
  /// the gallery, previews, thumbnails.
  static Future<Directory> tempDirectory() => getTemporaryDirectory();

  /// Kept until the app is uninstalled. Holds files the user saved.
  static Future<Directory> documentsDirectory() =>
      getApplicationDocumentsDirectory();

  /// Kept until the app is uninstalled, for app-internal state the user
  /// never sees (cookies, pending uploads).
  static Future<Directory> supportDirectory() =>
      getApplicationSupportDirectory();

  /// A path in [tempDirectory] for [fileName], cleaned with [safeFileName].
  static Future<String> tempFilePath(String fileName) async =>
      join((await tempDirectory()).path, safeFileName(fileName));

  /// Where to download [url] before saving or opening it: a file in
  /// [tempDirectory] named after [name] (or `wowcare_file_<time>` when it's
  /// blank), with the URL's extension — or [fallbackExtension] when the URL
  /// has none.
  static Future<String> tempPathForDownload(
    String url, {
    String? name,
    required String fallbackExtension,
  }) {
    final base = (name ?? '').trim().isNotEmpty
        ? name!.trim()
        : 'wowcare_file_${AppTime.nowUtc().millisecondsSinceEpoch}';
    final urlExt = extension(url);
    return tempFilePath(
      '$base.${urlExt.isNotEmpty ? urlExt : fallbackExtension}',
    );
  }

  // ── Names and paths ───────────────────────────────────────────────────────

  static String join(String part1, String part2, [String? part3]) =>
      p.join(part1, part2, part3);

  /// The last part of a path or URL: `/a/b/report.pdf` → `report.pdf`.
  static String fileName(String pathOrUrl) => p.basename(_pathOf(pathOrUrl));

  /// Lowercase extension without the dot: `Report.PDF` → `pdf`. Works on
  /// paths and URLs (ignores `?query` and `#fragment`). Empty when there is
  /// none.
  static String extension(String pathOrUrl) {
    final ext = p.extension(_pathOf(pathOrUrl));
    return ext.isEmpty ? '' : ext.substring(1).toLowerCase();
  }

  /// [name] made safe to use as a file name: characters that are illegal in
  /// file names, and whitespace, become `_`. Letters of every language are
  /// kept, so two documents with non-Latin names don't end up the same file.
  ///
  /// Saved downloads are found again by this name, so changing the rule
  /// makes the app download them again.
  static String safeFileName(String name) => name
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'\s+'), '_');

  // ── MIME types ────────────────────────────────────────────────────────────

  /// The MIME type for a file path, name or URL — `image/heic`,
  /// `application/pdf`… Uses the mime package first, then our own table
  /// (the types the backend expects), then [fallback].
  static String mimeType(
    String pathOrName, {
    String fallback = unknownMimeType,
  }) {
    final path = _pathOf(pathOrName);
    return mime.lookupMimeType(path) ?? _mimeTypes[extension(path)] ?? fallback;
  }

  /// The MIME type for an extension (`pdf`, `.PDF`…) from our own table, or
  /// `application/octet-stream`.
  static String mimeTypeForExtension(String? extension) {
    if (extension == null) return unknownMimeType;
    final ext = extension.toLowerCase().replaceAll('.', '');
    return _mimeTypes[ext] ?? unknownMimeType;
  }

  /// Whether a file path, name or URL is a photo, judged by its extension.
  static bool isImage(String pathOrName) =>
      mimeType(pathOrName).startsWith('image/');

  /// Whether a file path, name or URL is a video, judged by its extension.
  static bool isVideo(String pathOrName) =>
      mimeType(pathOrName).startsWith('video/');

  /// A URL's path part (no query or fragment); a plain path is returned as is.
  static String _pathOf(String pathOrUrl) {
    final value = pathOrUrl.trim();
    if (!value.contains('://')) return value;
    return Uri.tryParse(value)?.path ?? value;
  }

  static const Map<String, String> _mimeTypes = {
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
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx':
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'webm': 'video/webm',
    'csv': 'text/csv',
    'txt': 'text/plain',
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
}
