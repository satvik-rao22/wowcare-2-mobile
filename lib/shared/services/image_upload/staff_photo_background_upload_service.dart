import 'dart:io';

import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/services/image_upload/profile_photo_upload_events.dart';
import 'package:wowcare/shared/services/image_upload/profile_photo_uploader.dart';

/// Fire-and-forget staff profile-photo upload.
///
/// Deliberately detached from any widget or cubit lifecycle: the add-staff and
/// edit-profile forms pop as soon as the save returns, and the photo upload has
/// to survive that. Because the service is a singleton and the work is started
/// from here rather than from the caller's `State`, closing the calling cubit
/// cannot orphan it.
///
/// On success it clears the cached profile-photo URL so the staff list/profile
/// avatar re-resolves the new photo.
class StaffPhotoBackgroundUploadService {
  const StaffPhotoBackgroundUploadService(this._uploader);

  final ProfilePhotoUploader _uploader;

  Future<void> upload({
    required String staffCode,
    required File file,
    required String schoolCode,
    required String organizationCode,
  }) async {
    final code = staffCode.trim();
    if (code.isEmpty || schoolCode.trim().isEmpty) {
      AppLogger.d('[photo] staff upload skipped — no staff code');
      return;
    }
    try {
      await _uploader.uploadStaffPhoto(
        staffCode: code,
        file: file,
        schoolCode: schoolCode.trim(),
        organizationCode: organizationCode.trim(),
      );
      DocumentImageWidget.clearProfilePhotoCache(staffCode: code);
      DocumentImageWidget.markStaffPhotoUploaded(code);
      ProfilePhotoUploadEvents.notifyStaffUploaded();
      AppLogger.d('[photo] staff $code photo uploaded (bg)');
    } catch (e) {
      AppLogger.d('[photo] staff background upload failed: $e');
    }
  }
}
