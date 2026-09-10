/// What the platform decoder could read from a video file.
class VideoProbe {
  const VideoProbe({required this.decodable, required this.durationMs});

  /// A probe that could not read the file at all — a truncated capture, or a
  /// container the device has no decoder for.
  static const VideoProbe undecodable = VideoProbe(
    decodable: false,
    durationMs: 0,
  );

  /// Whether the decoder read the file's metadata successfully.
  final bool decodable;

  /// Track duration. Zero from a decoder that opened a truncated file without
  /// throwing — which is why [decodable] alone is not sufficient.
  final int durationMs;
}

/// Reads a video's metadata through the platform decoder.
///
/// Exists so the decodability check is an explicit, injectable step rather than
/// a side effect of constructing a player in a widget — and so validation can
/// be tested without a platform channel.
abstract class VideoProbeRepository {
  /// Never throws: a decoder failure IS the answer, returned as
  /// [VideoProbe.undecodable].
  Future<VideoProbe> probe(String path);
}
