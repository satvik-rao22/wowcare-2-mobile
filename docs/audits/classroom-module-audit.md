# Classroom Module — Eight Mandates Compliance Audit

| | |
|---|---|
| **Module** | Classroom |
| **Paths** | `lib/presentation/features/classroom/`, `lib/data/features/classroom/`, `lib/domain/features/classroom/` |
| **Commit audited** | `cdb6b86e251c87c14718cf1054344e480f8f091f` (`cdb6b86e`), branch `develop-refactor` |
| **Date** | 2026-09-09 |
| **Scope size** | 57 files, 12,872 lines |
| **Standard** | `WowCare2-Engineering-Standards-Eight-Mandates 1.pdf` + `docs/mandate-rules.md` |
| **Nature** | Audit only. No code was changed. |

> **A note on inputs.** The task template arrived with `MODULE_NAME` and `MODULE_PATH` as
> unfilled placeholders (`<e.g. Scheduling>`). I resolved them from the prose instruction
> ("the classroom module") and verified all three directories exist before auditing. No path
> was invented.
>
> **Commit note.** HEAD has moved since the two earlier audits in this folder (`bfbc4fbb` →
> `cdb6b86e`, one commit: "fixed the issue now working fine"). `git diff bfbc4fbb..HEAD` over
> the three classroom directories is **empty**, so this module is byte-identical to what the
> earlier audits saw, and the three reports remain directly comparable.
>
> **Precedence note.** The brief says `docs/mandate-rules.md` wins where the two sources
> differ. `docs/mandate-rules.md` itself says the PDF wins. I followed the brief and flagged
> the conflict in **Open questions**, as in the two prior audits. The two agree on all eight
> rules; they differ only in emphasis and recommended execution order.

**Severity definitions** (identical to `activity-module-audit.md` and
`attendance-kiosk-module-audit.md`):
**Critical** — a live defect or a security/correctness hazard reachable in production.
**High** — a rule broken in a way that will cause divergence or defects as the code changes.
**Medium** — a real rule breach with contained blast radius.
**Low** — cosmetic, mechanical, or already mitigated in practice.

---

## 0. Scope — the exact file set audited

**57 files, 12,872 lines.** Every file below was read in full.

### `lib/data/features/classroom/` — 9 files

| Folder | Files (lines) |
|---|---|
| `datasources/` (1) | `classroom_remote_datasource.dart` (451) |
| `mappers/` (1) | `classroom_mapper.dart` (41) |
| `models/` (6) | `classroom_all_models.dart` (130), `classroom_attendance_summary_model.dart` (30), `classroom_details_models.dart` (134), `classroom_enrollment_models.dart` (47), `classroom_logo_models.dart` (66), `dashboard_summary_models.dart` (59) |
| `repositories/` (1) | `classroom_repository_impl.dart` (389) |

### `lib/domain/features/classroom/` — 18 files

| Folder | Files (lines) |
|---|---|
| `entities/` (8) | `classroom.dart` (33), `classroom_count.dart` (16), `classroom_details.dart` (125), `classroom_logo_upload_session.dart` (17), `ratio_monitoring_classroom.dart` (71), `school_capacity.dart` (16), `school_fte.dart` (14), `student_classroom_enrolled_count.dart` (17) |
| `repositories/` (1) | `classroom_repository.dart` (101) |
| `usecases/` (9) | `create_classroom_logo_upload_session_usecase.dart` (20), `finalize_classroom_logo_usecase.dart` (17), `get_active_classrooms_usecase.dart` (21), `get_classroom_by_code_usecase.dart` (14), `get_classroom_count_usecase.dart` (12), `get_ratio_monitoring_classrooms_usecase.dart` (46), `get_school_capacity_usecase.dart` (12), `get_school_fte_usecase.dart` (12), `get_student_classroom_enrolled_count_usecase.dart` (20) |

### `lib/presentation/features/classroom/` — 30 files

| Folder | Files (lines) |
|---|---|
| `forms/` (3) | `assign_staff_to_classroom_form.dart` (512), `assign_student_to_classroom_form.dart` (547), `date_picker_normal.dart` (34) |
| `forms/widgets/` (1) | `assign_classroom_form_widgets.dart` (227) |
| `utils/` (1) | `classroom_age_range.dart` (90) |
| `view/classroom_tab_cards/` (3) | `classroom_notes_tab_card.dart` (238), `classroom_staff_tab_card.dart` (1,438), `classroom_students_tab_card.dart` (1,853) |
| `view/filters/` (3) | `classroom_staff_filter_screen.dart` (192), `classroom_student_filter_screen.dart` (252), `designation_display_utils.dart` (15) |
| `view/screens/` (3) | `classroom_info_screen.dart` (1,362), `classroom_overview_screen.dart` (606), `classroom_screen.dart` (692) |
| `view/widgets/` (2) | `classroom_dropdown.dart` (145), `classroom_student_list_item.dart` (518) |
| `view_model/` (14) | `assign_staff_confirmation_cubit.dart` (62), `assign_staff_confirmation_state.dart` (26), `assign_staff_selection_cubit.dart` (226), `assign_staff_selection_state.dart` (102), `assign_student_confirmation_cubit.dart` (115), `assign_student_confirmation_state.dart` (35), `assign_student_selection_cubit.dart` (238), `assign_student_selection_state.dart` (116), `classroom_cubit.dart` (204), `classroom_staff_cubit.dart` (406), `classroom_staff_state.dart` (76), `classroom_state.dart` (54), `classroom_students_cubit.dart` (467), `classroom_students_state.dart` (93) |

### Also examined (module code outside MODULE_PATH, and shared code the module reaches into)

`lib/core/utils/classroom_visibility.dart` · `lib/core/utils/attendance_classroom_scope.dart` ·
`lib/shared/common/widgets/classroom_selection_widget_exact.dart` ·
`lib/shared/common/widgets/custom_multi_select_dropdown.dart` ·
`lib/presentation/features/staff/widgets/staff_list_item.dart` ·
`lib/presentation/features/billing/widgets/analytics/analytics_section.dart` ·
`lib/presentation/features/attendance/view_model/attendance_school_time.dart` ·
`lib/core/router/app_routes.dart` · `lib/src/app_router.dart` · `lib/app/di/di.dart` ·
`lib/core/theme/{app_colors,app_text_styles,app_spacing,app_radius,app_dimensions}.dart` ·
`lib/core/constants/{app_strings,app_sizes}.dart` ·
`lib/core/responsive/{app_breakpoints,responsive_scope}.dart` ·
`lib/shared/utils/responsive_helper.dart` ·
`lib/domain/features/{staff_classroom,student_classroom}/` · `pubspec.yaml` ·
`analysis_options.yaml` · the full `test/` tree

**Adjacent features deliberately excluded from the counts.** `lib/data/features/staff_classroom/`
(3 files), `lib/domain/features/staff_classroom/` (5), `lib/data/features/student_classroom/` (3)
and `lib/domain/features/student_classroom/` (4) are separate feature directories under the
standard's structure, not classroom-owned. The classroom module consumes them
(`AssignStaffToClassroomUseCase`, `AssignStudentsToClassroomUseCase`, `StudentClassroomItem`).
They are named here so the boundary is explicit — see **Open questions**.

---

## 1. Summary table

| # | Mandate | Verdict | Violations | Highest severity |
|---|---|---|---|---|
| 1 | Navigation — GoRouter everywhere | **Violated** | 3 | High |
| 2 | State — setState scarcely | **Violated** | 3 | High |
| 3 | Folder structure | **Violated** | 5 | High |
| 4 | Centralized theming / constants | **Partially violated** | 4 | High |
| 5 | Presentation talks to cubits only | **Violated** | 4 | High |
| 6 | Reuse; pure functions out of build() | **Violated** | 6 | High |
| 7 | One responsive source | **Partially violated** | 3 | Medium |
| 8 | Models everywhere, never raw maps | **Violated** | 5 | High |
| | **Total** | | **33** | |

No mandate is Not Applicable — all eight bear on this module.

---

## 2. Overall risk assessment

Classroom is the smallest of the three modules audited so far (12,872 lines against Activity's
40,840 and Attendance/Kiosk's 48,004) and the most polarised: its data and domain layers are the
best in the codebase, and its presentation layer is the worst. Domain is genuinely exemplary —
pure Dart, zero `Map<String, dynamic>`, and real business logic living on the entities where
Mandate 6 wants it (`Classroom.isAgeOutsideRange`, `RatioMonitoringClassroom.isRatioGood`,
`ClassroomDetails.formatStudentTeacherRatioDisplay`). It is one of only two features in the repo
with a `mappers/` folder, its datasource returns typed models rather than raw maps, and three
defects the standard names by path are fixed: the `fromJson` on
`ratio_monitoring_classroom.dart` (§8.2d), the misspelled kebab-case `Toggel-Service/` directory
(§3.3), and the `views/` → `view/` rename that made classroom "the only `views/`" (§3.2).

The presentation layer has not moved at all. Navigation is effectively outside GoRouter: 15
`MaterialPageRoute` plus 15 `Navigator.push` against **zero** `context.push`, with no classroom
route constants in `app_routes.dart` — and unlike Attendance, none of these carries a documented
rationale. `classroom_info_screen.dart` resolves **six use cases as `State` fields** and has no
cubit of its own, which is the most direct Mandate 5 breach found in any module so far; its 12
`serviceLocator` calls are unchanged from the count the PDF recorded at the reference commit.
Typography is untouched — 59 inline `TextStyle(` and 57 literal `fontFamily: 'Manrope'` lines
against zero uses of `AppTextStyles` — even though colours are fully tokenised (193 `AppColors`,
zero raw `Colors.*`).

Two findings are live rather than structural. `CustomMultiSelectDropdown` exists in
`shared/common/widgets/` with 46 importers and a rich API, and
`classroom_students_tab_card.dart:1693` declares a **second class of the same name** with a
narrower constructor that silently shadows it in that file. And the two assign forms — the pair
`docs/mandate-rules.md` singles out as "two assign forms sharing 151 lines", now 167 — have
already drifted: `assign_student_to_classroom_form.dart:469` renders the tooltip "This Student
Jane Smith is already signed in", where its staff twin reads correctly. That is a user-visible
defect produced by the duplication the standard predicted.

The compounding risk is that **the module has zero tests** — no file under `test/` covers any
classroom file, against 16 for Activity and 49 for Attendance/Kiosk. Every remediation below
therefore runs unverified, which is why the order puts characterisation tests for the pure
logic first. `analysis_options.yaml` still has `flutter_lints` commented out, so none of these
33 findings currently fails a build.

---

## 3. Findings by mandate

### Mandate 1 — Navigation: GoRouter everywhere, MaterialPageRoute nowhere

**Verdict: Violated** (3 violations, highest High)

**What is compliant.** `ClassroomScreen` and `ClassroomOverviewScreen` are registered as real
`GoRoute` entries ([app_router.dart:229](lib/src/app_router.dart#L229),
[:656](lib/src/app_router.dart#L656)) and the module makes 5 `context.go` calls. The classroom
branch has its own navigator key ([app_router.dart:343](lib/src/app_router.dart#L343)). That is
the extent of it.

---

#### 1.1 — Fifteen `MaterialPageRoute` and fifteen `Navigator.push` sites, and zero `context.push`

**Rule broken.** MANDATE 1: *"No `Navigator.push`, `Navigator.of(context).push`, or
`MaterialPageRoute` anywhere under `lib/presentation`."* The only stated exemption is
*"Modals are exempt. `showDialog` and `showModalBottomSheet` are not route pushes."*

**Where.** 15 `MaterialPageRoute` across 4 files, each paired with a `Navigator.push`:

| File | Sites |
|---|---|
| [classroom_students_tab_card.dart](lib/presentation/features/classroom/view/classroom_tab_cards/classroom_students_tab_card.dart) | 456, 978, 1020, 1073, 1121, 1613 |
| [classroom_staff_tab_card.dart](lib/presentation/features/classroom/view/classroom_tab_cards/classroom_staff_tab_card.dart) | 616, 621, 626, 631, 738, 768 |
| [classroom_info_screen.dart](lib/presentation/features/classroom/view/screens/classroom_info_screen.dart) | 1068, 1098 |
| [classroom_screen.dart](lib/presentation/features/classroom/view/screens/classroom_screen.dart) | 514 |

```dart
// classroom_staff_tab_card.dart:614-631 — four attendance forms, four raw pushes
await Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => StaffSignInForm(staff: target)),
);
...
  MaterialPageRoute(builder: (_) => StaffSignOutForm(staff: target)),
...
  MaterialPageRoute(builder: (_) => StaffTransferForm(staff: target)),
...
  MaterialPageRoute(builder: (_) => StaffMarkAbsentForm(staff: target)),
```

```dart
// classroom_students_tab_card.dart:454-456 — a result-returning filter push
final result = await Navigator.push<ClassroomStudentFilterResult>(
  context,
  MaterialPageRoute(
```

**Why it violates.** The prohibition is unconditional and the modal exemption does not apply —
all fifteen push full screens. Two points make this the weakest navigation result of the three
modules audited. First, there are **zero** `context.push` calls anywhere in the module, so this
is not a partial migration but an unmigrated one. Second, unlike Attendance — where every raw
push carries an explicit `// GoRouter holdout (documented):` comment and a stated rationale —
grep for `holdout` or `GoRouter` across all 30 classroom presentation files returns **nothing**.
These are undocumented.

The four staff-form pushes at lines 614–631 are the sharpest case: they push
`StaffSignInForm`/`StaffSignOutForm`/`StaffTransferForm`/`StaffMarkAbsentForm`, which are
*attendance* module screens that already declare `routeName` statics of their own. Classroom
reaches into another feature's screens imperatively rather than routing to them.

**Severity: High.** Fifteen unguarded entry points into full screens, four of them into another
feature. The router's `redirect` — where the kiosk lock and any future role guard live — does not
run for any of them. Not Critical: `/classroom` is on the kiosk `blockedRoutesForKiosk` list, so
no kiosk-lock bypass was demonstrated.

**Fix.** Group the work. The four staff-form pushes should become `context.push` to the
attendance routes those forms already declare — this is the smallest change and removes the
cross-feature imperative coupling. The two result-returning filter pushes
(`ClassroomStudentFilterResult`, `ClassroomStaffFilterResult`) need a typed args class passed
through `extra` and the result returned via `context.pop(result)`; the Activity module's
`ActivityFilterArgs` is the in-repo template. The remainder are plain screen pushes and convert
directly once §1.2 gives them route constants.

---

#### 1.2 — No classroom route constants; one inline path on a screen class

**Rule broken.** MANDATE 1: *"Route paths and names live as constants in
`lib/core/router/app_routes.dart`."*

**Where.** Grepping `app_routes.dart` for "classroom" returns exactly one line, and it is a
comment about a *staff* filter sheet:

```dart
// core/router/app_routes.dart:132
/// The shared staff filter sheet, also opened from attendance and classroom.
```

The module declares one route path, inline, on the screen class:

```dart
// classroom_info_screen.dart:65
static const String routeName = '/classroom-info-screen';
```

`ClassroomScreen.routeName` and `ClassroomOverviewScreen.routeName` are likewise defined on their
screen classes and referenced *from* the router
([app_router.dart:229](lib/src/app_router.dart#L229),
[:656](lib/src/app_router.dart#L656)) — the router depends on presentation for its addressing,
the inverse of the intended direction.

**Why it violates.** The mandate wants one file to be the list of route paths. For this module
that file has no entries at all. Compare Attendance, which has a `DashboardRoutes` block with
four classroom-adjacent constants, and Kiosk, which has a documented `KioskRoutes` class.

**Severity: Medium.** No runtime effect. It is the precondition for §1.1 — the pushes cannot be
converted until the destinations have addresses.

**Fix.** Add a `ClassroomRoutes` block to `app_routes.dart` covering the screens reached in §1.1,
and have `app_router.dart` and the screens reference the constants rather than the reverse. Add
only this module's routes, per the mandate's instruction not to lift all 56 at once.

---

#### 1.3 — `..loadActiveClassrooms()` cascaded inside `BlocProvider.create` in `build()`

**Rule broken.** MANDATE 1, §5.4 caution: *"an `..load()` inside a `GoRoute` builder re-runs on
every navigation to that route, including back navigation. Use the builder for construction and
trigger the load once, or you will double-fire the API. This has already caused duplicate-call
bugs in this codebase."*

**Where.** Three sites, and the classroom ones are inside a widget `build()` rather than a route
builder — which re-runs more often, not less:

```dart
// classroom_info_screen.dart:833-837 — inside build()
Widget build(BuildContext context) {
  return BlocProvider<ClassroomCubit>(
    create: (_) =>
        serviceLocator<ClassroomCubit>()
          ..loadActiveClassrooms(applyAttendanceStaffScope: true),

// classroom_info_screen.dart:1074-1079 — inside a MaterialPageRoute builder
BlocProvider<ClassroomCubit>(
  create: (_) => serviceLocator<ClassroomCubit>()
    ..loadActiveClassrooms(
      onlyTypeClassroom: false,
      applyAttendanceStaffScope: true,
    ),

// classroom_info_screen.dart:69-70
return BlocProvider<IndividualMovementsCubit>(
  create: (_) => serviceLocator<IndividualMovementsCubit>()..loadInitial(),
```

The same pattern appears in the shared router for this module's cubit
([app_router.dart:1047-1049](lib/src/app_router.dart#L1047-L1049),
[:1112-1115](lib/src/app_router.dart#L1112-L1115),
[:1189-1193](lib/src/app_router.dart#L1189-L1193)).

**Why it violates.** The mandate names this pattern as an established source of duplicate-call
bugs. `BlocProvider.create` is called when the provider is inserted into the tree, so a rebuild
that re-creates the provider re-fires the load. `ClassroomCubit.loadActiveClassrooms` has an
internal guard (`if (state.isLoading) return;` and an early return when the cached list matches
at [classroom_cubit.dart:89-95](lib/presentation/features/classroom/view_model/classroom_cubit.dart#L89-L95)),
which is why this is not currently producing visible duplicate traffic — but that guard is
defence in the cubit, not compliance in the caller, and it does not cover the
`IndividualMovementsCubit..loadInitial()` at line 70.

**Severity: High.** The mandate calls this out by name as a known bug class, it appears three
times in one file, and only one of the three cubits involved has a guard.

**Fix.** Construct in the builder, trigger the load once — from the cubit constructor or a single
`BlocProvider create` outside `build()`. Verify the network call count entering the screen and
returning to it is unchanged; the guard makes a regression here silent.

---

### Mandate 2 — State: setState scarcely, ValueNotifier for UI micro-state

**Verdict: Violated** (3 violations, highest High)

Measured: **82 `setState` calls across 9 files**; 15 `StatefulWidget` vs 24 `StatelessWidget`;
17 `BlocBuilder`; **0** `BlocSelector`; 3 `ValueNotifier`; **0** `ValueListenableBuilder`.

**What is compliant.** The `view_model/` folder holds 7 genuine cubit/state pairs, and they are
well-built: real `Equatable` state with `copyWith`, `isClosed` guards before every `emit`, use
cases injected rather than resolved, and no `BuildContext` anywhere. `AssignStaffConfirmationCubit`,
`AssignStudentConfirmationCubit`, `ClassroomCubit`, `ClassroomStaffCubit` and
`ClassroomStudentsCubit` are the shape the mandate asks for. The assign flow in particular is
properly layered.

---

#### 2.1 — Bucket A state held in widget `State`, on a screen with no cubit at all

**Rule broken.** MANDATE 2, Bucket A: *"API results, loading flags, filters, form submission,
selections that outlive the widget → Cubit"*, and *"Bucket A is 'no exceptions' — if it survives
a parent rebuild, is read by more than one widget, or comes from an API, it is Cubit state."*

**Where.** 82 `setState` calls, concentrated in four files that have no cubit of their own:

| File | `setState` | Has own cubit? |
|---|---|---|
| `classroom_students_tab_card.dart` | 21 | No |
| `classroom_info_screen.dart` | 20 | **No** |
| `classroom_staff_tab_card.dart` | 13 | No |
| `classroom_screen.dart` | 12 | No |

`classroom_info_screen.dart` is the clearest case — a 1,362-line `StatefulWidget` holding
API-derived state directly:

```dart
// classroom_info_screen.dart:95-115
bool _isAllClassroomApisLoading = false;
String? _detailsError;
...
StudentAttendanceExpectedSummary? _studentSummary;
StudentAttendanceExpectedSummary? _staffSummary;
String? _summaryError;
```

```dart
// classroom_info_screen.dart:298-302 — API/cache result straight into setState
setState(() {
  _enrolledActiveCount = (map['activeCount'] as num?)?.toInt() ?? 0;
  _enrolledUpcomingCount = (map['upcomingCount'] as num?)?.toInt() ?? 0;
  _enrolledCount = (map['enrolledCount'] as num?)?.toInt() ?? 0;
});

// classroom_info_screen.dart:147-149 — selection that outlives the widget
setState(() {
  _selectedRoom = initialClassroom;
});
```

**Why it violates.** Loading flags, error strings, attendance summaries and enrolled counts are
all Bucket A by the mandate's own test — they come from an API and survive parent rebuilds. The
aggravating fact is structural: this screen calls six use cases directly (§5.1) and stores every
result in `State`, so there is no view model anywhere on the path. The module *has* a working
cubit pattern seven files away in `view_model/`; these four screens simply do not use it.

**Severity: High.** A "no exceptions" rule broken on the module's four largest screens, one of
which has no view-model layer at all.

**Fix.** `classroom_info_screen.dart` needs a `ClassroomInfoCubit` that owns the six use-case
calls and the resulting state — this fixes §2.1 and §5.1 together and is the single highest-value
change in the module. For the two tab cards and `classroom_screen.dart`, extend the existing
`ClassroomStudentsCubit` / `ClassroomStaffCubit` states rather than adding new cubits. Move one
field group per change. Heed the mandate's warning: moving selections into a cubit may newly
*preserve* them across navigation where they previously reset — flag that rather than shipping it
silently.

---

#### 2.2 — Three `ValueNotifier`s and zero `ValueListenableBuilder`s

**Rule broken.** MANDATE 2: *"If the state is owned by one widget, never read by anything outside
it, and would be thrown away on navigation, use `ValueNotifier` with `ValueListenableBuilder`."*
And: *"`ValueListenableBuilder` takes a `child:` that is built once and handed to the builder
untouched. **Use it.**"*

**Where.** 3 `ValueNotifier` declarations, **0** `ValueListenableBuilder` anywhere in the 30
presentation files.

**Why it violates.** Bucket B has essentially no representation in this module while 82
`setState` calls exist. Several of those are genuine UI micro-state — expand/collapse, chip
selection, dropdown open/closed — which the mandate routes to `ValueNotifier` +
`ValueListenableBuilder` specifically so the surrounding subtree stops rebuilding.

**Severity: Low.** No defect; it marks unconverted Bucket B state rather than an incorrect
conversion.

**Fix.** During the §2.1 work, classify each remaining `setState` into the mandate's three buckets
and convert the Bucket B ones to `ValueNotifier` + `ValueListenableBuilder` **with** `child:`.

---

#### 2.3 — Zero `BlocSelector` across 17 `BlocBuilder`s

**Rule broken.** MANDATE 2: *"Use `BlocSelector` where only a small part of the UI depends on one
state property."*

**Where.** 17 `BlocBuilder` usages, 0 `BlocSelector`. The states involved are wide —
`ClassroomStudentsState` (93 lines) and `ClassroomStaffState` (76 lines) back tab cards of 1,853
and 1,438 lines.

**Why it violates.** Every `BlocBuilder` rebuilds its whole subtree on any state change, and here
the subtrees are among the largest in the module.

**Severity: Low.** A performance rule rather than a correctness one.

**Fix.** Apply `BlocSelector` opportunistically as part of §2.1, at the sites where one small
widget reads one property — counts, button enablement, filter chips. Not worth a dedicated sweep.

---

### Mandate 3 — Folder structure, followed strictly

**Verdict: Violated** (5 violations, highest High)

**What is compliant, and it includes three fixes the standard asked for by name.** The PDF §3.2
records *"classroom is the only `views/`"* — the directory is now `view/`. PDF §3.3 names
`classroom/views/classroom_tab_cards/Toggel-Service/` (kebab-case, with a typo for "toggle") and
`.../Toggel-Service/toogel-api-service.dart` (a second spelling of the same typo) — searching the
tree for `toggel`, `toogel` or `napping` returns nothing; both are gone. The module uses the
canonical `view_model/` name, its domain entities are pure Dart with no Flutter imports, and
`lib/data/features/classroom/` has a **`mappers/` folder** — making it one of the two features
the PDF says have one.

---

#### 3.1 — A forbidden `utils/` folder holding business rules, importing another feature's presentation layer

**Rule broken.** MANDATE 3: *"A presentation `util/` or `utils/` folder should not exist. Pure
business rules go to `domain/features/<x>/usecases/` or a domain service; mappers go to
`data/features/<x>/mappers/`; presentation helpers go to `widgets/` or `core/extensions/`."*

**Where.** [lib/presentation/features/classroom/utils/classroom_age_range.dart](lib/presentation/features/classroom/utils/classroom_age_range.dart)
— the folder's only file, 90 lines of pure age-vs-range business rules:

```dart
// utils/classroom_age_range.dart:1-2
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_school_time.dart';

// :20-26
int ageInCompletedMonths(DateTime birthDate, {DateTime? reference}) {
  final ref = reference ?? attendanceSchoolToday();
  var months = (ref.year - birthDate.year) * 12 + (ref.month - birthDate.month);
  if (ref.day < birthDate.day) months -= 1;
  return months < 0 ? 0 : months;
}

// :55-71
String? classroomAgeRangeWarning({ required Classroom classroom, ... }) {
```

**Why it violates.** Three things at once. The folder name is explicitly forbidden. Its contents
are business rules, not presentation helpers — the file's own doc comment says they are
*"Deliberately identical to the web client so the two platforms never disagree about who is 'out
of range'"*, which is the definition of a domain rule. And line 2 imports **another feature's
presentation `view_model/`** (`attendance/view_model/attendance_school_time.dart`), so a
classroom business rule depends on the attendance module's presentation layer — a dependency the
layer model has no place for. `docs/mandate-rules.md` names `classroom_age_range.dart` explicitly
as one of the pure-logic files that should get characterisation tests before Mandate 6 touches it;
it currently has none (see §6.3 and the risk assessment).

**Severity: High.** A forbidden folder holding a cross-platform business rule, reaching into
another feature's presentation layer, with zero test coverage.

**Fix.** Move the rules to `domain/features/classroom/` as a service or use cases, taking
"school today" as an injected parameter rather than importing the attendance helper — the
functions already accept an optional `reference` argument, so the seam exists. Write
characterisation tests first, per `docs/mandate-rules.md`. This also removes the cross-feature
presentation import in one move.

---

#### 3.2 — A non-canonical `forms/` folder at the feature root

**Rule broken.** MANDATE 3, canonical presentation layout:
```
presentation/features/<feature>/
  model/  view/  view_model/  widgets/
```

**Where.** [lib/presentation/features/classroom/forms/](lib/presentation/features/classroom/forms/)
holds `assign_staff_to_classroom_form.dart` (512), `assign_student_to_classroom_form.dart` (547),
`date_picker_normal.dart` (34), plus a nested
[forms/widgets/assign_classroom_form_widgets.dart](lib/presentation/features/classroom/forms/widgets/assign_classroom_form_widgets.dart) (227).

**Why it violates.** `forms/` is not one of the four canonical folders. The two assign forms are
screens and belong in `view/`; `date_picker_normal.dart` and the form widgets belong in
`widgets/`. The PDF's §6.3 analysis of the attendance module's `attendance/forms/` directory
records that it was dissolved for exactly this reason — and the attendance audit confirms it now
lives under `view/staff_attendance_forms/` and `view/student_attendance_forms/`. Classroom kept
the pattern the sibling module abandoned.

**Severity: Medium.** No runtime effect; it puts two 500-line screens outside the directory every
path-scoped check and reviewer looks in.

**Fix.** Move the two form screens to `view/`, and the picker and shared form widgets to a
feature-root `widgets/` (created by §3.3). Import-only moves with no behaviour change.

---

#### 3.3 — No `model/` folder, and widgets nested under `view/` instead of at the feature root

**Rule broken.** MANDATE 3: *"`model/` # screen params, UI config, route arg classes"* and
*"`widgets/` # this feature only; shared goes to `core/widgets/`"* — both siblings of `view/`.

**Where.** The feature has no `model/` directory at all, and its widgets live at
[view/widgets/](lib/presentation/features/classroom/view/widgets/) (2 files) plus
[forms/widgets/](lib/presentation/features/classroom/forms/widgets/) (1 file) — two widget
locations, neither at the feature root.

The missing `model/` is why §1.1's filter pushes have nowhere to declare typed route arguments:
`ClassroomStudentFilterResult` and `ClassroomStaffFilterResult` are declared inside the filter
screen files rather than in a `model/` folder.

**Severity: Medium.** Structural; it is the direct obstacle to §1.1's typed-args conversion.

**Fix.** Create `model/` and move the two filter-result classes into it alongside the route args
§1.1 needs. Consolidate `view/widgets/` and `forms/widgets/` into a feature-root `widgets/`.

---

#### 3.4 — Classroom code living outside MODULE_PATH

**Rule broken.** MANDATE 3: *"Pure business rules go to `domain/features/<x>/usecases/` or a
domain service."* GUARDRAIL 2 (module ownership).

**Where.**

| File | What it is |
|---|---|
| [core/utils/classroom_visibility.dart](lib/core/utils/classroom_visibility.dart) | `filterSelectableClassrooms` — the "hide Office" rule, called from [classroom_cubit.dart:155](lib/presentation/features/classroom/view_model/classroom_cubit.dart#L155) |
| [core/utils/attendance_classroom_scope.dart](lib/core/utils/attendance_classroom_scope.dart) | Classroom scoping rules (382 lines, 24 importers); classroom_cubit calls `isAttendanceScopedStaffPersona` and `resolveAttendanceAllowedClassroomCodes` |
| [shared/common/widgets/classroom_selection_widget_exact.dart](lib/shared/common/widgets/classroom_selection_widget_exact.dart) | A classroom selection widget in the shared library |

**Why it violates.** `filterSelectableClassrooms` is a classroom visibility rule sitting in
`core/utils` rather than in the classroom domain. `attendance_classroom_scope.dart` was already
flagged in `attendance-kiosk-module-audit.md` §3.2 as attendance business logic in `core/utils`;
it is recorded here because the classroom cubit is one of its callers and the two modules will
need to agree on where it lands. The `_exact` suffix on the shared widget is a naming smell that
usually marks a pinned copy of something.

**Severity: Medium.** No defect; it is module logic outside the module, and one file is
co-owned with attendance.

**Fix.** Move `classroom_visibility.dart` into `domain/features/classroom/` as a rule — small and
self-contained. Coordinate `attendance_classroom_scope.dart` with the attendance module's
remediation rather than moving it unilaterally; both audits list it.

---

#### 3.5 — Cross-folder relative imports

**Rule broken.** MANDATE 3, Imports: *"all cross-folder imports use `package:wowcare/...`.
Relative imports only within the same folder."*

**Where.** The `view_model/` and data-layer files use `../../../../` consistently:

```dart
// view_model/classroom_cubit.dart:3-9
import '../../../../core/utils/attendance_classroom_scope.dart';
import '../../../../core/utils/cache_manager.dart';
import '../../../../core/utils/classroom_visibility.dart';
import '../../../../core/storage/storage_service.dart';
...
import '../../../../domain/features/classroom/entities/classroom.dart';
```

**Why it violates.** Cross-folder imports must use the `package:` form. Note the specific hazard
§3.4 describes — an import with one excess `..` segment compiles in the app but breaks the moment
a test reaches the file by `file:` URI. **I resolved every relative import in the module against
the filesystem and all of them point at a real file**, so that latent breakage is absent. Given
§6.3's zero test coverage, no test currently reaches these files by any route.

**Severity: Low.** No broken imports; mechanical consistency only.

**Fix.** Single codemod converting `../`-crossing imports to `package:wowcare/...`, leaving
same-folder relative imports alone. Run after §3.1–§3.3 have moved files, not before.

---

### Mandate 4 — Centralized theming, constants, strings, colors, fonts, sizes

**Verdict: Partially violated** (4 violations, highest High)

The result splits by concern:

| Check | Count | Status |
|---|---|---|
| `Color(0x...)` | **0** | Compliant |
| Raw `Colors.<name>` | **0** | Compliant |
| `AppColors.` uses | 193 | — |
| Inline `TextStyle(` | **59** | Violated |
| `fontFamily: 'Manrope'` | **57** | Violated |
| `AppTextStyles.` uses | **0** | Violated |
| `AppStrings.` uses | **0** | Violated |
| `AppSpacing`/`AppRadius`/`AppDimensions`/`AppSizes` uses | **0** | Violated |

**Colour is done.** Zero raw colours and 193 `AppColors` references, including semantic tokens
the module added (`AppColors.classroomPositiveStatusColor`,
`AppColors.classroomNegativeStatusColor`, `AppColors.classroomRatioHeaderSubtextColor`). That is
the half of Mandate 4 the PDF describes as the long pole, and it is finished here.

---

#### 4.1 — 59 inline `TextStyle(` constructors and zero `AppTextStyles` uses

**Rule broken.** MANDATE 4: *"No inline `TextStyle(`. Use `Theme.of(context).textTheme.<slot>`
or a named `AppTextStyles` entry; local variation uses `.copyWith()` on a named style, never a
fresh `TextStyle`."*

**Where.** 59 inline constructors across 12 files:
`classroom_overview_screen.dart` 11, `classroom_students_tab_card.dart` 11,
`classroom_staff_tab_card.dart` 9, `classroom_info_screen.dart` 7,
`classroom_student_list_item.dart` 5, `assign_classroom_form_widgets.dart` 5,
`assign_student_to_classroom_form.dart` 3, `assign_staff_to_classroom_form.dart` 3,
`classroom_dropdown.dart` 2, and one each in three more.

```dart
// classroom_overview_screen.dart:481-486
style: TextStyle(
  color: AppColors.primaryColor,
  fontSize: 16,
  fontWeight: FontWeight.w700,
  fontFamily: 'Manrope',
),
```

`AppTextStyles.` appears **0 times**, though
[core/theme/app_text_styles.dart](lib/core/theme/app_text_styles.dart) is 1,319 lines and has
**70 importers** app-wide. Also zero uses of `Theme.of(context).textTheme`.

**Why it violates.** The rule names both destinations and the module uses neither. Each
hand-written style restates every property, so it tracks nothing: the §4.6 consequence is that a
later letter-spacing or brand-font change reaches the theme and not these 59 sites. The
`fontWeight`/`fontSize` pairs repeat across files with no shared name.

**Severity: High.** A whole typography layer outside the theme system, in a module whose colours
are fully tokenised — so a theme change produces a half-updated screen, which is harder to spot
than a wholly-unmigrated one.

**Fix.** Add named `AppTextStyles` entries for the repeated combinations (there are far fewer
distinct styles than 59 sites) and replace the inline constructors, using `.copyWith()` for local
variation. Rendered output must be identical: where a size/weight pair has no matching named
style, add the entry with those exact values rather than snapping to the nearest existing one, and
list every style added.

---

#### 4.2 — 57 literal `fontFamily: 'Manrope'` lines

**Rule broken.** MANDATE 4: *"No `fontFamily: 'Manrope'`. The family is already on `ThemeData` —
these lines are a find-and-delete."*

**Where.** All 57 occurrences are the raw string, not the `Fonts.manrope` token:

```
57 × fontFamily: 'Manrope'
```

```dart
// classroom_overview_screen.dart:449-452
style: TextStyle(
  color: AppColors.primaryColor.withValues(alpha: 0.8),
  fontSize: 13,
  fontFamily: 'Manrope',
),
```

**Why it violates.** This is the rule's literal case — the PDF describes the app-wide equivalent
as *"a single find and delete"* because `ThemeData` already sets the family and `TextStyle`
inherits it. Unlike the Activity module's three `fontFamily` lines (which sit in `StrutStyle`,
where inheritance genuinely does not apply — see `activity-module-audit.md` §4.3), **all 57 here
are inside `TextStyle`**, so deletion is safe and behaviour-preserving.

**Severity: Medium.** Zero-risk to fix and mechanically bounded, but 57 sites is the largest
single count of this violation found in any module audited.

**Fix.** Delete the 57 lines. Do it **after** §4.1, since converting to named `AppTextStyles`
entries removes most of them as a side effect and deleting first would mean touching the same
lines twice. Verify the rendered font is unchanged — this is the one check that matters.

---

#### 4.3 — `AppStrings` is never used; ~55 user-visible literals

**Rule broken.** MANDATE 4: *"No user-visible string literal in a view file. Everything through
`AppStrings` (`lib/core/constants/app_strings.dart`)."*

**Where.** `AppStrings.` appears **0 times**. Measured: 5 `Text('literal')` and 50
`message:`/`title:`/`label:`/`hintText:` literals. User-visible copy also sits in the cubits and
in domain entities:

```dart
// view_model/assign_staff_confirmation_cubit.dart:35, 44, 57
throw 'Please select at least one staff member';
throw 'Missing schoolCode. Please sign in / select a school again.';
return message.isEmpty ? 'Assigned successfully' : message;

// utils/classroom_age_range.dart:70
return "$who is outside the classroom's age range. Do you want to continue?";

// domain/.../classroom_details.dart:55, 81
if (minPart.isEmpty && maxPart.isEmpty) return 'No Age Limit';
if (studentsPerTeacher <= 0) return '—';
```

**Why it violates.** The rule is absolute for view files, and the infrastructure exists and is
used by 17 files elsewhere in the app. The cubit and entity cases are outside the rule's literal
wording (it names view files) — noted here for completeness and raised in **Open questions**.

**Severity: Medium.** No functional risk; it blocks localisation, which the standard names as the
main reason to do Mandate 4 properly.

**Fix.** Extract the view-file literals to `AppStrings` first — that is what the rule requires.
Apply the mandate's exclusion: skip log tags, storage keys, API payload keys and backend enum
values (`'SIGNED_IN'`, `'ABSENT'`, `'CLASSROOM'`, `'ADMIN'` are wire values and must stay).
Decide separately whether cubit-thrown and entity-returned copy is in scope.

---

#### 4.4 — 198 magic spacing and radius literals, and no spacing token family in use

**Rule broken.** MANDATE 4: *"No magic spacing. `AppSizes` (`lib/core/constants/app_sizes.dart`)."*

**Where.** Measured with a balanced-parenthesis parser that excludes token references: **198**
magic spacing/radius literals across the 30 presentation files. The module uses **neither**
available token family — `AppSizes.` 0 uses, `AppSpacing`/`AppRadius`/`AppDimensions` 0 uses.

```dart
// classroom_overview_screen.dart:150
padding: const EdgeInsets.all(8),
```

**Why it violates.** This is a stronger finding than the equivalent in the other two modules.
Activity uses `AppSizes` zero times but so does everything in its layer; Attendance uses
`AppSpacing` ~400 times and only has stragglers. Classroom uses no spacing token family at all,
so every one of the 198 values is hand-written.

**Severity: Medium.** Cosmetic drift, but unmitigated — there is no partial adoption to build on.

**Fix.** Blocked on the app-wide `AppSizes` vs `AppSpacing` decision (see **Open questions** and
`attendance-kiosk-module-audit.md` §4.4). Once settled, sweep per file, adding tokens for values
with no match rather than substituting the nearest — rendered output must be identical.

---

### Mandate 5 — Presentation talks to cubits only

**Verdict: Violated** (4 violations, highest High)

Measured: **38 `serviceLocator<T>()` calls** in presentation; **1** `StreamBuilder`; **0**
`DataSource`/`Repository`/`RepositoryImpl` types named anywhere in presentation.

**What is compliant.** No datasource or repository type appears in any presentation file — the
§5.2a violation class ("a view calling a datasource") is absent, and there are no `Dio` or
`ApiClient` references either. The seven cubits in `view_model/` all receive their use cases
through constructor injection rather than resolving them.

---

#### 5.1 — Six use cases resolved as `State` fields on a screen with no cubit

**Rule broken.** MANDATE 5: *"A view file may reference exactly three things from outside itself:
its own Cubit (via `context.read<T>()` / `BlocBuilder` / `BlocSelector`), widgets, and constants.
Nothing else."* Forbidden explicitly: *"direct use-case invocation from a view"*. PDF §5.1
tabulates `classroom/views/screens/classroom_info_screen.dart` at **12** `serviceLocator` calls.

**Where.** [classroom_info_screen.dart:97-112](lib/presentation/features/classroom/view/screens/classroom_info_screen.dart#L97-L112)
— six use cases as instance fields on the `State` class:

```dart
final GetClassroomByCodeUseCase _getClassroomByCodeUseCase =
    serviceLocator<GetClassroomByCodeUseCase>();
final GetStudentAttendanceExpectedSummaryUseCase
_getStudentAttendanceExpectedSummaryUseCase =
    serviceLocator<GetStudentAttendanceExpectedSummaryUseCase>();
final GetStudentClassroomEnrolledCountUseCase
_getStudentClassroomEnrolledCountUseCase =
    serviceLocator<GetStudentClassroomEnrolledCountUseCase>();
final CreateClassroomLogoUploadSessionUseCase
_createClassroomLogoUploadSessionUseCase =
    serviceLocator<CreateClassroomLogoUploadSessionUseCase>();
final FinalizeClassroomLogoUseCase _finalizeClassroomLogoUseCase =
    serviceLocator<FinalizeClassroomLogoUseCase>();
final GetStaffAttendanceExpectedSummaryUseCase
_getStaffAttendanceExpectedSummaryUseCase =
    serviceLocator<GetStaffAttendanceExpectedSummaryUseCase>();
```

The module resolves **17 use cases** from views in total, across five files —
`classroom_staff_tab_card.dart` (4 attendance form-list use cases at lines 511, 537, 561, and
one more), `classroom_students_tab_card.dart` (4), `classroom_notes_tab_card.dart`
(`GetOrCreateClassroomChatUseCase` at 75 and 166), and
`classroom_student_filter_screen.dart:59,67,94`:

```dart
// view/filters/classroom_student_filter_screen.dart:59-94
late final GetTagNameCodeMapForSchoolUseCase _tagMapUseCase;
...
_tagMapUseCase = serviceLocator<GetTagNameCodeMapForSchoolUseCase>();
...
final map = await _tagMapUseCase(schoolCode: schoolCode);
```

**Why it violates.** `classroom_info_screen.dart` is a 1,362-line screen wired directly to the
domain layer with no view model on the path — the flow is `View → UseCase`, skipping the Cubit
the mandate places between them. This is the most direct Mandate 5 breach found across the three
modules audited: Activity had one direct use-case call from a view, Attendance had a handful,
Classroom has seventeen. The count of 12 `serviceLocator` calls in this file is **unchanged**
from the PDF's reference-commit measurement.

**Severity: High.** A whole screen bypassing the view-model layer, on the module's central screen,
recorded by the standard and unmoved since.

**Fix.** Introduce a `ClassroomInfoCubit` owning the six use cases and the state they produce —
this closes §2.1 and §5.1 together and is the module's highest-value single change. For the
tab cards and filter screen, extend the existing `ClassroomStudentsCubit` /
`ClassroomStaffCubit`, or add narrow cubits where none fits. Verify the network call count
entering and returning to each screen is unchanged.

---

#### 5.2 — `StorageService` and `ImageUploadService` resolved inside views

**Rule broken.** MANDATE 5, forbidden anywhere under `lib/presentation`: *"`DataSource`,
`Repository`, `RepositoryImpl`, `ApiClient`, `Dio`, `StorageService`, `SharedPreferences`
types"*, and *"direct network or platform calls (including `path_provider` and friends — put
them behind an injected service)"*.

**Where.**

```dart
// view/screens/classroom_info_screen.dart:126, 139-140
late final StorageService _storage;
...
_storage = serviceLocator<StorageService>();
_cacheManager = CacheManager(_storage);

// view/screens/classroom_info_screen.dart:540 — mid-method, in an upload handler
final uploadService = serviceLocator<ImageUploadService>();

// view/filters/classroom_student_filter_screen.dart:60, 68
late final StorageService _storageService;
_storageService = serviceLocator<StorageService>();

// view/screens/classroom_screen.dart:279
final storage = serviceLocator<StorageService>();
```

`StorageService` is also a constructor field on six cubits (`classroom_cubit.dart:16,23`,
`classroom_students_cubit.dart:29,41`, `classroom_staff_cubit.dart:27,37`,
`assign_staff_selection_cubit.dart:25,37`, `assign_student_selection_cubit.dart:27,41`,
`assign_staff_confirmation_cubit.dart:13,19`, `assign_student_confirmation_cubit.dart:18,26`).

**Why it violates.** The prohibition is on the type appearing anywhere under `lib/presentation`.
The view cases are the sharper ones: `classroom_info_screen.dart` builds a `CacheManager` over
raw storage and reads and writes the disk cache itself (§8.2), and resolves the image-upload
service inside a method body to run a logo upload from the view.

**Severity: High.** A view performing its own cache I/O and driving an upload service, on the
same screen as §5.1.

**Fix.** The `ClassroomInfoCubit` from §5.1 absorbs the storage, cache and upload-service
dependencies. For the six cubits, introduce narrow domain services for what they actually read —
school code, persona scope — so each depends on an abstraction rather than the storage layer.
Take the three view-level sites first; they are the clearest breach and the smallest change.

---

#### 5.3 — 38 `serviceLocator` calls, including cubit construction inside `build()`

**Rule broken.** MANDATE 5: *"No `serviceLocator<T>()` in `lib/presentation`. Cubits are created
in the router, in the `GoRoute` builder, wrapped in a `BlocProvider`. That is the only place the
service locator appears on the presentation side."* PDF §5.2c names cubit-construction-in-view.

**Where.** 38 calls across 10 files. Beyond §5.1 and §5.2, nine resolve cubits:

```dart
// classroom_info_screen.dart:69-70 — in build()
return BlocProvider<IndividualMovementsCubit>(
  create: (_) => serviceLocator<IndividualMovementsCubit>()..loadInitial(),

// classroom_info_screen.dart:1071-1075 — in a MaterialPageRoute builder
BlocProvider<StudentCubit>(
  create: (_) => serviceLocator<StudentCubit>()..loadInitial(),
),
BlocProvider<ClassroomCubit>(
  create: (_) => serviceLocator<ClassroomCubit>()
```

`ClassroomCubit` is resolved 4 times from views, plus 4 more `Assign*Cubit` resolutions in the
forms and 1 each for `ClassroomStudentsCubit` / `ClassroomStaffCubit`.

**Why it violates.** The rule permits `serviceLocator` in exactly one place — the `GoRoute`
builder. None of these is in one; several are inside `build()`, and two are inside a
`MaterialPageRoute` builder that §1.1 says should not exist.

**Severity: High.** 38 breaches of a rule with a single permitted location, and the placement
inside `build()` compounds §1.3's re-fire problem.

**Fix.** Move cubit creation into `GoRoute` builders as part of §1.1's conversion — the two are
one piece of work, which is why `docs/mandate-rules.md` says to *"Do 1 and 5 as a pair"*.
Heed §5.4: verify no double-loading once the loads move.

---

#### 5.4 — A `StreamBuilder` in a view

**Rule broken.** MANDATE 5: *"No `FutureBuilder` / `StreamBuilder` over data the cubit already
owns."*

**Where.** [classroom_screen.dart:373](lib/presentation/features/classroom/view/screens/classroom_screen.dart#L373)

```dart
Tab _builtNotesTab({required String label, required Color color}) {
  return Tab(
    child: StreamBuilder<int>(
      stream: getClassroomNotesUnreadCountStream(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final unreadCount = snapshot.data ?? 0;
```

**Why it violates — with a caveat.** The rule's stated target is a builder *"over data the cubit
already owns"*, creating a second source of truth. Here the unread count is not held by any
classroom cubit — the stream is the only source — so this is not a duplicate source of truth. It
is still a view subscribing directly to a data stream rather than receiving state from its cubit,
which the flow `View → Cubit → UseCase` does not allow.

**Severity: Medium.** No divergence risk today because nothing else owns this value; the issue is
that the view owns a subscription.

**Fix.** Have `classroom_screen.dart`'s cubit expose the unread count as state and subscribe to
the stream itself, cancelling in `close()`. The screen then renders from `BlocBuilder`. Confirm
the badge still updates live and that the subscription is cancelled when the screen leaves the
tree.

---

### Mandate 6 — Reuse what exists; pure functions out of build()

**Verdict: Violated** (6 violations, highest High)

**What is compliant.** Real business logic lives on the domain entities where the mandate wants
it, not inside `build()`: `Classroom.isAgeOutsideRange`,
`ClassroomDetails.ageRangeCompactDisplay`, `ClassroomDetails.formatStudentTeacherRatioDisplay`
(including a continued-fraction reduction for non-integer ratios), and
`RatioMonitoringClassroom.isRatioGood` with its four-case evaluation order documented. This is
the §6.4a pattern done correctly, and it is better than either module audited before.

---

#### 6.1 — A shared widget is shadowed by a narrower local copy of the same name

**Rule broken.** MANDATE 6: *"Before writing a widget, search `core/widgets/`,
`shared/common/widgets/` and the feature's own `widgets/`. Extend with a parameter rather than
copying."* And: *"**No two classes in the codebase share a name.** Diff each collision before
merging — copies with the same name often have different constructors and are not
interchangeable."*

**Where.** [classroom_students_tab_card.dart:1693](lib/presentation/features/classroom/view/classroom_tab_cards/classroom_students_tab_card.dart#L1693)
declares `CustomMultiSelectDropdown`, and so does
[shared/common/widgets/custom_multi_select_dropdown.dart:5](lib/shared/common/widgets/custom_multi_select_dropdown.dart#L5).
The private `_CustomMultiSelectDropdownState` collides too (local line 1716, shared line 46). The
classroom file does **not** import the shared widget — grep for `custom_multi_select_dropdown` in
it returns nothing — so within that 1,853-line file the name resolves to the local copy.

The two constructors are not equivalent:

```dart
// LOCAL copy — classroom_students_tab_card.dart:1693
class CustomMultiSelectDropdown extends StatefulWidget {
  final String hintText;
  final List<String> items;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;
  final bool isField;
  final double? width;
  const CustomMultiSelectDropdown({ Key? key, ... }) : super(key: key);
```

```dart
// SHARED original — shared/common/widgets/custom_multi_select_dropdown.dart:5
class CustomMultiSelectDropdown extends StatefulWidget {
  final String? label;
  final String? suffix;
  final String hintText;
  ...
  final double? labelBottomSpacing;
  final double gapHeight;
  final double maxDropdownHeight;
  final bool showSelectAll;
  final bool enableSearch;
  final String? searchHintText;
  final bool isRequired;
```

The shared version has **46 importers** and offers `showSelectAll`, `enableSearch`,
`searchHintText`, `isRequired`, `label`, `suffix` and three sizing parameters that the local copy
does not.

**Why it violates.** This is the §6.6 hazard exactly: *"A developer who searches for
[the class] and reasonably reuses the one that is easiest to find can hit a constructor mismatch
the moment they try to pass it the object they actually have, because the name is shared and the
shape is not."* Here it is worse than a mismatch — the local declaration shadows the shared one
silently, so a developer adding `enableSearch:` inside this file gets a compile error against a
widget they believe supports it, and the classroom students filter cannot offer select-all or
search while 46 other call sites can.

**Severity: High.** A shared widget with 46 importers reimplemented under an identical name with
a strictly smaller API, in the module's largest file.

**Fix.** Delete the local copy and import the shared widget, passing the parameters the local
call sites already use (the shared constructor is a superset, so the call sites compile
unchanged). Verify the dropdown's appearance and behaviour are unchanged — the shared version's
extra features default off, but confirm `isField` and `width` map across. Also rename the
colliding private State class if any local variant survives.

---

#### 6.2 — `StaffListItem` duplicated with an incompatible constructor

**Rule broken.** MANDATE 6: *"**No two classes in the codebase share a name.**"* PDF §6.1
tabulates `StaffListItem` at 6 copies, one of them
`classroom/forms/assign_staff_to_classroom_form.dart`; §6.6 uses this exact class as its worked
example.

**Where.** Two survive app-wide, and one is this module's:

```dart
// classroom/forms/assign_staff_to_classroom_form.dart:396 — takes an OBJECT
class StaffListItem extends StatelessWidget {
  const StaffListItem({
    required this.staff,              // StaffClassroomItem
    required this.isSelected,
    required this.onSelectionChanged,
    this.isSignedIn = false,
    this.todayStatusRaw,
    super.key,
  });
```

```dart
// staff/widgets/staff_list_item.dart:4 — takes plain STRINGS
class StaffListItem extends StatelessWidget {
  const StaffListItem({
    required this.fullName,           // String
    required this.role,               // String
    required this.roomName,           // String
    this.onTap,
    super.key,
  });
```

**Why it violates.** The PDF describes this pair almost verbatim: *"Five take a `Staff` or
`StaffEntity` object… The sixth, in `staff/widgets/staff_list_item.dart`, takes plain `fullName`
and `role` strings."* The remediation removed four of the six; these two remain, and they are
functionally different widgets — one is a selectable roster row with attendance state, the other
is a tappable directory row.

**Severity: High.** Two non-interchangeable classes sharing a name, and the standard's own worked
example of why that costs.

**Fix.** Rename, do not merge — they are genuinely different widgets. The classroom one is a
selection tile: `AssignStaffSelectionTile` or similar, moved into the feature's `widgets/` folder
(created by §3.3). Diff both before deciding, as the rule requires. `StudentListItem` at
`assign_student_to_classroom_form.dart:454` is now unique app-wide (the four attendance copies
were removed) but should be renamed alongside it for symmetry.

---

#### 6.3 — The two assign forms duplicate 167 lines and have already diverged into a user-visible defect

**Rule broken.** MANDATE 6: *"Extract when the same UI appears more than once with identical
structure and different configuration."* `docs/mandate-rules.md` names this pair: *"in the
classroom module that is two assign forms sharing 151 lines"*.

**Where.** [assign_staff_to_classroom_form.dart](lib/presentation/features/classroom/forms/assign_staff_to_classroom_form.dart)
(512 lines) and
[assign_student_to_classroom_form.dart](lib/presentation/features/classroom/forms/assign_student_to_classroom_form.dart)
(547 lines) share **167 distinct non-trivial lines** — up from the 151 the standard recorded.

The divergence has already produced a defect. Both files declare a `_disabledReason` getter
rendered as a `Tooltip` message (staff: lines 440 and 505; student: lines 478 and 540):

```dart
// assign_staff_to_classroom_form.dart:412-413 — correct
String get _disabledReason =>
    "${staff.fullName.trim().isEmpty ? 'This staff member' : staff.fullName.trim()} is already signed in. Please sign out before assigning to another classroom.";

// assign_student_to_classroom_form.dart:468-469 — a stray "This Student " prefix
String get _disabledReason =>
    "This Student ${student.fullName.trim().isEmpty ? 'This student' : student.fullName.trim()} is already signed in. Please sign out before assigning to another classroom.";
```

The student version renders **"This Student Jane Smith is already signed in."** when a name is
present, and **"This Student This student is already signed in."** when it is not. The staff
twin, from which it was copied, reads correctly in both cases.

**Why it violates.** Two forms differing by one axis — which entity type is being assigned —
share a third of their content, and the copy has drifted. This is the mandate's prediction
realised: the fix applied to one copy's wording did not reach the other.

**Severity: High.** A live, user-visible text defect in a tooltip on the assign flow, caused
directly by the duplication the standard flagged. Not Critical — it is cosmetic copy, not data
loss or a security issue.

**Fix.** Two steps, in order. First, correct the string at
`assign_student_to_classroom_form.dart:469` — a one-line change that stands alone and should not
wait for the refactor. Then extract one `AssignToClassroomForm<T>` parameterised by entity type
and the differing labels, migrating one form at a time and verifying the submitted payload and
post-submit navigation are unchanged. The two confirmation cubits are already separate and
well-factored, so the shared surface is the selection UI, not the submit logic.

---

#### 6.4 — Eleven files exceed the 400-line ceiling; the largest is 1,853

**Rule broken.** MANDATE 6: *"File size ceiling: 400 lines. Split by extracting cohesive units,
not arbitrarily at line 400."* PDF §9.3 gate 11.

**Where.**

| File | Lines |
|---|---|
| `view/classroom_tab_cards/classroom_students_tab_card.dart` | **1,853** |
| `view/classroom_tab_cards/classroom_staff_tab_card.dart` | **1,438** |
| `view/screens/classroom_info_screen.dart` | **1,362** |
| `view/screens/classroom_screen.dart` | 692 |
| `view/screens/classroom_overview_screen.dart` | 606 |
| `forms/assign_student_to_classroom_form.dart` | 547 |
| `view/widgets/classroom_student_list_item.dart` | 518 |
| `forms/assign_staff_to_classroom_form.dart` | 512 |
| `view_model/classroom_students_cubit.dart` | 467 |
| `data/.../classroom_remote_datasource.dart` | 451 |
| `view_model/classroom_staff_cubit.dart` | 406 |

**Why it violates.** The ceiling is 400 and the largest file is 4.6× over. File size is the
mechanism behind other findings here: `classroom_students_tab_card.dart` is where the duplicated
`CustomMultiSelectDropdown` hid (§6.1), and `classroom_info_screen.dart` is where six use cases
accumulated as `State` fields (§5.1).

**Severity: High.** Three files over 1,300 lines, two of which conceal specific violations found
in this audit.

**Fix.** Split by cohesive unit, not at an arbitrary line. `classroom_students_tab_card.dart`
divides at the local dropdown (removed by §6.1), the filter bar, and the roster list.
`classroom_info_screen.dart` splits naturally once §5.1 moves its six use cases into a cubit —
do that first so the split is not redone.

---

#### 6.5 — Twelve `Widget _buildXxx()` methods

**Rule broken.** MANDATE 6: *"Replace `Widget _buildXxx()` methods with private
`StatelessWidget` classes in the same file. A method returning a Widget cannot be `const`, cannot
take a key, and rebuilds with its whole enclosing widget."*

**Where.** 12 methods across 5 files: `classroom_info_screen.dart` 6,
`classroom_student_filter_screen.dart` 2, `classroom_staff_filter_screen.dart` 2,
`classroom_students_tab_card.dart` 1, `classroom_staff_tab_card.dart` 1.

**Why it violates.** Each rebuilds with its whole enclosing widget. In `classroom_info_screen.dart`
the enclosing widget is 1,362 lines and calls `setState` 20 times (§2.1), so every one of those
calls rebuilds all six sections.

**Severity: Medium.** Mechanical, and mostly a rebuild-cost issue — but material on the screen
where it concentrates.

**Fix.** Convert each to a private `StatelessWidget` in the same file, passing what it reads as
constructor parameters. Doing this first surfaces which `State` fields each section depends on,
which directly supports §2.1 and §6.4.

---

#### 6.6 — `_LegendDot` duplicated across two features

**Rule broken.** MANDATE 6: *"No two classes in the codebase share a name."*

**Where.** [classroom_overview_screen.dart:430](lib/presentation/features/classroom/view/screens/classroom_overview_screen.dart#L430)
and [billing/widgets/analytics/analytics_section.dart:1066](lib/presentation/features/billing/widgets/analytics/analytics_section.dart#L1066).

**Why it violates.** Two private classes sharing a name across unrelated features — the §6.1
*"`_Chip`, `_EmptyState`, `_DialogField`… Private duplicates across unrelated features"* pattern.
Being private, they cannot collide at compile time, so the cost is duplicated maintenance of the
same small legend-dot widget rather than a resolution hazard.

**Severity: Low.** Private, small, no compile-time interaction.

**Fix.** If the two are visually identical, promote one to `core/widgets/` and delete the other.
If they differ, rename to say what each is. Diff before merging.

---

### Mandate 7 — One responsive source

**Verdict: Partially violated** (3 violations, highest Medium)

**What is compliant.** Only **two** width-literal comparisons exist in the whole module (§7.1),
and all three `LayoutBuilder` instances are legitimate own-box uses — the mandate requires these
be listed with a reason:

| Site | Why it is legitimate |
|---|---|
| [classroom_staff_tab_card.dart:955](lib/presentation/features/classroom/view/classroom_tab_cards/classroom_staff_tab_card.dart#L955) | Reads `constraints.maxHeight` to give an empty-state `ListView` a minimum height so pull-to-refresh works when the roster is empty. Responds to its own box. |
| [classroom_students_tab_card.dart:1447](lib/presentation/features/classroom/view/classroom_tab_cards/classroom_students_tab_card.dart#L1447) | Same empty-state overscroll wrapper on the students roster. |
| [classroom_overview_screen.dart:141](lib/presentation/features/classroom/view/screens/classroom_overview_screen.dart#L141) | `ConstrainedBox(minHeight: constraints.maxHeight)` so a short overview page still fills and scrolls. |

**Keep all three.** They are the "card that reflows inside a narrow column" case the mandate
preserves.

---

#### 7.1 — Inline 600/900 breakpoint literals

**Rule broken.** MANDATE 7: *"Breakpoints are defined once in
`lib/core/responsive/app_breakpoints.dart`. No other file contains a screen-width comparison
against a literal."*

**Where.** [classroom_screen.dart:630-632](lib/presentation/features/classroom/view/screens/classroom_screen.dart#L630-L632)

```dart
final screenWidth = MediaQuery.of(context).size.width;
final isTablet = screenWidth >= 600;
final isLargeTablet = screenWidth >= 900;
```

passed down at lines 658-659 and 686-687.

**Why it violates.** Two screen-width comparisons against literals, in a file that is not
`app_breakpoints.dart`. This is the exact pattern PDF §7.1 tabulates for
`students/view/student_screen.dart:1514` (`>= 600` / `>= 900`) and
`activities/view/activity_feed_screen.dart:271,341` — the same 600/900 pair, declared locally.
`AppBreakpoints.compactMaxWidth` (600) and `AppBreakpoints.wideMinWidth` (900) both already exist.

**Severity: Medium.** The values happen to match `AppBreakpoints`, so there is no live layout
disagreement — but nothing keeps them in sync, and this is the file a future breakpoint change
would miss.

**Fix.** Replace with `context.isTablet` and a `context.responsive(...)` call, or at minimum
resolve the literals from `AppBreakpoints`. One-line changes; verify the two consumers at lines
658 and 686 receive the same booleans at the same widths.

---

#### 7.2 — Five `MediaQuery.of(context)` reads and no field-scoped alternatives

**Rule broken.** MANDATE 7: *"`MediaQuery.sizeOf(context)` over `MediaQuery.of(context)` — `.of`
subscribes to the whole object, so a width read re-runs on every keyboard open."*

**Where.** 5 `MediaQuery.of`, **0** `MediaQuery.sizeOf`, **0** `MediaQuery.paddingOf`:

```dart
// view/filters/classroom_staff_filter_screen.dart:137
final bottomPadding = MediaQuery.of(context).padding.bottom;
// view/filters/classroom_student_filter_screen.dart:160
final bottomPadding = MediaQuery.of(context).padding.bottom;
// view/classroom_tab_cards/classroom_students_tab_card.dart:1790
maxWidth: MediaQuery.of(context).size.width * 0.4,
// view/screens/classroom_screen.dart:630
final screenWidth = MediaQuery.of(context).size.width;
// view/widgets/classroom_dropdown.dart:114
maxHeight: MediaQuery.of(context).size.height * 0.5,
```

**Why it violates.** All five subscribe to the whole `MediaQuery`. Three read `size` and map
directly to `MediaQuery.sizeOf`; the two `padding.bottom` reads map to `MediaQuery.paddingOf`
(not named in the rule, but the stated reason — field-scoped subscription — applies identically).
Both filter screens contain text fields, which is the keyboard-transition case the rule describes.
By comparison the Attendance module already uses `paddingOf` 13 times.

**Severity: Medium.** Redundant rebuilds on keyboard open, on screens where the keyboard opens
routinely.

**Fix.** Three sites to `MediaQuery.sizeOf`, two to `MediaQuery.paddingOf`. Behaviour-preserving
one-line swaps.

---

#### 7.3 — Feature code does not read the published size class

**Rule broken.** MANDATE 7: *"One `LayoutBuilder`, at the top of the tree inside
`ResponsiveScope`, publishing the size class through an `InheritedWidget`. Feature code reads
`context.screenSize` / `context.isTablet` / `context.responsive(compact:, medium:, expanded:)`;
**it does not measure**."*

**Where.** `context.responsive` / `context.isTablet` / `context.screenSize` are used **0 times**.
Only 2 of the 30 presentation files import any responsive helper at all — the rest either measure
directly (§7.2) or do not adapt.

**Why it violates.** `ResponsiveScope` is mounted at [app/app.dart:82](lib/app/app.dart#L82) and
the extension API exists at
[responsive_scope.dart:49-74](lib/core/responsive/responsive_scope.dart#L49-L74), so the
destination is available and unused. Classroom is further behind than the other two modules:
Attendance routes 34 files through `ResponsiveHelper` (which delegates to `AppBreakpoints`), and
Activity routes 12. Classroom mostly does not adapt at all.

**Severity: Medium.** No layout inconsistency — the two literals in §7.1 match `AppBreakpoints` —
but tablet adaptation is largely absent rather than merely routed the long way.

**Fix.** Adopt `context.isTablet` / `context.responsive(...)` at the §7.1 site first. Beyond that,
this is app-wide sequencing work (the shared helper has 116 importers) that this module should
follow rather than lead. Verify each screen at 375, 768 and 1024 as the mandate requires.

---

### Mandate 8 — Models everywhere, generated, never raw maps

**Verdict: Violated** (5 violations, highest High)

Measured:

| Check | Count | Target |
|---|---|---|
| `@JsonSerializable()` classes | **0** | all models |
| `.g.dart` files | **0** | one per model |
| Hand-written `fromJson` factories | **15** | 0 |
| Hand-written `toJson` methods | **0** | 0 |
| Datasource methods returning raw `Map` | **0** | 0 |
| `Map<String, dynamic>` in `lib/domain/features/classroom` | **0** | **0** |
| `Map<String, dynamic>` in `lib/presentation/features/classroom` | **10** | **0** |
| `mappers/` folder | **present** | present |

**What is compliant, and it is the strongest data/domain result of the three modules.** The
domain layer has **zero** `Map<String, dynamic>` references — not as a parameter, return type or
field. The `fromJson` factory the PDF §8.2d names on
`domain/features/classroom/entities/ratio_monitoring_classroom.dart:69` is **gone**; the entity
is now pure. `data/features/classroom/mappers/classroom_mapper.dart` exists — one of only two
`mappers/` folders in the repo — with three model→entity conversions. And the datasource returns
typed models throughout, with no `Future<Map<String, dynamic>>` signatures anywhere.

---

#### 8.1 — Fifteen hand-written parsers and no code generation

**Rule broken.** MANDATE 8: *"Models are annotated `@JsonSerializable()` with generated
`fromJson`/`toJson` via `part 'x.g.dart'`. **No hand-written serialisation.**"*

**Where.** 15 `fromJson` factories across all 6 model files, zero `@JsonSerializable`, zero
`.g.dart`:

| File | Factories |
|---|---|
| `classroom_all_models.dart` | 18, 58, 82, 116 |
| `classroom_details_models.dart` | 89, 122 |
| `classroom_logo_models.dart` | 10, 32, 58 |
| `classroom_enrollment_models.dart` | 12, 34 |
| `dashboard_summary_models.dart` | 12, 33, 52 |
| `classroom_attendance_summary_model.dart` | 19 |

`json_annotation ^4.9.0` and `json_serializable ^6.8.0` are both in `pubspec.yaml`, and
`data/features/attendance/models/qr_validation_model.dart` is a working reference implementation
elsewhere in the repo.

**Why it violates.** The rule is "no hand-written serialisation" and the pipeline is installed
and proven. Fifteen parsers each choose their own defaulting convention independently — the
mechanism §8.7 describes as how the `signedInBy` alias defect arose in attendance.

**Severity: High.** No live defect found, but 15 unguarded parsers with zero test coverage
(§6.3 note) is the highest per-file parser density with the lowest verification of the three
modules.

**Fix.** Convert model-by-model using `qr_validation_model.dart` as the template. The mandate
requires a characterisation test **before** deleting any parser — feed the same fixture through
old and new and assert field-for-field equality including nulls, missing keys and wrong types.
This module has no tests at all, so those characterisation tests are net-new and are the
gating work.

---

#### 8.2 — Hand-rolled cache serialisation in a cubit and a view

**Rule broken.** MANDATE 8: *"No `Map<String, dynamic>` in `lib/domain` or `lib/presentation` —
not as a parameter, not as a return type, not as a field."* And: *"No hand-written
serialisation."*

**Where.** [classroom_cubit.dart:39-82](lib/presentation/features/classroom/view_model/classroom_cubit.dart#L39-L82)
encodes and decodes the classroom list to and from the disk cache by hand:

```dart
Map<String, dynamic> _encodeClassroomsForCache(List<Classroom> classrooms) => {
  'items': classrooms.map(
    (e) => <String, dynamic>{
      'code': e.code,
      'name': e.name,
      'minAgeMonths': e.minAgeMonths,
      'maxAgeMonths': e.maxAgeMonths,
    },
  ).toList(),
};

List<Classroom> _decodeClassroomsFromCache(Map<String, dynamic>? payload) {
  ...
  final code = (m['code'] ?? '').toString().trim();
  ...
  int months(dynamic v) {
    final n = v is num ? v.toInt() : int.tryParse('${v ?? ''}'.trim()) ?? 0;
```

and [classroom_info_screen.dart:294-302](lib/presentation/features/classroom/view/screens/classroom_info_screen.dart#L294-L302)
does the read side in a **view**:

```dart
final data = cached['data'];
if (data is! Map) return;
final map = Map<String, dynamic>.from(data);
setState(() {
  _enrolledActiveCount = (map['activeCount'] as num?)?.toInt() ?? 0;
```

**Why it violates.** A cubit and a view are both performing JSON serialisation against raw maps,
which the mandate confines to the data layer. The cubit's own comment records that this has
already cost something: *"Age bounds must be cached too — omitting them meant a cache-hydrated
list reported every room as 'no age limit', silently disabling the age warning until a live
refetch"* — a hand-written encoder that dropped two fields and silently disabled a safety warning.

**Severity: Medium.** The named defect is fixed; the pattern that produced it is not, and it now
exists in two layers.

**Fix.** Give the cache a model in `data/features/classroom/models/` with generated
serialisation, and move both the encode and decode behind the repository. The view's read
disappears once §5.1 moves its state into a cubit. Preserve the age-bounds fields explicitly —
a regression there silently disables the age-range warning again.

---

#### 8.3 — Ten `Map<String, dynamic>` references in the presentation layer

**Rule broken.** MANDATE 8: *"No `Map<String, dynamic>` in `lib/domain` or `lib/presentation`."*
PDF §8.3 sets the expected count for `lib/presentation` at **zero**.

**Where.** 10 references across 7 files: `classroom_cubit.dart` 3 (§8.2),
`classroom_students_tab_card.dart` 2, and one each in `classroom_student_list_item.dart`,
`classroom_overview_screen.dart`, `classroom_info_screen.dart`, `classroom_notes_tab_card.dart`,
`date_picker_normal.dart`.

**Why it violates.** The target for this layer is zero.

**Severity: Medium.** Ten sites — proportionally similar to Attendance's five and far below
Activity's 159, but the module is also a third the size.

**Fix.** Three of the ten close with §8.2. Audit the remaining seven individually: each is either
a cache payload (→ model) or an untyped argument bag (→ a typed class in the `model/` folder
§3.3 creates).

---

#### 8.4 — The `mappers/` folder covers three of the module's conversions

**Rule broken.** MANDATE 8: *"Mappers convert model → entity, which is what `mappers/` is for."*

**Where.** [classroom_mapper.dart](lib/data/features/classroom/mappers/classroom_mapper.dart) is
41 lines and holds exactly three static mappings — attendance-summary, enrolled-count and
logo-upload-session. The module's other conversions (classroom list, classroom details, school
capacity, classroom count, school FTE, ratio monitoring) do not go through it; the repository
performs them, reading map keys 13 times.

**Why it violates — narrowly.** The folder exists and is correctly placed, which is more than 17
of 19 features can say. The rule is about mappers being *where* conversion happens, and here
conversion happens in two places.

**Severity: Low.** A partial adoption of the right pattern, not an absence of it.

**Fix.** Move the remaining repository-level conversions into `ClassroomMapper` as §8.1 converts
each model. No behaviour change; it consolidates rather than introduces.

---

#### 8.5 — A domain contract returns a `Map` keyed by classroom code

**Rule broken.** MANDATE 8: *"No `Map<String, dynamic>` in `lib/domain`… not as a return type."*

**Where.** [classroom_repository.dart:47-58](lib/domain/features/classroom/repositories/classroom_repository.dart#L47-L58)

```dart
Future<Map<String, ClassroomAttendanceSummaryEntry>>
getStudentAttendanceSummaryByClassrooms({ ... });

Future<Map<String, ClassroomAttendanceSummaryEntry>>
getStaffAttendanceSummaryByClassrooms({ ... });
```

**Why it violates — with a caveat.** The rule names `Map<String, dynamic>` specifically, and
these are `Map<String, ClassroomAttendanceSummaryEntry>` — a typed lookup keyed by classroom
code, with a proper entity as the value. The rule's stated purpose (*"a map standing in for a
type that should exist"*) is arguably not met: the type exists and is used. Recorded for
consistency with the same question raised in both prior audits.

**Severity: Low.** Fully typed on the value side; a keyed lookup is a reasonable shape.

**Fix.** None required unless the team decides typed maps are in scope — see **Open questions**.
If they are, introduce a small `ClassroomAttendanceSummaries` wrapper with a `byCode(String)`
accessor.

---

## 4. Remediation order

Sequenced so each step is a single isolated change that preserves existing behaviour, and so no
step has to be redone by a later one. The ordering follows `docs/mandate-rules.md`'s revised
sequence (**1 → 5 → 2 → 3 → 6 → 4 → 7 → 8**) adapted to this module.

**Before anything:** capture the baseline the guardrails require — `flutter analyze` on the three
module directories. **There is no `flutter test` baseline to capture: the module has zero test
files.** That is the defining constraint on this plan, which is why steps 1 and 2 add tests
before any refactor touches logic.

### Phase A — make the module verifiable, and fix the live defect

| # | Change | Fixes | Why here |
|---|---|---|---|
| 1 | Correct the tooltip string at `assign_student_to_classroom_form.dart:469` | §6.3 (part) | A live user-visible defect. One line, stands entirely alone, needs no refactor. |
| 2 | Write characterisation tests for `classroom_age_range.dart` and the entity logic (`isAgeOutsideRange`, `isRatioGood`, `formatStudentTeacherRatioDisplay`, `ageRangeCompactDisplay`) | — | `docs/mandate-rules.md` names `classroom_age_range.dart` for exactly this. Everything below is safer with it, and this is the module's only pure logic. |
| 3 | Delete the local `CustomMultiSelectDropdown`; import the shared widget | §6.1 | Self-contained, removes a name collision and restores select-all/search. Verify appearance unchanged. |

### Phase B — navigation and layer discipline (the "1 and 5 as a pair" step)

| # | Change | Fixes | Why here |
|---|---|---|---|
| 4 | Add a `ClassroomRoutes` block to `app_routes.dart` for the screens reached in §1.1 | §1.2 | Prerequisite for every push conversion. |
| 5 | Create `model/`; move the two filter-result classes into it and add typed route-args classes | §3.3 (part) | Prerequisite for converting the two result-returning pushes. |
| 6 | Convert the four staff-form pushes to `context.push` against the attendance routes those forms already declare | §1.1 (part) | Smallest conversion; removes the cross-feature imperative coupling. |
| 7 | Convert the two filter pushes to `context.push` + `context.pop(result)` using step 5's args | §1.1 (part) | Verify the returned filter result reaches the caller identically. |
| 8 | Convert the remaining nine pushes | §1.1 (part) | Mechanical once 4–7 establish the pattern. |
| 9 | **Introduce `ClassroomInfoCubit`**: move the six use cases, `StorageService`, `CacheManager` and `ImageUploadService` off `classroom_info_screen.dart` | §5.1, §5.2, §2.1 (part) | **The module's highest-value change** — it closes the worst Mandate 5 breach and the worst Mandate 2 one together. Compare network call counts before/after. |
| 10 | Move the remaining view-level use-case resolutions into the existing students/staff cubits | §5.1 (part) | Follows 9's pattern. |
| 11 | Move cubit creation into the `GoRoute` builders; trigger each load once | §5.3, §1.3 | Depends on 4–8. **Check §5.4**: `ClassroomCubit` has an internal guard, so a double-fire regression would be silent — count calls explicitly. |
| 12 | Move the notes unread-count stream into a cubit | §5.4 | Independent of 9–11; confirm the badge still updates and the subscription is cancelled. |

### Phase C — structure

| # | Change | Fixes | Why here |
|---|---|---|---|
| 13 | Move `classroom_age_range.dart` to domain, taking "school today" as a parameter | §3.1 | Safe because step 2 wrote its tests. Removes the cross-feature presentation import. |
| 14 | Move `classroom_visibility.dart` from `core/utils/` into the classroom domain | §3.4 (part) | Small and self-contained. Leave `attendance_classroom_scope.dart` to the coordinated cross-module decision. |
| 15 | Create a feature-root `widgets/`; consolidate `view/widgets/` and `forms/widgets/` into it | §3.3 (part) | Resolve any name collisions as they surface. |
| 16 | Move the two assign forms into `view/` and the picker into `widgets/`; delete `forms/` | §3.2 | After 15, so the widget destination exists. |
| 17 | Codemod relative → `package:` imports | §3.5 | After 13–16 have moved files, not before. |

### Phase D — reuse

| # | Change | Fixes | Why here |
|---|---|---|---|
| 18 | Rename the classroom `StaffListItem` (and `StudentListItem` for symmetry) to selection-tile names | §6.2 | Diff both copies before deciding, as the rule requires. Follows 15/16's moves. |
| 19 | Extract one parameterised `AssignToClassroomForm<T>`; migrate the two forms one at a time | §6.3 | Verify submitted payload and post-submit navigation per form. Step 1 already fixed the string, so no defect is carried into the shared version. |
| 20 | Convert the 12 `Widget _buildXxx()` to private `StatelessWidget` classes | §6.5 | Surfaces which `State` fields each section reads — feeds step 22. |
| 21 | Split the three files over 1,300 lines by cohesive unit | §6.4 | After 9 and 20, so the seams are already visible. |
| 22 | Move the remaining Bucket A state off the two tab cards and `classroom_screen.dart` | §2.1 (rest) | **Flag the behaviour change the mandate warns about**: selections may now persist across navigation where they previously reset. |
| 23 | Convert genuine Bucket B micro-state to `ValueNotifier` + `ValueListenableBuilder` **with** `child:`; apply `BlocSelector` where one widget reads one property | §2.2, §2.3 | Falls out of 22. |
| 24 | Resolve or rename `_LegendDot` | §6.6 | Cosmetic; batch with 18. |

### Phase E — theming

| # | Change | Fixes | Why here |
|---|---|---|---|
| 25 | Add named `AppTextStyles` entries and replace the 59 inline `TextStyle(` constructors | §4.1 | **After Phase D** — per `docs/mandate-rules.md`'s "Move 6 before 4", doing this earlier would tokenise two copies of a form step 19 collapses. |
| 26 | Delete the 57 `fontFamily: 'Manrope'` lines | §4.2 | Mostly removed as a side effect of 25; sweep the remainder. Verify the rendered font is unchanged. |
| 27 | Extract view-file user-visible strings to `AppStrings` | §4.3 | Same sequencing reason as 25. |
| 28 | Adopt a spacing token family across the 198 magic literals | §4.4 | Blocked on the app-wide `AppSizes` vs `AppSpacing` decision. **Do not migrate this module in isolation.** |

### Phase F — responsiveness

| # | Change | Fixes | Why here |
|---|---|---|---|
| 29 | Replace the 600/900 literals with `context.isTablet` / `context.responsive(...)` | §7.1, §7.3 (part) | Small and self-contained. |
| 30 | Swap the five `MediaQuery.of` reads for `sizeOf` / `paddingOf` | §7.2 | One line each. |
| 31 | Broader `context.responsive` adoption | §7.3 (rest) | App-wide sequencing; follow, do not lead. |

### Phase G — models

| # | Change | Fixes | Why here |
|---|---|---|---|
| 32 | Write characterisation tests for the 15 `fromJson` factories | §8.1 (prerequisite) | The mandate requires this before any parser is deleted, and the module has no tests. This is the gating work, not the conversion. |
| 33 | Convert one model to `@JsonSerializable()` as the reference, then the rest; commit the `.g.dart` files | §8.1 | `qr_validation_model.dart` is the in-repo template. |
| 34 | Give the classroom-list cache a model; move encode/decode behind the repository | §8.2 | **Preserve the age-bounds fields explicitly** — dropping them silently disables the age warning, as the cubit's own comment records. |
| 35 | Type or eliminate the remaining presentation maps | §8.3 | Three close with 34; audit the other seven individually. |
| 36 | Move the repository's remaining conversions into `ClassroomMapper` | §8.4 | Last. Consolidation only, once 33 has given each model a generated shape. |

---

## 5. Open questions

Points where the standard does not clearly settle the case. I have reported the finding and
flagged the ambiguity rather than guessing.

1. **Which source wins.** The brief says `docs/mandate-rules.md` takes precedence; that file's
   own preamble says the PDF wins. I followed the brief. It changed no verdict — the two agree
   on all eight rules — but it decides the execution order, and my remediation order follows
   mandate-rules.md. **One of the two documents should be corrected**; this is now the third
   audit to raise it.

2. **Are `staff_classroom` and `student_classroom` part of the classroom module?** They are four
   separate feature directories (`data/` and `domain/` for each, 15 files total) with no
   presentation layer of their own, consumed almost exclusively by classroom's assign flow. The
   standard organises strictly by feature and does not describe a feature whose domain lives
   under a different feature name. I audited classroom proper and excluded them from the counts;
   if they are classroom-owned, the scope and the violation totals both grow.

3. **Does the "no user-visible string literal" rule reach cubits and entities?** MANDATE 4 says
   *"No user-visible string literal in a **view file**"*. This module puts user-facing copy in
   cubits (`throw 'Please select at least one staff member'`,
   `assign_staff_confirmation_cubit.dart:35`) and in domain entities (`return 'No Age Limit'`,
   `classroom_details.dart:55`). Both are rendered to users. The rule's wording exempts them; its
   purpose (localisation) does not. Worth deciding once, for all modules.

4. **Is a typed `Map<String, Entity>` in scope for the no-maps rule?** MANDATE 8 specifies
   `Map<String, dynamic>`. `classroom_repository.dart:47,54` return
   `Future<Map<String, ClassroomAttendanceSummaryEntry>>` — a lookup keyed by classroom code with
   a proper entity as the value. I did not count it as a violation. (Raised in both prior audits
   for `Map<String, String>`; the same decision covers both.)

5. **`AppSizes` or `AppSpacing`?** MANDATE 4 names `AppSizes`
   (`lib/core/constants/app_sizes.dart`). Repo-wide, `AppSpacing` (`lib/core/theme/`) has 76
   importers to `AppSizes`' 35. Classroom uses **neither**, so unlike Attendance it has no
   existing adoption to preserve — but the destination still needs one app-wide decision before
   198 literals are migrated. (Raised in `attendance-kiosk-module-audit.md` §4.4.)

6. **Should `view/` have subdirectories?** The canonical layout is `view/  # screens. Zero logic.`
   Classroom uses `view/screens/`, `view/filters/`, `view/classroom_tab_cards/` and
   `view/widgets/`. I graded only the misplaced `widgets/` (§3.3) and the non-canonical top-level
   `forms/` (§3.2), not the grouping itself. If subdirectories under `view/` are meant to be
   forbidden, that should be stated — the same question arose for attendance.

7. **What is `classroom_selection_widget_exact.dart`?** The `_exact` suffix on a file in
   `shared/common/widgets/` usually marks a pinned copy of something. I flagged it as module code
   outside MODULE_PATH (§3.4) but could not determine from the code what it is "exact" relative
   to, and the standard has no rule about suffix conventions.

8. **Zero test coverage is not itself a mandate.** The module has no test files, which is the
   single largest risk to executing this plan — the mandate requires characterisation tests
   before touching parsers and pure logic, so those tests are net-new work rather than
   extensions. PDF §9.4 lists test coverage as *"deliberately not in this document"*, so it has
   no mandate to attach to. It is recorded here and in the risk assessment because it changes the
   cost and sequencing of nearly every item above.

9. **Nothing currently enforces any of this.** `analysis_options.yaml` still has every lint line
   commented out, including `include: package:flutter_lints/flutter.yaml`; only an
   `analyzer: exclude: third_party/**` block is active. That is PDF §9.1, unchanged. Outside this
   module's scope, but it is why the module was able to drift.

---

## 6. Method and limits

- All 57 in-scope files were read in full — the module is small enough that no sampling was
  needed. Cross-cutting counts (`setState`, `serviceLocator`, `Map<String, dynamic>`, `Colors.*`,
  `TextStyle(`, `fontFamily`, `fromJson`, imports, class declarations) were produced by exhaustive
  grep over the three module directories and then verified by reading the matched sites in
  context. Every quoted snippet was read before quoting.
- Every file path and line number was checked against the working tree at `cdb6b86e` on
  `develop-refactor`. Nothing is inferred from a filename.
- `git diff bfbc4fbb..HEAD` over the three module directories is empty, so this module is
  identical to what the two earlier audits in this folder saw; the three reports are directly
  comparable despite the SHA difference.
- Duplication figures are counts of shared **distinct, non-trivial** lines (whitespace-normalised,
  brace- and punctuation-only lines excluded) — a conservative proxy for copy-paste, not a formal
  clone analysis.
- Every relative import in the module was resolved programmatically against the filesystem to test
  for the §3.4 excess-`..` hazard. All resolve; none is broken.
- Duplicate class names were found by extracting all public and private class declarations in
  `lib/` (excluding `.g.dart`) at the audited commit and diffing against the module's 116 public
  classes.
- **Two measurements were corrected during this audit before publication.** An initial
  width-comparison regex was case-sensitive and missed `screenWidth >= 600` at
  `classroom_screen.dart:631`; re-run case-insensitively, the module has two inline breakpoint
  literals, not zero — which is why Mandate 7 is graded Partially violated rather than Compliant.
  Separately, an initial magic-number grep counted token references such as
  `EdgeInsets.all(AppSpacing.s2)`; re-measured with a balanced-parenthesis parser, the count is
  198 and the module uses no spacing token family at all.
- I did not run `flutter analyze` as part of this audit; the baseline capture is listed as the
  first remediation step rather than claimed as done. There is no `flutter test` baseline to
  capture — the module has zero test files, which I verified by searching the whole `test/` tree.
- The earlier `docs/audits/activity-module-audit.md` and
  `docs/audits/attendance-kiosk-module-audit.md` were used only for cross-module comparison and
  heading parity. Every finding here was derived from the classroom code.
- No files were modified.
