import 'dart:io';

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/services/image_upload/profile_photo_upload_events.dart';
import 'package:wowcare/shared/services/image_upload/profile_photo_uploader.dart';

/// Fire-and-forget profile-photo uploads, detached from any widget lifecycle.
///
/// These are top-level functions (not State methods) so they keep running — and
/// finish — even after the originating screen is popped or refreshed. They never
/// touch a BuildContext. On success they clear the cached profile-photo URL so
/// the next render of any avatar for that owner re-resolves and shows the new
/// photo (the entity list/profile caches are invalidated by the create/update
/// calls themselves).

Future<void> uploadStudentPhotoInBackground({
  required String studentCode,
  required File file,
  required String schoolCode,
  required String organizationCode,
}) async {
  final code = studentCode.trim();
  if (code.isEmpty || schoolCode.trim().isEmpty) return;
  try {
    await serviceLocator<ProfilePhotoUploader>().uploadStudentPhoto(
      studentCode: code,
      file: file,
      schoolCode: schoolCode.trim(),
      organizationCode: organizationCode.trim(),
    );
    DocumentImageWidget.clearProfilePhotoCache(studentCode: code);
    ProfilePhotoUploadEvents.notifyStudentUploaded();
    AppLogger.d('[photo] student $code photo uploaded (bg)');
  } catch (e) {
    AppLogger.d('[photo] student background upload failed: $e');
  }
}

/// Uploads a guardian photo. If [guardianCode] is empty (the create response
/// didn't echo it), resolves the code from the student's guardian list by
/// matching [email], then [mobile].
Future<void> uploadGuardianPhotoInBackground({
  required File file,
  required String guardianCode,
  required String studentCode,
  required String email,
  required String mobile,
  required String schoolCode,
  required String organizationCode,
  required String userCode,
}) async {
  try {
    var code = guardianCode.trim();
    if (code.isEmpty && studentCode.trim().isNotEmpty) {
      final repo = serviceLocator<StudentRepository>();
      final guardians = await repo.getStudentGuardians(
        studentCode: studentCode.trim(),
      );
      final wantEmail = email.trim().toLowerCase();
      final wantMobile = mobile.replaceAll(RegExp(r'\D'), '');
      for (final g in guardians) {
        if (wantEmail.isNotEmpty && g.email.trim().toLowerCase() == wantEmail) {
          code = g.guardianCode.trim();
          break;
        }
      }
      if (code.isEmpty) {
        for (final g in guardians) {
          if (wantMobile.isNotEmpty &&
              g.mobile.replaceAll(RegExp(r'\D'), '') == wantMobile) {
            code = g.guardianCode.trim();
            break;
          }
        }
      }
    }
    if (code.isEmpty || schoolCode.trim().isEmpty) {
      AppLogger.d('[photo] guardian upload skipped — no guardian code');
      return;
    }
    await serviceLocator<ProfilePhotoUploader>().uploadGuardianPhoto(
      guardianCode: code,
      file: file,
      schoolCode: schoolCode.trim(),
      organizationCode: organizationCode.trim(),
      userCode: userCode.trim(),
    );
    // Clear cached avatar URLs so the family/pickup cards re-resolve the photo.
    DocumentImageWidget.clearProfilePhotoCache();
    ProfilePhotoUploadEvents.notifyGuardianUploaded();
    // A guardian photo also affects the student's family view → nudge students.
    ProfilePhotoUploadEvents.notifyStudentUploaded();
    AppLogger.d('[photo] guardian $code photo uploaded (bg)');
  } catch (e) {
    AppLogger.d('[photo] guardian background upload failed: $e');
  }
}
