import 'return_code.dart';

/// No-op stub mirroring the subset of the ffmpeg_kit_flutter_new_https API used
/// by the app. ffmpeg is unavailable on the arm64 iOS simulator (the real
/// plugin has no arm64-simulator slice), so every execution reports failure
/// rather than transcoding. Callers fall back / surface an error gracefully.
class FFmpegSession {
  static const String _disabledMessage =
      'ffmpeg is disabled in this build (arm64 iOS-simulator stub).';

  /// Returning null => treated as "not success" by [ReturnCode.isSuccess].
  Future<ReturnCode?> getReturnCode() async => null;

  Future<String?> getOutput() async => _disabledMessage;

  Future<String?> getAllLogsAsString() async => _disabledMessage;
}

class FFmpegKit {
  static Future<FFmpegSession> executeWithArguments(
    List<String> arguments,
  ) async =>
      FFmpegSession();

  static Future<FFmpegSession> execute(String command) async => FFmpegSession();

  static Future<void> cancel() async {}
}
