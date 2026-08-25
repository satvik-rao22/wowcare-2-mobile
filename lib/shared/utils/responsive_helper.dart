import 'package:flutter/material.dart';

class ResponsiveHelper {
  final BuildContext context;

  ResponsiveHelper(this.context);

  bool get isTablet => MediaQuery.of(context).size.width >= 768;
  bool get isLargeTablet => MediaQuery.of(context).size.width >= 1024;

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
}
