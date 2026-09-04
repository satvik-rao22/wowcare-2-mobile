/// Single source of truth for screen-size breakpoints.
///
/// The repo previously had four disagreeing definitions of "tablet" (599,
/// 600, 768, 900/1024 depending on the file). This is the one the app is
/// converging on — 600/1024 match Material's window size classes.
enum ScreenSize { compact, medium, expanded } // phone, tablet, large tablet

abstract final class AppBreakpoints {
  static const double medium = 600; // >= 600 is a tablet
  static const double expanded = 1024; // >= 1024 is a large tablet

  static ScreenSize of(double width) => width >= expanded
      ? ScreenSize.expanded
      : width >= medium
          ? ScreenSize.medium
          : ScreenSize.compact;
}
