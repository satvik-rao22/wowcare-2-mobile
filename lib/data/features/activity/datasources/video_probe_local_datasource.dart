import 'dart:io';

import 'package:video_player/video_player.dart';
import 'package:wowcare/domain/features/activity/repositories/video_probe_repository.dart';

/// Probes a video by opening it with the platform decoder and reading the
/// metadata it exposes.
abstract class VideoProbeLocalDataSource {
  Future<VideoProbe> probe(String path);
}

class VideoPlayerProbeLocalDataSource implements VideoProbeLocalDataSource {
  const VideoPlayerProbeLocalDataSource();

  @override
  Future<VideoProbe> probe(String path) async {
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      // `initialize()` throwing is the common signal for an unreadable file,
      // but not the only one: ExoPlayer can resolve the future and report the
      // problem on the value instead. Both are treated as undecodable.
      final value = controller.value;
      if (!value.isInitialized || value.hasError) {
        return VideoProbe.undecodable;
      }
      return VideoProbe(
        decodable: true,
        durationMs: value.duration.inMilliseconds,
      );
    } catch (_) {
      return VideoProbe.undecodable;
    } finally {
      // Disposal of a controller whose initialize() failed can itself throw;
      // that must not become the reported failure.
      try {
        await controller.dispose();
      } catch (_) {}
    }
  }
}
