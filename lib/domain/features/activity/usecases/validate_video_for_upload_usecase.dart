import 'dart:io';
import 'dart:typed_data';

import 'package:wowcare/domain/features/activity/entities/video_validation_result.dart';
import 'package:wowcare/domain/features/activity/repositories/video_probe_repository.dart';
import 'package:wowcare/domain/features/activity/usecases/video_container_sniffer.dart';

/// Runs every pre-upload rule against a video and returns a typed verdict.
///
/// Ordered cheapest-first so an obviously bad file is rejected before the
/// expensive decoder probe: existence → size → sniffed mime → decode →
/// duration.
///
/// Runs against the PERSISTENT (staged) path and before the checksum, so the
/// bytes that are validated are exactly the bytes that get hashed and uploaded.
class ValidateVideoForUploadUseCase {
  const ValidateVideoForUploadUseCase(this._probeRepository);

  final VideoProbeRepository _probeRepository;

  /// How many leading bytes to read for content sniffing — one small read, not
  /// a load of the file.
  static const int _sniffBytes = VideoContainerSniffer.requiredBytes;

  Future<VideoValidationResult> call(String path) async {
    final file = File(path);

    // 1. Exists.
    try {
      if (!await file.exists()) {
        return const VideoValidationRejected(VideoRejectionReason.fileMissing);
      }
    } catch (_) {
      return const VideoValidationRejected(VideoRejectionReason.fileMissing);
    }

    // 2. Size > 0, and 3. size under the maximum.
    final int sizeBytes;
    try {
      sizeBytes = await file.length();
    } catch (_) {
      return const VideoValidationRejected(VideoRejectionReason.fileMissing);
    }
    if (sizeBytes <= 0) {
      // Previously waved through: `0 > maxSize` is false, so an empty capture
      // reached the uploader and failed server-side instead.
      return const VideoValidationRejected(
        VideoRejectionReason.emptyFile,
        sizeBytes: 0,
      );
    }
    if (sizeBytes > VideoUploadLimits.maxSizeBytes) {
      return VideoValidationRejected(
        VideoRejectionReason.tooLarge,
        sizeBytes: sizeBytes,
      );
    }

    // 4. Mime type, read from the file's own header — NEVER from its
    //    extension. A text file named `clip.mp4` must not reach the uploader
    //    just because it was named convincingly.
    final mimeType = await _sniffMimeType(file);
    if (mimeType == null ||
        !VideoUploadLimits.acceptedMimeTypes.contains(mimeType)) {
      return VideoValidationRejected(
        VideoRejectionReason.unsupportedMimeType,
        sizeBytes: sizeBytes,
      );
    }

    // 5. Decodable — explicit, not incidental. A capture truncated before its
    //    moov atom was written fails here with its own reason.
    final probe = await _probeRepository.probe(path);
    if (!probe.decodable) {
      return VideoValidationRejected(
        VideoRejectionReason.undecodable,
        sizeBytes: sizeBytes,
      );
    }

    // 6. Duration > 0, and 7. duration under the maximum.
    if (probe.durationMs <= 0) {
      return VideoValidationRejected(
        VideoRejectionReason.zeroDuration,
        sizeBytes: sizeBytes,
        durationMs: probe.durationMs,
      );
    }
    if (probe.durationMs > VideoUploadLimits.maxDurationSeconds * 1000) {
      return VideoValidationRejected(
        VideoRejectionReason.tooLong,
        sizeBytes: sizeBytes,
        durationMs: probe.durationMs,
      );
    }

    return VideoValidationAccepted(
      sizeBytes: sizeBytes,
      durationMs: probe.durationMs,
      mimeType: mimeType,
    );
  }

  /// Reads the leading bytes and identifies the container from them alone.
  ///
  /// There is deliberately NO extension fallback: the filename is
  /// user-controlled, so falling back to it would let anything through under a
  /// convincing name — which is exactly the hole this check exists to close.
  Future<String?> _sniffMimeType(File file) async {
    try {
      final chunks = <int>[];
      await for (final chunk in file.openRead(0, _sniffBytes)) {
        chunks.addAll(chunk);
        if (chunks.length >= _sniffBytes) break;
      }
      return VideoContainerSniffer.sniff(Uint8List.fromList(chunks));
    } catch (_) {
      return null;
    }
  }
}
