import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:wowcare/core/observability/telemetry_redactor.dart';
import 'package:wowcare/core/utils/logger_service.dart';

/// Where a capture came from. Recorded because the two paths fail differently:
/// only the camera path can lose its result to Android activity death, and only
/// the gallery path can hand back a file the app does not own.
enum MediaCaptureSource { camera, gallery }

/// Every stage the activity video/photo flow passes through, in order.
///
/// A crash that kills the process leaves only the breadcrumbs already written,
/// so [MediaUploadTrace.stage] is called on *entering* each stage rather than
/// on completing it — the last breadcrumb in a report names the stage that
/// killed it, which is the whole point of the exercise.
enum MediaUploadStage {
  pickerOpened,
  pickerReturned,
  pickerCancelled,
  pickerFailed,
  fileOnDisk,
  fileMissing,
  stagingStarted,
  stagingDone,
  stagingFailed,
  orphanSwept,
  validationStarted,
  validationRejected,
  validationPassed,
  validationProbeStarted,
  thumbnailStarted,
  thumbnailDone,
  thumbnailFailed,
  lostMediaCheckStarted,
  lostMediaNoneFound,
  lostMediaFailedCapture,
  lostMediaClaimed,
  lostMediaRestored,
  lostMediaDiscarded,
  uploadRequested,
  sessionCreated,
  checksumStarted,
  checksumDone,
  presignRequested,
  presignDone,
  putStarted,
  putRetry,
  putSucceeded,
  putFailed,
  assetCompleted,
  readyPollStarted,
  readyPollSucceeded,
  readyPollFailed,
  uploadSucceeded,
  uploadFailed,
  uploadCancelled,
}

/// Crashlytics breadcrumbs and custom keys for the activity media
/// capture-and-upload flow.
///
/// ## Why this exists
///
/// The flow's breadcrumbs were written with `AppLogger.d`, which is a
/// deliberate release no-op (it is handed raw API bodies elsewhere). Crashes
/// therefore arrived in production with no indication of which stage produced
/// them. This is the release-surviving replacement, and it is a *closed*
/// vocabulary rather than a free-text logger so that call sites cannot
/// reintroduce the PII risk that made `AppLogger.d` a no-op in the first place.
///
/// ## PII policy — enforced by the API shape
///
/// No method here accepts a file path, a person's name, or any user, student,
/// staff, school or organisation identifier. Only sizes, durations, counts,
/// booleans and fixed enum labels can be recorded. [mimeType] is the one free
/// string, and it is whitelist-checked before being written.
///
/// If you need a new fact, add a typed method here rather than reaching for
/// `AppLogger.trail` at the call site.
class MediaUploadTrace {
  const MediaUploadTrace._();

  /// Namespaced so these are greppable in a Crashlytics report and cannot
  /// collide with keys set by another feature.
  static const String _keyPrefix = 'media_upload_';

  /// Marks entry into [stage]. Call BEFORE doing the stage's work.
  static void stage(MediaUploadStage stage) {
    AppLogger.trail('[media_upload] ${stage.name}');
  }

  /// Marks entry into [stage] with a short, fixed-vocabulary qualifier — e.g.
  /// the reason a validation rejected. [detail] must not be user data or
  /// free-form text derived from it.
  static void stageWithDetail(MediaUploadStage stage, String detail) {
    AppLogger.trail('[media_upload] ${stage.name}: $detail');
  }

  /// Records the host platform once per flow, so a report can be bucketed
  /// without cross-referencing device metadata.
  static void platform() {
    AppLogger.setKey(
      '${_keyPrefix}platform',
      kIsWeb
          ? 'web'
          : Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : Platform.operatingSystem,
    );
  }

  static void source(MediaCaptureSource source) {
    AppLogger.setKey('${_keyPrefix}source', source.name);
  }

  /// Size of the file being handled, in bytes. Bytes, not MB, so a report can
  /// be compared against the 200 MB ceiling without rounding.
  static void fileSizeBytes(int bytes) {
    AppLogger.setKey('${_keyPrefix}file_size_bytes', bytes);
  }

  /// Video duration in milliseconds. Zero is meaningful — it is what a
  /// truncated MP4 with no readable `moov` atom reports.
  static void durationMs(int milliseconds) {
    AppLogger.setKey('${_keyPrefix}duration_ms', milliseconds);
  }

  /// The declared content type. Whitelisted rather than passed through: a mime
  /// derived from a user-chosen filename could otherwise smuggle text into the
  /// report.
  static void mimeType(String mimeType) {
    const allowed = <String>{
      'video/mp4',
      'video/quicktime',
      'video/webm',
      'image/jpeg',
      'image/png',
      'image/webp',
      'image/heic',
      'image/heif',
      'image/avif',
      'image/gif',
      'image/bmp',
      'image/tiff',
    };
    final normalized = mimeType.trim().toLowerCase();
    AppLogger.setKey(
      '${_keyPrefix}mime_type',
      allowed.contains(normalized) ? normalized : 'other',
    );
  }

  /// Upload progress. A custom key rather than a breadcrumb precisely because
  /// it fires continuously — breadcrumbs are capped at ~64 per report and
  /// progress would evict every stage marker before it. Overwriting a key is
  /// free, so a crash mid-PUT still shows exactly how far it got.
  static void bytesUploaded(int sent, int total) {
    AppLogger.setKey('${_keyPrefix}bytes_uploaded', sent);
    AppLogger.setKey('${_keyPrefix}bytes_total', total);
  }

  /// Which PUT attempt is in flight (1-based) out of [maxAttempts].
  static void attempt(int attempt, int maxAttempts) {
    AppLogger.setKey('${_keyPrefix}attempt', attempt);
    AppLogger.setKey('${_keyPrefix}max_attempts', maxAttempts);
  }

  /// How many orphaned staged copies a sweep deleted. A number climbing over
  /// releases means uploads are dying before their cleanup runs.
  static void orphansSwept(int count) {
    AppLogger.setKey('${_keyPrefix}orphans_swept', count);
  }

  /// Position within a multi-file batch, so a failure names which item died.
  static void itemPosition(int index, int total) {
    AppLogger.setKey('${_keyPrefix}item_index', index);
    AppLogger.setKey('${_keyPrefix}item_count', total);
  }

  /// Reports a caught exception from this flow, with paths and URLs redacted.
  ///
  /// The exceptions this flow throws are exactly the ones that carry sensitive
  /// text in their own message, so the raw object must never reach Crashlytics:
  ///
  /// * `FileSystemException` / `PathAccessException` / `PathNotFoundException`
  ///   embed the absolute file path — which on Android contains the package
  ///   sandbox and on iOS the per-install UUID, and whose basename is often the
  ///   user's own file name.
  /// * `DioException` embeds the request URI, and for the S3 PUT that is the
  ///   **presigned URL — a bearer credential** carrying `X-Amz-Signature`.
  ///
  /// [fatal] is true only where the failure leaves the feature unusable to the
  /// user — it counts against crash-free-users, so a recoverable error the UI
  /// surfaces and the user can retry stays non-fatal.
  static void failure(
    MediaUploadStage stage,
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
  }) {
    AppLogger.recordError(
      _RedactedError(error.runtimeType.toString(), _redact(error.toString())),
      stackTrace,
      reason: '[media_upload] failed at ${stage.name}',
      fatal: fatal,
    );
  }

  /// Test seam for [_redact] — the redaction is the PII guarantee, so it is
  /// asserted rather than assumed.
  @visibleForTesting
  static String debugRedact(String message) => _redact(message);

  /// Strips anything path- or URL-shaped out of an exception message.
  ///
  /// Deliberately blunt: it over-redacts rather than risk letting a path
  /// through, because the diagnostic value here is the exception *type* and
  /// error code, not the filename. The rules live in [TelemetryRedactor] so
  /// the Sentry hooks apply exactly the same ones.
  static String _redact(String message) =>
      TelemetryRedactor.redactPathsAndUrls(message);
}

/// A stand-in for a caught exception carrying only its type and a redacted
/// message, so Crashlytics groups by type without ever receiving a path or a
/// presigned URL. See [MediaUploadTrace.failure].
class _RedactedError implements Exception {
  const _RedactedError(this.type, this.redactedMessage);

  final String type;
  final String redactedMessage;

  @override
  String toString() => '$type: $redactedMessage';
}
