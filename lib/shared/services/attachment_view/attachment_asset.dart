import 'package:equatable/equatable.dart';
import 'package:wowcare/core/util/file_picker_utils.dart';

/// One resolved attachment: URLs plus enough metadata to render it.
///
/// Read-side counterpart to [PickedFile] — the picker produces [PickedFile] on
/// the way up, [AttachmentAssetService] produces this on the way back.
///
/// Built straight from `POST /media-assets/resolve`. Note which URL is which:
/// [thumbnailUrl] and [deliveryUrl] are unsigned CloudFront links and so are
/// safe to hold for the life of the app, while [downloadUrl] is a presigned S3
/// link that expires in minutes and must be re-resolved rather than stored.
class AttachmentAsset extends Equatable {
  const AttachmentAsset({
    required this.assetCode,
    this.fileName = '',
    this.contentType = '',
    this.mediaType = '',
    this.sizeBytes = 0,
    this.status = '',
    this.thumbnailUrl = '',
    this.deliveryUrl = '',
    this.downloadUrl = '',
    this.width = 0,
    this.height = 0,
    this.isMissing = false,
  });

  /// The asset code came back under `missingAssetCodes`, or the request failed.
  factory AttachmentAsset.missing(String assetCode) =>
      AttachmentAsset(assetCode: assetCode, isMissing: true);

  factory AttachmentAsset.fromJson(Map<dynamic, dynamic> json) {
    // Primary variant carries the pixel dimensions, which let a preview reserve
    // the right aspect ratio instead of jumping once the image decodes.
    var width = 0;
    var height = 0;
    final variants = json['variants'];
    if (variants is List) {
      for (final row in variants.whereType<Map>()) {
        final isDefault =
            (row['defaultVariant'] ?? false).toString().toLowerCase() == 'true';
        if (!isDefault) continue;
        width = _int(row['width']);
        height = _int(row['height']);
        break;
      }
    }

    return AttachmentAsset(
      assetCode: (json['assetCode'] ?? '').toString().trim(),
      fileName: (json['fileName'] ?? '').toString().trim(),
      contentType: (json['contentType'] ?? '').toString().trim().toLowerCase(),
      mediaType: (json['mediaType'] ?? '').toString().trim().toUpperCase(),
      sizeBytes: _int(json['sizeBytes']),
      status: (json['status'] ?? '').toString().trim().toUpperCase(),
      thumbnailUrl: (json['thumbnailUrl'] ?? '').toString().trim(),
      deliveryUrl: (json['deliveryUrl'] ?? '').toString().trim(),
      downloadUrl: (json['downloadUrl'] ?? '').toString().trim(),
      width: width,
      height: height,
    );
  }

  final String assetCode;
  final String fileName;
  final String contentType;

  /// `IMAGE` / `VIDEO` / `DOCUMENT`.
  final String mediaType;
  final int sizeBytes;

  /// `READY` / `PROCESSING` / `UPLOADED` / `FAILED`.
  final String status;

  /// 256px webp — a few KB. What lists and small tiles should load.
  final String thumbnailUrl;

  /// Full-size processed artifact. What the viewer loads.
  final String deliveryUrl;

  /// Presigned S3 link for handing the original to another app. Expires in
  /// ~15 minutes, so re-resolve rather than reuse a stored copy.
  final String downloadUrl;

  final int width;
  final int height;

  final bool isMissing;

  /// Whether there is something to show. `PROCESSING` assets have no URLs yet.
  bool get isReady => !isMissing && deliveryUrl.isNotEmpty;

  bool get isProcessing => !isMissing && !isReady && status != 'FAILED';

  /// Best URL for a small tile — the thumbnail when the service made one.
  String get previewUrl =>
      thumbnailUrl.isNotEmpty ? thumbnailUrl : deliveryUrl;

  /// Best URL for a full-screen view.
  String get fullUrl => deliveryUrl.isNotEmpty ? deliveryUrl : thumbnailUrl;

  double? get aspectRatio =>
      (width > 0 && height > 0) ? width / height : null;

  String get extension {
    final dot = fileName.lastIndexOf('.');
    if (dot >= 0 && dot < fileName.length - 1) {
      return fileName.substring(dot + 1).toLowerCase();
    }
    // Fall back to the content type — the processed artifact is webp even when
    // the original was a jpg, so the file name is the better source.
    final slash = contentType.lastIndexOf('/');
    if (slash >= 0 && slash < contentType.length - 1) {
      return contentType.substring(slash + 1);
    }
    return '';
  }

  bool get isImage =>
      mediaType == 'IMAGE' || contentType.startsWith('image/');

  bool get isVideo =>
      mediaType == 'VIDEO' || contentType.startsWith('video/');

  bool get isPdf => contentType == 'application/pdf' || extension == 'pdf';

  bool get isDocument => !isImage && !isVideo;

  /// Never empty — falls back to the code so a row is always labelled.
  String get displayName => fileName.isEmpty ? assetCode : fileName;

  String get displaySize =>
      sizeBytes <= 0 ? '' : FilePickerUtils.formatBytes(sizeBytes);

  /// `JPG · 74 KB`, or whichever half is known.
  String get displaySubtitle {
    final parts = <String>[
      if (extension.isNotEmpty) extension.toUpperCase(),
      if (displaySize.isNotEmpty) displaySize,
    ];
    return parts.join(' · ');
  }

  /// Short, user-facing reason this cannot be shown. Empty when it can.
  String get unavailableLabel {
    if (isMissing) return 'This file is no longer available';
    if (status == 'FAILED') return "This file couldn't be processed";
    if (isProcessing) return 'Still processing — check back shortly';
    return '';
  }

  static int _int(Object? raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse((raw ?? '').toString()) ?? 0;
  }

  @override
  List<Object?> get props => [
        assetCode,
        fileName,
        contentType,
        mediaType,
        sizeBytes,
        status,
        thumbnailUrl,
        deliveryUrl,
        downloadUrl,
        width,
        height,
        isMissing,
      ];
}
