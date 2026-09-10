/// What kind of capture a [RecoveredMedia] came from.
///
/// Mirrors the two capture entry points the activity media picker offers
/// ("Take Photo" / "Record Video") so a caller can decide whether the recovery
/// belongs to it at all — a photo-only uploader must ignore a recovered video
/// exactly as it would have ignored a freshly picked one.
enum RecoveredMediaType { image, video }

/// A camera capture that the OS took from us before it could be handed back.
///
/// On Android the system may destroy the host activity while the camera app is
/// in the foreground (a long video recording on a memory-constrained device is
/// the common case). The capture still completes and is still written to disk,
/// but the result is delivered to an activity that no longer exists, so the
/// `pickImage`/`pickVideo` future never returns and the file is orphaned. The
/// platform picker caches that result; this entity is what comes back when it
/// is claimed.
///
/// Pure Dart by design (Mandate 3): file *paths*, not `File` handles or plugin
/// response types, so nothing platform-specific leaks above the data layer.
class RecoveredMedia {
  const RecoveredMedia({
    required this.type,
    required this.filePaths,
    this.errorMessage,
  });

  /// Nothing was waiting to be claimed — the overwhelmingly common case, and
  /// always the case on iOS, which has no equivalent loss mode.
  static const RecoveredMedia none = RecoveredMedia(
    type: RecoveredMediaType.image,
    filePaths: <String>[],
  );

  final RecoveredMediaType type;

  /// Absolute paths of the recovered captures, in the order the platform
  /// reported them. Empty when there was nothing to recover.
  final List<String> filePaths;

  /// Set when the platform cached a *failure* rather than a file — e.g. the
  /// camera app itself crashed. Carries no file, and is informational only:
  /// the capture is unrecoverable either way.
  final String? errorMessage;

  /// The platform had a *failed* capture waiting rather than a file — the
  /// camera app itself died. Distinct from [isNothingToRecover]: something was
  /// pending and it is now claimed and gone, there is just no file to restore.
  bool get hasFailedCapture => filePaths.isEmpty && errorMessage != null;

  /// Nothing was pending at all — the normal outcome on every run, and the
  /// only outcome off Android.
  bool get isNothingToRecover => filePaths.isEmpty && errorMessage == null;

  bool get isEmpty => filePaths.isEmpty;
  bool get isNotEmpty => filePaths.isNotEmpty;
}
