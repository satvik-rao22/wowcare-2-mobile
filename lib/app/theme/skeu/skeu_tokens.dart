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

/// Surfaces — the skeuomorphic layer.
///
/// Every product surface is a shallow vertical gradient (light at the top,
/// because the light source is directly above) plus a bevel from
/// [SkeuElevation]. Gloss is a separate overlay so it can be layered on a
/// coloured face without recolouring it.
class SkeuSurfaces {
  const SkeuSurfaces._();

  /// `--surface-page`: radial-gradient(120% 90% at 50% -10%, ...)
  static const page = RadialGradient(
    center: Alignment(0, -1.2),
    radius: 1.2,
    colors: [Color(0xFFFFFFFF), Color(0xFFF6F7FC), Color(0xFFEFF1F9)],
    stops: [0, .45, 1],
  );

  /// `--surface-card`
  static const card = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FE)],
  );

  /// `--surface-raised`
  static const raised = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF2F4FB)],
  );

  /// `--surface-sunken`
  static const sunken = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFECEEF7), Color(0xFFF7F8FD)],
  );

  /// `--surface-field`: linear-gradient(180deg, #f2f4fb 0%, #ffffff 60%)
  static const field = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF2F4FB), Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
    stops: [0, .6, 1],
  );

  /// `--surface-navy`
  static const navy = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF142A7A), Color(0xFF0A1C5D)],
  );

  /// `--surface-rail`: the navy-to-teal header the sign-in screen sits on.
  static const rail = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF16307F), Color(0xFF0D2A6B), Color(0xFF186265)],
    stops: [0, .45, 1],
  );

  static const glass = Color(0xD9FFFFFF); // rgb(255 255 255 / .85)

  // ---- Tinted surfaces — soft brand-washed panels ----
  static const tealSoft = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF4FDFD), Color(0xFFD4F4F5)],
  );
  static const pinkSoft = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF6F9), Color(0xFFFDE2EC)],
  );
  static const sunSoft = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFCF4), Color(0xFFFDF0D5)],
  );
  static const greenSoft = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF4FDF8), Color(0xFFD8F6E7)],
  );
  static const orangeSoft = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF8F3), Color(0xFFFDEADD)],
  );
  static const purpleSoft = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFAF6FE), Color(0xFFF1E7FA)],
  );

  // ---- Pressable faces — solid brand-coloured objects ----
  static const facePink = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFA699C), Color(0xFFE01B5D), Color(0xFFD4175A)],
    stops: [0, .52, 1],
  );
  static const faceTeal = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF45CDD1), Color(0xFF1D9B9E), Color(0xFF1B9295)],
    stops: [0, .52, 1],
  );
  static const faceSun = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFBC971), Color(0xFFF9AD3A), Color(0xFFF2A52E)],
    stops: [0, .52, 1],
  );
  static const faceGreen = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF3CC986), Color(0xFF13B167), Color(0xFF10A25E)],
    stops: [0, .52, 1],
  );
  static const faceOrange = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8AB84), Color(0xFFF37A42), Color(0xFFEA6D33)],
    stops: [0, .52, 1],
  );
  static const faceNavy = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E3488), Color(0xFF0A1C5D)],
  );
  static const faceNeutral = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFEEF0F8)],
  );

  // ---- Overlays ----
  /// `--gloss-top`: the specular highlight laid over a coloured face.
  static const glossTop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x73FFFFFF), Color(0x14FFFFFF), Color(0x00FFFFFF)],
    stops: [0, .42, .6],
  );

  /// `--gloss-sheen`: diagonal sweep for larger glass surfaces.
  static const glossSheen = LinearGradient(
    begin: Alignment(-1, -.6),
    end: Alignment(1, .6),
    colors: [Color(0x00FFFFFF), Color(0x47FFFFFF), Color(0x00FFFFFF)],
    stops: [.3, .48, .62],
  );

  /// `--scrim-navy`: bottom-weighted scrim for text over imagery.
  static const scrimNavy = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x000A1C5D), Color(0x8C0A1C5D)],
  );

  /// `--rail-brand`: pink -> sun -> teal -> green, the logo's own colour order.
  static const railBrand = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      SkeuColors.pink500,
      SkeuColors.sun400,
      SkeuColors.teal500,
      SkeuColors.green500,
    ],
  );

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
  static const slow = Duration(milliseconds: 380);

  static const easeOut = Curves.easeOutCubic;
  static const easeInOut = Curves.easeInOutCubic;
}
