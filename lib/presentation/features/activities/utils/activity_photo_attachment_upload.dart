import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// Holds upload session asset codes keyed by local file path (one coordinator per screen).
class ActivityPhotoAttachmentState {
  final Map<String, String> assetCodeByPath = {};
  String? lastContextKey;

  void onSelectedFilesChanged(List<File> current) {
    assetCodeByPath.removeWhere(
      (path, _) => !current.any((f) => f.path == path),
    );
  }

  int uploadedCount(List<File> files) =>
      files.where((f) => assetCodeByPath.containsKey(f.path)).length;
}

/// Presign → PUT → complete → poll, then build attachment rows for activity creation.
/// [bindingMode] must match the activity type (`PER_STUDENT` or `SHARED`).
Future<List<Map<String, dynamic>>> uploadActivityPhotoAttachments({
  required ImageUploadService uploadService,
  required ActivityPhotoAttachmentState state,
  required List<File> files,
  required String classroomCode,
  required String activityTypeCode,
  required String organizationCode,
  required String schoolCode,
  required List<String> studentCodes,
  required String bindingMode,
  required void Function(VoidCallback) setState,
  required bool Function() mounted,
  required void Function(bool uploading) setUploading,
  void Function(int percent)? onOverallProgressPercent,
}) async {
  if (files.isEmpty) return const [];

  final normalizedStudentCodes = studentCodes
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList()
    ..sort();
  final uploadContextKey = [
    organizationCode.trim(),
    schoolCode.trim(),
    classroomCode.trim(),
    normalizedStudentCodes.join(','),
    activityTypeCode.trim(),
    bindingMode,
  ].join('|');

  if (state.lastContextKey != uploadContextKey) {
    state.assetCodeByPath.clear();
    state.lastContextKey = uploadContextKey;
  }

  final isShared = bindingMode.trim().toUpperCase() == 'SHARED';
  final ownerType = isShared ? 'CLASSROOM' : 'STUDENT';
  final ownerCode = isShared ? classroomCode.trim() : studentCodes.first;
  final missing =
      files.where((f) => !state.assetCodeByPath.containsKey(f.path)).toList();

  if (missing.isNotEmpty) {
    setState(() => setUploading(true));
    try {
      onOverallProgressPercent?.call(0);
      final uploadSession = await uploadService.createActivityUploadSession(
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        classroomCode: classroomCode,
        activityTypeCode: activityTypeCode,
        bindingMode: bindingMode,
        studentCodes: studentCodes,
      );

      final sessionAssetCodes = <String>[];
      for (var i = 0; i < missing.length; i++) {
        final photo = missing[i];
        final fileIndex = i + 1;
        final totalFiles = missing.length;
        final fileName = photo.uri.pathSegments.isNotEmpty
            ? photo.uri.pathSegments.last
            : 'photo.jpg';
        final contentLengthBytes = await photo.length();
        final checksumSha256 =
            await uploadService.computeFileChecksumSha256(photo);
        final presign = await uploadService.createAssetPresign(
          sessionCode: uploadSession.sessionCode,
          documentApiBasePath: uploadSession.documentApiBasePath,
          fileName: fileName,
          contentType: 'image/jpeg',
          contentLengthBytes: contentLengthBytes,
          checksumSha256: checksumSha256,
          mediaType: 'IMAGE',
          ownerType: ownerType,
          ownerCode: ownerCode,
        );
        await uploadService.uploadFileToPresignedUrl(
          file: photo,
          presignedPutUrl: presign.presignedPutUrl,
          requiredHeaders: presign.requiredHeaders,
          fallbackContentType: 'image/jpeg',
          onProgress: (_, __, percent) {
            final overallFraction =
                ((fileIndex - 1) + (percent / 100)) / totalFiles;
            final overallPercent =
                (overallFraction * 100).clamp(0, 100).round();
            final displayPercent =
                overallPercent >= 100 ? 99 : overallPercent;
            if (mounted()) {
              setState(() => onOverallProgressPercent?.call(displayPercent));
            }
          },
        );
        await uploadService.completeAssetUpload(
          sessionCode: uploadSession.sessionCode,
          assetCode: presign.assetCode,
          documentApiBasePath: uploadSession.documentApiBasePath,
        );
        state.assetCodeByPath[photo.path] = presign.assetCode;
        sessionAssetCodes.add(presign.assetCode);
      }
      await uploadService.waitUntilAssetsReady(
        sessionCode: uploadSession.sessionCode,
        expectedAssetCodes: sessionAssetCodes,
      );
      onOverallProgressPercent?.call(100);
    } finally {
      if (mounted()) {
        setState(() => setUploading(false));
      }
    }
  }

  final attachments = <Map<String, dynamic>>[];
  for (final photo in files) {
    final assetCode = state.assetCodeByPath[photo.path];
    if (assetCode != null && assetCode.isNotEmpty) {
      if (isShared) {
        attachments.add({'assetCode': assetCode});
      } else {
        attachments.add({
          'assetCode': assetCode,
          'studentCode': ownerCode,
          'bindingMode': bindingMode,
        });
      }
    }
  }
  return attachments;
}
