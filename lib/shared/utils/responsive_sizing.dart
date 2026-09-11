import 'package:flutter/material.dart';
import 'package:wowcare/core/responsive/app_breakpoints.dart';

class ResponsiveSizing {
  const ResponsiveSizing._();

  static bool isTablet(BuildContext context) =>
      AppBreakpoints.classify(MediaQuery.sizeOf(context).width).isTablet;

  static double titleFontSize(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool tablet = AppBreakpoints.classify(screenWidth).isTablet;
    return tablet ? 26 : (AppBreakpoints.isNarrow(screenWidth) ? 18 : 20);
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

  /// Activity feed list area: same insets as [StudentScreen] scroll body — default
  /// [GlobalScaffold] body padding (8) plus this [contentPadding] (e.g. phone: +8 L/T/R).
  static EdgeInsets activityFeedListPadding(BuildContext context) {
    return contentPadding(context);
  }
}
