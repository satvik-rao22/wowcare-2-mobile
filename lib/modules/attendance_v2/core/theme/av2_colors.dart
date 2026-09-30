import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

/// Semantic colour tokens for the Attendance V2 module.
///
/// Every value resolves to an [AppPalette] role, so this module re-skins with
/// the rest of the app instead of carrying its own look. It was written
/// against the previous palette (plum `#573353`, blue `#5978F7`, a pink page
/// ground and two gradients) and is pointed at the flat skin here — the names
/// below are the module's own vocabulary, kept so its 60-odd widgets did not
/// all have to be rewritten, but none of them declares a colour any more.
class Av2Colors {
  const Av2Colors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color primary = AppPalette.textPrimary;
  static const Color theme = AppPalette.brand;
  static const Color secondary = AppPalette.actionSecondary;
  static const Color accent = AppPalette.actionHighlight;

  // ── Surfaces ─────────────────────────────────────────────────────────────
  static const Color surface = AppPalette.surfaceCard;
  static const Color surfaceMuted = AppPalette.surfaceField;
  static const Color pageBackground = AppPalette.surfacePage;

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = AppPalette.textPrimary;
  static const Color textSecondary = AppPalette.textSecondary;
  static const Color textTertiary = AppPalette.textMuted;

  // ── Borders ──────────────────────────────────────────────────────────────
  static const Color border = AppPalette.borderHairline;
  static const Color borderStrong = AppPalette.border;

  // ── Regular hours ────────────────────────────────────────────────────────
  static const Color regular = AppPalette.actionSecondary;
  static const Color regularFill = AppPalette.domainStaffSoft;
  static const Color barRegular = AppPalette.actionSecondary;

  // ── Overtime ─────────────────────────────────────────────────────────────
  static const Color overtime = AppPalette.statusWarning;
  static const Color barOvertime = AppPalette.statusWarning;
  static const Color overtimeFill = AppPalette.statusWarningSoft;

  // ── Present / success ────────────────────────────────────────────────────
  static const Color success = AppPalette.statusSuccess;
  static const Color successFill = AppPalette.statusSuccessSoft;

  // ── Absent / alert ───────────────────────────────────────────────────────
  static const Color danger = AppPalette.statusError;
  static const Color dangerFill = AppPalette.statusErrorSoft;

  // ── Break ────────────────────────────────────────────────────────────────
  static const Color breakTime = AppPalette.actionSecondary;
  static const Color breakFill = AppPalette.domainStaffSoft;

  // ── Neutral ──────────────────────────────────────────────────────────────
  static const Color neutral = AppPalette.textMuted;
  static const Color neutralFill = AppPalette.surfaceMuted;

  /// Ink on a saturated face: a primary key's label, a selected chip's
  /// label, an avatar's initials. Warm white — the flat skin has no pure one.
  static const Color onPrimary = AppPalette.textOnDark;

  // ── Avatar ───────────────────────────────────────────────────────────────
  static const Color avatarBg = AppPalette.actionSecondary;
  static const Color avatarText = AppPalette.textOnDark;

  // ── Retired gradients ────────────────────────────────────────────────────
  // The skin is flat, so both former ramps are now the single face they
  // resolve to. Kept as names (not deleted) because the widgets that used
  // them read as "the page ground" and "the primary fill", which is exactly
  // what these still mean.

  /// The page ground the detail scaffold paints. Was a white→pink ramp.
  static const Color scaffoldFill = AppPalette.surfacePage;

  /// The fill of a primary key or a selected chip. Was a blue→violet ramp.
  static const Color primaryFill = AppPalette.brand;
}
