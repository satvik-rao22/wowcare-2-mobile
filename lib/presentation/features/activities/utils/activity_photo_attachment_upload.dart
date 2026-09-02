import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:wowcare/core/util/file_picker_utils.dart';
import 'package:wowcare/domain/features/activity/entities/activity_attachment.dart';
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
Future<List<ActivityAttachment>> uploadActivityPhotoAttachments({
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
  /// Fired with (completedCount, totalCount) after each file's upload+
  /// complete call, before the batched ready-poll — lets callers show
  /// granular "N/M uploaded" progress text alongside the overall percent.
  void Function(int completedCount, int totalCount)? onFileCompleted,
  CancelToken? cancelToken,
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
        cancelToken: cancelToken,
      );

      final sessionAssetCodes = <String>[];
      // Keyed separately from state.assetCodeByPath so a photo is only
      // considered "done" (and eligible for Save/attach) once
      // waitUntilAssetsReady below actually confirms it — completing the
      // S3 PUT/complete call is not the same as the backend reporting the
      // asset ready to link, and writing straight into
      // state.assetCodeByPath here let a subsequent ready-poll timeout pass
      // through silently: the map already held the assetCode, so the caller
      // believed upload had finished and let Save submit an asset the
      // backend then rejected with 409 "not ready for linking".
      final pendingAssetCodeByPath = <String, String>{};
      for (var i = 0; i < missing.length; i++) {
        final photo = missing[i];
        final fileIndex = i + 1;
        final totalFiles = missing.length;
        final fileName = photo.uri.pathSegments.isNotEmpty
            ? photo.uri.pathSegments.last
            : 'photo.jpg';
        // Declaring every picked photo as image/jpeg regardless of its real
        // format (HEIC/PNG/WEBP/etc. are all pickable) tells S3/the backend
        // the wrong content type for anything that isn't literally already a
        // JPEG — a plausible reason a HEIC upload sits stuck at PROCESSING
        // and never reaches READY, since the backend's decoder is told to
        // parse non-JPEG bytes as JPEG.
        final contentType =
            lookupMimeType(photo.path) ??
            FilePickerUtils.getMimeType(fileName.split('.').last);
        final contentLengthBytes = await photo.length();
        final checksumSha256 =
            await uploadService.computeFileChecksumSha256(photo);
        final presign = await uploadService.createAssetPresign(
          sessionCode: uploadSession.sessionCode,
          documentApiBasePath: uploadSession.documentApiBasePath,
          fileName: fileName,
          contentType: contentType,
          contentLengthBytes: contentLengthBytes,
          checksumSha256: checksumSha256,
          mediaType: 'IMAGE',
          ownerType: ownerType,
          ownerCode: ownerCode,
          cancelToken: cancelToken,
        );
        await uploadService.uploadFileToPresignedUrl(
          file: photo,
          presignedPutUrl: presign.presignedPutUrl,
          requiredHeaders: presign.requiredHeaders,
          fallbackContentType: contentType,
          onProgress: (_, __, percent) {
            final overallFraction =
                ((fileIndex - 1) + (percent / 100)) / totalFiles;
            final overallPercent =
                (overallFraction * 100).clamp(0, 100).round();
            if (mounted()) {
              setState(() => onOverallProgressPercent?.call(overallPercent));
            }
          },
          cancelToken: cancelToken,
        );
        await uploadService.completeAssetUpload(
          sessionCode: uploadSession.sessionCode,
          assetCode: presign.assetCode,
          documentApiBasePath: uploadSession.documentApiBasePath,
          cancelToken: cancelToken,
        );
        pendingAssetCodeByPath[photo.path] = presign.assetCode;
        sessionAssetCodes.add(presign.assetCode);
        if (mounted()) {
          setState(() => onFileCompleted?.call(fileIndex, totalFiles));
        }
      }
      await uploadService.waitUntilAssetsReady(
        sessionCode: uploadSession.sessionCode,
        expectedAssetCodes: sessionAssetCodes,
      );
      state.assetCodeByPath.addAll(pendingAssetCodeByPath);
      onOverallProgressPercent?.call(100);
    } finally {
      if (mounted()) {
        setState(() => setUploading(false));
      }
    }
  }

  final attachments = <ActivityAttachment>[];
  for (final photo in files) {
    final assetCode = state.assetCodeByPath[photo.path];
    if (assetCode != null && assetCode.isNotEmpty) {
      if (isShared) {
        attachments.add(ActivityAttachment(assetCode: assetCode));
      } else {
        attachments.add(
          ActivityAttachment(
            assetCode: assetCode,
            studentCode: ownerCode,
            bindingMode: bindingMode,
          ),
        );
      }
    }
  }
  return attachments;
}
