import 'package:flutter/widgets.dart';

/// Centralised corner-radius scale (logical pixels).
///
/// Values mirror the `BorderRadius.circular(...)` radii already used across the
/// app, so replacing a literal with the matching token is **pixel-identical**.
/// Prefer the semantic names ([xs]…[xl], [pill]); the numeric aliases exist
/// only to migrate off-scale legacy radii without visual drift.
///
/// The `all*` helpers return a ready-made [BorderRadius] for the common
/// symmetric case.
class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;

  /// Fully rounded (used for chips / pills / circular avatars via a large
  /// radius on a square box).
  static const double pill = 100;

  /// Off-scale legacy values retained for faithful migration.
  static const double r7 = 7;
  static const double r10 = 10;
  static const double r14 = 14;
  static const double r15 = 15;

  // ── Ready-made symmetric BorderRadius values ───────────────────────────────
  static const BorderRadius allXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius allSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius allMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius allLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius allXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius allPill = BorderRadius.all(Radius.circular(pill));
}
