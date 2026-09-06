/// The single definition of the app's screen-size breakpoints (Mandate M7).
///
/// No other file may compare a screen width against a literal. Feature code
/// reads `context.screenSize` / `context.isTablet` /
/// `context.responsive(compact:, medium:, expanded:)` from
/// `responsive_scope.dart`; it does not measure.
///
/// Values follow Material 3's window size classes, which is also what the
/// mandate's `compact` / `medium` / `expanded` API implies.
class AppBreakpoints {
  const AppBreakpoints._();

  /// Phones in portrait. Below this width the layout is single-column.
  static const double compactMaxWidth = 600;

  /// Tablets. Ends at the width the app already treats as a large tablet.
  ///
  /// Material 3's own `expanded` class starts at 840, but this codebase had
  /// already standardised on 1024 (`ResponsiveHelper.isLargeTablet`), so 840
  /// would have introduced a boundary nothing else uses. `CalendarResponsive-
  /// Helper` disagrees again at 900 — see the migration report.
  static const double mediumMaxWidth = 1024;

  /// Very small phones. Matches the existing `ResponsiveHelper.isNarrow`.
  static const double narrowMaxWidth = 360;

  /// Legacy sub-boundary kept because two helpers already depend on it:
  /// `ResponsiveHelper.isWide` (>= 900) and `CalendarResponsiveHelper`'s
  /// "large tablet" (> 900). It sits inside [ScreenSizeClass.medium] and is
  /// NOT a size class — it exists so those call sites keep their exact
  /// behaviour while still resolving their number from this one file.
  static const double wideMinWidth = 900;

  /// True below [narrowMaxWidth] — a sub-compact tweak, not a size class.
  static bool isNarrow(double width) => width < narrowMaxWidth;

  /// True at [wideMinWidth] and above. See that constant for why it exists.
  static bool isWide(double width) => width >= wideMinWidth;

  /// Resolve a width to its size class.
  static ScreenSizeClass classify(double width) {
    if (width < compactMaxWidth) return ScreenSizeClass.compact;
    if (width < mediumMaxWidth) return ScreenSizeClass.medium;
    return ScreenSizeClass.expanded;
  }
}

/// Material 3 window size class.
enum ScreenSizeClass {
  compact,
  medium,
  expanded;

  /// Anything at or above [AppBreakpoints.compactMaxWidth].
  ///
  /// NOTE: this is the value the legacy helpers disagree on. `ResponsiveHelper`
  /// currently calls 600–839 a phone (its `isTablet` is >= 768), so adopting
  /// this changes layout for that range app-wide. See the impact report before
  /// redirecting the legacy helpers here.
  bool get isTablet => this != ScreenSizeClass.compact;

  bool get isCompact => this == ScreenSizeClass.compact;
  bool get isMedium => this == ScreenSizeClass.medium;
  bool get isExpanded => this == ScreenSizeClass.expanded;
}
