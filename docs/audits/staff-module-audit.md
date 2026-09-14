# Staff Module — Eight Mandates Compliance Audit

| | |
|---|---|
| **Module** | Staff |
| **Paths** | `lib/presentation/features/staff/`, `lib/data/features/staff/`, `lib/domain/features/staff/` |
| **Commit audited** | `cdb6b86e251c87c14718cf1054344e480f8f091f` (`cdb6b86e`), branch `develop-refactor` |
| **Date** | 2026-09-09 |
| **Scope size** | 100 files, 22,940 lines |
| **Standard** | `WowCare2-Engineering-Standards-Eight-Mandates 1.pdf` + `docs/mandate-rules.md` |
| **Nature** | Audit only. No code was changed. |

> **A note on inputs.** The task template arrived with `MODULE_NAME` and `MODULE_PATH` as
> unfilled placeholders. I resolved them from the prose instruction ("the Staff module") and
> verified all three directories exist before auditing. No path was invented.
>
> **Precedence note.** The brief says `docs/mandate-rules.md` wins where the two sources differ.
> `docs/mandate-rules.md` itself says the PDF wins. I followed the brief and flagged the conflict
> in **Open questions**, as in the five prior audits. The two agree on all eight rules; they
> differ in emphasis, in recommended execution order, and — materially for §5 below — in how
> broadly the forbidden-types rule is scoped.

**Severity definitions** (identical to the five existing audits in this folder):
**Critical** — a live defect or a security/correctness hazard reachable in production.
**High** — a rule broken in a way that will cause divergence or defects as the code changes.
**Medium** — a real rule breach with contained blast radius.
**Low** — cosmetic, mechanical, or already mitigated in practice.

---

## 0. Scope — the exact file set audited

**100 files, 22,940 lines.** Every file below was read in full.

### `lib/data/features/staff/` — 10 files (4,145 lines)

| Folder | Files |
|---|---|
| `datasources/` (1) | `staff_remote_datasource.dart` (1,231) |
| `mappers/` (1) | `staff_shift_mapper.dart` (86) |
| `models/` (6) | `staff_models.dart` (735), `staff_document_models.dart` (250), `school_user_models.dart` (172), `staff_important_dates_models.dart` (127), `staff_shift_models.dart` (100), `school_regular_schedule_models.dart` (72), `staff_count_models.dart` (63) |
| `repositories/` (1) | `staff_repository_impl.dart` (1,309) |

### `lib/domain/features/staff/` — 46 files

| Folder | Files |
|---|---|
| `entities/` (14) | `create_school_user_result.dart`, `school_regular_schedule_day.dart`, `school_user.dart`, `staff_address_update.dart`, `staff_count.dart`, `staff_document.dart`, `staff_documents_page.dart`, `staff_important_date.dart`, `staff_member.dart` (also declares `StaffPage`), `staff_my_profile_update.dart`, `staff_profile.dart`, `staff_profile_update.dart`, `staff_schedule_entry.dart`, `staff_shift.dart` |
| `repositories/` (1) | `staff_repository.dart` (302) |
| `usecases/` (31) | `create_school_user_usecase.dart` (74), `get_staff_page_usecase.dart`, `load_cached_staff_page_usecase.dart`, `invalidate_cached_staff_page_usecase.dart`, `get_all_staff_usecase.dart`, `get_staff_count_usecase.dart`, `get_staff_profile_usecase.dart`, `load_cached_staff_profile_usecase.dart`, `update_staff_profile_usecase.dart`, `update_staff_address_usecase.dart`, `update_staff_schedules_usecase.dart`, `update_staff_primary_classroom_usecase.dart`, `update_staff_allowed_classrooms_usecase.dart`, `get_important_dates_usecase.dart`, `load_cached_important_dates_usecase.dart`, `update_important_dates_usecase.dart`, `get_staff_documents_usecase.dart`, `load_cached_staff_documents_usecase.dart`, `add_staff_document_usecase.dart`, `delete_staff_document_usecase.dart`, `get_school_regular_schedules_usecase.dart`, `activate_school_user_usecase.dart`, `deactivate_school_user_usecase.dart`, `activate_organization_admin_usecase.dart`, `deactivate_organization_admin_usecase.dart`, `delete_school_user_usecase.dart`, `change_user_email_usecase.dart`, `get_staff_code_for_user_usecase.dart`, and 3 more |

### `lib/presentation/features/staff/` — 44 files

| Folder | Files |
|---|---|
| `model/` (5) | `staff_route_args.dart` (192), `staff_route_results.dart` (97), `staff_filter_data.dart` (58), `schedule_entry.dart` (18), `staff_attendance_action.dart` (17) |
| `view/` (10) | `edit_profile_details_screen.dart` (1,838), `staff_screen.dart` (1,601), `add_staff_screen.dart` (1,296), `edit_schedule_screen.dart` (854), `staff_profile_screen.dart` (822), `add_document_screen.dart` (709), `edit_important_dates_screen.dart` (655), `staff_filter_screen.dart` (533), `add_staff_screen_formatters.dart`, `staff_document_viewer_screen.dart` |
| `view_model/` (18) | `staff_cubit.dart` (638), `staff_state.dart`, `staff_profile_cubit.dart`, `staff_profile_edit_cubit.dart`, `staff_profile_edit_state.dart`, `staff_schedule_cubit.dart`, `staff_schedule_state.dart`, `staff_document_cubit.dart`, `staff_document_state.dart`, `staff_document_upload_cubit.dart`, `staff_documents_list_cubit.dart`, `staff_profile_photo_upload_cubit.dart`, `staff_classroom_name_cubit.dart`, `staff_attendance_summary_cubit.dart`, `staff_attendance_action_targets_cubit.dart`, `important_dates_cubit.dart`, `create_school_user_cubit.dart`, `create_school_user_state.dart` |
| `widgets/` (11) | `staff_documents_tab.dart` (916), `staff_dates_tab.dart` (889), `staff_profile_tab.dart` (880), `staff_card.dart` (850), `staff_list_item.dart` (123), `staff_action_panel.dart`, `staff_profile_tab_widgets.dart`, and 4 more |

### Also examined (module code outside MODULE_PATH, and shared code the module reaches into)

`lib/core/utils/staff_code_resolver.dart` · `lib/core/utils/newsletter_staff_scope.dart` ·
`lib/shared/services/image_upload/staff_photo_background_upload_service.dart` ·
`lib/shared/common/widgets/post_add_staff_bottom_sheet.dart` ·
`lib/shared/common/widgets/profile_info_card.dart` ·
`lib/presentation/features/classroom/forms/assign_staff_to_classroom_form.dart` ·
`lib/presentation/features/students/view/student_form_formatters.dart` ·
`lib/presentation/features/students/view/student_profile_screen_tabs/student_documents_tab.dart` ·
`lib/core/router/app_routes.dart` · `lib/src/app_router.dart` · `lib/app/di/di.dart` ·
`lib/core/theme/*` · `lib/core/constants/app_strings.dart` · `lib/core/responsive/*` ·
`pubspec.yaml` · `analysis_options.yaml` · 17 test files under `test/`

**Adjacent features excluded from the counts.** `lib/data/features/staff_classroom/` (3 files) and
`lib/domain/features/staff_classroom/` (5) are separate feature directories under the standard's
structure, consumed by the classroom assign flow. `lib/domain/features/staff_scheduling/` contains
**no Dart files at all** — only two `.DS_Store` files (see §3.2). Named here so the boundary is
explicit.

---

## 1. Summary table

| # | Mandate | Verdict | Violations | Highest severity |
|---|---|---|---|---|
| 1 | Navigation — GoRouter everywhere | **Partially violated** | 2 | Medium |
| 2 | State — setState scarcely | **Partially violated** | 3 | High |
| 3 | Folder structure | **Partially violated** | 3 | Low |
| 4 | Centralized theming / constants | **Violated** | 5 | High |
| 5 | Presentation talks to cubits only | **Partially violated** | 2 | Medium |
| 6 | Reuse; pure functions out of build() | **Violated** | 3 | High |
| 7 | One responsive source | **Violated** | 3 | Medium |
| 8 | Models everywhere, never raw maps | **Violated** | 5 | High |
| | **Total** | | **26** | |

No mandate is Not Applicable — all eight bear on this module.

---

## 2. Overall risk assessment

Staff is the best-architected module of the six audited, and it is the clearest evidence in the
repo that the mandates are achievable. Every item the standard names for this module on
navigation and state has been fixed: `staff_screen.dart` had **9 raw pushes and 16
`serviceLocator` calls** at the reference commit and now has **zero of each**; `staff_card.dart`
— the PDF's §2.3 worked example of a card made stateful for one boolean — has been converted to
the exact `ValueNotifier` + `ValueListenableBuilder` + `dispose()` pattern the standard prescribes,
with a doc comment citing the mandate. `StaffListItem`, which §6.1 recorded at **six** copies, is
down to two. The module has the only fully canonical presentation layout in the repo (`model/`,
`view/`, `view_model/`, `widgets/` and nothing else), a pure domain layer, typed route arguments
**and** typed route results — the only module with the latter — and cubits that inject roughly 35
distinct use cases and not one repository. Its `serviceLocator` count is **2**, against 81 in
Students and 60 in Attendance.

What has not moved is everything below the architecture line. Theming is the weakest result of
the six: **102 inline `TextStyle(` constructors against 13 `AppTextStyles` uses**, **69
`fontFamily:` lines** the rule says to delete outright, and — uniquely among the six modules —
**zero** spacing tokens and **zero** string centralisation of any kind, neither `AppStrings` nor a
feature-local class. Mandate 8 is barely started: no `@JsonSerializable`, no `.g.dart`, 20
hand-written `fromJson` and 14 hand-written `toJson`, and **109** restatements of the defaulting
idioms the standard says collapse into annotations. Two patterns the PDF counts app-wide appear
together in a single factory at `staff_models.dart:319` — a `fromJson` taking `dynamic` (one of
only two in the codebase) wrapping a private parse closure.

The practical risk is contained rather than acute. There is no Critical finding: no view touches a
datasource, no `Dio` is constructed in presentation, no `FutureBuilder` competes with a cubit, and
the layer boundary holds in both directions. The real exposure is the 1,231-line datasource and
735-line model file where every field is parsed by hand with 82 separate `as String? ?? ''`
decisions — the mechanism behind the `signedInBy` defect the standard documents — and the six
`routeName` constants that are now dead, four of which declare paths that disagree with what the
router actually registers, waiting for a developer to use one.

---

## 3. Findings by mandate

### Mandate 1 — Navigation: GoRouter everywhere, MaterialPageRoute nowhere

**Verdict: Partially violated** (2 violations, highest Medium)

**What is compliant — and this is the strongest navigation result of the six.** Exhaustive grep
across all 44 presentation files:

| Check | Count |
|---|---|
| `MaterialPageRoute` | **0** |
| `Navigator.push` / `.of(context).push` | **0** |
| `context.push` / `.go` / `.pop` | 17 |

PDF §1.1 records `presentation/features/staff/view/staff_screen.dart` at **9 raw pushes**; it now
has **zero**. `app_routes.dart` declares a documented `StaffRoutes` class
([app_routes.dart:96-140](lib/core/router/app_routes.dart#L96-L140)) with both relative segments
and absolute locations, referenced **23 times** including from attendance. The router registers
its routes by those constants only
([app_router.dart:1666-1918](lib/src/app_router.dart#L1666-L1918)).

Route arguments are typed in
[model/staff_route_args.dart](lib/presentation/features/staff/model/staff_route_args.dart) (192
lines), and — uniquely in this codebase — **route results are typed too**, in
[model/staff_route_results.dart](lib/presentation/features/staff/model/staff_route_results.dart):

```dart
/// These replace the untyped `Map<String, dynamic>` each screen used to
/// `Navigator.pop`, which the caller then had to probe key by key
/// (`result is Map && result['showPostAddPrompt'] == true`) — a shape no
/// compiler was checking on either side.
class AddStaffResult {
```

`model/staff_attendance_action.dart` likewise replaces string-branching with an enum, documented
as fixing a typo that *"silently fell through to the mark-absent branch"*.

---

#### 1.1 — Six dead `routeName` constants, four of which contradict the registered route

**Rule broken.** MANDATE 1: *"Route paths and names live as constants in
`lib/core/router/app_routes.dart`."* And the guardrail against two competing definitions of one
path — *"Do not create compatibility duplicate folders to avoid updating imports. One canonical
implementation"* (MANDATE 3), applied to route addressing.

**Where.** Eight screens still declare their own `routeName`. I checked each against what the
router registers and against every reference in `lib/`:

| Screen | Declared `routeName` | Router registers | Refs | Verdict |
|---|---|---|---|---|
| `staff_filter_screen.dart:36` | `/staff-filter` | `/dashboard/staff-filter-screen` | **0** | **dead + wrong** |
| `add_document_screen.dart:38` | `/add-document-screen` | `/dashboard/add-document-screen` | **0** | **dead + wrong** |
| `edit_schedule_screen.dart:23` | `/edit-schedule-screen` | `/dashboard/edit-schedule-screen` | **0** | **dead + wrong** |
| `add_staff_screen.dart:37` | `/add-staff-screen` | `/dashboard/add-staff-screen` | **0** | **dead + wrong** |
| `edit_profile_details_screen.dart:54` | `/dashboard/edit-profile-details-screen` | same | **0** | dead |
| `edit_important_dates_screen.dart:32` | `/dashboard/edit-important-dates-screen` | same | **0** | dead |
| `staff_screen.dart:55` | `/dashboard/staff` | same | 3 | live, agrees |
| `staff_profile_screen.dart:25` | `/dashboard/staff-profile` | same | 5 | live, agrees |

```dart
// view/staff_filter_screen.dart:36 — unreferenced, and not the path the router serves
static const String routeName = '/staff-filter';
// vs app_routes.dart: StaffRoutes.filter == '/dashboard/staff-filter-screen'
```

**Why it violates.** The mandate wants one file to be the list of route paths. Here two
declarations coexist, and for four screens they **disagree**. The four stale constants are
currently harmless only because nothing references them — but they are exactly the thing a
developer reaches for when adding a `context.push`, and using one would route to a path the
router does not serve. This is the residue of a migration that added `StaffRoutes` correctly
without removing what it replaced.

**Severity: Medium.** No live defect — all six are unreferenced. The hazard is latent and
specific: four constants that look authoritative and are wrong.

**Fix.** Delete the six unreferenced `routeName` constants. For the two that are live and agree
(`StaffScreen`, `StaffProfileScreen`), either repoint their 8 references at `StaffRoutes.list` /
`StaffRoutes.profile` and delete them too, or keep them as documented aliases — `StaffRoutes`
already annotates them (*"Matches `StaffScreen.routeName`"*), so the alias is deliberate; pick one
direction and make it consistent.

---

#### 1.2 — Screen-route pops go through `Navigator` on most sites

**Rule broken.** MANDATE 1: *"Every navigation goes through GoRouter: `context.push(...)`,
`context.go(...)`, `context.pop()`."*

**Where.** **18** `Navigator.pop` calls against **7** `context.pop` — the module uses both
conventions, sometimes within the same flow. A subset of the 18 are exempt modal and bottom-sheet
dismissals; the remainder close screens and, given `staff_route_results.dart` exists, several
return a typed result.

**Why it violates.** The mandate names `context.pop()` as the way. The notable point is
inconsistency rather than absence — the module already knows the right call and uses it 7 times.

**Severity: Medium.** No guard runs on pop today, so no live gap; the cost is that the module will
not inherit a future pop-time guard, and a reader cannot tell which convention is intended.

**Fix.** Audit the 18 sites, separating modal dismissals (which stay, per the mandate's explicit
exemption) from screen-route pops (which become `context.pop`). The typed result classes make this
low-risk — each pop's payload is already a declared type, so the conversion is checked by the
compiler.

---

### Mandate 2 — State: setState scarcely, ValueNotifier for UI micro-state

**Verdict: Partially violated** (3 violations, highest High)

Measured: **84 `setState` calls across 13 files**; **13** `StatefulWidget` vs **24**
`StatelessWidget` — the best ratio of the six; **5** `ValueNotifier` and **5**
`ValueListenableBuilder` — the highest Bucket B adoption in the repo; 15 `BlocBuilder`; **0**
`BlocSelector`.

**What is compliant.** The PDF's §2.3 worked example for this module has been fixed. It records
`presentation/features/staff/widgets/staff_card.dart:216` as a `setState` toggle; the file now
reads:

```dart
// widgets/staff_card.dart:82-92
/// UI-only expand/collapse toggle. A [ValueNotifier] instead of `setState`
/// so toggling only rebuilds the subtree that reads it, not the whole
/// State object (Mandate 2 — see docs/eight-mandates §2.3).
late final ValueNotifier<bool> _isExpanded = ValueNotifier<bool>(
  widget.initiallyExpanded,
);

@override
void dispose() {
  _isExpanded.dispose();
  super.dispose();
}
```

That is the mandate's Bucket B remedy applied correctly, including disposal, with the rule cited.
Four more `ValueNotifier`s follow the same pattern for submit flags and panel selection. The
`view_model/` folder holds 18 files — 9 cubit/state pairs — and 12 of the module's 17 tests cover
them.

---

#### 2.1 — Bucket A state held in widget `State` across the six largest screens

**Rule broken.** MANDATE 2, Bucket A: *"API results, loading flags, filters, form submission,
selections that outlive the widget → Cubit."* And: *"Bucket A is 'no exceptions' — if it survives
a parent rebuild, is read by more than one widget, or comes from an API, it is Cubit state."*

**Where.** 84 `setState` calls, concentrated in the screens:

| File | Lines | `setState` |
|---|---|---|
| `view/staff_screen.dart` | 1,601 | 14 |
| `view/add_staff_screen.dart` | 1,296 | 14 |
| `view/edit_profile_details_screen.dart` | 1,838 | 12 |
| `view/staff_profile_screen.dart` | 822 | 11 |
| `view/edit_schedule_screen.dart` | 854 | 10 |
| `view/edit_important_dates_screen.dart` | 655 | 5 |
| `widgets/staff_dates_tab.dart` | 889 | 4 |
| `view/add_document_screen.dart` | 709 | 4 |
| 5 more files | — | 10 |

**Why it violates.** These are the add/edit form screens — form field values, submission flags,
validation results and the fetched profile they edit. All four are named Bucket A categories, and
the rule admits no exceptions. The module has cubits for exactly these concerns
(`staff_profile_edit_cubit.dart`, `staff_schedule_cubit.dart`, `important_dates_cubit.dart`,
`create_school_user_cubit.dart`) with paired state classes, so the destination exists and is
partly wired — the screens call the cubits to *submit* but keep the state themselves.

**Severity: High.** A "no exceptions" rule broken across the module's entire write surface, on
files of 1,296–1,838 lines where a `setState` rebuilds the whole form.

**Fix.** Move form state into the existing cubits, one screen at a time, starting with
`edit_schedule_screen.dart` (854 lines, a well-bounded form with `staff_schedule_state.dart`
already defined). Flag the behaviour change the mandate warns about: state moved to a cubit may
now *preserve* form values across navigation where they previously reset. The five existing
`ValueNotifier`s show which state is genuinely Bucket B and should stay local.

---

#### 2.2 — None of the five `ValueListenableBuilder`s passes `child:`

**Rule broken.** MANDATE 2: *"`ValueListenableBuilder` takes a `child:` that is built once and
handed to the builder untouched. **Use it.** That is the actual performance win over `setState`
and the reason this rule exists rather than being style preference."*

**Where.** All five sites discard the third builder parameter and pass no `child:` — verified by
parsing each call's balanced argument list:

| Site | `child:` |
|---|---|
| `view/edit_profile_details_screen.dart:1637` | NO |
| `view/edit_schedule_screen.dart:613` | NO |
| `widgets/staff_action_panel.dart:92` | NO |
| `widgets/staff_card.dart:212` | NO |
| `widgets/staff_documents_tab.dart:725` | NO |

```dart
// widgets/staff_card.dart:212-215
return ValueListenableBuilder<bool>(
  valueListenable: _isExpanded,
  builder: (context, isExpanded, _) {      // third param discarded
    return LayoutBuilder(
```

**Why it violates.** The rule is explicit that `child:` *is* the mechanism — without it the whole
subtree rebuilds on every toggle, which is the cost the conversion from `setState` was meant to
avoid. `staff_card.dart` is the sharpest case: its builder wraps a `LayoutBuilder`, an
`IntrinsicHeight`, a `Container` with decoration, a `Material` and an `InkWell` before reaching
anything that reads `isExpanded`, and all of it is rebuilt per tap.

**Severity: Medium.** The correct pattern is in place and disposal is handled; the performance
benefit the rule exists for is not being realised at any of the five sites.

**Fix.** For each site, identify the subtree that does not depend on the notifier's value and pass
it as `child:`, taking it back through the builder's third parameter. In `staff_card.dart` the
collapsed header row is the natural candidate. Purely mechanical and behaviour-preserving.

---

#### 2.3 — Zero `BlocSelector` across 15 `BlocBuilder`s

**Rule broken.** MANDATE 2: *"Use `BlocSelector` where only a small part of the UI depends on one
state property."*

**Where.** 15 `BlocBuilder` usages, 0 `BlocSelector`, on screens of 1,601 and 1,838 lines.

**Why it violates.** Every `BlocBuilder` rebuilds its subtree on any state change.

**Severity: Low.** A performance rule; no correctness impact.

**Fix.** Apply opportunistically during §2.1 where one small widget reads one property — the staff
counts on `staff_screen.dart`, submit-button enablement on the add/edit forms. Not worth a
dedicated sweep.

---

### Mandate 3 — Folder structure, followed strictly

**Verdict: Partially violated** (3 violations, highest Low)

**What is compliant — this is the cleanest structure of the six modules.** The presentation layer
has **exactly** the four canonical folders and nothing else:

```
presentation/features/staff/
  model/       (5)   view/  (10)   view_model/  (18)   widgets/  (11)
```

No `utils/`, no `forms/`, no loose files at the feature root, no nested `view/` subdirectories —
the four structural violations found in the other five modules are all absent here. The data layer
has all four canonical folders including `mappers/`. The domain layer is **pure**: zero
`package:flutter` imports across all 46 files. The feature name is consistent across all three
layers (`staff`), avoiding the singular/plural split found in Activity and Students.

---

#### 3.1 — 192 cross-folder relative imports

**Rule broken.** MANDATE 3, Imports: *"all cross-folder imports use `package:wowcare/...`.
Relative imports only within the same folder."*

**Where.** 192 imports beginning `../` against 236 `package:wowcare/` imports — the module mixes
both conventions roughly evenly.

**Why it violates.** Cross-folder imports must use the `package:` form. Note the specific hazard
§3.4 describes — an import with one excess `..` compiles in the app but breaks when a test reaches
the file by `file:` URI. **I resolved every relative import in the module and all point at real
files**, so that latent breakage is absent.

**Severity: Low.** No broken imports; mechanical consistency only.

**Fix.** Single codemod converting `../`-crossing imports to `package:wowcare/...`, leaving
same-folder relative imports alone. Verify with `flutter analyze` before and after.

---

#### 3.2 — An empty feature directory containing only committed `.DS_Store` files

**Rule broken.** MANDATE 3, canonical structure — a `domain/features/<feature>/` directory is
expected to hold `entities/`, `repositories/`, `usecases/`. MANDATE 6: *"Commented-out code is
deleted, not kept"* (the same disposition toward dead artefacts).

**Where.** `lib/domain/features/staff_scheduling/` contains **no Dart files**:

```
lib/domain/features/staff_scheduling/.DS_Store
lib/domain/features/staff_scheduling/repositories/.DS_Store
```

**Why it violates.** It is a feature directory with no feature in it, and the only files present
are macOS filesystem metadata that should not be in version control at all. A path-scoped check
written against `domain/features/*/` will match it and find nothing.

**Severity: Low.** No runtime effect. Worth reporting because it is trivially fixable and because
committed `.DS_Store` files suggest a `.gitignore` gap that affects more than this directory.

**Fix.** Delete the directory. Separately, confirm `.DS_Store` is in `.gitignore` — this is
outside the module's scope but the two `.DS_Store` files here are evidence it is not being caught.

---

#### 3.3 — A non-screen file in `view/`

**Rule broken.** MANDATE 3: *"`view/` # screens. Zero logic. Zero API calls."*

**Where.** [view/add_staff_screen_formatters.dart](lib/presentation/features/staff/view/add_staff_screen_formatters.dart)
declares three `TextInputFormatter` classes — `PhoneNumberFormatter:3`,
`NameCapitalizationFormatter:64`, `TrimFormatter:102`. It is not a screen.

**Why it violates.** `view/` is defined as screens; this is input-transformation logic. All three
classes are also duplicated with the students module (§6.1), which is the substantive problem.

**Severity: Low.** One file, correctly grouped with the screen it serves; the placement is
defensible and only the letter of the rule is broken.

**Fix.** Resolve together with §6.1 — the de-duplication moves these classes to a shared location
anyway, which removes them from `view/` as a side effect. No separate change needed.

---

### Mandate 4 — Centralized theming, constants, strings, colors, fonts, sizes

**Verdict: Violated** (5 violations, highest High)

Measured — **the weakest theming result of the six modules**:

| Check | Count | Status |
|---|---|---|
| Raw `Colors.<name>` | **2** | near-compliant |
| `Color(0x...)` | **0** | Compliant |
| `AppColors.` uses | **247** | — |
| Inline `TextStyle(` | **102** | Violated |
| `AppTextStyles.` uses | 13 | Violated |
| `fontFamily:` | **69** | Violated |
| `AppSpacing`/`AppRadius`/`AppDimensions`/`AppSizes` | **0** | Violated |
| `AppStrings.` or any feature `*Strings` | **0** | Violated |

Colour is done. Everything else in this mandate is not.

---

#### 4.1 — 102 inline `TextStyle(` constructors against 13 `AppTextStyles` uses

**Rule broken.** MANDATE 4: *"No inline `TextStyle(`. Use `Theme.of(context).textTheme.<slot>` or
a named `AppTextStyles` entry; local variation uses `.copyWith()` on a named style, never a fresh
`TextStyle`."*

**Where.** 102 inline constructors across the module, against only 13 uses of `AppTextStyles` —
which exists at 1,319 lines with 70 importers app-wide.

```dart
// widgets/staff_card.dart — inside the LayoutBuilder, one of nine in this file
style: TextStyle(
  fontFamily: 'Manrope',
  fontSize: 16,
```

**Why it violates.** The rule names two destinations and 102 sites use neither. The ratio here —
102 inline to 13 named — is the worst of the six modules (Students 146:65, Classroom 59:0,
Scheduling 98:0). A later typography change reaches 13 sites and misses 102.

**Severity: High.** The largest inline-to-named ratio in the codebase, on the module's six
biggest screens.

**Fix.** Add named `AppTextStyles` entries for the recurring size/weight combinations — there are
far fewer distinct styles than 102 sites — and replace the constructors, using `.copyWith()` for
local variation. Rendered output must be identical; where a combination has no entry, add it with
those exact values and list what was added.

---

#### 4.2 — 69 `fontFamily:` lines, in two quoting styles

**Rule broken.** MANDATE 4: *"No `fontFamily: 'Manrope'`. The family is already on `ThemeData` —
these lines are a find-and-delete."*

**Where.** 69 occurrences:

```
50 × fontFamily: 'Manrope'      (single quotes)
17 × fontFamily: "Manrope"      (double quotes)
 1 × fontFamily: 'Inter'         (a deliberate different family)
```

**Why it violates.** The rule's remedy is deletion — `TextStyle` inherits the family from
`ThemeData`, so all 67 Manrope lines are redundant. Unlike Students (which mostly uses a
`Fonts.manrope` token) these are **raw string literals**, exactly the form the rule names. The
17 double-quoted ones additionally violate `prefer_single_quotes`, one of the five lints §9.1
proposes.

**Severity: Medium.** Zero-risk to fix and mechanically bounded, but 69 sites and two spellings of
the same literal.

**Fix.** Delete the 67 Manrope lines; **keep the `Fonts.inter` one**, which is an intentional
override. Do this **after** §4.1, since converting to named `AppTextStyles` entries removes most
of them as a side effect. All are inside `TextStyle`, so deletion is behaviour-preserving.

---

#### 4.3 — No spacing tokens at all

**Rule broken.** MANDATE 4: *"No magic spacing. `AppSizes`
(`lib/core/constants/app_sizes.dart`)."*

**Where.** **Zero** references to `AppSizes`, `AppSpacing`, `AppRadius` or `AppDimensions` across
all 44 presentation files. Every `EdgeInsets`, `SizedBox` and `BorderRadius.circular` dimension is
a numeric literal:

```dart
// widgets/staff_card.dart — within the card's decoration
borderRadius: BorderRadius.circular(12),
height: 60,
padding: EdgeInsets.symmetric(
```

**Why it violates.** The rule names a destination and the module uses none. Note the repo has two
competing spacing containers — `AppSizes` in `core/constants/` (35 importers) and the
`AppSpacing`/`AppRadius`/`AppDimensions` family in `core/theme/` — and this module uses neither,
so unlike the convention question in §4.4 there is no defensible alternative in play here.

**Severity: Medium.** No functional risk; it is why spacing drifts between the staff screens and
the students screens that render near-identical document and profile tabs.

**Fix.** Adopt one of the two existing containers — settle which per **Open questions** — and
extract per file, only where the literal is genuinely *spacing*. Fixed sizes that are not spacing
(icon sizes, border widths, a control's own height) stay, per the mandate and `AppSizes`' own doc
comment. Where a literal has no matching token, add the token rather than snapping to the nearest.

---

#### 4.4 — No string centralisation of any kind

**Rule broken.** MANDATE 4: *"No user-visible string literal in a view file. Everything through
`AppStrings` (`lib/core/constants/app_strings.dart`)."*

**Where.** **Zero** `AppStrings.` references, and **no** feature-local strings file — I checked;
`lib/presentation/features/staff/` contains no `*strings*.dart`. Every user-visible string in the
module is an inline literal.

**Why it violates.** This is the unambiguous case of the rule. Three sibling features solved it
locally (`StudentStrings` 367 entries, `BillingStrings`, `ReportsStrings`) and `AppStrings` exists
with 58 entries and 17 importers — so both conventions are available and the module adopted
neither.

**Severity: Medium.** No functional risk; it blocks localisation, which the standard names as the
main reason to do Mandate 4 properly, and it is the only module of the six with no centralisation
at all.

**Fix.** Once the app-wide convention question is settled (**Open questions**), extract in
tranches, highest-traffic first: snackbar and validation messages, then button and field labels,
then the long tail. Apply the mandate's exclusion — skip log tags, storage keys, API payload keys
and backend enum values (`'ACTIVE'`, `'HIRE_DATE'`, `'MONDAY'` and similar are wire values, not
display text, and must stay). Extract character-for-character.

---

#### 4.5 — Two residual raw colour references

**Rule broken.** MANDATE 4: *"No `Color(0x...)` and no `Colors.<name>` outside
`core/theme/app_colors.dart`."*

**Where.** 2 raw `Colors.*` references, against 247 compliant `AppColors` uses and zero
`Color(0x…)`.

**Why it violates.** The prohibition is unconditional, though in context these are clearly
stragglers from an otherwise-complete sweep.

**Severity: Low.** Two sites against 247 compliant ones — the closest any module has come to
finishing this half of the mandate.

**Fix.** Tokenise both against `AppColors`, adding tokens with the exact value where no match
exists. A few minutes of work that closes the colour rule completely.

---

### Mandate 5 — Presentation talks to cubits only

**Verdict: Partially violated** (2 violations, highest Medium)

Measured — **by a wide margin the strongest layer-discipline result of the six**:

| Check | Staff | Scheduling | Activity | Classroom | Attendance | Students |
|---|---|---|---|---|---|---|
| `serviceLocator<T>()` in presentation | **2** | 4 | 27 | 38 | 60 | 81 |
| Datasource type named in a view | **0** | 0 | 0 | 0 | 0 | 6 |
| `Dio` / `ApiClient` in presentation | **0** | 0 | 3 | 1 | 0 | 2 |
| `FutureBuilder`/`StreamBuilder` in a view | **0** | 0 | 0 | 1 | 0 | 3 |
| Repositories injected into cubits | **0** | 0 | 3 | 0 | 2 | 2 |

**What is compliant.** PDF §5.1 lists `staff_screen.dart` at **16** `serviceLocator` calls — tied
for worst in the codebase. It now has **zero**. No view names a `DataSource`, `Repository`,
`RepositoryImpl`, `ApiClient` or `Dio` type. No `FutureBuilder` or `StreamBuilder` appears
anywhere. The 18 cubits inject roughly **35 distinct use cases** and **not one repository**,
satisfying *"Cubits call use cases, not repositories"* outright — the only module of the six to do
so. The cubit doc comments narrate the migration, e.g.
`create_school_user_cubit.dart:39`: *"them there was the last direct [StorageService] dependency
the add-staff…"*.

---

#### 5.1 — Twelve cubits hold infrastructure service types

**Rule broken.** `docs/mandate-rules.md`, MANDATE 5 — *"Forbidden anywhere under
`lib/presentation`: … `DataSource`, `Repository`, `RepositoryImpl`, `ApiClient`, `Dio`,
`StorageService`, `SharedPreferences` types."*

**Where.** Constructor-injected into `view_model/` cubits:

```dart
// view_model/staff_schedule_cubit.dart:23, 31
required StorageService storageService,
final StorageService _storageService;
```

`StorageService` × 7 (`create_school_user_cubit`, `staff_schedule_cubit`,
`staff_document_upload_cubit`, `staff_classroom_name_cubit`, `staff_profile_photo_upload_cubit`,
and 2 more), `ImageUploadService` × 3, `StaffPhotoBackgroundUploadService` × 2.

**Why it violates — and where the two sources diverge.** `docs/mandate-rules.md` forbids these
types *"anywhere under `lib/presentation`"*, which includes `view_model/`. The PDF's §5.3 wording
is narrower: *"No `DataSource`, `Repository`, `ApiClient`, `Dio` or `SharedPreferences` type may be
named in a **view file**"* — and it omits `StorageService` from that list entirely. Under the PDF
these twelve would not be violations; under mandate-rules.md, which the brief says wins, they are.

I graded them as violations on that basis, but the mitigation is real and worth stating: these are
**constructor-injected**, not service-located, so the cubits are testable and the dependency is
explicit — which is the architectural outcome the mandate is protecting. This is the same call I
made for `ApiClient` held by cubits in the activity audit (§5.5 there), applied consistently.

**Severity: Medium.** The type appears in presentation, but injected rather than resolved, and the
PDF's own wording would not flag most of them. Blast radius is contained.

**Fix.** Introduce narrow domain services for what the cubits actually read — school code, staff
code, the persisted persona — so each cubit depends on an abstraction rather than the storage
primitive. The three upload services are a harder case: they are already abstractions, just named
`Service`, which suggests the rule's list is targeting the wrong noun (see **Open questions**).
Low priority relative to everything else in this report.

---

#### 5.2 — Two `serviceLocator` calls inside cubits

**Rule broken.** MANDATE 5: *"No `serviceLocator<T>()` in `lib/presentation`. Cubits are created
in the router, in the `GoRoute` builder, wrapped in a `BlocProvider`. That is the only place the
service locator appears on the presentation side."*

**Where.** Exactly two, both in `view_model/`, both resolving a use case:

```
view_model/staff_attendance_summary_cubit.dart
view_model/staff_attendance_action_targets_cubit.dart
```

**Why it violates.** The rule permits `serviceLocator` in one place — the `GoRoute` builder — and
neither of these is it. Both resolve a use case that could be constructor-injected like the other
~35 across the module's cubits.

**Severity: Low.** Two occurrences, in cubits rather than views, resolving the correct layer. The
lowest count of any module audited.

**Fix.** Add the two use cases to their cubits' constructors and register them in DI alongside the
others. Two small, self-contained changes that would take this mandate to fully compliant on the
`serviceLocator` rule.

---

### Mandate 6 — Reuse what exists; pure functions out of build()

**Verdict: Violated** (3 violations, highest High)

**What is partly remediated.** PDF §6.1 records `StaffListItem` at **six** copies — *"4 in
attendance/forms/staff_attendance_forms/, 1 in classroom/forms/assign_staff_to_classroom_form.dart,
1 in staff/widgets/staff_list_item.dart"*. It is now down to **two**: the four attendance copies
are gone. §6.6's characterisation still holds for the survivors — `staff/widgets/staff_list_item.dart:4`
is the `const` one taking plain `fullName` / `role` / `roomName` strings, and
`classroom/forms/assign_staff_to_classroom_form.dart:396` is the other shape.

---

#### 6.1 — Ten duplicate class names, four of them inside this module

**Rule broken.** MANDATE 6: *"**No two classes in the codebase share a name.** Diff each collision
before merging — copies with the same name often have different constructors and are not
interchangeable."*

**Where.** I compared all class declarations in `lib/`. Ten collisions involve this module:

| Name | Copies | Locations |
|---|---|---|
| `_ErrorState` | **3** | `view_model/important_dates_cubit.dart:157`, `view_model/staff_document_state.dart:44`, `view_model/staff_document_upload_cubit.dart:250` |
| `_InitialState` | 2 | `view_model/important_dates_cubit.dart:141`, `view_model/staff_document_upload_cubit.dart:228` |
| `_LoadingState` | 2 | `view_model/important_dates_cubit.dart:145`, `view_model/staff_document_state.dart:31` |
| `_SuccessState` | 2 | `view_model/important_dates_cubit.dart:149`, `view_model/staff_document_state.dart:35` |
| `PhoneNumberFormatter` | 2 | `view/add_staff_screen_formatters.dart:3`, `students/view/student_form_formatters.dart:6` |
| `NameCapitalizationFormatter` | 2 | same two files (`:64` / `:38`) |
| `TrimFormatter` | 2 | same two files (`:102` / `:74`) |
| `ProfileField` | 2 | `widgets/staff_profile_tab_widgets.dart:51`, **`shared/common/widgets/profile_info_card.dart:125`** |
| `_DocumentDetailRow` | 2 | `widgets/staff_documents_tab.dart:877`, `students/.../student_documents_tab.dart:958` |
| `StaffListItem` | 2 | `widgets/staff_list_item.dart:4`, `classroom/forms/assign_staff_to_classroom_form.dart:396` |

**Why it violates.** The rule is absolute on names. Three groups matter differently:

- **`ProfileField` is the serious one** — a feature widget colliding with a widget of the same
  name in the **shared** library. A developer importing `ProfileField` gets whichever the IDE
  offers, and one of the two is the shared component the other should arguably be using.
- **The three formatters** duplicated with students are pure logic copied wholesale; §6.6's
  warning about non-interchangeable same-named classes applies directly.
- **The four state-class collisions are internal to this module** and are a different case: they
  are private sealed-state subclasses in separate cubit files, which is idiomatic Dart. See
  **Open questions** — I report them because the rule's wording is unqualified, but the §6.6
  rationale (*"a developer who searches… can hit a constructor mismatch"*) applies weakly to
  file-private state classes.

**Severity: High.** Ten collisions, one of them against the shared library, and three that are
duplicated logic rather than duplicated names.

**Fix.** Three groups, three changes. Diff `ProfileField` against
`shared/common/widgets/profile_info_card.dart` and either adopt the shared one or rename the local
one. Move the three formatters to a shared location used by both staff and students — this also
closes §3.3. Leave the four internal state classes unless the team decides the rule covers
file-private classes; if it does, prefix them per cubit (`_ImportantDatesError` and so on).

---

#### 6.2 — Sixteen of 100 files exceed the 400-line ceiling; the largest is 1,838

**Rule broken.** MANDATE 6: *"File size ceiling: 400 lines. Split by extracting cohesive units,
not arbitrarily at line 400."* PDF §9.3 gate 11.

**Where.** 16 files over:

| File | Lines |
|---|---|
| `presentation/.../view/edit_profile_details_screen.dart` | **1,838** |
| `presentation/.../view/staff_screen.dart` | **1,601** |
| `data/.../repositories/staff_repository_impl.dart` | **1,309** |
| `presentation/.../view/add_staff_screen.dart` | **1,296** |
| `data/.../datasources/staff_remote_datasource.dart` | **1,231** |
| `presentation/.../widgets/staff_documents_tab.dart` | 916 |
| `presentation/.../widgets/staff_dates_tab.dart` | 889 |
| `presentation/.../widgets/staff_profile_tab.dart` | 880 |
| `presentation/.../view/edit_schedule_screen.dart` | 854 |
| `presentation/.../widgets/staff_card.dart` | 850 |
| `presentation/.../view/staff_profile_screen.dart` | 822 |
| `data/.../models/staff_models.dart` | 735 |
| `presentation/.../view/add_document_screen.dart` | 709 |
| `presentation/.../view/edit_important_dates_screen.dart` | 655 |
| `presentation/.../view_model/staff_cubit.dart` | 638 |
| `presentation/.../view/staff_filter_screen.dart` | 533 |

`staff_card.dart` is 850 lines, having **grown** from the 825 the PDF §6.2 records — even though
its state handling was correctly remediated in the meantime.

**Why it violates.** The ceiling is 400 and the largest is 4.6× over. Four widget files exceed
850 lines. `staff_models.dart` at 735 lines holds 7 models with 7 hand-written parsers (§8.1),
which is why the private duplicates in §6.1 can hide inside it.

**Severity: High.** Sixteen files over, five over 1,200, and one grew after being named in the
standard.

**Fix.** Split by cohesive unit. The datasource and repository divide along the profile /
documents / important-dates / schedules / school-user axes the use cases already name. The three
~880-line tab widgets each split into their card sections. Do this after Phase A's smaller
changes so the extraction works on already-tidied code.

---

#### 6.3 — Twenty-one `Widget _buildXxx()` methods

**Rule broken.** MANDATE 6: *"Replace `Widget _buildXxx()` methods with private
`StatelessWidget` classes in the same file. A method returning a Widget cannot be `const`, cannot
be given a key, and rebuilds with its whole enclosing widget."*

**Where.** 21 methods across the module.

**Why it violates.** Each rebuilds with its whole enclosing widget, and this module's enclosing
widgets run to 1,838 lines with 84 `setState` calls driving them (§2.1).

**Severity: Medium.** Mechanical, but the rebuild cost is real at these file sizes.

**Fix.** Convert each to a private `StatelessWidget` in the same file, passing what it reads as
constructor parameters. Doing this first surfaces which `State` fields each section depends on,
which directly supports §2.1 and §6.2.

---

### Mandate 7 — One responsive source

**Verdict: Violated** (3 violations, highest Medium)

**What is compliant.** One of the three `LayoutBuilder`s is a legitimate own-box use:
`widgets/staff_card.dart:215` reads `constraints.maxWidth` to size the card within its parent
column, which the mandate explicitly preserves (*"A card that reflows inside a narrow column is a
legitimate use"*). **Keep it.**

---

#### 7.1 — Two `LayoutBuilder`s used to derive a screen breakpoint

**Rule broken.** MANDATE 7: *"Breakpoints are defined once in
`lib/core/responsive/app_breakpoints.dart`. No other file contains a screen-width comparison
against a literal."* And: *"A feature `LayoutBuilder` is allowed **only** when the widget must
respond to its own box rather than the screen."*

**Where.**

```dart
// view/staff_screen.dart:708-711
return LayoutBuilder(
  builder: (context, constraints) {
    ...
    constraints.maxWidth >= 600;

// view/staff_screen.dart:755-757
LayoutBuilder(
  builder: (context, constraints) {
    final bool isTablet = constraints.maxWidth >= 600;
```

**Why it violates.** This is the PDF §7.4 *WRONG* block reproduced almost verbatim — the standard
shows *"LayoutBuilder(builder: (context, constraints) { final bool isTablet = constraints.maxWidth
>= 600;"* as the pattern to remove. Using a `LayoutBuilder` to make a tablet/phone decision is
precisely the misuse §7.2 forbids: the exemption is for widgets responding to their own box, and
a device-class decision is a screen decision. The same pattern appears in the students module at
`student_screen.dart:1314`.

**Severity: Medium.** No live layout break demonstrated — 600 matches `AppBreakpoints`'
`compactMaxWidth`, so the answers agree today. The cost is that the breakpoint is redeclared
outside the single source, so it will not follow a future change to it.

**Fix.** Replace both with `context.isTablet`, which resolves from `AppBreakpoints`. Remove the
two `LayoutBuilder`s entirely if the breakpoint is their only purpose; keep them if something else
reads `constraints`. Leave `staff_card.dart:215` alone.

---

#### 7.2 — Nine `MediaQuery.of(context)` reads and no field-scoped accessors

**Rule broken.** MANDATE 7: *"`MediaQuery.sizeOf(context)` over `MediaQuery.of(context)` — `.of`
subscribes to the whole object, so a width read re-runs on every keyboard open."*

**Where.** **9** `MediaQuery.of`, **0** `MediaQuery.sizeOf`, **0** `MediaQuery.paddingOf`.

**Why it violates.** All nine subscribe to the whole `MediaQuery` object. This module is
form-heavy — the add-staff wizard, the edit-profile screen, the schedule and document forms — so
the keyboard opens constantly and each open re-runs every one of these reads.

**Severity: Medium.** Redundant rebuilds on the module's most keyboard-intensive screens.

**Fix.** Swap each to the field-scoped accessor: `MediaQuery.sizeOf` for `.size` reads,
`MediaQuery.paddingOf` for `.padding`, `MediaQuery.viewInsetsOf` for `.viewInsets`.
Behaviour-preserving one-line changes.

---

#### 7.3 — Feature code does not read the published size class

**Rule broken.** MANDATE 7: *"Feature code reads `context.screenSize` / `context.isTablet` /
`context.responsive(compact:, medium:, expanded:)`; **it does not measure**."*

**Where.** `context.responsive` / `context.isTablet` / `context.screenSize` are used **0 times**.
Ten files import a responsive helper instead, and two measure directly (§7.1).

**Why it violates.** `ResponsiveScope` is mounted at [app/app.dart:82](lib/app/app.dart#L82) and
the extension API exists at
[responsive_scope.dart:49-74](lib/core/responsive/responsive_scope.dart#L49-L74), so the
destination is available and unused. Scheduling demonstrates the target state with 12 uses.

**Severity: Medium.** No layout inconsistency where the helper is used — it delegates to
`AppBreakpoints` — but the two direct measurements in §7.1 sit outside that guarantee.

**Fix.** Convert the two direct measurements first (§7.1), then adopt `context.responsive(...)`
per call site. The broader helper migration is app-wide work (116 importers) that this module
should follow rather than lead.

---

### Mandate 8 — Models everywhere, generated, never raw maps

**Verdict: Violated** (5 violations, highest High)

Measured:

| Check | Count | Target |
|---|---|---|
| `@JsonSerializable()` classes | **0** | all models |
| `.g.dart` files committed | **0** | one per model |
| Hand-written `fromJson` factories | **20** | 0 |
| Hand-written `toJson` methods | **14** | 0 |
| `as String? ?? ''` restatements | **82** | 0 |
| `as int? ?? 0` restatements | 7 | 0 |
| `?.toString() ??` restatements | 20 | 0 |
| `fromJson` calls inside the datasource | 17 | 0 |
| `mappers/` files | 1 | per-feature |
| `Map<String, dynamic>` in domain (code) | 7 | **0** |
| `Map<String, dynamic>` in presentation | 7 | **0** |

`json_annotation ^4.9.0` is in `dependencies` and `json_serializable ^6.8.0` + `build_runner
^2.1.4` are in `dev_dependencies`. The pipeline is installed and has never been pointed at this
module.

---

#### 8.1 — No code generation; 34 hand-written serialisation members and 109 defaulting restatements

**Rule broken.** MANDATE 8: *"Models are annotated `@JsonSerializable()` with generated
`fromJson`/`toJson` via `part 'x.g.dart'`. **No hand-written serialisation.**"* And:
*"Defaulting is declared once per field with `@JsonKey(defaultValue: ...)`."*

**Where.** All 7 model files. `staff_models.dart` alone declares 7 `fromJson` factories and 7
`toJson` methods:

```
staff_models.dart:44   StaffListItemModel.fromJson          :131  toJson
staff_models.dart:190  StaffPageModel.fromJson              :224  toJson
staff_models.dart:267  StaffProfileAddressModel.fromJson    :279  toJson
staff_models.dart:319  StaffProfileTimeModel.fromJson       :365  toJson
staff_models.dart:396  StaffProfileWorkScheduleModel.fromJson :404 toJson
staff_models.dart:433  StaffProfileBreakScheduleModel.fromJson :442 toJson
staff_models.dart:514  StaffProfileModel.fromJson           :678  toJson
```

and the defaulting idioms §8.4 says collapse into annotations are restated **109 times** across
the data layer: 82 × `as String? ?? ''`, 20 × `?.toString() ??`, 7 × `as int? ?? 0`.

**Why it violates.** The rule is "no hand-written serialisation" and the generator is already a
dependency. Every one of the 109 restatements is a per-field re-decision that
`@JsonKey(defaultValue:)` would declare once. This is the mechanism behind the `signedInBy` defect
§8.2a documents — the same contract retyped enough times that one copy drifts.

**Severity: High.** No live defect found, but this module is one of the three §8.6 names as
holding the most parsing (*"Then attendance, student and staff, in that order"*), and it has the
largest untouched parser surface of the three.

**Fix.** Convert the models to `@JsonSerializable()` with `part 'x.g.dart'`, commit the generated
files, and delete the hand-written bodies. The mandate requires a characterisation test per model
**before** deleting any parser — same fixture through old and new, field-for-field, including
nulls, missing keys and wrong types. Convert one model first as the reference;
`StaffCountModel` (63 lines) is the right size. Follow §8.6's order — do this after attendance and
student.

---

#### 8.2 — A `fromJson` taking `dynamic`, wrapping a private parse closure

**Rule broken.** MANDATE 8: *"Field quirks are annotations, not inline expressions."* PDF §8.1
counts both of these patterns app-wide: *"Private parse closures inside factory bodies — 12 —
Cannot be tested or reused"* and *"`fromJson` taking `dynamic` instead of `Map<String, dynamic>` —
**2** — No type contract at the boundary at all."*

**Where.** [models/staff_models.dart:319-330](lib/data/features/staff/models/staff_models.dart#L319-L330)
— **one of the only two `dynamic` factories in the codebase**, and it contains a parse closure:

```dart
factory StaffProfileTimeModel.fromJson(dynamic json) {
  if (json == null) return const StaffProfileTimeModel(hour: 0, minute: 0);

  // If it's already a Map (object format), parse it
  if (json is Map<String, dynamic>) {
    int toInt(dynamic v) {              // private closure, untestable
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.round();
      return int.tryParse(v.toString()) ?? 0;
    }
```

**Why it violates.** Two named patterns in one factory. The `dynamic` parameter means there is no
type contract at the JSON boundary at all — the caller can pass anything. `toInt` is a numeric
coercion rule defined inside a factory body, so it can be neither unit-tested nor reused, and the
same coercion is restated elsewhere in the file.

**Severity: Medium.** Contained to one model, but it is the boundary for every time value on the
staff profile — work schedules and break schedules both flow through it.

**Fix.** Change the signature to `Map<String, dynamic>` and handle the string-format branch at the
call site, or via `@JsonKey(readValue:)` once the model is generated. Extract `toInt` to a named,
tested helper. Do this as part of §8.1's conversion of this file, not before.

---

#### 8.3 — Domain entities carry `toPayload()`, and one carries a `fromMap` factory

**Rule broken.** MANDATE 8: *"Domain entities have no serialisation."* MANDATE 3: *"Domain
entities are pure Dart with no Flutter imports and no `fromJson`/`toJson`."*

**Where.** Seven code sites across five entities (the other five matches in the domain layer are
doc comments, not code — verified line by line):

```dart
// entities/staff_important_date.dart:29 — deserialisation on a domain entity
factory StaffImportantDate.fromMap(Map<String, dynamic> json) {
  return StaffImportantDate(
    importantDateType: (json['importantDateType'] ?? '').toString(),

// entities/staff_important_date.dart:41, staff_address_update.dart:30,
// staff_my_profile_update.dart:34, staff_profile_update.dart:40,
// staff_schedule_entry.dart:20 and :48
Map<String, dynamic> toPayload() => { … };
```

**Why it violates.** `fromMap` is the §8.2d violation class under a different name — a domain
entity that knows the wire format, so a backend rename propagates into the pure layer. The six
`toPayload()` methods are serialisation on a domain entity in substance if not in name; whether
the rule's `fromJson`/`toJson` wording covers them is genuinely ambiguous (see **Open questions**),
and the activity module has the identical pattern.

The mitigation is real and documented: these entities were introduced deliberately to *replace*
raw maps flowing through the views, and the doc comments say so —
*"Replaces the raw `Map<String, dynamic>` body the edit-profile view used to build inline. JSON
shaping stays at the data-layer boundary."* That is a clear improvement on what preceded it.

**Severity: Medium.** `fromMap` is the substantive half — inbound parsing in domain. The
`toPayload()` methods are a defensible intermediate state.

**Fix.** Move `StaffImportantDate.fromMap` into a data-layer model with generated `fromJson`, and
add a mapper to convert it — `ImportantDateRequestModel` already exists in
`staff_important_dates_models.dart:15` with its own `fromJson`, so the destination is half-built.
Defer the `toPayload()` question until the team rules on it.

---

#### 8.4 — Only one mapper, and it does presentation formatting

**Rule broken.** MANDATE 8: *"Domain entities have no serialisation. Mappers convert model →
entity, which is what the `mappers/` folder is for."* MANDATE 6: *"Pure logic (dates, formatting,
derived values) lives on the entity or in `core/extensions/`."*

**Where.** `mappers/` holds a single file,
[staff_shift_mapper.dart](lib/data/features/staff/mappers/staff_shift_mapper.dart), covering
`staff_shift` only — none of the profile, document, important-dates or school-user shapes has a
mapper. And that one mapper produces display strings:

```dart
// mappers/staff_shift_mapper.dart:10-19
static String _toShiftClockString(StaffProfileTimeModel time) {
  final period = time.hour >= 12 ? 'PM' : 'AM';
  ...
// mappers/staff_shift_mapper.dart:64
room: 'Lunch Break',
```

**Why it violates.** Two things at once. Six of the seven model families convert to entities
without a mapper — the repository does it inline, so the `mappers/` folder exists but is not the
convention. And the one mapper that does exist formats `"09:00:00 AM"` strings and hardcodes the
user-visible label `'Lunch Break'`, putting presentation concerns in the data layer (which is also
a Mandate 4 string that cannot reach `AppStrings` from there).

**Severity: Low.** The folder exists, which is more than most features have; the gap is coverage
and one misplaced concern.

**Fix.** As §8.1 converts each model, add its mapper alongside — generated models make mappers
trivial. Move `_toShiftClockString` onto the entity as a getter (where `StaffProfileTime`
already has a `formattedTime` doing the same job) and lift `'Lunch Break'` to a constant the
presentation layer owns.

---

#### 8.5 — Seven `Map<String, dynamic>` references in the presentation layer

**Rule broken.** MANDATE 8: *"No `Map<String, dynamic>` in `lib/domain` or `lib/presentation` —
not as a parameter, not as a return type, not as a field."* PDF §8.3 sets the expected count for
`lib/presentation` at **zero**.

**Where.** 7 references across the presentation layer.

**Why it violates.** The target for this layer is zero.

**Severity: Low.** Seven sites — the lowest count of the six modules (Activity 159, Students 37,
Classroom 10, Attendance 5). The typed route args and results (§1) are why this number is so low.

**Fix.** Audit each individually — each is either a wire shape (→ a data-layer model) or an
untyped argument bag (→ a typed class in `model/`, following `staff_route_args.dart`). Most will
close as a side effect of §8.1.

---

## 4. Remediation order

Sequenced so each step is a single isolated change that preserves existing behaviour, and so no
step has to be redone by a later one. The ordering follows `docs/mandate-rules.md`'s revised
sequence (**1 → 5 → 2 → 3 → 6 → 4 → 7 → 8**) adapted to this module.

**Before anything:** capture the baseline the guardrails require — `flutter analyze` on the three
module directories and `flutter test` on the **17** test files covering it (1 data, 4 domain, 12
presentation). The analyzer count must not increase and no passing test may fail.

### Phase A — small, isolated, high-clarity wins

| # | Change | Fixes | Why here |
|---|---|---|---|
| 1 | Delete the six unreferenced `routeName` constants; settle the two live ones | §1.1 | Removes four constants that declare paths the router does not serve. Zero references, so zero risk. |
| 2 | Constructor-inject the two use cases currently service-located in cubits | §5.2 | Takes the `serviceLocator` count to **zero** — two small DI changes. |
| 3 | Delete `lib/domain/features/staff_scheduling/`; check `.gitignore` for `.DS_Store` | §3.2 | No Dart files; standalone. |
| 4 | Tokenise the two residual raw colour references | §4.5 | Closes the colour rule completely. |
| 5 | Pass `child:` at the five `ValueListenableBuilder` sites | §2.2 | The pattern is already correct; this adds the mechanism the rule exists for. Behaviour-preserving. |
| 6 | Replace the two `LayoutBuilder`-derived breakpoints with `context.isTablet`; **keep `staff_card.dart:215`** | §7.1, §7.3 (part) | Removes the §7.4 *WRONG* pattern. 600 already matches `AppBreakpoints`, so no visual change. |
| 7 | Swap the nine `MediaQuery.of` reads for `sizeOf`/`paddingOf`/`viewInsetsOf` | §7.2 | One line each. |

### Phase B — navigation and reuse

| # | Change | Fixes | Why here |
|---|---|---|---|
| 8 | Audit the 18 `Navigator.pop` sites; convert screen-route pops to `context.pop`, leave modal dismissals | §1.2 | The typed result classes make each conversion compiler-checked. |
| 9 | Diff `ProfileField` against the shared `profile_info_card.dart`; adopt or rename | §6.1 (part) | The one collision against the shared library — highest-risk of the ten. |
| 10 | Move the three formatters to a shared location used by staff and students | §6.1 (part), §3.3 | Closes two findings in one change. |
| 11 | Decide whether the rule covers file-private state classes; act or record | §6.1 (rest) | Blocked on an Open Question. |
| 12 | Convert the 21 `Widget _buildXxx()` to private `StatelessWidget` classes | §6.3 | Surfaces the seams for step 13. |
| 13 | Split the 16 files over 400 lines — `staff_models.dart` and the datasource first | §6.2 | After 12. `staff_models.dart` first because §8.1 needs it split anyway. |

### Phase C — state

| # | Change | Fixes | Why here |
|---|---|---|---|
| 14 | Move form state into the existing cubits, one screen at a time, starting with `edit_schedule_screen.dart` | §2.1 | The cubits and state classes exist. **Flag the behaviour change**: form values may now persist across navigation where they previously reset. |
| 15 | Apply `BlocSelector` where one small widget reads one property | §2.3 | Opportunistic, within 14. |
| 16 | Introduce narrow domain services to replace `StorageService` in cubits | §5.1 | After 14, when it is clear what each cubit actually reads. Low priority. |

### Phase D — theming (deliberately after Phase B)

| # | Change | Fixes | Why here |
|---|---|---|---|
| 17 | Add named `AppTextStyles` entries; replace the 102 inline `TextStyle(` constructors | §4.1 | **After Phase B** — per "Move 6 before 4", doing this earlier would tokenise duplicated formatter and tab code that steps 10 and 13 restructure. |
| 18 | Delete the 67 Manrope `fontFamily:` lines; **keep the `Fonts.inter` one** | §4.2 | Mostly removed as a side effect of 17. |
| 19 | Adopt a spacing container and extract spacing literals per file | §4.3 | Blocked on the Open Question about which container. |
| 20 | Extract user-visible strings, highest-traffic first | §4.4 | Blocked on the Open Question about which strings convention. |
| 21 | Codemod relative → `package:` imports | §3.1 | After all file moves are done. |

### Phase E — models (largest blast radius, safest last)

| # | Change | Fixes | Why here |
|---|---|---|---|
| 22 | Move `_toShiftClockString` onto the entity; lift `'Lunch Break'` out of the mapper | §8.4 (part) | Small and isolated. |
| 23 | Convert one model to `@JsonSerializable()` as the reference — `StaffCountModel` | §8.1 (part) | **Write the characterisation test first**, per the mandate. |
| 24 | Convert the remaining models; commit the `.g.dart` files; add a mapper per model | §8.1, §8.4 | Repeat 23's pattern. §8.6 puts staff after attendance and student. |
| 25 | Fix `StaffProfileTimeModel.fromJson(dynamic)` and extract its parse closure | §8.2 | Part of 24's conversion of `staff_models.dart`. |
| 26 | Move `StaffImportantDate.fromMap` into a data-layer model + mapper | §8.3 (part) | Needs 24's generated models. |
| 27 | Type or eliminate the seven presentation maps | §8.5 | **Last.** Most close as a side effect of 24. |

---

## 5. Open questions

Points where the standard does not clearly settle the case. I have reported the finding and
flagged the ambiguity rather than guessing.

1. **Which source wins.** The brief says `docs/mandate-rules.md` takes precedence; that file's own
   preamble says the PDF wins. I followed the brief. **This is now the sixth audit to raise it**,
   and for this module it changed a verdict rather than just the ordering — see question 2. One of
   the two documents should be corrected.

2. **How broadly is the forbidden-types rule scoped?** §5.1. `docs/mandate-rules.md` forbids
   `StorageService` and the other infrastructure types *"anywhere under `lib/presentation`"*, which
   catches twelve constructor-injected dependencies in this module's cubits. The PDF's §5.3 is
   narrower — *"may be named in a **view file**"* — and does not list `StorageService` at all.
   Under the PDF, Mandate 5 here would be **Compliant** with one Low finding; under
   mandate-rules.md it is Partially violated with two. I applied mandate-rules.md per the brief.
   Worth settling explicitly, because constructor injection into a cubit is arguably the outcome
   the mandate wants, not a breach of it — and because three of the twelve are `*Service`
   abstractions the rule's noun-list does not obviously target.

3. **Does "no two classes share a name" cover file-private classes?** §6.1. Four collisions here
   are private sealed-state subclasses (`_ErrorState`, `_LoadingState`, `_SuccessState`,
   `_InitialState`) in separate cubit files — idiomatic Dart, invisible outside their library, and
   not reachable by the "developer searches and reuses the wrong one" failure §6.6 describes. The
   rule's wording is unqualified and the PDF's §6.1 table does list private duplicates (`_Chip`,
   `_DialogField`), but those were duplicated *widgets* across unrelated features, which is a
   different situation. A ruling would settle this for every module.

4. **Is `toPayload()` on a domain entity "serialisation"?** §8.3. Mandate 8 says *"Domain entities
   have no serialisation"* and Mandate 3 says *"no `fromJson`/`toJson`"*. Six entities here expose
   `toPayload()` returning `Map<String, dynamic>` — not named `toJson`, but functionally a wire
   serialiser. They were introduced deliberately to replace raw maps in views and are documented
   as such, so they are a clear improvement on what preceded them. Whether they are the
   destination or an intermediate step is a call the standard does not make. **The activity module
   has the identical pattern**, so one ruling covers both.

5. **Which spacing container?** §4.3. The repo has two — `AppSizes` in `core/constants/` (which
   Mandate 4 names, 35 importers) and the `AppSpacing`/`AppRadius`/`AppDimensions` family in
   `core/theme/`. This module uses neither, so it has no stake in the answer, but it cannot adopt
   one until the question is settled. Raised in the attendance, classroom and scheduling audits.

6. **`AppStrings` or feature-local `*Strings`?** §4.4. Mandate 4 names `AppStrings`. Three features
   instead use feature-local classes (`StudentStrings` 367 entries, `BillingStrings`,
   `ReportsStrings`) against `AppStrings`' 58 entries total. Staff uses neither, so whichever
   convention wins, this module starts from zero — but it should not adopt one unilaterally.
   Probably decided together with question 5, since both are "the mandate names one container, the
   codebase adopted another".

7. **Should `StaffScreen.routeName` and `StaffRoutes.list` both exist?** §1.1. `StaffRoutes`
   annotates two of its constants as *"Matches `StaffScreen.routeName`"*, so the aliasing looks
   deliberate. The mandate says paths live in `app_routes.dart` but does not say whether a screen
   may keep a matching constant for its own use. The four *stale* duplicates are unambiguously
   wrong; the two agreeing ones are a style question.

8. **Nothing currently enforces any of this.** `analysis_options.yaml` still has every lint line
   commented out, including `include: package:flutter_lints/flutter.yaml`; only an
   `analyzer: exclude: third_party/**` block is active. That is PDF §9.1, unchanged. Note the 17
   double-quoted `fontFamily: "Manrope"` lines in §4.2 would be caught by `prefer_single_quotes`,
   one of the five rules §9.1 proposes.

---

## 6. Method and limits

- All 100 in-scope files were read in full. Cross-cutting counts (`setState`, `serviceLocator`,
  `Map<String, dynamic>`, `Colors.*`, `Color(0x`, `TextStyle(`, `fontFamily`, `fromJson`, `toJson`,
  the four defaulting idioms, imports, class declarations, `MediaQuery` variants) were produced by
  exhaustive grep over the three module directories and then verified by reading the matched sites
  in context. Every quoted snippet was read before quoting.
- Both authoritative sources were re-read for this audit: the PDF was re-extracted from
  `WowCare2-Engineering-Standards-Eight-Mandates 1.pdf` (39 pages, 80,842 characters) and
  `docs/mandate-rules.md` re-read in full (160 lines).
- Every file path and line number was checked against the working tree at `cdb6b86e` on
  `develop-refactor`. Nothing is inferred from a filename.
- Comparisons against the reference commit come from the PDF's own tables (§1.1, §2.3, §5.1, §6.1,
  §6.2, §6.6, §8.1, §8.2c, §8.6), each of which names this module by path; I re-measured every one
  at the audited commit rather than assuming the recorded figure still held. Three were found
  remediated (`staff_screen.dart` pushes and `serviceLocator`, `staff_card.dart` state handling),
  one partly (`StaffListItem` 6 → 2), and two unchanged (the datasource, the model parsers).
- Duplicate class names were found by extracting all public and private class declarations in
  `lib/` (excluding `.g.dart`) and diffing against this module's declarations.
- `child:` usage in `ValueListenableBuilder` was determined by parsing each call's balanced
  argument list and testing for a top-level `child:` key, not by proximity grep — **an earlier
  proximity grep in this audit reported 5 of 5 sites passing `child:`, which was a false positive
  matching the enclosing widget's `child:`. The correct answer is 0 of 5**, which is why §2.2 is
  reported as a violation.
- Domain-layer `Map<String, dynamic>` occurrences were classified line by line as code or comment;
  of 12 matches, **5 are doc comments** and 7 are real code, and only the 7 are counted in §8.3.
- Test coverage was counted as files under `test/data/features/staff`,
  `test/domain/features/staff` and `test/presentation/features/staff` (1 + 4 + 12 = 17). Files
  elsewhere that merely mention "staff" — attendance forms, classroom assign — were excluded.
- I did not run `flutter analyze` or `flutter test` as part of this audit; the baseline capture is
  listed as the first remediation step rather than claimed as done.
- The five existing audits in this folder were used only for cross-module comparison and heading
  parity. Every finding here was derived from the staff code.
- No files were modified.
