// import 'package:flutter/material.dart';

// class ResponsiveSizing {
//   const ResponsiveSizing._();

//   static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600;

//   static double titleFontSize(BuildContext context) {
//     final double screenWidth = MediaQuery.of(context).size.width;
//     final bool tablet = screenWidth >= 600;
//     return tablet ? 26 : (screenWidth < 360 ? 18 : 20);
//   }

//   static double titleLineHeight(BuildContext context) {
//     final double size = titleFontSize(context);
//     final bool tablet = isTablet(context);
//     return (tablet ? 34 : 28) / size;
//   }

//   /// Desired outer content padding from app bar divider/edges.
//   /// GlobalScaffold applies 8 px already, this returns extra top/left needed.
//   static EdgeInsets contentPadding(BuildContext context) {
//     final bool tablet = isTablet(context);
//     final double desiredOuter = tablet ? 24 : 16;
//     final double extra = (desiredOuter - 8).clamp(0, 32).toDouble();
//     return EdgeInsets.fromLTRB(extra, extra, 8, 0);
//   }
// }



import 'package:flutter/material.dart';

class ResponsiveSizing {
  const ResponsiveSizing._();

  static const double baseWidth = 375;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;

  /// Scale factor based on screen width
  static double _scale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width / baseWidth;
  }

  /// ✅ Universal responsive font size
  static double fontSize(BuildContext context, double size) {
    final scale = _scale(context);

    // clamp to avoid too small / too large
    return (size * scale).clamp(size * 0.85, size * 1.3);
  }

  /// ✅ Convert px to Flutter height ratio
  static double lineHeight(double height, double fontSize) {
    return height / fontSize;
  }

  /// Your existing logic (kept as-is)
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

  static EdgeInsets contentPadding(BuildContext context) {
    final bool tablet = isTablet(context);
    final double desiredOuter = tablet ? 24 : 16;
    final double extra = (desiredOuter - 8).clamp(0, 32).toDouble();
    return EdgeInsets.fromLTRB(extra, extra, 8, 0);
  }
}