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

  // ── The flat skeuomorphic material ────────────────────────────────────────
  //
  // Radii the `03 Components` specimens use that the scale above does not
  // reach. Referenced from `AppSurfaces`; a call site should normally take
  // the whole decoration from there rather than one of these on its own.

  /// 18 — a list row, a kiosk digit, a toast, a message bubble.
  static const double r18 = 18;

  /// 22 — the 64x64 well behind an empty state's icon.
  static const double r22 = 22;

  /// 24 — the optional update banner on a tablet.
  static const double r24 = 24;

  /// 28 — the top corners of a bottom sheet.
  static const double r28 = 28;

  /// 42 — the bottom corners of a bottom sheet, where it meets the device.
  static const double r42 = 42;

  // ── Ready-made symmetric BorderRadius values ───────────────────────────────
  static const BorderRadius allXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius allSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius allMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius allLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius allXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius allPill = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius allR14 = BorderRadius.all(Radius.circular(r14));
  static const BorderRadius allR18 = BorderRadius.all(Radius.circular(r18));
  static const BorderRadius allR22 = BorderRadius.all(Radius.circular(r22));

  /// A bottom sheet: 28 at the top, 42 at the bottom so it meets the device's
  /// own corner radius rather than cutting across it.
  static const BorderRadius sheet = BorderRadius.only(
    topLeft: Radius.circular(r28),
    topRight: Radius.circular(r28),
    bottomLeft: Radius.circular(r42),
    bottomRight: Radius.circular(r42),
  );
}
