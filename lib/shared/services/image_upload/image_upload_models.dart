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

