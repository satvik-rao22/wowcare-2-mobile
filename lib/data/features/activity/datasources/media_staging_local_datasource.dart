import 'dart:io';
import 'dart:math';

import 'package:wowcare/core/utils/file_utils/file_utils.dart';
import 'package:wowcare/domain/features/activity/entities/staged_media.dart';

/// Filesystem side of [MediaStagingRepository]. The only place in the app that
/// writes into the staging directory.
abstract class MediaStagingLocalDataSource {
  Future<StagedMedia> stage(String sourcePath);
  Future<void> discard(String stagedPath);
  Future<int> sweepOrphans({required Duration maxAge});
}

class FileMediaStagingLocalDataSource implements MediaStagingLocalDataSource {
  FileMediaStagingLocalDataSource({Random? random})
    : _random = random ?? Random.secure();

  final Random _random;

  /// Dedicated subdirectory so the sweep can delete everything old inside it
  /// without ever having to reason about whether a neighbouring file belongs to
  /// something else.
  static const String _stagingDirName = 'pending_media_uploads';

  /// Extensions the flow can produce. An unrecognised one is normalised to
  /// `.bin` rather than echoed back into a filename — the source extension is
  /// user-controlled text and this is the one part of it that survives.
  static const Set<String> _knownExtensions = <String>{
    'mp4', 'mov', 'webm',
    'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif', 'avif', 'gif', 'bmp', 'tiff',
    'tif',
  };

  Future<Directory> _stagingDir() async {
    final docs = await FileUtils.documentsDirectory();
    final dir = Directory('${docs.path}${Platform.pathSeparator}$_stagingDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Collision-proof by construction: microsecond clock plus 64 bits of
  /// secure randomness. The clock alone is not enough — two captures staged in
  /// the same microsecond, or a clock moved backwards by an NTP correction,
  /// would collide and one file would silently overwrite the other.
  String _uniqueName(String extension) {
    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final noise = List<String>.generate(
      8,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return 'media_${stamp}_$noise.$extension';
  }

  String _extensionOf(String sourcePath) {
    final name = sourcePath.split(Platform.pathSeparator).last;
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return 'bin';
    final ext = name.substring(dot + 1).toLowerCase();
    return _knownExtensions.contains(ext) ? ext : 'bin';
  }

  @override
  Future<StagedMedia> stage(String sourcePath) async {
    final source = File(sourcePath);

    final int sourceLength;
    try {
      if (!await source.exists()) {
        throw const MediaStagingException(MediaStagingFailure.ioError);
      }
      sourceLength = await source.length();
    } on MediaStagingException {
      rethrow;
    } catch (_) {
      throw const MediaStagingException(MediaStagingFailure.ioError);
    }

    final dir = await _stagingDir();
    final target = File(
      '${dir.path}${Platform.pathSeparator}${_uniqueName(_extensionOf(sourcePath))}',
    );

    try {
      // copy(), never rename(): the source may be a read-only materialisation
      // of a content:// URI the app does not own, and on the camera path the
      // picker plugin still holds a reference to it.
      await source.copy(target.path);

      // A copy onto a full disk can return without error having written short,
      // which would upload a truncated video that fails server-side decode
      // hours later. Verify the length matches before calling it staged.
      final copiedLength = await target.length();
      if (copiedLength != sourceLength) {
        await _deleteQuietly(target);
        throw const MediaStagingException(MediaStagingFailure.outOfSpace);
      }
      return StagedMedia(path: target.path, sizeBytes: copiedLength);
    } on MediaStagingException {
      rethrow;
    } on FileSystemException catch (e) {
      await _deleteQuietly(target);
      // errno 28 == ENOSPC on both Linux/Android and Darwin.
      final isNoSpace = e.osError?.errorCode == 28;
      throw MediaStagingException(
        isNoSpace ? MediaStagingFailure.outOfSpace : MediaStagingFailure.ioError,
      );
    } catch (_) {
      await _deleteQuietly(target);
      throw const MediaStagingException(MediaStagingFailure.ioError);
    }
  }

  @override
  Future<void> discard(String stagedPath) async {
    // Refuse to delete anything outside the staging directory. discard() takes
    // a path, and a caller that passed the ORIGINAL cache path (or worse) must
    // not be able to turn this into an arbitrary-delete primitive.
    final dir = await _stagingDir();
    if (!stagedPath.startsWith(dir.path)) return;
    await _deleteQuietly(File(stagedPath));
  }

  @override
  Future<int> sweepOrphans({required Duration maxAge}) async {
    final dir = await _stagingDir();
    final cutoff = DateTime.now().subtract(maxAge);
    var deleted = 0;
    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        try {
          final modified = await entity.lastModified();
          if (modified.isAfter(cutoff)) continue;
          await entity.delete();
          deleted++;
        } catch (_) {
          // One unreadable entry must not abort the sweep.
        }
      }
    } catch (_) {
      // Directory unreadable — nothing swept, and that is not an error worth
      // failing app start over.
    }
    return deleted;
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
