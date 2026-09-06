/// The app's spacing scale (Mandate M4).
///
/// No magic spacing numbers in feature code — spacing resolves through these
/// tokens. The scale is 4-based, which is what the reports module already used
/// in practice: 4 / 8 / 12 / 16 / 20 / 24 / 32 accounted for nearly every
/// literal in it.
///
/// Only spacing lives here. Fixed sizes that are *not* spacing — icon sizes,
/// border widths, a control's own height — stay where they are used, as §7.6
/// allows.
class AppSizes {
  const AppSizes._();

  /// 4 — hairline gap, e.g. between a label and its value.
  static const double xxs = 4;

  /// 8 — tight gap inside a control.
  static const double xs = 8;

  /// 10 — legacy half-step, kept because the report cards use it.
  static const double xsPlus = 10;

  /// 12 — gap between related controls.
  static const double sm = 12;

  /// 16 — the default gap between form fields on a phone.
  static const double md = 16;

  /// 20 — dialog inner padding.
  static const double lg = 20;

  /// 24 — the default gap between form fields on a tablet.
  static const double xl = 24;

  /// 32 — section separation.
  static const double xxl = 32;
}
