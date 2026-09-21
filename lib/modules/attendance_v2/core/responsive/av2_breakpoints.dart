import 'package:flutter/widgets.dart';
import '../theme/av2_spacing.dart';

/// Device size class for the module.
enum Av2FormFactor { mobile, tablet, desktop }

/// Centralised breakpoint logic so every widget agrees on what "tablet" means.
class Av2Breakpoints {
  const Av2Breakpoints._();

  static const double tablet = 600;
  static const double desktop = 1024;

  static Av2FormFactor of(double width) {
    if (width >= desktop) return Av2FormFactor.desktop;
    if (width >= tablet) return Av2FormFactor.tablet;
    return Av2FormFactor.mobile;
  }

  static Av2FormFactor ofContext(BuildContext context) =>
      of(MediaQuery.sizeOf(context).width);

  static double screenPadding(Av2FormFactor f) {
    switch (f) {
      case Av2FormFactor.mobile:
        return Av2Spacing.screenPadMobile;
      case Av2FormFactor.tablet:
        return Av2Spacing.screenPadTablet;
      case Av2FormFactor.desktop:
        return Av2Spacing.screenPadDesktop;
    }
  }
}
