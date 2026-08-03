/// No-op stub mirroring ffmpeg_kit_flutter_new_https' ReturnCode API surface.
class ReturnCode {
  static const int success = 0;
  static const int cancel = 255;

  final int value;
  const ReturnCode(this.value);

  static bool isSuccess(ReturnCode? returnCode) =>
      returnCode != null && returnCode.value == success;

  static bool isCancel(ReturnCode? returnCode) =>
      returnCode != null && returnCode.value == cancel;

  int getValue() => value;

  @override
  String toString() => value.toString();
}
