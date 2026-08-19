import 'package:flutter/material.dart';

/// ChildcareWow skeuomorphic design tokens.
///
/// A one-to-one port of the ChildcareWow design system CSS custom properties
/// (`tokens/colors.css`, `surfaces.css`, `elevation.css`, `radius.css`,
/// `typography.css`) into Dart. Names mirror the CSS variables so a value can
/// be traced straight back to the design source:
///
/// * `--color-teal-500`  -> [SkeuColors.teal500]
/// * `--surface-card`    -> [SkeuSurfaces.card]
/// * `--elev-2`          -> [SkeuElevation.elev2]
/// * `--well-md`         -> [SkeuElevation.wellMd]
/// * `--radius-field`    -> [SkeuRadius.field]
///
/// The material language: raised panels with a lit top bevel, recessed wells
/// for anything you type into, and rimmed keys that sink when pressed. Every
/// shadow is navy-tinted `rgb(10 28 93 / a)`, never pure black, and the light
/// always comes from directly above.
class SkeuColors {
  const SkeuColors._();

  // ---- Brand teal #27BEC1 — structure and secondary actions ----
  static const teal50 = Color(0xFFEEFAFA);
  static const teal100 = Color(0xFFD4F4F5);
  static const teal200 = Color(0xFFACEAEC);
  static const teal300 = Color(0xFF79DBDE);
  static const teal400 = Color(0xFF45CDD1);
  static const teal500 = Color(0xFF27BEC1);
  static const teal600 = Color(0xFF1D9B9E);
  static const teal700 = Color(0xFF1A7C7F);
  static const teal800 = Color(0xFF186265);
  static const teal900 = Color(0xFF12494B);

  // ---- Brand pink #F83D76 — THE recommended action ----
  static const pink50 = Color(0xFFFEF1F5);
  static const pink100 = Color(0xFFFDE2EC);
  static const pink200 = Color(0xFFFCC4D9);
  static const pink300 = Color(0xFFFB9CBE);
  static const pink400 = Color(0xFFFA699C);
  static const pink500 = Color(0xFFF83D76);
  static const pink600 = Color(0xFFE01B5D);
  static const pink700 = Color(0xFFBA124C);
  static const pink800 = Color(0xFF8E0E3A);

  // ---- Brand yellow #F9AD3A ("sun") — highlight, positivity ----
  static const sun50 = Color(0xFFFEFAF0);
  static const sun100 = Color(0xFFFDF0D5);
  static const sun200 = Color(0xFFFCE2AB);
  static const sun300 = Color(0xFFFBC971);
  static const sun400 = Color(0xFFF9AD3A);
  static const sun500 = Color(0xFFEF9518);
  static const sun600 = Color(0xFFD3790C);
  static const sun700 = Color(0xFF9D5809);
  static const sun800 = Color(0xFF714008);

  // ---- Brand green #13B167 — growth, support ----
  static const green100 = Color(0xFFD8F6E7);
  static const green200 = Color(0xFFAEEECF);
  static const green300 = Color(0xFF74DDAB);
  static const green400 = Color(0xFF3CC986);
  static const green500 = Color(0xFF13B167);
  static const green600 = Color(0xFF0E8F53);
  static const green700 = Color(0xFF0C7143);

  // ---- Brand orange #F37A42 — accent spark ----
  static const orange100 = Color(0xFFFDEADD);
  static const orange200 = Color(0xFFFBD3B9);
  static const orange300 = Color(0xFFF8AB84);
  static const orange400 = Color(0xFFF37A42);
  static const orange500 = Color(0xFFE05E26);
  static const orange600 = Color(0xFFB8481A);

  // ---- Brand purple #7D3BB7 — accent spark, decorative only ----
  static const purple100 = Color(0xFFF1E7FA);
  static const purple200 = Color(0xFFE0CBF4);
  static const purple300 = Color(0xFFC4A0E8);
  static const purple400 = Color(0xFFA06BD4);
  static const purple500 = Color(0xFF7D3BB7);

  /// Form-error red. Deliberately NOT brand pink: pink means "recommended
  /// action" and must never double as a warning.
  static const danger50 = Color(0xFFFEF3F2);
  static const danger100 = Color(0xFFFEE4E2);
  static const danger500 = Color(0xFFD92D20);
  static const danger600 = Color(0xFFB42318);

  // ---- Neutrals. Navy = headings, body text, trust. ----
  static const cream = Color(0xFFFEFEFE);
  static const cream100 = Color(0xFFF4F5FA);
  static const cream200 = Color(0xFFE9EBF5);
  static const ink = Color(0xFF0A1C5D);
  static const inkSoft = Color(0xFF4D5983);
  static const inkFaint = Color(0xFF8A93B2);
  static const navy = Color(0xFF0A1C5D);
  static const navy700 = Color(0xFF142A7A);
  static const navy900 = Color(0xFF061240);
  static const white = Color(0xFFFFFFFF);

  // ---- Semantic aliases: use these in product UI ----
  static const textHeading = ink;
  static const textBody = ink;
  static const textMuted = inkSoft;
  static const textFaint = inkFaint;
  static const textOnDark = white;
  static const textOnDarkMuted = teal100;
  static const textLink = teal700;
  static const textDanger = danger600;

  static const actionRecommended = pink600;
  static const actionPrimary = teal600;
  static const actionHighlight = sun400;

  static const borderHairline = Color(0x140A1C5D); // rgb(10 28 93 / .08)
  static const borderStrong = Color(0x290A1C5D); // rgb(10 28 93 / .16)
  static const borderField = Color(0x1F0A1C5D); // rgb(10 28 93 / .12)
  static const focusRing = teal500;
  static const selectionBg = pink200;

  static const statusOk = green500;
  static const statusOkSoft = green100;
  static const statusWarn = sun400;
  static const statusWarnSoft = sun100;
  static const statusBad = danger500;
  static const statusBadSoft = danger50;
  static const statusInfo = teal500;
  static const statusInfoSoft = teal100;
}

/// Surfaces — the skeuomorphic layer, **flat pass**.
///
/// v2 of the design ("WowCare Mobile Redesign v2") collapses every gradient
/// surface token to one flat colour. Depth is carried entirely by the lit top
/// bevel, the recessed wells and the navy ambient shadow from [SkeuElevation] —
/// there is no compensating darkening and no replacement gradient. Contrast was
/// checked at the flattened value, not at a gradient's lightest end, which is
/// why [faceTeal] flattens to teal-700 rather than teal-600.
///
/// The declared types stay [Gradient] so the ~60 call sites that pass these to
/// `BoxDecoration.gradient` are unchanged; each is simply a single-colour
/// gradient, which paints identically to a flat fill. Use the matching
/// `…Color` constant when you need the raw [Color].
class SkeuSurfaces {
  const SkeuSurfaces._();

  // ---- Neutral surfaces ----
  static const pageColor = Color(0xFFF2F4FB);
  static const cardColor = Color(0xFFFFFFFF);
  static const raisedColor = Color(0xFFFBFCFE);
  static const sunkenColor = Color(0xFFE8EBF6);
  static const fieldColor = Color(0xFFF3F5FC);
  static const navyColor = Color(0xFF0A1C5D);

  /// `--surface-rail`: the one flat navy that anchors the app. The v1
  /// navy-to-teal wash is gone.
  static const railColor = Color(0xFF0A1C5D);

  /// `--surface-page`
  static const page = LinearGradient(colors: [pageColor, pageColor]);

  /// `--surface-card`
  static const card = LinearGradient(colors: [cardColor, cardColor]);

  /// `--surface-raised`
  static const raised = LinearGradient(colors: [raisedColor, raisedColor]);

  /// `--surface-sunken`
  static const sunken = LinearGradient(colors: [sunkenColor, sunkenColor]);

  /// `--surface-field`
  static const field = LinearGradient(colors: [fieldColor, fieldColor]);

  /// `--surface-navy`
  static const navy = LinearGradient(colors: [navyColor, navyColor]);

  /// `--surface-rail`
  static const rail = LinearGradient(colors: [railColor, railColor]);

  static const glass = Color(0xD9FFFFFF); // rgb(255 255 255 / .85)

  // ---- Tinted surfaces — soft brand-washed panels ----
  static const tealSoftColor = Color(0xFFDDF5F6);
  static const pinkSoftColor = Color(0xFFFDE4EE);
  static const sunSoftColor = Color(0xFFFDEFD4);
  static const greenSoftColor = Color(0xFFDCF6E8);
  static const orangeSoftColor = Color(0xFFFDEADE);
  static const purpleSoftColor = Color(0xFFF1E7FA);

  static const tealSoft = LinearGradient(
    colors: [tealSoftColor, tealSoftColor],
  );
  static const pinkSoft = LinearGradient(
    colors: [pinkSoftColor, pinkSoftColor],
  );
  static const sunSoft = LinearGradient(colors: [sunSoftColor, sunSoftColor]);
  static const greenSoft = LinearGradient(
    colors: [greenSoftColor, greenSoftColor],
  );
  static const orangeSoft = LinearGradient(
    colors: [orangeSoftColor, orangeSoftColor],
  );
  static const purpleSoft = LinearGradient(
    colors: [purpleSoftColor, purpleSoftColor],
  );

  // ---- Pressable faces — solid brand-coloured objects ----
  /// pink-600, 4.6:1 with white.
  static const facePinkColor = SkeuColors.pink600;

  /// teal-700, 4.9:1 with white. Flattening forced the step down from
  /// teal-600: the v1 gradient only cleared AA at its light end.
  static const faceTealColor = SkeuColors.teal700;

  /// Navy text only — never white.
  static const faceSunColor = SkeuColors.sun400;

  /// Fills only; carries no text.
  static const faceGreenColor = SkeuColors.green500;
  static const faceOrangeColor = SkeuColors.orange500;
  static const faceNavyColor = SkeuColors.navy;
  static const faceNeutralColor = Color(0xFFFFFFFF);

  static const facePink = LinearGradient(
    colors: [facePinkColor, facePinkColor],
  );
  static const faceTeal = LinearGradient(
    colors: [faceTealColor, faceTealColor],
  );
  static const faceSun = LinearGradient(colors: [faceSunColor, faceSunColor]);
  static const faceGreen = LinearGradient(
    colors: [faceGreenColor, faceGreenColor],
  );
  static const faceOrange = LinearGradient(
    colors: [faceOrangeColor, faceOrangeColor],
  );
  static const faceNavy = LinearGradient(
    colors: [faceNavyColor, faceNavyColor],
  );
  static const faceNeutral = LinearGradient(
    colors: [faceNeutralColor, faceNeutralColor],
  );

  // ---- Overlays ----
  /// `--gloss-top: none`. The specular highlight was a gradient overlay, so
  /// the flat pass removes it. Kept as a fully transparent gradient rather
  /// than deleted so the render sites that layer it need no change.
  static const glossTop = LinearGradient(
    colors: [Color(0x00FFFFFF), Color(0x00FFFFFF)],
  );

  /// `--gloss-sheen: none`.
  static const glossSheen = LinearGradient(
    colors: [Color(0x00FFFFFF), Color(0x00FFFFFF)],
  );

  /// `--scrim-navy`: bottom-weighted scrim for text over imagery. Not part of
  /// the flat pass — it is a legibility scrim, not a surface.
  static const scrimNavy = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x000A1C5D), Color(0x8C0A1C5D)],
  );

  /// `--rail-brand`: pink -> sun -> teal -> green, the logo's own colour order.
  /// Hard-stopped into four equal flat bands, the way the design draws it.
  static const railBrand = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      SkeuColors.pink500,
      SkeuColors.pink500,
      SkeuColors.sun400,
      SkeuColors.sun400,
      SkeuColors.teal500,
      SkeuColors.teal500,
      SkeuColors.green500,
      SkeuColors.green500,
    ],
    stops: [0, .25, .25, .5, .5, .75, .75, 1],
  );

  /// `--blur-glass`. Retained as a token, but the flat pass uses no blurs, so
  /// nothing in the app reads it today.
  static const blurGlass = 12.0;
  static const blurBloom = 48.0;
}

/// Elevation — drop shadows, bevels, wells and button rims.
///
/// Flutter has no inset box-shadow, so the `--bevel-*` and `--well-*` tokens
/// are expressed as [SkeuInset] values and painted by `SkeuInnerShadow`
/// (see `skeu_inner_shadow.dart`).
class SkeuElevation {
  const SkeuElevation._();

  static const _navy = Color(0xFF0A1C5D);

  static Color _ink(double a) => _navy.withValues(alpha: a);

  // ---- Ambient drop shadows (raised objects) ----
  static List<BoxShadow> get elev1 => [
    BoxShadow(color: _ink(.05), offset: const Offset(0, 1), blurRadius: 1),
    BoxShadow(color: _ink(.06), offset: const Offset(0, 2), blurRadius: 4),
  ];

  static List<BoxShadow> get elev2 => [
    BoxShadow(color: _ink(.06), offset: const Offset(0, 2), blurRadius: 3),
    BoxShadow(
      color: _ink(.16),
      offset: const Offset(0, 8),
      blurRadius: 16,
      spreadRadius: -6,
    ),
  ];

  static List<BoxShadow> get elev3 => [
    BoxShadow(
      color: _ink(.08),
      offset: const Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: _ink(.22),
      offset: const Offset(0, 18),
      blurRadius: 32,
      spreadRadius: -12,
    ),
  ];

  static List<BoxShadow> get elev4 => [
    BoxShadow(
      color: _ink(.14),
      offset: const Offset(0, 10),
      blurRadius: 18,
      spreadRadius: -6,
    ),
    BoxShadow(
      color: _ink(.34),
      offset: const Offset(0, 30),
      blurRadius: 60,
      spreadRadius: -24,
    ),
  ];

  static List<BoxShadow> get elevOverlay => [
    BoxShadow(
      color: _ink(.4),
      offset: const Offset(0, 18),
      blurRadius: 40,
      spreadRadius: -16,
    ),
  ];

  // ---- Bevels: the 1px lit top edge / shaded bottom edge that make a
  // surface read as a solid object rather than a rectangle. ----
  static const bevelTop = [
    SkeuInset(color: Color(0xE6FFFFFF), offset: Offset(0, 1)),
  ];
  static const bevelTopSoft = [
    SkeuInset(color: Color(0x8CFFFFFF), offset: Offset(0, 1)),
  ];
  static const bevelBottom = [
    SkeuInset(color: Color(0x120A1C5D), offset: Offset(0, -1)),
  ];
  static const bevelEdge = [SkeuInset(color: Color(0x59FFFFFF), spread: 1)];
  static const bevelFull = [
    SkeuInset(color: Color(0xE6FFFFFF), offset: Offset(0, 1)),
    SkeuInset(color: Color(0x120A1C5D), offset: Offset(0, -1)),
  ];

  // ---- Wells — recessed. Inputs, tracks, search fields, progress troughs. ----
  static const wellSm = [
    SkeuInset(color: Color(0x170A1C5D), offset: Offset(0, 1), blur: 2),
    SkeuInset(color: Color(0x0F0A1C5D), spread: 1),
  ];
  static const wellMd = [
    SkeuInset(color: Color(0x1F0A1C5D), offset: Offset(0, 2), blur: 4),
    SkeuInset(color: Color(0x120A1C5D), spread: 1),
  ];
  static const wellLg = [
    SkeuInset(color: Color(0x260A1C5D), offset: Offset(0, 3), blur: 7),
    SkeuInset(color: Color(0x140A1C5D), spread: 1),
  ];

  // ---- Button rims — the solid darker under-edge you press away.
  // Depth 4px at rest, 1px pressed. ----
  static const rimDepth = 4.0;
  static const rimDepthPressed = 1.0;
  static const rimTeal = SkeuColors.teal800;
  static const rimPink = SkeuColors.pink800;
  static const rimSun = SkeuColors.sun600;
  static const rimGreen = SkeuColors.green700;
  static const rimNavy = SkeuColors.navy900;
  static const rimNeutral = Color(0xFFCCD1E4);

  static const shadowChip = [
    BoxShadow(
      color: Color(0x4D0A1C5D),
      offset: Offset(0, 8),
      blurRadius: 18,
      spreadRadius: -14,
    ),
  ];

  /// `--shadow-focus`: 0 0 0 3px rgb(39 190 193 / .45)
  static const focusRingColor = Color(0x7327BEC1);
  static const focusRingWidth = 3.0;
}

/// A single inset (inner) shadow — Flutter's missing `inset` box-shadow.
///
/// [spread] alone with a zero [offset]/[blur] reproduces the CSS
/// `inset 0 0 0 Npx <color>` ring idiom used for hairline field borders.
@immutable
class SkeuInset {
  const SkeuInset({
    required this.color,
    this.offset = Offset.zero,
    this.blur = 0,
    this.spread = 0,
  });

  final Color color;
  final Offset offset;
  final double blur;
  final double spread;
}

/// Radius. Nothing in the system uses sharp corners.
class SkeuRadius {
  const SkeuRadius._();

  static const sm = 8.0; // 0.5rem
  static const md = 12.0; // 0.75rem
  static const lg = 16.0; // 1rem
  static const xl = 17.6; // 1.1rem
  static const xxl = 22.4; // 1.4rem
  static const xxxl = 32.0; // 2rem
  static const banner = 36.0; // 2.25rem
  static const pill = 999.0;
  static const field = 14.4; // 0.9rem
}

/// Type scale. Poppins throughout; Semi Bold (600) headings, Medium (500) body.
class SkeuText {
  const SkeuText._();

  static const family = 'Poppins';

  static const weightBody = FontWeight.w500;
  static const weightMedium = FontWeight.w500;
  static const weightHeading = FontWeight.w600;
  static const weightBold = FontWeight.w700;
  static const weightEyebrow = FontWeight.w800;

  static const trackingHeading = -0.015; // em; multiply by fontSize for Flutter
  static const trackingEyebrow = 0.12;

  static TextStyle _s(
    double size,
    FontWeight weight, {
    Color color = SkeuColors.ink,
    double? height,
    double? letterSpacingEm,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacingEm == null ? null : letterSpacingEm * size,
  );

  /// 11px dense table meta.
  static TextStyle meta({Color color = SkeuColors.inkFaint}) =>
      _s(11, weightBody, color: color);

  /// 12px eyebrow / badge label, uppercase with wide tracking.
  static TextStyle eyebrow({Color color = SkeuColors.inkFaint}) =>
      _s(12, weightEyebrow, color: color, letterSpacingEm: trackingEyebrow);

  /// 12px caption.
  static TextStyle caption({
    Color color = SkeuColors.inkFaint,
    FontWeight weight = weightBody,
  }) => _s(12, weight, color: color);

  /// 13px small label.
  static TextStyle small({
    Color color = SkeuColors.inkSoft,
    FontWeight weight = weightBody,
  }) => _s(13, weight, color: color);

  /// 14px body / table body.
  static TextStyle body({
    Color color = SkeuColors.ink,
    FontWeight weight = weightBody,
  }) => _s(14, weight, color: color);

  /// 14px prose with generous leading.
  static TextStyle prose({Color color = SkeuColors.inkSoft}) =>
      _s(14, weightBody, color: color, height: 1.65);

  /// 15px field value / list title.
  static TextStyle field({
    Color color = SkeuColors.ink,
    FontWeight weight = weightBody,
  }) => _s(15, weight, color: color);

  /// 16px button label.
  static TextStyle button({Color color = SkeuColors.white}) =>
      _s(16, weightBold, color: color);

  /// 17px card title.
  static TextStyle title({
    Color color = SkeuColors.ink,
    FontWeight weight = weightHeading,
  }) => _s(17, weight, color: color);

  /// 20px screen heading.
  static TextStyle heading({Color color = SkeuColors.ink}) =>
      _s(20, weightHeading, color: color, letterSpacingEm: trackingHeading);

  /// 24px stat / panel heading.
  static TextStyle stat({
    Color color = SkeuColors.ink,
    FontWeight weight = weightBold,
  }) => _s(24, weight, color: color, letterSpacingEm: trackingHeading);

  /// 28px display (the sign-in wordmark).
  static TextStyle display({Color color = SkeuColors.ink}) =>
      _s(28, weightBold, color: color, letterSpacingEm: trackingHeading);
}

/// Motion. Presses are fast and slightly overshooting; panels ease.
class SkeuMotion {
  const SkeuMotion._();

  static const press = Duration(milliseconds: 90);
  static const quick = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 240);
  static const panel = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 380);

  /// `--anim-*` entrance/settle durations from the v2 design.
  static const fabIn = Duration(milliseconds: 560);
  static const confirmPop = Duration(milliseconds: 420);
  static const glowCycle = Duration(milliseconds: 3600);
  static const glowDelay = Duration(milliseconds: 1000);

  static const easeOut = Curves.easeOutCubic;
  static const easeInOut = Curves.easeInOutCubic;

  /// `--ease-spring: cubic-bezier(0.34, 1.56, 0.64, 1)`. The overshoot that
  /// makes a sliding indicator *settle* rather than stop dead, and the pop on
  /// the FAB and its confirmation.
  static const spring = Cubic(0.34, 1.56, 0.64, 1);
}
