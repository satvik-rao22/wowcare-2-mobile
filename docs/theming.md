# Theming — one file controls the app's colours and fonts

Everything visual in WowCare resolves to a token in **`lib/core/theme/app_theme_config.dart`**.
No other file under `lib/` names a colour or a font family. Change a value in that
file and the whole app follows.

A guard test enforces this: `test/core/theme/centralized_theme_test.dart` fails the
build if any file reintroduces a `Colors.*` reference or a bare `'Manrope'`-style
font string.

---

## Switching the entire app's look

One constant:

```dart
// lib/core/theme/app_theme_config.dart
static const AppSkin skin = AppSkin.legacy;   // ← change this
```

| Skin | Palette | Typeface |
|---|---|---|
| `AppSkin.legacy` (**current default**) | plum `#573353` text, indigo `#5978F7` brand | Manrope |
| `AppSkin.childcareWow` | navy `#0A1C5D` ink, brand teal `#27BEC1`, pink `#F83D76` | Poppins |

`AppSkin.childcareWow` is the ChildcareWow brand design language, taken from
*WowCare Design Components* and the brand colour and type guide. Both skins are
fully populated, so the flip is a one-line change with no call-site edits.

Verified effect of flipping the constant:

```
                                    legacy              childcareWow
AppFonts.body                       Manrope             Poppins
ThemeData.fontFamily                Manrope             Poppins
AppTextStyles.title.fontFamily      Manrope             Poppins
AppColors.themeColor                #5978F7             #27BEC1
AppColors.primaryColor              #573353             #0A1C5D
AppColors.errorColor                #D32F2F             #D92D20
AppColors.successColor              #388E3C             #13B167
AppColors.primaryGradientColors     #6F8CFF → #9C84FF   #45CDD1 → #1D9B9E
lightTheme.primaryColor             #5978F7             #27BEC1
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
| `AppFontFamilies` | The families registered in `pubspec.yaml`. | Only to pin one specific family. |
| `AppFonts` | **Font roles.** `body`, `display`, `numeric`, `script`, `mono`. | **Yes. Prefer these.** |
| `AppTypeScale` | Sizes, weights, line-heights, letter-spacing. | Yes, for new text. |

`AppPalette` is the layer the skin switch rewires. Each role is written as
`_brand ? <brand value> : <legacy value>`, so both skins are visible side by side.

`AppColors` (`lib/core/theme/app_colors.dart`) is now a **directory, not a
definition**: its semantic tokens forward to `AppPalette`, and its feature-scoped
tokens (`billing*`, `attendance*`, `activity*`…) forward to `AppPalette`,
`LegacyHues` or `MaterialHues` wherever their value matches one.

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

## What this pass covered, and what it did not

**Centralised** (this phase):

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
  instead of the 1.1 MB a full 400–800 set costs. Flutter resolves the other
  weights the app asks for to the nearest bundled face, so the 192 `w400` sites
  render at Medium, where the guide wants body copy anyway.

**Deliberately not touched:**

- **No widget was restyled.** `lightTheme`/`darkTheme` still set only
  `brightness`, `primaryColor`, `colorScheme`, `useMaterial3`, `fontFamily` and
  `textTheme`. No `appBarTheme`, `inputDecorationTheme` or button themes were
  added, because those would restyle every widget that currently relies on
  Flutter's defaults.
- **No colour changed value.** Under `AppSkin.legacy` all 435 `AppColors` tokens
  render byte-identical to `develop`, verified by dumping every token's ARGB on
  both branches and diffing.
- **Font sizes** were left at their call sites. `AppTypeScale` exists for new
  text; migrating ~1,250 existing `fontSize:` values is a layout change, not a
  colour or font change.
- **186 module-local colour literals** remain across 52 files, mostly
  already-named per-module palettes: `scheduling_staff_shift_style.dart`,
  `scheduling_block_status_style.dart`, `notification_category_style.dart`,
  `enrollment_card.dart`'s breakdown-bar segments, and roughly 85 one-offs in
  `lib/shared/common/widgets/`. These are decorative values local to one widget,
  not app-level theme colours. Folding them in is a follow-up.
- `newsletter_color_theme.dart` stays as it is on purpose: those colours arrive
  with the newsletter record and are chosen by its author, so they are data, not
  theming.

Nothing moved between folders, and no file was renamed.
