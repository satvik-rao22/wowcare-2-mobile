import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:wowcare/core/util/file_picker_utils.dart';
import 'package:wowcare/domain/features/activity/entities/activity_attachment.dart';
import 'package:wowcare/domain/features/activity/repositories/activity_media_upload_repository.dart';
import 'package:wowcare/domain/features/activity/usecases/upload_activity_assets_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/wait_activity_assets_ready_usecase.dart';

import '../../../../app/di/di.dart';

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

      final items = <ActivityUploadItem>[];
      for (final photo in missing) {
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
        items.add(
          ActivityUploadItem(
            file: photo,
            fileName: fileName,
            contentType: contentType,
            mediaType: 'IMAGE',
          ),
        );
      }

      final result = await serviceLocator<UploadActivityAssetsUseCase>().call(
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        classroomCode: classroomCode,
        activityTypeCode: activityTypeCode,
        bindingMode: bindingMode,
        studentCodes: studentCodes,
        ownerType: ownerType,
        ownerCode: ownerCode,
        items: items,
        onItemProgress: (itemIndex, totalItems, percent) {
          final overallFraction =
              ((itemIndex - 1) + (percent / 100)) / totalItems;
          final overallPercent =
              (overallFraction * 100).clamp(0, 100).round();
          if (mounted()) {
            setState(() => onOverallProgressPercent?.call(overallPercent));
          }
        },
        onItemComplete: (completed, total) {
          if (mounted()) {
            setState(() => onFileCompleted?.call(completed, total));
          }
        },
        cancelToken: cancelToken,
      );

      // Only mark a photo "done" (eligible for Save/attach) once the blocking
      // ready-poll confirms it — completing the S3 PUT/complete call is not the
      // same as the backend reporting the asset ready to link. Writing into
      // state.assetCodeByPath before this (i.e. inside the upload) let a
      // subsequent ready-poll timeout pass through silently: the map already
      // held the assetCode, so the caller believed upload had finished and let
      // Save submit an asset the backend then rejected with 409 "not ready for
      // linking". Hence the wait precedes the addAll below.
      await serviceLocator<WaitActivityAssetsReadyUseCase>().call(
        sessionCode: result.sessionCode,
        assetCodes: result.newAssetCodes,
      );
      state.assetCodeByPath.addAll(result.assetCodeByPath);
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
