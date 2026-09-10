import 'package:dio/dio.dart';

import 'package:wowcare/core/observability/media_upload_trace.dart';
import 'package:wowcare/domain/features/activity/repositories/activity_media_upload_repository.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// Concrete [ActivityMediaUploadRepository] that drives the shared
/// [ImageUploadService]. Preserves the P5 fixes carried by the underlying
/// service — streamed PUT (P5-a), [CancelToken] threading (P5-b) — while the
/// context-keyed retry cache (P5-c) stays owned by each caller. No readiness
/// poll happens here; callers pick [waitUntilAssetsReady] (blocking) or
/// [getUploadAssetStatuses] (background).
class ActivityMediaUploadRepositoryImpl implements ActivityMediaUploadRepository {
  ActivityMediaUploadRepositoryImpl(this._uploadService);

  final ImageUploadService _uploadService;

  @override
  Future<ActivityAssetUploadResult> uploadAssets({
    required String organizationCode,
    required String schoolCode,
    required String classroomCode,
    required String activityTypeCode,
    required String bindingMode,
    required List<String> studentCodes,
    required String ownerType,
    required String ownerCode,
    required List<ActivityUploadItem> items,
    void Function(int itemIndex, int totalItems, int percent)? onItemProgress,
    void Function(int completedItems, int totalItems)? onItemComplete,
    void Function(String filePath, String assetCode, String sessionCode)?
    onAssetUploaded,
    CancelToken? cancelToken,
  }) async {
    // Every stage below is breadcrumbed on ENTRY. A process killed mid-upload
    // (the Android OOM case the audit could not distinguish from a network
    // failure) leaves the stage it died in as the last entry in the report.
    MediaUploadTrace.stage(MediaUploadStage.uploadRequested);
    final session = await _uploadService.createActivityUploadSession(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      classroomCode: classroomCode,
      activityTypeCode: activityTypeCode,
      bindingMode: bindingMode,
      studentCodes: studentCodes,
      cancelToken: cancelToken,
    );
    MediaUploadTrace.stage(MediaUploadStage.sessionCreated);

    final assetCodeByPath = <String, String>{};
    final newAssetCodes = <String>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final itemIndex = i + 1;
      final totalItems = items.length;
      // Position, size and type only — never the path or file name, both of
      // which are user-controlled text.
      MediaUploadTrace.itemPosition(itemIndex, totalItems);
      MediaUploadTrace.mimeType(item.contentType);
      final contentLengthBytes = await item.file.length();
      MediaUploadTrace.fileSizeBytes(contentLengthBytes);

      MediaUploadTrace.stage(MediaUploadStage.checksumStarted);
      final checksumSha256 =
          await _uploadService.computeFileChecksumSha256(item.file);
      MediaUploadTrace.stage(MediaUploadStage.checksumDone);

      MediaUploadTrace.stage(MediaUploadStage.presignRequested);
      final presign = await _uploadService.createAssetPresign(
        sessionCode: session.sessionCode,
        documentApiBasePath: session.documentApiBasePath,
        fileName: item.fileName,
        contentType: item.contentType,
        contentLengthBytes: contentLengthBytes,
        checksumSha256: checksumSha256,
        mediaType: item.mediaType,
        ownerType: ownerType,
        ownerCode: ownerCode,
        cancelToken: cancelToken,
      );
      MediaUploadTrace.stage(MediaUploadStage.presignDone);

      await _uploadService.uploadFileToPresignedUrl(
        file: item.file,
        presignedPutUrl: presign.presignedPutUrl,
        requiredHeaders: presign.requiredHeaders,
        fallbackContentType: item.contentType,
        onProgress: (sentBytes, totalBytes, percent) {
          onItemProgress?.call(itemIndex, totalItems, percent);
        },
        cancelToken: cancelToken,
      );

      MediaUploadTrace.stage(MediaUploadStage.assetCompleted);
      await _uploadService.completeAssetUpload(
        sessionCode: session.sessionCode,
        assetCode: presign.assetCode,
        documentApiBasePath: session.documentApiBasePath,
        cancelToken: cancelToken,
      );
      assetCodeByPath[item.file.path] = presign.assetCode;
      newAssetCodes.add(presign.assetCode);
      // Surface this asset before starting the next item, so a throw later in
      // the loop doesn't discard the ones already uploaded (see the callback's
      // doc on the repository contract).
      onAssetUploaded?.call(
        item.file.path,
        presign.assetCode,
        session.sessionCode,
      );
      onItemComplete?.call(itemIndex, totalItems);
    }

    return ActivityAssetUploadResult(
      assetCodeByPath: assetCodeByPath,
      sessionCode: session.sessionCode,
      newAssetCodes: newAssetCodes,
    );
  }

  @override
  Future<void> waitUntilAssetsReady({
    required String sessionCode,
    required List<String> assetCodes,
  }) {
    return _uploadService.waitUntilAssetsReady(
      sessionCode: sessionCode,
      expectedAssetCodes: assetCodes,
    );
  }

  @override
  Future<Map<String, String>> getUploadAssetStatuses({
    required String sessionCode,
    required List<String> assetCodes,
  }) {
    return _uploadService.getUploadAssetStatuses(
      sessionCode: sessionCode,
      expectedAssetCodes: assetCodes,
    );
  }
}
