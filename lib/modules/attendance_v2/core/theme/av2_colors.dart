import 'package:flutter/material.dart';

/// Semantic color tokens for the Attendance V2 module.
///
/// Values mirror the host app's `AppColors` so the module feels native — punchy
/// gradients, the brand plum text color (#573353), and the sky-blue / mustard
/// progress palette. Kept self-contained (literal values) so the module stays
/// isolated; when wired in, these can be pointed at `AppColors` in one place.
class Av2Colors {
  const Av2Colors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color primary = Color.fromRGBO(87, 51, 83, 1); // #573353 plum
  static const Color theme = Color.fromRGBO(89, 120, 247, 1); // #5978F7 blue
  static const Color secondary = Color.fromRGBO(27, 35, 126, 1); // #1B237E
  static const Color accent = Color.fromRGBO(220, 156, 19, 1); // #DC9C13 amber

  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color.fromRGBO(177, 175, 233, 0.1); // field bg
  static const Color pageBackground = Color.fromRGBO(251, 238, 250, 1);

  // ── Text (brand plum, never pure black) ────────────────────────────────────
  static const Color textPrimary = primary;
  static const Color textSecondary = Color.fromRGBO(87, 51, 83, 0.62);
  static const Color textTertiary = Color.fromRGBO(87, 51, 83, 0.42);

  // ── Borders ─────────────────────────────────────────────────────────────────
  static const Color border = Color.fromRGBO(87, 51, 83, 0.15);
  static const Color borderStrong = Color.fromRGBO(87, 51, 83, 0.3);

  // ── Regular hours (blue) ────────────────────────────────────────────────────
  static const Color regular = theme; // icons, emphasis, hero number
  static const Color regularFill = Color.fromRGBO(155, 232, 255, 0.35);
  static const Color barRegular = Color.fromRGBO(155, 232, 255, 1); // #9BE8FF

  // ── Overtime (amber / mustard) ──────────────────────────────────────────────
  static const Color overtime = accent; // OT text + system flag
  static const Color barOvertime = Color.fromRGBO(253, 205, 22, 1); // #FDCD16
  static const Color overtimeFill = Color.fromRGBO(253, 205, 22, 0.18);

  // ── Present / success (green) ───────────────────────────────────────────────
  static const Color success = Color.fromRGBO(56, 142, 60, 1); // #388E3C
  static const Color successFill = Color.fromRGBO(151, 242, 148, 0.28);

  // ── Absent / alert (red) ────────────────────────────────────────────────────
  static const Color danger = Color.fromRGBO(211, 47, 47, 1); // #D32F2F
  static const Color dangerFill = Color.fromRGBO(240, 111, 111, 0.18);

  // ── Break (fresh, friendly teal — a "break", never grey) ─────────────
  static const Color breakTime = Color(0xFF1F9D8B);
  static const Color breakFill = Color.fromRGBO(31, 157, 139, 0.12);

  // ── Neutral ──────────────────────────────────────────────────────────────────
  static const Color neutral = Color.fromRGBO(136, 135, 128, 1);
  static const Color neutralFill = Color.fromRGBO(241, 239, 232, 1);

  // ── Avatar (punchy sky blue, white initials) ───────────────────────────────
  static const Color avatarBg = Color(0xFF87CEEB);
  static const Color avatarText = Colors.white;

  // ── Gradients ────────────────────────────────────────────────────────────────
  static const List<Color> _scaffold = [
    Color.fromRGBO(255, 255, 255, 1),
    Color.fromRGBO(251, 238, 250, 1),
  ];
  static const List<Color> _primary = [
    Color.fromRGBO(111, 140, 255, 1),
    Color.fromRGBO(156, 132, 255, 1),
  ];

  static const LinearGradient scaffoldGradient = LinearGradient(
    colors: _scaffold,
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: _primary,
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
