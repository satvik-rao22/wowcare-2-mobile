# Scheduling Module — Eight Mandates Compliance Audit

| | |
|---|---|
| **Module** | Scheduling |
| **Paths** | `lib/presentation/features/scheduling/`, `lib/data/features/scheduling/`, `lib/domain/features/scheduling/` |
| **Commit audited** | `cdb6b86e251c87c14718cf1054344e480f8f091f` (`cdb6b86e`), branch `develop-refactor` |
| **Date** | 2026-09-09 |
| **Scope size** | 73 files, 15,830 lines |
| **Standard** | `WowCare2-Engineering-Standards-Eight-Mandates 1.pdf` + `docs/mandate-rules.md` |
| **Nature** | Audit only. No code was changed. |

> **A note on inputs.** The task template arrived with `MODULE_NAME` and `MODULE_PATH` as
> unfilled placeholders, and the example path (`lib/features/scheduling/`) does not match this
> repo's layout — that directory does not exist. I resolved the three real directories from the
> prose instruction ("the Scheduling module") and verified all three before auditing. No path was
> invented.
>
> **Precedence note.** The brief says `docs/mandate-rules.md` wins where the two sources differ.
> `docs/mandate-rules.md` itself says the PDF wins. I followed the brief and flagged the conflict
> in **Open questions**, as in the three prior audits. The two agree on all eight rules; they
> differ only in emphasis and recommended execution order.

**Severity definitions** (identical to the three existing audits in this folder):
**Critical** — a live defect or a security/correctness hazard reachable in production.
**High** — a rule broken in a way that will cause divergence or defects as the code changes.
**Medium** — a real rule breach with contained blast radius.
**Low** — cosmetic, mechanical, or already mitigated in practice.

---

## 0. Scope — the exact file set audited

**73 files, 15,830 lines.** Every file below was read in full.

### `lib/data/features/scheduling/` — 8 files

| Folder | Files (lines) |
|---|---|
| `datasources/` (2) | `staff_scheduling_remote_datasource.dart` (71), `staff_shift_remote_datasource.dart` (519) |
| `models/` (4) | `classroom_forecast_models.dart` (134), `scheduling_json_parsing.dart` (18), `staff_shift_hours_models.dart` (77), `staff_shift_models.dart` (418) |
| `repositories/` (2) | `staff_scheduling_repository_impl.dart` (36), `staff_shift_repository_impl.dart` (363) |

### `lib/domain/features/scheduling/` — 20 files

| Folder | Files (lines) |
|---|---|
| `entities/` (3) | `classroom_forecast_block.dart` (46), `staff_shift.dart` (323), `staff_shift_hours_entry.dart` (46) |
| `repositories/` (2) | `staff_scheduling_repository.dart` (14), `staff_shift_repository.dart` (165) |
| `services/` (2) | `scheduling_school_time.dart` (28), `staff_hours_aggregator.dart` (59) |
| `usecases/` (13) | `bootstrap_scheduling_school_timezone_usecase.dart` (24), `create_staff_shift_usecase.dart` (12), `delete_staff_shift_series_usecase.dart` (19), `delete_staff_shift_usecase.dart` (18), `get_classroom_forecast_range_usecase.dart` (34), `get_classroom_forecast_usecase.dart` (32), `get_school_staff_shifts_usecase.dart` (29), `get_staff_shift_by_code_usecase.dart` (14), `get_staff_shift_hours_range_usecase.dart` (27), `get_staff_shifts_usecase.dart` (24), `publish_staff_shifts_usecase.dart` (27), `update_staff_shift_series_usecase.dart` (14), `update_staff_shift_usecase.dart` (13) |

### `lib/presentation/features/scheduling/` — 45 files

| Folder | Files (lines) |
|---|---|
| `model/` (6) | `scheduling_models.dart` (181), `scheduling_responsive.dart` (36), `scheduling_route_args.dart` (138), `scheduling_staff_shift_style.dart` (46), `shift_models.dart` (33), `staff_shift_slot_mapper.dart` (116) |
| `navigation/` (1) | `scheduling_shift_navigator.dart` (335) |
| `utils/` (5) | `classroom_name_resolver.dart` (78), `forecast_slot_mapper.dart` (236), `scheduling_block_status_style.dart` (590), `scheduling_cache_gate.dart` (22), `school_hours_resolver.dart` (172) |
| `view/` (6) | `add_shift_screen.dart` (593), `edit_shift_screen.dart` (639), `publish_shifts_screen.dart` (376), `scheduling_screen.dart` (637), `staff_scheduling_screen.dart` (1,113), `view_shift_screen.dart` (556) |
| `view_model/` (13) | `add_shift_cubit.dart` (902), `add_shift_state.dart` (224), `edit_shift_cubit.dart` (800), `edit_shift_state.dart` (181), `publish_shifts_cubit.dart` (121), `publish_shifts_state.dart` (59), `scheduling_cubit.dart` (775), `scheduling_school_scope_mixin.dart` (34), `scheduling_staff_list_cubit.dart` (84), `scheduling_staff_list_state.dart` (35), `scheduling_state.dart` (87), `staff_scheduling_cubit.dart` (655), `staff_scheduling_state.dart` (141) |
| `widgets/` (14) | `day_classroom_section.dart` (384), `day_gantt_table.dart` (50), `no_schedule_bottom_sheet.dart` (57), `scheduling_bottom_sheet_scaffold.dart` (65), `scheduling_day_timeline.dart` (1,163), `scheduling_filter_bar.dart` (57), `scheduling_legend.dart` (140), `shift_override_bottom_sheet.dart` (110), `staff_absent_bottom_sheet.dart` (52), `staff_day_schedule_calendar.dart` (524), `staff_no_availability_bottom_sheet.dart` (49), `staff_schedule_tile.dart` (440), `staff_scheduling_staff_dropdown.dart` (89), `week_classroom_row.dart` (51) |

### Also examined (module code outside MODULE_PATH, and shared code the module reaches into)

`lib/shared/common/widgets/schedule_picker.dart` · `lib/core/router/app_routes.dart` ·
`lib/src/app_router.dart` · `lib/app/di/di.dart` ·
`lib/core/theme/{app_colors,app_text_styles,app_spacing,app_radius,app_dimensions}.dart` ·
`lib/core/constants/{app_strings,app_sizes}.dart` ·
`lib/core/responsive/{app_breakpoints,responsive_scope}.dart` ·
`lib/shared/utils/responsive_helper.dart` ·
`lib/core/utils/{app_time,school_timezone_resolver,school_zone_datetime}.dart` ·
`lib/presentation/features/classroom/view_model/classroom_cubit.dart` ·
`lib/presentation/features/dashboard/` (6 files importing this module) · `pubspec.yaml` ·
`analysis_options.yaml` · the full `test/` tree

**One directory deliberately excluded.** `lib/domain/features/staff_scheduling/` exists on disk
but contains **only two untracked `.DS_Store` files** — `git ls-files` returns zero entries for it
and nothing in `lib/` imports it. It is a local filesystem artifact, not committed code, so it is
neither in the file count nor reported as a finding.

---

## 1. Summary table

| # | Mandate | Verdict | Violations | Highest severity |
|---|---|---|---|---|
| 1 | Navigation — GoRouter everywhere | **Partially violated** | 2 | Medium |
| 2 | State — setState scarcely | **Partially violated** | 3 | Low |
| 3 | Folder structure | **Violated** | 5 | High |
| 4 | Centralized theming / constants | **Violated** | 5 | High |
| 5 | Presentation talks to cubits only | **Partially violated** | 2 | Medium |
| 6 | Reuse; pure functions out of build() | **Violated** | 5 | High |
| 7 | One responsive source | **Partially violated** | 2 | Low |
| 8 | Models everywhere, never raw maps | **Violated** | 4 | High |
| | **Total** | | **28** | |

No mandate is Not Applicable — all eight bear on this module.

---

## 2. Overall risk assessment

Scheduling is the strongest module audited so far on the mandates that usually go worst, and the
weakest on the one that usually goes best. It is the **only** module with no `MaterialPageRoute`
and no `Navigator.push` anywhere — 10 `context.push` calls, a documented `SchedulingRoutes`
constants class covering all six screens, and typed route-argument classes. Its state management
is the cleanest in the codebase by a wide margin: **3** `setState` calls in 45 presentation files,
50 `StatelessWidget` against 9 `StatefulWidget`, and `ValueNotifier` genuinely paired with
`ValueListenableBuilder`. It is the first module to actually use the mandated responsive API —
`context.responsive(compact:, medium:, expanded:)` and `context.isTablet`, sourced from
`AppBreakpoints` — with zero breakpoint literals and zero `LayoutBuilder`. And it is the first to
score **zero** `Map<String, dynamic>` in *both* the domain and presentation layers.

Against that, two findings stand out. First, **this is the only module in the codebase whose
domain layer imports Flutter**: five files under `lib/domain/features/scheduling/` import
`package:flutter/material.dart` to use `TimeOfDay` as an entity field and repository-contract
parameter type, across 26 references. Activity, Attendance, Kiosk and Classroom all measure zero.
Mandate 3 states the rule without qualification ("Domain entities are pure Dart with no Flutter
imports"), and the breach reaches beyond entities into two use cases and a repository contract.
Second, theming is the worst result of the four modules: 55 raw `Colors.*`, 24 `Color(0x…)`, and
98 inline `TextStyle(` constructors against **zero** uses of `AppTextStyles`, `AppStrings` or any
spacing token family.

The theming picture has a specific edge worth flagging: the module defines its own *semantic*
status colours — under-ratio red, in-ratio green, extra-staff blue — as local constants in two
separate feature files, and the same hex appears in up to four places (`0xFFE9ECEF` ×4). These
encode ratio compliance, which Mandate 4 singles out as needing named semantic tokens in
`core/theme` that stay distinguishable by something other than colour. The instinct was right and
the location is wrong, which means a ratio-colour change today requires finding four literals.

The compounding risk is that **no test anywhere references `features/scheduling`** — the six
schedule-named test files all cover other features (student schedules, staff schedules, reports).
Combined with the 902- and 800-line shift cubits that hold the create/edit validation logic
`docs/mandate-rules.md` names for characterisation tests, that makes the Mandate 8 conversion the
riskiest item here, which is why the remediation order puts tests before it.

---

## 3. Findings by mandate

### Mandate 1 — Navigation: GoRouter everywhere, MaterialPageRoute nowhere

**Verdict: Partially violated** (2 violations, highest Medium)

**What is compliant — and this is the best navigation result in the codebase.** Exhaustive grep
across all 45 presentation files:

| Check | Count |
|---|---|
| `MaterialPageRoute` | **0** |
| `Navigator.push` / `pushReplacement` / `pushAndRemoveUntil` | **0** |
| `context.push` | 10 |

`app_routes.dart` carries a dedicated, documented constants class
([app_routes.dart:160-175](lib/core/router/app_routes.dart#L160-L175)):

```dart
/// Route paths for the scheduling feature.
/// Mirrors [ReportRoutes] / [StaffRoutes]: named `SchedulingRoutes` rather
abstract final class SchedulingRoutes {
  static const String scheduling = '/dashboard/scheduling';
  static const String staffScheduling = '/dashboard/staff-scheduling';
  static const String addShift = '/dashboard/add-shift-screen';
  static const String editShift = '/dashboard/edit-shift-screen';
  static const String viewShift = '/dashboard/view-shift-screen';
  static const String publishShifts = '/dashboard/publish-shifts-screen';
}
```

All six screens are registered as `GoRoute` entries
([app_router.dart:1452, 1496, 1534, 1562, 1591, 1617](lib/src/app_router.dart#L1452)), and route
arguments are typed in
[model/scheduling_route_args.dart](lib/presentation/features/scheduling/model/scheduling_route_args.dart)
with `AddShiftRouteArgs`, `EditShiftRouteArgs` and siblings — no `Object?`, no `dynamic` at the
receiving end. For comparison: Classroom has 15 `MaterialPageRoute` and zero `context.push`.

---

#### 1.1 — Seven screen-route pops go through `Navigator` rather than `context.pop`

**Rule broken.** MANDATE 1: *"Every navigation goes through GoRouter: `context.push(...)`,
`context.go(...)`, `context.pop()`."*

**Where.** 16 `Navigator.pop` sites, of which **9 are exempt modal/bottom-sheet dismissals** and
**7 are screen-route pops**:

```dart
// add_shift_screen.dart:140
Navigator.of(context).pop(true);
// edit_shift_screen.dart:206
Navigator.of(context).pop(true);
// view_shift_screen.dart:368, 387
Navigator.of(context).pop(true);
// view_shift_screen.dart:453
onTap: () => Navigator.of(context).pop(option.scope),
// publish_shifts_screen.dart:141, 209
Navigator.of(context).pop( … );
```

The exempt nine are dismissals of `showModalBottomSheet` content, identifiable because they pop a
builder-captured context (`sheetContext`, `sheetCtx`) or sit inside the four `*_bottom_sheet.dart`
widgets — [staff_scheduling_screen.dart:333](lib/presentation/features/scheduling/view/staff_scheduling_screen.dart#L333),
[view_shift_screen.dart:381,383](lib/presentation/features/scheduling/view/view_shift_screen.dart#L381),
[shift_override_bottom_sheet.dart:104,105](lib/presentation/features/scheduling/widgets/shift_override_bottom_sheet.dart#L104),
[no_schedule_bottom_sheet.dart:51,52](lib/presentation/features/scheduling/widgets/no_schedule_bottom_sheet.dart#L51),
[staff_absent_bottom_sheet.dart:47](lib/presentation/features/scheduling/widgets/staff_absent_bottom_sheet.dart#L47),
[staff_no_availability_bottom_sheet.dart:44](lib/presentation/features/scheduling/widgets/staff_no_availability_bottom_sheet.dart#L44).
The mandate explicitly exempts those.

**Why it violates.** The seven remaining pops close full screens and return results to an awaiting
caller. They talk to the `Navigator` directly, so the router's `redirect` — where the kiosk lock
and any future guard live — does not observe them. The mandate's positive statement names
`context.pop()` as the way.

**Severity: Medium.** No guard currently runs on pop, so there is no live gap; the cost is that
this module will not inherit a future pop-time guard, and the migration is otherwise complete.

**Fix.** Replace the seven with `context.pop(result)`. Leave the nine modal dismissals alone.
Verify each converted site still delivers the same result value — `add_shift`/`edit_shift` return
`true` to trigger a caller refresh, and `view_shift_screen.dart:453` returns a scope enum that
drives the delete flow.

---

#### 1.2 — Route arguments carry live cubit instances through `extra`

**Rule broken.** MANDATE 1: *"Route arguments are **typed**: path parameters, or a declared class
passed through `extra`."* MANDATE 5: *"Cubits needed by a route are created in the `GoRoute`
builder, wrapped in `BlocProvider`."*

**Where.** [scheduling_route_args.dart:9-38](lib/presentation/features/scheduling/model/scheduling_route_args.dart#L9-L38)

```dart
/// Each route reads its arguments from `state.extra` cast to the matching
/// class below — the `extra` object is passed through untouched, so it can
/// safely carry live [ClassroomCubit] / [SchedulingStaffListCubit] instances
/// captured at the call site rather than the route re-resolving them, which
/// would create a second instance outside the one the entry screen's
/// `MultiBlocProvider` owns.

class AddShiftRouteArgs {
  const AddShiftRouteArgs({
    required this.schedulingStaffListCubit,
    required this.classroomCubit,
    ...
  final SchedulingStaffListCubit schedulingStaffListCubit;
  final ClassroomCubit classroomCubit;
```

**Why it violates — and this is genuinely ambiguous.** The argument class is typed and declared,
which is exactly what the rule asks for; `extra` is passed through untouched and never serialized,
so a cubit reference is technically safe to carry. But Mandate 5 says cubits are *created* in the
`GoRoute` builder, and this deliberately does the opposite — it hands an existing instance across
the route boundary to avoid a duplicate. The doc comment states the reason plainly.

Notably, this is the module that **answers** the question `attendance-kiosk-module-audit.md` left
open (§Open question 3: *"How should a route push carrying a live cubit be expressed in
GoRouter?"*). Attendance solved the same problem by keeping two `MaterialPageRoute` pushes with
`BlocProvider.value`; Scheduling solved it by routing properly and passing the cubit through typed
`extra`. Scheduling's approach is strictly closer to the mandate — it is on the router, guards
apply, and the argument is typed.

**Severity: Low.** The alternative in the same codebase is worse, the intent is documented, and no
defect follows. Recorded because the standard does not sanction it explicitly.

**Fix.** No change recommended until the standard rules on it — see **Open questions**. If passing
cubits through `extra` is ruled out, the fix is to hoist `ClassroomCubit` and
`SchedulingStaffListCubit` to a shared parent scope that both the entry screen and the shift routes
sit inside, so the route builder can read rather than create. That is a larger change and should
not be made on this audit's authority alone.

---

### Mandate 2 — State: setState scarcely, ValueNotifier for UI micro-state

**Verdict: Partially violated** (3 violations, highest Low)

Measured — **the best state-management result in the codebase**:

| Check | Scheduling | Classroom | Attendance/Kiosk | Activity |
|---|---|---|---|---|
| `setState` calls | **3** | 82 | 198 | 338 |
| `StatelessWidget` : `StatefulWidget` | **50 : 9** | 24 : 15 | 65 : 39 | 24 : 27 |
| `ValueListenableBuilder` | **4** | 0 | 0 | 1 |

**What is compliant.** All three `setState` calls sit in one file. The 13 `view_model/` files are
real cubits with `Equatable` state and `copyWith`, and the two heaviest
(`add_shift_cubit.dart` 902 lines, `edit_shift_cubit.dart` 800) own the shift create/edit logic
rather than leaving it in the screens — the screens are 593 and 639 lines against cubits of 902
and 800, an inversion not seen in any other module. `scheduling_school_scope_mixin.dart` factors
shared school-scope resolution across cubits. There is no Bucket A state in any widget.

---

#### 2.1 — All four `ValueListenableBuilder`s omit `child:`

**Rule broken.** MANDATE 2: *"`ValueListenableBuilder` takes a `child:` that is built once and
handed to the builder untouched. **Use it.** That is the actual performance win over `setState`
and the reason this rule exists."*

**Where.** Four sites, each discarding the third builder parameter and passing no `child:`:

```dart
// scheduling_day_timeline.dart:429-431
return ValueListenableBuilder<int?>(
  ...
  builder: (context, selectedIndex, _) => SchedulingDayTimelineTrack(

// scheduling_day_timeline.dart:531-533  — same shape
// day_classroom_section.dart:222-224
return ValueListenableBuilder<bool>(
  ...
  builder: (context, expanded, _) => Column(

// day_classroom_section.dart:300-302  — same shape
```

**Why it violates.** The `_` is the `child` slot and it is discarded at all four sites. The module
adopted the right half of the Bucket B pattern (a held, disposed `ValueNotifier` driving a
targeted rebuild) but not the half the rule exists for — the invariant subtree built once. In
`day_classroom_section.dart` the builder returns a `Column` whose non-expanding children are
rebuilt on every expand/collapse.

**Severity: Low.** Four sites; the wasted work is a small subtree each. The module is already far
ahead of the codebase on this mandate.

**Fix.** Pass the invariant part — the section header in `day_classroom_section.dart`, the static
track chrome in `scheduling_day_timeline.dart` — as `child:` and consume it in the builder. Verify
the expand/collapse and selection behaviour is unchanged.

---

#### 2.2 — Three `setState` calls hold Bucket B micro-state

**Rule broken.** MANDATE 2, Bucket B: *"expand/collapse, tab index, chip selection, visibility
toggles → `ValueNotifier` + `ValueListenableBuilder`."*

**Where.** [scheduling_screen.dart:104, 384, 403](lib/presentation/features/scheduling/view/scheduling_screen.dart#L104)

```dart
// :104
setState(() => _tappedHighlightClassroomCode = classroomCode);
// :384 and :403 — the same toggle, twice
onToggleExpandAll: () => setState(() => _expandAll = !_expandAll),
```

**Why it violates.** `_expandAll` is an expand/collapse toggle and
`_tappedHighlightClassroomCode` is a transient selection — both Bucket B by name, and both routed
to `ValueNotifier` by the rule. Each `setState` currently rebuilds the whole 637-line screen's
`build`. The same widget already uses `ValueNotifier` correctly two files away in
`day_classroom_section.dart`, so the pattern is established in the module.

**Severity: Low.** Three calls on one screen; the rebuild is real but bounded, and this is the
smallest `setState` footprint of any module audited.

**Fix.** Convert both fields to `ValueNotifier` held as final fields and disposed, wrapping only
the affected subtrees in `ValueListenableBuilder` — with `child:`, per §2.1. Note `_expandAll` is
toggled from two call sites (384 and 403) that pass it down to two different child widgets, so
confirm both still react.

---

#### 2.3 — Zero `BlocSelector` across eight `BlocBuilder`s

**Rule broken.** MANDATE 2: *"Use `BlocSelector` where only a small part of the UI depends on one
state property."*

**Where.** 8 `BlocBuilder` and 1 `BlocConsumer`, 0 `BlocSelector`. The states are wide —
`SchedulingState` (87 lines), `StaffSchedulingState` (141), `AddShiftState` (224).

**Why it violates.** Every `BlocBuilder` rebuilds its subtree on any state change. With
`AddShiftState` at 224 lines, a change to one validation flag rebuilds the whole form.

**Severity: Low.** A performance rule, and the module's subtrees are already well decomposed into
50 `StatelessWidget`s, which limits the cost.

**Fix.** Apply `BlocSelector` opportunistically where one small widget reads one property —
submit-button enablement, error text, the selected-day chip. Not worth a dedicated sweep.

---

### Mandate 3 — Folder structure, followed strictly

**Verdict: Violated** (5 violations, highest High)

**What is compliant.** The presentation layer has `model/`, `view/`, `view_model/` and `widgets/`
— all four canonical folders, correctly named. PDF §3.2 records that *"Only scheduling has one"*
`model/` folder; that is now outdated in a good way — 10 of 19 features have one, and scheduling
established the pattern. PDF §3.3 names `scheduleDataModel.dart` for renaming to
`schedule_data_model.dart`; searching the tree returns nothing, so the file is gone. The domain
layer has `entities/`, `repositories/` and `usecases/`.

---

#### 3.1 — The domain layer imports Flutter (the only module in the codebase that does)

**Rule broken.** MANDATE 3: *"Domain entities are **pure Dart with no Flutter imports** and no
`fromJson`/`toJson`."* PDF §3.1: `domain/` holds *"Pure Dart. NO fromJson/toJson here."*

**Where.** Five files under `lib/domain/features/scheduling/` import
`package:flutter/material.dart`, with **26** `TimeOfDay` references:

| File | Line | Use |
|---|---|---|
| [entities/staff_shift.dart](lib/domain/features/scheduling/entities/staff_shift.dart#L2) | 2 | `TimeOfDay startTime/endTime/breakStartTime/breakEndTime` on `StaffShift` and three request entities |
| [entities/classroom_forecast_block.dart](lib/domain/features/scheduling/entities/classroom_forecast_block.dart#L2) | 2 | `TimeOfDay blockStart/blockEnd` |
| [repositories/staff_shift_repository.dart](lib/domain/features/scheduling/repositories/staff_shift_repository.dart#L1) | 1 | `TimeOfDay` in `ClassroomForecastQuery` / `ClassroomForecastRangeQuery` |
| [usecases/get_classroom_forecast_usecase.dart](lib/domain/features/scheduling/usecases/get_classroom_forecast_usecase.dart#L1) | 1 | forecast query parameters |
| [usecases/get_classroom_forecast_range_usecase.dart](lib/domain/features/scheduling/usecases/get_classroom_forecast_range_usecase.dart#L1) | 1 | forecast query parameters |

```dart
// domain/features/scheduling/entities/staff_shift.dart:1-2
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
...
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final TimeOfDay? breakStartTime;
```

**Why it violates.** The rule states domain entities are pure Dart with no Flutter imports, without
qualification, and here the breach extends past entities into two use cases and a repository
contract. `TimeOfDay` is a `package:flutter/material.dart` type. The comparative measurement is
stark: **Activity 0, Attendance 0, Kiosk 0, Classroom 0, Scheduling 5.** The practical consequence
is that this domain layer cannot be exercised without the Flutter framework — a pure-Dart unit test
or any non-Flutter reuse pulls in the widget library — and the layer boundary the standard is built
around is broken at its innermost ring.

**Severity: High.** The only domain-purity breach in the codebase, spanning entities, use cases and
a contract, on a module with zero test coverage to catch a regression during the fix.

**Fix.** Replace `TimeOfDay` in the domain with a pure-Dart time-of-day value — either a small
`ShiftTime` value object (hour/minute) in `domain/features/scheduling/entities/`, or minutes-past-
midnight as an `int`. Convert to and from `TimeOfDay` at the presentation boundary and in the data
models. This touches 26 references across 5 domain files plus their callers, so do it after
characterisation tests exist (see the remediation order) — the shift start/end/break times are the
module's core data and a silent off-by-one in the conversion would be hard to spot.

---

#### 3.2 — A forbidden `utils/` folder holding 1,098 lines, including a mapper and style constants

**Rule broken.** MANDATE 3: *"A presentation `util/` or `utils/` folder should not exist. Pure
business rules go to `domain/features/<x>/usecases/` or a domain service; mappers go to
`data/features/<x>/mappers/`; presentation helpers go to `widgets/` or `core/extensions/`."*

**Where.** [lib/presentation/features/scheduling/utils/](lib/presentation/features/scheduling/utils/)
— 5 files, 1,098 lines:

| File | Lines | What it is | Belongs in |
|---|---|---|---|
| `scheduling_block_status_style.dart` | 590 | Ratio-status colour constants + status logic | `core/theme` (colours, §4.3) + domain (status rules) |
| `forecast_slot_mapper.dart` | 236 | Model→UI slot mapping | `data/features/scheduling/mappers/` (§3.4) |
| `school_hours_resolver.dart` | 172 | School operating-hours resolution | domain service |
| `classroom_name_resolver.dart` | 78 | Code→name resolution | domain service |
| `scheduling_cache_gate.dart` | 22 | Cache gating rule | data layer |

**Why it violates.** The folder name is explicitly forbidden and none of the five files is a
presentation helper — they are business rules, a mapper, cache policy and theme constants. The
largest, `scheduling_block_status_style.dart` at 590 lines, is simultaneously the module's colour
palette (§4.3) and its ratio-status decision logic.

**Severity: High.** A forbidden folder holding the module's ratio-status rules — the logic that
decides whether a classroom is under-staffed — at 1,098 lines with no test coverage.

**Fix.** Retire by destination, in tranches. `classroom_name_resolver.dart` and
`school_hours_resolver.dart` become domain services (the module already has a `services/` folder,
see §3.3). `forecast_slot_mapper.dart` moves to the new `mappers/` folder from §3.4.
`scheduling_cache_gate.dart` moves to the data layer. `scheduling_block_status_style.dart` splits:
colours to `core/theme/app_colors.dart` (§4.3), status rules to domain.

---

#### 3.3 — A non-canonical `navigation/` folder, and a `services/` folder in domain

**Rule broken.** MANDATE 3, canonical presentation layout:
```
presentation/features/<feature>/
  model/  view/  view_model/  widgets/
```
and per layer: `domain/features/<feature>/  entities/  repositories/  usecases/`.

**Where.** Two non-canonical folders, with different standing:

```
presentation/features/scheduling/navigation/scheduling_shift_navigator.dart  (335 lines)
domain/features/scheduling/services/  (scheduling_school_time.dart 28, staff_hours_aggregator.dart 59)
```

**Why it violates — with a distinction.** `navigation/` is a clear breach: it is a fifth
presentation folder outside the four the standard names, holding `SchedulingShiftNavigator`, a
presentation navigation helper that belongs in `widgets/` or `core/extensions/`. Its contents are
otherwise compliant — it uses `context.push` and `SchedulingRoutes` correctly.

`domain/.../services/` is **ambiguous**. The canonical tree lists only `entities/`,
`repositories/`, `usecases/` — but `docs/mandate-rules.md`'s Mandate 3 text explicitly sanctions
the concept: *"Pure business rules go to `domain/features/<x>/usecases/` **or a domain service**"*,
and §3.3 of the PDF likewise says such rules *"belong in `domain/features/<x>/usecases/` or as
domain services"*. The folder holds exactly that: `StaffHoursAggregator` is pure, static, testable
aggregation logic. The rules text permits it; the tree diagram does not list it. Flagged rather
than graded — see **Open questions**.

**Severity: Medium.** `navigation/` is one file in the wrong place with no functional effect;
`services/` is arguably correct.

**Fix.** Move `scheduling_shift_navigator.dart` into `widgets/` (it takes `BuildContext` and drives
UI flows) or `core/extensions/`. Leave `domain/services/` alone pending the ruling in **Open
questions** — moving compliant, well-factored pure logic on a tree-diagram technicality would be
churn.

---

#### 3.4 — No `mappers/` folder in the data layer

**Rule broken.** MANDATE 3, per-layer structure:
`data/features/<feature>/  datasource/  models/  mappers/  repository/`. MANDATE 8: *"Mappers
convert model → entity, which is what `mappers/` is for."*

**Where.** `lib/data/features/scheduling/` has `datasources/`, `models/`, `repositories/` — no
`mappers/`. Conversion happens in two other places instead: `toEntity()`-style methods on the
models, and `forecast_slot_mapper.dart` (236 lines) filed under the **presentation** `utils/`
folder (§3.2).

**Why it violates.** The required folder is absent, and one of the module's mappers has ended up in
the presentation layer as a result. Classroom, audited previously, does have a `mappers/` folder —
so the pattern exists in-repo to copy.

**Severity: Medium.** Structural; it compounds §3.2 because the misplaced mapper has nowhere
correct to move to.

**Fix.** Create `data/features/scheduling/mappers/`, move `forecast_slot_mapper.dart` into it, and
consolidate the model-side conversions there as part of the Mandate 8 work (§8.1). Do it in that
order — generated models make mappers trivial, so creating the folder first and filling it twice is
wasted effort.

---

#### 3.5 — More cross-folder relative imports than `package:` imports

**Rule broken.** MANDATE 3, Imports: *"all cross-folder imports use `package:wowcare/...`.
Relative imports only within the same folder."*

**Where.** **180** imports beginning `../` against **141** `package:wowcare/` imports — the only
module audited where relative imports outnumber package imports (Activity 256:419,
Attendance/Kiosk 232:1152, Classroom well under).

```dart
// domain/features/scheduling/repositories/staff_shift_repository.dart:3-5
import '../entities/classroom_forecast_block.dart';
import '../entities/staff_shift.dart';
import '../entities/staff_shift_hours_entry.dart';
```

**Why it violates.** Cross-folder imports must use the `package:` form. Note the specific hazard
§3.4 describes — an import with one excess `..` compiles in the app but breaks when a test reaches
the file by `file:` URI. **I resolved every relative import in the module and all point at real
files**, so that latent breakage is absent. With zero tests referencing this module, nothing
currently reaches these files by any route.

**Severity: Low.** No broken imports; mechanical consistency only.

**Fix.** Single codemod converting `../`-crossing imports to `package:wowcare/...`, leaving
same-folder relative imports alone. Run after §3.2–§3.4 have moved files, not before.

---

### Mandate 4 — Centralized theming, constants, strings, colors, fonts, sizes

**Verdict: Violated** (5 violations, highest High)

Measured — **the weakest theming result of the four modules audited**:

| Check | Count | Status |
|---|---|---|
| `fontFamily:` | **0** | Compliant |
| Raw `Colors.<name>` | **55** | Violated |
| `Color(0x...)` | **24** | Violated |
| Inline `TextStyle(` | **98** | Violated |
| `AppColors.` uses | 112 | partial |
| `AppTextStyles.` uses | **0** | Violated |
| `AppStrings.` uses | **0** | Violated |
| `AppSpacing`/`AppRadius`/`AppDimensions`/`AppSizes` uses | **0** | Violated |
| `Theme.of(context).textTheme` uses | **0** | Violated |

The one clean result: **zero `fontFamily:` lines**, where Classroom has 57 and Activity 3.

---

#### 4.1 — 79 hardcoded colour references alongside 112 tokenised ones

**Rule broken.** MANDATE 4: *"No `Color(0x...)` and no `Colors.<name>` outside
`core/theme/app_colors.dart`. Resolve through `AppColors` or `Theme.of(context).colorScheme`."*

**Where.** 55 raw `Colors.*` and 24 `Color(0x…)` across 14 files, against 112 `AppColors` uses in
the same module. Highest concentrations: `staff_day_schedule_calendar.dart` 9,
`edit_shift_screen.dart` 8, `add_shift_screen.dart` 8, `staff_scheduling_screen.dart` 6,
`scheduling_day_timeline.dart` 5, `view_shift_screen.dart` 5.

```dart
// view/staff_scheduling_screen.dart:766
border: Border.all(color: const Color(0x19162831)),
// view/scheduling_screen.dart:532, 602  and  widgets/day_gantt_table.dart:23
border: Border.all(color: const Color(0x33162831)),
// widgets/staff_scheduling_staff_dropdown.dart:52
color: const Color(0xFFB1AFE9).withValues(alpha: 0.102),
```

**Why it violates.** The prohibition is unconditional. This is a half-migrated state, which is
harder to reason about than an unmigrated one: a theme change updates the 112 tokenised references
and leaves 79 behind on the same screens.

**Severity: High.** Nearly half the module's colour references bypass the token layer, on the
screens a scheduler uses daily, and dark mode cannot work while they remain.

**Fix.** Tokenise the 79 against `AppColors`. Rendered output must be **identical in light mode** —
where a hex has no matching token, add the token with that exact value rather than substituting the
nearest, and list every token added. Start with the seven duplicated hexes identified in §4.3,
since one token replaces several literals.

---

#### 4.2 — 98 inline `TextStyle(` constructors and zero `AppTextStyles` uses

**Rule broken.** MANDATE 4: *"No inline `TextStyle(`. Use `Theme.of(context).textTheme.<slot>` or
a named `AppTextStyles` entry; local variation uses `.copyWith()` on a named style, never a fresh
`TextStyle`."*

**Where.** 98 inline constructors across 13 files: `scheduling_day_timeline.dart` 18,
`edit_shift_screen.dart` 13, `add_shift_screen.dart` 12, `staff_scheduling_screen.dart` 11,
`staff_day_schedule_calendar.dart` 10, `view_shift_screen.dart` 10, `staff_schedule_tile.dart` 6,
`shift_override_bottom_sheet.dart` 4, and five more.

`AppTextStyles.` appears **0 times**, though
[core/theme/app_text_styles.dart](lib/core/theme/app_text_styles.dart) is 1,319 lines with 70
importers app-wide. `Theme.of(context).textTheme` is likewise unused.

**Why it violates.** The rule names both destinations and the module uses neither. This is the
highest inline-`TextStyle` count of the four modules (Classroom 59, Kiosk 20, Attendance 0,
Activity 0). Each hand-written style restates every property, so it tracks nothing.

**Severity: High.** The module's entire typography layer sits outside the theme system.

**Fix.** Add named `AppTextStyles` entries for the repeated size/weight combinations — there are
far fewer distinct styles than 98 sites — and replace the inline constructors, using `.copyWith()`
for local variation. Where a combination has no matching entry, add it with those exact values.

---

#### 4.3 — Semantic ratio-status colours defined in the feature, with the same hex in up to four places

**Rule broken.** MANDATE 4: *"**Colours that encode meaning** (status, compliance, workflow state)
become *named semantic* tokens, not generic palette entries — and must stay distinguishable by
something other than colour alone."*

**Where.** Two feature files define the module's status palette as local constants:

```dart
// utils/scheduling_block_status_style.dart:23-35
static const Color dayUnderRatioColor = Color(0xFFF38D8D);   // under-staffed
static const Color dayInRatioColor    = Color(0xFFACF3AA);   // compliant
static const Color dayExtraStaffColor = Color(0xFF5978F7);   // over-staffed
static const Color dayEmptyColor      = Color(0xFFE9ECEF);
static const Color badgeInRatioColor  = Color(0xFF3D9A4A);

// model/scheduling_staff_shift_style.dart:10-12  — the same three hexes again
static const Color workTimeColor    = Color(0xFFACF3AA);
static const Color breakTimeColor   = Color(0xFFF38D8D);
static const Color outsideShiftColor = Color(0xFFE9ECEF);
```

and the same values recur as loose constants elsewhere:

```dart
// widgets/day_classroom_section.dart:15
const Color kSchedulingGridColor = Color(0xFFE9ECEF);
// widgets/scheduling_day_timeline.dart:356
static const Color dividerColor = Color(0xFFE9ECEF);
```

Duplicate counts across the module: `0xFFE9ECEF` ×4, `0xFF8B7B89` ×3, `0x33162831` ×3,
`0xFFF38D8D` ×2, `0xFFACF3AA` ×2, `0x66573353` ×2, `0x19162831` ×2.

**Why it violates.** These encode ratio compliance — the module's core signal — so the rule
requires *named semantic tokens*, and they are named, which is the right instinct. But they are
defined in the feature rather than `core/theme/app_colors.dart`, and the same value is redeclared
in up to four files under four different names, so a ratio-colour change requires finding all of
them. The rule's second clause also applies: the ratio state must stay distinguishable by something
other than colour alone, and I could not find a non-colour cue accompanying the day-status blocks.

**Severity: Medium.** Correct semantics in the wrong location, with a real fan-out cost; the
colour-only encoding is an accessibility concern the standard names explicitly.

**Fix.** Move the semantic names into `core/theme/app_colors.dart`
(`schedulingUnderRatio`, `schedulingInRatio`, `schedulingExtraStaff`, `schedulingEmptyBlock`),
collapse the duplicate hexes onto them, and have both feature style files reference the tokens.
Separately, confirm whether the ratio blocks carry a text or icon cue; if not, that is a distinct
accessibility fix the mandate calls for.

---

#### 4.4 — `AppStrings` is never used; ~64 user-visible literals

**Rule broken.** MANDATE 4: *"No user-visible string literal in a view file. Everything through
`AppStrings` (`lib/core/constants/app_strings.dart`)."*

**Where.** `AppStrings.` appears **0 times**. Measured: 4 `Text('literal')` and 60
`message:`/`title:`/`label:`/`hintText:` literals across the views, widgets and bottom sheets.

**Why it violates.** The rule is absolute for view files, and the infrastructure exists and is used
by 17 files elsewhere in the app.

**Severity: Medium.** No functional risk; it blocks localisation, which the standard names as the
main reason to do Mandate 4 properly.

**Fix.** Extract to `AppStrings`, highest-traffic first. Apply the mandate's exclusion — skip log
tags, storage keys, API payload keys and backend enum values; the shift status strings
(`PUBLISHED`, block-status codes) are wire values and must stay.

---

#### 4.5 — 183 magic spacing and radius literals, with no spacing token family in use

**Rule broken.** MANDATE 4: *"No magic spacing. `AppSizes`
(`lib/core/constants/app_sizes.dart`)."*

**Where.** Measured with a balanced-parenthesis parser that excludes token references: **183**
magic spacing/radius literals. The module uses **neither** available family — `AppSizes.` 0 uses,
`AppSpacing`/`AppRadius`/`AppDimensions` 0 uses.

Partial mitigation exists: `SchedulingResponsive`
([model/scheduling_responsive.dart:26-35](lib/presentation/features/scheduling/model/scheduling_responsive.dart#L26-L35))
centralises nine size/spacing values behind named getters (`verticalSpacing`, `inputFieldHeight`,
`buttonHeight`), so some spacing does resolve through a single place — just a feature-local one
rather than a shared token file.

**Severity: Medium.** Cosmetic drift, largely unmitigated.

**Fix.** Blocked on the app-wide `AppSizes` vs `AppSpacing` decision (see **Open questions**;
raised in both prior audits). Once settled, sweep per file and fold `SchedulingResponsive`'s nine
hardcoded pairs into the chosen family.

---

### Mandate 5 — Presentation talks to cubits only

**Verdict: Partially violated** (2 violations, highest Medium)

Measured — **the second-strongest layer-discipline result**, after only the count of breaches:

| Check | Count | Status |
|---|---|---|
| `serviceLocator<T>()` in presentation | **4** | see §5.2 |
| `DataSource` / `Repository` / `RepositoryImpl` types in presentation | **0** | Compliant |
| `Dio` / `ApiClient` / `SharedPreferences` in presentation | **0** | Compliant |
| `FutureBuilder` / `StreamBuilder` | **0** | Compliant |
| Direct use-case invocation from a view or widget | **0** | Compliant |

For comparison, Classroom resolves 17 use cases directly from views and Attendance makes 60
`serviceLocator` calls. Scheduling's four are all `BlocProvider` wiring for the screen's own cubit,
and every use case reaches the views through a cubit.

---

#### 5.1 — `StorageService` held by six cubits and exposed through a mixin

**Rule broken.** MANDATE 5, forbidden anywhere under `lib/presentation`: *"`DataSource`,
`Repository`, `RepositoryImpl`, `ApiClient`, `Dio`, `StorageService`, `SharedPreferences`
types"*.

**Where.** Six cubits take and hold it, and a mixin makes it part of a shared contract:

```dart
// view_model/scheduling_school_scope_mixin.dart:17
StorageService get storageService;

// view_model/scheduling_cubit.dart:43, 73, 105
required StorageService storageService,
final StorageService _storageService;
StorageService get storageService => _storageService;
```

Same in `staff_scheduling_cubit.dart:39,70,109`, `scheduling_staff_list_cubit.dart:20,28,31`,
`add_shift_cubit.dart:39,57`, `edit_shift_cubit.dart:37,57`, `publish_shifts_cubit.dart:19,29`.

**Why it violates.** The prohibition is on the type appearing anywhere under `lib/presentation`,
not only in view files. The mixin is the notable part: `scheduling_school_scope_mixin.dart:17`
declares `StorageService get storageService;` as an abstract member, so the forbidden type is
baked into a contract every scheduling cubit implements rather than being an incidental field.

**Severity: Medium.** Confined to the view-model layer — no view names the type — but a mixin makes
it structural rather than incidental, so it will propagate to the next cubit added.

**Fix.** Introduce a narrow domain service for what these cubits actually read from storage — the
school and organisation codes the mixin resolves — and have the mixin depend on that abstraction
instead. This is one change to the mixin plus six constructor signatures; behaviour is unchanged
because the underlying reads are the same.

---

#### 5.2 — Four `serviceLocator` calls in view `BlocProvider` rather than the route builder

**Rule broken.** MANDATE 5: *"No `serviceLocator<T>()` in `lib/presentation`. Cubits are created in
the router, in the `GoRoute` builder, wrapped in a `BlocProvider`. That is the only place the
service locator appears on the presentation side."*

**Where.** Four sites, each the screen providing its own cubit:

```dart
// view/scheduling_screen.dart:64
value: serviceLocator<SchedulingCubit>(),
// view/add_shift_screen.dart:57
create: (_) => serviceLocator<AddShiftCubit>()
// view/edit_shift_screen.dart:90
create: (_) => serviceLocator<EditShiftCubit>()
// view/publish_shifts_screen.dart:62
create: (_) => serviceLocator<PublishShiftsCubit>()
```

**Why it violates.** The rule permits `serviceLocator` in exactly one place — the `GoRoute` builder
— and these are in the screens. The mitigating facts are real: all four wrap the cubit in a
`BlocProvider` so the lifecycle is owned and disposal is automatic, and each screen provides only
its own cubit rather than reaching for another feature's. This is the mildest form of the
violation; Classroom, by contrast, resolves cubits inside `build()` and inside
`MaterialPageRoute` builders.

**Severity: Medium.** A rule with a single permitted location, broken four times — but with correct
lifecycle ownership and no cross-feature reach.

**Fix.** Move the four creations into the corresponding `GoRoute` builders in `app_router.dart`,
which already register all six screens. Heed §5.4: three of the four cascade initialisation off the
resolve, so verify the network call count entering and returning to each screen is unchanged.
Note this interacts with §1.2 — if cubits stop being passed through `extra`, the provider scoping
has to be resolved at the same time.

---

### Mandate 6 — Reuse what exists; pure functions out of build()

**Verdict: Violated** (5 violations, highest High)

**What is compliant.** Only **one** duplicate class name involves this module, and both copies are
private and inside the module — no cross-feature collisions at all, the cleanest result of the four
audits (Classroom had 4, Attendance/Kiosk 5). Pure logic is properly extracted:
`StaffHoursAggregator` (domain, static and testable) and `SchedulingJsonParsing` (data, centralised
coercion) are both the shape Mandate 6 asks for. The 50-to-9 `StatelessWidget` ratio means the UI
is genuinely decomposed.

---

#### 6.1 — Fifteen of 73 files exceed the 400-line ceiling; the largest is 1,163

**Rule broken.** MANDATE 6: *"File size ceiling: 400 lines. Split by extracting cohesive units,
not arbitrarily at line 400."* PDF §9.3 gate 11.

**Where.**

| File | Lines |
|---|---|
| `widgets/scheduling_day_timeline.dart` | **1,163** |
| `view/staff_scheduling_screen.dart` | **1,113** |
| `view_model/add_shift_cubit.dart` | **902** |
| `view_model/edit_shift_cubit.dart` | **800** |
| `view_model/scheduling_cubit.dart` | **775** |
| `view_model/staff_scheduling_cubit.dart` | 655 |
| `view/edit_shift_screen.dart` | 639 |
| `view/scheduling_screen.dart` | 637 |
| `view/add_shift_screen.dart` | 593 |
| `utils/scheduling_block_status_style.dart` | 590 |
| `view/view_shift_screen.dart` | 556 |
| `widgets/staff_day_schedule_calendar.dart` | 524 |
| `data/.../staff_shift_remote_datasource.dart` | 519 |
| `widgets/staff_schedule_tile.dart` | 440 |
| `data/.../models/staff_shift_models.dart` | 418 |

**Why it violates.** The ceiling is 400 and the largest is 2.9× over. `scheduling_day_timeline.dart`
at 1,163 lines is a **widget** file. Unlike other modules, the largest offenders here include four
cubits — which is a consequence of the module's good Mandate 2 behaviour (logic pulled out of
widgets) landing in files that then grew past the ceiling.

**Severity: High.** Fifteen files over, five of them over 650, and `add_shift_cubit.dart` /
`edit_shift_cubit.dart` hold the create/edit validation logic with no tests covering it.

**Fix.** Split by cohesive unit. The two shift cubits divide along validation / conflict-resolution
/ submission; `scheduling_day_timeline.dart` divides at the track, the ruler and the block
renderers. Do the cubits after §8's characterisation tests exist, since that is where the untested
logic lives.

---

#### 6.2 — `_RadioDot` duplicated with incompatible constructors

**Rule broken.** MANDATE 6: *"**No two classes in the codebase share a name.** Diff each collision
before merging — copies with the same name often have different constructors and are not
interchangeable."*

**Where.** Two private widgets, both inside this module:

```dart
// view/publish_shifts_screen.dart:344 — takes a selection flag
class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;
  ...
        color: selected
            ? AppColors.themeColor
            : AppColors.primaryColor.withValues(alpha: 0.4),

// view/view_shift_screen.dart:530 — takes nothing, always "selected"
class _RadioDot extends StatelessWidget {
  const _RadioDot();
  ...
        color: AppColors.themeColor,
```

**Why it violates.** Same name, different constructors, different behaviour — the second is the
first with `selected: true` hardcoded. This is the §6.6 non-interchangeability pattern in
miniature.

**Severity: Medium.** Both are private so they cannot collide at compile time, and both live in
this module — but the two screens now render radio dots from separate implementations that could
drift.

**Fix.** Keep the parameterised version from `publish_shifts_screen.dart`, promote it to
`widgets/`, and have `view_shift_screen.dart` use it with `selected: true`. Diff the rendered
output first — the sizes are the same (20×20, width 2) but confirm the unselected colour is not
needed at the second site.

---

#### 6.3 — `SchedulingResponsive` reimplements the shared `ResponsiveHelper` API

**Rule broken.** MANDATE 6: *"Before writing a widget, search `core/widgets/`,
`shared/common/widgets/` and the feature's own `widgets/`. Extend with a parameter rather than
copying."*

**Where.** [model/scheduling_responsive.dart](lib/presentation/features/scheduling/model/scheduling_responsive.dart)
duplicates the property surface of `lib/shared/utils/responsive_helper.dart` (116 importers), and
its own doc comment says so:

```dart
/// Scheduling's per-screen responsive values, sourced from the single
/// [AppBreakpoints] definition (600/1024) instead of measuring `MediaQuery`
/// directly. Mirrors the property surface of `shared/utils/responsive_helper.dart`
/// (still used elsewhere in the app) so call sites in this feature needed no
/// changes beyond swapping the constructor — only the breakpoint source
/// changed, not the API.
```

The nine value getters (`titleFontSize`, `labelFontSize`, `inputFontSize`, `verticalSpacing`,
`horizontalSpacing`, `inputFieldHeight`, `buttonHeight`, `buttonFontSize`, `containerWidth`) are
value-for-value identical to `ResponsiveHelper`'s.

**Why it violates — with a caveat.** It is a deliberate copy, and it was made to *improve*
compliance: it moved this feature off `MediaQuery` measurement onto `AppBreakpoints` (§7) without
touching the 116 importers of the shared helper. That is a defensible migration tactic. But the
outcome is two classes with the same nine getters and the same magic values, and the mandate's
remedy for "close but not identical" is to extend the existing one, not fork it.

**Severity: Medium.** A duplicate of a widely-used helper, created for a good reason, that will
drift once either side's values change.

**Fix.** Redirect `ResponsiveHelper` itself to `AppBreakpoints` — which the attendance audit
records has **already happened** for that file — and then delete `SchedulingResponsive`, pointing
its call sites at the shared helper or, better, at `context.responsive(...)` directly. Verify the
nine values resolve identically at 375, 768 and 1024 before deleting.

---

#### 6.4 — Twenty-eight `Widget _buildXxx()` methods

**Rule broken.** MANDATE 6: *"Replace `Widget _buildXxx()` methods with private
`StatelessWidget` classes in the same file. A method returning a Widget cannot be `const`, cannot
take a key, and rebuilds with its whole enclosing widget."*

**Where.** 28 methods across 6 files: `staff_day_schedule_calendar.dart` 7,
`edit_shift_screen.dart` 6, `view_shift_screen.dart` 5, `add_shift_screen.dart` 5,
`day_classroom_section.dart` 3, `publish_shifts_screen.dart` 2.

**Why it violates.** Each rebuilds with its whole enclosing widget. The mitigating factor is that
this module already extracts 50 `StatelessWidget`s, so the enclosing widgets are smaller than in
other modules — but `staff_day_schedule_calendar.dart` is 524 lines with seven of them.

**Severity: Medium.** Mechanical; mostly a rebuild-cost issue.

**Fix.** Convert each to a private `StatelessWidget` in the same file, passing what it reads as
constructor parameters. Doing this first surfaces the seams for §6.1's file splits.

---

#### 6.5 — The same colour hex declared under four different names

**Rule broken.** MANDATE 6: *"Extract when the same UI appears more than once with identical
structure and different configuration."* (Applied to constants; see §4.3 for the theming half.)

**Where.** `Color(0xFFE9ECEF)` is declared four times under four names:
[scheduling_block_status_style.dart:29](lib/presentation/features/scheduling/utils/scheduling_block_status_style.dart#L29)
(`dayEmptyColor`),
[scheduling_staff_shift_style.dart:12](lib/presentation/features/scheduling/model/scheduling_staff_shift_style.dart#L12)
(`outsideShiftColor`),
[day_classroom_section.dart:15](lib/presentation/features/scheduling/widgets/day_classroom_section.dart#L15)
(`kSchedulingGridColor`),
[scheduling_day_timeline.dart:356](lib/presentation/features/scheduling/widgets/scheduling_day_timeline.dart#L356)
(`dividerColor`). Also `0xFF8B7B89` ×3 and `0x33162831` ×3.

**Why it violates.** Four names for one value, in four files, with no shared source. Whether they
are *meant* to be the same colour is undiscoverable from the code — which is precisely the cost.

**Severity: Low.** No defect; it makes §4.1's tokenisation ambiguous, since a reviewer must decide
whether four names collapse to one token or stay distinct.

**Fix.** Resolve as part of §4.3. Decide per name whether it is semantically the same colour
(collapse) or coincidentally equal (keep separate tokens with distinct names), then move all four
into `AppColors`.

---

### Mandate 7 — One responsive source

**Verdict: Partially violated** (2 violations, highest Low)

**What is compliant — and this is the best responsive result in the codebase.** Measured:

| Check | Count | Status |
|---|---|---|
| Screen-width literal comparisons | **0** | Compliant |
| `LayoutBuilder` instances | **0** | Compliant |
| `context.responsive` / `isTablet` / `screenSize` uses | **12** | Compliant |

Scheduling is the **first and only** module audited that actually reads the published size class
through the mandated API rather than measuring:

```dart
// widgets/scheduling_bottom_sheet_scaffold.dart:21-33 — the exact API §7.3 specifies
context.responsive(compact: 15.0, medium: 16.0, expanded: 18.0);
final isLargeTablet = context.screenSize == ScreenSizeClass.expanded;
context.responsive(compact: 16.0, medium: 24.0, expanded: 32.0);
```

```dart
// model/scheduling_responsive.dart:17-21 — delegates to AppBreakpoints, uses sizeOf
bool get isTablet => context.isTablet;
bool get isLargeTablet => context.screenSize == ScreenSizeClass.expanded;
double get screenWidth => MediaQuery.sizeOf(context).width;
```

The only width comparison in the module is
[staff_day_schedule_calendar.dart:284](lib/presentation/features/scheduling/widgets/staff_day_schedule_calendar.dart#L284)
— `if (contentHeight < 44)` — which measures the widget's own computed content height, not the
screen, and is therefore not a breakpoint. Activity, Attendance and Classroom all use
`context.responsive` zero times.

---

#### 7.1 — Four `MediaQuery.of(context)` reads where a field-scoped accessor exists

**Rule broken.** MANDATE 7: *"`MediaQuery.sizeOf(context)` over `MediaQuery.of(context)` — `.of`
subscribes to the whole object, so a width read re-runs on every keyboard open."*

**Where.** Four sites, all reading the same field:

```dart
// view/view_shift_screen.dart:73
final safeBottom = MediaQuery.of(context).padding.bottom;
// view/edit_shift_screen.dart:215
// view/publish_shifts_screen.dart:169
// view/add_shift_screen.dart:149
```

against three compliant `MediaQuery.sizeOf` uses and one `paddingOf`/`viewInsetsOf` elsewhere in
the module.

**Why it violates.** All four subscribe to the whole `MediaQuery` to read one field. The precise
counterpart for `padding` is `MediaQuery.paddingOf` — not named in the rule, which says `sizeOf`,
but the stated reason (field-scoped subscription) applies identically. `add_shift_screen.dart` and
`edit_shift_screen.dart` are forms with text fields, which is the keyboard-transition case the rule
describes.

**Severity: Low.** Four sites; redundant rebuilds on keyboard open, not incorrect layout. The
module already uses `paddingOf` once, so the pattern is present.

**Fix.** Swap all four to `MediaQuery.paddingOf(context).bottom`. Behaviour-preserving one-line
changes.

---

#### 7.2 — Hardcoded dimension pairs inside the responsive helper

**Rule broken.** MANDATE 7: *"No hardcoded pixel dimension for anything that should scale. Fixed
sizes are for icons and borders. Content uses `Flexible`, `Expanded`, `AspectRatio`, or
`AppSizes`."*

**Where.** [model/scheduling_responsive.dart:23-35](lib/presentation/features/scheduling/model/scheduling_responsive.dart#L23-L35)

```dart
double get containerWidth => isLargeTablet ? 1200.0 : MediaQuery.sizeOf(context).width;
double get titleFontSize => isTablet ? 24.0 : 18.0;
double get labelFontSize => isTablet ? 16.0 : 14.0;
double get verticalSpacing => isTablet ? 24.0 : 16.0;
double get inputFieldHeight => isTablet ? 56.0 : 48.0;
double get buttonHeight => isTablet ? 64.0 : 56.0;
```

**Why it violates — narrowly.** These are hardcoded pixel values for content that scales. But they
are *centralised* into one file and *do* respond to the size class, which is most of what the rule
wants; the residual issue is that the values live here rather than in a shared token family, and
that `titleFontSize`/`labelFontSize`/`buttonFontSize` are typography values outside
`AppTextStyles` (§4.2).

**Severity: Low.** Centralised and size-class-aware; the placement is the only issue.

**Fix.** Resolve alongside §4.5 and §6.3 — when `SchedulingResponsive` is retired in favour of the
shared helper or `context.responsive(...)`, these nine values move to the chosen spacing/type token
family rather than being re-hardcoded.

---

### Mandate 8 — Models everywhere, generated, never raw maps

**Verdict: Violated** (4 violations, highest High)

Measured:

| Check | Count | Target |
|---|---|---|
| `Map<String, dynamic>` in `lib/domain/features/scheduling` | **0** | **0** |
| `Map<String, dynamic>` in `lib/presentation/features/scheduling` | **0** | **0** |
| `@JsonSerializable()` classes | **0** | all models |
| `.g.dart` files | **0** | one per model |
| Hand-written `fromJson` factories | 4 | 0 |
| Hand-written `toJson` methods | 8 | 0 |
| Inline `fromJson` calls in datasources | 7 | 0 |
| `mappers/` folder | absent | present |

**What is compliant — and one result is a first.** Scheduling is the **only** module audited to
score zero `Map<String, dynamic>` in *both* the domain and presentation layers (Classroom had 0 and
10; Attendance 25 and 5; Activity 14 and 159). Request bodies are modelled as typed domain
entities — `StaffShiftCreateRequest`, `StaffShiftUpdateRequest`, `StaffShiftSeriesUpdateRequest`
([staff_shift.dart:78, 166, 223](lib/domain/features/scheduling/entities/staff_shift.dart#L78)) —
which is §8.4's *"Request bodies get request models too, not just responses"* satisfied. The
datasource returns typed models from 11 of its 12 methods. And
[models/scheduling_json_parsing.dart](lib/data/features/scheduling/models/scheduling_json_parsing.dart)
centralises the numeric-coercion defaulting rule that §8.1 counts as restated 321 + 171 + 113 + 51
times app-wide:

```dart
/// The backend sometimes sends numbers as JSON numbers and sometimes as numeric
/// strings … this centralizes the defaulting rule instead of restating it per
/// field, per model.
abstract final class SchedulingJsonParsing {
  static int intValue(dynamic value, {int fallback = 0}) { ... }
```

That is the right instinct, hand-rolled — it is what `@JsonKey(defaultValue:)` would declare.

---

#### 8.1 — No code generation; 12 hand-written serialisation members

**Rule broken.** MANDATE 8: *"Models are annotated `@JsonSerializable()` with generated
`fromJson`/`toJson` via `part 'x.g.dart'`. **No hand-written serialisation.**"*

**Where.** Zero `@JsonSerializable`, zero `.g.dart`. Four `fromJson` factories —
[staff_shift_models.dart:246, 381](lib/data/features/scheduling/models/staff_shift_models.dart#L246),
[staff_shift_hours_models.dart:52](lib/data/features/scheduling/models/staff_shift_hours_models.dart#L52),
[classroom_forecast_models.dart:35](lib/data/features/scheduling/models/classroom_forecast_models.dart#L35)
— and eight `toJson` methods across the same three files.

`json_annotation ^4.9.0` and `json_serializable ^6.8.0` are both in `pubspec.yaml`, and
`data/features/attendance/models/qr_validation_model.dart` is a working reference implementation
elsewhere in the repo.

**Why it violates.** The rule is "no hand-written serialisation" and the pipeline is installed and
proven in-repo. The eight `toJson` methods are the sharper half — they build the wire bodies for
shift create, update and series-update, the module's write paths.

**Severity: High.** Twelve hand-written serialisation members on the create/edit write paths, with
**no test anywhere covering this module** to catch a parse regression.

**Fix.** Convert model-by-model using `qr_validation_model.dart` as the template. The mandate
requires a characterisation test **before** deleting any parser — same fixture through old and new,
field-for-field, including nulls, missing keys and wrong types. Those tests are net-new here.
`SchedulingJsonParsing`'s coercion rules become `@JsonKey(defaultValue:)` / custom converters; the
`TimeOfDay` fields need a converter, and that interacts with §3.1 — settle the domain time type
first.

---

#### 8.2 — A datasource method takes a raw map body with no request model

**Rule broken.** MANDATE 8: *"Every API payload is represented by a model class in
`data/features/<x>/models/`. **Request models too, not just responses.**"* And: *"A view never
builds a wire payload… `toJson()` happens once, in the datasource."*

**Where.** [staff_shift_remote_datasource.dart:87](lib/data/features/scheduling/datasources/staff_shift_remote_datasource.dart#L87)
— the one method of twelve that is untyped:

```dart
Future<void> publishStaffShifts({required Map<String, dynamic> body});
```

against typed siblings such as:

```dart
Future<StaffShiftModel> updateStaffShift({ ... });
Future<StaffShiftCreateResultModel> updateStaffShiftSeries({ ... });
Future<List<ClassroomForecastBlockModel>> getClassroomForecast({ ... });
```

**Why it violates.** This is §8.3b's *"the pattern was established and then not followed"* case
inside a single file: three request entities exist for create/update/series-update, and the publish
path takes a bare map. Publishing is what makes shifts visible to staff, so it is a live write
path.

**Severity: Medium.** One method, and the map is assembled in the repository rather than a view —
so it does not cross the presentation boundary — but it is unchecked at the call site.

**Fix.** Add a `StaffShiftPublishRequest` entity alongside the three that exist, and a matching
request model, so the datasource takes a typed object and calls `toJson()` itself. Wire JSON must
stay byte-identical.

---

#### 8.3 — Seven inline `fromJson` calls in the datasource

**Rule broken.** MANDATE 8: *"Datasources call `Model.fromJson(response)` and return the model.
They do not read keys off a map."* PDF §8.2c tabulates
`data/features/scheduling/datasources/staff_shift_remote_datasource.dart` at **7** `fromJson`
calls.

**Where.** The count is **7** — unchanged from the reference commit.

**Why it violates.** The rule's intent is that parsing lives in the model, not the datasource. The
mitigating fact here is real: unlike the attendance datasource (which returns raw maps from twelve
methods), this one calls `Model.fromJson` and returns the **model** — so the parsing is delegated
correctly and the seven calls are the delegation itself, not inline key-reading. What §8.2c counts
as "parsing that leaked out of the models folder" is, in this file, the datasource invoking its
models.

**Severity: Medium.** Recorded because the standard counts it and the count has not moved; the
underlying pattern is closer to compliant than the raw number suggests.

**Fix.** Largely resolves with §8.1 — once the models are generated, these become calls to
generated constructors. The `getStaffAbsentDatesInRange` and `markStaffShiftAbsentDays` methods
return `List<DateTime>` and `int` directly and should be reviewed for whether a model is warranted.

---

#### 8.4 — No `mappers/` folder; conversion split between models and a presentation util

Covered in full under **§3.4** — it is simultaneously a Mandate 3 structure violation and the
Mandate 8 rule *"Mappers convert model → entity, which is what `mappers/` is for."* The specific
Mandate 8 consequence is that `forecast_slot_mapper.dart` (236 lines) performs model-to-UI mapping
from inside the presentation `utils/` folder. Counted once, in Mandate 3, and not double-counted in
the summary table. **Severity: Medium.**

---

## 4. Remediation order

Sequenced so each step is a single isolated change that preserves existing behaviour, and so no
step has to be redone by a later one. The ordering follows `docs/mandate-rules.md`'s revised
sequence (**1 → 5 → 2 → 3 → 6 → 4 → 7 → 8**) adapted to what this module actually needs.

**Before anything:** capture the baseline the guardrails require — `flutter analyze` on the three
module directories. **There is no `flutter test` baseline to capture: no test anywhere references
`features/scheduling`.** That is the defining constraint, and it is why step 1 writes tests before
any logic moves.

### Phase A — make the module verifiable (everything below depends on this)

| # | Change | Fixes | Why here |
|---|---|---|---|
| 1 | Write characterisation tests for `StaffHoursAggregator`, `SchedulingJsonParsing`, the block-status rules in `scheduling_block_status_style.dart`, and the add/edit shift validation in the two cubits | — | `docs/mandate-rules.md` names "the scheduling validators" for exactly this. The module has zero tests and the riskiest later steps (§3.1, §8.1) touch this logic. |
| 2 | Write characterisation tests for the 4 `fromJson` factories and 8 `toJson` methods | §8.1 prerequisite | The mandate requires this before any parser is deleted. Net-new work here. |

### Phase B — navigation and layer discipline (the "1 and 5 as a pair" step)

| # | Change | Fixes | Why here |
|---|---|---|---|
| 3 | Convert the seven screen-route `Navigator.pop` calls to `context.pop(result)` | §1.1 | Self-contained; leave the nine modal dismissals alone. Verify each result value still reaches its caller. |
| 4 | Replace `StorageService` on the mixin and six cubits with a narrow domain service | §5.1 | The mixin makes this structural, so fixing it stops the next cubit inheriting it. |
| 5 | Move the four `serviceLocator` cubit creations into the `GoRoute` builders | §5.2 | **Check §5.4**: three cascade initialisation off the resolve — count network calls before/after. Coordinate with the §1.2 decision, since provider scoping is shared. |

### Phase C — structure

| # | Change | Fixes | Why here |
|---|---|---|---|
| 6 | **Replace `TimeOfDay` in the domain with a pure-Dart time value**; convert at the presentation and data boundaries | §3.1 | **The module's most important change** — the only domain-purity breach in the codebase. Gated on step 1's tests because it touches shift start/end/break times everywhere. |
| 7 | Create `data/features/scheduling/mappers/`; move `forecast_slot_mapper.dart` into it | §3.4, §8.4 | Gives §3.2's mapper a correct destination. |
| 8 | Move `classroom_name_resolver.dart` and `school_hours_resolver.dart` to domain services; `scheduling_cache_gate.dart` to data | §3.2 (part) | Follows 7. The `services/` folder already exists. |
| 9 | Split `scheduling_block_status_style.dart`: status rules → domain, colours → held for step 14 | §3.2 (rest) | Do not move the colours yet — step 14 needs to decide the token names first. |
| 10 | Move `scheduling_shift_navigator.dart` out of `navigation/`; delete the folder | §3.3 | Import-only move. |
| 11 | Codemod relative → `package:` imports | §3.5 | After 6–10 have moved files, not before. |

### Phase D — reuse

| # | Change | Fixes | Why here |
|---|---|---|---|
| 12 | Consolidate the two `_RadioDot` copies into one parameterised widget in `widgets/` | §6.2 | Small, self-contained. Diff rendered output first. |
| 13 | Convert the 28 `Widget _buildXxx()` to private `StatelessWidget` classes | §6.4 | Surfaces the seams for step 15. |
| 14 | Retire `SchedulingResponsive`: point call sites at `context.responsive(...)` / the shared helper | §6.3, §7.2 | `ResponsiveHelper` already delegates to `AppBreakpoints` (per the attendance audit), so the migration reason has lapsed. Verify all nine values at 375/768/1024 before deleting. |
| 15 | Split the 15 files over 400 lines by cohesive unit — the two shift cubits first | §6.1 | After 13, and after step 1's tests cover the cubit logic being split. |

### Phase E — theming (deliberately after Phase D)

| # | Change | Fixes | Why here |
|---|---|---|---|
| 16 | Decide which duplicate hexes are semantically one colour; move the semantic ratio tokens into `AppColors`; add a non-colour cue to the ratio blocks | §4.3, §6.5 | **Per `docs/mandate-rules.md`'s "Move 6 before 4"** — doing this earlier would tokenise constants step 9 is about to relocate. |
| 17 | Tokenise the remaining 79 raw colour references against `AppColors` | §4.1 | Follows 16, which resolves the ambiguous duplicates first. |
| 18 | Add named `AppTextStyles` entries; replace the 98 inline `TextStyle(` constructors | §4.2 | Largest single theming item. Rendered output must be identical. |
| 19 | Extract user-visible strings to `AppStrings` | §4.4 | Skip wire values (shift statuses, block-status codes). |
| 20 | Adopt a spacing token family across the 183 magic literals | §4.5 | Blocked on the app-wide `AppSizes` vs `AppSpacing` decision. **Do not migrate this module in isolation.** |

### Phase F — responsiveness

| # | Change | Fixes | Why here |
|---|---|---|---|
| 21 | Swap the four `MediaQuery.of(context).padding.bottom` reads for `paddingOf` | §7.1 | One line each; the module already uses `paddingOf` once. |

### Phase G — models

| # | Change | Fixes | Why here |
|---|---|---|---|
| 22 | Add `StaffShiftPublishRequest` and a matching request model; type `publishStaffShifts` | §8.2 | Independent of the generator work; the three sibling request entities are the template. |
| 23 | Convert one model to `@JsonSerializable()` as the reference, then the rest; commit the `.g.dart` files | §8.1 | Gated on step 2's tests and step 6's domain time type — the `TimeOfDay` converter depends on it. |
| 24 | Review `getStaffAbsentDatesInRange` / `markStaffShiftAbsentDays` for whether a model is warranted | §8.3 | Last; mostly resolves as a side effect of 23. |
| 25 | Consolidate model→entity conversion into the `mappers/` folder from step 7 | §8.4 | **Last.** Needs 23's generated models to map from. |

---

## 5. Open questions

Points where the standard does not clearly settle the case. I have reported the finding and flagged
the ambiguity rather than guessing.

1. **Which source wins.** The brief says `docs/mandate-rules.md` takes precedence; that file's own
   preamble says the PDF wins. I followed the brief. It changed no verdict — the two agree on all
   eight rules — but it decides execution order, and my remediation order follows mandate-rules.md.
   **One of the two documents should be corrected**; this is now the fourth audit to raise it.

2. **May a route pass a live cubit through `extra`?** §1.2. Mandate 1 requires typed arguments
   through `extra`, which this satisfies; Mandate 5 says cubits are *created* in the `GoRoute`
   builder, and this deliberately passes an existing instance instead, with a documented reason.
   **This module's approach answers the question `attendance-kiosk-module-audit.md` left open**
   (its §Open question 3) and is strictly closer to the mandate than Attendance's — which kept two
   `MaterialPageRoute` pushes to preserve a cubit. The standard should rule once, for both modules.

3. **Is `domain/features/<x>/services/` a sanctioned folder?** §3.3. The canonical tree lists only
   `entities/`, `repositories/`, `usecases/`, but the Mandate 3 *text* in both sources explicitly
   permits "a domain service" as a destination for pure business rules. Scheduling has such a
   folder with two well-factored pure files. I did not grade it as a violation. The tree diagram
   should either list `services/` or the text should stop referring to domain services.

4. **Is `TimeOfDay` in the domain a hard breach or a pragmatic exception?** §3.1. The rule says
   "no Flutter imports" without qualification, and I graded accordingly. But shift times are
   inherently wall-clock values, `TimeOfDay` is the natural type, and the alternative costs a
   value object plus conversions at two boundaries. Every other module manages zero Flutter
   imports in domain, so the precedent is against an exception — but this is the one place where
   the cost of compliance is non-trivial and worth a deliberate decision rather than an
   assumption.

5. **`AppSizes` or `AppSpacing`?** §4.5. Mandate 4 names `AppSizes`
   (`lib/core/constants/app_sizes.dart`); repo-wide, `AppSpacing` (`lib/core/theme/`) has 76
   importers to `AppSizes`' 35. Scheduling uses neither. One app-wide decision is needed before
   183 literals are migrated. (Raised in the attendance and classroom audits.)

6. **Does the "no user-visible string literal" rule reach cubits and domain entities?** §4.4. The
   rule names *view files*. This module keeps user-facing copy relatively contained, but the
   question recurs across audits (Classroom §4.3 raised it for cubit-thrown and entity-returned
   copy). Worth deciding once, for all modules.

7. **Should `SchedulingResponsive` have been created at all?** §6.3. It was written to move this
   feature onto `AppBreakpoints` without touching `ResponsiveHelper`'s 116 importers — a
   defensible tactic that produced a duplicate. Now that `ResponsiveHelper` itself delegates to
   `AppBreakpoints`, the reason has lapsed. The standard has no guidance on temporary forks
   created to enable a migration, or on retiring them afterwards.

8. **Zero test coverage is not itself a mandate.** No test references `features/scheduling`. PDF
   §9.4 lists test coverage as *"deliberately not in this document"*, so it has no mandate to
   attach to. It is recorded here and in the risk assessment because it changes the cost and
   sequencing of nearly every item above — most acutely §3.1 and §8.1, which touch the module's
   core data types and write paths.

9. **Nothing currently enforces any of this.** `analysis_options.yaml` still has every lint line
   commented out, including `include: package:flutter_lints/flutter.yaml`; only an
   `analyzer: exclude: third_party/**` block is active. That is PDF §9.1, unchanged. Outside this
   module's scope, but it is why the module was able to drift — and notably, a
   `flutter_lints`-enabled analyzer would not have caught §3.1 either, which needs a custom
   import-boundary rule.

---

## 6. Method and limits

- All 73 in-scope files were read in full. Cross-cutting counts (`setState`, `serviceLocator`,
  `Map<String, dynamic>`, `Colors.*`, `Color(0x`, `TextStyle(`, `fontFamily`, `fromJson`,
  `toJson`, imports, class declarations, `MediaQuery` variants) were produced by exhaustive grep
  over the three module directories and then verified by reading the matched sites in context.
  Every quoted snippet was read before quoting.
- Every file path and line number was checked against the working tree at `cdb6b86e` on
  `develop-refactor`. Nothing is inferred from a filename.
- Duplicate class names were found by extracting all public and private class declarations in
  `lib/` (excluding `.g.dart`) at the audited commit and diffing against this module's 151 public
  classes.
- Every relative import in the module was resolved programmatically against the filesystem to test
  for the §3.4 excess-`..` hazard. All 180 resolve; none is broken.
- Magic spacing was measured with a balanced-parenthesis parser that excludes token references, so
  a construct like `EdgeInsets.all(AppSpacing.s2)` is correctly not counted — the same method used
  in the classroom and attendance audits after an earlier grep over-counted them.
- The 16 `Navigator.pop` sites were each read in context to separate exempt modal dismissals (9)
  from screen-route pops (7); the mandate exempts the former.
- Comparative figures for Activity, Attendance/Kiosk and Classroom are taken from the three
  existing audits in this folder and, where quoted as counts (domain Flutter imports,
  `context.responsive` uses), re-measured directly at this commit.
- `lib/domain/features/staff_scheduling/` was excluded after confirming via `git ls-files` that it
  contains zero tracked files — only two untracked `.DS_Store` artifacts — and that nothing in
  `lib/` imports it.
- I did not run `flutter analyze` as part of this audit; the baseline capture is listed as the
  first remediation step rather than claimed as done. There is no `flutter test` baseline to
  capture — no test references this module, which I verified by searching the whole `test/` tree.
- No files were modified.
