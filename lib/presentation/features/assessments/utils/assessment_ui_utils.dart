import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

/// Presentation helpers for the Assessments module: responsive breakpoints,
/// score-badge colour logic, the fixed scale-point palette, accent colours
/// and the per-entity avatar gradients that give the module its colour.
abstract final class AssessmentUi {
  const AssessmentUi._();

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

  /// Section heading used above lists/cards (friendlier mobile size).
  static const TextStyle sectionTitle =
      TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.1);

  /// Card / panel heading.
  static const TextStyle cardTitle =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

  /// Card-grid column count that adapts gracefully across devices.
  static int gridColumns(double width) {
    if (width >= 1280) return 4;
    if (width >= tabletMax) return 3;
    if (width >= mobileMax) return 2;
    return 1;
  }

  /// Constrains very wide web layouts so content stays readable.
  static double contentMaxWidth(double width) => width >= 1400 ? 1320 : width;

  // ------------------------------------------------------- score badge colour

  /// Domain/average score badge colours (PRD BR-AS-03): green ≥ 4,
  /// yellow 2–3 (i.e. ≥ 2 and < 4), red < 2. Used for both individual domain
  /// scores and computed averages.
  static ScoreBadgeStyle badgeStyle(double? score) {
    if (score == null) {
      // "Not yet assessed" reads as a calm, on-brand indigo rather than dead
      // grey — sparsely-assessed students no longer look washed-out.
      return const ScoreBadgeStyle(
        background: Color(0xFFEEF1FF),
        foreground: AppColors.themeColor,
        border: Color(0xFFD7DEFF),
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
  /// BR-AS-03 thresholds). Unscored falls back to the brand indigo so cards
  /// stay colourful and on-brand instead of grey.
  static Color scoreAccent(double? score) {
    if (score == null) return AppColors.themeColor;
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

  /// Brand blue→violet — student avatars and primary CTAs.
  static const List<Color> studentGradientColors = <Color>[
    Color(0xFF5978F7),
    Color(0xFF9C6BF7),
  ];

  /// Violet→indigo — classroom avatars.
  static const List<Color> classroomGradientColors = <Color>[
    Color(0xFF8B5CF6),
    Color(0xFF6366F1),
  ];

  /// Blue→violet (deeper) — school avatar.
  static const List<Color> schoolGradientColors = <Color>[
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
  ];

  static LinearGradient _diagonal(List<Color> colors) => LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get studentGradient => _diagonal(studentGradientColors);
  static LinearGradient get classroomGradient =>
      _diagonal(classroomGradientColors);
  static LinearGradient get schoolGradient => _diagonal(schoolGradientColors);

  /// Distinct accent colours for parameter-management domain cards so each
  /// domain reads as its own colour (deterministic by id), the way Events
  /// colour-codes by type.
  static const List<Color> domainPalette = <Color>[
    Color(0xFF6366F1), // indigo
    Color(0xFF8B5CF6), // violet
    Color(0xFF3B82F6), // blue
    Color(0xFF0EA5E9), // sky
    Color(0xFF14B8A6), // teal
    Color(0xFFF59E0B), // amber
    Color(0xFFEC4899), // pink
    Color(0xFF10B981), // green
  ];

  static Color domainColor(String seed) {
    if (seed.isEmpty) return domainPalette.first;
    final i = seed.codeUnits.fold<int>(0, (s, c) => s + c) %
        domainPalette.length;
    return domainPalette[i];
  }

  /// Horizontal brand gradient for primary buttons / header banners.
  static const LinearGradient brandGradient = LinearGradient(
    colors: studentGradientColors,
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
