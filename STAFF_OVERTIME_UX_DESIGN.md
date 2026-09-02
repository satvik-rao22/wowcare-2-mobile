# Staff Attendance & Overtime — UX Redesign + Standalone Module Plan

| | |
|---|---|
| **Goal** | Rebuild the staff-attendance experience as a NEW, isolated module — better information density, fewer clicks, beautiful and responsive (mobile → tablet → desktop). Do not touch the 3rd-party code; connect later by flipping one entry point. |
| **Build order** | Static UI (mock data) first → verify/iterate → then cubit + clean-arch data layer → then wire to real API/routes. |
| **Date** | 2026-06-13 |

---

## 1. Why redesign (problems in both current UIs)

| Current web | Current mobile | Cost to the user |
|---|---|---|
| Dense table; 3 "tabs" via stat cards swap the table; Summarised/Separate toggle; Show-Absent toggle | 3 big stat cards stacked vertically; Present/Absent toggle hides one set; every day needs a tap to reveal sign-in/out | Too many **mode switches** to see one staff's full picture. Overtime isn't visible at a glance anywhere. High vertical cost on mobile. |

**Design thesis:** one screen, **progressive disclosure**, no data hidden behind mode-toggles. The collapsed state already answers "how much regular vs overtime, which days"; expanding answers "which sessions, who signed me out". A single filter (chips) narrows the same list instead of swapping views.

---

## 2. The two screens & component layout

### Screen 1 — Staff Attendance (roster)
Top → bottom: title + date · summary strip (Total / Signed-in / Signed-out / Absent / Not-marked as compact chips, horizontally scrollable on mobile) · filter row (search, classroom, designation) · staff list rows (avatar · name · classroom · today-status pill · today attended-time · chevron). Tap a row → Screen 2.

### Screen 2 — Staff Detail (the redesign centerpiece — see mockup)
Five fixed zones, top to bottom:

1. **App bar** — back · title · export.
2. **Identity row** — avatar/initials · name · `designation · classroom` · today-status pill.
3. **Hero summary card** (the single most important block):
   - Big **total attended** number (`71h 3m`).
   - **Regular vs Overtime stacked bar** + legend (blue = regular, amber = overtime). This is the headline the old UIs buried.
   - Mini-metric trio: Attended days · Absent days · Avg/day.
   - **Needs-attention banner** (only if any): "1 day needs attention — auto signed-out" → tap filters the list.
   - Date-range chip (`Jun 2026`) opens the range picker; `Regular 8h/day` label echoes the config.
4. **Filter chips** (single control replacing 3 toggles): `All days · Overtime · Absent · Needs attention`.
5. **Day timeline** — one card per day:
   - **Collapsed = the "Summarised" data**: date + weekday · mini regular/OT bar · OT chip (`+16m OT`) · total. Scannable without tapping.
   - **Expanded = the "Separate" data**: each session (in→out, classroom, by, method, duration) with per-session edit/delete. `out by System` rendered in amber to flag auto-close.
   - **Absent days** appear inline as a red-accented card (date · marked by · note · edit/delete) — no separate Show-Absent mode needed; the `Absent` filter chip isolates them when wanted.

> Net effect: the web's Summarised view, Separate view, and Show-Absent toggle collapse into **one progressively-disclosed list + one filter** — every fact reachable, far fewer clicks.

---

## 3. Responsive strategy (one data model, two presentations)

| Breakpoint | Layout |
|---|---|
| **Mobile < 600px** | Single column. Hero card full-width. Day **cards**, tap-to-expand. Filters = horizontal scroll chips. Range picker = bottom sheet. |
| **Tablet 600–1024px** | Hero card goes horizontal (bar + metrics side-by-side). Day list in a centered max-width column; filters inline. |
| **Desktop > 1024px** | **Master-detail**: persistent staff roster rail (left) + detail (right). Day list renders as a **data table** (Date · Regular · Overtime · Total · Break · expand), since the width is there. Expanding a row reveals session sub-rows. |

The presentation switch is a single `LayoutBuilder` (or `ResponsiveHelper.isTablet/isLargeTablet`, already in the project) choosing **card list vs table** from the *same* `StaffOvertimeDay` model. Build the widgets so `OvertimeDayCard` (mobile) and `OvertimeDayRow` (desktop table) consume identical data.

Reused shared widgets (read-only, no edits to them): `CustomStatBarCard` (the regular/OT bar), `CustomToggle`/segmented chips, `CustomDateTimeField` (range), `ShimmerLoaderCard`, `CustomRefreshIndicator`, `AppText`/`AppColors`, duration formatter in `attendance_attended_duration.dart`.

---

## 4. Standalone module — zero impact on the 3rd-party code

Everything lands under ONE new top-level folder. We **import from** their shared widgets/theme (read-only) but **modify none** of their files.

```
lib/modules/attendance_v2/
  presentation/
    screens/   staff_attendance_list_screen.dart, staff_detail_screen.dart
    widgets/   overtime_hero_card.dart, overtime_day_card.dart, overtime_day_row.dart,
               overtime_bar.dart, filter_chips.dart, session_tile.dart, absent_tile.dart
    cubit/     staff_detail_cubit.dart, staff_detail_state.dart,
               staff_list_cubit.dart,  staff_list_state.dart
    responsive/ layout.dart   // breakpoint switch helpers
  domain/
    entities/  staff_overtime_profile.dart (Profile, Aggregation, Day, Session, AbsentDay)
    repositories/ attendance_v2_repository.dart   // our own interface
    usecases/  get_staff_overtime_profile_usecase.dart, get_staff_roster_usecase.dart
  data/
    models/    staff_overtime_models.dart   // fromJson/toJson → entity
    datasources/ attendance_v2_remote_datasource.dart      // Dio (later)
                 attendance_v2_mock_datasource.dart        // static data (now)
    repositories/ attendance_v2_repository_impl.dart
  di/      attendance_v2_di.dart    // registerAttendanceV2(serviceLocator) — one self-contained fn
  router/  attendance_v2_routes.dart // additive routes; nothing in their router edited
  mock/    staff_overtime_fixtures.dart
```

**Isolation rules**
- **Do not edit** their `di.dart`, `app_router.dart`, or existing attendance files during the build.
- Our `registerAttendanceV2(sl)` is a single function; wiring it later is **one added line**, not edits scattered across their DI.
- For the static phase, run the module via a **dev entrypoint** (`lib/modules/attendance_v2/dev_main.dart`) or a single additive dev route — so we never touch their navigation graph until cutover.
- The **mock datasource** implements *our* repository interface, so the static screens are fully functional with no backend and no dependency on their code.

**Cutover later (when complete):**
1. Swap `attendance_v2_mock_datasource` → `attendance_v2_remote_datasource` (real API per the JSON contract in `STAFF_OVERTIME_BUILD_PLAN.md`).
2. Add the one `registerAttendanceV2(sl)` line to app startup.
3. Point the staff-attendance entry (home tile / route) at `attendance_v2` screens — replacing their flow only once ours is proven. Their original screens stay intact as instant rollback.

---

## 5. Clean-arch / SOLID / DRY notes (for phase 3)

- **State**: Equatable + named constructors + `copyWith` (match the project's existing cubit convention — no freezed).
- **Usecases**: single `call()`, no Either (match existing).
- **Single source of truth**: regular/OT/break are computed server-side per the tech doc; the client only renders — no payroll math in the app.
- **DRY presentation**: card (mobile) and table-row (desktop) bind to the same `StaffOvertimeDay` entity; one formatter, one color mapping (`Regular→info/blue`, `Overtime→warning/amber`, `Absent→danger/red`).
- **Mock flag**: `kAttendanceV2UseMock` lets the team keep building UI even after wiring begins.

---

## 6. The one open visual choice

The mockup shows the recommended direction (progressive day list + filter chips + master-detail on desktop). During the iterate phase, the main thing to confirm is **desktop density**: table (shown) vs. keeping the same expandable cards in a wider column. Recommendation: table on desktop — it matches admin expectations for payroll review and uses the width well.
