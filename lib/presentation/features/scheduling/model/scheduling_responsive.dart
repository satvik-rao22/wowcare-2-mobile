import 'package:flutter/material.dart';

import 'package:wowcare/core/responsive/app_breakpoints.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';

/// Scheduling's per-screen responsive values, sourced from the single
/// [AppBreakpoints] definition (600/1024) instead of measuring `MediaQuery`
/// directly. Mirrors the property surface of `shared/utils/responsive_helper.dart`
/// (still used elsewhere in the app) so call sites in this feature needed no
/// changes beyond swapping the constructor — only the breakpoint source
/// changed, not the API.
class SchedulingResponsive {
  const SchedulingResponsive(this.context);

  final BuildContext context;

  bool get isTablet => context.isTablet;
  bool get isLargeTablet => context.screenSize == ScreenSizeClass.expanded;

  double get screenWidth => MediaQuery.sizeOf(context).width;
  double get screenHeight => MediaQuery.sizeOf(context).height;

  double get containerWidth =>
      isLargeTablet ? 1200.0 : MediaQuery.sizeOf(context).width;

  double get titleFontSize => isTablet ? 24.0 : 18.0;
  double get labelFontSize => isTablet ? 16.0 : 14.0;
  double get inputFontSize => isTablet ? 18.0 : 16.0;

  double get verticalSpacing => isTablet ? 24.0 : 16.0;
  double get horizontalSpacing => isTablet ? 32.0 : 16.0;

  double get inputFieldHeight => isTablet ? 56.0 : 48.0;
  double get buttonHeight => isTablet ? 64.0 : 56.0;
  double get buttonFontSize => isTablet ? 20.0 : 18.0;
}
