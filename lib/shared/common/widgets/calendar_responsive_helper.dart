import 'package:flutter/material.dart';

class CalendarResponsiveHelper {
  final BuildContext context;

  late final double screenWidth;
  late final double screenHeight;

  late final bool isTablet;
  late final bool isLargeTablet;

  late final double calendarWidth;
  late final double calendarHeight;
  late final double dayCellSize;
  late final double headerFontSize;
  late final double dayFontSize;
  late final double eventDotSize;
  late final double calendarPadding;
  late final double calendarMargin;

  CalendarResponsiveHelper(this.context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    isTablet = screenWidth > 600;
    isLargeTablet = screenWidth > 900;

    // Calendar width and height
    if (isLargeTablet) {
      calendarWidth = (screenWidth * 0.7).clamp(600.0, 900.0);
      calendarHeight = (screenHeight * 0.7).clamp(600.0, 900.0);
    } else if (isTablet) {
      calendarWidth = (screenWidth * 0.85).clamp(400.0, 700.0);
      calendarHeight = (screenHeight * 0.6).clamp(400.0, 700.0);
    } else {
      calendarWidth = screenWidth - 16.0;
      calendarHeight = (screenWidth - 16.0) * 1.1;
    }

    // Day cell size
    dayCellSize = isLargeTablet
        ? 64.0
        : isTablet
            ? 48.0
            : 36.0;

    // Font sizes
    headerFontSize = isLargeTablet
        ? 28.0
        : isTablet
            ? 22.0
            : 16.0;

    dayFontSize = isLargeTablet
        ? 20.0
        : isTablet
            ? 16.0
            : 12.0;

    // Event dot size
    eventDotSize = isLargeTablet
        ? 10.0
        : isTablet
            ? 8.0
            : 6.0;

    // Padding and margin
    calendarPadding = isLargeTablet
        ? 32.0
        : isTablet
            ? 24.0
            : 12.0;

    calendarMargin = isLargeTablet
        ? 32.0
        : isTablet
            ? 24.0
            : 8.0;
  }
} 