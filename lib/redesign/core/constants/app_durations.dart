/// Timings that are not animation.
///
/// How long a toast stays, how long a search waits before it fires, how long a
/// success state holds before it clears. Animation curves and durations are
/// [AppMotion]'s job, not this file's.
abstract final class AppDurations {
  /// How long a search field waits after the last keystroke.
  static const Duration searchDebounce = Duration(milliseconds: 350);

  /// How long a toast stays up before it dismisses itself.
  static const Duration toast = Duration(seconds: 3);

  /// A toast carrying an error, which needs longer to read.
  static const Duration toastError = Duration(seconds: 5);

  /// How long a key holds its done state after a successful write.
  static const Duration successHold = Duration(milliseconds: 1200);

  /// How long a pull-to-refresh spinner stays up at minimum, so a fast
  /// response does not flash.
  static const Duration minRefresh = Duration(milliseconds: 400);
}
