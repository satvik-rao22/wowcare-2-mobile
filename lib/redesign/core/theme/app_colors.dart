import 'package:flutter/material.dart';

/// The raw swatches, retyped from `WowCare Design Components.dc.html`
/// (section 01, "The palette") on the finalized L4 "warm tray, cool cards"
/// colourway.
///
/// **Nothing outside `colourway.dart` reads this class.** Widgets resolve
/// colour through the [Colourway] theme extension, which names these swatches
/// by the job they do. Keeping the hexes in one place is what lets the D1
/// midnight-navy colourway drop in later without a screen changing.
///
/// The earlier `wowcare-skeumorph` branch is a generation stale and its values
/// must not be trusted: its page ground is `#F2F4FB` where L4 is `#FBF8F2`,
/// and its ambient shadows are navy where L4 is warm brown.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Pink · the action. One per screen.
  // ---------------------------------------------------------------------------

  /// Primary key, FAB, active nav, links, badges.
  static const Color pink600 = Color(0xFFE01B5D);

  /// The 3 to 4px rim a pink key sinks onto.
  static const Color pinkRim = Color(0xFFA10F45);

  /// Active tab-bar tile, selected sidebar row.
  static const Color pinkBg = Color(0xFFFBDEE9);

  /// Ink on a pink tint. Never [pink600] on a tint.
  static const Color onPinkTint = Color(0xFFBA124C);

  // ---------------------------------------------------------------------------
  // Navy · ink and impact.
  // ---------------------------------------------------------------------------

  /// Titles, values, impact cards, selected chip.
  static const Color navy = Color(0xFF0A1C5D);

  /// Field labels, secondary values, body.
  static const Color ink2 = Color(0xFF4D5983);

  /// Sublines, placeholders, inactive nav, glyphs.
  static const Color ink3 = Color(0xFF8A93B2);

  /// The only white in the app: key text and SVG strokes.
  static const Color warmWhite = Color(0xFFFFFAF2);

  // ---------------------------------------------------------------------------
  // Domain colour · teal is students, sun is staff, violet is M17 tasks.
  // ---------------------------------------------------------------------------

  /// Student counts, roster headers, capacity fill.
  static const Color teal700 = Color(0xFF1A7C7F);

  /// Student avatar, Active students tile, tags.
  static const Color tealBg = Color(0xFFD2F1F2);
  static const Color tealRim = Color(0xFF12595B);
  static const Color tealLine = Color.fromRGBO(39, 190, 193, .35);

  /// Staff section badge, shift blocks.
  static const Color sun400 = Color(0xFFF9AD3A);

  /// Staff avatar, Upcoming pill, break rows.
  static const Color sunBg = Color(0xFFFBEBCF);
  static const Color sunFg = Color(0xFF8A5208);
  static const Color sunLine = Color.fromRGBO(249, 173, 58, .35);

  /// Module 17 tasks only.
  static const Color violet = Color(0xFF6D4AC9);
  static const Color violetBg = Color(0xFFE8E0FB);

  // ---------------------------------------------------------------------------
  // Status.
  // ---------------------------------------------------------------------------

  /// Signed In dot, clocked-in ring, toggle on.
  static const Color greenSolid = Color(0xFF0E8F53);

  /// In Ratio, Signed In, Active, On file.
  static const Color greenBg = Color(0xFFD3F4E4);
  static const Color greenFg = Color(0xFF0C7143);
  static const Color greenLine = Color.fromRGBO(19, 177, 103, .28);

  /// Absent dot, destructive key, field error.
  static const Color dangerSolid = Color(0xFFD92D20);

  /// Not in Ratio, Absent, Log out, refusals.
  static const Color dangerBg = Color(0xFFFBDEDC);
  static const Color dangerFg = Color(0xFFB42318);
  static const Color dangerLine = Color.fromRGBO(217, 45, 32, .22);

  /// The Not Marked attendance dot. Quieter than [ink3], which it sits beside.
  static const Color notMarkedDot = Color(0xFFBFC9E2);

  // ---------------------------------------------------------------------------
  // Surfaces · a warm tray carrying cool cards.
  // ---------------------------------------------------------------------------

  /// Every screen ground.
  static const Color page = Color(0xFFFBF8F2);

  /// Cards, header bar, tab bar, secondary key faces.
  static const Color card = Color(0xFFFBFCFF);

  /// Bottom-sheet ground, inner rows, tab pills.
  static const Color sub = Color(0xFFEFF2FB);

  /// Search, text fields, tracks, troughs, disabled keys.
  static const Color well = Color(0xFFE5EAF7);

  /// Icon tiles, neutral chips, quiet rows.
  static const Color altWell = Color(0xFFEDF1FA);

  /// Grabbers, deep troughs, kiosk pad ground.
  static const Color deepWell = Color(0xFFD8E0F2);

  /// The solid rim under every neutral key.
  static const Color keyRim = Color(0xFFCFD8EC);

  /// Device case. Presentation chrome in the design frames, not app UI.
  static const Color bezel = Color(0xFFCAC2B4);

  // ---------------------------------------------------------------------------
  // Lines, bevels and shadow.
  //
  // Ambient shadows are warm brown; inset shadows stay navy. Never the reverse.
  // ---------------------------------------------------------------------------

  /// The lit top bevel on every raised face.
  static const Color bevel = Color.fromRGBO(255, 255, 255, .95);

  /// The bevel on a navy or pink face, which is warm rather than pure white.
  static const Color bevelOnImpact = Color.fromRGBO(255, 250, 240, .22);
  static const Color bevelOnPink = Color.fromRGBO(255, 250, 240, .3);

  /// The lit bottom edge inside a well.
  static const Color wellBevel = Color.fromRGBO(255, 255, 255, .8);

  static const Color cardHairline = Color.fromRGBO(10, 28, 93, .09);
  static const Color keyBorder = Color.fromRGBO(10, 28, 93, .1);
  static const Color barLine = Color.fromRGBO(10, 28, 93, .07);
  static const Color divider = Color.fromRGBO(10, 28, 93, .05);
  static const Color dashedLine = Color.fromRGBO(10, 28, 93, .16);

  /// The grabber pill on a bottom sheet.
  static const Color grabber = Color.fromRGBO(10, 28, 93, .18);

  /// Navy inset. Every well keeps a navy shadow.
  static const Color insetNavy = Color.fromRGBO(10, 28, 93, .14);
  static const Color insetNavyShallow = Color.fromRGBO(10, 28, 93, .13);
  static const Color insetNavyKeyDown = Color.fromRGBO(10, 28, 93, .15);

  /// Warm-brown ambient drop shadow, at the alphas the design uses.
  static const Color ambient28 = Color.fromRGBO(63, 45, 20, .28);
  static const Color ambient45 = Color.fromRGBO(63, 45, 20, .45);
  static const Color ambient50 = Color.fromRGBO(63, 45, 20, .5);
  static const Color ambient60 = Color.fromRGBO(63, 45, 20, .6);

  /// An off dot, and the shadow under a toggle knob.
  static const Color dotOff = Color.fromRGBO(63, 45, 20, .25);

  static const Color onImpactSoft = Color.fromRGBO(255, 250, 240, .6);
  static const Color onImpactSub = Color.fromRGBO(255, 250, 240, .7);

  /// The glow under a pink key, and the pink key's own ambient shadow.
  static const Color pinkGlow = Color.fromRGBO(224, 27, 93, .45);
  static const Color pinkKeyShadow = Color.fromRGBO(224, 27, 93, .8);

  static const Color impactShadow = Color.fromRGBO(10, 28, 93, .7);
  static const Color avatarShadow = Color.fromRGBO(10, 28, 93, .5);

  /// The dim behind an open bottom sheet.
  static const Color scrim = Color.fromRGBO(10, 28, 93, .32);
}
