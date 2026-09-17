import 'package:equatable/equatable.dart';
import 'package:wowcare/core/utils/file_picker_utils.dart';

/// Why an asset could not be shown. Kept distinct from "not resolved yet" so the
/// UI can say something true instead of spinning forever.
enum AttachmentAssetFailure {
  /// The document service has no such asset (404), or it was detached.
  notFound,

  /// The asset exists but has no delivery URL yet — still finalizing.
  notReady,

  /// Network/permission/parse problem. Retryable.
  error,
}

/// One resolved attachment: where to fetch it and enough metadata to render it
/// without a second request.
///
/// This is the read-side counterpart to [PickedFile]: the picker produces
/// [PickedFile] going up, [AttachmentAssetService] produces this coming back.
class AttachmentAsset extends Equatable {
  const AttachmentAsset({
    required this.assetCode,
    this.url = '',
    this.fileName = '',
    this.contentType = '',
    this.mediaType = '',
    this.sizeBytes = 0,
    this.status = '',
    this.failure,
    this.failureMessage = '',
    this.resolvedAt,
  });

  /// A failed resolution, carried as a value so callers never have to catch.
  factory AttachmentAsset.failed({
    required String assetCode,
    required AttachmentAssetFailure failure,
    String message = '',
    DateTime? resolvedAt,
  }) {
    return AttachmentAsset(
      assetCode: assetCode,
      failure: failure,
      failureMessage: message,
      resolvedAt: resolvedAt,
    );
  }

  final String assetCode;

  /// Delivery URL. Empty when the asset could not be resolved.
  ///
  /// Presigned and therefore short-lived — never persist it. The service's TTL
  /// exists precisely so a stale one is re-resolved rather than rendered as a
  /// broken image.
  final String url;

  final String fileName;
  final String contentType;

  /// `IMAGE` / `VIDEO` / `DOCUMENT` as classified by the document service.
  final String mediaType;
  final int sizeBytes;

  /// `UPLOADED` / `READY` / … as reported by the service.
  final String status;

  final AttachmentAssetFailure? failure;
  final String failureMessage;

  /// When this was resolved — the service compares it against its TTL.
  final DateTime? resolvedAt;

  bool get isReady => url.isNotEmpty && failure == null;
  bool get hasFailed => failure != null;

  /// Whether retrying could plausibly help. A missing asset will stay missing.
  bool get isRetryable => failure != AttachmentAssetFailure.notFound;

  String get _extension {
    final fromName = fileName.lastIndexOf('.');
    if (fromName >= 0 && fromName < fileName.length - 1) {
      return fileName.substring(fromName + 1).toLowerCase();
    }
    // Presigned URLs often carry the extension even when the payload omits a
    // file name.
    final path = (Uri.tryParse(url)?.path ?? '').toLowerCase();
    final fromUrl = path.lastIndexOf('.');
    if (fromUrl >= 0 && fromUrl < path.length - 1) {
      return path.substring(fromUrl + 1);
    }
    return '';
  }

  String get extension => _extension;

  bool get isImage {
    if (mediaType == 'IMAGE') return true;
    if (contentType.startsWith('image/')) return true;
    return const {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'heic', 'heif'}
        .contains(_extension);
  }

  bool get isVideo {
    if (mediaType == 'VIDEO') return true;
    if (contentType.startsWith('video/')) return true;
    return const {'mp4', 'mov', 'webm'}.contains(_extension);
  }

  bool get isPdf =>
      contentType == 'application/pdf' || _extension == 'pdf';

  bool get isDocument => !isImage && !isVideo;

  /// Never empty — falls back to the code so a row always has a label.
  String get displayName => fileName.trim().isEmpty ? assetCode : fileName;

  /// Empty when the payload omitted the size, so callers can hide the line.
  String get displaySize =>
      sizeBytes <= 0 ? '' : FilePickerUtils.formatBytes(sizeBytes);

  /// `JPG · 78 KB`, or just one half when the other is unknown.
  String get displaySubtitle {
    final type = _extension.toUpperCase();
    final size = displaySize;
    if (type.isEmpty) return size;
    if (size.isEmpty) return type;
    return '$type · $size';
  }

  /// A short, user-facing reason. Deliberately plain — the raw server message
  /// is kept in [failureMessage] for logs.
  String get failureLabel {
    switch (failure) {
      case AttachmentAssetFailure.notFound:
        return 'This file is no longer available';
      case AttachmentAssetFailure.notReady:
        return 'Still processing — try again in a moment';
      case AttachmentAssetFailure.error:
        return "Couldn't load this file";
      case null:
        return '';
    }
  }

  AttachmentAsset copyWith({
    String? url,
    String? fileName,
    String? contentType,
    String? mediaType,
    int? sizeBytes,
    String? status,
    DateTime? resolvedAt,
  }) {
    return AttachmentAsset(
      assetCode: assetCode,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      contentType: contentType ?? this.contentType,
      mediaType: mediaType ?? this.mediaType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      status: status ?? this.status,
      failure: failure,
      failureMessage: failureMessage,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  @override
  List<Object?> get props => [
        assetCode,
        url,
        fileName,
        contentType,
        mediaType,
        sizeBytes,
        status,
        failure,
        failureMessage,
      ];
}
