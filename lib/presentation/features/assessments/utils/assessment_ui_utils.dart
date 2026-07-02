import 'package:flutter/material.dart';

/// One switchable colour theme for the Assessments module. Two are shipped:
/// [AssessmentUi.theme1] (the original indigo "1.0" look) and
/// [AssessmentUi.theme2] (the "2.0" look, where **teal `#18B5AF` is primary**
/// — backgrounds, heroes, navigation, badges, selection states — and **pink
/// `#E2528C` is reserved for buttons/CTAs and other actionable controls**;
/// orange `#FCC33D` is used sparingly, confined to the domain colour-coding
/// pool). Every themable colour the module uses lives here; neutrals (ink,
/// hairlines) are shared.
class AssessmentPalette {
  const AssessmentPalette({
    required this.name,
    required this.pageBackground,
    required this.brand,
    required this.brandDeep,
    required this.brandSoft,
    required this.brandSoftBorder,
    required this.brandFaint,
    required this.brandFaintFg,
    required this.secondary,
    required this.accent,
    required this.accentGradientColors,
    required this.accentFaint,
    required this.accentFaintFg,
    required this.chipBg,
    required this.chipBorder,
    required this.chipFg,
    required this.studentGradientColors,
    required this.classroomGradientColors,
    required this.schoolGradientColors,
    required this.classroomCardGradients,
    required this.domainPalette,
    required this.statAccents,
  });

  /// Short version label shown in the theme switcher ("1.0" / "2.0").
  final String name;

  /// Module page background behind the cards.
  final Color pageBackground;

  /// Primary brand colour — the dominant colour: backgrounds, heroes,
  /// navigation, badges, banners, selection/menu state. NOT for buttons —
  /// see [accent].
  final Color brand;

  /// Darker brand tone used for text sitting on [brandSoft].
  final Color brandDeep;

  /// Soft brand-tinted fill (chips, selected rows, info banners).
  final Color brandSoft;

  /// Border that pairs with [brandSoft].
  final Color brandSoftBorder;

  /// Disabled/inactive brand fill and its foreground.
  final Color brandFaint;
  final Color brandFaintFg;

  /// Secondary accent (classrooms tab affordances).
  final Color secondary;

  /// Action colour — filled buttons, FABs, "+Add" affordances, focused
  /// inputs, the theme switcher's selected segment. Reserved for controls the
  /// user presses to *do* something, kept distinct from [brand] so CTAs pop
  /// against the primary colour rather than blending into it.
  final Color accent;

  /// Two-stop gradient for [accent] surfaces (flat/solid on 2.0 — see
  /// [AssessmentUi.theme2] doc — a real gradient on 1.0).
  final List<Color> accentGradientColors;

  /// Disabled/inactive [accent] fill and its foreground.
  final Color accentFaint;
  final Color accentFaintFg;

  /// Assignment-chip family (age-group chips on parameter cards).
  final Color chipBg;
  final Color chipBorder;
  final Color chipFg;

  /// Per-entity avatar/hero gradients.
  final List<Color> studentGradientColors;
  final List<Color> classroomGradientColors;
  final List<Color> schoolGradientColors;

  /// Rotating gradients for classroom list cards.
  final List<List<Color>> classroomCardGradients;

  /// Deterministic per-domain accent pool.
  final List<Color> domainPalette;

  /// School-dashboard stat-tile accents (classrooms / students / domains).
  final List<Color> statAccents;
}

/// Presentation helpers for the Assessments module: responsive breakpoints,
/// score-badge colour logic, the fixed scale-point palette, accent colours
/// and the per-entity avatar gradients that give the module its colour.
abstract final class AssessmentUi {
  const AssessmentUi._();

  // ------------------------------------------------------- switchable theme
  //
  // The module ships two colour themes, toggled from the top header. All
  // themable colours below read from [palette]; the cubit flips it (and
  // re-emits state so the whole shell rebuilds). Neutral ink/hairline tones
  // are shared by both themes.

  /// The original "1.0" look: brand indigo on a soft lilac page.
  static const AssessmentPalette theme1 = AssessmentPalette(
    name: '1.0',
    pageBackground: Color(0xFFF5F4FB),
    brand: Color(0xFF5978F7),
    brandDeep: Color(0xFF3F58C9),
    brandSoft: Color(0xFFEEF1FF),
    brandSoftBorder: Color(0xFFDCE2FF),
    brandFaint: Color(0xFFE3E8FF),
    brandFaintFg: Color(0xFF9BA8E0),
    secondary: Color(0xFF8B5CF6),
    // 1.0 never distinguished a separate action colour — accent mirrors
    // brand so every existing 1.0 surface renders pixel-identical.
    accent: Color(0xFF5978F7),
    accentGradientColors: [Color(0xFF5978F7), Color(0xFF9C6BF7)],
    accentFaint: Color(0xFFE3E8FF),
    accentFaintFg: Color(0xFF9BA8E0),
    chipBg: Color(0xFFEFF6FF),
    chipBorder: Color(0xFFBFDBFE),
    chipFg: Color(0xFF1D4ED8),
    studentGradientColors: [Color(0xFF5978F7), Color(0xFF9C6BF7)],
    classroomGradientColors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
    schoolGradientColors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
    classroomCardGradients: [
      [Color(0xFF8B5CF6), Color(0xFF6366F1)],
      [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
      [Color(0xFF34B3A0), Color(0xFF3B82F6)],
      [Color(0xFF9C6BF7), Color(0xFF5978F7)],
    ],
    domainPalette: [
      Color(0xFF6366F1), // indigo
      Color(0xFF8B5CF6), // violet
      Color(0xFF3B82F6), // blue
      Color(0xFF0EA5E9), // sky
      Color(0xFF14B8A6), // teal
      Color(0xFFF59E0B), // amber
      Color(0xFFEC4899), // pink
      Color(0xFF10B981), // green
    ],
    statAccents: [Color(0xFF5978F7), Color(0xFF8B5CF6), Color(0xFF3B82F6)],
  );

  /// The "2.0" look: **teal `#18B5AF` is primary** (backgrounds, heroes, nav,
  /// badges, banners, selection state), **pink `#E2528C` is the action colour**
  /// (buttons, FABs, "+Add" affordances, focused inputs — kept off the
  /// primary surfaces so CTAs pop), and **orange `#FCC33D` is used sparingly**
  /// — confined to a single slot in [domainPalette] and nowhere else.
  ///
  /// 2.0 uses **flat fills, not gradients**: every gradient slot lists the
  /// same colour twice (a two-identical-stop LinearGradient paints solid), so
  /// heroes/CTAs render in the exact palette colours with no blended tones.
  static const AssessmentPalette theme2 = AssessmentPalette(
    name: '2.0',
    pageBackground: Color(0xFFF2FBFA),
    brand: Color(0xFF18B5AF),
    brandDeep: Color(0xFF0E7A75),
    brandSoft: Color(0xFFE1F5F4),
    brandSoftBorder: Color(0xFFBFE9E6),
    brandFaint: Color(0xFFD7F1EF),
    brandFaintFg: Color(0xFF7FBFBB),
    secondary: Color(0xFFE2528C),
    accent: Color(0xFFE2528C),
    accentGradientColors: [Color(0xFFE2528C), Color(0xFFE2528C)],
    accentFaint: Color(0xFFF9DCE7),
    accentFaintFg: Color(0xFFD998B4),
    chipBg: Color(0xFFE1F5F4),
    chipBorder: Color(0xFFBFE9E6),
    chipFg: Color(0xFF0E7A75),
    studentGradientColors: [Color(0xFF18B5AF), Color(0xFF18B5AF)],
    classroomGradientColors: [Color(0xFF18B5AF), Color(0xFF18B5AF)],
    schoolGradientColors: [Color(0xFF18B5AF), Color(0xFF18B5AF)],
    classroomCardGradients: [
      [Color(0xFF18B5AF), Color(0xFF18B5AF)],
      [Color(0xFFE2528C), Color(0xFFE2528C)],
      [Color(0xFF18B5AF), Color(0xFF18B5AF)],
      [Color(0xFF18B5AF), Color(0xFF18B5AF)],
    ],
    domainPalette: [
      Color(0xFF18B5AF), // teal (primary)
      Color(0xFFE2528C), // pink (accent)
      Color(0xFF18B5AF),
      Color(0xFFE2528C),
      Color(0xFF18B5AF),
      Color(0xFFE2528C),
      Color(0xFF18B5AF),
      Color(0xFFFCC33D), // orange — the one deliberately sparing use
    ],
    statAccents: [Color(0xFF18B5AF), Color(0xFFE2528C), Color(0xFF18B5AF)],
  );

  /// The active theme. Flipped by `AssessmentsCubit.setThemeV2`, which then
  /// re-emits state so every widget in the module shell rebuilds with the
  /// new colours.
  static AssessmentPalette palette = theme1;

  static bool get isThemeV2 => identical(palette, theme2);

  static void setTheme({required bool v2}) {
    palette = v2 ? theme2 : theme1;
  }

  // ------------------------------------------------------- neutral palette
  //
  // The redesign's surface/ink palette (from the standalone mock): white
  // cards, deep-plum ink and a muted lavender for secondary text. Shared by
  // both themes; the page tint and brand colours come from [palette].

  /// Module page background — soft tint behind the cards (themed).
  static Color get pageBackground => palette.pageBackground;

  /// Primary text colour (deep plum).
  static const Color ink = Color(0xFF2E2740);

  /// Secondary / muted text colour (lavender-grey).
  static const Color inkMuted = Color(0xFF9089A0);

  /// Hairline / divider colour used between rows in trees and lists.
  static const Color hairline = Color(0xFFEDEBF4);

  /// Primary brand colour of the active theme.
  static Color get brand => palette.brand;

  /// Action colour of the active theme — use for buttons/CTAs, not for
  /// backgrounds or navigation (see [AssessmentPalette.accent]).
  static Color get accent => palette.accent;

  // ----------------------------------------------------------- breakpoints

  /// Phones.
  static const double mobileMax = 600;

  /// Tablets / small web.
  static const double tabletMax = 1024;

  static bool isMobile(double width) => width < mobileMax;
  static bool isTablet(double width) => width >= mobileMax && width < tabletMax;
  static bool isDesktop(double width) => width >= tabletMax;

  // -------------------------------------------------- mobile design tokens

  /// Minimum comfortable tap target (Material/HIG ≥ 44–48dp). Interactive
  /// affordances in the module size to at least this so they're thumb-friendly.
  static const double minTouchTarget = 48;

  /// Standard screen edge inset for the module's scrollable bodies.
  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(16, 16, 16, 32);

  /// A soft, flat "native card" surface — replaces the old web-dashboard look
  /// (flat white + grey hairline border + tight drop shadow) with a single
  /// diffuse, lifted shadow and no hard border, so cards read like physical
  /// mobile surfaces. Pass [accent] to tint the lift toward a score colour.
  static BoxDecoration softSurface({
    double radius = 20,
    Color? color,
    Color? accent,
  }) {
    final lift = (accent ?? const Color(0xFF1B2559)).withValues(alpha: 0.06);
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(color: lift, blurRadius: 24, offset: const Offset(0, 10)),
      ],
    );
  }

  /// Card-grid column count that adapts gracefully across devices.
  static int gridColumns(double width) {
    if (width >= 1280) return 4;
    if (width >= tabletMax) return 3;
    if (width >= mobileMax) return 2;
    return 1;
  }

  /// Constrains very wide web layouts so content stays readable.
  static double contentMaxWidth(double width) => width >= 1400 ? 1320 : width;

  // ----------------------------------------------------- responsive tokens
  //
  // The module is mobile-first but reflows on tablet/web: edge insets and card
  // padding breathe, headings grow, list-card heights and avatars scale up, and
  // profiles split into two columns (main content beside the insights rail)
  // instead of one tall scroll. These helpers are driven by the *available*
  // width (from a LayoutBuilder / MediaQuery) so a panel inside a two-column
  // layout sizes to its own box, not the whole window.

  /// Minimum canvas width at which profile screens place the insights rail
  /// (radar + scale guide) beside the main content instead of stacked below.
  static const double twoColumnMin = 900;

  static bool useTwoColumn(double width) => width >= twoColumnMin;

  /// Screen edge inset that grows with the canvas (phones 16 → web 32).
  static double gutter(double width) =>
      width >= tabletMax ? 32 : (width >= mobileMax ? 24 : 16);

  /// Scrollable-body padding using the responsive [gutter] (extra bottom room
  /// so the last card clears the navigation bar).
  static EdgeInsets bodyPadding(double width) {
    final g = gutter(width);
    return EdgeInsets.fromLTRB(g, g, g, g + 16);
  }

  /// Inner padding for large surface cards (table, radar, guide, stats).
  static double cardPadding(double width) => width >= tabletMax ? 24 : 18;

  /// Gap between stacked sections; opens up on larger canvases.
  static double sectionGap(double width) => width >= tabletMax ? 24 : 16;

  /// Section heading above lists/dashboards — grows with the canvas.
  static TextStyle sectionTitleStyle(double width) => TextStyle(
        fontSize: width >= tabletMax ? 24 : (width >= mobileMax ? 21 : 18),
        fontWeight: FontWeight.w800,
        height: 1.1,
      );

  /// Card / panel heading — a touch larger on tablet+.
  static TextStyle cardTitleStyle(double width) => TextStyle(
        fontSize: width >= mobileMax ? 18 : 16,
        fontWeight: FontWeight.w700,
      );

  /// Fixed grid-card height. Cards get *narrower* as columns are added, so they
  /// need a little more height on wide canvases to fit the wrapped score badges.
  static double cardExtent(double width) =>
      width >= tabletMax ? 244 : (width >= mobileMax ? 224 : 206);

  /// Avatar radius for list cards / headers; scales up so avatars don't look
  /// diminished on large displays.
  static double avatarRadius(double width, {double base = 22}) =>
      width >= tabletMax ? base + 8 : (width >= mobileMax ? base + 4 : base);

  /// Wrap/grid spacing inside cards (tight on phones, roomier on web).
  static double wrapSpacing(double width) => width >= tabletMax ? 10 : 6;

  /// 1–5 scale-button edge length, larger on web where there's room and a
  /// mouse target benefits from being bigger.
  static double scaleButtonSize(double width, {bool compact = false}) {
    final base = compact ? 42.0 : 48.0;
    if (width >= tabletMax) return base + 10;
    if (width >= mobileMax) return base + 4;
    return base;
  }

  /// Radar chart height derived from its own available width: roughly square
  /// (allowing for the label gutter) but clamped so it never gets tiny on a
  /// phone or absurdly tall in a wide panel.
  static double radarHeight(double width) =>
      (width * 0.82).clamp(300.0, 460.0);

  // ------------------------------------------------------- score badge colour

  /// Domain/average score badge colours (PRD BR-AS-03): green ≥ 4,
  /// yellow 2–3 (i.e. ≥ 2 and < 4), red < 2. Used for both individual domain
  /// scores and computed averages.
  static ScoreBadgeStyle badgeStyle(double? score) {
    if (score == null) {
      // "Not yet assessed" reads as a calm, on-brand tint rather than dead
      // grey — sparsely-assessed students no longer look washed-out.
      return ScoreBadgeStyle(
        background: palette.brandSoft,
        foreground: palette.brand,
        border: palette.brandSoftBorder,
      );
    }
    if (score >= 4) {
      return const ScoreBadgeStyle(
        background: Color(0xFFECFDF3),
        foreground: Color(0xFF15803D),
        border: Color(0xFFBBF7D0),
      );
    }
    if (score >= 2) {
      return const ScoreBadgeStyle(
        background: Color(0xFFFEFCE8),
        foreground: Color(0xFFA16207),
        border: Color(0xFFFEF08A),
      );
    }
    return const ScoreBadgeStyle(
      background: Color(0xFFFEF2F2),
      foreground: Color(0xFFB91C1C),
      border: Color(0xFFFECACA),
    );
  }

  /// Per-point scale palette (based on PRD §17.2): 1 red, 2 orange, 3 gold,
  /// 4 light-green, 5 green. Used by the Assessment Guide legend and the 1–5
  /// scale selector. Point 5 is brightened from the doc's near-black
  /// `#375623` (which read muddy/grey on a tile) to a vivid emerald so the
  /// "best" score is unmistakably the greenest.
  static const Map<int, Color> scaleColors = <int, Color>{
    1: Color(0xFFDC2626),
    2: Color(0xFFEA8C00),
    3: Color(0xFFEAB308),
    4: Color(0xFF65B741),
    5: Color(0xFF16A34A),
  };

  static Color scaleColor(int score) =>
      scaleColors[score] ?? const Color(0xFF6B7280);

  // --------------------------------------------------------- accent + surface

  /// A *solid*, saturated accent for a score or average — used to tint card
  /// shadows, left accent strips, score rings and progress fills (PRD
  /// BR-AS-03 thresholds). Unscored falls back to the brand colour so cards
  /// stay colourful and on-brand instead of grey.
  static Color scoreAccent(double? score) {
    if (score == null) return palette.brand;
    if (score >= 4) return const Color(0xFF16A34A); // green-600
    if (score >= 2) return const Color(0xFFF59E0B); // amber-500
    return const Color(0xFFEF4444); // red-500
  }

  /// Short qualitative label for an aggregate score — shown next to overall
  /// score rings ("Proficient", "On track", "Needs focus", "Not assessed").
  static String scoreSummary(double? score) {
    if (score == null) return 'Not assessed';
    if (score >= 4) return 'On track';
    if (score >= 2) return 'Developing';
    return 'Needs focus';
  }

  // ----------------------------------------------------- per-entity gradients

  /// Student avatars and primary CTAs (themed).
  static List<Color> get studentGradientColors =>
      palette.studentGradientColors;

  /// Classroom avatars (themed).
  static List<Color> get classroomGradientColors =>
      palette.classroomGradientColors;

  /// School avatar (themed).
  static List<Color> get schoolGradientColors => palette.schoolGradientColors;

  static LinearGradient _diagonal(List<Color> colors) => LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get studentGradient => _diagonal(studentGradientColors);
  static LinearGradient get classroomGradient =>
      _diagonal(classroomGradientColors);
  static LinearGradient get schoolGradient => _diagonal(schoolGradientColors);

  /// Rotating gradients for classroom list cards (themed).
  static List<LinearGradient> get classroomCardGradients => palette
      .classroomCardGradients
      .map(_diagonal)
      .toList(growable: false);

  /// Distinct accent colours for parameter-management domain cards so each
  /// domain reads as its own colour (deterministic by id), the way Events
  /// colour-codes by type. Pool is themed.
  static Color domainColor(String seed) {
    final pool = palette.domainPalette;
    if (seed.isEmpty) return pool.first;
    final i = seed.codeUnits.fold<int>(0, (s, c) => s + c) % pool.length;
    return pool[i];
  }

  /// Fixed emoji for the 5 seeded domains; any admin-created domain falls
  /// back to a small deterministic pool (hashed like [domainColor]) so it
  /// still gets a stable glyph instead of a blank tile.
  static const Map<String, String> _domainEmoji = <String, String>{
    'DOM-SE': '😊',
    'DOM-LL': '💬',
    'DOM-COG': '🧠',
    'DOM-PH': '🏃',
    'DOM-CE': '🎨',
  };

  static const List<String> _domainEmojiFallbackPool = <String>[
    '⭐',
    '🔷',
    '🔶',
    '🌟',
    '🧩',
  ];

  static String domainEmoji(String domainId) {
    final fixed = _domainEmoji[domainId];
    if (fixed != null) return fixed;
    if (domainId.isEmpty) return _domainEmojiFallbackPool.first;
    final i = domainId.codeUnits.fold<int>(0, (s, c) => s + c) %
        _domainEmojiFallbackPool.length;
    return _domainEmojiFallbackPool[i];
  }

  /// Horizontal brand gradient for decorative brand marks (themed). For
  /// buttons/CTAs use [accentGradient] instead.
  static LinearGradient get brandGradient => LinearGradient(
        colors: studentGradientColors,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  /// Horizontal action gradient for primary buttons/CTAs (themed).
  static LinearGradient get accentGradient => LinearGradient(
        colors: palette.accentGradientColors,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  // ------------------------------------------------------------- month label

  static const List<String> _months = <String>[
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// e.g. "June 2026".
  static String monthLabel(DateTime date) =>
      '${_months[date.month - 1]} ${date.year}';

  /// e.g. "Jun 2026".
  static String shortMonthLabel(DateTime date) =>
      '${_months[date.month - 1].substring(0, 3)} ${date.year}';
}

/// Resolved colours for a score badge.
class ScoreBadgeStyle {
  const ScoreBadgeStyle({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}
