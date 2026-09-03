# WowCare Redesign: Build Order and Working Rules

## Context

The design folder holds a finished redesign of the whole mobile app: 171 phone screens across 16 modules, drawn in a skeuomorphic language (raised cards, recessed wells, rimmed keys that sink 3px) on the finalized L4 "warm tray, cool cards" colourway. Nothing in the current app matches it, and an earlier attempt on branch `wowcare-skeumorph` retrofitted the design in place across 271 files, which is why we are not doing that again.

Instead we build a clean presentation and core layer in `lib/redesign/` on branch `improvements/wowcare-redesign`. The existing `lib/data/` and `lib/domain/` layers are good and stay exactly as they are. We finish the entire UI first, then link it to those layers in one final phase. Nothing under `lib/` outside `lib/redesign/` gets edited; additive changes to `pubspec.yaml` and `assets/` are fine, and the redesign stays part of this project rather than becoming a nested one.

## Non-negotiables

From the design brief's hard rules and the finalized decisions:

- **No new API work, ever.** Every field and count must come from an endpoint the app already calls. `_split/modules.json` lists, per module, the `costly` things the design wanted but the backend cannot serve. Those do not get built.
- **Nothing invented.** Every element traces to a real widget in `lib/presentation/features/`.
- **No sign-up flow.** Sign in and password reset only; accounts are created on web.
- **No gradients.** Depth comes from a lit top bevel, recessed wells and rims. Ambient shadows are warm brown `rgba(63,45,20,a)`; inset shadows stay navy `rgba(10,28,93,a)`.
- **Colour carries meaning.** Pink `#E01B5D` is the one action per screen. Navy `#0A1C5D` is ink plus a single impact surface. Teal `#1A7C7F` means students, sun `#F9AD3A` means staff, violet `#6D4AC9` is M17 tasks only, green `#0E8F53` is signed in, red `#D92D20` is danger. Role carries no colour: Admin, Staff and Parent screens for the same feature use identical material.
- **The app's own words win.** Students not children. Sign In / Signed In / Not Marked for attendance. Logout means leaving the app and must never be swapped with Sign Out. Dashboard not Home, Classrooms not Rooms. US spelling. No gendered pronouns.
- **Radius ladder:** 20 card, 16 inner row / well / key / icon tile, 12 chip, 28 sheet top, 999 pill.
- **Light only.** The D1 midnight navy dark colourway is fully designed but deliberately not applied, so the token layer must stay swappable for it to land later without touching a screen.
- Bottom nav is five fixed slots. Admin and Staff: Dashboard, Attendance, Classrooms, Activities, Messages. Guardian: Dashboard, Attendance, Activities, Messages, Billing. More sits behind a hamburger key in the dashboard app bar. Drill-down screens highlight nothing.

## What we reuse, and what we write fresh

**Import untouched:** `core/network/` (`ApiClient`, `AuthInterceptor` with its three-casing header contract, `SessionExpiredInterceptor`), `core/storage/`, `core/cache/`, `core/errors/`, `core/auth/`, `core/firebase/`, `core/security/`, `core/util/api_paths.dart` and `api_constants.dart`, the global `serviceLocator`, `AppBootstrap.initialize()`, and all of `lib/domain/` and `lib/data/`.

**Do not import:** `core/util/app_themes.dart`, `core/common/widgets/`, and the feature logic misfiled in `core/util/` (`attendance_classroom_scope.dart`, `newsletter_staff_scope.dart`, `classroom_visibility.dart`). Those get re-expressed in the owning redesign feature.

**Structural reference only:** `lib/app/theme/skeu/` on `wowcare-skeumorph` is about 4,900 lines of self-contained Flutter (it imports only `flutter/material`, `flutter/services`, `dart:ui`, `flutter_svg`). Port its techniques: `SkeuInsetPainter` for the inset shadow Flutter lacks, `SkeuPressable` with sink in logical pixels, and the rim-collapse press. Retype every token value from `WowCare Design Components.dc.html`, because that branch is a generation stale: its page ground is `#F2F4FB` where L4 is `#FBF8F2`, its ambient shadows are navy where L4 is warm brown, its card radius is 16 where the ladder says 20.

**Cherry-pick:** `assets/fonts/poppins/*.ttf` and its `pubspec.yaml` fonts block from `wowcare-skeumorph` (Poppins is the substitution of record; the brand's Modulus Pro is unlicensed). Add the four SVGs the repo lacks: `more-menu.svg`, `upload-cloud-icon.svg`, `logo-mark.svg`, `kiosk-qr.svg`. Every other icon the design uses is already in `assets/`.

## Folder layout

```
lib/redesign/
  main_redesign.dart          entrypoint, reuses AppBootstrap + serviceLocator
  app/                        root widget, provider composition, theme host
  core/
    constants/                app_strings, app_sizes, app_durations, app_assets
    theme/                    app_colors, app_surfaces, app_elevation, app_radii,
                              app_text_styles, app_motion, colourway (ThemeExtension),
                              app_theme
    painters/                 inset_shadow_painter
    widgets/                  shared component library, one widget per file
    router/                   app_routes, app_router, guards/
    responsive/  di/  preview/  extensions/  utils/
  features/<module>/
    presentation/pages/       one file per design screen
    presentation/widgets/     widgets only this module uses
    cubit/                    cubit + state pairs
    preview/                  this module's fixture source
    SCREEN_MAP.md             the design-to-code trace
  analysis_options.yaml       strict lints, scoped to this folder only
```

Analyzer config nests, so a folder-scoped `analysis_options.yaml` holds new code to a standard the existing code would fail. The repo-root one is entirely commented out today, so nothing is enforced anywhere right now.

## Build order

**Phase 0. Scaffolding.** Cut `improvements/wowcare-redesign` from `develop`. Commit this plan to the branch as `lib/redesign/PLAN.md` so it travels with the work. Create the folder tree, the scoped lint file (add `flutter_lints` to dev deps), the Poppins and asset additions, and `main_redesign.dart`. Save the memory note that data and domain are final and get linked last.

**Phase 1. Core layer.** Tokens first, typed from the Design Components page: colours, surfaces, elevation recipes, radii, the Poppins scale (2.1rem headline count, 1.28rem module home title, 1.12rem detail and sheet title, .96rem card title, .93rem row name, .87rem key label, .74rem sub-line, .68rem eyebrow, .62rem nav label), motion (`press 90ms`, `fast 160ms`, `base 200ms`, `panel 300ms`, spring `Cubic(.34, 1.56, .64, 1)`), and the 4px grid with a 44px minimum touch target. Colours resolve through a `Colourway` ThemeExtension rather than static constants so D1 can drop in later. Then `app_strings.dart` grouped per module, `app_assets.dart`, `app_sizes.dart`, and `app_theme.dart` mapping tokens onto `ThemeData`.

**Phase 2. Routing.** One `GoRouter`, with every path in a single `AppRoutes` class. The existing router spreads paths across `AppRoutes` and 104 scattered `Screen.routeName` statics, and we do not repeat that. `StatefulShellRoute.indexedStack` with five branches matching the nav slots, branch `GlobalKey`s at module level so they survive rebuilds, typed route arguments instead of `state.extra as Map`, and a redirect covering the kiosk lockdown and the guardian billing split. Keep the `SizerInit` shape rather than wrapping `Sizer` around `MaterialApp.router`, which trips a `GlobalKey used multiple times` assertion.

**Phase 3. Common widgets.** Built from `WowCare Design Components.dc.html`, the reference the design team wrote for developers, which carries real CSS beside each component. The set: surfaces (card, well, impact card, bottom sheet with grabber), keys (primary, secondary, destructive, disabled with the rim removed), the FAB (58px, radius 14, plus dead and absent states), tab bar (88px, active pink tile, unread badge), list row (44px round avatar, 13px attendance dot with a card-coloured ring, status pills), fields (well-backed, error state, pink required asterisk, multi-select dropdown), switches (toggle, segmented, filter chips), header bar and icon keys (38px, Lucide outline at stroke 2.1), counting tiles, troughs, toasts, and the empty state whose icon is a well and whose single key is pink. Round is a list row's leading slot; square is a badge.

**Phase 4. Modules, in this order.**

1. **M01 Authentication** (11: `1a`-`1f`, kiosk `2a`-`2e`). Establishes forms, validation, the PIN pad.
2. **M03 Dashboard and More** (11: `3A1`-`3A3`, `3S1`-`3S3`, `3M`, `3M2`, `3P1`-`3P3`). All three personas, attention deck, More tile grid.
3. **M07 Classrooms** (10: `7a`-`7j`)
4. **M05 Students** (8: `5a`-`5h`)
5. **M06 Staff** (6: `6a`-`6f`)
6. **M13 My Profile** (6: `13a`-`13f`)

Then the rest, ordered so shared vocabulary lands before the screens leaning on it, with the two heaviest last:

7. **M04 Attendance** (6). The dashboards and rosters already show its statuses, so its forms and verbs should settle next.
8. **M12 Notifications** (5). Small, and phase 2 already stubs the bell and deep-link routing.
9. **M08 Activities** (22) and 10. **M09 Communication** (16). The two highest-traffic daily modules.
11. **M11 Movements and Availability** (13), 12. **M14 Scheduling** (14), 13. **M15 Newsletter** (10), 14. **M16 Reports** (12). The admin long tail, each self-contained.
15. **M10 Billing** (24 screens against 103 existing files, the largest surface).
16. **M17 Events, Tasks and Calendar** (21). Last, cross-referenced against `feature/event-todo-notifications`, since nothing for it exists on `develop`.

**Phase 5. Data linking.** Swap each feature's `PreviewSource` binding for the real usecase or repository. Because cubits and states were written against an interface, this is one DI edit per feature and no screen changes.

## The per-screen ritual

This is the part that must not be skipped. For every design screen ID:

1. Open the module `.dc.html` in a browser. The frames are live and interactive; reading raw HTML for layout wastes time.
2. Look the ID up in the **Screen map** table in the design folder's `github.md`. It already maps every design screen to its source files. Two renames are needed: `classrooom/` becomes `classroom/`, and `features/student/module_access.dart` becomes `features/students/module_access.dart`. The design was grounded against `main`, which is behind `develop` and still carries those misspellings. Spot-checked, the rest of the map resolves cleanly on `develop`.
3. Read those files on `develop` and fill in the module's `SCREEN_MAP.md`: design ID, design title, existing screen path, cubit, usecase or repository method, `ApiPaths` constant, role gate. Read the widget as well as the cubit. Presentation code calls `serviceLocator` 654 times and hits `ApiClient` directly in 28 files, so real API behaviour lives in widgets too, not only in domain.
4. Check the module's `costly` list in `_split/modules.json`. Anything on it is out of scope.
5. Build the screen from `core/widgets` only. A new shared widget goes in `core/widgets`, never in the feature.
6. Compare side by side with the frame before moving on.

## BLoC conventions

Match the house style so linking is mechanical rather than a rewrite.

- Cubit only, no `Bloc`, no events. `flutter_bloc` 8, `equatable`, no freezed.
- One immutable state class per cubit: `extends Equatable`, `copyWith`, `props`, a `Status` enum, and explicit `clearX: true` flags for nullable clearing. State in its own file, `part of` the cubit.
- `load({bool isSilent = false})` for navigation revisits, `refresh()` for pull to refresh, a `_isFetching` re-entrancy guard, and `if (!isClosed) emit(...)`.
- Every cubit takes its data through a constructor-injected interface. During the UI phase that is a `PreviewSource` returning fixtures lifted from the design frames, so the design's loading, empty and error frames are exercised from day one. Cubits never call `serviceLocator`, never touch `ApiClient`, never import `lib/data/`.
- Registered in `core/di/redesign_di.dart` with `registerFactory`, invoked after the existing `configureDependencies()`. The 2,498-line `di.dart` is not edited.
- Cubits are provided in the page, not in the router's `pageBuilder`; a `..load()` there refires on every navigation.
- Read `RoleCubit` with `BlocBuilder` or `BlocSelector`, never `context.watch`. `BlocProvider` is a plain `Provider`, and since the instance never changes, `watch` does not fire on state emissions. The existing 28 `watch<RoleCubit>()` sites only work because the persona settles before they build.

## Clean code rules

- No hardcoded copy in a widget file. Everything in `core/constants/app_strings.dart`, grouped per module, templated copy as functions.
- No raw colours, sizes, radii or durations in widgets. Tokens only. A literal hex in a feature file fails review.
- Stateless by default. Anything past roughly 150 lines splits into private section builders (`_headerSection()`, `_rosterList()`, `_footerKeys()`).
- One public widget per file, named after it. Barrel exports per folder. A feature may import `core`; features never import each other.
- Lints: `flutter_lints` plus `prefer_single_quotes`, `require_trailing_commas`, `avoid_print`, `discarded_futures`. Zero analyzer output is the bar.

## Verification

- `flutter analyze lib/redesign` clean at the end of every phase.
- Run on Android: `flutter run -t lib/redesign/main_redesign.dart --dart-define=ENVIRONMENT=QA`. There is no `DEV` environment in this repo, whatever the earlier draft of this line said: the Gradle `copyGoogleServices` task resolves `android/app/firebase/<env>/google-services.json` and only `local`, `qa`, `uat` and `prod` exist. Web is broken in this repo and there is no macOS target. `dependency_overrides` stubs out ffmpeg locally and must be removed for a device build.
- Screenshot every built screen and compare against its frame.
- Widget tests per `core/widgets` component covering its states, cubit tests per feature. Nothing currently tests auth, dashboard, classroom, students, staff or profile, so there is no safety net to inherit; `test/presentation/features/reports/view/` is the only widget-test precedent. Add `bloc_test` and `mocktail` as dev deps when the first cubit test lands.
- `git diff develop --stat -- lib` must show changes only under `lib/redesign/`. Check before every commit.

## Traps worth writing down

- Two error conventions coexist: `Either<Failure, T>` in auth, reports and communication; throw plus `ApiErrorHandler.extractErrorMessage(e)` in students, staff, classroom and dashboard.
- `ModuleAccess` and `AppAccessModules` live in `presentation/features/students/module_access.dart` and are imported by the nav bar and unrelated features. Import read-only for role gating; do not fork the list. Note the backend's misspelled `INDIVISUAL_MOVEMENTS`.
- `RoleCubit.isAdmin` is true for staff as well as admins. `isTrueAdmin` is the admin-only check.
- School switching invalidates caches manually via `SchoolSwitchReloadMixin`, `KeyedSubtree` re-keying and `clearAllCachesForContextSwitch`. Skip it and the redesign shows the previous school's data.
- Time is school-timezone based, not device local. Go through `ServerTimeService`, `SchoolTimezoneResolver` and `SchoolZoneDateTime`.
- `SplashCubit` needs the widget tree's `RoleCubit`, `ParentChildCubit` and `AuthCubit` instances, not fresh ones from `serviceLocator`. The persona switch in `user_profile_screen.dart` has a load-bearing ordering (guardian preload before the role flips) that must be reproduced.
- The design folder's `CLAUDE.md` is chronological and later entries supersede earlier ones. Its "Decisions already made" section near line 954 is partly stale: nav is five slots not four, attendance verbs are Sign In / Signed In, and ratio shows counts written students-first with two states only. `WowCare App Design Language.dc.html` still documents the retired all-warm surfaces; the Design Components page is current.

## Conventions settled while building (3 Sep 2026)

- **The launcher is the one sanctioned edit outside `lib/redesign/`.** `lib/main.dart` now runs
  `DesignChooser` (in `lib/redesign/launcher/`) which shows two keys on every launch, New Design
  and Old Design, and inflates `RedesignApp` or the untouched `MyApp` accordingly. `git diff
  develop --stat -- lib` therefore shows `lib/main.dart` plus `lib/redesign/`, and nothing else.
- **Per-module strings files.** Shared vocabulary stays in `core/constants/app_strings.dart`;
  everything a module says lives in `features/<m>/<m>_strings.dart` as `<X>Strings`, so modules
  can be built in parallel without touching one file.
- **Per-module routes and DI files.** `features/<m>/<m>_routes.dart` exports the module's
  `List<RouteBase>` (relative paths, nested by `core/routing/app_router.dart` under the right
  shell branch; branch owners also export `build<X>Root`). `features/<m>/<m>_di.dart` exports
  `register<X>Dependencies(GetIt)`, called from `core/di/redesign_di.dart`. Absolute paths stay
  in `AppRoutes` only.
- **Its own locator.** `redesignLocator` is a separate `GetIt` instance, not the app's global
  `serviceLocator`, because both presentation layers coexist behind the launcher. Phase 5 pulls
  real usecases from the app's locator inside `register<X>Dependencies`.
- **Session and persona.** `core/session/SessionCubit` holds who is signed in, where, and as
  which `Persona` (admin / staff / guardian). The router's redirect gates on it, and
  `ShellScaffold` maps a persona's five slots onto the six shell branches. `BadgeCubit` carries
  the Messages and bell counts.
- **One demo world.** `core/preview/demo_data.dart` is Maple View: Marcus Whitfield (Admin),
  Dana Whitfield (Staff, Sunflower), Ngozi Okafor (Guardian of Amara and Sam), the Sunflower and
  Bluebell rosters and the staff list, all lifted from the design's own demo arrays. Every module's
  fixtures reuse these people. The preview account holds all three roles so 13d Switch Profile is
  a real, exercised path for flipping persona.
- **Frame extraction.** `WowCare M*.dc.html` pages are split per frame (PNG render, simplified DOM
  text and the page script) by a scratchpad script; screens are built against those renders rather
  than by reading raw HTML.
- **Icons.** `lucide_icons_flutter` provides the Lucide outline set the design draws; glyphs are
  named in `core/constants/app_icons.dart`.
