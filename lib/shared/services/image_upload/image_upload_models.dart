class UploadSessionResult {
  const UploadSessionResult({
    required this.sessionCode,
    required this.documentApiBasePath,
  });

  final String sessionCode;
  final String documentApiBasePath;
}

/// One file's worth of input to the presign endpoint.
///
/// The endpoint is `.../assets/presign/batch` and takes an array, so several of
/// these are signed in a single round trip.
class AssetPresignRequest {
  const AssetPresignRequest({
    required this.fileName,
    required this.contentType,
    required this.contentLengthBytes,
    required this.mediaType,
    required this.ownerType,
    required this.ownerCode,
    this.checksumSha256,
  });

  final String fileName;
  final String contentType;
  final int contentLengthBytes;

  /// `IMAGE` / `VIDEO` / `DOCUMENT`.
  final String mediaType;
  final String ownerType;
  final String ownerCode;
  final String? checksumSha256;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'fileName': fileName,
        'contentType': contentType,
        'contentLengthBytes': contentLengthBytes,
        if ((checksumSha256 ?? '').trim().isNotEmpty)
          'checksumSha256': checksumSha256!.trim(),
        'mediaType': mediaType,
        'ownerType': ownerType,
        'ownerCode': ownerCode,
      };
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

