import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/theme/app_colors.dart';

/// Every colour a screen is allowed to use, named by the job it does.
///
/// This is the swap point. The design ships two colourways: L4 "warm tray,
/// cool cards", which is what the app renders, and D1 midnight navy, which is
/// fully designed but deliberately not applied. Because widgets name roles
/// rather than swatches, D1 lands later as one more const in this file and no
/// screen changes.
///
/// Field names mirror the design's own CSS custom properties, so a token in a
/// `.dc.html` frame traces straight to a field here: `--cardBorder` is
/// [cardBorder], `--onImpactSoft` is [onImpactSoft].
///
/// Read it through `context.colours`.
@immutable
class Colourway extends ThemeExtension<Colourway> {
  const Colourway({
    required this.page,
    required this.card,
    required this.cardBorder,
    required this.sub,
    required this.well,
    required this.altWell,
    required this.deepWell,
    required this.bar,
    required this.barLine,
    required this.divider,
    required this.dashedLine,
    required this.grabber,
    required this.scrim,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.bevel,
    required this.wellBevel,
    required this.inset,
    required this.insetShallow,
    required this.insetKeyDown,
    required this.ambientSoft,
    required this.ambient,
    required this.ambientDeep,
    required this.ambientLift,
    required this.key,
    required this.keyBorder,
    required this.keyRim,
    required this.pink,
    required this.pinkRim,
    required this.pinkBg,
    required this.onPinkTint,
    required this.onPink,
    required this.pinkGlow,
    required this.pinkKeyShadow,
    required this.impact,
    required this.onImpact,
    required this.onImpactSoft,
    required this.onImpactSub,
    required this.impactBevel,
    required this.impactShadow,
    required this.avatar,
    required this.onAvatar,
    required this.avatarShadow,
    required this.student,
    required this.studentBg,
    required this.studentRim,
    required this.studentLine,
    required this.staff,
    required this.staffBg,
    required this.staffFg,
    required this.staffLine,
    required this.task,
    required this.taskBg,
    required this.success,
    required this.successBg,
    required this.successFg,
    required this.successLine,
    required this.danger,
    required this.dangerBg,
    required this.dangerFg,
    required this.dangerLine,
    required this.neutralBg,
    required this.neutralFg,
    required this.signedIn,
    required this.signedOut,
    required this.absent,
    required this.notMarked,
    required this.track,
    required this.knob,
    required this.dotOff,
  });

  // --- Surfaces -------------------------------------------------------------

  /// The tray every screen sits on.
  final Color page;

  /// Cards, and anything raised off the tray.
  final Color card;
  final Color cardBorder;

  /// Bottom-sheet ground, inner rows, tab pills.
  final Color sub;

  /// Anything you type into, or a knob slides in.
  final Color well;

  /// Icon tiles, neutral chips, quiet rows.
  final Color altWell;

  /// Grabbers, deep troughs, the kiosk pad ground.
  final Color deepWell;

  /// Header bar and tab bar.
  final Color bar;
  final Color barLine;

  final Color divider;
  final Color dashedLine;
  final Color grabber;

  /// The dim behind an open bottom sheet.
  final Color scrim;

  // --- Ink ------------------------------------------------------------------

  /// Titles and values.
  final Color ink;

  /// Field labels, secondary values, body.
  final Color ink2;

  /// Sublines, placeholders, inactive nav, glyphs.
  final Color ink3;

  // --- Light and shadow -----------------------------------------------------

  /// The lit top bevel on every raised face.
  final Color bevel;

  /// The lit bottom edge inside a well.
  final Color wellBevel;

  /// Navy inset. Every well keeps a navy shadow, whatever the colourway.
  final Color inset;
  final Color insetShallow;
  final Color insetKeyDown;

  /// Warm-brown ambient shadow, four alphas deep. Never navy.
  final Color ambientSoft;
  final Color ambient;
  final Color ambientDeep;
  final Color ambientLift;

  // --- Keys -----------------------------------------------------------------

  /// A secondary key's face.
  final Color key;
  final Color keyBorder;

  /// The solid rim a neutral key sinks onto.
  final Color keyRim;

  // --- Pink · the one action per screen -------------------------------------

  final Color pink;
  final Color pinkRim;
  final Color pinkBg;

  /// Ink on a pink tint. Never [pink] on [pinkBg].
  final Color onPinkTint;
  final Color onPink;
  final Color pinkGlow;
  final Color pinkKeyShadow;

  // --- Impact · the one fact that outranks the rest -------------------------

  final Color impact;
  final Color onImpact;
  final Color onImpactSoft;
  final Color onImpactSub;
  final Color impactBevel;
  final Color impactShadow;

  // --- Avatars --------------------------------------------------------------

  final Color avatar;
  final Color onAvatar;
  final Color avatarShadow;

  // --- Domain · teal is students, sun is staff, violet is M17 tasks ---------

  final Color student;
  final Color studentBg;
  final Color studentRim;
  final Color studentLine;

  final Color staff;
  final Color staffBg;
  final Color staffFg;
  final Color staffLine;

  final Color task;
  final Color taskBg;

  // --- Status ---------------------------------------------------------------

  final Color success;
  final Color successBg;
  final Color successFg;
  final Color successLine;

  final Color danger;
  final Color dangerBg;
  final Color dangerFg;
  final Color dangerLine;

  /// Not Marked, view-only, neutral tags.
  final Color neutralBg;
  final Color neutralFg;

  // --- Attendance dots ------------------------------------------------------

  final Color signedIn;
  final Color signedOut;
  final Color absent;
  final Color notMarked;

  // --- Controls -------------------------------------------------------------

  final Color track;
  final Color knob;
  final Color dotOff;

  /// L4 "warm tray, cool cards". The colourway the app renders.
  static const Colourway l4 = Colourway(
    page: AppColors.page,
    card: AppColors.card,
    cardBorder: AppColors.cardHairline,
    sub: AppColors.sub,
    well: AppColors.well,
    altWell: AppColors.altWell,
    deepWell: AppColors.deepWell,
    bar: AppColors.card,
    barLine: AppColors.barLine,
    divider: AppColors.divider,
    dashedLine: AppColors.dashedLine,
    grabber: AppColors.grabber,
    scrim: AppColors.scrim,
    ink: AppColors.navy,
    ink2: AppColors.ink2,
    ink3: AppColors.ink3,
    bevel: AppColors.bevel,
    wellBevel: AppColors.wellBevel,
    inset: AppColors.insetNavy,
    insetShallow: AppColors.insetNavyShallow,
    insetKeyDown: AppColors.insetNavyKeyDown,
    ambientSoft: AppColors.ambient28,
    ambient: AppColors.ambient45,
    ambientDeep: AppColors.ambient50,
    ambientLift: AppColors.ambient60,
    key: AppColors.card,
    keyBorder: AppColors.keyBorder,
    keyRim: AppColors.keyRim,
    pink: AppColors.pink600,
    pinkRim: AppColors.pinkRim,
    pinkBg: AppColors.pinkBg,
    onPinkTint: AppColors.onPinkTint,
    onPink: AppColors.warmWhite,
    pinkGlow: AppColors.pinkGlow,
    pinkKeyShadow: AppColors.pinkKeyShadow,
    impact: AppColors.navy,
    onImpact: AppColors.warmWhite,
    onImpactSoft: AppColors.onImpactSoft,
    onImpactSub: AppColors.onImpactSub,
    impactBevel: AppColors.bevelOnImpact,
    impactShadow: AppColors.impactShadow,
    avatar: AppColors.navy,
    onAvatar: AppColors.warmWhite,
    avatarShadow: AppColors.avatarShadow,
    student: AppColors.teal700,
    studentBg: AppColors.tealBg,
    studentRim: AppColors.tealRim,
    studentLine: AppColors.tealLine,
    staff: AppColors.sun400,
    staffBg: AppColors.sunBg,
    staffFg: AppColors.sunFg,
    staffLine: AppColors.sunLine,
    task: AppColors.violet,
    taskBg: AppColors.violetBg,
    success: AppColors.greenSolid,
    successBg: AppColors.greenBg,
    successFg: AppColors.greenFg,
    successLine: AppColors.greenLine,
    danger: AppColors.dangerSolid,
    dangerBg: AppColors.dangerBg,
    dangerFg: AppColors.dangerFg,
    dangerLine: AppColors.dangerLine,
    neutralBg: AppColors.altWell,
    neutralFg: AppColors.ink2,
    signedIn: AppColors.greenSolid,
    signedOut: AppColors.ink2,
    absent: AppColors.dangerSolid,
    notMarked: AppColors.notMarkedDot,
    track: AppColors.well,
    knob: AppColors.card,
    dotOff: AppColors.dotOff,
  );

  /// A colourway is swapped whole, never blended: half-way between a warm tray
  /// and midnight navy is a surface that exists in neither design. So this
  /// snaps rather than interpolating, which is also what makes it safe to hold
  /// [Colourway] as a flat set of const swatches.
  @override
  Colourway lerp(ThemeExtension<Colourway>? other, double t) =>
      other is Colourway && t >= .5 ? other : this;

  /// A colourway is a complete, internally consistent set. Overriding one
  /// colour of it is how the "colour carries meaning" rule gets broken by
  /// accident, so there is deliberately nothing to override.
  @override
  Colourway copyWith() => this;
}
