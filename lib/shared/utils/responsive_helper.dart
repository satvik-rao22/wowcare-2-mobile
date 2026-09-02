import 'package:flutter/material.dart';

class ResponsiveHelper {
  final BuildContext context;

  ResponsiveHelper(this.context);

  bool get isTablet => MediaQuery.of(context).size.width >= 768;
  bool get isLargeTablet => MediaQuery.of(context).size.width >= 1024;

  // Compact breakpoints preserved from the legacy ResponsiveSizing (tablet >=600)
  // and the inline attendance literals (wide >=900). Kept verbatim so
  // consolidating onto this single helper does NOT shift any existing visual
  // breakpoint. Distinct from the canonical isTablet(768)/isLargeTablet(1024).
  bool get isTabletCompact => MediaQuery.of(context).size.width >= 600;
  bool get isWide => MediaQuery.of(context).size.width >= 900;

  // Narrow-phone breakpoint, preserved verbatim from inline attendance
  // literals (`screenWidth < 360`) so consolidating onto this helper does
  // NOT shift any existing visual breakpoint.
  bool get isNarrow => MediaQuery.of(context).size.width < 360;

  /// Raw screen dimensions, for call sites that need the actual pixel value
  /// (e.g. popup positioning math) rather than a breakpoint boolean. Routing
  /// these through the helper — even as a plain passthrough — keeps every
  /// screen-dimension read in one place.
  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;

  double get containerWidth =>
      isLargeTablet ? 1200.0 : MediaQuery.of(context).size.width;

  double get titleFontSize => isTablet ? 24.0 : 18.0;
  double get labelFontSize => isTablet ? 16.0 : 14.0;
  double get inputFontSize => isTablet ? 18.0 : 16.0;

  double get verticalSpacing => isTablet ? 24.0 : 16.0;
  double get horizontalSpacing => isTablet ? 32.0 : 16.0;

  double get inputFieldHeight => isTablet ? 56.0 : 48.0;
  double get buttonHeight => isTablet ? 64.0 : 56.0;
  double get buttonFontSize => isTablet ? 20.0 : 18.0;

  /// Desired outer content padding from app bar divider/edges. GlobalScaffold
  /// applies 8px already; this returns the extra top/left needed.
  ///
  /// Ported verbatim from the legacy `ResponsiveSizing.contentPadding` (which
  /// used its own 600px `isTablet`) so consolidating onto this helper does
  /// NOT shift the visual breakpoint — uses [isTabletCompact], not the
  /// canonical 768px [isTablet], to match exactly.
  EdgeInsets get contentPadding {
    final double desiredOuter = isTabletCompact ? 24 : 16;
    final double extra = (desiredOuter - 8).clamp(0, 32).toDouble();
    return EdgeInsets.fromLTRB(extra, extra, 8, 0);
  }
}
