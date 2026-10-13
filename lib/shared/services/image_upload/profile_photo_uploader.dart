import 'dart:io';

import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/core/utils/file_utils/file_utils.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_models.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// A finished profile-photo upload: the new asset and its finalized URL.
typedef UploadedProfilePhoto = ({String assetCode, String url});

/// The one way the app uploads a staff, student or guardian profile photo:
/// create the session → upload (ImageUploadService.uploadToSession) →
/// finalize. Used by the profile screens and the add/edit forms alike.
///
/// Call it after the person exists (so their `code` does). [onPercent]
/// reports progress for a ring or bar: 5 → 15 once the session is open,
/// 25–80 while the bytes upload, 100 when the server has the photo.
class ProfilePhotoUploader {
  ProfilePhotoUploader(this._service);

  final ImageUploadService _service;

  Future<UploadedProfilePhoto> uploadStudentPhoto({
    required String studentCode,
    required File file,
    required String schoolCode,
    required String organizationCode,
    void Function(int percent)? onPercent,
  }) async {
    onPercent?.call(5);
    final sessionCode = await _service.createStudentProfilePhotoUploadSession(
      studentCode: studentCode,
      schoolCode: schoolCode,
      organizationCode: organizationCode,
    );
    final assetCode = await _upload(
      sessionCode: sessionCode,
      file: file,
      owner: AssetOwner.student(studentCode),
      namePrefix: 'student-profile-photo',
      onPercent: onPercent,
    );
    final url = await _service.finalizeStudentProfilePhoto(
      studentCode: studentCode,
      sessionCode: sessionCode,
      assetCode: assetCode,
      schoolCode: schoolCode,
    );
    return (assetCode: assetCode, url: url);
  }

  Future<UploadedProfilePhoto> uploadStaffPhoto({
    required String staffCode,
    required File file,
    required String schoolCode,
    required String organizationCode,
    void Function(int percent)? onPercent,
  }) async {
    onPercent?.call(5);
    final sessionCode = await _service.createStaffProfilePhotoUploadSession(
      staffCode: staffCode,
      schoolCode: schoolCode,
      organizationCode: organizationCode,
    );
    final assetCode = await _upload(
      sessionCode: sessionCode,
      file: file,
      owner: AssetOwner.staff(staffCode),
      namePrefix: 'staff-profile-photo',
      onPercent: onPercent,
    );
    final url = await _service.finalizeStaffProfilePhoto(
      staffCode: staffCode,
      assetCode: assetCode,
    );
    return (assetCode: assetCode, url: url);
  }

  Future<UploadedProfilePhoto> uploadGuardianPhoto({
    required String guardianCode,
    required File file,
    required String schoolCode,
    required String organizationCode,
    required String userCode,
    void Function(int percent)? onPercent,
  }) async {
    onPercent?.call(5);
    final sessionCode = await _service.createGuardianProfilePhotoUploadSession(
      guardianCode: guardianCode,
      schoolCode: schoolCode,
      organizationCode: organizationCode,
    );
    final assetCode = await _upload(
      sessionCode: sessionCode,
      file: file,
      owner: AssetOwner.guardian(guardianCode),
      namePrefix: 'guardian-profile-photo',
      onPercent: onPercent,
    );
    final url = await _service.finalizeGuardianProfilePhoto(
      guardianCode: guardianCode,
      assetCode: assetCode,
      schoolCode: schoolCode,
      userCode: userCode,
    );
    return (assetCode: assetCode, url: url);
  }

  /// The steps shared by every owner, once the session is open. Profile-photo
  /// sessions return only a code; their base path is the default /api/v1.
  Future<String> _upload({
    required String sessionCode,
    required File file,
    required AssetOwner owner,
    required String namePrefix,
    void Function(int percent)? onPercent,
  }) async {
    onPercent?.call(15);
    final name = FileUtils.fileName(file.path).toLowerCase();
    final asset = await _service.uploadToSession(
      session: UploadSessionResult(
        sessionCode: sessionCode,
        documentApiBasePath: '/api/v1',
      ),
      file: file,
      owner: owner,
      fileName: name.isNotEmpty
          ? name
          : '$namePrefix-${AppTime.nowUtc().millisecondsSinceEpoch}.jpg',
      // Every allowed image format (png/webp/heic/gif/bmp/tiff/…) uploads
      // with its real type, not a hard-coded jpeg.
      contentType: await FileUtils.imageMimeTypeOfFile(file.path),
      onUploadProgress: (percent) =>
          onPercent?.call(25 + (percent * 0.55).round()),
    );
    onPercent?.call(100);
    return asset.assetCode;
  }
}
