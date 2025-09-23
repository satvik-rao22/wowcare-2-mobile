import 'package:flutter/material.dart';

class CalendarResponsiveHelper {
  final BuildContext context;
  
  CalendarResponsiveHelper(this.context);
  
  bool get isTablet => MediaQuery.of(context).size.width > 600;
  bool get isLargeTablet => MediaQuery.of(context).size.width > 900;
  
  double get calendarWidth => MediaQuery.of(context).size.width * 0.9;
  double get calendarPadding => isTablet ? 24 : 16;
  double get calendarMargin => isTablet ? 32 : 16;
  double get headerFontSize => isLargeTablet ? 20 : (isTablet ? 18 : 16);
}