import 'dart:io';
import 'dart:typed_data';

import 'package:mime/mime.dart' as mime;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/core/utils/logger_service.dart';

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
/// | Open, share or save a file to the gallery   | FileActions            |
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

  /// Where [fileName] is (or would be) kept in [documentsDirectory], cleaned
  /// with [safeFileName]. Doesn't touch the disk — check `exists()` to see
  /// whether it was saved before. Same rule as [saveToDocuments], so a saved
  /// file is always found again.
  static Future<File> documentsFile(String fileName) async {
    final dir = await documentsDirectory();
    return File('${dir.path}/${safeFileName(fileName)}');
  }

  /// Saves [bytes] as [fileName] in [documentsDirectory] and returns its
  /// path, or null when there's nothing to save, it's over 500 MB, or the
  /// write failed. Never throws.
  static Future<String?> saveToDocuments(
    Uint8List bytes,
    String fileName,
  ) async {
    if (bytes.isEmpty) {
      AppLogger.e('[FileUtils] Not saving $fileName: no bytes');
      return null;
    }
    if (bytes.length > _maxSavedFileBytes) {
      AppLogger.e(
        '[FileUtils] Not saving $fileName: ${bytes.length} bytes is over 500 MB',
      );
      return null;
    }
    try {
      final file = await documentsFile(fileName);
      await file.writeAsBytes(bytes);
      final size = await file.length();
      if (size == 0) {
        AppLogger.e('[FileUtils] Saved $fileName is empty: ${file.path}');
        return null;
      }
      if (size != bytes.length) {
        AppLogger.w(
          '[FileUtils] Saved $fileName size $size, expected ${bytes.length}',
        );
      }
      AppLogger.i('[FileUtils] Saved $fileName ($size bytes): ${file.path}');
      return file.path;
    } catch (e, stackTrace) {
      AppLogger.e('[FileUtils] Saving $fileName failed', e, stackTrace);
      return null;
    }
  }

  static const int _maxSavedFileBytes = 500 * 1024 * 1024;

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
  //
  // One rule for the whole app:
  // - Uploading a file on the device → mimeTypeOfFile (or
  //   imageMimeTypeOfFile for photos). Reads the file's first bytes.
  // - Only a name or URL (previews, saved document records) → mimeType.

  /// The MIME type for a file path, name or URL, judged by its name —
  /// `image/heic`, `application/pdf`… Uses the mime package first, then our
  /// own table (the types the backend expects), then [fallback].
  ///
  /// For a file that is about to be uploaded use [mimeTypeOfFile]: a name
  /// can lie, the file's bytes can't.
  static String mimeType(
    String pathOrName, {
    String fallback = unknownMimeType,
  }) {
    final path = _pathOf(pathOrName);
    return mime.lookupMimeType(path) ?? _mimeTypes[extension(path)] ?? fallback;
  }

  /// The real MIME type of the file at [path], for uploads.
  ///
  /// Photos and PDFs are recognised from the file's first bytes, so a HEIC
  /// photo saved as `IMG_1.jpg` uploads as `image/heic`, not `image/jpeg` —
  /// a wrong type leaves the backend unable to process the file. Everything
  /// else (videos, Word/Excel/PowerPoint, audio) is judged by its name, as
  /// [mimeType] does: the bytes of those formats can't be told apart
  /// reliably. If the file can't be read, the name decides.
  static Future<String> mimeTypeOfFile(
    String path, {
    String fallback = unknownMimeType,
  }) async {
    final byContent = await _imageOrPdfFromBytes(path);
    return byContent ?? mimeType(path, fallback: fallback);
  }

  /// [mimeTypeOfFile] for photo uploads: anything that isn't recognised as
  /// an image uploads as `image/jpeg`.
  static Future<String> imageMimeTypeOfFile(String path) async {
    final type = await mimeTypeOfFile(path);
    return type.startsWith('image/') ? type : 'image/jpeg';
  }

  /// Image or PDF type from the file's first bytes, or null. Only these are
  /// trusted: the mime package's byte checks misread WebM as audio and miss
  /// QuickTime, and Office files are plain ZIPs on the inside.
  static Future<String?> _imageOrPdfFromBytes(String path) async {
    final List<int> header;
    try {
      final file = await File(path).open();
      try {
        header = await file.read(_headerBytes);
      } finally {
        await file.close();
      }
    } catch (_) {
      return null;
    }
    // An empty name, so only the bytes are matched — never the extension.
    final type = mime.lookupMimeType('', headerBytes: header);
    if (type == null) return null;
    return type.startsWith('image/') || type == 'application/pdf' ? type : null;
  }

  /// Enough for every image/PDF signature the mime package checks.
  static const int _headerBytes = 32;

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
