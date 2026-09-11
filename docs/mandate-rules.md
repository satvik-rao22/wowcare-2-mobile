# Mandate Rules — shared reference

**Put this file in the repo at `docs/mandate-rules.md` and commit it.** Every module prompt begins by telling Claude Code to read the relevant section, so the rules live in one place instead of being retyped in forty prompts.

Source of truth: *WowCare 2.0 Engineering Standards: Eight Mandates* (develop @ 16b1b2b6), the PDF in the repo root. Where this file and the PDF disagree, the PDF wins.

---

## GUARDRAILS — apply to every mandate task, in every module

1. **Behaviour must not change.** Same screens, same navigation outcomes, same API endpoints and payload keys, same user-visible strings, same error messages, same loading states, same validation outcomes. These are refactors.
2. **Stay in scope.** Touch only the module named in the task, plus the shared files the task explicitly names. If another file must change, stop and explain why before editing it.
3. **No opportunistic cleanup.** No reformatting, renaming, import reordering, or unrelated lint fixes outside the mandate being worked.
4. **Measure before and after.** Run `flutter analyze` on the module's directories and `flutter test` on its test directories before starting and after finishing. The analyzer count must not increase; no previously-passing test may fail.
5. **Inspect before assuming.** Do not assume the current structure, the existence of `AppRoutes`, `AppStrings`, `AppSizes`, `AppColors`, `core/responsive/`, or a `mappers/` folder. Check first and reuse what exists.
6. **If it cannot be done without changing behaviour, stop and explain the conflict.** Do not guess.
7. **Report at the end:** files changed, counts before/after, and one line per behavioural risk you identified.
8. **Do not commit.** Leave the working tree for review.

---

## MANDATE 1 — GoRouter everywhere, MaterialPageRoute nowhere

- Every navigation goes through GoRouter: `context.push(...)`, `context.go(...)`, `context.pop()`.
- No `Navigator.push`, `Navigator.of(context).push`, or `MaterialPageRoute` anywhere under `lib/presentation`.
- Route paths and names live as constants in `lib/core/router/app_routes.dart`. If that file does not exist, create it — but add only the routes for the module being worked, not all 56 inline paths.
- Routes are registered in the app router. Use nested `routes:` where the hierarchy is real.
- Route arguments are **typed**: path parameters, or a declared class passed through `extra`. No `Object?`, no `dynamic`, no untyped casts at the receiving end.
- Cubits needed by a route are created in the `GoRoute` builder, wrapped in `BlocProvider`. That is the only place `serviceLocator` may appear on the presentation side.
- **§5.4 caution:** an `..load()` inside a `GoRoute` builder re-runs on every navigation to that route, including back navigation. Use the builder for construction and trigger the load once, or you will double-fire the API. This has already caused duplicate-call bugs in this codebase.
- **Modals are exempt.** `showDialog` and `showModalBottomSheet` are not route pushes and stay as they are.
- Preserve result handling exactly. If a screen currently returns a value that drives a refresh, a tab switch or a snackbar, the new code must produce the same outcome.

## MANDATE 2 — setState scarcely, ValueNotifier for UI micro-state

Classify every `setState` call into one of three buckets before changing anything:

| Bucket | Examples | Destination |
|---|---|---|
| **A. Business / screen state** | API results, loading flags, filters, form submission, selections that outlive the widget | Cubit |
| **B. UI micro-state** | expand/collapse, tab index, chip selection, visibility toggles | `ValueNotifier` + `ValueListenableBuilder` |
| **C. Controller tick** | animation/controller lifecycle | `setState` is fine |

- Bucket A is "no exceptions" — if it survives a parent rebuild, is read by more than one widget, or comes from an API, it is Cubit state.
- `ValueListenableBuilder` takes a `child:` that is built once and handed to the builder untouched. **Use it.** That is the actual performance win over `setState` and the reason this rule exists.
- Never create a `ValueNotifier` inside `build()`. Hold it as a final field and dispose it.
- Do not make a widget `StatefulWidget` merely to store one boolean.
- Do not introduce another state-management library.
- Use `BlocSelector` where only a small part of the UI depends on one state property.
- **Watch for a visible change:** moving state to a cubit may now *preserve* selections across navigation where they previously reset. Flag it rather than shipping it silently.

## MANDATE 3 — Folder structure, followed strictly

Canonical presentation layout per feature:

```
presentation/features/<feature>/
  model/       # screen params, UI config, route arg classes
  view/        # screens. Zero logic. Zero API calls.
  view_model/  # Cubit + State
  widgets/     # this feature only; shared goes to core/widgets/
```

And per layer:

```
data/features/<feature>/    datasource/  models/  mappers/  repository/
domain/features/<feature>/  entities/    repositories/  usecases/
```

- `cubit/` → `view_model/`. **17 of 19 features use `cubit/`, so this is app-wide — confirm before doing it in one module alone.**
- `views/` → `view/`, `widget/` → `widgets/`.
- A presentation `util/` or `utils/` folder should not exist. Pure business rules go to `domain/features/<x>/usecases/` or a domain service; mappers go to `data/features/<x>/mappers/`; presentation helpers go to `widgets/` or `core/extensions/`.
- API DTOs never live in presentation. Entities never live in presentation.
- Domain entities are **pure Dart with no Flutter imports** and no `fromJson`/`toJson`.
- A file ending `_screen` is not a widget and does not live in `widgets/`.
- **Imports:** all cross-folder imports use `package:wowcare/...`. Relative imports only within the same folder. Tests import lib code as `package:wowcare/...`, never `../../../lib/...`. Dart silently discards excess `..` segments at the package root, so an import with one too many compiles in the app and breaks the moment a test reaches it by file URI.
- Do not create compatibility duplicate folders to avoid updating imports. One canonical implementation.

## MANDATE 4 — Centralized theming, constants, strings, colors, fonts, sizes

- No `Color(0x...)` and no `Colors.<name>` outside `core/theme/app_colors.dart`. Resolve through `AppColors` or `Theme.of(context).colorScheme`.
- No inline `TextStyle(`. Use `Theme.of(context).textTheme.<slot>` or a named `AppTextStyles` entry; local variation uses `.copyWith()` on a named style, never a fresh `TextStyle`.
- No `fontFamily: 'Manrope'`. The family is already on `ThemeData` — these lines are a find-and-delete.
- No user-visible string literal in a view file. Everything through `AppStrings` (`lib/core/constants/app_strings.dart`).
- No magic spacing. `AppSizes` (`lib/core/constants/app_sizes.dart`).
- Reuse `AppDecorations` rather than writing another `BoxDecoration`.
- **Rendered output must be IDENTICAL in light mode.** If a hex has no matching token, add the token with that exact hex rather than substituting the nearest existing one. List every token added.
- **Colours that encode meaning** (status, compliance, workflow state) become *named semantic* tokens, not generic palette entries — and must stay distinguishable by something other than colour alone.
- Skip anything not user-visible: log tags, storage keys, API payload keys, backend enum values.
- Dark mode may newly differ where it previously did not work at all. Report what changed; do not chase it.
- **This is centralization, not redesign.**

## MANDATE 5 — Presentation talks to cubits only

A view file may reference exactly three things from outside itself: its own Cubit (via `context.read<T>()` / `BlocBuilder` / `BlocSelector`), widgets, and constants.

Forbidden anywhere under `lib/presentation`:

- `serviceLocator<T>()` — except in the router's `GoRoute` builder
- `DataSource`, `Repository`, `RepositoryImpl`, `ApiClient`, `Dio`, `StorageService`, `SharedPreferences` types
- direct use-case invocation from a view
- direct network or platform calls (including `path_provider` and friends — put them behind an injected service)
- `FutureBuilder` / `StreamBuilder` over data the cubit already owns

Flow: `View → Cubit → UseCase → Repository → DataSource → API`.

- Cubits call use cases, not repositories. If a use case is missing, create one.
- Verify call counts before and after: entering a screen and returning to it must produce the same number of network calls as the baseline.
- Make screens `StatelessWidget` where possible once state has moved.

## MANDATE 6 — Reuse what exists; pure functions out of build()

- Before writing a widget, search `core/widgets/`, `shared/common/widgets/` and the feature's own `widgets/`. Extend with a parameter rather than copying.
- A widget used by two or more features moves to the shared library **at the moment the second use appears**.
- **No two classes in the codebase share a name.** Diff each collision before merging — copies with the same name often have different constructors and are not interchangeable.
- Replace `Widget _buildXxx()` methods with private `StatelessWidget` classes in the same file. A method returning a Widget cannot be `const`, cannot take a key, and rebuilds with its whole enclosing widget.
- Pure logic (dates, formatting, derived values, validation) lives on the entity or in `core/extensions/`, never inside `build()`.
- Delete commented-out code rather than keeping it.
- File size ceiling: 400 lines. Split by extracting cohesive units, not arbitrarily at line 400.
- **Do not abstract for its own sake.** Extract when the same UI appears more than once with identical structure and different configuration.

## MANDATE 7 — One responsive source

- Breakpoints are defined once in `lib/core/responsive/app_breakpoints.dart`. No other file contains a screen-width comparison against a literal.
- One `LayoutBuilder`, at the top of the tree inside `ResponsiveScope`, publishing the size class through an `InheritedWidget`. Feature code reads `context.screenSize` / `context.isTablet` / `context.responsive(compact:, medium:, expanded:)`; it does not measure.
- `updateShouldNotify` compares the size **class**, not the width — otherwise every dependant rebuilds during rotation and keyboard transitions.
- A feature `LayoutBuilder` is allowed **only** when the widget must respond to its own box rather than the screen. Those stay. List each one you keep and say why.
- `MediaQuery.sizeOf(context)` over `MediaQuery.of(context)` — `.of` subscribes to the whole object, so a width read re-runs on every keyboard open.
- No hardcoded pixel dimension for anything that should scale. Fixed sizes are for icons and borders. Content uses `Flexible`, `Expanded`, `AspectRatio`, or `AppSizes`.
- **Warning:** making the existing helpers agree changes layout for widths 600–767, because `responsive_helper` (116 importers) currently calls that range "phone" and `AppBreakpoints` calls it tablet. That is app-wide. Produce an impact report before applying it.

## MANDATE 8 — Models everywhere, generated, never raw maps

- Every API payload has a model class in `data/features/<x>/models/`. **Request models too, not just responses.**
- Models are annotated `@JsonSerializable()` with generated `fromJson`/`toJson` via `part 'x.g.dart'`. No hand-written serialisation.
- Field quirks are annotations, not inline expressions: `@JsonKey(name:)`, `@JsonKey(readValue:)`, `@JsonKey(defaultValue:)`.
- **No `Map<String, dynamic>` in `lib/domain` or `lib/presentation`** — not as a parameter, not as a return type, not as a field. Maps stop at the datasource.
- If an entity has a model, that model is the type used everywhere it travels.
- A view never builds a wire payload. It hands typed values to a cubit; the cubit hands a model to a use case; `toJson()` happens once, in the datasource.
- Datasources call `Model.fromJson(response)` and return the model. They do not read keys off a map.
- Domain entities have no serialisation. Mappers convert model → entity, which is what `mappers/` is for.
- `build_runner ^2.1.4` is already a dev dependency (wired for Isar). Add `json_annotation` to dependencies and `json_serializable` to dev_dependencies. **Use json_serializable, not freezed.** Commit the `.g.dart` files.
- **Parse behaviour must be identical, including on malformed input.** Before deleting any hand-written parser, write a test feeding the same fixture through old and new and asserting field-for-field equality — including nulls, missing keys and wrong types.
- Do not change backend API contracts or parameter names. Do not silently change null/default semantics.

---

## Recommended execution order (revised)

The order in the original Reports prompt set was: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8. Two changes are worth making:

**Move 6 before 4.** Mandate 6 deletes duplicated screens and widgets. Theming them first (Mandate 4) means tokenising code you are about to delete — in the classroom module that is two assign forms sharing 151 lines, and in reports it is fourteen near-identical form screens.

**Run 5 immediately after 1, not after 4.** Mandate 1 already requires cubits to be created in `GoRoute` builders, which is Mandate 5's work. Splitting them means doing half of 5 inside 1, then coming back. Do 1 and 5 as a pair.

Revised: **1 → 5 → 2 → 3 → 6 → 4 → 7 → 8**

**Before any of it:** each module's blocker prompts, from the risk-ordered files. These mandate prompts are architecture work; the blockers are defects. Fixing the classroom ratio indicator or the messaging outbox is worth more than any refactor in this file, and doing the refactor first means moving broken code into a nicer shape.

**One note on tests.** These prompts follow the original instruction not to add tests. That is defensible for a pure move, but it means every refactor here runs unverified against modules that currently have zero tests. At minimum, add characterisation tests for the pure-logic files (`classroom_age_range.dart`, the scheduling validators, `newsletter_content_parser.dart`, `individual_movement_validators.dart`) before Mandate 6 touches them.