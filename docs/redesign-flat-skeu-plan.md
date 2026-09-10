# Flat, skeuomorphic re-skin: implementation plan

Re-skin the shipped app to the ChildcareWow design language: no gradients anywhere, a warm
off-white ground, pink and navy as the driving colours, and the skeuomorphic material
(lit top bevel, recessed wells, rimmed keys that sink) from the design components page.

Restyle only. No widget loses, gains or rearranges the information it shows today.

## 0. Sources of truth

**Design folder: `/Users/atharvapatwardhan/work/Redesign`**

| What | File |
|---|---|
| Component recipes, the primary reference | `WowCare Design Components.dc.html`, section `03 Components` (11 live specimens, each with its real CSS) |
| Palette and the L4 surface set | same page, section `01 The palette`; `CLAUDE.md` heading "Colour system" |
| Raw tokens as CSS | `_ds/childcarewow-design-system-1e96c220-d374-4047-a87c-067f2817484e/tokens/` : `colors.css`, `elevation.css`, `radius.css`, `typography.css`, `motion.css` |
| Per-screen specifics | the module pages, `WowCare M01 Authentication.dc.html` through `WowCare M17 Events, Tasks and Calendar.dc.html` |
| Binding rules | `CLAUDE.md` rule 3 (no gradients, flat fills, depth from bevel/well/rim/ambient shadow) and rule 4 (pink is the action, navy the impact, teal and sun are domain coding) |

Two things in that folder must not be used:

* `tokens/surfaces.css` is the marketing website layer and every value in it is a gradient
  (`--surface-card`, `--face-pink`, `--gloss-top`). Rule 3 forbids all of it in the app. Take
  colour from `colors.css` and depth from `elevation.css` instead.
* The consolidated roll-ups (`WowCare Mobile App Consolidated Design.dc.html` and the tablet
  one) mix two generations of screen IDs. Work from the module pages plus Design Components.

Repo side: branch `improvements/centralized-themes`, on top of `cd22e2ed`, which moved every
colour and font in `lib/` behind `lib/core/theme/app_theme_config.dart`. No widget names a
colour any more, so re-pointing one semantic role reaches every call site at once. That commit
is what makes this plan tractable.

There is also a full Flutter skeuomorphic kit on branch `wowcare-skeumorph`
(`lib/app/theme/skeu/`, about 157 KB across 11 files plus a test). We are **not** adopting its
components, because swapping `CustomTextField` for `SkeuTextField` would rearrange screens and
that is a revamp. We port two primitives out of it and leave the rest.

## 1. The target, and the four places your brief overrides the design page

### Colour roles after this work

| Role | Value | Where it lands |
|---|---|---|
| Ground (page, drawer, bottom bar, tab bar) | `#FBF8F2` | every scaffold, the drawer, the nav bar, tab strips |
| Card, bar and key face | `#FBFCFF` | anything raised off the ground |
| Inner tinted row, chip, sheet ground | `#EFF2FB` | bottom sheets, nested rows |
| Well | `#E5EAF7` | fields, tracks, troughs, disabled keys |
| Alt well, deep well, deepest | `#EDF1FA`, `#D8E0F2`, `#BFC9E2` | segmented rests, handles, "not marked" dots |
| Action, active nav, links | pink `#E01B5D`, rim `#A10F45`, tint `#FBDEE9`, text-on-tint `#BA124C` | primary keys, FAB, active nav tile, required asterisks |
| Ink and impact | navy `#0A1C5D`, soft `#4D5983`, faint `#8A93B2` | all text, glyphs, chips when selected, toasts, the one impact card per screen |
| Secondary minor actions, and student-domain coding | teal `#1D9B9E` / `#1A7C7F`, tint `#D2F1F2` | quiet secondary keys, body links, student avatars, stat tiles, capacity troughs |
| Staff-domain coding | sun `#F9AD3A`, dark `#D3790C`, tint `#FBEBCF`, text `#8A5208` | staff avatars, staff-scoped tiles |
| Status | green `#0E8F53` / `#0C7143` tint `#D3F4E4`, danger `#D92D20` / `#B42318` tint `#FBDEDC` | attendance pills, errors, destructive keys. Warnings borrow the sun ramp above |
| Warm white, the only white | `#FFFAF2`, gloss `rgba(255,250,240,a)` | text and glyphs on pink or navy, lit bevels |

Pure `#FFFFFF` and pure black are retired. Today the app has 442 `AppColors.whiteColor` sites
and 121 `AppColors.blackColor` sites, and each one is either a surface (becomes `#FBFCFF`) or
ink on a dark face (becomes `#FFFAF2`). That triage is the bulk of the per-module work.

### Material, ported from `elevation.css` and the `03 Components` specimens

```
card     radius 20   fill #FBFCFF   border 1px rgba(10,28,93,.07)
                     inset 0 1px 0 rgba(255,255,255,.95)      <- lit top bevel
                     0 7px 16px -14px rgba(63,45,20,.6)       <- warm ambient

well     radius 16   fill #E5EAF7
                     inset 0 3px 6px rgba(10,28,93,.14)
                     inset 0 -1px 0 rgba(255,255,255,.8)

key      radius 16   fill #E01B5D   text #FFFAF2
                     0 4px 0 #A10F45                          <- the rim you press away
                     0 12px 22px -14px rgba(224,27,93,.8)
         pressed:    translateY(3px), rim drops to 0 1px 0

impact   radius 20   fill #0A1C5D   text #FFFAF2
                     inset 0 1px 0 rgba(255,250,240,.22)
                     0 14px 26px -18px rgba(63,45,20,.6)
```

Light comes from directly above, always. Bevel on the top edge, shadow below, and no
gradients: that is what makes a flat fill read as a solid object.

### Where your brief and the design components page disagree

These are deliberate. Recorded here so nobody "fixes" them back later, and the design
components page should be updated to match once you confirm, since that page states it is the
reference developers read.

| # | Design components page says | We are doing | Note |
|---|---|---|---|
| 1 | `.tabbar` background `#FBFCFF`, the cool card tone | `#FBF8F2`, the warm tray tone | your call, applies to drawer, bottom bar and tab strips |
| 2 | active tab is a `#FBDEE9` pink-tint tile with a pink glyph and a pink label | active tab is a solid `#E01B5D` pink squircle with a `#FFFAF2` glyph | stronger read, matches your brief |
| 3 | inactive label `#8A93B2` | inactive glyph and label navy ink `#0A1C5D` (soft `#4D5983` for the label) | you asked for black icons; L4 retires pure black, so ink is the honest reading |
| 4 | teal carries student-domain coding (avatars, stat tiles, trough fills) | teal keeps the domain coding, and comes off all chrome | resolved, decision 1 below |

## 2. Phase 0, foundation. One commit, no screen touched

Everything after this phase is a restyle of call sites. This phase builds what they call.

1. **Add the L4 surface ramp** to `BrandRamps` in `lib/core/theme/app_theme_config.dart`:
   `tray #FBF8F2`, `card #FBFCFF`, `sub #EFF2FB`, `well #E5EAF7`, `wellAlt #EDF1FA`,
   `wellDeep #D8E0F2`, `wellDeepest #BFC9E2`, `offWhite #F5F8FE`, `warmWhite #FFFAF2`.
   The class currently stops at the brand ramps and the cool `cream` set, so the L4 surfaces
   have nowhere to live yet.
2. **Re-point the `AppPalette` roles** for the brand skin: `brand` from `teal500` to
   `pink600`, `brandDark` to `pink700`, `surfacePage` to `tray`, `surfaceCard` to `card`,
   `surfaceSunken` to `sub`, `surfaceField` to `well`, `textOnDark` to `warmWhite`,
   `textLink` to `teal700`, and add `actionSecondary` on `teal600`. This one edit is what
   turns 256 `AppColors.themeColor` sites pink and 1135 `AppColors.primaryColor` sites navy.
3. **Flatten the gradient roles.** `AppPalette.gradientPage`, `gradientPrimary`,
   `gradientSecondary` and `gradientPink` become two identical stops, and
   `AppColors.buildScaffoldGradient()` / `buildPrimaryGradient()` / `buildSecondaryGradient()`
   / `buildPinkGradient()` keep their signatures but return a flat fill. Every one of the 123
   files that draws a gradient goes flat the moment this lands, without touching a single
   widget. Those helpers then get deleted per module as call sites move to `AppSurfaces`.
4. **Port two primitives** from `wowcare-skeumorph` into `lib/core/theme/`:
   `skeu_inner_shadow.dart` (Flutter has no inset `BoxShadow`; this paints them by clipping to
   the shape and blurring inward, which is the whole bevel-and-well language) and
   `skeu_press.dart` (the 3 px sink with a 90 ms press curve). Keep the technique, drop the
   token values, which are a generation stale. Land its test too.
5. **Add an elevation and surface layer**: `AppElevation` (the shadow lists above, as
   `List<BoxShadow>` plus `List<AppInset>`) and `AppSurfaces` with decoration builders:
   `card()`, `well()`, `sub()`, `impact()`, `key(variant)`, `iconKey()`, `sheet()`, `fab()`,
   `trough()`, `pill(tone)`. Builders, not widgets, so a widget swaps its `BoxDecoration` and
   nothing about its content moves.
6. **Extend the guard test** `test/core/theme/centralized_theme_test.dart`:
   * no `LinearGradient`, `RadialGradient`, `SweepGradient` or `ShaderMask` under `lib/`,
     starting from an explicit allowlist of the 123 known files that shrinks to zero as the
     modules land. A module is not done while its files are still on that list.
   * no raw `Color(0x...)` outside `app_theme_config.dart`.
   * `AppPalette.surfacePage` is the tray tone, and the brand role is pink not teal.
7. **Fix `docs/theming.md`**: it says `AppSkin.legacy` is the current default and the code says
   `AppSkin.childcareWow` (line 68). Also fold the L4 surface table and the material recipes
   into it, so the file stays the one place a developer reads.

Verification for this phase: `flutter test test/core/theme/`, `flutter analyze` stays at the
140-issue baseline, and one screenshot of the dashboard to confirm the whole app went flat and
warm in a single step.

## 2b. Phase 0 as landed

Done, one commit, no screen touched. What shipped, against the list above:

| # | Item | Landed as |
|---|---|---|
| 1 | L4 surface ramp | `BrandRamps`: `tray card sub well wellAlt wellDeep wellDeepest offWhite warmWhite`, plus the L4 tints (`pinkTint tealTint sunTint sunText greenTint dangerTint`), the rims (`pinkRim tealRim neutralRim`) and the warm shadow base `shadowWarm` |
| 2 | `AppPalette` re-point | `brand` teal500 to pink600, `brandLight` to pink500, `brandDark` to pink700, `onBrand` and `textOnDark` to warmWhite, `surfacePage` to tray, `surfaceCard` and `surfaceRaised` to card, `surfaceSunken` to sub, `surfaceMuted` to wellAlt, `surfaceField` to well, `surfaceSelected` and `brandSoft` to pinkTint, the four border roles to translucent navy, the status tints to their L4 values, `statusSuccess` to green600. New: `actionSecondary`, and a Material block (`shadowAmbient shadowInset bevelLit bevelGloss rimNeutral rimAction rimSecondary rimDestructive rimImpact`) |
| 3 | Gradients flattened | all four roles are two identical stops. `gradientPink` is the one judgement call: deep pink `pink800` rather than the design's `#FBDEE9`, because the guardian bubble's ink is light and chosen at the call site, so the tint would be unreadable until Communication re-skins bubble and ink together |
| 4 | Primitives ported | `lib/core/theme/skeu_inner_shadow.dart`, `lib/core/theme/skeu_press.dart`, with the token values retyped from L4 |
| 5 | Elevation and surfaces | `app_elevation.dart` (`AppInset`, `AppElevation`), `skeu_decoration.dart`, `app_surfaces.dart` (25 builders, `KeyVariant`, `AppTone`), `AppMotion` in the config file, four radii in `AppRadius` |
| 6 | Guard test | two ratcheting allowlists (119 gradient files, 53 colour-literal files), a check that the gradient roles have one stop, and four assertions that the skin really is the flat one. `test/core/theme/flat_skeu_material_test.dart` is new: 26 tests on the material |
| 7 | `docs/theming.md` | default skin corrected, the L4 table, the colour roles, the four recipes and the `AppSurfaces` usage folded in, and the stale "no colour changed value" section rewritten |

**One deviation from the plan worth knowing.** `AppSurfaces` returns a
`SkeuDecoration`, not a `BoxDecoration`. Flutter's `BoxDecoration` cannot paint
an inset shadow, and the bevel and the well are both inset shadows, so a
`BoxDecoration` builder would have forced every call site to gain a wrapper
widget. `SkeuDecoration` is a `Decoration`, so it drops straight into
`decoration:` on `Container`, `DecoratedBox`, `AnimatedContainer` and `Ink`, and
its `padding` matches `BoxDecoration`'s exactly. The intent of the plan's
"builders, not widgets" is kept: a call site swaps one value and its content
does not move.

**Verified:** `flutter analyze` 140 (baseline), `flutter test` 1348 pass / 8
fail (the same 8 that fail on `develop`), `test/core/theme/` 40 pass, and the
app built and ran on `emulator-5554`. The login screen is flat: solid pink hero,
`#FBFCFF` card, navy ink, a pink key with no gradient anywhere. The dashboard
shot in the plan's verification line still wants doing, since taking it means
signing in.

## 3. Phase 1, chrome. Your items 1 and 2

| Surface | File | Work |
|---|---|---|
| Bottom navigation | `lib/shared/common/widgets/custom_navigation_bar.dart` (496 lines) | ground `#FBF8F2`, top hairline `rgba(10,28,93,.07)`, ambient shadow upward. Active slot: solid pink squircle, radius 16, 38x38, glyph `#FFFAF2`, label `#E01B5D` at 700. Inactive: no tile, glyph `#0A1C5D`, label `#4D5983`. Replaces today's primary gradient with white glyphs and a 35 %-black active tile. The badge stays pink on `#FFFAF2`, which is already correct. |
| Drawer | `lib/shared/common/widgets/custom_drawer.dart` (1674 lines) | same treatment. The header slab at line 806 loses `buildPrimaryGradient()` and becomes the ground with navy ink; the active item at line 339 becomes the pink squircle; the 40-odd `whiteColor` glyph and label sites become ink. Expanded sub-groups sit in a `sub()` well rather than a white 6 %-alpha panel. |
| Tab strips | `lib/shared/common/widgets/custom_app_bar.dart` plus 21 screens with their own `TabBar` | ground `#FBF8F2`. Two forms: the `.segmented` well for two or three peers (billing, profile tabs), and the pink-underline strip for four or more. Selected label navy at 700, unselected `#8A93B2`. |
| App bar | `custom_app_bar.dart`, `custom_curved_appbar.dart` | flat ground, no elevation, navy title at 1.28 rem / 600, back and action keys become `.iconkey`: 38x38, radius 16, `#FBFCFF`, hairline border, lit bevel, 2 px sink. |
| Page ground | `custom_scaffold.dart`, `gradient_background.dart` and 223 `backgroundColor:` sites | `gradient_background.dart` keeps its name and its 9 call sites but paints the flat tray. Decide whether `MediaRes.wowcareMobileBg`, the background image it stamps on every page, survives. |
| Icon assets | 46 of 117 SVGs in `assets/icons` ship baked-in gradients, including most drawer and nav glyphs | see open question 2 |

One note on the existing nav code: it tints glyphs with `ColorFilter.mode(colour, BlendMode.dstIn)`, which uses the glyph as a mask rather than recolouring it. `srcIn` is the mode that actually flattens a gradient-filled SVG to one colour, and that is what the pink-squircle-with-white-glyph state needs.

### Phase 1 as landed

| Surface | What changed |
|---|---|
| Bottom navigation | ground is the tray with a hairline top edge and the ambient shadow thrown upward. The active slot is a solid pink squircle behind the **glyph alone** (the design's `.tabbar__glyph`, sized `iconSize + 16` so it stays 38x38 on a phone and grows with the glyph on a tablet), warm-white glyph, pink label at 700. Inactive: no tile, navy glyph, `inkSoft` label. Every glyph now goes through `BlendMode.srcIn`, which was the actual bug: `dstIn` was using the glyph as a mask and leaving its baked-in gradient showing. Badge is pink with a warm-white ring. Nothing about the slot order, the hidden-slot `Expanded`, the height measurement or the navigation logic moved |
| Drawer | ground is the tray, ink is navy. Header logo sits on the card face, the school switcher's panel is a `sub()` well and its selected row the pink tint. The active item is the pink squircle with warm-white content; an **expanded** section is a `sub()` well with navy ink, because it is a container for its children rather than a destination. Every child tile and nested panel dropped to navy: the 13 `themeColor` glyph filters in this file were labels on the panel, not actions, and `themeColor` is pink now. Badge is pink |
| App bar | flat tray ground, navy foreground, no elevation. The 1.5px coloured rule under it is a hairline. Tab strips default to a navy selected label, `inkFaint` unselected and a pink indicator, still overridable per screen through `TabBarStyle`. The kebab menu's sheet is the card face; the change-password sheet inside this file took the sheet ground, a `key(primary)` for its confirm and lost a hard-coded `#6C7FD8` |
| Curved app bar | tray ground, navy title. Lost its own `Color.fromRGBO` literal |
| Page ground | `gradient_background.dart` keeps its name and all 9 call sites and paints the flat tray. **The photographic backdrop is gone** (open question in section 7, resolved as assumed): the `image:` parameter survives and still works, and the one call site that passes one deliberately, `page_under_construction`, still gets it. 19 scaffolds that set their own white or card ground moved to the new `AppColors.pageBackgroundColor` role |

**Deliberately left to the module commits:**

* The **per-screen tab strips** (students, staff, communication, newsletter,
  billing, reports). Each picks its colours from a module token
  (`studentDarkPlum`, `messagingTabLabel`, `newsletterTabUnselectedLabel`,
  `billingTextColor`), so re-pointing them here would do six modules' work
  half-way and take none of them off the allowlist. `CustomAppBar` now gives
  the right default to every strip that does not override it.
* The **back and action keys as `.iconkey`**. `CustomAppBar` does not set
  `leading`, so `AppBar` picks the back arrow or the drawer hamburger itself
  depending on context. Overriding `leading` centrally to wrap it in a key
  would break that choice, so the icon keys land per screen.
* The **five media-viewer scaffolds** (document viewer, QR scanner, three
  full-screen media views) keep their black ground. A photo on a warm tray is
  worse, not better, and pure black behind media is not the "pure black is
  retired" rule's target.

**Verified:** analyze 140, tests 1350 pass / 8 fail (baseline), theme suite 40.
Built and ran on `emulator-5554`. The bottom bar and drawer only appear behind
the sign-in, so those two are verified by their code and the guard test rather
than by a screenshot.

## 4. Phase 2, the shared widget kit. Your item 3, and the multiplier

88 widgets in `lib/shared/common/widgets` carry 251 of the 442 `whiteColor` sites and are what
every module is built from. Restyle these and most of the app follows. Grouped by the design
components specimen that governs them:

| Specimen | Widgets |
|---|---|
| `.key--primary` / `secondary` / `destructive` / `disabled` | `rounded_button`, `rounded_button_new`, `custom_confirm_button`, `custom_cancel_button`, `custom_button_layout`, `reusable_cancle_save_buttons`, `reusable_password_change_button`, `custom_floating_text_button`, `gradient_toggle_button` |
| `.fab` | `custom_floating_action_button`, `gradient_add_button`. Square plus, 58x58, radius 14, pink, rim `#A10F45`. Dead state is a recessed well with an `#8A93B2` glyph, never hidden |
| `.field` / `.search` / `.dropdown` | `custom_text_field`, `text_field`, `custom_add_notes_field`, `custom_search_bar`, `custom_date_time_field`, `simple_time_picker_field`, `gradient_time_picker_field`, `custom_dropdown`, `custom_flexible_dropdown`, `common_single_select_dropdown`, `common_multi_select_dropdown`, `custom_multi_select_dropdown`, `messaging_filter_dropdown`, `student_search_dropdown`, `select_dropdown_card` |
| `.card` | `custom_section_card`, `profile_info_card`, `expandable_info_card`, `highlightable_card`, `custom_stat_bar_card`, `profile_show_widget` |
| `.row`, `.avatar`, `.pill` | `student_tile`, `selected_student_tile`, `selection_list_item`, `remove_student_tile`, `custom_profile_avatar`, `activity_status_panel` |
| `.sheet` | `confirmation_bottom_sheet`, `delete_confirmation_bottom_sheet`, `duplicate_student_bottom_sheet`, `post_add_staff_bottom_sheet`, `post_add_student_bottom_sheet`, `reusable_modal_bottom_sheet`, `reusable_log_out_model_sheet`, `confirmation_dialogue_box`, `calendar_dialog`. Radius 28 top, 42 bottom to meet the device corners, ground `#EFF2FB`, 44x5 grabber at `rgba(10,28,93,.18)`, docked Cancel and Save footer |
| `.toggle`, `.segmented`, `.chip` | `custom_toggle`, `custom_checkbox`, `custom_chip`, `custom_time_chip`, `custom_clear_all_chip`, `relation_selector`, `custom_repeat_on_days_selector`, `multi_selection_widget`, `filter_icon_button` |
| `.trough`, `.tile`, `.toast` | `gradient_circular_progress`, `primary_circular_loader`, `photo_upload_progress_overlay`, `custom_stat_bar_card` |
| shimmer | `simmer_loader`, `custom_shimmer_loader`: base the well tone `#E5EAF7`, highlight `#EDF1FA` |
| press | `button_press_effect.dart` already exists and is where the 3 px sink and 90 ms curve belong |

The five `gradient_*` filenames keep their names through this work so the diff stays a restyle.
Renaming them is a separate, mechanical commit at the end if you want it.

### Phase 2 as landed

Grouped by the `03 Components` specimen that governs each widget.

| Specimen | What changed |
|---|---|
| `.key--primary` / `secondary` / `disabled` | `custom_confirm_button` is `key(primary)` with the disabled variant behind the same call; `custom_cancel_button` and `custom_floating_text_button` are `key(secondary)`; `rounded_button_new` is the pill primary key and lost its `gradient` parameter (one call site, the sign-in screen); `custom_button_layout` and `reusable_cancle_save_buttons` sit on a `card()`; `reusable_password_change_button` likewise. `rounded_button` lost its `AnimatedScale(0.80)`, which collapsed the button 20 percent, in favour of the 3px sink a key actually does |
| `.fab` | `custom_floating_action_button` and `gradient_add_button` are `fab()`. The no-permission state is the design's dead FAB: recessed, rimless, `inkFaint` glyph, **still in place** |
| `.field` / `.search` / `.dropdown` | `AppSurfaces.fieldDecoration()` gives every `TextField` the well's fill and radius with the focus and error rings; `custom_text_field`, `text_field`, `custom_search_bar` use it. The tappable wells that are not text fields (`custom_dropdown`, `custom_flexible_dropdown`, `custom_add_notes_field`, `custom_date_time_field`, `simple_time_picker_field`, `select_dropdown_card`, `common_single_select_dropdown`, `common_multi_select_dropdown`, `relation_selector`) take `well()` and keep the inset shadow |
| `.card` | `custom_section_card`, `profile_info_card`, `custom_time_chip`, `expandable_info_card`, `schedule_picker`, `multi_selection_widget`'s panel |
| `.sheet` | `confirmation_bottom_sheet`, `delete_confirmation_bottom_sheet`, `duplicate_student_bottom_sheet`, `post_add_staff_bottom_sheet`, `post_add_student_bottom_sheet`, `reusable_modal_bottom_sheet`, `reusable_log_out_model_sheet`, `confirmation_dialogue_box`, `calendar_dialog`: sheet ground `#EFF2FB`, pink circular badge with warm-white glyph, `key(secondary)` cancel and `key(primary)` confirm |
| `.toggle`, `.chip`, `.segmented` | `custom_toggle` and `gradient_toggle_button` are the design's toggle: a **well** for the track, green when on, a raised knob. `custom_checkbox`, `custom_chip`, `custom_clear_all_chip`, `custom_repeat_on_days_selector`, and the three hand-rolled checkboxes in `classroom_selection_widget_exact`, `multi_selection_widget` and `custom_multi_select_dropdown` |
| `.row`, `.avatar`, `.trough`, `.toast` | `student_tile`, `selected_student_tile`, `selection_list_item`, `custom_profile_avatar`, `profile_show_widget`, `custom_stat_bar_card`, `gradient_circular_progress`, `photo_upload_progress_overlay`, and `app_tooltip`, which was a near-black slab and is now the design's navy toast |
| shimmer | `custom_shimmer_loader` and `simmer_loader`: 185 sites. Base is the well `#E5EAF7`, highlight the alt well `#EDF1FA`, and every placeholder block is a card face |

**The one place the design could not be followed literally.** A Flutter
`TextField` takes its fill and border from an `InputDecoration`, which has no
inset shadow, and wrapping the field in a decorated box is wrong for a
different reason: the error and counter text render *below* the input and
would end up inside the well. So a text field gets the well's flat fill and
radius and goes without the inset; the cool fill on the warm tray still reads
as cut in. Everything you do not type into keeps the inset. This is written
into `AppSurfaces` where the helper lives.

**Also worth knowing:**

* `custom_chip` and `gradient_background` still accept a `LinearGradient`
  parameter, so both stay on the gradient allowlist. Neither paints one:
  `custom_chip` takes the first stop as a flat fill. They come off the list
  when the parameters go, which is a caller-side change.
* `hls_web_player` keeps its white player chrome. It is a video surface, not
  an app surface.

**Verified:** analyze 139, one below the 140 baseline, because a dead
`responsive` local in `confirmation_dialogue_box` went with the import that
made it unused. Tests 1350 pass / 8 fail, the baseline 8. Theme suite 40.
Allowlists: gradient files 116 to 97, colour-literal files 51 to 44.

## 5. Module order

Chrome and the shared kit first, because they front every module. Then module by module, each
one its own commit, each verified before the next starts.

| Order | Module | Design page | App path | Files | Gradients | `whiteColor` |
|---|---|---|---|---|---|---|
| 1 | Authentication | `M01 Authentication` | `features/auth`, `splash`, `onboarding` | 18 | 3 | 0 |
| 2 | Dashboard and More | `M03 Dashboard and More` | `features/dashboard` | 67 | 6 | 60 |
| 3 | Attendance | `M04 Attendance` | `features/attendance`, `kiosk`, `geofencing` | 149 | 7 | 14 |
| 4 | Students | `M05 Students` | `features/students` | 62 | 2 | 76 |
| 5 | Staff | `M06 Staff` | `features/staff` | 44 | 0 | 0 |
| 6 | Classrooms | `M07 Classrooms` | `features/classroom` | 30 | 0 | 0 |
| 7 | Activities | `M08 Activities` | `features/activities` | 79 | 3 | 0 |
| 8 | Communication | `M09 Communication` | `features/communication` | 83 | 7 | 1 |
| 9 | Billing | `M10 Billing` | `features/billing` | 112 | 9 | 0 |
| 10 | Movements and Availability | `M11 Movements and Availability` | `features/availability` | 11 | 0 | 0 |
| 11 | Notifications | `M12 Notifications` | `features/notifications` | 11 | 0 | 4 |
| 12 | My Profile | `M13 My Profile` | `features/user_profile` | 13 | 0 | 0 |
| 13 | Scheduling | `M14 Scheduling` | `features/scheduling` | 45 | 4 | 22 |
| 14 | Newsletter | `M15 Newsletter` | `features/newsletter` | 23 | 3 | 10 |
| 15 | Reports | `M16 Reports` | `features/reports` | 48 | 2 | 0 |

Auth is first as the pilot: 18 files, self-contained, and every screen in it is a form and a
key, so it exercises the field and key recipes before the heavy modules depend on them.

`M17 Events, Tasks and Calendar` has a design page but the feature is not on this branch; it
lives on `feature/events` and `feature/tasks`. It gets re-skinned when those merge.

### Per-module recipe, the same every time

1. Open the module page in the design folder next to the running app.
2. `grep` the module for `LinearGradient`, `ShaderMask`, `whiteColor`, `blackColor`,
   `cardColor` and triage each hit: surface, ink on dark, or well.
3. Swap decorations to `AppSurfaces` builders. Content, order and copy stay untouched.
4. Empty states get the `.empty` recipe: a 64x64 well icon, a 0.95 rem navy title, and exactly
   one key, the pink one.
5. Remove the module's files from the guard test allowlist.
6. Verify: `flutter analyze` at 140, `flutter test`, and a screenshot of every screen the
   module owns against the module page.
7. Commit as `theme(<module>): flat skeuomorphic re-skin`.

### Definition of done, per module

* No gradient in code or in the module's own assets.
* Ground is `#FBF8F2` on every screen in the module.
* Every raised thing has the bevel and the ambient shadow; everything you type into is a well;
  every key has a rim and sinks 3 px.
* Pink only on the recommended action, the active nav slot and required asterisks. Navy on ink
  and at most one impact card per screen. Teal only where question 1 lands it.
* No pure white and no pure black.
* Same widgets, same fields, same copy, same order as before the commit.

## 6. Decisions taken

1. **Teal keeps its domain coding.** Student avatars stay `#D2F1F2` on `#1A7C7F`, staff stay
   sun `#F9AD3A` on `#FBEBCF`, stat tiles and capacity troughs stay teal. Teal comes off all
   chrome: no teal app bars, primary keys or active states. On attendance and classroom
   screens the teal and sun split is how a student row reads apart from a staff row, so it is
   load-bearing rather than decorative. This narrows "teal for secondary minor actions" to
   mean chrome and generic actions, not domain colour.
2. **Gradient SVGs are flattened at the call site**, not on disk. Every glyph goes through
   `ColorFilter.mode(colour, BlendMode.srcIn)`, which collapses the baked gradient to one
   flat colour. No asset edits. Note that `custom_navigation_bar.dart` currently uses
   `BlendMode.dstIn`, which masks the glyph instead of recolouring it; that becomes `srcIn`
   as part of Phase 1 either way, since the pink-active state needs a real tint.
3. **Billing card faces flatten to navy** with a flat sun chip and the scheme logo. No
   permanent exception in the guard test: rule 3 holds with no carve-outs. The four
   `billing*GradientColors` token sets are deleted in the Billing module commit.

## 7. Still open

* **The page background image** `MediaRes.wowcareMobileBg`, currently stamped behind every
  `GradientBackground` on 9 screens. The design pages all sit on a plain ground. Proceeding on
  the assumption it goes, since a photographic ground fights the flat material. Say the word
  and it stays.

---

## 6. Where it finished

The two ratchets both reached zero, so the four rules in
`test/core/theme/centralized_theme_test.dart` are absolute rather than
aspirational: no gradient, no colour literal, no `Colors.*` but transparent,
no bare `SvgPicture`.

| Phase | What landed |
|---|---|
| 3. Glyphs | `AppIcon` forces `ColorFilter.mode(token, BlendMode.srcIn)` over every SVG, so an asset cannot carry a colour of its own. `AppArtwork` is the opt-out for a pictogram whose colours are the content. All 165 call sites moved. Two assets shipped a full-bleed white rect from Figma that `srcIn` turned into a solid block; removed. |
| 4. Material | `ColorScheme.fromSeed(pink)` was making every Material-owned surface a pink-tinted neutral the palette could not reach. The scheme is written out from `AppPalette` and `surfaceTint` is transparent; component themes set for the twenty-odd Material widgets the app uses directly. |
| 5. The palette | 287 hex values and 118 Material-swatch references in `app_colors.dart`, then 141 literals across 41 other files, all resolve to a role. New role groups: domain coding (teal/sun), a categorical `data*` series, and the over-media set. |
| 6. Flat | The last 86 gradient-drawing files. 19 page grounds, 66 keys, 19 `ShaderMask`es, 4 media scrims, 3 action panels, the stored-card faces, the analytics plumbing, the newsletter schemes and the scanner's sweep line. The four `build*Gradient()` helpers and the four gradient roles are deleted. |
| 7. Surfaces | 62 hand-rolled cards onto `card()`, 12 flat field-toned boxes onto `well()`, 9 outlined text fields given the well's fill, 8 sheet roots onto `sheet()`, plus a central `inputDecorationTheme`. |
| 8. The press | `SkeuKeyBox`: the face travels 3px while the rim collapses 4px to 1px, so the key's bottom edge stays put and only the face descends. 85 keys moved onto it. |
| 9. Login | The Lottie and the pink hero replaced by the ground, the logo and the wordmark; the form a raised panel; the fields wells rather than pink-outlined boxes. |

### Still open

* **The `whiteColor` triage.** All 199 sites are the cool card face. The ones
  that are ink on a pink or navy face want `textOnDarkColor` instead. It needs
  eyes on each screen, which needs a reachable backend.
* **305 card-toned boxes with no shadow.** Some are cards missing their depth,
  some are nested panels that should stay flat. The decoration alone does not
  say which, so this wants the running app rather than a script.
* **Font sizes** are still at their call sites, by the original plan.

### Verification

`analyze` 72 issues in `lib/` against a 104 baseline, `flutter test` 1352 pass
and 8 fail (the same 8 that fail on `develop`), the theme suite 44, and the
debug APK builds and runs on `emulator-5554`. Only the login screen could be
checked on device: the dev server is not reachable from this machine, so no
authenticated screen could be opened. `test/core/theme/goldens/material_specimen.png`
exists for that reason.
