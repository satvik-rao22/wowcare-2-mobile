/// Spacing, radius and sizing tokens for the Attendance V2 module.
///
/// One place for vertical rhythm and component metrics so every widget
/// stays consistent and easy to retune.
class Av2Spacing {
  const Av2Spacing._();

  // Base spacing scale
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  // Corner radii
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusPill = 999;

  // Screen padding (horizontal) per breakpoint
  static const double screenPadMobile = 16;
  static const double screenPadTablet = 24;
  static const double screenPadDesktop = 32;

  // Content max width on large screens so lines never stretch too wide
  static const double contentMaxWidth = 720;

  // Desktop master-detail rail width
  static const double rosterRailWidth = 280;
}

/// Font weights kept to two values per the design system (regular / medium).
class Av2FontWeight {
  const Av2FontWeight._();
}
