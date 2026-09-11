# Students Module — Eight Mandates Compliance Audit

| | |
|---|---|
| **Module** | Students |
| **Paths** | `lib/presentation/features/students/`, `lib/data/features/student/`, `lib/domain/features/student/` |
| **Commit audited** | `cdb6b86e251c87c14718cf1054344e480f8f091f` (`cdb6b86e`), branch `develop-refactor` |
| **Date** | 2026-09-09 |
| **Scope size** | 154 files, 33,915 lines |
| **Standard** | `WowCare2-Engineering-Standards-Eight-Mandates 1.pdf` + `docs/mandate-rules.md` |
| **Nature** | Audit only. No code was changed. |

> **A note on inputs.** The task template arrived with `MODULE_NAME` and `MODULE_PATH` as
> unfilled placeholders. I resolved them from the prose instruction ("the Students module") and
> verified all three directories exist before auditing. No path was invented. Note the
> singular/plural split: presentation is `students/`, data and domain are `student/`.
>
> **Precedence note.** The brief says `docs/mandate-rules.md` wins where the two sources differ.
> `docs/mandate-rules.md` itself says the PDF wins. I followed the brief and flagged the conflict
> in **Open questions**, as in the four prior audits. The two agree on all eight rules; they
> differ only in emphasis and recommended execution order.

**Severity definitions** (identical to the four existing audits in this folder):
**Critical** — a live defect or a security/correctness hazard reachable in production.
**High** — a rule broken in a way that will cause divergence or defects as the code changes.
**Medium** — a real rule breach with contained blast radius.
**Low** — cosmetic, mechanical, or already mitigated in practice.

---

## 0. Scope — the exact file set audited

**154 files, 33,915 lines.** Every file below was read in full.

### `lib/data/features/student/` — 23 files

| Folder | Files |
|---|---|
| `datasources/` (2) | `student_remote_datasource.dart` (2,054), `student_document_remote_datasource.dart` |
| `mappers/` (13) | `guardian_profile_mapper.dart`, `school_guardian_summary_mapper.dart`, `student_guardian_mapper.dart`, `student_health_mapper.dart`, `student_health_update_request_mapper.dart`, `student_immunization_mapper.dart`, `student_physical_exam_mapper.dart`, `student_physician_mapper.dart`, `student_pickup_mapper.dart`, `student_regular_schedule_input_mapper.dart`, `update_guardian_request_mapper.dart`, `update_student_address_request_mapper.dart`, `update_student_profile_request_mapper.dart` |
| `models/` (7 + 3 generated) | `student_models.dart` (761) + `.g.dart`, `student_document_models.dart` + `.g.dart`, `student_physician_models.dart` + `.g.dart`, `student_pickup_models.dart`, `vaccine_model.dart` |
| `repositories/` (1) | `student_repository_impl.dart` (1,795) |

### `lib/domain/features/student/` — 68 files

| Folder | Files |
|---|---|
| `entities/` (~14) | `student.dart`, `guardian_profile.dart`, `school_guardian_summary.dart`, `student_health.dart`, `student_health_update_request.dart`, `student_regular_schedule_input.dart`, `update_guardian_request.dart`, `update_student_address_request.dart`, `update_student_profile_request.dart`, and the physician / pickup / immunization / physical-exam / important-dates entities |
| `repositories/` (2) | `student_repository.dart` (490), `student_document_repository.dart` |
| `usecases/` (~52) | the full CRUD surface — `get_student_page`, `get_student_profile`, `create_student`, `update_student_profile`, `update_student_address`, `update_student_health`, `update_student_important_dates`, `update_student_regular_schedules`, `update_student_siblings`, `update_student_tags`, the guardian set (`get_student_guardians`, `create_guardian_user`, `link_existing_guardian`, `update_guardian`, `delete_guardian`, `get_guardian_names_for_school`, `get_guardian_name_code_map_for_school`, `get_guardians_raw_for_school`), the physician set, the pickup set, the physical-exam set, the immunization set, the document set, the tag set, `get_student_counts`, `get_student_settings`, `get_student_codes_for_activity_tag_filter` |

### `lib/presentation/features/students/` — 63 files

| Folder | Files |
|---|---|
| *(feature root, 2)* | `module_access.dart`, `student_strings.dart` (383) |
| `model/` (1) | `student_sibling_info.dart` |
| `utils/` (1) | `profile_photo_background.dart` |
| `view/` (17) | `student_screen.dart` (1,888), `student_profile_screen.dart` (1,342), `edit_student_profile_details_screen.dart` (1,479), `add_student_step1_screen.dart` (1,317), `add_student_step2_screen.dart` (1,178), `add_student_step3_screen.dart` (449), `add_student_wizard_screen.dart`, `add_pickup_screen.dart` (713), `add_document_screen.dart` (596), `add_physician_screen.dart`, `edit_student_health_screen.dart`, `edit_student_important_dates_screen.dart`, `edit_student_physical_exam_screen.dart`, `student_filter_screen.dart` (463), `student_form_formatters.dart`, and two more |
| `view/student_health_tab_cards/` (4) | `student_dates_tab_card.dart` (881), `student_immunization_tab_card.dart` (837), `student_physician_tab_card.dart` (530), `student_health_tab_card.dart` |
| `view/student_profile_screen_tabs/` (4) | `student_documents_tab.dart` (997), `student_profile_tab.dart` (480), `student_health_tab.dart`, `student_important_dates_tab.dart` |
| `view/student_profile_tab_cards/` (3) | `student_about_tab_card.dart` (1,153), `student_pickup_tab_card.dart` (613), `student_family_tab_card.dart` (532) |
| `view_model/` (26) | `student_cubit.dart` (890), `student_create_cubit.dart` (421), `student_profile_cubit.dart`, `student_profile_edit_cubit.dart`, `student_guardian_cubit.dart`, `student_health_cubit.dart`, `student_physician_cubit.dart`, `student_physical_exam_cubit.dart`, `student_pickup_cubit.dart`, `student_document_cubit.dart`, `student_documents_list_cubit.dart`, `student_important_dates_cubit.dart`, `student_immunization_cubit.dart`, `student_schedule_cubit.dart`, `student_tags_cubit.dart`, and their paired `*_state.dart` files |
| `widgets/` (5) | `student_action_panel.dart` (1,090), `student_card.dart` (707), `same_last_name_siblings_dialog.dart`, and two more |

### Also examined (module code outside MODULE_PATH, and shared code the module reaches into)

`lib/shared/common/widgets/student_tile.dart` · `selected_student_tile.dart` ·
`remove_student_tile.dart` · `student_search_dropdown.dart` ·
`post_add_student_bottom_sheet.dart` · `duplicate_student_bottom_sheet.dart` ·
`lib/shared/common/widgets/schedule_picker.dart` ·
`lib/presentation/features/staff/view/add_staff_screen_formatters.dart` ·
`lib/presentation/features/staff/widgets/staff_documents_tab.dart` ·
`lib/presentation/features/billing/model/student_models.dart` ·
`lib/domain/features/user_profile/entities/guardian_profile.dart` ·
`lib/presentation/features/user_profile/view/edit_user_profile_screen.dart` ·
`lib/core/router/app_routes.dart` · `lib/src/app_router.dart` · `lib/app/di/di.dart` ·
`lib/core/theme/*` · `lib/core/constants/app_strings.dart` ·
`lib/core/responsive/*` · `lib/shared/utils/responsive_helper.dart` · `pubspec.yaml` ·
`analysis_options.yaml` · 86 test files under `test/`

**Adjacent feature excluded from the counts.** `lib/data/features/student_classroom/` (3 files)
and `lib/domain/features/student_classroom/` (4) are separate feature directories under the
standard's structure, consumed by the classroom module's assign flow. Named here so the boundary
is explicit; also flagged in `classroom-module-audit.md`.

---

## 1. Summary table

| # | Mandate | Verdict | Violations | Highest severity |
|---|---|---|---|---|
| 1 | Navigation — GoRouter everywhere | **Violated** | 3 | High |
| 2 | State — setState scarcely | **Violated** | 3 | High |
| 3 | Folder structure | **Violated** | 5 | Medium |
| 4 | Centralized theming / constants | **Partially violated** | 4 | High |
| 5 | Presentation talks to cubits only | **Violated** | 4 | **Critical** |
| 6 | Reuse; pure functions out of build() | **Violated** | 5 | High |
| 7 | One responsive source | **Violated** | 3 | Medium |
| 8 | Models everywhere, never raw maps | **Partially violated** | 3 | High |
| | **Total** | | **30** | |

No mandate is Not Applicable — all eight bear on this module.

---

## 2. Overall risk assessment

Students is the module the standard cites most often, and it is the module where the most cited
defects have survived. The PDF's flagship §5.2a example — *"A view calling a datasource"*, which
it says *"was cited by name fifteen months of commits ago and has not been touched"* — is not only
still live, it has **spread**: `serviceLocator<StudentRemoteDataSource>()` now appears at six sites
across **five** view files, where the reference commit recorded three sites in one. The module
makes 81 `serviceLocator` calls (the most of any module audited; Scheduling makes 4), resolves
`StorageService` 26 times and `ApiClient` twice inside presentation, and three views drive their
own `FutureBuilder` over data the cubits already hold — a pattern the cubits' own doc comments
acknowledge in writing.

Set against that, the data and domain layers are the strongest in the codebase. Domain is pure —
no Flutter imports, no `fromJson`/`toJson` on entities, and the only `Map<String, dynamic>`
mentions are doc comments describing what typed request entities *replaced*. The data layer has
**13 mapper files** (the largest `mappers/` folder in the repo, against two features having one at
all) and real code generation: 6 `@JsonSerializable` classes with 3 committed `.g.dart` files. And
the module carries **86 tests** — 48 use-case, 16 data-layer including 12 mapper tests, 22
presentation — comfortably the best coverage in the repo, where Classroom and Scheduling have zero.

Theming is largely done: 437 `AppColors` and 451 spacing-token references, and a
`StudentStrings` class with 367 entries used by 33 files. The unfinished half is typography — 146
inline `TextStyle(` constructors against 65 `AppTextStyles` uses — and responsiveness, where the
module makes zero use of the mandated `context.responsive` API and still derives a screen
breakpoint from a `LayoutBuilder` at `student_screen.dart:1314`, which is the PDF §7.4 *WRONG*
block reproduced almost verbatim.

The practical risk is concentrated and specific: the write and read paths for student profile data
run through views that talk to the datasource directly, so a bug on those screens can originate in
the cubit, the view, or the cache the view writes itself — which is exactly the diagnosis cost
§5.5 describes. The strong test suite covers the cubits and use cases but not those view-level
calls, so the safety net does not reach the riskiest code.

---

## 3. Findings by mandate

### Mandate 1 — Navigation: GoRouter everywhere, MaterialPageRoute nowhere

**Verdict: Violated** (3 violations, highest High)

**What is compliant.** 40 GoRouter calls — 21 `context.push`, 18 `context.pop`, 1 `context.go` —
so the migration is substantially under way. The PDF §1.1 table records
`presentation/features/students/view/student_screen.dart` at **9** raw pushes; it now has 4.

---

#### 1.1 — Eight `MaterialPageRoute` and eight `Navigator.push` sites remain

**Rule broken.** MANDATE 1: *"No `Navigator.push`, `Navigator.of(context).push`, or
`MaterialPageRoute` anywhere under `lib/presentation`."* The only stated exemption is
*"Modals are exempt."*

**Where.** 8 `MaterialPageRoute`, each paired with a `Navigator.push`:

| File | Lines |
|---|---|
| [view/student_screen.dart](lib/presentation/features/students/view/student_screen.dart) | 759, 807, 863, 910 |
| [view/student_health_tab_cards/student_physician_tab_card.dart](lib/presentation/features/students/view/student_health_tab_cards/student_physician_tab_card.dart) | 94, 458 |
| [view/student_health_tab_cards/student_health_tab_card.dart](lib/presentation/features/students/view/student_health_tab_cards/student_health_tab_card.dart) | 136 |
| [view/student_profile_screen_tabs/student_documents_tab.dart](lib/presentation/features/students/view/student_profile_screen_tabs/student_documents_tab.dart) | 176 |

```dart
// view/student_screen.dart:757-766
await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => sign_in_form.StudentSignInForm(
      students: entities,
      refreshCallback: () {
        context.read<StudentCubit>().refresh();
      },
    ),
```

**Why it violates.** The prohibition is unconditional and these push full screens. The four in
`student_screen.dart` push *attendance* module forms (`StudentSignInForm` and siblings), so this
module reaches imperatively into another feature's screens — which already declare `routeName`
statics of their own. The `refreshCallback` closure is the same rationale the attendance module
documents for its own holdouts; unlike attendance, no comment here records a decision.

**Severity: High.** Eight unguarded entry points into full screens, four of them cross-feature.
The router's `redirect` — where the kiosk lock and any future guard live — does not observe them.

**Fix.** Convert to `context.push` with a typed args class carrying the entity list and the
callback through `extra`. The scheduling module's `AddShiftRouteArgs` is the in-repo template and
demonstrates that `extra` carries closures and live objects safely. Do the four cross-feature
pushes first — they target routes that already exist.

---

#### 1.2 — No `StudentRoutes` constants class; fourteen inline route paths on screen classes

**Rule broken.** MANDATE 1: *"Route paths and names live as constants in
`lib/core/router/app_routes.dart`."*

**Where.** `app_routes.dart` has **no** `StudentRoutes` class. Its only student entries are
*report* routes under a reports hub ([app_routes.dart:21-56](lib/core/router/app_routes.dart#L21-L56)).
The module instead declares 14 paths inline on screen classes:

```dart
// view/student_screen.dart:71
static const String routeName = '/dashboard/students';
// view/student_profile_screen.dart:51
static const String routeName = '/dashboard/student-profile';
// view/add_student_step1_screen.dart:56
static const String routeName = '/add-student-step1-screen';
```

plus `add_student_step2/step3`, `add_student_wizard`, `add_document`, `add_physician`,
`add_pickup`, `edit_student_profile_details`, `edit_student_health`,
`edit_student_important_dates`, `edit_student_physical_exam`, `student_filter`.

**Why it violates.** The mandate wants one file to be the list of route paths. Scheduling has
`SchedulingRoutes` with six constants and Kiosk has a documented `KioskRoutes`; this module has
none, so the router depends on presentation classes for its addressing.

**Severity: Medium.** No runtime effect; it is the precondition for §1.1 and it means no single
file inventories the module's routes.

**Fix.** Add a `StudentRoutes` block to `app_routes.dart` covering the 14 paths, and have both
`app_router.dart` and the screens reference the constants. Add only this module's routes, per the
mandate's instruction.

---

#### 1.3 — Screen-route pops go through `Navigator`

**Rule broken.** MANDATE 1: *"Every navigation goes through GoRouter: `context.push(...)`,
`context.go(...)`, `context.pop()`."*

**Where.** 41 `Navigator.pop` calls against 18 compliant `context.pop` calls — the module uses
both conventions side by side. A representative result-returning screen pop:

```dart
// view/student_screen.dart — the same file also uses context.pop elsewhere
Navigator.of(context).pop(true);
```

**Why it violates.** The mandate names `context.pop()` as the way. A subset of the 41 are exempt
modal and bottom-sheet dismissals; the remainder close screens. The notable point is the
inconsistency — 18 sites already use `context.pop`, so two conventions coexist within the module
and sometimes within a file.

**Severity: Medium.** No guard runs on pop today, so no live gap; the cost is that the module will
not inherit a future pop-time guard, and the mixed convention makes the boundary unclear.

**Fix.** Audit the 41 sites, separating modal dismissals (which stay) from screen-route pops
(which become `context.pop`). Preserve each result value — several drive a caller refresh. Do this
alongside §1.1 so each screen is converted once.

---

### Mandate 2 — State: setState scarcely, ValueNotifier for UI micro-state

**Verdict: Violated** (3 violations, highest High)

Measured: **67 `setState` calls across 18 files**; 30 `StatefulWidget` vs 25 `StatelessWidget`;
37 `BlocBuilder`; **0** `BlocSelector`; **0** `ValueNotifier`; **0** `ValueListenableBuilder`.

**What is compliant.** The `view_model/` folder holds 26 files — 13 cubit/state pairs covering
profile, guardians, health, physicians, physical exams, pickups, documents, important dates,
immunizations, schedules and tags. They are real cubits with `Equatable` state, `isClosed` guards
and injected use cases, and **22 of the module's 86 tests** cover them directly
(`student_cubit_pagination_dedup_test.dart`, `student_cubit_generation_guard_test.dart`,
`student_cubit_search_debounce_test.dart`, `student_cubit_mutation_single_flight_test.dart` among
them). The view-model layer is well built; the problem is that the views do not fully rely on it.

---

#### 2.1 — Bucket A state held in widget `State`, including the card the standard names

**Rule broken.** MANDATE 2, Bucket A: *"API results, loading flags, filters, form submission,
selections that outlive the widget → Cubit"*, and *"Bucket A is 'no exceptions'."* PDF §2.3
tabulates `presentation/features/students/widgets/student_card.dart:211` by name.

**Where.** 67 `setState` calls. Highest: `student_profile_screen.dart` 14,
`student_action_panel.dart` 8, `student_screen.dart` 8, `student_documents_tab.dart` 7,
`student_important_dates_tab.dart` 5, `student_filter_screen.dart` 5,
`student_health_tab_card.dart` 4.

The card the PDF names is still 707 lines (was 732) and still toggles by `setState`:

```dart
// widgets/student_card.dart:82
late bool isExpanded = widget.initiallyExpanded;

// widgets/student_card.dart:218-222
child: InkWell(
  onTap: () {
    setState(() {
      isExpanded = !isExpanded;
    });
  },
```

**Why it violates.** `student_card.dart` is the §2.3 worked example verbatim — a `StatefulWidget`
existing largely to hold one boolean, where the toggle rebuilds the whole card including the photo
and badges. The 14 calls in `student_profile_screen.dart` are worse: that screen fetches profile
data itself (§5.1) and stores the result in `State`, which is Bucket A with no exception.

**Severity: High.** A "no exceptions" rule broken on the module's central screen and on the exact
widget the standard uses to illustrate the cost.

**Fix.** For `student_card.dart`, the standard's own §2.3 remedy applies: `ExpandableInfoCard`
already exists at `lib/core/common/widgets/expandable_info_card.dart` with a general API and zero
callers — extend it rather than converting in place (see §6.5). For
`student_profile_screen.dart`, the profile state moves into `StudentProfileCubit`, which exists
and is tested; this closes §5.1 at the same time.

---

#### 2.2 — Zero `ValueNotifier` and zero `ValueListenableBuilder` in 63 files

**Rule broken.** MANDATE 2, Bucket B: *"If the state is owned by one widget, never read by
anything outside it, and would be thrown away on navigation, use `ValueNotifier` with
`ValueListenableBuilder`."*

**Where.** Neither appears anywhere in the module, while 67 `setState` calls do — several of them
plainly Bucket B (the `student_card.dart` expand toggle above, filter chip selections in
`student_filter_screen.dart`, tab visibility toggles in the health tab cards).

**Why it violates.** Bucket B has no representation at all. The mandate routes expand/collapse and
chip selection to `ValueNotifier` specifically so the surrounding subtree stops rebuilding; here
every such toggle marks the whole `State` dirty.

**Severity: Medium.** No defect, but it means the §2.1 conversion has two destinations to sort
between, and the module has no in-house example of the pattern to copy. Scheduling
(`day_classroom_section.dart`) is the nearest reference.

**Fix.** As part of §2.1, classify each `setState` into the mandate's three buckets. Convert the
Bucket B ones to `ValueNotifier` held as a final field and disposed, with
`ValueListenableBuilder` — and pass `child:`, which is the point of the rule.

---

#### 2.3 — Zero `BlocSelector` across 37 `BlocBuilder`s

**Rule broken.** MANDATE 2: *"Use `BlocSelector` where only a small part of the UI depends on one
state property."*

**Where.** 37 `BlocBuilder` usages, 0 `BlocSelector`, across screens of 1,888, 1,479 and 1,342
lines.

**Why it violates.** Every `BlocBuilder` rebuilds its subtree on any state change, and these are
among the largest subtrees in the codebase.

**Severity: Low.** A performance rule rather than a correctness one.

**Fix.** Apply `BlocSelector` opportunistically during §2.1 where one small widget reads one
property — the student counts on `student_screen.dart`, submit-button enablement on the add
wizard. Not worth a dedicated sweep.

---

### Mandate 3 — Folder structure, followed strictly

**Verdict: Violated** (5 violations, highest Medium)

**What is compliant — and the domain layer is exemplary.** Domain entities are **pure Dart with no
Flutter imports** and carry **no `fromJson`/`toJson`** — verified by exhaustive grep across all 68
domain files. (Scheduling, by contrast, has five Flutter imports in its domain.) The data layer
has all four canonical folders including `mappers/`, and the presentation layer has `model/`,
`view/`, `view_model/` and `widgets/`.

---

#### 3.1 — Two loose files at the feature root, one named by the standard

**Rule broken.** MANDATE 3, canonical presentation layout: `model/  view/  view_model/  widgets/`.
PDF §3.3 lists `lib/presentation/features/students/module_access.dart` explicitly:
*"Loose file at a feature root. Move under domain if it is a rule, or `view_model/` if it is UI
gating."*

**Where.**

```
lib/presentation/features/students/module_access.dart      ← named in PDF §3.3, unmoved
lib/presentation/features/students/student_strings.dart    (383 lines, 367 entries)
```

**Why it violates.** Neither sits in one of the four canonical folders. `module_access.dart` was
called out by path at the reference commit and has not moved. `student_strings.dart` is a
constants file, which the canonical structure places in `core/constants/` (see §4.3 for the
substantive question about it).

**Severity: Medium.** No runtime effect; `module_access.dart` is an access rule sitting outside
both domain and `view_model/`, which is where a reviewer or path-scoped check would look for it.

**Fix.** Read `module_access.dart` and place it per the PDF's own instruction — domain if it is a
rule, `view_model/` if it is UI gating. Hold `student_strings.dart` until the `AppStrings`
convention question (§4.3, **Open questions**) is settled, since its destination depends on that.

---

#### 3.2 — A forbidden `utils/` folder

**Rule broken.** MANDATE 3: *"A presentation `util/` or `utils/` folder should not exist. Pure
business rules go to `domain/features/<x>/usecases/` or a domain service; mappers go to
`data/features/<x>/mappers/`; presentation helpers go to `widgets/` or `core/extensions/`."*

**Where.** [lib/presentation/features/students/utils/profile_photo_background.dart](lib/presentation/features/students/utils/profile_photo_background.dart)
— the folder's only file, which resolves `serviceLocator` three times.

**Why it violates.** The folder name is explicitly forbidden. This is the smallest instance of the
violation across the five modules audited (Scheduling has 5 files / 1,098 lines, Classroom 1 file,
Kiosk 1 file), but the rule is absolute.

**Severity: Medium.** One file; the `serviceLocator` calls inside it are the substantive issue
(§5.2), not the folder itself.

**Fix.** Move it to `widgets/` if it is a presentation helper, or to a domain/core service if the
photo-background derivation is a rule. Its DI resolution should move with it (§5.2).

---

#### 3.3 — Three levels of `view/` subdirectories holding non-screen files

**Rule broken.** MANDATE 3: *"`view/` # screens. Zero logic. Zero API calls."* And
*"`widgets/` # this feature only."*

**Where.** `view/` holds 17 files plus three subdirectories of card widgets:

```
view/student_health_tab_cards/     (4 files — student_dates_tab_card.dart 881, …)
view/student_profile_screen_tabs/  (4 files — student_documents_tab.dart 997, …)
view/student_profile_tab_cards/    (3 files — student_about_tab_card.dart 1,153, …)
```

Also in `view/`: `student_form_formatters.dart`, which declares three `TextInputFormatter`
classes, not a screen.

**Why it violates.** Eleven card and tab widgets live under `view/` while the feature's `widgets/`
folder holds only five files. The canonical split puts screens in `view/` and this feature's
widgets in `widgets/`. `student_form_formatters.dart` is neither a screen nor a widget — it is
input-formatting logic (and duplicated, see §6.1).

**Severity: Medium.** Structural; it splits the widget surface across four directories and puts
1,000-line widgets in the screens folder.

**Fix.** Move the eleven card/tab widgets into `widgets/`, preserving the three-way grouping as
subdirectories there if that grouping is useful. Move `student_form_formatters.dart` to
`core/extensions/` or a shared formatters location — §6.1 shows it is duplicated with the staff
module, so resolve both together.

---

#### 3.4 — Feature directory naming is inconsistent across layers

**Rule broken.** MANDATE 3 / PDF §3.1: `<feature_name>/  # snake_case` — one feature name used
consistently across `data/`, `domain/` and `presentation/`.

**Where.** `lib/data/features/**student**/`, `lib/domain/features/**student**/`, but
`lib/presentation/features/**students**/`.

**Why it violates.** The same feature has two names, so a path-scoped search or CI rule written
for `features/student/` misses the entire presentation layer and vice versa — the §3.6 "the check
simply does not run and nothing reports that it skipped anything" failure mode. The activity
module has the identical `activity`/`activities` split, flagged in `activity-module-audit.md` §3.7.

**Severity: Low.** Cosmetic, but it defeats path-based tooling exactly as the standard warns.

**Fix.** Pick one name app-wide. Because the same split exists in the activity module, this should
be one coordinated decision rather than two independent renames.

---

#### 3.5 — Cross-folder relative imports

**Rule broken.** MANDATE 3, Imports: *"all cross-folder imports use `package:wowcare/...`.
Relative imports only within the same folder."*

**Where.** Relative `../`-crossing imports appear throughout the data and presentation layers.

**Why it violates.** Cross-folder imports must use the `package:` form. Note the specific hazard
§3.4 describes — an import with one excess `..` compiles in the app but breaks when a test reaches
the file by `file:` URI. **I resolved every relative import in the module and all point at real
files**, so that latent breakage is absent. This module has 86 tests, several of which do reach
these files, and none fails to load.

**Severity: Low.** No broken imports; mechanical consistency only.

**Fix.** Single codemod converting `../`-crossing imports to `package:wowcare/...`, leaving
same-folder relative imports alone. Run after §3.1–§3.3 have moved files.

---

### Mandate 4 — Centralized theming, constants, strings, colors, fonts, sizes

**Verdict: Partially violated** (4 violations, highest High)

Measured — **the most complete theming result of the five modules on colour and spacing**:

| Check | Count | Status |
|---|---|---|
| Raw `Colors.<name>` | **6** | near-compliant |
| `Color(0x...)` | **8** | near-compliant |
| `AppColors.` uses | **437** | — |
| `AppSpacing`/`AppRadius`/`AppDimensions` uses | **451** | — |
| `StudentStrings.` uses | **424** | see §4.3 |
| `AppTextStyles.` uses | 65 | partial |
| Inline `TextStyle(` | **146** | Violated |
| `fontFamily:` | **117** | Violated |

For comparison: Scheduling has 55 raw colours and zero spacing tokens; Classroom has zero spacing
tokens. Students has 888 token references across colour and spacing.

---

#### 4.1 — 146 inline `TextStyle(` constructors alongside 65 `AppTextStyles` uses

**Rule broken.** MANDATE 4: *"No inline `TextStyle(`. Use `Theme.of(context).textTheme.<slot>` or
a named `AppTextStyles` entry; local variation uses `.copyWith()` on a named style, never a fresh
`TextStyle`."*

**Where.** 146 inline constructors across the module — `edit_student_profile_details_screen.dart`
13, `add_student_step2_screen.dart` 13, `add_student_step1_screen.dart` 13,
`student_documents_tab.dart` 10, `student_card.dart` 9, `student_profile_screen.dart` 9,
`student_health_tab_card.dart` 8, `add_student_step3_screen.dart` 8, and more.

The module *does* use the correct pattern in places:

```dart
// view/add_document_screen.dart:332 — the mandated form
final labelStyle = AppTextStyles.label.copyWith(
// view/student_health_tab_cards/student_health_tab_card.dart:154
Text('Health', style: AppTextStyles.title),
```

but far more often writes a fresh style:

```dart
// view/add_student_step1_screen.dart:873-878
style: TextStyle(
  fontFamily: Fonts.manrope,
  fontSize: responsive.titleFontSize,
  fontWeight: FontWeight.w600,
  color: AppColors.primaryColor,
),
```

**Why it violates.** The rule names both destinations and 146 sites use neither. This is a
half-migrated state on the same screens as the compliant 65 — which is harder to reason about
than a wholly-unmigrated module, because a later typography change updates some text on a screen
and not the rest.

**Severity: High.** The largest inline-`TextStyle` count of the five modules (Scheduling 98,
Classroom 59, Kiosk 20), on the module's highest-traffic add/edit wizards.

**Fix.** Add named `AppTextStyles` entries for the recurring size/weight combinations — there are
far fewer distinct styles than 146 sites — and replace the constructors, using `.copyWith()` for
local variation as `add_document_screen.dart` already does. Rendered output must be identical;
where a combination has no entry, add it with those exact values and list what was added.

---

#### 4.2 — 117 `fontFamily:` lines that the rule says to delete

**Rule broken.** MANDATE 4: *"No `fontFamily: 'Manrope'`. The family is already on `ThemeData` —
these lines are a find-and-delete."*

**Where.** 117 occurrences, of which **104 use the `Fonts.manrope` token** and **8 use the raw
string** `'Manrope'`:

```
104 × fontFamily: Fonts.manrope
  8 × fontFamily: 'Manrope'
  1 × fontFamily: Fonts.inter
```

**Why it violates.** The rule's remedy is deletion, not tokenisation — `TextStyle` inherits the
family from `ThemeData`, so every one of these lines is redundant regardless of form. The 8 raw
strings are the literal case the rule names; the 104 token references are one step better but
still redundant. The single `Fonts.inter` is a deliberate different family and must be kept.

**Severity: Medium.** Zero-risk to fix for the `TextStyle` cases and mechanically bounded, but 117
sites is the largest count of this violation across the five modules (Classroom 57, Activity 3).

**Fix.** Delete the 116 Manrope lines; **keep the `Fonts.inter` one**, which is an intentional
override. Do this **after** §4.1, since converting to named `AppTextStyles` entries removes most
of them as a side effect. Unlike the Activity module's `StrutStyle` case, all of these are inside
`TextStyle`, so deletion is behaviour-preserving — verify the rendered font is unchanged.

---

#### 4.3 — Strings centralise into a feature-local `StudentStrings`, not the mandate's `AppStrings`

**Rule broken.** MANDATE 4: *"No user-visible string literal in a view file. Everything through
`AppStrings` (`lib/core/constants/app_strings.dart`)."*

**Where.** `AppStrings.` appears **0 times**. Instead
[student_strings.dart](lib/presentation/features/students/student_strings.dart) declares 367
entries used **424 times across 33 files**:

```dart
/// Centralized user-visible copy for the Student feature (Step 7).
/// Every display string in the Student module resolves through this class so
/// copy lives in one place. Code/enum values, interpolated strings, map keys and
/// format patterns are intentionally NOT here — they are logic, not display copy.
/// Mirrors the established `BillingStrings` convention.
class StudentStrings {
  static const String about = 'About';
```

Repo-wide there are three such classes — `StudentStrings`, `BillingStrings`, `ReportsStrings` —
against `AppStrings` with 58 entries and 17 importers.

**Why it violates — narrowly.** The module *has* centralised its strings, which is the rule's
purpose, and it has done so more thoroughly than any module audited (367 entries vs `AppStrings`'
58 in total). It simply centralised into a feature-local class the mandate does not name. The
doc comment shows this was a deliberate, documented convention, not drift. Reporting this as "no
string centralisation" would be wrong.

**Severity: Low.** The intent of the rule is met and exceeded. The finding is the app-wide
convention split, not this module's behaviour.

**Fix.** This is an app-wide decision, not a module change — see **Open questions**. Whichever
convention wins, the losing one should delegate rather than be deleted. **Do not migrate this
module in isolation**; it would move 367 entries for no functional gain while two sibling features
keep the other pattern.

---

#### 4.4 — Fourteen residual hardcoded colour references

**Rule broken.** MANDATE 4: *"No `Color(0x...)` and no `Colors.<name>` outside
`core/theme/app_colors.dart`."*

**Where.** 6 raw `Colors.*` and 8 `Color(0x…)`, concentrated in the health tab cards:
`student_physician_tab_card.dart` 3, `student_health_tab_card.dart` 2,
`edit_student_physical_exam_screen.dart` 1, plus the eight hex literals.

**Why it violates.** The prohibition is unconditional. In context these are clearly stragglers —
437 `AppColors` references surround them.

**Severity: Low.** Fourteen sites against 437 compliant ones; the sweep is nearly complete.

**Fix.** Tokenise the 14 against `AppColors`, adding tokens with the exact hex where no match
exists. A short, low-risk sweep that finishes this half of the mandate.

---

### Mandate 5 — Presentation talks to cubits only

**Verdict: Violated** (4 violations, highest **Critical**)

Measured — **the weakest layer-discipline result of the five modules**:

| Check | Students | Scheduling | Activity | Classroom | Attendance/Kiosk |
|---|---|---|---|---|---|
| `serviceLocator<T>()` in presentation | **81** | 4 | 27 | 38 | 60 |
| Datasource types named in a view | **6** | 0 | 0 | 0 | 0 |
| `FutureBuilder` over cubit-owned data | **3** | 0 | 0 | 1 | 0 |

---

#### 5.1 — Views call `StudentRemoteDataSource` directly — the standard's flagship example, now in five files

**Rule broken.** MANDATE 5: *"A view file may reference exactly three things from outside itself:
its own Cubit… widgets, and constants."* Forbidden explicitly: *"`DataSource`, `Repository`,
`RepositoryImpl`, `ApiClient`, `Dio`, `StorageService`, `SharedPreferences` types"*. PDF §5.2a
uses this module as its worked example of *"A view calling a datasource"*, citing
`student_profile_screen.dart:203, 248, 420`, and notes the pattern *"was cited by name fifteen
months of commits ago and has not been touched."*

**Where.** Six sites across **five** view files:

```dart
// view/student_profile_screen.dart:261
final profile = await serviceLocator<StudentRemoteDataSource>()
    .getStudentProfile(code);
// view/student_profile_screen.dart:583
final dataSource = serviceLocator<StudentRemoteDataSource>();
final refreshed = await dataSource.getStudentProfile(studentCode);

// view/student_screen.dart:191
final profile = await serviceLocator<StudentRemoteDataSource>()
    .getStudentProfile(code);
// view/student_screen.dart:268
final dataSource = serviceLocator<StudentRemoteDataSource>();

// view/student_profile_screen_tabs/student_profile_tab.dart:181-184
final dataSource = serviceLocator<StudentRemoteDataSource>();
final model = await dataSource.getStudentProfile(studentCode);
await _cacheManager.saveCache(          // the view also writes the cache
  _studentProfileCacheKey(studentCode),

// view/add_student_step1_screen.dart:791
final remote = serviceLocator<StudentRemoteDataSource>();
await remote.updateStudentRegularSchedules(
```

**Why it violates.** The presentation layer reaches past the repository and the use case straight
into data, on both read and write paths. `add_student_step1_screen.dart:791` is a **write** —
a view mutating student schedules through the datasource. `student_profile_tab.dart:181-184` is
worse than a read: the view fetches from the datasource *and* writes the result to the cache
itself, so the screen owns a second copy of the caching policy the repository already implements.

The comparison with the reference commit matters. The PDF recorded three sites in **one** file;
there are now six across **five**. The count in `student_profile_screen.dart` fell from 3 to 2, but
the pattern propagated to four more files. It did not stay put — it spread.

**Severity: Critical.** The standard's own worst-case example, still live, on the module's core
read and write paths, now in five files. `StudentProfileCubit`, `StudentScheduleCubit` and
`GetStudentProfileUseCase` all exist and are tested, so the correct path is built and bypassed.
The §5.5 consequence is concrete: a bug in profile data on these screens can originate in the
cubit, in the view's own fetch, or in the cache the view writes — and establishing which is the
first step before any fix.

**Fix.** Route each of the six through the cubit that already exists.
`GetStudentProfileUseCase` and `StudentProfileCubit` cover the four reads;
`UpdateStudentRegularSchedulesUseCase` and `StudentScheduleCubit` cover the write (both have
tests: `update_student_regular_schedules_usecase_test.dart`, `student_schedule_cubit_test.dart`).
Move the cache write in `student_profile_tab.dart` into the repository, which already owns caching
elsewhere. Verify the network call count entering and returning to each screen is unchanged —
several of these fetches are refresh-on-return.

---

#### 5.2 — 81 `serviceLocator` calls, including `StorageService` ×26 and `ApiClient` ×2

**Rule broken.** MANDATE 5: *"No `serviceLocator<T>()` in `lib/presentation`. Cubits are created
in the router, in the `GoRoute` builder, wrapped in a `BlocProvider`. That is the only place the
service locator appears on the presentation side."* And the forbidden-types list.

**Where.** 81 calls across the module. What is resolved: `StorageService` ×26,
`StudentRemoteDataSource` ×6 (§5.1), `ClassroomCubit` ×3 (cross-feature),
`GetGuardianNamesForSchoolUseCase` ×3, `StaffRepository` ×2, `ApiClient` ×2,
`ImageUploadService` ×2, `StudentRepository` ×1, plus ~20 module cubits.

```dart
// view/edit_student_physical_exam_screen.dart:107-108 — both forbidden types in a view
storage: serviceLocator<StorageService>(),
apiClient: serviceLocator<ApiClient>(),

// view/student_profile_screen_tabs/student_profile_tab.dart:84
_cacheManager = CacheManager(serviceLocator<StorageService>());

// view/add_student_step2_screen.dart:105, 126
late final StorageService _storageService;
_storageService = serviceLocator<StorageService>();
```

**Why it violates.** The rule permits `serviceLocator` in exactly one place and none of these is
in it. `ApiClient` in a view is the §5.2b pattern the standard names; `StaffRepository` and
`StudentRepository` in presentation are repository types the forbidden list covers directly.
Four views construct their own `CacheManager` over raw storage.

**Severity: High.** 81 breaches — the most of any module — of a rule with a single permitted
location, including three forbidden type families.

**Fix.** Move cubit creation into `GoRoute` builders as §1.1's conversion lands — the two are one
piece of work, which is why `docs/mandate-rules.md` says to *"Do 1 and 5 as a pair"*. For
`StorageService`, introduce narrow domain services for what the views actually read (school code,
persona) so the cubit or service depends on an abstraction. Heed §5.4: verify no double-loading
once the loads move.

---

#### 5.3 — Three views drive `FutureBuilder` over data the cubits already own

**Rule broken.** MANDATE 5: *"No `FutureBuilder` / `StreamBuilder` in a view over data the cubit
already owns. There are 25 of these and each one is a second source of truth for state the cubit
is already tracking."*

**Where.** Three live `FutureBuilder` widgets:

```dart
// view/student_health_tab_cards/student_health_tab_card.dart:94
child: FutureBuilder<StudentHealth?>(
// view/student_profile_screen_tabs/student_profile_tab.dart:271
child: FutureBuilder<StudentProfileModel?>(
// view/student_health_tab_cards/student_physician_tab_card.dart:143
FutureBuilder<List<StudentPhysician>>(
```

The cubits acknowledge the arrangement in writing, and expose a parallel Future API to support it:

```dart
// view_model/student_guardian_cubit.dart:16-19
/// Reads stay Future-based (the views keep their own `FutureBuilder`s), so the
/// cubit does not hold the list — it only tracks mutation progress / errors.
...
/// State-based load of a student's guardians — the card renders
/// `state.guardians` via BlocBuilder instead of driving its own FutureBuilder.
```

The same doc pattern appears in `student_pickup_cubit.dart`, `student_physical_exam_cubit.dart`,
`student_health_cubit.dart`, `student_profile_cubit.dart` and `student_physician_cubit.dart` —
six cubits each carrying both a state-based `load()` and a *"Thin Future-based read for callers
that drive their own `FutureBuilder`"*.

**Why it violates.** Each cubit holds the data in state (`state.guardians`, `state.exams`) **and**
exposes a Future the view consumes independently — two sources of truth for the same value, which
is exactly what the rule exists to prevent. The comments show this is a knowing intermediate
state rather than an oversight, which makes it tractable but does not make it compliant.

**Severity: High.** Six cubits carry a dual API to support three views, so the duplication is
structural; a mutation that updates cubit state will not refresh a `FutureBuilder` unless the view
also re-triggers its future.

**Fix.** Convert the three views to `BlocBuilder` over the state the cubits already emit — each
cubit's doc comment names the intended property. Then delete the "thin Future-based read" methods
from all six cubits so the dual API cannot be re-adopted. The cubits are covered by
`student_guardian_cubit_test.dart`, `student_health_cubit_test.dart`,
`student_physician_cubit_test.dart` and siblings, so the state path is already verified.

---

#### 5.4 — Sixteen use cases resolved directly from views and widgets

**Rule broken.** MANDATE 5, forbidden: *"direct use-case invocation from a view"*.

**Where.** 16 `serviceLocator<…UseCase>()` resolutions inside `view/` and `widgets/`, including
`GetGuardianNamesForSchoolUseCase` ×3 and `GetTagNamesForSchoolUseCase` ×2.

**Why it violates.** The mandated flow is `View → Cubit → UseCase`. These skip the cubit, so the
view depends on the domain layer directly. The module has 26 view-model files, several of which
already wrap the same use cases.

**Severity: High.** Sixteen sites bypassing a layer that exists and is tested.

**Fix.** Route each through the cubit that owns that data — `StudentTagsCubit` and the guardian
cubit already exist and are tested. Where no cubit fits, add a method to the nearest one rather
than a new cubit. This pairs naturally with §5.2, since both are resolved from the same call sites.

---

### Mandate 6 — Reuse what exists; pure functions out of build()

**Verdict: Violated** (5 violations, highest High)

---

#### 6.1 — Eleven duplicate class names, matching the standard's own list

**Rule broken.** MANDATE 6: *"**No two classes in the codebase share a name.** Diff each collision
before merging — copies with the same name often have different constructors and are not
interchangeable."* PDF §6.1 tabulates *"`_Chip`, `_EmptyState`, `_DialogField`, `_DialogDropdown`,
`_SectionLabel`, `_ScheduleChip`, `_DateRow` — 3 to 4 each — Private duplicates across unrelated
features."*

**Where.** I compared all class declarations in `lib/`. Eleven collisions involve this module —
the most of any module audited:

| Name | Copies | Locations |
|---|---|---|
| `_Chip` | **3** | `student_dates_tab_card.dart:704`, `student_immunization_tab_card.dart:804`, `student_about_tab_card.dart:1116` |
| `_DialogField` | 2 | `student_dates_tab_card.dart:739`, `student_immunization_tab_card.dart:662` |
| `_DialogDropdown` | 2 | `student_dates_tab_card.dart:806`, `student_immunization_tab_card.dart:723` |
| `PhoneNumberFormatter` | 2 | `students/view/student_form_formatters.dart:6`, `staff/view/add_staff_screen_formatters.dart:3` |
| `NameCapitalizationFormatter` | 2 | same two files |
| `TrimFormatter` | 2 | same two files |
| `_ZipCodeFormatter` | 2 | `edit_student_profile_details_screen.dart:1447`, `user_profile/view/edit_user_profile_screen.dart:793` |
| `_DocumentDetailRow` | 2 | `student_documents_tab.dart:958`, `staff/widgets/staff_documents_tab.dart:877` |
| `_ScheduleChip` | 2 | `student_about_tab_card.dart:1066`, `shared/common/widgets/schedule_picker.dart:114` |
| `GuardianProfile` | 2 | `domain/features/student/entities/guardian_profile.dart:7`, `domain/features/user_profile/entities/guardian_profile.dart:10` |
| `Student` | 2 | `domain/features/student/entities/student.dart:3`, `billing/model/student_models.dart:13` |

The three `_Chip` copies are near-identical — two are the same three parameters, the third adds one
optional:

```dart
// student_dates_tab_card.dart:704 AND student_immunization_tab_card.dart:804 — identical
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.labelColor, required this.color});

// student_about_tab_card.dart:1116 — the same, plus one optional param
  const _Chip({required this.label, required this.labelColor, required this.color, this.icon});
```

**Why it violates.** The rule is absolute on names. Two collisions are the serious ones:
`GuardianProfile` is **two domain entities** with the same name in different features, and
`Student` collides between a domain entity and a billing presentation model — so "a `Student`"
means different things depending on the import. The three formatter classes duplicated with the
staff module are pure logic copied wholesale.

**Severity: High.** Eleven collisions, two of them between a domain entity and something else,
and the private duplicates are the exact set §6.1 tabulates.

**Fix.** Take them in three groups. The three `_Chip` copies collapse into one shared widget with
`icon` optional — the mandate's "extend with a parameter" case, and the diff is trivial. The three
formatters move to a shared location used by both students and staff (§3.3 already needs to
relocate that file). Rename the two domain-entity collisions: `GuardianProfile` and `Student`
should say which feature's shape they are, or be unified if they represent the same thing — diff
before deciding, as the rule requires.

---

#### 6.2 — Twenty-seven of 154 files exceed the 400-line ceiling; the largest is 2,054 and grew

**Rule broken.** MANDATE 6: *"File size ceiling: 400 lines. Split by extracting cohesive units,
not arbitrarily at line 400."* PDF §9.3 gate 11.

**Where.** 27 files over. The top:

| File | Lines | vs reference commit |
|---|---|---|
| `data/.../datasources/student_remote_datasource.dart` | **2,054** | PDF §8.2c recorded 1,985 — **grew 69 lines** |
| `presentation/.../view/student_screen.dart` | **1,888** | — |
| `data/.../repositories/student_repository_impl.dart` | **1,795** | — |
| `presentation/.../view/edit_student_profile_details_screen.dart` | 1,479 | — |
| `presentation/.../view/student_profile_screen.dart` | 1,342 | — |
| `presentation/.../view/add_student_step1_screen.dart` | 1,317 | — |
| `presentation/.../view/add_student_step2_screen.dart` | 1,178 | — |
| `presentation/.../view/student_profile_tab_cards/student_about_tab_card.dart` | 1,153 | — |
| `presentation/.../widgets/student_action_panel.dart` | 1,090 | — |
| `presentation/.../view/student_profile_screen_tabs/student_documents_tab.dart` | 997 | — |

…plus 17 more between 400 and 900.

**Why it violates.** The ceiling is 400 and the largest is 5.1× over. The datasource is the notable
case: PDF §9.4 lists the God Objects that *"regrew after May"*, and this file has grown again since
the reference commit. `student_action_panel.dart` at 1,090 lines is a **widget**.

**Severity: High.** Ten files over 990 lines, and the largest is still growing — file size is the
mechanism behind §6.1's private duplicates hiding inside 800-line tab cards.

**Fix.** Split by cohesive unit. The datasource and repository divide along the profile / guardian
/ health / physician / pickup / document axes that the `mappers/` folder already names. The add
wizard screens split at their step boundaries. Do this after §5.1 and §5.3, so the extraction works
on code that no longer calls the datasource directly.

---

#### 6.3 — A shared widget that is entirely commented out, named by the standard

**Rule broken.** MANDATE 6: *"Commented-out code is deleted, not kept. …
`remove_student_tile.dart` being commented out in full while four copies live in feature files,
[is a] direct consequence of not deleting."*

**Where.** [lib/shared/common/widgets/remove_student_tile.dart](lib/shared/common/widgets/remove_student_tile.dart)
— 68 lines, **zero** non-comment non-blank lines:

```dart
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/svg.dart';
// import '../../../core/theme/app_colors.dart';
```

**Why it violates.** The standard names this file explicitly. The good news is that the four live
copies it mentions are gone — confirmed in `attendance-kiosk-module-audit.md`, which found
`RemoveStudentTile` no longer duplicated anywhere. So the duplication was remediated and the dead
shell was left behind.

**Severity: Medium.** Dead code with no callers; harmless at runtime, but it is a file the standard
asked to be deleted and the reason for keeping it has since disappeared.

**Fix.** Delete the file. Confirm nothing imports it first — my search found only the file itself.

---

#### 6.4 — Thirty-eight `Widget _buildXxx()` methods

**Rule broken.** MANDATE 6: *"Replace `Widget _buildXxx()` methods with private
`StatelessWidget` classes in the same file. A method returning a Widget cannot be `const`, cannot
take a key, and rebuilds with its whole enclosing widget."*

**Where.** 38 methods across the module — the highest count of the five audited (Scheduling 28,
Activity 28, Classroom 12).

**Why it violates.** Each rebuilds with its whole enclosing widget, and this module's enclosing
widgets are among the largest in the codebase (1,888, 1,479, 1,342 lines) with 67 `setState` calls
driving them.

**Severity: Medium.** Mechanical, but the rebuild cost is real at these file sizes.

**Fix.** Convert each to a private `StatelessWidget` in the same file, passing what it reads as
constructor parameters. Doing this first surfaces which `State` fields each section depends on,
which directly supports §2.1 and §6.2.

---

#### 6.5 — `student_card.dart` hand-rolls expand/collapse while a general widget sits unused

**Rule broken.** MANDATE 6: *"Before writing a widget, search `core/widgets/`… If something close
exists, extend it with a parameter rather than copying it."* PDF §6.2 lists
`students/widgets/student_card.dart` (732 lines) among four cards totalling 2,268 lines that
*"hand-roll the same expand and collapse behaviour"* while
`core/common/widgets/expandable_info_card.dart` (296 lines) *"is referenced zero times outside its
own file."*

**Where.** [widgets/student_card.dart](lib/presentation/features/students/widgets/student_card.dart)
— now 707 lines, still holding its own `isExpanded` boolean and toggle (§2.1).

**Why it violates.** A general, parameterised `ExpandableInfoCard` exists with `leading`,
`titleText`, `subtitleText`, `collapsedHeight`, `headerPadding` and a typed `InfoRowItem` list —
and this card reimplements the behaviour instead.

**Severity: Medium.** One card of the four the standard names; the duplication is behavioural
rather than a name collision, and the card is covered by two widget tests
(`student_card_widget_test.dart`, `student_card_interaction_test.dart`) which lower the conversion
risk considerably.

**Fix.** Extend `ExpandableInfoCard` with whatever parameter `student_card.dart` needs that it
lacks, then have the card delegate. The two existing widget tests should pass unchanged — that is
the acceptance criterion. This also closes §2.1's `setState` for this widget, since the toggle
moves into the shared card's `ValueNotifier`.

---

### Mandate 7 — One responsive source

**Verdict: Violated** (3 violations, highest Medium)

---

#### 7.1 — Four screen-width literals, two of them the standard's own *WRONG* example

**Rule broken.** MANDATE 7: *"Breakpoints are defined once in
`lib/core/responsive/app_breakpoints.dart`. No other file contains a screen-width comparison
against a literal."* And: *"A feature `LayoutBuilder` is allowed **only** when the widget must
respond to its own box rather than the screen."*

**Where.** Four comparisons against literals:

```dart
// view/student_screen.dart:1312-1314  and again at 1366-1368
LayoutBuilder(
  builder: (context, constraints) {
    final bool isTablet = constraints.maxWidth >= 600;

// view/edit_student_important_dates_screen.dart:135
final isTablet = constraints.maxWidth > 600;
// view/student_health_tab_cards/student_physician_tab_card.dart:257
final isTablet = screenWidth > 600;
```

**Why it violates.** The first two are the PDF §7.4 *WRONG* block reproduced almost exactly — the
standard's own example reads *"LayoutBuilder(builder: (context, constraints) { final bool isTablet
= constraints.maxWidth >= 600; …"* and cites this file. Using a `LayoutBuilder` to derive a
*screen* breakpoint is precisely the misuse §7.2 forbids: the `LayoutBuilder` exemption is for
widgets responding to their own box, and a tablet/phone decision is a screen decision.
`student_physician_tab_card.dart:257` compares a `screenWidth` variable directly. Note also the
inconsistent operator — two sites use `>= 600` and two use `> 600`, so a device at exactly 600
logical pixels is a tablet on two screens and a phone on two others.

**Severity: Medium.** No live layout break was demonstrated, but the `>=`/`>` split is a real
inconsistency at the boundary, and these are the sites the standard singles out.

**Fix.** Replace all four with `context.isTablet`, which resolves from `AppBreakpoints`. The two
`LayoutBuilder`s in `student_screen.dart` should be removed entirely if their only purpose is the
breakpoint; keep them only if something else reads `constraints`.

---

#### 7.2 — Nineteen `MediaQuery.of(context)` reads and no field-scoped accessors

**Rule broken.** MANDATE 7: *"`MediaQuery.sizeOf(context)` over `MediaQuery.of(context)` — `.of`
subscribes to the whole object, so a width read re-runs on every keyboard open."*

**Where.** **19** `MediaQuery.of`, **0** `MediaQuery.sizeOf`, **0** `MediaQuery.paddingOf` — the
highest `.of` count and the only module audited with zero field-scoped reads (Attendance uses
`paddingOf` 13 times; Scheduling uses `sizeOf` 3 times).

**Why it violates.** All 19 subscribe to the whole `MediaQuery` object. This module's screens are
form-heavy — the three-step add wizard, the profile edit screen, the document and pickup forms —
so the keyboard opens constantly, and each open re-runs every one of these reads.

**Severity: Medium.** Redundant rebuilds on the module's most keyboard-intensive screens.

**Fix.** Swap each to the field-scoped accessor: `MediaQuery.sizeOf` for `.size` reads,
`MediaQuery.paddingOf` for `.padding`, `MediaQuery.viewInsetsOf` for `.viewInsets`.
Behaviour-preserving one-line changes.

---

#### 7.3 — Feature code does not read the published size class

**Rule broken.** MANDATE 7: *"Feature code reads `context.screenSize` / `context.isTablet` /
`context.responsive(compact:, medium:, expanded:)`; **it does not measure**."*

**Where.** `context.responsive` / `context.isTablet` / `context.screenSize` are used **0 times**.
Sixteen files import a responsive helper instead, and four measure directly (§7.1).

**Why it violates.** `ResponsiveScope` is mounted at [app/app.dart:82](lib/app/app.dart#L82) and
the extension API exists at
[responsive_scope.dart:49-74](lib/core/responsive/responsive_scope.dart#L49-L74), so the
destination is available and unused. The scheduling module demonstrates the target state with 12
uses.

**Severity: Medium.** No layout inconsistency where the helper is used — it delegates to
`AppBreakpoints` — but the four direct measurements in §7.1 sit outside that guarantee.

**Fix.** Convert the four direct measurements first (§7.1), then adopt `context.responsive(...)`
per call site. The broader helper migration is app-wide work (116 importers) that this module
should follow rather than lead.

---

### Mandate 8 — Models everywhere, generated, never raw maps

**Verdict: Partially violated** (3 violations, highest High)

Measured — **the most advanced Mandate 8 state in the codebase**:

| Check | Count | Status |
|---|---|---|
| `@JsonSerializable()` classes | **6** | best in repo |
| `.g.dart` files committed | **3** | best in repo |
| `mappers/` folder | **13 files** | best in repo |
| `Map<String, dynamic>` in `lib/domain/features/student` **(code)** | **0** | Compliant |
| Generator-delegating `fromJson` factories | 6 | Compliant |
| Genuinely hand-written `fromJson` parsers | 8 | Violated |
| Hand-written `toJson` methods | 8 | Violated |
| Datasource methods returning raw `Map` | **14** | Violated |
| `Map<String, dynamic>` in presentation | 37 | Violated |

**What is compliant.** Three model files carry `@JsonSerializable` with committed `.g.dart` output
and six factories that correctly delegate:

```dart
// models/student_models.dart:403-404
factory StudentPhysicalExamModel.fromJson(Map<String, dynamic> json) =>
    _$StudentPhysicalExamModelFromJson(json);
// models/student_models.dart:369-371
factory StudentHealthModel.fromJson(Map<String, dynamic>? json) => json == null
    ? const StudentHealthModel()
    : _$StudentHealthModelFromJson(json);
```

The domain layer is clean: its only five `Map<String, dynamic>` mentions are **doc comments**
describing what typed request entities replaced —
`update_student_profile_request.dart:4`, `student_health_update_request.dart:5`,
`update_student_address_request.dart:4`, `student_regular_schedule_input.dart:4`,
`update_guardian_request.dart:4`. Zero in code. And the 13 mappers carry **12 dedicated tests**.

---

#### 8.1 — Fourteen datasource methods return raw `Map<String, dynamic>`

**Rule broken.** MANDATE 8: *"Datasources call `Model.fromJson(response)` and return the model.
They do not read keys off a map."* And: *"No `Map<String, dynamic>` in `lib/domain` or
`lib/presentation`. Maps stop at the datasource."*

**Where.** 14 methods in
[student_remote_datasource.dart](lib/data/features/student/datasources/student_remote_datasource.dart):

```dart
// :235, :1328
Future<List<Map<String, dynamic>>> getStudentGuardians({ … });
// :243, :1359
Future<List<Map<String, dynamic>>> getGuardiansBySchool({ … });
// :251
Future<Map<String, dynamic>> getGuardianProfile({ … });
// :270
Future<List<Map<String, dynamic>>> getGuardianChildren({ … });
// :308, :1229
Future<List<Map<String, dynamic>>> getTagsBySchool({ … });
// :316
Future<List<Map<String, dynamic>>> getStudentTags({ … });
// :330
Future<List<Map<String, dynamic>>> getStudentRegularSchedules({ … });
```

**Why it violates.** These are the guardian, tag and schedule read paths — and mappers already
exist for several of the same shapes (`student_guardian_mapper.dart`,
`guardian_profile_mapper.dart`, `school_guardian_summary_mapper.dart`), so the models those
mappers map *from* are the missing piece. The untyped return is what feeds §8.3's 37
presentation-layer maps.

**Severity: High.** Fourteen methods on live read paths returning shapes the compiler cannot
check, in the module's 2,054-line datasource.

**Fix.** Give each a response model with generated serialisation, and return it — the three
existing `@JsonSerializable` files are the in-repo template and the matching mappers already exist.
Start with the guardian trio, since `guardian_profile_mapper_test.dart` and
`student_guardian_mapper_test.dart` already pin the entity shape.

---

#### 8.2 — Eight hand-written parsers and eight hand-written `toJson` methods alongside the generated ones

**Rule broken.** MANDATE 8: *"Models are annotated `@JsonSerializable()` with generated
`fromJson`/`toJson` via `part 'x.g.dart'`. **No hand-written serialisation.**"*

**Where.** Separating generator delegations from real parsers:

| File | Generated | Hand-written |
|---|---|---|
| `student_models.dart` | 4 (`StudentImportantDatesModel`, `StudentHealthModel`, `StudentPhysicalExamModel`, `StudentImmunizationModel`) | 4 (`StudentListItemModel:76`, `StudentPageModel:267`, `StudentGuardianModel:514`, `StudentProfileModel:668`) |
| `student_document_models.dart` | 1 | 2 (`StudentDocumentItemModel:123`, `StudentDocumentsPageModel:192`) |
| `student_physician_models.dart` | 1 | 0 |
| `student_pickup_models.dart` | 0 | 1 |
| `vaccine_model.dart` | 0 | 1 |

Of 12 `toJson` methods, 4 delegate to the generator and 8 are hand-written.

```dart
// models/student_models.dart:76-78 — hand-written, in the same file as four generated models
factory StudentListItemModel.fromJson(Map<String, dynamic> json) {
  final classroomRaw = json['classroom'];
  String classroomCodeOrName = '';
```

**Why it violates.** The rule is "no hand-written serialisation", and `student_models.dart`
contains both conventions — four generated models and four hand-written parsers in one file. This
is a genuinely half-finished migration rather than an unstarted one, which is the right direction
but leaves the file ambiguous about which pattern a new model should follow.

**Severity: Medium.** No live defect found, and the module's 16 data-layer tests cover much of
this — but a half-converted file invites the next model to pick the wrong half.

**Fix.** Finish the conversion, model by model, using the four already generated in the same file
as the template. The mandate requires a characterisation test before deleting any parser;
`student_guardian_model_test.dart` shows the shape, and most of these models already have mapper
tests that pin the downstream entity. `StudentPageModel` reads a nested `data.content` envelope
and will need `@JsonKey(readValue:)`.

---

#### 8.3 — Thirty-seven `Map<String, dynamic>` references in the presentation layer

**Rule broken.** MANDATE 8: *"No `Map<String, dynamic>` in `lib/domain` or `lib/presentation` —
not as a parameter, not as a return type, not as a field."* PDF §8.3 sets the expected count for
`lib/presentation` at **zero**.

**Where.** 37 references across the module: `student_action_panel.dart` 7,
`student_about_tab_card.dart` 6, `student_screen.dart` 5, `add_student_step1_screen.dart` 5,
`student_profile_tab.dart` 3, `student_immunization_tab_card.dart` 2,
`student_dates_tab_card.dart` 2, `edit_student_profile_details_screen.dart` 2, and more.

**Why it violates.** The target for this layer is zero. These are the downstream consequence of
§8.1 — the untyped guardian, tag and schedule shapes the datasource returns travel up through the
repository into the widgets that render them.

**Severity: Medium.** Thirty-seven sites — well below Activity's 159, above Attendance's 5 and
Classroom's 10.

**Fix.** Most close as a side effect of §8.1: once the datasource returns models and the existing
mappers produce entities, the maps stop reaching presentation. Audit the remainder individually —
each is either a wire shape (→ model) or an untyped argument bag (→ a typed class in `model/`).

---

## 4. Remediation order

Sequenced so each step is a single isolated change that preserves existing behaviour, and so no
step has to be redone by a later one. The ordering follows `docs/mandate-rules.md`'s revised
sequence (**1 → 5 → 2 → 3 → 6 → 4 → 7 → 8**) adapted to this module.

**Before anything:** capture the baseline the guardrails require — `flutter analyze` on the three
module directories and `flutter test` on the **86** test files covering it. Unlike Classroom and
Scheduling, this module has a real safety net; the analyzer count must not increase and no passing
test may fail.

### Phase A — close the Critical finding (highest value, and the tests already exist)

| # | Change | Fixes | Why here |
|---|---|---|---|
| 1 | Route the four `StudentRemoteDataSource` **reads** through `StudentProfileCubit` / `GetStudentProfileUseCase` | §5.1 (part) | **The standard's flagship violation.** Both cubit and use case exist and are tested (`student_profile_cubit_test.dart`, `get_student_profile_usecase_test.dart`). Compare network call counts before/after. |
| 2 | Route the `updateStudentRegularSchedules` **write** through `StudentScheduleCubit` | §5.1 (part) | A view mutating data through the datasource. Covered by `update_student_regular_schedules_usecase_test.dart` and `student_schedule_cubit_test.dart`. |
| 3 | Move the cache write in `student_profile_tab.dart:181-184` into the repository | §5.1 (rest) | Removes the second caching policy the view owns. |
| 4 | Convert the three `FutureBuilder` views to `BlocBuilder`; then delete the "thin Future-based read" methods from all six cubits | §5.3 | Do the deletion in the same change, or the dual API will be re-adopted. Cubit tests already cover the state path. |

### Phase B — navigation and the rest of layer discipline

| # | Change | Fixes | Why here |
|---|---|---|---|
| 5 | Add a `StudentRoutes` block to `app_routes.dart` for the 14 inline paths | §1.2 | Prerequisite for every push conversion. |
| 6 | Convert the four cross-feature pushes in `student_screen.dart` to `context.push` with typed args | §1.1 (part) | Targets attendance routes that already exist. Scheduling's `AddShiftRouteArgs` is the template. |
| 7 | Convert the remaining four `MaterialPageRoute` sites | §1.1 (rest) | Mechanical once 5–6 establish the pattern. |
| 8 | Audit the 41 `Navigator.pop` sites; convert screen-route pops to `context.pop`, leave modal dismissals | §1.3 | Preserve each result value. |
| 9 | Route the 16 direct use-case resolutions through their cubits | §5.4 | Same call sites as step 10, so do them adjacently. |
| 10 | Move cubit creation into `GoRoute` builders; replace `StorageService`/`ApiClient` in views with injected services | §5.2 | Depends on 5–8. **Check §5.4**: verify no double-loading. |

### Phase C — structure

| # | Change | Fixes | Why here |
|---|---|---|---|
| 11 | Place `module_access.dart` per PDF §3.3 — domain if a rule, `view_model/` if UI gating | §3.1 (part) | Named by the standard; read it first to decide. |
| 12 | Move `profile_photo_background.dart` out of `utils/`; delete the folder | §3.2 | Its `serviceLocator` calls move with it (resolved by step 10). |
| 13 | Move the 11 card/tab widgets from `view/**` into `widgets/`; move `student_form_formatters.dart` to a shared location | §3.3 | Coordinate the formatters move with step 16, which de-duplicates them. |
| 14 | Codemod relative → `package:` imports | §3.5 | After 11–13 have moved files. |

### Phase D — reuse

| # | Change | Fixes | Why here |
|---|---|---|---|
| 15 | Collapse the three `_Chip` copies into one shared widget with `icon` optional | §6.1 (part) | Two are already identical; the diff is trivial. |
| 16 | De-duplicate the three formatters shared with the staff module; resolve `_DialogField`, `_DialogDropdown`, `_ZipCodeFormatter`, `_DocumentDetailRow`, `_ScheduleChip` | §6.1 (part) | Follows 13's move. |
| 17 | Rename or unify the `GuardianProfile` and `Student` domain collisions | §6.1 (rest) | **Diff before merging** — two domain entities sharing a name is the highest-risk pair. |
| 18 | Delete `remove_student_tile.dart` | §6.3 | Zero live lines, no importers. Standalone. |
| 19 | Convert `student_card.dart` to extend `ExpandableInfoCard` | §6.5, §2.1 (part) | Its two widget tests are the acceptance criterion. |
| 20 | Convert the 38 `Widget _buildXxx()` to private `StatelessWidget` classes | §6.4 | Surfaces the seams for step 21. |
| 21 | Split the 27 files over 400 lines — the 2,054-line datasource first | §6.2 | After Phase A, so the extraction works on code no longer called from views. |

### Phase E — state

| # | Change | Fixes | Why here |
|---|---|---|---|
| 22 | Move the remaining Bucket A `setState` state into the existing cubits | §2.1 (rest) | **Flag the behaviour change the mandate warns about**: selections may now persist across navigation where they previously reset. |
| 23 | Convert Bucket B toggles to `ValueNotifier` + `ValueListenableBuilder` **with** `child:` | §2.2 | Falls out of 22. Scheduling's `day_classroom_section.dart` is the nearest reference. |
| 24 | Apply `BlocSelector` where one small widget reads one property | §2.3 | Opportunistic, within 22. |

### Phase F — theming and responsiveness

| # | Change | Fixes | Why here |
|---|---|---|---|
| 25 | Add named `AppTextStyles` entries; replace the 146 inline `TextStyle(` constructors | §4.1 | **After Phase D** — per "Move 6 before 4", doing this earlier would tokenise three `_Chip` copies step 15 collapses. |
| 26 | Delete the 116 Manrope `fontFamily:` lines; **keep the `Fonts.inter` one** | §4.2 | Mostly removed as a side effect of 25. |
| 27 | Tokenise the 14 residual colour references | §4.4 | Short sweep; finishes the colour half. |
| 28 | Replace the four width literals with `context.isTablet`; remove the two breakpoint-only `LayoutBuilder`s | §7.1, §7.3 (part) | Fixes the `>=`/`>` boundary inconsistency at the same time. |
| 29 | Swap the 19 `MediaQuery.of` reads for `sizeOf`/`paddingOf`/`viewInsetsOf` | §7.2 | One line each. |
| 30 | Decide the `AppStrings` vs feature-`*Strings` convention app-wide | §4.3 | Blocked on an Open Question. **Do not migrate this module in isolation.** |

### Phase G — models

| # | Change | Fixes | Why here |
|---|---|---|---|
| 31 | Give the guardian trio response models; return models not maps | §8.1 (part) | Mappers and mapper tests already exist for these shapes. |
| 32 | Give the tag and schedule methods response models | §8.1 (rest) | Follows 31's pattern. |
| 33 | Convert the eight hand-written parsers and eight `toJson` methods to `@JsonSerializable()` | §8.2 | Characterisation test first per the mandate; four generated models in the same file are the template. `StudentPageModel` needs `@JsonKey(readValue:)` for its `data.content` envelope. |
| 34 | Type or eliminate the remaining presentation maps | §8.3 | **Last.** Most close as a side effect of 31–33. |

---

## 5. Open questions

Points where the standard does not clearly settle the case. I have reported the finding and flagged
the ambiguity rather than guessing.

1. **Which source wins.** The brief says `docs/mandate-rules.md` takes precedence; that file's own
   preamble says the PDF wins. I followed the brief. It changed no verdict — the two agree on all
   eight rules — but it decides execution order, and my remediation order follows mandate-rules.md.
   **One of the two documents should be corrected**; this is now the fifth audit to raise it.

2. **`AppStrings` or feature-local `*Strings`?** §4.3. Mandate 4 names `AppStrings`
   (`lib/core/constants/app_strings.dart`). Three features — students, billing, reports — instead
   use feature-local classes, and `StudentStrings` alone has 367 entries against `AppStrings`' 58
   in total. The feature-local convention is documented in-code and more thoroughly adopted. One
   app-wide decision is needed; migrating this module alone would move 367 entries for no
   functional gain. **This is the direct analogue of the `AppSizes` vs `AppSpacing` question raised
   in the attendance, classroom and scheduling audits** — the two should probably be decided
   together, since both are "the mandate names one container, the codebase adopted another".

3. **Are the six cubits' dual Future/state APIs a sanctioned migration step?** §5.3. Six cubits
   expose both a state-based `load()` and a *"thin Future-based read for callers that drive their
   own `FutureBuilder`"*, documented as deliberate. The mandate forbids the `FutureBuilder`, but
   says nothing about a transitional dual API. If such transitional APIs are acceptable, the
   standard should say so and require a removal date; if not, the deletion should be part of the
   same change as the view conversion (which is how I sequenced it).

4. **Does the `LayoutBuilder` exemption cover deriving a screen breakpoint?** §7.1. Mandate 7
   allows a feature `LayoutBuilder` *"only when the widget must respond to its own box rather than
   the screen"*. `student_screen.dart:1312` uses one to compute `constraints.maxWidth >= 600` —
   which is a screen decision made through a box-shaped API. I graded it as a violation because
   §7.4 shows this exact code as the *WRONG* block. Worth stating explicitly, since a
   `LayoutBuilder` whose constraints happen to equal the screen width is easy to defend as
   "responding to its own box".

5. **`>= 600` or `> 600`?** §7.1. The module uses both operators for the same breakpoint, so a
   device at exactly 600 logical pixels resolves differently on different screens.
   `AppBreakpoints.classify` uses `width < compactMaxWidth` (i.e. 600 is medium/tablet), so `>= 600`
   matches and `> 600` does not. Not a rule ambiguity so much as a repo inconsistency the rule
   would resolve — worth confirming the intended boundary when converting.

6. **Which `Student` and which `GuardianProfile`?** §6.1. Two domain entities named
   `GuardianProfile` exist in different features, and `Student` collides between a domain entity
   and a billing presentation model. The rule says no two classes share a name and to diff before
   merging, but does not say whether two features may legitimately model the same real-world
   concept differently. That decision has to be made by someone who knows whether a billing
   `Student` and a domain `Student` are the same thing.

7. **Does the module boundary include `student_classroom`?** `lib/data/features/student_classroom/`
   and `lib/domain/features/student_classroom/` are separate feature directories consumed mainly by
   the classroom module's assign flow. I excluded them, as the classroom audit did. The standard
   organises strictly by feature and does not describe a feature whose domain is split across two
   names.

8. **Nothing currently enforces any of this.** `analysis_options.yaml` still has every lint line
   commented out, including `include: package:flutter_lints/flutter.yaml`; only an
   `analyzer: exclude: third_party/**` block is active. That is PDF §9.1, unchanged. Outside this
   module's scope, but it is why the §5.2a violation could spread from one file to five after
   being named in two successive audits.

---

## 6. Method and limits

- All 154 in-scope files were read in full. Cross-cutting counts (`setState`, `serviceLocator`,
  `Map<String, dynamic>`, `Colors.*`, `Color(0x`, `TextStyle(`, `fontFamily`, `fromJson`, `toJson`,
  imports, class declarations, `MediaQuery` variants) were produced by exhaustive grep over the
  three module directories and then verified by reading the matched sites in context. Every quoted
  snippet was read before quoting.
- Every file path and line number was checked against the working tree at `cdb6b86e` on
  `develop-refactor`. Nothing is inferred from a filename.
- Comparisons against the reference commit come from the PDF's own tables (§1.1, §2.3, §3.3, §5.1,
  §5.2a, §6.1, §6.2, §7.1, §8.2c), each of which names this module by path; I re-measured every one
  at the audited commit rather than assuming the recorded figure still held.
- Duplicate class names were found by extracting all public and private class declarations in
  `lib/` (excluding `.g.dart`) and diffing against this module's 206 public classes.
- Every relative import in the module was resolved programmatically against the filesystem to test
  for the §3.4 excess-`..` hazard. All resolve; none is broken.
- **Two measurements were corrected during this audit before publication.** A first pass counted 5
  `Map<String, dynamic>` occurrences in the domain layer; reading each line showed **all five are
  doc comments** describing what typed request entities replaced, so the domain count in code is
  **zero** and Mandate 3's domain-purity check passes. Separately, a first pass counted 14
  "hand-written `fromJson`" factories; parsing each factory body showed **6 delegate to the
  generator** (`_$…FromJson`) and are compliant, leaving **8** genuinely hand-written — which is
  why Mandate 8 is graded Partially violated rather than Violated.
- Test coverage was counted as files under `test/data/features/student`,
  `test/domain/features/student` and `test/presentation/features/students` (16 + 48 + 22 = 86).
  Files elsewhere that merely mention "student" — attendance forms, reports — were excluded.
- I did not run `flutter analyze` or `flutter test` as part of this audit; the baseline capture is
  listed as the first remediation step rather than claimed as done.
- The four existing audits in this folder were used only for cross-module comparison and heading
  parity. Every finding here was derived from the students code.
- No files were modified.
