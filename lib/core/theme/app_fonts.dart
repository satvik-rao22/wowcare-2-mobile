import 'package:wowcare/core/theme/app_theme_config.dart';
export 'package:wowcare/core/theme/app_theme_config.dart'
    show AppFontFamilies, AppFonts, AppTypeScale;

/// Legacy font-family names, kept so existing call sites keep compiling.
///
/// Prefer `AppFonts` — it names the *role* a family plays (`AppFonts.body`,
/// `AppFonts.display`, `AppFonts.script`) rather than the family itself, so
/// swapping a typeface is a one-line change in
/// `lib/core/theme/app_theme_config.dart` instead of a repo-wide sweep. This
/// class is a thin alias over `AppFontFamilies` and pins a specific family, so
/// text styled through it does **not** follow the theme switch.
@Deprecated(
  'Use AppFonts.body / AppFonts.display / AppFonts.script instead, so the '
  'text follows AppThemeConfig.skin. AppFontFamilies holds the raw names.',
)
class Fonts {
  Fonts._();

  static const String inter = AppFontFamilies.inter;
  static const String manrope = AppFontFamilies.manrope;
  static const String imperialScript = AppFontFamilies.imperialScript;
}
