import 'package:wowcare/domain/features/activity/entities/staged_media.dart';

/// Owns the app's persistent staging area for captures awaiting upload.
///
/// ## Why this exists
///
/// Both pickers hand back a file in **cache** storage — `image_picker` writes
/// camera output under its FileProvider's `<cache-path>`, and `file_picker`
/// copies the SAF selection into the cache dir. Android is free to evict
/// `cacheDir` under storage pressure, and a 100 MB+ video being streamed to S3
/// over several minutes is exactly the window in which that happens: the
/// `openRead()` backing the PUT then fails partway with a `FileSystemException`
/// on a file that existed when the upload started.
///
/// Copying to `getApplicationDocumentsDirectory()` first takes the file out of
/// the OS's reach for the duration of the upload.
abstract class MediaStagingRepository {
  /// Copies [sourcePath] into the staging directory and returns the persistent
  /// copy.
  ///
  /// **Copy, never move.** The source can be a read-only content:// URI
  /// materialisation that the app does not own, so deleting or renaming it is
  /// not ours to do — and on the camera path the plugin still holds a reference
  /// to it.
  ///
  /// Throws [MediaStagingException] — and only that — when the copy cannot be
  /// made, so callers have one thing to catch and can map it to a message.
  Future<StagedMedia> stage(String sourcePath);

  /// Deletes one staged copy. Best-effort and never throws: a file that is
  /// already gone is the desired end state.
  ///
  /// Call ONLY once the server has confirmed the upload, or when the user has
  /// explicitly discarded the capture. Deleting earlier throws away the only
  /// copy of something that may still need to be retried.
  Future<void> discard(String stagedPath);

  /// Deletes staged files older than [maxAge], returning how many went.
  ///
  /// For leftovers from a previous run: a process killed mid-upload leaves its
  /// copy behind with nothing left to delete it. Never throws.
  Future<int> sweepOrphans({required Duration maxAge});
}
