import 'dart:async';

import 'package:flutter/foundation.dart';

/// Collapses a burst of rapid calls into a single trailing invocation: each
/// [run] restarts the timer, so [action] fires only once the caller has been
/// quiet for [duration]. Used to keep per-keystroke search inputs from
/// re-filtering (and rebuilding) on every character.
class Debouncer {
  Debouncer({this.duration = const Duration(milliseconds: 350)});

  final Duration duration;
  Timer? _timer;

  /// Whether a call is currently pending (mainly for tests/diagnostics).
  bool get isActive => _timer?.isActive ?? false;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Cancels any pending call without running it.
  void cancel() => _timer?.cancel();

  void dispose() => _timer?.cancel();
}
