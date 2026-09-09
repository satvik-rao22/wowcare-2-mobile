import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:wowcare/core/util/file_picker_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/domain/features/activity/entities/activity_attachment.dart';
import 'package:wowcare/domain/features/activity/repositories/activity_media_upload_repository.dart';
import 'package:wowcare/domain/features/activity/usecases/get_activity_upload_asset_statuses_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/upload_activity_assets_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/wait_activity_assets_ready_usecase.dart';

import '../../../../app/di/di.dart';

/// Holds upload session asset codes keyed by local file path (one coordinator per screen).
class ActivityPhotoAttachmentState {
  /// Files whose asset is uploaded AND confirmed READY — eligible for Save.
  final Map<String, String> assetCodeByPath = {};

  /// Files whose asset was uploaded+completed but whose batch then failed
  /// before the readiness poll ran. NOT eligible for Save — a retry re-checks
  /// their status and promotes the ready ones into [assetCodeByPath], so a
  /// partial failure doesn't re-upload (and orphan) work already done.
  final Map<String, String> pendingAssetCodeByPath = {};

  /// Session the [pendingAssetCodeByPath] assets belong to.
  String? pendingSessionCode;

  String? lastContextKey;

  void onSelectedFilesChanged(List<File> current) {
    assetCodeByPath.removeWhere(
      (path, _) => !current.any((f) => f.path == path),
    );
    pendingAssetCodeByPath.removeWhere(
      (path, _) => !current.any((f) => f.path == path),
    );
  }

  int uploadedCount(List<File> files) =>
      files.where((f) => assetCodeByPath.containsKey(f.path)).length;

  void clearForNewContext() {
    assetCodeByPath.clear();
    pendingAssetCodeByPath.clear();
    pendingSessionCode = null;
  }
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

  final isShared = bindingMode.trim().toUpperCase() == 'SHARED';

  // Trimmed, blank-free, ORIGINAL order — `ownerCode` below is the first of
  // these, so this must not be sorted.
  final cleanedStudentCodes = studentCodes
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  if (!isShared && cleanedStudentCodes.isEmpty) {
    throw ArgumentError.value(
      studentCodes,
      'studentCodes',
      'A PER_STUDENT activity upload needs at least one non-blank student code '
          'to own the asset',
    );
  }
  // Sorted copy, so the cache key is stable regardless of selection order.
  final normalizedStudentCodes = List<String>.from(cleanedStudentCodes)..sort();
  final uploadContextKey = [
    organizationCode.trim(),
    schoolCode.trim(),
    classroomCode.trim(),
    normalizedStudentCodes.join(','),
    activityTypeCode.trim(),
    bindingMode,
  ].join('|');

  if (state.lastContextKey != uploadContextKey) {
    state.clearForNewContext();
    state.lastContextKey = uploadContextKey;
  }

  final ownerType = isShared ? 'CLASSROOM' : 'STUDENT';
  final ownerCode = isShared ? classroomCode.trim() : cleanedStudentCodes.first;

  // Resume point: a previous attempt uploaded these but failed before the
  // readiness poll could confirm them. Promote any that have since reached
  // READY so they aren't uploaded a second time (which would orphan the copy
  // already sitting in the session). Anything not READY is left pending and
  // falls through to a normal re-upload below, exactly as before.
  await _promoteReadyPendingAssets(state, files);

  final missing = files
      .where((f) => !state.assetCodeByPath.containsKey(f.path))
      .toList();

  if (missing.isNotEmpty) {
    setState(() => setUploading(true));
    try {
      onOverallProgressPercent?.call(0);

      final items = <ActivityUploadItem>[];
      for (final photo in missing) {
        final fileName = photo.uri.pathSegments.isNotEmpty
            ? photo.uri.pathSegments.last
            : 'photo.jpg';
        // Sniff the real format (HEIC/PNG/WEBP are all pickable) rather than
        // declaring everything image/jpeg: telling S3/the backend the wrong
        // content type left non-JPEG uploads stuck at PROCESSING, never
        // reaching READY, because the decoder parsed them as JPEG. Falls back
        // to the extension when the bytes can't be sniffed.
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
          final overallPercent = (overallFraction * 100).clamp(0, 100).round();
          if (mounted()) {
            setState(() => onOverallProgressPercent?.call(overallPercent));
          }
        },
        onItemComplete: (completed, total) {
          if (mounted()) {
            setState(() => onFileCompleted?.call(completed, total));
          }
        },
        // Record each asset as it lands, so a throw partway through the batch
        // leaves a resume point instead of discarding the work. These are NOT
        // yet eligible for Save — only the ready-poll below promotes them.
        onAssetUploaded: (filePath, assetCode, sessionCode) {
          state.pendingAssetCodeByPath[filePath] = assetCode;
          state.pendingSessionCode = sessionCode;
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
      // Confirmed ready and cached — nothing left to resume for these.
      for (final path in result.assetCodeByPath.keys) {
        state.pendingAssetCodeByPath.remove(path);
      }
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

/// Re-checks assets left pending by a partially-failed batch and moves the ones
/// the backend now reports READY into [ActivityPhotoAttachmentState.assetCodeByPath].
///
/// Uses the one-shot status read rather than the blocking poll: this runs on the
/// happy path of every retry, so it must not stall the UI waiting on an asset
/// that is still PROCESSING. Anything not READY simply stays pending and is
/// re-uploaded by the caller, which is the pre-existing behaviour.
///
/// Best-effort by design — a failure here must not block the upload it precedes.
Future<void> _promoteReadyPendingAssets(
  ActivityPhotoAttachmentState state,
  List<File> files,
) async {
  final sessionCode = state.pendingSessionCode;
  if (sessionCode == null || sessionCode.isEmpty) return;
  if (state.pendingAssetCodeByPath.isEmpty) return;

  // Only the files still selected on screen.
  final selectedPaths = files.map((f) => f.path).toSet();
  final candidates = <String, String>{
    for (final e in state.pendingAssetCodeByPath.entries)
      if (selectedPaths.contains(e.key) &&
          !state.assetCodeByPath.containsKey(e.key))
        e.key: e.value,
  };
  if (candidates.isEmpty) return;

  try {
    final statuses =
        await serviceLocator<GetActivityUploadAssetStatusesUseCase>().call(
          sessionCode: sessionCode,
          assetCodes: candidates.values.toList(),
        );
    candidates.forEach((path, assetCode) {
      if ((statuses[assetCode] ?? '').trim().toUpperCase() == 'READY') {
        state.assetCodeByPath[path] = assetCode;
        state.pendingAssetCodeByPath.remove(path);
      }
    });
  } catch (error) {
    // Status read failed — leave everything pending and let the caller upload
    // as it always has. Logged so a systematic failure is visible.
    AppLogger.e('Activity upload: pending-asset status check failed', error);
  }
}
