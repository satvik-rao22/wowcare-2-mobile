import 'dart:io';

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/services/image_upload/profile_photo_upload_events.dart';
import 'package:wowcare/shared/services/image_upload/profile_photo_uploader.dart';

/// Fire-and-forget staff profile-photo upload, detached from any widget
/// lifecycle (top-level, never touches a BuildContext) so it finishes even
/// after the form is popped/refreshed. On success it clears the cached
/// profile-photo URL so the staff list/profile avatar re-resolves the new photo.
Future<void> uploadStaffPhotoInBackground({
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
    await serviceLocator<ProfilePhotoUploader>().uploadStaffPhoto(
      staffCode: code,
      file: file,
      schoolCode: schoolCode.trim(),
      organizationCode: organizationCode.trim(),
    );
    DocumentImageWidget.clearProfilePhotoCache(staffCode: code);
    ProfilePhotoUploadEvents.notifyStaffUploaded();
    AppLogger.d('[photo] staff $code photo uploaded (bg)');
  } catch (e) {
    AppLogger.d('[photo] staff background upload failed: $e');
  }
}
