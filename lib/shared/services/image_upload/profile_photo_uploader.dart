import 'dart:io';

import 'package:wowcare/core/utils/file_utils/file_utils.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_models.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// One-call profile-photo upload for the add/edit forms.
///
/// Encapsulates the proven 6-step flow (create session → presign → PUT bytes →
/// complete → wait-ready → finalize) that was previously copy-pasted into
/// `student_profile_screen`, `staff_profile_screen` and `user_profile_cubit`.
/// Each method returns the finalized profile-photo URL.
///
/// The forms call this AFTER the entity is created/updated (so the entity
/// `code` exists). [onPercent] reports 0–100 for an optional progress UI.
class ProfilePhotoUploader {
  ProfilePhotoUploader(this._service);

  final ImageUploadService _service;

  Future<String> uploadStudentPhoto({
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
    final presign = await _presignAndUpload(
      sessionCode: sessionCode,
      file: file,
      ownerType: 'STUDENT',
      ownerCode: studentCode,
      namePrefix: 'student-profile-photo',
      onPercent: onPercent,
    );
    onPercent?.call(100);
    return _service.finalizeStudentProfilePhoto(
      studentCode: studentCode,
      sessionCode: sessionCode,
      assetCode: presign.assetCode,
      schoolCode: schoolCode,
    );
  }

  Future<String> uploadStaffPhoto({
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
    final presign = await _presignAndUpload(
      sessionCode: sessionCode,
      file: file,
      ownerType: 'STAFF',
      ownerCode: staffCode,
      namePrefix: 'staff-profile-photo',
      onPercent: onPercent,
    );
    onPercent?.call(100);
    return _service.finalizeStaffProfilePhoto(
      staffCode: staffCode,
      assetCode: presign.assetCode,
    );
  }

  Future<String> uploadGuardianPhoto({
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
    final presign = await _presignAndUpload(
      sessionCode: sessionCode,
      file: file,
      ownerType: 'GUARDIAN',
      ownerCode: guardianCode,
      namePrefix: 'guardian-profile-photo',
      onPercent: onPercent,
    );
    onPercent?.call(100);
    return _service.finalizeGuardianProfilePhoto(
      guardianCode: guardianCode,
      assetCode: presign.assetCode,
      schoolCode: schoolCode,
      userCode: userCode,
    );
  }

  /// Shared middle steps: presign → PUT bytes → complete → wait-ready.
  Future<AssetPresignResult> _presignAndUpload({
    required String sessionCode,
    required File file,
    required String ownerType,
    required String ownerCode,
    required String namePrefix,
    void Function(int percent)? onPercent,
  }) async {
    onPercent?.call(15);
    final lowerPath = file.path.toLowerCase();
    final rawName = lowerPath.split(Platform.pathSeparator).last;
    // Every allowed image format (png/webp/heic/gif/bmp/tiff/…) uploads with
    // its real MIME type, not a hard-coded jpeg.
    final contentType = await FileUtils.imageMimeTypeOfFile(file.path);
    final presign = await _service.createAssetPresign(
      sessionCode: sessionCode,
      documentApiBasePath: '/api/v1',
      fileName: rawName.isNotEmpty ? rawName : '$namePrefix.jpg',
      contentType: contentType,
      contentLengthBytes: await file.length(),
      mediaType: 'IMAGE',
      ownerType: ownerType,
      ownerCode: ownerCode,
    );
    onPercent?.call(25);
    await _service.uploadFileToPresignedUrl(
      file: file,
      presignedPutUrl: presign.presignedPutUrl,
      requiredHeaders: presign.requiredHeaders,
      fallbackContentType: contentType,
      onSendProgress: (int sent, int total) {
        if (total <= 0) return;
        final frac = (sent / total).clamp(0.0, 1.0);
        onPercent?.call(25 + (frac * 55).round());
      },
    );
    onPercent?.call(84);
    await _service.completeAssetUpload(
      sessionCode: sessionCode,
      assetCode: presign.assetCode,
      documentApiBasePath: '/api/v1',
    );
    onPercent?.call(90);
    await _service.waitUntilAssetsReady(
      sessionCode: sessionCode,
      expectedAssetCodes: <String>[presign.assetCode],
    );
    return presign;
  }
}
