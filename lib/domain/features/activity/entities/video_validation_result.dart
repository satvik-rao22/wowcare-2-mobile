/// Why a video was rejected before upload.
///
/// One value per rule, so the caller can show the specific reason and a
/// breadcrumb can name it — rather than a bare `false` that says only "no".
enum VideoRejectionReason {
  /// The file is not there any more (evicted, or the path went stale).
  fileMissing,

  /// Zero bytes. A capture that produced nothing at all — previously waved
  /// through, because `0 > maxSize` is false.
  emptyFile,

  /// Over the client's configured maximum.
  tooLarge,

  /// The bytes are not one of the accepted video container types. Determined
  /// by sniffing the file header, not by trusting the extension.
  unsupportedMimeType,

  /// The platform decoder could not read the file's metadata at all.
  ///
  /// This is the signature of a capture truncated by a crash before the `moov`
  /// atom was written — the exact failure mode this whole flow exists to
  /// survive. Explicitly rejected rather than inferred from a duration check.
  undecodable,

  /// Decoded, but reports no duration. The other half of the truncated-file
  /// case: some decoders return a zero-length track instead of throwing.
  zeroDuration,

  /// Over the client's configured duration maximum.
  tooLong,
}

/// Outcome of pre-upload validation.
///
/// Sealed so the caller must handle both cases, and so adding a reason cannot
/// silently fall through a `bool` check.
sealed class VideoValidationResult {
  const VideoValidationResult();

  bool get isValid => this is VideoValidationAccepted;
}

/// The file passed every rule. Carries the facts the checks already measured,
/// so the caller does not re-read them.
class VideoValidationAccepted extends VideoValidationResult {
  const VideoValidationAccepted({
    required this.sizeBytes,
    required this.durationMs,
    required this.mimeType,
  });

  final int sizeBytes;
  final int durationMs;
  final String mimeType;
}

/// The file failed [reason].
class VideoValidationRejected extends VideoValidationResult {
  const VideoValidationRejected(this.reason, {this.sizeBytes, this.durationMs});

  final VideoRejectionReason reason;

  /// Whatever was measured before the rule tripped, for the report. Null when
  /// the check that would have produced it never ran.
  final int? sizeBytes;
  final int? durationMs;
}

/// The thresholds pre-upload validation enforces.
///
/// ## Provenance — read before changing these
///
/// [maxSizeBytes] and [maxDurationSeconds] are **client-side only**. They were
/// carried over verbatim from the original `MediaUploader` constants
/// (`videoMaxSizeMB = 200`, `videoMaxDurationSec = 60`), which trace back to the
/// feature's first commits with no accompanying specification. There is no
/// server-provided limit anywhere in this codebase: no config endpoint returns
/// one, the presign request sends `contentLengthBytes` but nothing reads a cap
/// back, and no 413/"too large" response is handled. They are therefore
/// UNVERIFIED against what the backend actually enforces and must not be
/// treated as authoritative — see the note in the change report.
///
/// [acceptedMimeTypes] is different: it mirrors the list documented on
/// `FilePickerUtils.allowedVideoExtensions` ("Allowed video formats:
/// video/mp4, video/quicktime, video/webm"), which is the server's accepted
/// set — the backend rejects anything else with its own "Content type '…' is
/// not allowed" message.
abstract final class VideoUploadLimits {
  /// 200 MB. Client-side; see the provenance note above.
  static const int maxSizeBytes = 200 * 1024 * 1024;

  /// 30 seconds (lowered from 60 — see below). Client-side; also passed to
  /// `pickVideo(maxDuration:)` so the camera stops at it. See the provenance
  /// note above.
  ///
  /// Lowered because `image_picker` gives no control over the camera's
  /// recording resolution/bitrate (no equivalent of `imageQuality` exists
  /// for video capture — confirmed by reading its native Android source),
  /// so a long recording at whatever quality the OEM camera defaults to
  /// (often 1080p/4K) was crashing/freezing the device while the camera
  /// app finalized and saved it. Duration is the only capture-time lever
  /// this app has to bound the resulting file size; halving it directly
  /// halves the worst case. Still a mitigation, not a guarantee — a true
  /// fix needs native control over `EXTRA_VIDEO_QUALITY`.
  static const int maxDurationSeconds = 30;

  /// Server-enforced set, mirrored from the document service's accepted types.
  static const Set<String> acceptedMimeTypes = <String>{
    'video/mp4',
    'video/quicktime',
    'video/webm',
  };
}
