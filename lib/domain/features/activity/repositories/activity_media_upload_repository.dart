import 'dart:io';

import 'package:dio/dio.dart';

/// One file's worth of input for [ActivityMediaUploadRepository.uploadAssets].
/// Each caller computes [fileName]/[contentType]/[mediaType] with its own
/// (distinct) logic and hands the results here — the repository stays agnostic
/// about how those were derived.
class ActivityUploadItem {
  const ActivityUploadItem({
    required this.file,
    required this.fileName,
    required this.contentType,
    required this.mediaType,
  });

  final File file;
  final String fileName;
  final String contentType;

  /// `IMAGE` or `VIDEO` — the document service's media classification.
  final String mediaType;
}

/// Outcome of a single-session batch upload.
class ActivityAssetUploadResult {
  const ActivityAssetUploadResult({
    required this.assetCodeByPath,
    required this.sessionCode,
    required this.newAssetCodes,
  });

  /// Local file path → the asset code presigned+completed for it in this run.
  final Map<String, String> assetCodeByPath;

  /// The upload session all items were presigned/completed under.
  final String sessionCode;

  /// Asset codes created in THIS run, in item order — the set a caller polls
  /// (blocking or background) for readiness.
  final List<String> newAssetCodes;
}

/// Wraps the shared image-upload transaction (session → presign → PUT →
/// complete, and the two readiness-poll variants) behind the activity domain
/// so the presentation layer never touches the data-layer upload service
/// directly. Callers own the readiness-poll choice (blocking
/// [waitUntilAssetsReady] vs. background [getUploadAssetStatuses]).
abstract class ActivityMediaUploadRepository {
  /// Opens ONE upload session, then for each item: computes checksum + length,
  /// presigns, streams the PUT (bridging progress to [onItemProgress]), and
  /// completes. No readiness poll is performed here.
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

    /// Fired as each item finishes its `complete` call, BEFORE the next item
    /// starts. Lets a caller record progress that would otherwise be lost when
    /// a later item throws: the returned [ActivityAssetUploadResult] only ever
    /// materializes on full success, so without this a failure at item 3 of 5
    /// discards items 1–2 and the retry re-uploads (and orphans) them.
    ///
    /// The asset is uploaded and completed, but NOT yet known to be READY —
    /// a caller must confirm readiness before letting it be linked.
    void Function(String filePath, String assetCode, String sessionCode)?
    onAssetUploaded,
    CancelToken? cancelToken,
  });

  /// Blocking readiness poll — the util's strategy. Returns once every asset in
  /// [assetCodes] is ready, or throws on failure/timeout.
  Future<void> waitUntilAssetsReady({
    required String sessionCode,
    required List<String> assetCodes,
  });

  /// One-shot status read — the photo screen's background-poll strategy.
  /// Returns `assetCode → status` for the codes visible in the session.
  Future<Map<String, String>> getUploadAssetStatuses({
    required String sessionCode,
    required List<String> assetCodes,
  });
}
