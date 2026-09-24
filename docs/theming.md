# Theming: one file controls the app's colours and fonts

Everything visual in WowCare resolves to a token in **`lib/core/theme/app_theme_config.dart`**.
No other file under `lib/` names a colour or a font family. Change a value in that
file and the whole app follows.

Two guard tests enforce this. `test/core/theme/centralized_theme_test.dart` fails
the build if any file reintroduces a `Colors.*` reference, a bare `'Manrope'`-style
font string, a colour literal of its own, or a gradient.
`test/core/theme/flat_skeu_material_test.dart` guards the material itself.

---

## Switching the entire app's look

One constant:

```dart
// lib/core/theme/app_theme_config.dart
static const AppSkin skin = AppSkin.childcareWow;   // ← change this
```

| Skin | Palette | Typeface |
|---|---|---|
| `AppSkin.legacy` | plum `#573353` text, indigo `#5978F7` brand, white ground | Manrope |
| `AppSkin.childcareWow` (**current default**) | navy `#0A1C5D` ink, pink `#E01B5D` action, warm `#FBF8F2` ground | Poppins |

`AppSkin.childcareWow` is the ChildcareWow brand design language, taken from
*WowCare Design Components* and the brand colour and type guide. Both skins are
fully populated, so the flip is a one-line change with no call-site edits.

Verified effect of flipping the constant:

```
                                    legacy              childcareWow
AppFonts.body                       Manrope             Poppins
ThemeData.fontFamily                Manrope             Poppins
AppTextStyles.title.fontFamily      Manrope             Poppins
AppColors.themeColor                #5978F7             #E01B5D
AppColors.primaryColor              #573353             #0A1C5D
AppColors.errorColor                #D32F2F             #D92D20
AppColors.successColor              #388E3C             #0E8F53
AppColors.cardColor                 #FFFFFF             #FBFCFF
AppColors.fieldBackgroundColor      #1AB1AFE9           #E5EAF7
AppColors.primaryGradientColors     #6F8CFF → #9C84FF   #E01B5D → #E01B5D
lightTheme.primaryColor             #5978F7             #E01B5D
```

### Why the switch is compile-time

The app declares thousands of `const TextStyle`s and `const BoxDecoration`s, and a
`const` cannot read from an `InheritedWidget`. Every token is therefore a `const`
selected by a `const` ternary on the skin, which is what lets a single constant
reach `const` call sites without rewriting every widget. A runtime toggle would
mean converting all of them to `Theme.of(context)` lookups.

---

## How the file is laid out

| Section | Holds | Reference it? |
|---|---|---|
| `AppSkin` / `AppThemeConfig` | The switch. | No, just edit it. |
| `BrandRamps` | The ChildcareWow palette, ramp by ramp (`teal500`, `pink600`, `ink`…). | No. Raw palette. |
| `LegacyHues` | The hues the app ships with today (`plum`, `indigo`, `lavender`…). | No. Raw palette. |
| `MaterialHues` | Exact values of the Flutter `Colors.*` swatches the app used to reach for. | Only to preserve an exact Material shade. |
| `AppPalette` | **Semantic roles.** `textPrimary`, `surfaceCard`, `statusError`, `borderHairline`… | **Yes. Prefer these.** |
| `AppMotion` | Durations, curves, and how far a pressed thing sinks. | Yes. |
| `AppFontFamilies` | The families registered in `pubspec.yaml`. | Only to pin one specific family. |
| `AppFonts` | **Font roles.** `body`, `display`, `numeric`, `script`, `mono`. | **Yes. Prefer these.** |
| `AppTypeScale` | Sizes, weights, line-heights, letter-spacing. | Yes, for new text. |

Four more files sit on top of it, and they are what a widget actually calls:

| File | Holds |
|---|---|
| `app_elevation.dart` | `AppElevation`: the shadow, bevel, well and rim recipes, plus `AppInset`. |
| `skeu_decoration.dart` | `SkeuDecoration`, a `Decoration` that can paint an *inset* shadow, which `BoxDecoration` cannot. |
| `skeu_inset_paint.dart` | The inset drawing itself, shared by `SkeuDecoration` and `SkeuInnerShadow`. Blurred insets are rasterised once per recipe into a nine-slice tile and reused; drawing them from scratch per well per frame is what made the keyboard slow. |
| `app_surfaces.dart` | **`AppSurfaces`**: one ready-made decoration per design specimen. **This is the one to call.** |
| `skeu_press.dart` | `SkeuPressable`, the app's single press effect. |

`AppPalette` is the layer the skin switch rewires. Each role is written as
`_brand ? <brand value> : <legacy value>`, so both skins are visible side by side.

`AppColors` (`lib/core/theme/app_colors.dart`) is now a **directory, not a
definition**: its semantic tokens forward to `AppPalette`, and its feature-scoped
tokens (`billing*`, `attendance*`, `activity*`…) forward to `AppPalette`,
`LegacyHues` or `MaterialHues` wherever their value matches one.

---

## The flat skeuomorphic material

Under `AppSkin.childcareWow` the app is built from physical, pressable objects
on a warm tray. **Rule 3 of the design language: there are no gradients.** Every
fill is one flat colour, and an object reads as an object because of four things
instead: a lit bevel on the *top* edge, an ambient shadow *below*, an inset
shadow for anything recessed, and a solid rim under anything you press. Light
always comes from directly above.

### The L4 surface set

Nine tones, warm at the bottom and cooler as they rise. They live on
`BrandRamps` and reach product code through the `AppPalette` roles beside them.

| Tone | Hex | Role | Where |
|---|---|---|---|
| tray | `#FBF8F2` | `surfacePage` | scaffolds, drawer, bottom bar, tab strips |
| card | `#FBFCFF` | `surfaceCard`, `surfaceRaised` | anything raised off the tray |
| sub | `#EFF2FB` | `surfaceSunken` | inner tinted rows, chips, sheet grounds |
| well | `#E5EAF7` | `surfaceField` | fields, tracks, troughs, disabled keys |
| wellAlt | `#EDF1FA` | `surfaceMuted` | segmented rests, inert tiles |
| wellDeep | `#D8E0F2` | none yet | sheet grabbers, inset rules |
| wellDeepest | `#BFC9E2` | none yet | "not marked" dots, inert markers |
| offWhite | `#F5F8FE` | none yet | a panel that must separate from `card` |
| warmWhite | `#FFFAF2` | `textOnDark`, `onBrand`, `bevelGloss` | **the only white** |

Pure `#FFFFFF` and pure black are retired. Ink on a dark face is warm white.

### Colour roles

| Role | Value |
|---|---|
| Action: primary keys, active nav, links, required asterisks | pink `#E01B5D`, rim `#A10F45`, tint `#FBDEE9`, text-on-tint `#BA124C` |
| Ink and impact | navy `#0A1C5D`, soft `#4D5983`, faint `#8A93B2` |
| Secondary action | teal `#1D9B9E` / `#1A7C7F` |
| **Student** domain coding | teal `#1A7C7F` on tint `#D2F1F2` |
| **Staff** domain coding | sun `#F9AD3A`, dark `#D3790C`, tint `#FBEBCF`, text `#8A5208` |
| Status | green `#0E8F53` tint `#D3F4E4`; danger `#D92D20` tint `#FBDEDC`; warnings borrow the sun ramp |

Teal and sun are **domain** colours, not decoration: on an attendance or
classroom screen the split is how a child's row reads apart from an adult's.
They are load-bearing, so keep them off the chrome. Pink is the action and
nothing else; navy is ink, and at most one navy impact card per screen.

### The four devices, as CSS

```
card     radius 20   fill #FBFCFF   border 1px rgba(10,28,93,.07)
                     inset 0 1px 0 rgba(255,255,255,.95)      <- lit top bevel
                     0 7px 16px -14px rgba(63,45,20,.6)       <- warm ambient

well     radius 16   fill #E5EAF7
                     inset 0 3px 6px rgba(10,28,93,.14)
                     inset 0 -1px 0 rgba(255,255,255,.8)

key      radius 16   fill #E01B5D   text #FFFAF2
                     0 4px 0 #A10F45                          <- the rim
                     0 12px 22px -14px rgba(224,27,93,.8)
         pressed:    translateY(3px), rim drops to 0 1px 0

impact   radius 20   fill #0A1C5D   text #FFFAF2
                     inset 0 1px 0 rgba(255,250,240,.22)
                     0 14px 26px -18px rgba(63,45,20,.6)
```

### Using it

Do not assemble these by hand. `AppSurfaces` has one builder per specimen, and
each returns a `SkeuDecoration`, which is a `Decoration`, so a widget swaps its
`decoration:` and nothing about its content moves or shifts:

```dart
Container(
  decoration: AppSurfaces.card(),   // was BoxDecoration(color: ..., boxShadow: ...)
  child: ...,                        // unchanged
)

Container(decoration: AppSurfaces.key(KeyVariant.primary));
Container(decoration: AppSurfaces.pill(AppTone.success));  // ink: AppTone.success.ink
```

The full set: `card`, `panel`, `impact`, `toast`, `sub`, `tray`, `bar`, `sheet`,
`well`, `field`, `trough`, `segmented`, `segmentSelected`, `key`, `keyPressed`,
`keyInk`, `iconKey`, `fab`, `pill`, `chip`, `chipSelected`, `avatar`, `knob`,
`navActive`, `emptyIcon`.

Wrap anything tappable in `SkeuPressable`: `.key` for a rimmed key (sinks 3px,
exactly the distance the rim collapses by), `.surface` for everything else
(sinks 2px). That is the app's only press effect.

Gradient SVGs are flattened at the call site with
`ColorFilter.mode(colour, BlendMode.srcIn)`. No asset is edited. Note that
`BlendMode.dstIn` *masks* a glyph rather than recolouring it, which is not the
same thing.

### The four rules the guard test enforces

`centralized_theme_test.dart` checks four things about every `.dart` file under
`lib/`. All four are absolute: the allowlists they started as reached zero.

| Rule | Why |
|---|---|
| no `LinearGradient`, `RadialGradient`, `SweepGradient` or `ShaderMask` | rule 3: every fill is flat, depth is the bevel, the well, the rim and the ambient shadow |
| no `Color(0x…)`, `Color.fromRGBO` or `Color.fromARGB` outside `app_theme_config.dart` | a literal is invisible to the skin switch |
| no `Colors.*` except `transparent` | a Material swatch is not reachable from a palette either |
| no bare `SvgPicture`; use `AppIcon` or `AppArtwork` | 45 of the icon assets carry a baked-in gradient, so an untinted glyph paints last season's brand |

There is a fifth check with no rule attached: `material_specimen_test.dart`
renders the material and the real widgets onto one sheet at
`test/core/theme/goldens/material_specimen.png`. It is written, never
compared (see its header for why), so it is a picture to look at rather than
a regression test.

---

## Adding or changing a colour

1. **Is it a role?** Something that means "an error", "a card surface", "a
   hairline"? Add it to `AppPalette` and give both skins a value. That is the
   normal case.
2. **Is it decorative and genuinely local?** A pastel chip in a rotating palette,
   a per-category badge tint? Add a feature-scoped constant to `AppColors`,
   matching the existing `billing*` / `attendance*` naming. This keeps the
   semantic layer small and honest.
3. **Never** write a `Color(0x…)` or a `Colors.*` in a widget file. The guard test
   will fail.

## Adding or changing a font

Point an `AppFonts` role at a different family, or add a family to
`AppFontFamilies` and register it under `fonts:` in `pubspec.yaml`. The guard test
checks that every family an `AppFonts` role resolves to is actually bundled, so a
typo cannot silently fall back to the platform font.

`Fonts` (the old `Fonts.manrope` class) is `@Deprecated` but still compiles. It
pins a specific family, so text styled through it does **not** follow the skin
switch. Use `AppFonts.body` instead.

---
## What the centralisation pass covered

- 566 font-family references across 126 files → `AppFonts` roles. Zero raw
  font-family strings remain in `lib/`.
- 650 `Colors.*` references across 109 files → tokens. Only `Colors.transparent`
  remains, which means the same thing under every skin.
- 129 raw colour literals → existing tokens and four new cross-module roles
  (`borderField`, `surfaceSelected`, `brandSoft`, `statusErrorStrong`).
- `AppColors`: all 435 tokens now source their value from the config file.
- `lightTheme` / `darkTheme`: colours and typography now come from the tokens.
- Poppins registered in `pubspec.yaml` so the brand skin renders rather than
  silently falling back. Three weights only (Medium 500, Semi Bold 600, Bold
  700, plus a Medium italic), which is what the brand guide prescribes: 648 KB
  instead of the 1.1 MB a full 400 to 800 set costs. Flutter resolves the other
  weights the app asks for to the nearest bundled face, so the 192 `w400` sites
  render at Medium, where the guide wants body copy anyway.

That pass changed no pixel: under `AppSkin.legacy` all 435 `AppColors` tokens
rendered byte-identical to `develop`. It is what made the re-skin below a
one-file edit rather than a thousand call-site edits.

## What the flat skeuomorphic pass covered

Every screen changed colour and material. No widget changed the information
it shows.

### The foundation

- The **L4 surface ramp**, the L4 tints, the rims and the shadow bases in
  `BrandRamps`.
- The **semantic roles re-pointed**: `brand` from teal to pink, `surfacePage`
  to the warm tray, `surfaceCard` to the cool card face, `surfaceField` to the
  well, `textOnDark` and `onBrand` to warm white.
- **`AppElevation`, `SkeuDecoration`, `AppSurfaces`, `SkeuPressable`,
  `SkeuKeyBox`** and `SkeuInnerShadow`: the material, and the primitives
  ported from the `wowcare-skeumorph` kit.

### Everything a colour can be, is a role

`AppColors` was a directory with 287 hex values still in it. It is a directory
now. Three groups of roles were added to reach zero:

* **`domainStudent` / `domainStaff`** (+`Soft`, +`Ink`): rule 4's teal/sun
  split. Not decoration and not status. It is how a child's row reads apart
  from an adult's.
* **`data*`**: `dataTeal`, `dataPink`, `dataSun`, `dataGreen`, `dataPurple`,
  `dataOrange`, each with a `Soft`. A categorical series for charts, legends,
  role chips and attachment glyphs. No status meaning, only "this one is not
  that one".
* **`onMediaHint` / `onMediaTrack` / `mediaScrim`**: chrome over a photo or a
  video, where nothing in the L4 ramp is legible.

Plus `statusSuccessStrong` and `statusWarningStrong` for ink that has to sit
on the soft tints, and `iconDefault` / `iconMuted` / `iconOnBrand` /
`iconAction` for glyphs.

### Material's own widgets

`ColorScheme.fromSeed(pink)` derived thirty-odd roles algorithmically from one
colour, which made every Material-owned surface a pink-tinted neutral that
this file could not reach: the date picker's ground, a dropdown's menu, an
`AlertDialog`. The scheme is written out role by role from `AppPalette` now,
`surfaceTint` is transparent everywhere, and component themes are set for the
app bar, card, dialog, bottom sheet, popup and dropdown menus, date and time
pickers, divider, list tile, chip, snackbar, tooltip, progress indicators,
switch, checkbox, radio, text selection, tab bar and input fields.

### Glyphs

`AppIcon` paints every SVG through `ColorFilter.mode(token, BlendMode.srcIn)`,
so an asset cannot carry a colour of its own. `AppArtwork` is the deliberate
opt-out for a pictogram whose colours are the content. Two assets shipped a
full-bleed opaque background rect from Figma that `srcIn` turned into a solid
block; those rects are gone.

### The press

A key's rim is a shadow on the key's own decoration, so translating the widget
carries the rim down with the face and nothing appears to move. `SkeuKeyBox`
does both halves: the face travels down 3px while the decoration swaps to
`keyPressed`, whose rim is 1px instead of 4. The key's bottom edge stays put
and only the face descends, onto the rim. A rimless secondary key pulls its
ambient shadow in close instead and travels 2px.

**Deliberately not touched:**

- **Font sizes** stay at their call sites. `AppTypeScale` exists for new text;
  migrating ~1,250 existing `fontSize:` values is a layout change, not a
  colour or font change.
- **`whiteColor` is the cool card face** at all 199 of its sites. Where one is
  ink on a saturated face rather than a surface it wants `textOnDarkColor`
  instead; that triage is per-module and still open.
- **A text field gets the well's inset from `SkeuFieldWell`**, which paints
  it over the field rather than replacing the field's decoration. That was
  the way round the problem: an `InputDecoration` cannot carry an inset, and
  wrapping the field in a decorated box would have put its error and counter
  text inside the well.
- **Five media-viewer scaffolds keep a black ground.** A photo on a warm tray
  is worse, not better.

Nothing moved between folders, and no file was renamed.
