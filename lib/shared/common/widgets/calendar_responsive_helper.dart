import 'package:flutter/material.dart';
import 'package:wowcare/core/responsive/app_breakpoints.dart';

class CalendarResponsiveHelper {
  final BuildContext context;

  CalendarResponsiveHelper(this.context);

  bool get isTablet =>
      AppBreakpoints.classify(MediaQuery.sizeOf(context).width).isTablet;
  bool get isLargeTablet =>
      AppBreakpoints.isWide(MediaQuery.sizeOf(context).width);

  double get calendarWidth => MediaQuery.of(context).size.width * 0.9;
  double get calendarHeight => MediaQuery.of(context).size.height * 0.6;
  double get calendarPadding => isTablet ? 24 : 16;
  double get calendarMargin => isTablet ? 32 : 16;
  double get headerFontSize => isLargeTablet ? 20 : (isTablet ? 18 : 16);

  // Used by date/time field & calendar UI elements
  double get dayCellSize => isLargeTablet ? 52 : (isTablet ? 46 : 40);
  double get dayFontSize => isLargeTablet ? 16 : (isTablet ? 15 : 14);
}
