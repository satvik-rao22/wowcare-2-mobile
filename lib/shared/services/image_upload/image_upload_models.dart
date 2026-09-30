class UploadSessionResult {
  const UploadSessionResult({
    required this.sessionCode,
    required this.documentApiBasePath,
    this.ownerType,
    this.ownerCode,
  });

  final String sessionCode;
  final String documentApiBasePath;

  /// Owner scope the document service authorized this session under (e.g.
  /// `SCHOOL`), returned by session-creation endpoints whose caller doesn't
  /// already know a fixed owner (unlike student/staff document uploads,
  /// where the owner is the student/staff code the caller passed in).
  final String? ownerType;
  final String? ownerCode;
}

/// One file's worth of request fields for [ImageUploadService.createAssetPresignBatch].
class AssetPresignRequest {
  const AssetPresignRequest({
    required this.fileName,
    required this.contentType,
    required this.contentLengthBytes,
    this.checksumSha256,
    required this.mediaType,
    required this.ownerType,
    required this.ownerCode,
  });

  final String fileName;
  final String contentType;
  final int contentLengthBytes;
  final String? checksumSha256;
  final String mediaType;
  final String ownerType;
  final String ownerCode;
}

class AssetPresignResult {
  const AssetPresignResult({
    required this.assetCode,
    required this.presignedPutUrl,
    required this.requiredHeaders,
  });

  final String assetCode;
  final String presignedPutUrl;
  final Map<String, String> requiredHeaders;
}

/// What `POST .../assets/{assetCode}/complete` hands back.
///
/// The endpoint already returns the asset's status and full metadata, so the
/// client does not need to re-fetch the session to learn them. `UPLOADED` is a
/// usable terminal state — some domains (EVENT) never promote past it, so
/// treating only `READY` as success hangs forever.
class AssetCompleteResult {
  const AssetCompleteResult({
    required this.assetCode,
    required this.status,
    this.fileName = '',
    this.contentType = '',
    this.mediaType = '',
    this.sizeBytes = 0,
    this.supportsAutoQuality = false,
  });

  factory AssetCompleteResult.fromJson(Map<String, dynamic> json) {
    return AssetCompleteResult(
      assetCode: (json['assetCode'] ?? '').toString().trim(),
      status: (json['status'] ?? '').toString().trim().toUpperCase(),
      fileName: (json['fileName'] ?? '').toString(),
      contentType: (json['contentType'] ?? '').toString(),
      mediaType: (json['mediaType'] ?? '').toString().toUpperCase(),
      sizeBytes: json['sizeBytes'] is num
          ? (json['sizeBytes'] as num).toInt()
          : int.tryParse((json['sizeBytes'] ?? '').toString()) ?? 0,
      supportsAutoQuality: json['supportsAutoQuality'] == true,
    );
  }

  final String assetCode;

  /// `UPLOADED`, `READY`, `FAILED`, … upper-cased. Empty when the response
  /// omitted it.
  final String status;
  final String fileName;
  final String contentType;
  final String mediaType;
  final int sizeBytes;

  /// Whether the service will generate derivatives for this asset. False means
  /// there is nothing to process, so the asset will not change state again.
  final bool supportsAutoQuality;

  /// Whether the asset can be attached now.
  ///
  /// An empty status is treated as attachable: older responses omitted it, and
  /// a successful `complete` is itself the confirmation the bytes landed.
  bool get isAttachable =>
      status.isEmpty || status == 'UPLOADED' || status == 'READY';

  bool get isFailed => status == 'FAILED';
}

