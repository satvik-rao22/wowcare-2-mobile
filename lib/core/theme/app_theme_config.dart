/// The app's design tokens: the skin switch, the raw colour ramps, motion,
/// fonts and the type scale.
///
/// `AppPalette`, the colour roles product code uses, is generated into
/// `app_palette.gen.dart` from the `skin_*.dart` files. To add a skin: add a
/// value to [AppSkin], create `skin_<name>.dart` overriding only the roles
/// that differ from the base skin, and run `dart run tool/gen_palette.dart`.
///
/// The switch is compile-time because the app's `const` styles and
/// decorations cannot read an `InheritedWidget`.
library;

import 'package:flutter/material.dart';

part 'skin_childcare_wow.dart';
part 'skin_legacy.dart';
part 'app_palette.gen.dart';

/// The visual identities. The first value is the base every other skin
/// inherits from.
enum AppSkin { childcareWow, legacy }

abstract final class AppThemeConfig {
  /// The switch. Change this one constant to re-skin the app.
  static const AppSkin skin = AppSkin.childcareWow;

  /// Legacy is the only pre-brand skin; every other skin is a brand variant
  /// and takes the brand fonts and weights.
  static const bool isBrandSkin = skin != AppSkin.legacy;
}

const bool _brand = AppThemeConfig.isBrandSkin;

/// The ChildcareWow palette, ramp by ramp. Raw values: product code uses
/// [AppPalette] roles, never these.
abstract final class BrandRamps {
  // Teal: structure, secondary actions, and anything about a child.
  static const Color teal50 = Color(0xFFEEFAFA);
  static const Color teal100 = Color(0xFFD4F4F5);
  static const Color teal200 = Color(0xFFACEAEC);
  static const Color teal300 = Color(0xFF79DBDE);
  static const Color teal400 = Color(0xFF45CDD1);
  static const Color teal500 = Color(0xFF27BEC1);
  static const Color teal600 = Color(0xFF1D9B9E);
  static const Color teal700 = Color(0xFF1A7C7F);
  static const Color teal800 = Color(0xFF186265);
  static const Color teal900 = Color(0xFF12494B);

  // Pink: THE recommended action. Never a warning.
  static const Color pink50 = Color(0xFFFEF1F5);
  static const Color pink100 = Color(0xFFFDE2EC);
  static const Color pink200 = Color(0xFFFCC4D9);
  static const Color pink300 = Color(0xFFFB9CBE);
  static const Color pink400 = Color(0xFFFA699C);
  static const Color pink500 = Color(0xFFF83D76);
  static const Color pink600 = Color(0xFFE01B5D);
  static const Color pink700 = Color(0xFFBA124C);
  static const Color pink800 = Color(0xFF8E0E3A);

  // Sun: highlight, and anything about a member of staff.
  static const Color sun50 = Color(0xFFFEFAF0);
  static const Color sun100 = Color(0xFFFDF0D5);
  static const Color sun200 = Color(0xFFFCE2AB);
  static const Color sun300 = Color(0xFFFBC971);
  static const Color sun400 = Color(0xFFF9AD3A);
  static const Color sun500 = Color(0xFFEF9518);
  static const Color sun600 = Color(0xFFD3790C);
  static const Color sun700 = Color(0xFF9D5809);
  static const Color sun800 = Color(0xFF714008);

  // Green: growth and support.
  static const Color green100 = Color(0xFFD8F6E7);
  static const Color green200 = Color(0xFFAEEECF);
  static const Color green300 = Color(0xFF74DDAB);
  static const Color green400 = Color(0xFF3CC986);
  static const Color green500 = Color(0xFF13B167);
  static const Color green600 = Color(0xFF0E8F53);
  static const Color green700 = Color(0xFF0C7143);

  // Orange and purple: decorative accents only.
  static const Color orange100 = Color(0xFFFDEADD);
  static const Color orange200 = Color(0xFFFBD3B9);
  static const Color orange300 = Color(0xFFF8AB84);
  static const Color orange400 = Color(0xFFF37A42);
  static const Color orange500 = Color(0xFFE05E26);
  static const Color orange600 = Color(0xFFB8481A);
  static const Color purple100 = Color(0xFFF1E7FA);
  static const Color purple200 = Color(0xFFE0CBF4);
  static const Color purple300 = Color(0xFFC4A0E8);
  static const Color purple400 = Color(0xFFA06BD4);
  static const Color purple500 = Color(0xFF7D3BB7);

  // Danger: form errors. Deliberately not pink.
  static const Color danger50 = Color(0xFFFEF3F2);
  static const Color danger100 = Color(0xFFFEE4E2);
  static const Color danger500 = Color(0xFFD92D20);
  static const Color danger600 = Color(0xFFB42318);

  // Neutrals. Navy is ink.
  static const Color cream = Color(0xFFFEFEFE);
  static const Color cream100 = Color(0xFFF4F5FA);
  static const Color cream200 = Color(0xFFE9EBF5);
  static const Color ink = Color(0xFF0A1C5D);
  static const Color inkSoft = Color(0xFF4D5983);
  static const Color inkFaint = Color(0xFF8A93B2);
  static const Color navy = Color(0xFF0A1C5D);
  static const Color navy700 = Color(0xFF142A7A);
  static const Color navy900 = Color(0xFF061240);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // L4 surfaces: the flat ground set, warm at the bottom, cooler as it rises.
  /// The page ground: scaffolds, the drawer, the bottom bar.
  static const Color tray = Color(0xFFFBF8F2);

  /// The face of anything raised off the tray.
  static const Color card = Color(0xFFFBFCFF);

  /// An inner tinted row, a chip, a sheet ground.
  static const Color sub = Color(0xFFEFF2FB);

  /// Fields, tracks, troughs, disabled keys.
  static const Color well = Color(0xFFE5EAF7);

  /// A shallower well: a segmented control at rest.
  static const Color wellAlt = Color(0xFFEDF1FA);

  /// Sheet grabbers, inset dividers.
  static const Color wellDeep = Color(0xFFD8E0F2);

  /// Inert markers.
  static const Color wellDeepest = Color(0xFFBFC9E2);

  /// A panel that must separate from [card] without becoming a well.
  static const Color offWhite = Color(0xFFF5F8FE);

  /// The only white: ink on pink or navy, and the lit bevel.
  static const Color warmWhite = Color(0xFFFFFAF2);

  // Tints: the soft fill behind a pill, an avatar or a domain tile.
  static const Color pinkTint = Color(0xFFFBDEE9);
  static const Color tealTint = Color(0xFFD2F1F2);
  static const Color sunTint = Color(0xFFFBEBCF);

  /// Ink on [sunTint]; sun600 is too light for it.
  static const Color sunText = Color(0xFF8A5208);
  static const Color greenTint = Color(0xFFD3F4E4);
  static const Color dangerTint = Color(0xFFFBDEDC);

  // Rims: the solid under-edge of a key. Darker than the text tones.
  static const Color pinkRim = Color(0xFFA10F45);
  static const Color tealRim = Color(0xFF12595B);
  static const Color neutralRim = Color(0xFFCFD8EC);

  // Shadows and edges. Navy at low alpha darkens what it sits on.
  /// Base of every ambient shadow; call sites apply the alpha.
  static const Color shadowWarm = Color(0xFF3F2D14);
  static const Color inkHairline = Color(0x120A1C5D);
  static const Color inkEdge = Color(0x140A1C5D);
  static const Color inkEdgeField = Color(0x1F0A1C5D);
  static const Color inkEdgeStrong = Color(0x290A1C5D);

  // Over media: chrome on a photo or video.
  static const Color mediaHint = Color(0x8AFFFAF2);
  static const Color mediaTrack = Color(0x3DFFFAF2);
  static const Color mediaScrim = Color(0xB3061240);
}

/// The hues of the pre-brand app, carried over verbatim.
abstract final class LegacyHues {
  // Core hues.
  static const Color indigo = Color(0xFF5978F7);
  static const Color indigoLight = Color(0xFF6F8CFF);
  static const Color plum = Color(0xFF573353);
  static const Color plumDark = Color(0xFF241631);
  static const Color navy = Color(0xFF1B237E);
  static const Color violet = Color(0xFF9C84FF);
  static const Color lavender = Color(0xFFB1AFE9);
  static const Color blush = Color(0xFFFBEEFA);
  static const Color pinkLight = Color(0xFFFF9AC4);
  static const Color pink = Color(0xFFFF6B9D);
  static const Color amber = Color(0xFFDC9C13);

  // Status.
  static const Color red = Color(0xFFD32F2F);
  static const Color orange = Color(0xFFFFA000);
  static const Color green = Color(0xFF388E3C);
  static const Color blue = Color(0xFF2C63E2);

  // Neutrals.
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);

  // Soft fills and edges.
  static const Color fieldTint = Color(0x1AB1AFE9);
  static const Color selectedTint = Color(0xFFF9F5FA);
  static const Color hairline = Color(0xFFE9ECEF);
  static const Color plumEdge = Color(0x66573353);
  static const Color successSoft = Color(0xFFE8F5E9);
  static const Color errorStrong = Color(0xFFB3261E);
  static const Color successStrong = Color(0xFF1B5E20);
  static const Color warningStrong = Color(0xFFC05621);

  // Over media.
  static const Color mediaHint = Color(0x8AFFFFFF);
  static const Color mediaTrack = Color(0x3DFFFFFF);
  static const Color mediaScrim = Color(0xB3000000);
}

/// Exact values of the Flutter `Colors.*` swatches the app used to name, so
/// no file reaches into Material's palette. Prefer an [AppPalette] role.
abstract final class MaterialHues {
  // Colors.grey.shadeN.
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);

  // Black and white at Material's alphas.
  static const Color black87 = Color(0xDD000000);
  static const Color black54 = Color(0x8A000000);
  static const Color black26 = Color(0x42000000);
  static const Color black12 = Color(0x1F000000);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color white38 = Color(0x62FFFFFF);
  static const Color white24 = Color(0x3DFFFFFF);

  // Status swatches.
  static const Color red = Color(0xFFF44336);
  static const Color red50 = Color(0xFFFFEBEE);
  static const Color red200 = Color(0xFFEF9A9A);
  static const Color red600 = Color(0xFFE53935);
  static const Color red700 = Color(0xFFD32F2F);
  static const Color redAccent = Color(0xFFFF5252);
  static const Color redAccent100 = Color(0xFFFF8A80);
  static const Color green = Color(0xFF4CAF50);
  static const Color greenAccent100 = Color(0xFFB9F6CA);
  static const Color orange = Color(0xFFFF9800);
  static const Color orange50 = Color(0xFFFFF3E0);
  static const Color orange100 = Color(0xFFFFE0B2);
  static const Color orange800 = Color(0xFFEF6C00);
  static const Color blue = Color(0xFF2196F3);
  static const Color blue50 = Color(0xFFE3F2FD);
  static const Color blueGrey700 = Color(0xFF455A64);
  static const Color yellow = Color(0xFFFFEB3B);
  static const Color amber = Color(0xFFFFC107);

  // One-off decorative swatches.
  static const Color red100 = Color(0xFFFFCDD2);
  static const Color lightGreen = Color(0xFF8BC34A);
  static const Color deepOrange = Color(0xFFFF5722);
  static const Color blue400 = Color(0xFF42A5F5);
  static const Color lightBlue = Color(0xFF03A9F4);
  static const Color blueGrey = Color(0xFF607D8B);
  static const Color indigo = Color(0xFF3F51B5);
  static const Color purple = Color(0xFF9C27B0);
  static const Color deepPurple = Color(0xFF673AB7);
  static const Color pink = Color(0xFFE91E63);
  static const Color teal = Color(0xFF009688);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color brown = Color(0xFF795548);
}

/// Durations and curves. Objects settle; they never whip.
abstract final class AppMotion {
  /// A key going down or coming back up.
  static const Duration press = Duration(milliseconds: 90);

  /// A small state change.
  static const Duration fast = Duration(milliseconds: 160);

  /// The default.
  static const Duration base = Duration(milliseconds: 200);

  /// A panel or sheet moving.
  static const Duration panel = Duration(milliseconds: 300);

  /// The bottom bar's active droplet flying to another tab.
  static const Duration droplet = Duration(milliseconds: 620);

  /// How far a rimmed key sinks, in logical pixels. The rim collapses by the
  /// same distance, so the face lands on it.
  static const double pressTravel = 3;

  /// How far a rimless tappable surface sinks.
  static const double pressTravelSurface = 2;

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
}

/// Font families bundled with the app. Each name must match a `family:` in
/// `pubspec.yaml`, or Flutter silently falls back to the platform font.
abstract final class AppFontFamilies {
  /// The brand typeface. Four faces bundled: Regular, Medium, SemiBold, Bold.
  static const String poppins = 'Poppins';

  /// The legacy skin's typeface.
  static const String manrope = 'Manrope';

  /// Not bundled. Do not use without re-adding its `fonts:` block.
  static const String inter = 'Inter';

  /// Not bundled. Do not use without re-adding its `fonts:` block.
  static const String imperialScript = 'Imperial_Script';

  /// The decorative script on the incident-activity signature band.
  static const String mervaleScript = 'MervaleScript';
}

/// Fonts by role. Product code names the role, never the family.
abstract final class AppFonts {
  /// Body copy, labels, values: the default family.
  static const String body = _brand
      ? AppFontFamilies.poppins
      : AppFontFamilies.manrope;

  /// Headings. Same as [body] today; kept separate so a display face can be
  /// introduced without touching body text.
  static const String display = _brand
      ? AppFontFamilies.poppins
      : AppFontFamilies.manrope;

  /// Numeric chrome, e.g. countdown digits.
  static const String numeric = _brand
      ? AppFontFamilies.poppins
      : AppFontFamilies.manrope;

  /// The decorative script.
  static const String scriptAlt = AppFontFamilies.mervaleScript;

  /// Code and fixed-width values.
  static const String mono = 'monospace';
}

/// Sizes, weights, line heights and letter spacing.
///
/// Weights are a four-step ladder, one job each:
///   400 regular   body copy, captions, values
///   500 medium    every key and button label
///   600 semiBold  titles, names, section and table headers, selected tabs
///   700 bold      attention only: an amount, a hero figure, a badge, an alert
abstract final class AppTypeScale {
  // Sizes, in logical pixels: the rem scale at a 16px root, plus the
  // off-scale sizes the app already renders.
  static const double size2xs = 11;
  static const double sizeXs = 12;
  static const double sizeSm = 13;
  static const double sizeBase = 14;
  static const double sizeMd = 16;
  static const double sizeLg = 18;
  static const double sizeXl = 20;
  static const double size2xl = 24;
  static const double size3xl = 30;
  static const double size4xl = 36;
  static const double s32 = 32;

  // Weights
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  /// Legacy. No ExtraBold face is bundled, so this renders as [bold].
  static const FontWeight extraBold = FontWeight.w800;

  static const FontWeight bodyWeight = regular;
  static const FontWeight buttonWeight = medium;
  static const FontWeight headingWeight = _brand ? semiBold : bold;

  // Line heights, as multipliers for TextStyle.height.
  static const double leadingTight = 1.15;
  static const double leadingSnug = 1.3;
  static const double leadingBody = 1.65;

  // Letter spacing.
  static const double trackingHeading = -0.015;
  static const double trackingEyebrow = 0.12;
}
