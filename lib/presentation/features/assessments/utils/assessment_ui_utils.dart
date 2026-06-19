import 'package:flutter/material.dart';

/// Presentation helpers for the Assessments module: responsive breakpoints,
/// score-badge colour logic, and the fixed scale-point palette.
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
      return const ScoreBadgeStyle(
        background: Color(0xFFF3F4F6),
        foreground: Color(0xFF6B7280),
        border: Color(0xFFE5E7EB),
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

  /// Fixed per-point scale palette (PRD §17.2): 1 red, 2 orange, 3 yellow,
  /// 4 light-green, 5 green. Used by the Assessment Guide / scale reference.
  static const Map<int, Color> scaleColors = <int, Color>{
    1: Color(0xFFC00000),
    2: Color(0xFFE6AC00),
    3: Color(0xFFFFC000),
    4: Color(0xFF70AD47),
    5: Color(0xFF375623),
  };

  static Color scaleColor(int score) =>
      scaleColors[score] ?? const Color(0xFF6B7280);

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
