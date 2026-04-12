import 'package:flutter/material.dart';

class ResponsiveSizing {
  const ResponsiveSizing._();

  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600;

  static double titleFontSize(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool tablet = screenWidth >= 600;
    return tablet ? 26 : (screenWidth < 360 ? 18 : 20);
  }

  static double titleLineHeight(BuildContext context) {
    final double size = titleFontSize(context);
    final bool tablet = isTablet(context);
    return (tablet ? 34 : 28) / size;
  }

  /// Desired outer content padding from app bar divider/edges.
  /// GlobalScaffold applies 8 px already, this returns extra top/left needed.
  static EdgeInsets contentPadding(BuildContext context) {
    final bool tablet = isTablet(context);
    final double desiredOuter = tablet ? 24 : 16;
    final double extra = (desiredOuter - 8).clamp(0, 32).toDouble();
    return EdgeInsets.fromLTRB(extra, extra, 8, 0);
  }

  /// Activity feed list: no extra horizontal inset — [GlobalScaffold] already wraps the body
  /// with 8px; avoids stacking padding that widened the right gap. Vertical matches [contentPadding].
  static EdgeInsets activityFeedListPadding(BuildContext context) {
    final base = contentPadding(context);
    return EdgeInsets.fromLTRB(0, base.top, 0, base.bottom);
  }
}


