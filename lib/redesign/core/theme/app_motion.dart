import 'package:flutter/animation.dart';

/// How things move. Four durations and two curves, and nothing else.
///
/// The design's motion is physical rather than decorative: a key sinks and
/// settles, a sheet slides, a panel opens. Everything is short enough that it
/// never gets in the way of a second tap.
abstract final class AppMotion {
  /// A key sinking under a finger, and settling back.
  static const Duration press = Duration(milliseconds: 90);

  /// A colour, an opacity, a chip toggling.
  static const Duration fast = Duration(milliseconds: 160);

  /// The default for anything that changes size or position in place.
  static const Duration base = Duration(milliseconds: 200);

  /// A bottom sheet, a panel, a route.
  static const Duration panel = Duration(milliseconds: 300);

  /// The house curve. Standard ease-out: fast to start, settling at the end.
  static const Curve ease = Curves.easeOut;

  /// Overshoots and settles. For a thing arriving, never for a thing leaving.
  static const Curve spring = Cubic(.34, 1.56, .64, 1);
}
