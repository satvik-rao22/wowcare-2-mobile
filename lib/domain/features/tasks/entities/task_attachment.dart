import 'package:equatable/equatable.dart';
import 'package:wowcare/core/utils/file_picker_utils.dart';

/// Thrown when a task's attachments cannot be read — the backend exposes no
/// attachments endpoint, or the request failed.
///
/// This is not merely "no attachments": because create/update treat
/// `assetCodes` as a **full replace**, saving a list built from an unreadable
/// set would silently delete whatever the server actually holds. Callers must
/// therefore refuse to write attachments when they see this.
class TaskAttachmentsUnavailable implements Exception {
  const TaskAttachmentsUnavailable();

  @override
  String toString() => 'TaskAttachmentsUnavailable';
}

// SUPERSEDED by `FilePickerUtils.formatBytes`, which formats identically and is
// already used by every other attachment surface.
//
// String formatAttachmentSize(int bytes) {
//   if (bytes <= 0) return '';
//   if (bytes < 1024) return '$bytes B';
//   final kb = bytes / 1024;
//   if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
//   return '${(kb / 1024).toStringAsFixed(1)} MB';
// }

/// One attachment currently hanging off a task series.
///
/// Two codes matter and they are not interchangeable: [assetCode] is the
/// document-microservice asset (`AST_…`) that the §8/§9 upload flow mints and
/// that create/update's `assetCodes` full-replace speaks in, while [code] is
/// the events-todo-side attachment row (`ATT_…`) that the detach endpoint takes.
/// The list endpoint hands back both; a freshly uploaded asset only has the
/// former until the task is saved and re-read.
class TaskAttachment extends Equatable {
  const TaskAttachment({
    required this.assetCode,
    this.code = '',
    this.fileName = '',
    this.contentType = '',
    this.sizeBytes = 0,
    this.mediaType = '',
    this.status = '',
    this.url = '',
    this.thumbnailUrl = '',
  });

  /// events-todo attachment row code — the key `DELETE /tasks/{code}/
  /// attachments/{attachmentCode}` expects. Empty when this attachment was
  /// built from an upload that hasn't been persisted onto a task yet.
  final String code;

  /// document-microservice asset code (`AST_…`).
  final String assetCode;

  final String fileName;
  final String contentType;
  final int sizeBytes;

  /// `IMAGE` / `VIDEO` / `DOCUMENT` as classified by document-microservice.
  /// Absent on some payloads, so the [isImage]/[isVideo] getters fall back to
  /// [contentType] and finally to the [fileName] extension.
  final String mediaType;

  /// `UPLOADED` / `READY` / `FAILED` — only `READY` assets have a usable [url].
  final String status;

  /// Resolved delivery URL. Frequently empty on the list payload, in which case
  /// the UI resolves it lazily by [assetCode] through
  /// `AssetService.getMediaAssetUrlByCode`.
  final String url;
  final String thumbnailUrl;

  String get _extension {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }

  bool get isImage {
    if (mediaType.toUpperCase() == 'IMAGE') return true;
    if (contentType.toLowerCase().startsWith('image/')) return true;
    return const {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'heic', 'heif'}
        .contains(_extension);
  }

  bool get isVideo {
    if (mediaType.toUpperCase() == 'VIDEO') return true;
    if (contentType.toLowerCase().startsWith('video/')) return true;
    return const {'mp4', 'mov', 'webm'}.contains(_extension);
  }

  /// Anything that isn't previewable in-app — opened through the OS instead.
  bool get isDocument => !isImage && !isVideo;

  /// Whether the payload said anything at all about what kind of file this is.
  ///
  /// False for an attachment built from a task's `assetCodes`, which carries a
  /// code and nothing else. [isImage]/[isVideo] are then both false purely for
  /// lack of evidence — not because it's a document — so callers must resolve
  /// the delivery URL and re-classify through [withResolvedUrl] before deciding
  /// how to preview it.
  bool get hasKnownType =>
      mediaType.trim().isNotEmpty ||
      contentType.trim().isNotEmpty ||
      _extension.isNotEmpty;

  /// This attachment with [resolvedUrl] attached, inferring [contentType] from
  /// the URL's file extension when the type was unknown — which is what makes an
  /// `assetCodes`-only image preview as an image instead of falling through to a
  /// document tile. An opaque URL leaves the type unknown, and the document
  /// fallback still applies.
  TaskAttachment withResolvedUrl(String resolvedUrl) {
    final trimmed = resolvedUrl.trim();
    if (trimmed.isEmpty) return this;
    if (hasKnownType) return copyWith(url: trimmed);
    return copyWith(
      url: trimmed,
      contentType: _contentTypeFromUrl(trimmed),
    );
  }

  /// Best-effort MIME type from a URL path's extension, limited to the types
  /// tasks actually accept plus the video kinds the viewer can play. Empty when
  /// the URL carries no recognizable extension (pre-signed links often don't).
  static String _contentTypeFromUrl(String url) {
    final path = (Uri.tryParse(url)?.path ?? '').toLowerCase();
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '';
    switch (path.substring(dot + 1)) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      case 'pdf':
        return 'application/pdf';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      default:
        return '';
    }
  }

  /// Whether this attachment is worth trying to show.
  ///
  /// `UPLOADED` counts, not just `READY`: document-microservice parks task
  /// attachments at `UPLOADED` and they serve a delivery URL perfectly well
  /// there, so treating that as "still processing" hides attachments that are
  /// actually fine. Blank counts too — several payloads omit the field. Only an
  /// explicit non-uploaded state (e.g. `FAILED`, `PENDING`) is withheld.
  bool get isReady {
    final normalized = status.trim().toUpperCase();
    return normalized.isEmpty ||
        normalized == 'READY' ||
        normalized == 'UPLOADED';
  }

  /// Human-readable size for the subtitle line; empty when the payload omits
  /// it.
  String get displaySize =>
      sizeBytes <= 0 ? '' : FilePickerUtils.formatBytes(sizeBytes);

  /// Round-trip form for the local display cache (see
  /// `StorageKeys.taskAttachmentsCache`). Deliberately does **not** persist
  /// [url]/[thumbnailUrl]: delivery URLs are short-lived pre-signed links, so a
  /// stale one would render a broken image. [assetCode] survives instead, and
  /// the thumbnail re-resolves it on demand.
  Map<String, dynamic> toCacheJson() => <String, dynamic>{
        'code': code,
        'assetCode': assetCode,
        'fileName': fileName,
        'contentType': contentType,
        'sizeBytes': sizeBytes,
        'mediaType': mediaType,
      };

  static TaskAttachment? fromCacheJson(Object? raw) {
    if (raw is! Map) return null;
    final assetCode = (raw['assetCode'] ?? '').toString().trim();
    if (assetCode.isEmpty) return null;
    final size = raw['sizeBytes'];
    return TaskAttachment(
      assetCode: assetCode,
      code: (raw['code'] ?? '').toString().trim(),
      fileName: (raw['fileName'] ?? '').toString().trim(),
      contentType: (raw['contentType'] ?? '').toString().trim(),
      sizeBytes: size is int ? size : int.tryParse('$size') ?? 0,
      mediaType: (raw['mediaType'] ?? '').toString().trim(),
    );
  }

  TaskAttachment copyWith({
    String? code,
    String? assetCode,
    String? fileName,
    String? contentType,
    int? sizeBytes,
    String? mediaType,
    String? status,
    String? url,
    String? thumbnailUrl,
  }) {
    return TaskAttachment(
      code: code ?? this.code,
      assetCode: assetCode ?? this.assetCode,
      fileName: fileName ?? this.fileName,
      contentType: contentType ?? this.contentType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      mediaType: mediaType ?? this.mediaType,
      status: status ?? this.status,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  @override
  List<Object?> get props => [
        code,
        assetCode,
        fileName,
        contentType,
        sizeBytes,
        mediaType,
        status,
        url,
        thumbnailUrl,
      ];
}

// SUPERSEDED by `PickedFile` (lib/core/util/file_picker_utils.dart), which the
// shared picker service already returns and the upload manager already consumes.
// Identical fields under different names (filePath/fileName/contentType vs
// path/name/mimeType) plus `mediaType`, `readableSize` and dedupe-by-path.
//
// /// A locally picked file waiting to be uploaded. Held by the form (never
// /// uploaded on pick) so abandoning a form leaves nothing in the bucket.
// class PendingTaskAttachment extends Equatable {
//   const PendingTaskAttachment({
//     required this.filePath,
//     required this.fileName,
//     required this.contentType,
//     required this.sizeBytes,
//   });
//
//   final String filePath;
//   final String fileName;
//   final String contentType;
//   final int sizeBytes;
//
//   bool get isImage => contentType.toLowerCase().startsWith('image/');
//   bool get isVideo => contentType.toLowerCase().startsWith('video/');
//
//   String get displaySize => formatAttachmentSize(sizeBytes);
//
//   @override
//   List<Object?> get props => [filePath, fileName, contentType, sizeBytes];
// }
