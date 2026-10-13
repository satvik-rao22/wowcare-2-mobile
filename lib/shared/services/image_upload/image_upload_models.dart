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

/// Who an uploaded asset belongs to, in the document service's terms. The
/// server's owner-type strings live here and nowhere else.
class AssetOwner {
  const AssetOwner._(this.type, this.code);

  const AssetOwner.staff(String staffCode) : this._('STAFF', staffCode);
  const AssetOwner.student(String studentCode) : this._('STUDENT', studentCode);
  const AssetOwner.guardian(String guardianCode)
    : this._('GUARDIAN', guardianCode);
  const AssetOwner.classroom(String classroomCode)
    : this._('CLASSROOM', classroomCode);
  const AssetOwner.school(String schoolCode) : this._('SCHOOL', schoolCode);

  /// `STAFF`, `STUDENT`, `GUARDIAN`, `CLASSROOM` or `SCHOOL`.
  final String type;
  final String code;
}

/// What [ImageUploadService.uploadToSession] hands back.
class UploadedAsset {
  const UploadedAsset({required this.assetCode});

  final String assetCode;
}
