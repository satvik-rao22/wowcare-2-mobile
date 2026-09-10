/// # The single control point for the app's colours and typography.
///
/// Everything visual in WowCare resolves — directly or through
/// [AppColors]/[AppTextStyles]/[AppFonts] — to a token declared in this file.
/// Nothing else in `lib/` should contain a colour literal or a font-family
/// string. Change a value here and the whole app follows.
///
/// ## How the file is laid out
///
/// | Section | What it holds |
/// |---|---|
/// | 1. [AppSkin] / [AppThemeConfig] | **The switch.** One constant selects the active skin. |
/// | 2. [BrandRamps] | The ChildcareWow design-system palette (brand truth). |
/// | 3. [LegacyHues] | The hues the shipped app renders today. |
/// | 4. [MaterialHues] | Exact values of the Flutter `Colors.*` swatches the app used to name. |
/// | 5. [AppPalette] | **Semantic roles** — `textPrimary`, `surfaceCard`, `statusError`… |
/// | 6. [AppFontFamilies] / [AppFonts] | Font families and the role each one plays. |
/// | 7. [AppTypeScale] | Font sizes, weights, line-heights, letter-spacing. |
///
/// ## Switching the whole app's look
///
/// Flip [AppThemeConfig.skin] to [AppSkin.childcareWow]. Because every token
/// below is a compile-time `const` selected by that one constant, the change
/// propagates to every `const TextStyle` and `const Color` in the app — no
/// call-site edits, no `Theme.of(context)` plumbing, no runtime cost.
///
/// The switch is deliberately compile-time: the app declares thousands of
/// `const` text styles and decorations, and a `const` cannot read from an
/// `InheritedWidget`. Compile-time selection is what makes a single-file
/// switch possible at all without rewriting every widget.
///
/// ## Adding a colour
///
/// Add it to [AppPalette] as a semantic role (what it *means*: an error, a
/// card surface, a hairline). Give both skins a value. Only reach for a
/// feature-scoped constant in [AppColors] when the colour is decorative and
/// genuinely local — a pastel chip in a rotating palette, say.
library;

import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 1. THE SWITCH
// ═══════════════════════════════════════════════════════════════════════════

/// The available visual identities.
enum AppSkin {
  /// The palette and typography the app ships with today: plum/indigo on
  /// white, Manrope throughout. Visually identical to pre-centralisation
  /// WowCare — every value in [LegacyHues] is carried over verbatim.
  legacy,

  /// The ChildcareWow brand design language: navy ink, brand teal and pink,
  /// Poppins throughout. Sourced from the ChildcareWow Brand Colour & Type
  /// Guide as implemented in the production website and the mobile redesign
  /// (`WowCare Design Components`).
  childcareWow,
}

/// The app-wide theme switch. This is the only place a skin is chosen.
class AppThemeConfig {
  AppThemeConfig._();

  /// **The switch.** Change this one constant to re-skin the entire app.
  ///
  /// * [AppSkin.legacy] — the current production look (default).
  /// * [AppSkin.childcareWow] — the brand design language.
  static const AppSkin skin = AppSkin.childcareWow;

  /// Whether the brand design language is active. Every token in this file
  /// branches on this constant.
  static const bool isBrandSkin = skin == AppSkin.childcareWow;
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. BRAND RAMPS — the ChildcareWow design system
// ═══════════════════════════════════════════════════════════════════════════

/// The ChildcareWow brand palette, ramp by ramp.
///
/// The `-500` step of each ramp is the exact brand-guide hex. The logo carries
/// four of these: pink child, teal child, sun spark, green ground arc, on a
/// navy wordmark.
///
/// These are raw palette values. Product code should not reference them
/// directly — use the semantic roles in [AppPalette], which is what the skin
/// switch actually rewires.
class BrandRamps {
  BrandRamps._();

  // ── Teal #27BEC1 — technology, clarity; structure and secondary actions ──
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

  // ── Pink #F83D76 — energy, warmth; THE recommended action ────────────────
  static const Color pink50 = Color(0xFFFEF1F5);
  static const Color pink100 = Color(0xFFFDE2EC);
  static const Color pink200 = Color(0xFFFCC4D9);
  static const Color pink300 = Color(0xFFFB9CBE);
  static const Color pink400 = Color(0xFFFA699C);
  static const Color pink500 = Color(0xFFF83D76);
  static const Color pink600 = Color(0xFFE01B5D);
  static const Color pink700 = Color(0xFFBA124C);
  static const Color pink800 = Color(0xFF8E0E3A);

  // ── Sun #F9AD3A — highlight, positivity ──────────────────────────────────
  static const Color sun50 = Color(0xFFFEFAF0);
  static const Color sun100 = Color(0xFFFDF0D5);
  static const Color sun200 = Color(0xFFFCE2AB);
  static const Color sun300 = Color(0xFFFBC971);
  static const Color sun400 = Color(0xFFF9AD3A);
  static const Color sun500 = Color(0xFFEF9518);
  static const Color sun600 = Color(0xFFD3790C);
  static const Color sun700 = Color(0xFF9D5809);
  static const Color sun800 = Color(0xFF714008);

  // ── Green #13B167 — growth, support (the logo's ground arc) ──────────────
  static const Color green100 = Color(0xFFD8F6E7);
  static const Color green200 = Color(0xFFAEEECF);
  static const Color green300 = Color(0xFF74DDAB);
  static const Color green400 = Color(0xFF3CC986);
  static const Color green500 = Color(0xFF13B167);
  static const Color green600 = Color(0xFF0E8F53);
  static const Color green700 = Color(0xFF0C7143);

  // ── Orange #F37A42 — accent spark ────────────────────────────────────────
  static const Color orange100 = Color(0xFFFDEADD);
  static const Color orange200 = Color(0xFFFBD3B9);
  static const Color orange300 = Color(0xFFF8AB84);
  static const Color orange400 = Color(0xFFF37A42);
  static const Color orange500 = Color(0xFFE05E26);
  static const Color orange600 = Color(0xFFB8481A);

  // ── Purple #7D3BB7 — accent spark, decorative only ───────────────────────
  static const Color purple100 = Color(0xFFF1E7FA);
  static const Color purple200 = Color(0xFFE0CBF4);
  static const Color purple300 = Color(0xFFC4A0E8);
  static const Color purple400 = Color(0xFFA06BD4);
  static const Color purple500 = Color(0xFF7D3BB7);

  /// Form-error red. Deliberately NOT brand pink: pink means "recommended
  /// action" and must never double as a warning.
  static const Color danger50 = Color(0xFFFEF3F2);
  static const Color danger100 = Color(0xFFFEE4E2);
  static const Color danger500 = Color(0xFFD92D20);
  static const Color danger600 = Color(0xFFB42318);

  // ── Neutrals. Navy = headings, body text, trust. ─────────────────────────
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

  // ── L4 surfaces — the flat skeuomorphic ground set ───────────────────────
  //
  // Nine tones, warm at the bottom and cool as they rise, taken from the
  // design system's `colors.css` L4 block. They are what makes a *flat* fill
  // read as a solid object: the page is a warm tray, everything raised off it
  // is a cooler card, and everything you type into is cut back down into a
  // well. Depth comes from the bevel/shadow pairs in [AppElevation], never
  // from a gradient.

  /// `#FBF8F2` — the warm page ground. Scaffolds, the drawer, the bottom bar,
  /// tab strips: the tray everything else sits on.
  static const Color tray = Color(0xFFFBF8F2);

  /// `#FBFCFF` — the face of anything raised off the tray: cards, bars, keys.
  static const Color card = Color(0xFFFBFCFF);

  /// `#EFF2FB` — an inner tinted row, a chip, a bottom-sheet ground.
  static const Color sub = Color(0xFFEFF2FB);

  /// `#E5EAF7` — the well. Fields, tracks, troughs, disabled keys.
  static const Color well = Color(0xFFE5EAF7);

  /// `#EDF1FA` — a shallower well, e.g. a segmented control at rest.
  static const Color wellAlt = Color(0xFFEDF1FA);

  /// `#D8E0F2` — a deep well: sheet grabbers, inset dividers.
  static const Color wellDeep = Color(0xFFD8E0F2);

  /// `#BFC9E2` — the deepest step; "not marked" dots and inert markers.
  static const Color wellDeepest = Color(0xFFBFC9E2);

  /// `#F5F8FE` — the coolest near-white, for a panel that must separate from
  /// [card] without becoming a well.
  static const Color offWhite = Color(0xFFF5F8FE);

  /// `#FFFAF2` — **the only white**. Text and glyphs on pink or navy, and the
  /// lit top bevel. Pure `#FFFFFF` is retired under this skin.
  static const Color warmWhite = Color(0xFFFFFAF2);

  // ── L4 tints — the soft fill that pairs with each hue ────────────────────
  //
  // One step lighter and one step cooler than the `-100` steps above, tuned
  // to sit on the L4 tray without going chalky. These are the fills behind a
  // status pill, an avatar or a domain-coded tile.

  /// `#FBDEE9` — pink tint: the active-nav wash, a pink pill.
  static const Color pinkTint = Color(0xFFFBDEE9);

  /// `#D2F1F2` — teal tint: student avatars and student-scoped tiles.
  static const Color tealTint = Color(0xFFD2F1F2);

  /// `#FBEBCF` — sun tint: staff avatars and staff-scoped tiles.
  static const Color sunTint = Color(0xFFFBEBCF);

  /// `#8A5208` — readable ink on [sunTint]; `sun600` is too light to sit on it.
  static const Color sunText = Color(0xFF8A5208);

  /// `#D3F4E4` — green tint: "signed in", "on track", "paid".
  static const Color greenTint = Color(0xFFD3F4E4);

  /// `#FBDEDC` — danger tint: "absent", "over ratio", "overdue".
  static const Color dangerTint = Color(0xFFFBDEDC);

  // ── Rims — the solid under-edge a key is pressed down onto ───────────────
  //
  // A rim is a hard, un-blurred offset shadow, not a gradient and not a
  // border: it is the side of the key you can see until you push it away.

  /// `#A10F45` — the rim under a pink key. Darker than [pink700], which is a
  /// *text* tone; a rim needs to read as a shaded side, not as a hover state.
  static const Color pinkRim = Color(0xFFA10F45);

  /// `#12595B` — the rim under a teal key.
  static const Color tealRim = Color(0xFF12595B);

  /// `#CFD8EC` — the rim under a neutral (card-faced) key: kiosk digits,
  /// segmented peers, quiet secondary actions.
  static const Color neutralRim = Color(0xFFCFD8EC);

  // ── Shadow bases — tinted, never black ───────────────────────────────────

  /// `#3F2D14` — the base every *ambient* drop shadow is tinted with. A warm
  /// brown, so a shadow cast onto the warm [tray] reads as shade rather than
  /// as a grey smudge. Call sites apply the alpha.
  static const Color shadowWarm = Color(0xFF3F2D14);
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. LEGACY HUES — what the shipped app renders today
// ═══════════════════════════════════════════════════════════════════════════

/// The core hues of the app as shipped, named by colour rather than by role.
///
/// Every value here is carried over verbatim from the pre-centralisation
/// `AppColors`, so [AppSkin.legacy] is pixel-identical to what shipped.
class LegacyHues {
  LegacyHues._();

  /// `#5978F7` — the app's headline indigo (was `AppColors.themeColor`).
  static const Color indigo = Color(0xFF5978F7);

  /// `#6F8CFF` — lighter indigo, first stop of the primary gradient.
  static const Color indigoLight = Color(0xFF6F8CFF);

  /// `#573353` — the plum used for nearly all body text and headings
  /// (was `AppColors.primaryColor`).
  static const Color plum = Color(0xFF573353);

  /// `#241631` — deep plum, used behind photo overlays and avatars.
  static const Color plumDark = Color(0xFF241631);

  /// `#1B237E` — deep navy (was `AppColors.secondaryColor`).
  static const Color navy = Color(0xFF1B237E);

  /// `#9C84FF` — the lavender-violet second stop of the primary gradient.
  static const Color violet = Color(0xFF9C84FF);

  /// `#B1AFE9` — the soft lavender behind fields, chips and badges.
  static const Color lavender = Color(0xFFB1AFE9);

  /// `#FBEEFA` — the pale pink the scaffold gradient fades into.
  static const Color blush = Color(0xFFFBEEFA);

  /// `#FF9AC4` / `#FF6B9D` — the guardian message-bubble gradient.
  static const Color pinkLight = Color(0xFFFF9AC4);
  static const Color pink = Color(0xFFFF6B9D);

  /// `#DC9C13` — the amber accent (was `AppColors.accentColor`).
  static const Color amber = Color(0xFFDC9C13);

  /// Status hues (Material's 700-ish steps, as shipped).
  static const Color red = Color(0xFFD32F2F);
  static const Color orange = Color(0xFFFFA000);
  static const Color green = Color(0xFF388E3C);
  static const Color blue = Color(0xFF2C63E2);

  /// Neutrals, matching the Material greys the app reaches for.
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
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. MATERIAL HUES — exact stand-ins for Flutter's swatches
// ═══════════════════════════════════════════════════════════════════════════

/// Exact values of the Flutter `Colors.*` swatches the app used to reference
/// directly.
///
/// These exist so no file in `lib/` reaches into Flutter's Material palette:
/// a `Colors.grey.shade300` is a `final`, not a `const`, so it cannot be used
/// in a `const` decoration, and it ties the app's look to Material's defaults
/// rather than to this file. Each constant below is byte-identical to the
/// swatch named in its comment, so adopting one never changes a pixel.
///
/// Prefer a role from [AppPalette]. Reach for these only when migrating a
/// decorative one-off whose exact shade must be preserved.
class MaterialHues {
  MaterialHues._();

  // ── Greys (Colors.grey.shadeN) ───────────────────────────────────────────
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);

  /// `Colors.grey` itself, i.e. `grey.shade500`.
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);

  // ── Black and white at Material's standard alphas ────────────────────────
  /// `Colors.black87`.
  static const Color black87 = Color(0xDD000000);

  /// `Colors.black54`.
  static const Color black54 = Color(0x8A000000);

  /// `Colors.black26`.
  static const Color black26 = Color(0x42000000);

  /// `Colors.black12`.
  static const Color black12 = Color(0x1F000000);

  /// `Colors.white70`.
  static const Color white70 = Color(0xB3FFFFFF);

  /// `Colors.white38`.
  static const Color white38 = Color(0x62FFFFFF);

  /// `Colors.white24`.
  static const Color white24 = Color(0x3DFFFFFF);

  // ── Status swatches (Colors.red / green / orange / blue …) ───────────────
  /// `Colors.red`.
  static const Color red = Color(0xFFF44336);
  static const Color red50 = Color(0xFFFFEBEE);
  static const Color red200 = Color(0xFFEF9A9A);
  static const Color red600 = Color(0xFFE53935);
  static const Color red700 = Color(0xFFD32F2F);

  /// `Colors.redAccent`.
  static const Color redAccent = Color(0xFFFF5252);

  /// `Colors.redAccent.shade100`.
  static const Color redAccent100 = Color(0xFFFF8A80);

  /// `Colors.green`.
  static const Color green = Color(0xFF4CAF50);

  /// `Colors.greenAccent.shade100`.
  static const Color greenAccent100 = Color(0xFFB9F6CA);

  /// `Colors.orange`.
  static const Color orange = Color(0xFFFF9800);
  static const Color orange50 = Color(0xFFFFF3E0);
  static const Color orange100 = Color(0xFFFFE0B2);
  static const Color orange800 = Color(0xFFEF6C00);

  /// `Colors.blue`.
  static const Color blue = Color(0xFF2196F3);
  static const Color blue50 = Color(0xFFE3F2FD);

  /// `Colors.blueGrey.shade700`.
  static const Color blueGrey700 = Color(0xFF455A64);

  /// `Colors.yellow`.
  static const Color yellow = Color(0xFFFFEB3B);

  /// `Colors.amber`.
  static const Color amber = Color(0xFFFFC107);

  // ── Remaining swatches, each referenced from a single decorative site ────
  /// `Colors.red.shade100`.
  static const Color red100 = Color(0xFFFFCDD2);

  /// `Colors.lightGreen`.
  static const Color lightGreen = Color(0xFF8BC34A);

  /// `Colors.deepOrange`.
  static const Color deepOrange = Color(0xFFFF5722);

  /// `Colors.blue.shade400`.
  static const Color blue400 = Color(0xFF42A5F5);

  /// `Colors.lightBlue`.
  static const Color lightBlue = Color(0xFF03A9F4);

  /// `Colors.blueGrey`.
  static const Color blueGrey = Color(0xFF607D8B);

  /// `Colors.indigo`.
  static const Color indigo = Color(0xFF3F51B5);

  /// `Colors.purple`.
  static const Color purple = Color(0xFF9C27B0);

  /// `Colors.deepPurple`.
  static const Color deepPurple = Color(0xFF673AB7);

  /// `Colors.pink`.
  static const Color pink = Color(0xFFE91E63);

  /// `Colors.teal`.
  static const Color teal = Color(0xFF009688);

  /// `Colors.cyan`.
  static const Color cyan = Color(0xFF00BCD4);

  /// `Colors.brown`.
  static const Color brown = Color(0xFF795548);
}

// ═══════════════════════════════════════════════════════════════════════════
// 5. SEMANTIC ROLES — the layer the skin switch rewires
// ═══════════════════════════════════════════════════════════════════════════

const bool _brand = AppThemeConfig.isBrandSkin;

/// The app's colours **by meaning**, not by hue.
///
/// This is the layer that matters. `AppColors` and the generated [ThemeData]
/// both resolve here, so a role changed here changes everywhere that role is
/// used. Each role is a `const` ternary on [AppThemeConfig.isBrandSkin]: the
/// left branch is the brand design language, the right is the legacy look.
class AppPalette {
  AppPalette._();

  // ── Brand ────────────────────────────────────────────────────────────────

  /// The headline brand colour: primary keys, the active nav slot, links.
  ///
  /// Pink, not teal, under the brand skin. Teal is domain colour — it means
  /// "this is about a child" — so it comes off the chrome entirely and the
  /// one recommended action carries the brand instead.
  static const Color brand = _brand ? BrandRamps.pink600 : LegacyHues.indigo;

  /// A lighter brand tint, for a hover wash or a secondary accent.
  static const Color brandLight = _brand
      ? BrandRamps.pink500
      : LegacyHues.indigoLight;

  /// A darker brand tone for pressed states and text on a brand tint.
  static const Color brandDark = _brand ? BrandRamps.pink700 : LegacyHues.navy;

  /// Text and icons drawn on top of [brand]. Warm white, never pure white.
  static const Color onBrand = _brand ? BrandRamps.warmWhite : LegacyHues.white;

  /// The secondary brand tone (deep navy today, brand navy under the redesign).
  static const Color brandSecondary = _brand
      ? BrandRamps.navy
      : LegacyHues.navy;

  /// The accent used for the second gradient stop and decorative flourishes.
  static const Color brandAccent = _brand
      ? BrandRamps.pink500
      : LegacyHues.violet;

  /// The single "recommended action" colour. Under the brand skin this is
  /// deliberately pink and must never double as a warning.
  static const Color actionRecommended = _brand
      ? BrandRamps.pink600
      : LegacyHues.indigo;

  /// The highlight/attention colour (never a status).
  static const Color actionHighlight = _brand
      ? BrandRamps.sun400
      : LegacyHues.amber;

  /// A soft brand wash used as the base for badges and pills.
  /// Call sites usually apply their own low alpha on top of it.
  static const Color brandSoft = _brand
      ? BrandRamps.pinkTint
      : LegacyHues.lavender;

  /// The quiet, non-recommended action: a secondary key, a body link, a
  /// minor chrome affordance. Teal is deliberately *not* the headline colour
  /// any more, but it is still the app's second voice.
  static const Color actionSecondary = _brand
      ? BrandRamps.teal600
      : LegacyHues.indigo;

  // ── Text ─────────────────────────────────────────────────────────────────

  /// Headings and body copy — the app's default text colour.
  static const Color textPrimary = _brand ? BrandRamps.ink : LegacyHues.plum;

  /// Supporting text: captions, secondary values, metadata.
  static const Color textSecondary = _brand
      ? BrandRamps.inkSoft
      : LegacyHues.grey600;

  /// De-emphasised text: hints, placeholders, disabled labels.
  static const Color textMuted = _brand
      ? BrandRamps.inkFaint
      : LegacyHues.grey500;

  /// Text on a dark or saturated surface. Warm white `#FFFAF2` — the only
  /// white in the brand skin.
  static const Color textOnDark = _brand
      ? BrandRamps.warmWhite
      : LegacyHues.white;

  /// A tappable link.
  static const Color textLink = _brand ? BrandRamps.teal700 : LegacyHues.indigo;

  // ── Glyphs ───────────────────────────────────────────────────────────────
  //
  // An icon is a *shape* the theme colours in, never a picture that carries
  // its own palette. 45 of the SVGs in `assets/icons` ship a baked-in
  // gradient from the previous look, so anything that paints one without a
  // colour filter renders last season's brand no matter what this file says.
  // `AppIcon` exists to make that impossible; these are the tones it offers.

  /// The default glyph: navy ink, the same voice as body copy.
  static const Color iconDefault = textPrimary;

  /// A glyph that supports rather than leads: row affordances, metadata,
  /// an inactive tab.
  static const Color iconMuted = textMuted;

  /// A glyph on pink, navy or any other saturated face.
  static const Color iconOnBrand = textOnDark;

  /// A glyph that *is* the action — a live filter, a selected slot.
  static const Color iconAction = actionRecommended;

  // ── Surfaces ─────────────────────────────────────────────────────────────

  /// The scaffold background — the warm tray everything else sits on.
  static const Color surfacePage = _brand ? BrandRamps.tray : LegacyHues.white;

  /// A card, sheet or dialog: the cool face of anything raised off the tray.
  static const Color surfaceCard = _brand ? BrandRamps.card : LegacyHues.white;

  /// A panel raised above the page but below a dialog. Shares the [card]
  /// face — in a flat material, "raised" is told by the bevel and the
  /// ambient shadow, not by a different fill.
  static const Color surfaceRaised = _brand
      ? BrandRamps.card
      : LegacyHues.white;

  /// An inner tinted region: a nested row, a chip strip, a bottom-sheet
  /// ground. One step down from [surfaceCard], not yet a well.
  static const Color surfaceSunken = _brand
      ? BrandRamps.sub
      : LegacyHues.grey100;

  /// A neutral light fill for read-only fields and inert tiles — the shallow
  /// well, so it reads as inert rather than as something you can press.
  static const Color surfaceMuted = _brand
      ? BrandRamps.wellAlt
      : LegacyHues.grey100;

  /// The fill behind a form field or an inline chip: the well. Anything you
  /// type into is cut *into* the surface, never raised off it.
  static const Color surfaceField = _brand
      ? BrandRamps.well
      : Color(0x1AB1AFE9);

  /// The fill of a selected row, tile or chip in a list or picker.
  static const Color surfaceSelected = _brand
      ? BrandRamps.pinkTint
      : Color(0xFFF9F5FA);

  /// A dark surface: the navy rail, an inverse banner.
  static const Color surfaceInverse = _brand
      ? BrandRamps.navy
      : LegacyHues.navy;

  /// A scrim over content, e.g. behind a dialog or on a media overlay.
  static const Color scrim = _brand ? BrandRamps.navy : LegacyHues.black;

  // ── Borders and dividers ─────────────────────────────────────────────────

  /// The faintest rule: the 1px hairline round a card, and the line between
  /// list rows. Translucent navy, so it darkens whatever it sits on rather
  /// than painting a grey line over it.
  static const Color borderHairline = _brand
      ? Color(0x120A1C5D)
      : Color(0xFFE9ECEF);

  /// A visible card or input border.
  static const Color border = _brand ? Color(0x140A1C5D) : Color(0xFFE0E0E0);

  /// The border of a text field or a bordered chip. In the legacy skin this is
  /// [textPrimary] at 40% alpha, which is why it reads as a tinted rather than
  /// a neutral edge.
  static const Color borderField = _brand
      ? Color(0x1F0A1C5D)
      : Color(0x66573353);

  /// A border that needs to read as an edge, e.g. a focused field.
  static const Color borderStrong = _brand
      ? Color(0x290A1C5D)
      : LegacyHues.grey400;

  /// The focus ring. Pink: the field you are typing into is the thing you
  /// are acting on, and pink is what the app uses to say so.
  static const Color focusRing = _brand
      ? BrandRamps.pink600
      : LegacyHues.indigo;

  /// A divider between sections.
  static const Color divider = _brand ? Color(0x140A1C5D) : LegacyHues.grey400;

  // ── Material — the depth set the flat skeuomorphic surfaces are built from
  //
  // Depth comes from four things and never from a gradient: a lit bevel on
  // the top edge, an ambient shadow below, an inset shadow for anything
  // recessed, and a solid rim under anything you press. Light always comes
  // from directly above.

  /// The base tint of every **ambient** drop shadow. A warm brown, so shade
  /// cast onto the warm [surfacePage] reads as shade, not as grey haze.
  /// [AppElevation] applies the alpha.
  static const Color shadowAmbient = _brand
      ? BrandRamps.shadowWarm
      : LegacyHues.black;

  /// The base tint of every **inset** shadow — wells, troughs, recessed
  /// keys. Navy, never black.
  static const Color shadowInset = _brand ? BrandRamps.ink : LegacyHues.black;

  /// The lit top edge of a raised **light** surface (card, key face, chip).
  static const Color bevelLit = _brand ? BrandRamps.white : LegacyHues.white;

  /// The lit top edge of a raised **dark** surface (impact card, toast, a
  /// pink key) — warm white, so the highlight matches the ink on it.
  static const Color bevelGloss = _brand
      ? BrandRamps.warmWhite
      : LegacyHues.white;

  /// The solid under-edge of a key faced in [surfaceCard].
  static const Color rimNeutral = _brand
      ? BrandRamps.neutralRim
      : LegacyHues.grey300;

  /// The solid under-edge of the recommended (pink) key.
  static const Color rimAction = _brand ? BrandRamps.pinkRim : LegacyHues.navy;

  /// The solid under-edge of a [actionSecondary] key.
  static const Color rimSecondary = _brand
      ? BrandRamps.tealRim
      : LegacyHues.navy;

  /// The solid under-edge of a destructive key.
  static const Color rimDestructive = _brand
      ? BrandRamps.danger600
      : LegacyHues.red;

  /// The solid under-edge of a navy (impact) key.
  static const Color rimImpact = _brand ? BrandRamps.navy900 : LegacyHues.black;

  // ── Status ───────────────────────────────────────────────────────────────

  /// Success: a completed upload, a met ratio, a paid invoice.
  static const Color statusSuccess = _brand
      ? BrandRamps.green600
      : LegacyHues.green;

  /// The soft tint that pairs with [statusSuccess].
  static const Color statusSuccessSoft = _brand
      ? BrandRamps.greenTint
      : Color(0xFFE8F5E9);

  /// Warning: something needs attention but nothing has failed.
  static const Color statusWarning = _brand
      ? BrandRamps.sun400
      : LegacyHues.orange;

  /// The soft tint that pairs with [statusWarning].
  static const Color statusWarningSoft = _brand
      ? BrandRamps.sunTint
      : Color(0xFFFFF3E0);

  /// Error: a failed request, a validation failure, a destructive action.
  static const Color statusError = _brand
      ? BrandRamps.danger500
      : LegacyHues.red;

  /// The soft tint that pairs with [statusError].
  static const Color statusErrorSoft = _brand
      ? BrandRamps.dangerTint
      : Color(0xFFFFEBEE);

  /// A stronger, more saturated error tone than [statusError] — used for
  /// destructive-action accents and required-field emphasis.
  static const Color statusErrorStrong = _brand
      ? BrandRamps.danger600
      : Color(0xFFB3261E);

  /// Information: a neutral notice.
  static const Color statusInfo = _brand ? BrandRamps.teal500 : LegacyHues.blue;

  /// The soft tint that pairs with [statusInfo].
  static const Color statusInfoSoft = _brand
      ? BrandRamps.tealTint
      : Color(0xFFE3F2FD);

  /// A stronger success tone, for ink that has to sit on [statusSuccessSoft].
  static const Color statusSuccessStrong = _brand
      ? BrandRamps.green700
      : Color(0xFF1B5E20);

  /// A stronger warning tone, for ink that has to sit on [statusWarningSoft].
  static const Color statusWarningStrong = _brand
      ? BrandRamps.sun600
      : Color(0xFFC05621);

  // ── Domain coding ────────────────────────────────────────────────────────
  //
  // Rule 4 of the design language: teal is anything about a child, sun is
  // anything about a member of staff. Neither is decoration and neither is a
  // status — on an attendance, classroom or scheduling screen this split is
  // how a child's row reads apart from an adult's at a glance.

  /// Anything about a child: avatars, capacity troughs, student-scoped tiles.
  static const Color domainStudent = _brand
      ? BrandRamps.teal600
      : LegacyHues.blue;

  /// The tint [domainStudent] sits on.
  static const Color domainStudentSoft = _brand
      ? BrandRamps.tealTint
      : LegacyHues.grey100;

  /// Readable ink on [domainStudentSoft].
  static const Color domainStudentInk = _brand
      ? BrandRamps.teal700
      : LegacyHues.blue;

  /// Anything about a member of staff.
  static const Color domainStaff = _brand
      ? BrandRamps.sun400
      : LegacyHues.amber;

  /// The tint [domainStaff] sits on.
  static const Color domainStaffSoft = _brand
      ? BrandRamps.sunTint
      : LegacyHues.grey100;

  /// Readable ink on [domainStaffSoft]. `sun600` is too light to sit on it.
  static const Color domainStaffInk = _brand
      ? BrandRamps.sunText
      : LegacyHues.orange;

  // ── Categorical data ─────────────────────────────────────────────────────
  //
  // A rotating series palette: chart bands, legend swatches, conversation
  // role chips, attachment-type glyphs. These carry no status meaning, only
  // "this one is not that one", so the only rule is that neighbours read
  // apart. `*Soft` is the fill; the plain step is the ink or the solid.

  static const Color dataTeal = _brand ? BrandRamps.teal500 : LegacyHues.blue;
  static const Color dataTealSoft = _brand
      ? BrandRamps.teal200
      : LegacyHues.lavender;
  static const Color dataPink = _brand ? BrandRamps.pink500 : LegacyHues.pink;
  static const Color dataPinkSoft = _brand
      ? BrandRamps.pink200
      : LegacyHues.pinkLight;
  static const Color dataSun = _brand ? BrandRamps.sun400 : LegacyHues.amber;
  static const Color dataSunSoft = _brand
      ? BrandRamps.sun200
      : LegacyHues.grey200;
  static const Color dataGreen = _brand
      ? BrandRamps.green500
      : LegacyHues.green;
  static const Color dataGreenSoft = _brand
      ? BrandRamps.green200
      : LegacyHues.grey200;
  static const Color dataPurple = _brand
      ? BrandRamps.purple400
      : LegacyHues.violet;
  static const Color dataPurpleSoft = _brand
      ? BrandRamps.purple200
      : LegacyHues.lavender;
  static const Color dataOrange = _brand
      ? BrandRamps.orange400
      : LegacyHues.orange;
  static const Color dataOrangeSoft = _brand
      ? BrandRamps.orange200
      : LegacyHues.grey200;

  // ── Over media ───────────────────────────────────────────────────────────
  //
  // A photo or a video is not an app surface: chrome laid over one needs its
  // own translucent set, because nothing in the L4 ramp is legible there.

  /// A caption or hint over media.
  static const Color onMediaHint = _brand
      ? Color(0x8AFFFAF2)
      : Color(0x8AFFFFFF);

  /// The rest state of a scrubber track over media.
  static const Color onMediaTrack = _brand
      ? Color(0x3DFFFAF2)
      : Color(0x3DFFFFFF);

  /// The wash that puts controls in front of a photo.
  static const Color mediaScrim = _brand
      ? Color(0xB3061240)
      : Color(0xB3000000);
}

// ═══════════════════════════════════════════════════════════════════════════
// 5b. MOTION
// ═══════════════════════════════════════════════════════════════════════════

/// Durations and curves. Gentle, sparing, physical: objects settle, they
/// never whip. Ported from the design system's `motion.css`.
class AppMotion {
  AppMotion._();

  /// 90 ms — a key going down or coming back up. Must feel instant.
  static const Duration press = Duration(milliseconds: 90);

  /// 160 ms — a small state change.
  static const Duration fast = Duration(milliseconds: 160);

  /// 200 ms — the default.
  static const Duration base = Duration(milliseconds: 200);

  /// 300 ms — a panel or sheet moving.
  static const Duration panel = Duration(milliseconds: 300);

  /// How far a rimmed key sinks, in logical pixels. The rim collapses from
  /// [AppElevation.rimDepth] to [AppElevation.rimDepthPressed] over the same
  /// distance, so the face lands exactly on the rim.
  static const double pressTravel = 3;

  /// How far a non-rimmed tappable surface sinks — a row, a card, a chip.
  static const double pressTravelSurface = 2;

  /// `cubic-bezier(0.22, 1, 0.36, 1)`, near enough.
  static const Curve easeOut = Curves.easeOutCubic;

  /// `cubic-bezier(0.4, 0, 0.2, 1)`.
  static const Curve easeInOut = Curves.easeInOutCubic;
}

// ═══════════════════════════════════════════════════════════════════════════
// 6. FONTS
// ═══════════════════════════════════════════════════════════════════════════

/// Font families bundled with the app. Every name here must match a `family:`
/// entry in `pubspec.yaml`, or Flutter falls back to the platform default
/// silently.
class AppFontFamilies {
  AppFontFamilies._();

  /// Poppins — the geometric sans the ChildcareWow brand guide substitutes for
  /// Modulus Pro.
  ///
  /// Three weights are bundled, matching what the guide prescribes: Medium
  /// (500) body, Semi Bold (600) headings, Bold (700) emphasis, plus a Medium
  /// italic. Any other weight a call site asks for resolves to the nearest of
  /// these, so `w400` body text renders at Medium — which is what the guide
  /// wants body copy set in anyway. See the `fonts:` block in `pubspec.yaml`.
  static const String poppins = 'Poppins';

  /// Manrope — the family the app has shipped with. Weights 200–800.
  static const String manrope = 'Manrope';

  /// Inter — used by a handful of legacy screens. Weights 100–900.
  static const String inter = 'Inter';

  /// Imperial Script — decorative script, used for rendered signatures.
  static const String imperialScript = 'Imperial_Script';

  /// Mervale Script — the second decorative script.
  static const String mervaleScript = 'MervaleScript';
}

/// Fonts **by role**. Product code names the role, never the family, so
/// swapping a family is a one-line change here (or a skin flip above).
class AppFonts {
  AppFonts._();

  /// Body copy, labels, values — the app's default family. This is the one
  /// name that should appear in almost every text style.
  static const String body = _brand
      ? AppFontFamilies.poppins
      : AppFontFamilies.manrope;

  /// Headings. The same family as [body] in both skins; kept as its own role
  /// so a display face can be introduced without touching body text.
  static const String display = _brand
      ? AppFontFamilies.poppins
      : AppFontFamilies.manrope;

  /// Numeric/tabular chrome, e.g. countdown digits.
  static const String numeric = _brand
      ? AppFontFamilies.poppins
      : AppFontFamilies.manrope;

  /// Rendered signatures and other decorative script.
  static const String script = AppFontFamilies.imperialScript;

  /// The alternate decorative script.
  static const String scriptAlt = AppFontFamilies.mervaleScript;

  /// Code and fixed-width values.
  static const String mono = 'monospace';
}

// ═══════════════════════════════════════════════════════════════════════════
// 7. TYPE SCALE
// ═══════════════════════════════════════════════════════════════════════════

/// Font sizes, weights, line-heights and letter-spacing.
///
/// The `size*` steps mirror the design system's rem scale at a 16px root, and
/// also cover the off-scale sizes the app already renders, so a literal can be
/// swapped for a token without shifting layout.
class AppTypeScale {
  AppTypeScale._();

  // ── Sizes (logical pixels) ───────────────────────────────────────────────
  /// 11px — dense table metadata.
  static const double size2xs = 11;

  /// 12px — eyebrows, badges, captions.
  static const double sizeXs = 12;

  /// 13px — field labels.
  static const double sizeSm = 13;

  /// 14px — the app's workhorse body size.
  static const double sizeBase = 14;

  /// 16px — emphasised body, button labels.
  static const double sizeMd = 16;

  /// 18px — card and section headings.
  static const double sizeLg = 18;

  /// 20px — panel headings.
  static const double sizeXl = 20;

  /// 24px — screen titles, statistics.
  static const double size2xl = 24;

  /// 30px — large statistics.
  static const double size3xl = 30;

  /// 36px — hero figures.
  static const double size4xl = 36;

  /// Off-scale legacy size, retained so existing UI migrates onto a token
  /// without shifting. Follows the same convention as `AppSpacing.s10` etc.
  static const double s32 = 32;

  // ── Weights ──────────────────────────────────────────────────────────────
  /// 400 — the lightest weight used for readable copy.
  static const FontWeight regular = FontWeight.w400;

  /// 500 — body copy in the brand design language.
  static const FontWeight medium = FontWeight.w500;

  /// 600 — headings in the brand design language.
  static const FontWeight semiBold = FontWeight.w600;

  /// 700 — titles and emphasis.
  static const FontWeight bold = FontWeight.w700;

  /// 800 — eyebrows and small all-caps labels.
  static const FontWeight extraBold = FontWeight.w800;

  /// The weight body copy defaults to. The brand guide sets body at Medium.
  static const FontWeight bodyWeight = _brand ? medium : regular;

  /// The weight headings default to.
  static const FontWeight headingWeight = _brand ? semiBold : bold;

  // ── Line heights (multipliers, for TextStyle.height) ─────────────────────
  /// 1.15 — headings.
  static const double leadingTight = 1.15;

  /// 1.3 — subheadings and compact rows.
  static const double leadingSnug = 1.3;

  /// 1.65 — body copy.
  static const double leadingBody = 1.65;

  // ── Letter spacing ───────────────────────────────────────────────────────
  /// Headings tuck in slightly.
  static const double trackingHeading = -0.015;

  /// Eyebrows and small caps open right up.
  static const double trackingEyebrow = 0.12;
}
