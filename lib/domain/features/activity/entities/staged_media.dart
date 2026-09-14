/// A capture that has been copied out of volatile cache storage into the app's
/// documents directory, ready to survive an upload.
///
/// Pure Dart (Mandate 3): a path and a size, no `File` handle and no plugin
/// types.
class StagedMedia {
  const StagedMedia({required this.path, required this.sizeBytes});

  /// Absolute path of the persistent copy. Everything downstream —
  /// validation, checksum, the S3 PUT — reads THIS, never the cache original.
  final String path;

  /// Size of the copy as written, in bytes. Used to confirm the copy is
  /// complete rather than truncated by a full disk.
  final int sizeBytes;
}

/// Why staging a capture failed, in terms the UI can turn into a sentence.
///
/// A closed set rather than a raw `IOException`, so the presentation layer can
/// choose wording without parsing an OS error string (and without a file path
/// reaching a snackbar).
enum MediaStagingFailure {
  /// The device is out of space, or the copy came up short of the source.
  outOfSpace,

  /// The source is gone, unreadable, or the write failed for any other reason.
  ioError,
}

/// Thrown by `MediaStagingRepository.stage` when the persistent copy could not
/// be made. Carries no path — see [MediaStagingFailure].
class MediaStagingException implements Exception {
  const MediaStagingException(this.failure);

  final MediaStagingFailure failure;

  @override
  String toString() => 'MediaStagingException(${failure.name})';
}
