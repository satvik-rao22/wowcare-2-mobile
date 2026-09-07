# Dashboard Module — Eight Mandates Baseline

**Target:** `lib/presentation/features/dashboard/` plus its data and domain layers
**Measured against:** working tree at branch `develop-refactor`, HEAD `38629fc4` (clean).
The session opened on `audit/Report-Fixes` @ `b5069b67`; the checkout to `develop-refactor` happened before measurement. `git diff b5069b67..38629fc4 -- lib/presentation/features/dashboard lib/app/di/di.dart lib/src/app_router.dart` is **empty**, so every count below holds identically on both commits.
**Reference standard:** *WowCare 2.0 Engineering Standards: Eight Mandates* (`develop @ 16b1b2b6`, PDF in repo root) and `docs/mandate-rules.md`
**Date:** 2026-09-06
**No source file was modified.**

---

## 0. The defining fact: the dashboard has no data or domain layer

```
lib/data/features/    → activity auth attendance availability billing classroom
                        communication geofencing kiosk messaging newsletter
                        notifications onboarding reports scheduling staff
                        staff_classroom student student_classroom
lib/domain/features/  → (same 19, plus staff_scheduling)
```

**There is no `data/features/dashboard/` and no `domain/features/dashboard/`.**
Every byte of data the dashboard renders is borrowed from another feature's domain layer. The 16 cubits under `dashboard/cubit/` are aggregation adapters over eight other features' use cases and repositories. This is the single most important structural fact about the module and it shapes every finding below: the dashboard is not a feature, it is a *fan-out over other features*, and its mandate violations are almost entirely violations of the seams between it and them.

### Exact aggregation map (cubit → foreign domain layer)

| Dashboard cubit | Lines | Foreign domain/data it reaches into |
|---|---:|---|
| `school_status_cubit` | 212 | classroom (3 use cases), student (1), attendance (2) |
| `ratio_monitoring_cubit` | 442 | classroom (1 use case + 1 entity), scheduling (1 use case) |
| `classroom_shifts_cubit` | 266 | classroom (1), scheduling (2 use cases + 2 entities), **staff (repository, direct)** |
| `dashboard_attention_cubit` | 215 | **activity, availability, staff, student — all four as raw repositories, no use cases** |
| `my_day_cubit` | 208 | **staff (repository, direct)** + 2 staff entities |
| `my_shifts_cubit` | 284 | classroom (1 use case), scheduling (1 use case), **staff (repository, direct)** |
| `my_attendance_cubit` | 410 | attendance (repository, direct) + **`lib/data/features/attendance/models/` ← imports the data layer** |
| `my_childs_day_cubit` | 262 | student (1 use case + **repository direct**) |
| `student_attendance_profile_cubit` | 154 | attendance (2 use cases) |
| `student_newsletters_cubit` | 152 | newsletter (1 use case) |
| `qr_validation_cubit` | 250 | attendance (3 use cases) |
| `work_break_reminder_cubit` | 75 | **staff (repository, direct)** |
| `admin_/staff_/parent_dashboard_cubit` | 41/27/27 | none — card order + display name from storage |
| three `*_coordinator_cubit` | 279/176/234 | none directly; they orchestrate the above |

**Mandate 5 is broken at the cubit layer, not just the view layer:** 6 of 12 data-bearing cubits call repositories directly instead of use cases. `dashboard_attention_cubit` does it six times in one `Future.wait`. `my_attendance_cubit` imports `package:wowcare/data/features/attendance/models/student_attendance_models.dart` — a presentation file importing the data layer, and it does so because `AttendanceRepository.fetchStaffAttendanceProfile()` returns `StaffAttendanceProfileResponse?`, a **data model leaked through the domain contract**.

Beyond domain layers, the dashboard imports **8 other features' presentation layers** (see §M3).

---

# PART 1 — THE CARD INVENTORY

Three dashboards, dispatched by role from `view/dashboard_screen.dart` (81 lines) via `RoleCubit`:
parent → `ParentDashboard`, staff → `StaffDashboard`, else → `AdminDashboard`.

## 1.1 Admin dashboard — 7 cards + 1 header grid

| # | Card | File | Lines | Cubit(s) it depends on | Feature the data belongs to | Fetches or receives? | Loading | Empty | Error | Tappable → where |
|---|---|---|---:|---|---|---|---|---|---|---|
| — | **AttentionGrid** (header) | `widgets/attention_grid.dart` | 762 | `RatioMonitoringCubit`, `ClassroomShiftsCubit`, `DashboardAttentionCubit` — all via `context.watch` | activity + availability + staff + student + classroom + scheduling (6 APIs) | **Receives** | 4 `_ShimmerCard`s, only while `cards.isEmpty` | **`SizedBox.shrink()` — the whole section vanishes** | **no error state at all** | per-card: `/activityFeed`, scroll-to-ratio, scroll-to-shifts, `/dashboard/individual-movement`; 6 of 10 cards are `return;` no-ops |
| 1 | **MyDayCard** | `widgets/my_day_card.dart` | **2241** | `MyDayCubit`, `GeofenceCubit`, `RoleCubit` + **10 `serviceLocator` calls** | staff (schedule) + attendance (sign-in status) + messaging (chat rows) + classroom | **Fetches its own**, four ways: cubit, `serviceLocator<GetStaffTodaySignInStatusUseCase>`, `serviceLocator<StorageService>` ×5, `serviceLocator<Get*ConversationsEntityUseCase>` ×3 | `_buildShimmerBody()` (l.1537) | "No recent chat" in the chat row | `onRetry: () => context.read<MyDayCubit>().load()` — but the surrounding overlay is a **no-op** (§2.1) | 5 `MaterialPageRoute` pushes → **attendance** forms (SignIn/SignOut/Transfer/MarkAbsent) + **messaging** thread; 1 `context.go` → **classroom** Notes tab |
| 2 | **EnrollmentCard** | `widgets/enrollment_card.dart` | 621 | `SchoolStatusCubit` (own `BlocProvider.value`) | classroom (capacity, count, FTE) + student (counts) + attendance (2 summaries) | **Fetches** — `initState → _loadData()` re-calls `SchoolStatusCubit.loadSchoolStatus`, reading school code via `serviceLocator<StorageService>` | `_EnrollmentCardShimmer` | zeros | **falls through to the normal layout rendering zeros** (comment at l.96 admits this) | 3 live `context.push` → **attendance** tabbed views (student + staff), 3 more commented out |
| 3 | **RatioMonitoringCard** | `widgets/ratio_monitoring_card.dart` | 733 | `RatioMonitoringCubit` (cached in `didChangeDependencies`) + 3 `serviceLocator` calls | classroom + attendance + scheduling + **messaging** (unread badges) | **Fetches** — post-frame `_load()`, plus **one `GetOrCreateClassroomChatUseCase.findExisting()` per classroom row, started from `build()`** | `_RatioMonitoringCardShimmer`, first load only | `_buildEmptyRow()` | `DashboardCardErrorOverlay(show: state.isError)` — **no-op** | per row: `context.go` → **classroom** Notes tab; `context.push` → **attendance** student view, **attendance** staff view |
| 4 | **ClassroomShiftsCard** | `widgets/classroom_shifts_card.dart` | 670 | `ClassroomShiftsCubit` | classroom + scheduling + staff | **Receives**, with a guarded fallback fetch in `didChangeDependencies` | `_ClassroomShiftsCardShimmer` | "no entries" row when `!state.isLoading` | overlay — **no-op** | 2 `context.go` → **scheduling** screen (`?view=day&highlightCode=…`) |
| 5 | **AvailabilityCard** | `widgets/availability_card.dart` | 570 | `FutureAvailabilityCubit` (**availability feature's cubit**) | availability | **Receives**; re-fetches on date arrows | `AvailabilityCardShimmer` | `data.isEmpty` branch | overlay — **no-op** | `context.go` → **availability** future-availability screen; per row → **classroom** screen |
| 6 | **MovementsCard** | `widgets/movements_card.dart` | 645 | `IndividualMovementsCubit` (**availability feature's cubit**) | availability | **Receives** | `MovementsCardShimmer` | `_buildEmptyState()` | `DashboardCardErrorOverlay(show: board==null && errorMessage!=null)` — **no-op**; also an inline `board == null && errorMessage != null` branch | 3 `context.go` → **availability** individual-movement (`?studentCode=`) |
| 7 | **BillingCard** | `widgets/billing_card.dart` | 584 | `TransactionsCubit` + `AnalyticsCubit`, both `serviceLocator`-resolved inside its own `MultiBlocProvider` | billing | **Fetches** — `..loadOverview(...)` and `..load()` cascaded in the `BlocProvider` builders | `ShimmerLoader(height: 96)` / `(height: 220)` | zeros in the chart | no error branch | `context.go` → **billing** screen |

## 1.2 Staff dashboard — 4 cards

| # | Card | File | Lines | Cubit(s) | Feature | Fetches/receives | Loading | Empty | Error | Tap → |
|---|---|---|---:|---|---|---|---|---|---|---|
| 1 | MyDayCard | (same file, 2241) | — | as above | staff/attendance/messaging | fetches | shimmer | "No recent chat" | overlay no-op | attendance forms, messaging |
| 2 | RatioMonitoringCard | (same file, 733) | — | as above | classroom/attendance/scheduling | fetches | shimmer | empty row | overlay no-op | classroom, attendance |
| 3 | **MyShiftsCard** | `widgets/my_shifts_card.dart` | 478 | `MyShiftsCubit` | scheduling + classroom + staff | **Fetches** — post-frame `load()` in `initState` | inline | `_Status.empty` when `shifts.isEmpty` | overlay `show: state.isError` — **no-op** | `MaterialPageRoute` → **scheduling** `ViewShiftScreen`; `context.go` → **scheduling** staff screen |
| 4 | **MyAttendanceCard** | `widgets/my_attendance_card.dart` | 424 | `MyAttendanceCubit` | attendance | **Fetches** — post-frame `load()` in `initState` | `_buildShimmer()` (first load only) | zeros | overlay `show: state.isError` — **no-op** | `context.push` → **attendance** staff profile |

## 1.3 Parent dashboard — 4 cards

| # | Card | File | Lines | Cubit(s) | Feature | Fetches/receives | Loading | Empty | Error | Tap → |
|---|---|---|---:|---|---|---|---|---|---|---|
| 1 | **MyChildsDayCard** | `widgets/my_childs_day_card.dart` | **1816** | `MyChildsDayCubit`, `ParentChildCubit`, `GeofenceCubit` + **6 `serviceLocator` calls** | student + attendance + messaging + classroom | **Fetches** — `GetStudentTodaySignInStatusMapUseCase` direct, geofence init, plus one `_CommunicationRowWidget` **per sibling**, each with its own cache/REST/Firestore pipeline ×2 conversation types | `MyChildsDayCardShimmer` + `"Loading schedule..."` `ValueNotifier` | row skipped entirely when no conversation | `DashboardCardErrorOverlay` — **no-op** | 3 `MaterialPageRoute` → **attendance** StudentSignIn/SignOut forms, **messaging** thread; `context.go` → `/dashboard/student-sign-in-out-selection` |
| 2 | **StudentAttendanceCard** | `widgets/student_attendance_card.dart` | 499 | `StudentAttendanceProfileCubit`, `ParentChildCubit` | attendance | **Fetches** — post-frame `_loadAttendanceData` | `StudentAttendanceCardShimmer` | `'0 Hrs 0 Mins'` | overlay `show: isError` — **no-op**; comment at l.345 admits it renders defaults | `context.push` → **attendance** `StudentAttendanceProfile` |
| 3 | **StudentBillingCard** | `widgets/student_billing_card.dart` | 617 | `ParentBillingCubit` (**billing feature's cubit**) | billing | **Receives** | `BillingTransactionShimmer` | `'No Transactions'` | **real error text + Retry button — the only card in the module that surfaces an error** | `context.go` → **billing** parent screen; `MaterialPageRoute` → **billing** `PayNowAmountScreen` |
| 4 | **StudentNewslettersCard** | `widgets/student_newsletters_card.dart` | 376 | `StudentNewslettersCubit`, `ParentChildCubit` | newsletter | **Fetches** — post-frame `loadFirstPage` in `didChangeDependencies` | `StudentAttendanceCardShimmer` (borrowed from another card) | `_EmptyState` "No newsletters found" | **explicitly routed into the same `_EmptyState`** (comment at l.104) | `MaterialPageRoute` → **newsletter** preview; `context.go` → **newsletter** parent screen |

## 1.4 Dead cards — rendered by nothing

| File | Lines | Status |
|---|---:|---|
| `widgets/events_card.dart` | 184 | `EventsCard` referenced only from a **commented-out line** in `classroom_info_screen.dart:1036`. Hardcoded UI, `onRedirect: () {}`. |
| `widgets/todo_card.dart` | 137 | Zero references. Four hardcoded `_TodoTask`s ("Emma Wilson", "Staff Scheduling - Dec 2024"). |
| `widgets/classroom_progress_card.dart` | 169 | Zero references. Hardcoded `_classrooms`, `_lastMonthValues`, `_thisMonthValues`. |
| `widgets/student_attendance_forms.dart` | 75 | **100% commented out**, including its `Navigator.pushNamed` calls. |
| `view/QR_Code_scanner.dart` | 595 | Reachable *only* via `QrScanButton`'s `MaterialPageRoute`. Never registered as a `GoRoute`. |

**665 lines of dead card code**, plus the three `routeName` statics `/admin-dashboard`, `/staff-dashboard`, `/parent-dashboard` which are declared but registered nowhere and navigated to by nothing.

---

## 1.5 THE NUMBER: how many network calls does opening the dashboard fire?

Method: counted distinct use-case / repository invocations that reach a datasource on a cold open (no warm cache), from the coordinator constructor through the first frame's card `initState`/`didChangeDependencies`/`build`. Storage reads excluded. Cache-first paths counted as 1 (they fall through on a miss).

### Admin — ~41 HTTP requests + 8 Firestore listeners

| Wave | Trigger | Calls | Detail |
|---|---|---:|---|
| **1** | `serviceLocator<AdminDashboardCoordinatorCubit>()` in `initState` → constructor → `unawaited(initialize())` | | |
| 1a | `dashboardCubit.loadUserName()` | 0 | storage only |
| 1b | `classroomShiftsCubit.load(now)` | **4** | staff-shifts, classrooms, school-regular-schedules, classroom-forecast |
| 1c | `myDayCubit.load()` | **3** | `ServerTimeService.sync()` (`/time`), school-regular-schedules, staff-schedules |
| 1d | `_initSchoolDependentCubits()` → `movementsCubit.loadInitial()` | **1** | individual movements board |
| 1e | …`availabilityCubit.load()` | **1** | future availability grid |
| 1f | …`attentionCubit.load()` | **6** | pending-incident-count, movement-status-counts, staff-doc-expiry, staff-physical-checkup, student-doc-expiry, student-physical-checkup |
| 1g | …`schoolStatusCubit.loadSchoolStatus()` | **6** | capacity (serial, gates FTE) → then student-counts, classroom-count, staff-summary, student-summary, school-FTE |
| 1h | …`ratioMonitoringCubit.loadRatioMonitoring()` | **3** | ratio classrooms, student-attendance-by-classrooms, staff-attendance-by-classrooms |
| 1i | …`geofenceCubit.initForSchool()` | **2** | `checkStaffSignInStatus()` + school-location |
| **2** | first-frame card `initState` | | |
| 2a | `MyDayCard._loadStaffIdentity()` | **2** | `resolveStaffCodeForLoggedInUser()` (cache miss) + `GetStaffTodaySignInStatusUseCase` |
| 2b | `MyDayCard._initializeGeofencing()` | **1** | `initForSchool` early-exits, but `checkStaffSignInStatus()` runs *before* the guard (`geofence_cubit.dart:217` vs `:223`) — **always duplicated** |
| 2c | `MyDayCard._CommunicationRowWidget._init()` | **3** + 1 stream | `GetActiveClassroomsUseCase`, `GetConversationsEntityUseCase` (REST), `resolveStaffPrimaryClassroomCode`; `WatchConversationsUseCase` opens a Firestore listener |
| 2d | `BillingCard` `BlocProvider(create:)` | **2** | `TransactionsCubit.loadOverview` + `AnalyticsCubit.load` |
| 2e | `EnrollmentCard.initState._loadData()` | 0 | dropped by `SchoolStatusCubit._isFetching` |
| 2f | `RatioMonitoringCard` post-frame `_load()` | 0 | dropped by `RatioMonitoringCubit._isFetching` |
| **3** | first `build()` of the ratio table | | |
| 3a | `_notesUnreadStreamFor(room.code)` per visible row | **7** + 7 streams | `GetOrCreateClassroomChatUseCase.findExisting()` × min(classrooms, 7); tapping "Show More" fires one per additional classroom |
| | **TOTAL** | **≈41 HTTP + 8 Firestore listeners** | |

### Staff — ~20 HTTP + 8 Firestore listeners

`_initGeofence()` is **awaited before the `Future.wait`** (`staff_dashboard_coordinator_cubit.dart:47`), so 2 calls run serially in front of everything else. Then: `myDayCubit.load()` 3, `myAttendanceCubit.load()` 1–2, `myShiftsCubit.load()` 3–4, `ratioMonitoringCubit.loadRatioMonitoring()` **4** (staff persona adds a `GetStaffShiftsUseCase` call inside `_resolveClassroomScope`). Plus MyDayCard's 6 and the ratio Notes badges.

### Parent — ~23 HTTP + 2K Firestore listeners (K = number of children)

| Trigger | Calls |
|---|---:|
| `parentBillingCubit.load()` (fired from the constructor body, before subscriptions) | **1** |
| `myChildsDayCubit.loadForChild()` — tz `/time`, student profile, regular schedules, guardians | **4** |
| `studentAttendanceProfileCubit.loadAttendanceProfile()` — custom + absent-toggle | **2** |
| `studentNewslettersCubit.loadFirstPage()` | **1** |
| `communicationCubit.loadConversations()` | **1** |
| `_initGeofence()` | **2** |
| `MyChildsDayCard._loadChildrenSignInStatus()` | **1** |
| `MyChildsDayCard._initializeGeofencing()` → `checkStaffSignInStatus` | **1** |
| `MyChildsDayCard.didChangeDependencies` → **second** `loadForChild()` — see §3.4 | **4** |
| `StudentAttendanceCard` post-frame `_loadAttendanceData` | 0 (guard) |
| `StudentNewslettersCard` post-frame `loadFirstPage` | 0 (guard) |
| `_CommunicationRowWidget` × K children × 2 types × (REST + Firestore watch) | **2K** + 2K streams |
| **TOTAL (K=1)** | **≈19 HTTP + 2 Firestore**, of which **5 are exact duplicates** |

### Pull-to-refresh

Admin `refresh()` re-fires ~19, staff ~11, parent ~8 — plus `geofenceCubit.refreshSettings()` and `checkStaffSignInStatus()` fired `unawaited` on every pull.

---

# PART 2 — STRUCTURE

## 2.1 Full tree, line counts, classification

**18,440 lines across 67 files.** Classification: **V** = view/screen, **W** = widget, **VM** = cubit/state, **S** = service, **E** = enum/config, **D** = dead.

```
lib/presentation/features/dashboard/                              18,440
├── cubit/                                             (34 files)  4,373   ← §3.1 requires view_model/
│   ├── admin_dashboard_coordinator_cubit.dart    279  VM
│   ├── admin_dashboard_cubit.dart                 41  VM
│   ├── admin_dashboard_state.dart                 21  VM
│   ├── classroom_shifts_cubit.dart               266  VM
│   ├── classroom_shifts_state.dart                44  VM
│   ├── dashboard_attention_cubit.dart            215  VM
│   ├── dashboard_attention_state.dart            111  VM
│   ├── dashboard_coordinator_state.dart           43  VM  (shared by all 3 coordinators)
│   ├── my_attendance_cubit.dart                  410  VM  ⚠ >400, imports lib/data
│   ├── my_attendance_state.dart                  139  VM
│   ├── my_childs_day_cubit.dart                  262  VM  ⚠ no _isFetching guard
│   ├── my_childs_day_state.dart                   98  VM
│   ├── my_day_cubit.dart                         208  VM
│   ├── my_day_state.dart                         101  VM
│   ├── my_shifts_cubit.dart                      284  VM
│   ├── my_shifts_state.dart                      118  VM
│   ├── parent_dashboard_coordinator_cubit.dart   234  VM
│   ├── parent_dashboard_cubit.dart                27  VM
│   ├── parent_dashboard_state.dart                24  VM
│   ├── qr_validation_cubit.dart                  250  VM
│   ├── qr_validation_state.dart                   64  VM
│   ├── ratio_monitoring_cubit.dart               442  VM  ⚠ >400
│   ├── ratio_monitoring_state.dart                53  VM
│   ├── school_status_cubit.dart                  212  VM
│   ├── school_status_state.dart                  211  VM
│   ├── staff_dashboard_coordinator_cubit.dart    176  VM
│   ├── staff_dashboard_cubit.dart                 27  VM
│   ├── staff_dashboard_state.dart                 24  VM
│   ├── student_attendance_profile_cubit.dart     154  VM  ⚠ state class collides (§M6)
│   ├── student_attendance_profile_state.dart     106  VM
│   ├── student_newsletters_cubit.dart            152  VM
│   ├── student_newsletters_state.dart             86  VM
│   ├── work_break_reminder_cubit.dart             75  VM  ⚠ leaked (§3.3)
│   └── work_break_reminder_state.dart             35  VM
├── services/                                          (1 file)     116   ← §3.3: "belongs in DI"
│   └── dashboard_cubit_factory.dart              116  S
├── viewmodels/                                        (3 files)     100   ← §3.2: only feature using this name
│   ├── admin_dashboard_viewmodel.dart              40  E
│   ├── parent_dashboard_viewmodel.dart             29  E
│   └── staff_dashboard_viewmodel.dart              31  E
└── view/                                             (29 files) 13,851
    ├── dashboard_screen.dart                       81  V   role dispatcher
    ├── admin_dashboard.dart                       298  V
    ├── staff_dashboard.dart                       201  V
    ├── parent_dashboard.dart                      210  V
    ├── QR_Code_scanner.dart                       595  V   ⚠ §3.3 naming; >400; not a GoRoute
    └── widgets/                                  (24 files) 12,466
        ├── my_day_card.dart                     2241  W  ⚠ 5.6× ceiling
        ├── my_childs_day_card.dart              1816  W  ⚠ 4.5× ceiling
        ├── attention_grid.dart                   762  W  ⚠
        ├── ratio_monitoring_card.dart             733  W  ⚠
        ├── classroom_shifts_card.dart             670  W  ⚠
        ├── movements_card.dart                    645  W  ⚠
        ├── enrollment_card.dart                   621  W  ⚠
        ├── student_billing_card.dart              617  W  ⚠
        ├── billing_card.dart                      584  W  ⚠
        ├── availability_card.dart                 570  W  ⚠
        ├── student_attendance_card.dart           499  W  ⚠ class name collides (§M6)
        ├── my_shifts_card.dart                    478  W  ⚠
        ├── my_attendance_card.dart                424  W  ⚠
        ├── student_newsletters_card.dart          376  W
        ├── events_card.dart                       184  D  dead
        ├── classroom_progress_card.dart           169  D  dead
        ├── todo_card.dart                         137  D  dead
        ├── student_attendance_forms.dart           75  D  100% commented out
        ├── dashboard_card_header.dart              74  W  shared, 17 uses
        ├── dashboard_card_toggle.dart              62  W  shared, 3 uses
        ├── dashboard_welcome_header.dart           46  W  1 use
        ├── dashboard_error_chip.dart               36  W  ⚠ 12 uses, all no-ops (§3.1)
        └── qr_scan_button.dart                     28  W  2 uses
```

**Missing folders required by §3.1:** no `model/` (route-arg and screen-param classes — the module passes `Map<String, dynamic>` through `extra` instead, see §M8), no `view_model/` (uses `cubit/`).

## 2.2 The `viewmodels/` folder — confirmed

§3.2 of the PDF names the dashboard as **the only feature in the codebase using `viewmodels/`** (17 use `cubit/`, onboarding and user-profile use `view_model/`). Confirmed. It contains three files, 100 lines total, and **none of them is a ViewModel**:

| File | Contents |
|---|---|
| `admin_dashboard_viewmodel.dart` | `enum AdminDashboardCard` (7 values + 3 commented out: `events`, `todo`, `classroomProgress`) with a `String get title` switch; `class AdminDashboardViewModel` = one `const` ctor, `static const double maxContentWidth = 640`, `static List get defaultCards` |
| `parent_dashboard_viewmodel.dart` | `enum ParentDashboardCard` (4 values) + identical shell class |
| `staff_dashboard_viewmodel.dart` | `enum StaffDashboardCard` (4 values + 3 commented out) + identical shell class |

They are **card-order enums with display titles** — screen config, i.e. §3.1's `model/`. The three `ViewModel` classes are never instantiated; `maxContentWidth = 640` is declared in all three *and* re-declared as a private `static const double _maxContentWidth = 640` inside each dashboard's `_DashboardCardList` (`admin_dashboard.dart:237`, `staff_dashboard.dart:151`, `parent_dashboard.dart:161`), and it is the private copies the code actually reads. The `viewmodels/` value is dead in all three.

The commented-out enum values are the reason the three dead cards in §1.4 still compile and still ship.

## 2.3 `services/dashboard_cubit_factory.dart` — confirmed

§3.3 names this file explicitly: *"Cubit construction belongs in DI, not in a services folder inside presentation."*

**What it does.** 116 lines. Holds a `GetIt` instance injected via constructor. Exposes three methods — `createParentDashboardCoordinator()`, `createStaffDashboardCoordinator()`, `createAdminDashboardCoordinator()` — each of which news up the matching coordinator cubit, resolving its 6–9 constructor dependencies through a private `_resolveSafe<T>()`.

`_resolveSafe<T>()` is the interesting part:

```dart
T _resolveSafe<T extends Object>() {
  try {
    if (!_getIt.isRegistered<T>()) {
      AppLogger.e('DashboardCubitFactory Error: Type $T is not registered in GetIt.');
      if (T == ParentChildCubit)      return ParentChildCubit() as T;      // ← manual fallback
      if (T == ParentDashboardCubit)  return ParentDashboardCubit() as T;
      if (T == StaffDashboardCubit)   return StaffDashboardCubit() as T;
      if (T == AdminDashboardCubit)   return AdminDashboardCubit() as T;
      throw StateError('GetIt: Object/factory with type $T is not registered inside GetIt.');
    }
    return _getIt<T>();
  } catch (e, stack) { AppLogger.e(...); rethrow; }
}
```

Four hardcoded "safety fallbacks" that hand-construct a cubit when DI has not registered it. `ParentChildCubit` is a **`registerLazySingleton`** (`di.dart:2115`) — so the fallback would produce a *second, non-singleton* `ParentChildCubit` that `ParentDashboardCoordinatorCubit.close()` deliberately does not close (it assumes the singleton), leaking it and desynchronising child selection across the app. The fallback is latent today because all four types are registered; it is a silent-wrong-behaviour trap, not a crash.

**Who calls it.** Only `lib/app/di/di.dart`, at three sites:

```
di.dart:2120  registerLazySingleton<DashboardCubitFactory>(() => DashboardCubitFactory(serviceLocator));
di.dart:2123  registerFactory<ParentDashboardCoordinatorCubit>(() => serviceLocator<DashboardCubitFactory>().createParentDashboardCoordinator());
di.dart:2127  registerFactory<StaffDashboardCoordinatorCubit>(...)
di.dart:2131  registerFactory<AdminDashboardCoordinatorCubit>(...)
```

Nothing outside DI references it. So the file is a **DI module that lives in the presentation layer** — it is already only used by DI, which means the §3.3 move is a pure relocation to `lib/core/di/modules/dashboard_module.dart` with no call-site changes.

Note the three coordinators are `registerFactory`, so §5.5's "a fresh instance each time the screen opens" applies — see §3.3 for whether they are actually leaked (they are not; the cards are).

## 2.4 Files violating §3.3 naming conventions

| File | Violation | §3.3 verdict |
|---|---|---|
| `view/QR_Code_scanner.dart` | PascalCase + SCREAMING segment; not snake_case | **Named explicitly in the PDF's naming table:** *"should be `qr_code_scanner.dart`"* |
| `cubit/` (34 files) | folder name; §3.1 requires `view_model/` | §3.2 table — app-wide (17 features), do not fix in isolation |
| `viewmodels/` (3 files) | folder name; dashboard is the only user | §3.2 table |
| `services/dashboard_cubit_factory.dart` | folder does not exist in §3.1 | §3.3 structural table |
| `widgets/student_attendance_forms.dart` | plural-noun name for a file containing one commented-out `StudentSignInOutButton` widget | contents dead; name describes nothing that exists |
| `widgets/attention_grid.dart` | not a violation of naming, but it is a *screen section*, not a reusable widget | borderline |

Also worth recording, though not a §3.3 filename rule: the class inside `QR_Code_scanner.dart` is `QrScanScreen` — **a `_screen` class living under `view/` with a non-matching filename**, and `attention_grid.dart`, `dashboard_welcome_header.dart` are page sections filed under `widgets/`.

---

# PART 3 — MANDATE COUNTS

All greps scoped to `lib/presentation/features/dashboard/`.

## M1 — GoRouter everywhere, MaterialPageRoute nowhere

**13 `MaterialPageRoute` in 7 live files** (up to 26 in the worst app file per §1.1; the dashboard is not the worst offender but `my_day_card.dart` at 5 would rank ~9th app-wide).

| File | `MaterialPageRoute` | `Navigator.push` / `.of(ctx).push` | `context.push` | `context.go` | `Navigator.pop` |
|---|---:|---:|---:|---:|---:|
| `widgets/my_day_card.dart` | **5** | 4 | 0 | 1 | 0 |
| `widgets/my_childs_day_card.dart` | **3** | 3 | 0 | 1 | 0 |
| `widgets/my_shifts_card.dart` | 1 | 1 | 0 | 1 | 0 |
| `widgets/student_billing_card.dart` | 1 | 1 | 0 | 1 | 0 |
| `widgets/student_newsletters_card.dart` | 1 | 1 | 0 | 1 | 0 |
| `widgets/qr_scan_button.dart` | 1 | 1 | 0 | 0 | 0 |
| `view/QR_Code_scanner.dart` | 1 | 1 (`pushReplacement`) | 0 | 1 | **2** |
| `widgets/enrollment_card.dart` | 0 | 0 | **3** (+3 commented) | 0 | 0 |
| `widgets/attention_grid.dart` | 0 | 0 | 0 | **4** | 0 |
| `widgets/movements_card.dart` | 0 | 0 | 0 | 3 | 2 (dialog — exempt) |
| `widgets/ratio_monitoring_card.dart` | 0 | 0 | 2 | 1 | 0 |
| `widgets/availability_card.dart` | 0 | 0 | 0 | 2 | 0 |
| `widgets/classroom_shifts_card.dart` | 0 | 0 | 0 | 2 | 0 |
| `widgets/my_attendance_card.dart` | 0 | 0 | 1 | 0 | 0 |
| `widgets/student_attendance_card.dart` | 0 | 0 | 1 | 0 | 0 |
| `widgets/billing_card.dart` | 0 | 0 | 0 | 1 | 0 |
| `view/admin_dashboard.dart` | 0 | 0 | 0 | 1 | 0 |
| `view/dashboard_screen.dart` | 0 | 0 | 0 | 1 | 0 |
| `widgets/student_attendance_forms.dart` | 0 | 2 **commented** | 0 | 0 | 2 **commented** |
| **TOTAL live** | **13** | **12** | **7** | **21** | **4** (2 exempt) |

### Which feature each raw push targets

| Push site | Destination | Feature |
|---|---|---|
| `my_day_card.dart:528` | `StaffTransferForm` | **attendance** |
| `my_day_card.dart:575` | `StaffMarkAbsentForm` | **attendance** |
| `my_day_card.dart:608` | `StaffSignInForm(forceSelf:true)` | **attendance** |
| `my_day_card.dart:636` | `StaffSignOutForm` | **attendance** |
| `my_day_card.dart:1909` | `ConversationThreadScreen` | **communication/messaging** |
| `my_childs_day_card.dart:907` | `StudentSignOutForm` | **attendance** |
| `my_childs_day_card.dart:947` | `StudentSignInForm` | **attendance** |
| `my_childs_day_card.dart:1667` | `ConversationThreadScreen` | **communication/messaging** |
| `my_shifts_card.dart:120` | `ViewShiftScreen` (returns `bool` → drives a reload) | **scheduling** |
| `student_billing_card.dart:40` | `PayNowAmountScreen` (returns `bool` → drives `cubit.refresh()`) | **billing** |
| `student_newsletters_card.dart:179` | `PreviewNewsletterScreen` | **newsletter** |
| `qr_scan_button.dart:17` | `QrScanScreen` (`fullscreenDialog: true`) | **dashboard** (own) |
| `QR_Code_scanner.dart:168` | `StudentSelection*Form` / `Staff*Form` (`pushReplacement`) | **attendance** |

**11 of 13 raw pushes cross a feature boundary.** Two carry a result that drives behaviour (`my_shifts_card` `bool`, `student_billing_card` `bool`) — §M1's "preserve result handling exactly" applies to both.

### Existing GoRoute entries

`lib/src/app_router.dart` (1,575 lines, **126 `GoRoute(`** entries, still at `lib/src/` not `lib/core/router/` per §3.3). The dashboard module owns **exactly one**:

```
app_router.dart:909   path: AppRoutes.dashboard   ('/dashboard', = DashboardScreen.routeName)
app_router.dart:910   builder: (context, state) => const DashboardScreen(),
```

Everything the dashboard `context.go`s to belongs to another feature and is registered under the dashboard shell branch: `'scheduling'` (:1279), `'individual-movement'` (:1361), `'student-sign-in-out-selection'` (:1693), `AppRoutes.activityFeed` (:1779), plus `/dashboard/staff-sign-in-form` (:728) and `/dashboard/staff-sign-out-form` (:752) which exist as routes but are **not** used by `my_day_card.dart` — it pushes `StaffSignInForm` raw instead.

`lib/core/router/app_routes.dart` exists but declares only `ReportRoutes`; **no dashboard route constants**, and the dashboard imports it nowhere. Three unregistered, unreferenced `routeName` statics remain: `/admin-dashboard`, `/staff-dashboard`, `/parent-dashboard`.

### Untyped route arguments

`extra:` is passed a raw `Map<String, dynamic>` at 5 sites (`admin_dashboard.dart:127`, `ratio_monitoring_card.dart:348/370`, `student_attendance_card.dart:76`, `QR_Code_scanner.dart:136`) plus untyped `extra: {…}` at `enrollment_card.dart:184/234/290`. §M1 requires a declared class. None exists — there is no `model/` folder to hold one.

## M2 — setState scarcely, ValueNotifier for UI micro-state

**68 `setState(` calls · 26 `StatefulWidget` declarations across 23 files · 2 `ValueNotifier` · 2 `ValueListenableBuilder`.**

| File | `setState(` | Bucket (per §2's A/B/C table) |
|---|---:|---|
| `widgets/my_day_card.dart` | **20** | mixed: A (`_isSignedIn`, `_todayStatusRaw`, `_staffCode`, `_clockInPin` — all from APIs/storage), B (`_minimized`), plus `_CommunicationRowWidgetState` A (`_items`, `_loading`) and `_ReminderToggleButtonState` A (`_reminderEnabled` from an API) |
| `widgets/my_childs_day_card.dart` | **12** | mixed: A (`_childrenSignInStatusMap`, `_signInStatusLoaded`), B (`_isMinimized`) |
| `widgets/classroom_shifts_card.dart` | 5 | B (`_minimized`, `_expandAll`, `_rowExpanded`), A (`_selectedDate` — drives an API call) |
| `view/QR_Code_scanner.dart` | 5 | C (camera/animation) + A (`_result`) |
| `widgets/todo_card.dart` | 3 | B (`_minimized`) + A (`task.done` — mutates a model in place) |
| `widgets/ratio_monitoring_card.dart` | 3 | B (`_minimized`, `_showAllClassrooms`) + A (`_notesUnreadStreams` map from an API) |
| `widgets/billing_card.dart` | 3 | B (`_minimized`) + A (`_selectedYear`, `_rangeStart/_rangeEnd` → drive `loadOverview`) |
| `widgets/availability_card.dart` | 3 | B + A (`_selectedAvailabilityDate` → drives `load`) |
| `widgets/student_attendance_card.dart` | 2 | B + A (`_fromDate/_toDate` → drives a fetch) |
| `widgets/classroom_progress_card.dart` | 2 | B (dead file) |
| `view/dashboard_screen.dart` | 2 | A-ish — `_schoolReloadEpoch` re-keys the whole subtree on school switch / tab visibility |
| `widgets/student_newsletters_card.dart` | 1 | B |
| `widgets/student_billing_card.dart` | 1 | B |
| `widgets/my_shifts_card.dart` | 1 | B |
| `widgets/my_attendance_card.dart` | 1 | B |
| `widgets/movements_card.dart` | 1 | B |
| `widgets/events_card.dart` | 1 | B (dead file) |
| `widgets/enrollment_card.dart` | 1 | B |
| `widgets/attention_grid.dart` | 1 | B (`_expanded`) |

Every card's `_minimized` / `_isMinimized` expand-collapse boolean is bucket **B** and is hand-rolled in **13 separate `StatefulWidget`s** — this is precisely §2.3's *"the expand/collapse card, written seven times"*, and §6.2's unused `core/common/widgets/expandable_info_card.dart` (296 lines, zero callers) is the widget that already solves it.

### ValueNotifier / ValueListenableBuilder — per file

| File | `ValueNotifier` | `ValueListenableBuilder` | Disposed? |
|---|---:|---:|---|
| `widgets/my_childs_day_card.dart` | **2** (`_statusText: String` l.138, `_duration: Duration` l.141) | **2** | ✅ **Yes** — both `.dispose()`d at l.569–570 |
| every other file | 0 | 0 | — |

**Is every `ValueNotifier` disposed? Yes — both of them.** Neither is created inside `build()`; both are `final` fields. However **neither `ValueListenableBuilder` passes a `child:`**, so the module gets none of the rebuild-scoping win §M2 names as the reason for the rule. `my_day_card.dart` runs an identical 1-second countdown ticker with plain `setState` (`_startTicker`, l.402) — the same problem, solved two different ways in two files, and the `setState` version rebuilds all 2,241 lines of card every second.

`BlocSelector` is used **0 times**; `context.select` once (`admin_dashboard.dart:241`).

## M3 — Imports and folder discipline

**467 `package:wowcare/` imports · 6 relative cross-folder imports · 5 legitimate same-folder relative imports.**

### Relative cross-folder imports (violations)

| File | Import | Depth below `lib/` | `..` count | Resolves? |
|---|---|---:|---:|---|
| `cubit/my_childs_day_cubit.dart:15` | `'../../../../core/util/storage_keys.dart'` | 4 | 4 | ✅ correct |
| `view/widgets/my_day_card.dart:45` | `'../../../../../core/util/core_utils.dart'` | 5 | 5 | ✅ correct |
| `view/widgets/my_childs_day_card.dart:22` | `'../../../../../core/util/storage_keys.dart'` | 5 | 5 | ✅ correct |
| `view/widgets/classroom_shifts_card.dart:20` | `'../../../../../app/theme/media_res.dart'` | 5 | 5 | ✅ correct |
| `view/widgets/classroom_shifts_card.dart:21` | `'../../../scheduling/view/scheduling_screen.dart'` | 5 | 3 | ✅ correct |
| `view/widgets/availability_card.dart:17` | `'../../../classroom/views/screens/classroom_screen.dart'` | 5 | 3 | ✅ correct |

**Imports with MORE `..` than the file's depth below `lib/`: zero.** The dashboard is clean of the §3.4 excess-`..` defect that breaks `feature_flag_cubit_test.dart` (see §6.2). All six are still §M3 violations — cross-folder imports must use `package:wowcare/…` — but none is latent breakage.

Legitimate same-folder relatives (allowed): `dashboard_coordinator_state.dart` from the three coordinators, `dashboard_error_chip.dart` from `ratio_monitoring_card` and `my_childs_day_card`.

### Imports from another FEATURE's presentation layer

**8 features, 56 import statements.** This is the aggregation seam made concrete.

| Foreign feature | What is imported | Count |
|---|---|---:|
| **geofencing** | `cubit/geofence_cubit.dart` ×9, `widgets/geofence_sign_in_sheet.dart` ×2 | 11 |
| **scheduling** | `utils/school_hours_resolver.dart` ×3, `model/scheduling_models.dart` ×3, `widgets/staff_schedule_tile.dart` ×2, `view/staff_scheduling_screen.dart`, `view/view_shift_screen.dart`, `widgets/staff_day_schedule_calendar.dart`, `widgets/day_classroom_section.dart`, `utils/scheduling_block_status_style.dart`, `utils/forecast_slot_mapper.dart`, `utils/classroom_name_resolver.dart`, `model/shift_models.dart` | 15 |
| **attendance** | 4 `forms/staff_attendance_forms/*` (incl. `staff_entity.dart`), 4 `forms/student_attendance_forms/*`, `view/student_attendance_tabbed_view.dart` ×2, `view/staff_attendance_tabbed_view.dart` ×2, `view/student_attendance_profile.dart`, `view/staff_attendance_profile.dart`, `util/attendance_permission_service.dart` | 16 |
| **communication** | `cubit/communication_cubit.dart` ×4, `presentation/messaging/view/screens/conversation_thread_screen.dart` ×2, `shared/utils/message_content_processor.dart` ×2, `cubit/communication_state.dart`, `presentation/messaging/view/screens/messaging_entry_screen.dart` | 10 |
| **availability** | `cubit/individual_movements_cubit.dart` ×4, `cubit/future_availability_cubit.dart` ×4, `view/individual_movement_screen.dart`, `view/future_availability_screen.dart` | 10 |
| **billing** | `cubit/parent_billing_cubit.dart` ×4, `view/pay_now_amount_screen.dart`, `view/parent_billing_screen.dart`, `view/billing_screen.dart`, `cubit/transactions_cubit.dart`, `cubit/analytics_cubit.dart`, `widgets/accounting/date_range_selector.dart` | 10 |
| **newsletter** | `view/preview_newsletter_screen.dart`, `view/parent_newsletter_screen.dart`, `util/newsletter_thumbnail_resolver.dart`, `util/newsletter_entity_mapper.dart` | 4 |
| **classroom** | `views/screens/classroom_screen.dart`, `views/screens/classroom_overview_screen.dart` | 2 |
| **staff** | `widgets/staff_attendance_action_availability.dart`, `view/staff_filter_screen.dart` | 2 |

Three of these compound other mandate violations:
- `communication/presentation/messaging/…` — §3.3's *"a `presentation` folder nested inside the presentation layer"* (~40 files), imported twice from here.
- `scheduling/utils/`, `newsletter/util/`, `attendance/util/` — §3.1 says a presentation `util/`/`utils/` folder *should not exist*; the dashboard imports business logic out of three of them.
- `attendance/forms/staff_attendance_forms/staff_entity.dart` — an **entity** imported from another feature's presentation layer (§3.1: *"Entities never live in presentation"*).

The dashboard consumes **6 of the other features' cubits directly** (`GeofenceCubit`, `CommunicationCubit`, `ParentBillingCubit`, `IndividualMovementsCubit`, `FutureAvailabilityCubit`, `TransactionsCubit`/`AnalyticsCubit`) and re-provides them through its own `MultiBlocProvider`s.

## M4 — Centralized theming

| Token / anti-pattern | Count | Worst files |
|---|---:|---|
| `Colors.<name>` | **378** | `my_day_card` 45, `student_billing_card` 38, `enrollment_card` 36, `my_childs_day_card` 30, `classroom_shifts_card` 26, `attention_grid` 25 |
| `Color(0x…)` | **11** | `student_attendance_card` 3, `my_day_card` 3, `my_attendance_card` 2, `enrollment_card` 2, `classroom_shifts_card` 1 |
| inline `TextStyle(` | **158** | `my_childs_day_card` 21, `student_billing_card` 20, **`my_day_card` 18**, `billing_card` 11, `attention_grid` 11 |
| `fontFamily:` | **6** | `my_shifts_card` 5, `classroom_shifts_card` 1 — find-and-delete per §M4 |
| `textTheme` | **0** | — |
| `Theme.of(context)` | **0** | — |
| `AppColors.` | **227** | resolved, but bypassed 389:227 by raw colours |
| `AppStrings` | **0** | — |
| `AppSizes` | **0** | — |
| `EdgeInsets(` literal ctor | **0** | all use `.all/.only/.symmetric/.fromLTRB` — **120** of those |
| `SizedBox(` | **214** | `student_billing_card` 25, `my_day_card` 21, `my_childs_day_card` 17 |
| hardcoded dimensions (`width:`/`height:`/`size:`/`fontSize:`/`radius:` + literal) | **546** | `my_day_card` 56, `student_billing_card` 49, `my_childs_day_card` 43, `enrollment_card` 42 |

**`my_day_card.dart`'s 18 inline `TextStyle`s: confirmed.** (`grep -c 'TextStyle(' my_day_card.dart` → 18.)

**User-visible string literals: 100% inline.** `AppStrings` is used zero times in the module, and `lib/core/constants/app_strings.dart` **does not exist** — the folder contains only `app_sizes.dart`. §M4's target file has to be created. Sampled literals: `'Dashboard refreshed successfully.'`, `'Unable to load dashboard data. Please try again.'`, `'Need your attention'`, `'Ratio Monitoring'`, `'Show More'`/`'Show Less'`, `'No recent chat'`, `'No newsletters found'`, `'No Transactions'`, `'0 Hrs 0 Mins'`, `'Turn off Reminder'`/`'Send reminder'`, `'Unable to find your staff profile to transfer.'`, `'Absent can only be marked for Students/Staff not yet signed in'`, `'School context missing. Please sign in again.'`, `'Missing staff/school context.'`, and every card title (which are duplicated between the card widget and its `viewmodels/` enum `title` getter).

**`AppSizes` exists** at `lib/core/constants/app_sizes.dart` (23 importers app-wide) and the dashboard uses it **zero times**. All 546 dimensions and 120 `EdgeInsets` are literals.

**`AppColors` is single-sourced** — `lib/core/theme/app_colors.dart` is the only `class AppColors`, and all 21 dashboard imports go through the re-export shim `lib/app/theme/colors.dart`. That shim is itself a §3.3 leftover but is not a duplicate implementation.

**Colours encoding meaning** (§M4's "named semantic tokens, distinguishable by something other than colour alone"): `movements_card.dart:239–262` maps status strings to `Colors.red` / `Colors.yellow.shade700` / `Colors.green` / `Colors.red.shade300` / `Colors.grey` in a bare `switch` — five workflow states separated by colour only, with no icon or label differentiator. `attention_grid.dart`'s `_AttentionTone.danger`/`.warning` is the same shape one level better (it has an enum, but the enum still resolves to raw colours).

## M5 — Presentation talks to cubits only

**30 `serviceLocator<…>` calls across 13 files.** §M1/§M5 allow it in exactly one place: a `GoRoute` builder. **Zero of the 30 are in a `GoRoute` builder** — the module's only route builder is `const DashboardScreen()`.

| File | `serviceLocator<` | `StorageService` | `Repository` | `ApiClient` | `FutureBuilder` | `StreamBuilder` | `UseCase` |
|---|---:|---:|---:|---:|---:|---:|---:|
| `widgets/my_day_card.dart` | **10** | 5 | 0 | 0 | 0 | 0 | 6 |
| `widgets/my_childs_day_card.dart` | **6** | 2 | 0 | 0 | 0 | 0 | 4 |
| `widgets/ratio_monitoring_card.dart` | **3** | 1 | 1 | 0 | 0 | **1** | 1 |
| `widgets/billing_card.dart` | 2 | 0 | 0 | 0 | 0 | 0 | 0 |
| `widgets/enrollment_card.dart` | 1 | 1 | 0 | 0 | 0 | 0 | 0 |
| `view/admin_dashboard.dart` | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| `view/staff_dashboard.dart` | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| `view/parent_dashboard.dart` | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| `view/QR_Code_scanner.dart` | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| `cubit/admin_dashboard_coordinator_cubit.dart` | 1 | 1 | — | 0 | — | — | — |
| `cubit/staff_dashboard_coordinator_cubit.dart` | 1 | 1 | — | 0 | — | — | — |
| `cubit/parent_dashboard_coordinator_cubit.dart` | 1 | 1 | — | 0 | — | — | — |
| `cubit/admin_dashboard_cubit.dart` | 1 | 1 | — | 0 | — | — | — |
| **cubits (non-SL)** | — | 15 | **76** | **4** | 0 | 0 | 153 |
| **TOTAL** | **30** | **30** | **76** | **4** | **0** | **1** | **153** |

`DataSource` 0 · `SharedPreferences` 0 · `Dio` 0 · `FutureBuilder` 0. `StreamBuilder` 1 — `ratio_monitoring_card.dart:405`, over a Firestore unread-count stream the cubit does not own (§M5 forbids it *"over data the cubit already owns"*; this data is genuinely not in the cubit, so the violation is that the card is reaching a repository at all, not the builder itself).

**`my_day_card.dart`'s 10 `serviceLocator` calls: confirmed.** Exact sites:

| Line | Resolved type | Purpose |
|---:|---|---|
| 371 | `StorageService` | school code for geofence init |
| 421 | `StorageService` | clock-in PIN |
| 431 | `StorageService` | staff code / user code / display name / designation |
| 462 | **`GetStaffTodaySignInStatusUseCase`** | **direct use-case invocation from a view** — §M5's named prohibition |
| 1691 | `StorageService` | current user code |
| 1714 | **`GetActiveClassroomsUseCase`** | classroom name map |
| 1737 | **`GetCachedConversationsEntityUseCase`** | Isar-cached conversations |
| 1757 | **`GetConversationsEntityUseCase`** | REST conversations |
| 1774 | **`WatchConversationsUseCase`** | Firestore stream |
| 2139 | **`WorkBreakReminderCubit`** | a *cubit* resolved from the locator inside a tap handler |

Six of the ten are use cases invoked straight from the widget. `my_childs_day_card.dart` repeats the pattern with 6 more (`GetStudentTodaySignInStatusMapUseCase` at l.316 plus the same conversation trio at l.1595/1612/1628). `ratio_monitoring_card.dart:94/100` resolves `GetOrCreateClassroomChatUseCase` **and `ConversationEntityRepository`** — a repository type named directly in a view file.

**Does any cubit import from `lib/data`?** **Yes — one:**
```
cubit/my_attendance_cubit.dart:9
  import 'package:wowcare/data/features/attendance/models/student_attendance_models.dart';
```
It is unavoidable given the current contract: `AttendanceRepository.fetchStaffAttendanceProfile()` is declared in `lib/domain/features/attendance/repositories/attendance_repository.dart:458` as returning `Future<StaffAttendanceProfileResponse?>` — a **data-layer model leaked into a domain contract**. Fixing §M5 here requires fixing the domain contract first (§M8: *"mappers convert model → entity"*).

**Cubits calling repositories instead of use cases** (§M5: *"Cubits call use cases, not repositories. If a use case is missing, create one."*): `dashboard_attention_cubit` (4 repositories, 6 call sites), `my_day_cubit` (`StaffRepository` ×2), `my_shifts_cubit` (`StaffRepository`), `my_childs_day_cubit` (`StudentRepository` ×2), `my_attendance_cubit` (`AttendanceRepository` ×2), `classroom_shifts_cubit` (`StaffRepository`), `work_break_reminder_cubit` (`StaffRepository`). **7 of 12 data-bearing cubits.**

**Screens that could be `StatelessWidget` once state moves:** `dashboard_screen` (needs its epoch, keep), `admin_dashboard`/`staff_dashboard`/`parent_dashboard` (hold only a coordinator ref + two `GlobalKey`s — could be stateless once construction moves to the route builder), and 13 cards whose only state is `_minimized`.

## M6 — Reuse; pure functions out of build()

| Metric | Count |
|---|---:|
| `Widget _buildXxx()` methods | **46** (+5 more `Widget _xxx()` non-`_build` prefixed) |
| Files > 400 lines | **16 of 67** (24%) |
| `catch (_)` | **18** |
| Commented-out code lines | **287** |
| Duplicate class names in module | **3** |
| Duplicate class names vs `lib/` | **8** |

### `Widget _build*()` per file

`my_childs_day_card` 7 · `my_day_card` 6 · `movements_card` 5 · `student_billing_card` 4 · `student_attendance_card` 4 · `billing_card` 4 · `availability_card` 4 · `ratio_monitoring_card` 2 · `attention_grid` 2 · `admin_dashboard` 2 · `todo_card` 1 · `my_attendance_card` 1 · `classroom_shifts_card` 1 · `classroom_progress_card` 1 · `staff_dashboard` 1 · `parent_dashboard` 1.

`my_day_card.dart`'s `_buildShimmerBody()` (l.1537, ~74 lines) and `_buildAlignedTimerDisplay()` (l.949, ~70 lines) are the largest; neither can be `const`, and both rebuild with the enclosing 2,241-line widget on every one of the ticker's 1-second `setState`s.

### Files > 400 lines

```
2241  my_day_card.dart          1816  my_childs_day_card.dart    762  attention_grid.dart
 733  ratio_monitoring_card     670  classroom_shifts_card       645  movements_card
 621  enrollment_card           617  student_billing_card        595  QR_Code_scanner
 584  billing_card              570  availability_card           499  student_attendance_card
 478  my_shifts_card            442  ratio_monitoring_cubit      424  my_attendance_card
 410  my_attendance_cubit
```
Two files are **5.6×** and **4.5×** the ceiling. Together they are **4,057 lines — 22% of the module**.

### `catch (_)` — 18

`my_childs_day_card` 5 · `my_day_card` 4 · `qr_validation_cubit` 3 · `QR_Code_scanner` 2 · `my_childs_day_cubit` 2 · `ratio_monitoring_card` 1 · `my_shifts_cubit` 1.

Not merely a style issue here: `my_day_card.dart:262` swallows the sign-in-status failure and still sets `_signInStatusLoaded = true`, which is the flag that gates whether the geofence Sign-In sheet may be shown. A swallowed failure is treated as a resolved "not signed in".

### Commented-out code — 287 lines

`my_childs_day_card` 114 · `student_attendance_forms` **50 (the entire file)** · `enrollment_card` 29 · `my_day_card` 20 · `student_newsletters_card` 16 · `staff_dashboard` 8 · `admin_dashboard` 8 · `parent_dashboard` 7 · `student_attendance_card` 6 · `my_shifts_card` 4 · rest ≤3.

The same commented-out `isPartialError` snackbar block appears verbatim in **all three** dashboard files (`admin_dashboard.dart:198–204`, `staff_dashboard.dart:116–122`, `parent_dashboard.dart:117–123`). The three `viewmodels/` enums each carry commented-out `events`/`todo`/`classroomProgress` members that keep the three dead cards alive.

### Duplicate class names

**Confirmed: `StudentAttendanceCard` is now ×2, not ×3.** §6.1's table lists three (`attendance/view/screens/widgets/`, `attendance/widgets/`, `dashboard/view/widgets/`). The `attendance/widgets/student_attendance_card.dart` copy was deleted in commit `d8813e83` *"Task 07: de-duplicate attendance components"*. Remaining:

| Name | Copies | Locations |
|---|---:|---|
| **`StudentAttendanceCard`** | **2** | `attendance/view/screens/widgets/student_attendance_card.dart:76` · **`dashboard/view/widgets/student_attendance_card.dart:19`** — two different `StatefulWidget`s, one name |
| `_StudentAttendanceCardState` | 2 | same two files |
| **`_EmptyState`** | **3** | **`dashboard/view/widgets/student_newsletters_card.dart:350`** · `communication/…/admin_chat_host_screen.dart:1157` · `communication/…/conversation_list_screen.dart:832` — §6.1's *"private duplicates across unrelated features"*, confirmed at 3 |
| `StudentAttendanceProfileState` | 2 | `attendance/view_model/student_attendance_profile_state.dart:3` · **`dashboard/cubit/student_attendance_profile_state.dart:5`** — two cubit states, one name, different shapes |
| `_DashboardCardList` | **3** | **all inside the module** — `admin_dashboard.dart:231`, `parent_dashboard.dart:156`, `staff_dashboard.dart:146`. Near-identical: `BlocBuilder` → `LayoutBuilder` → gutter → `Align` → `ConstrainedBox(640)` → `CustomScrollView` → `SliverReorderableList`. Admin's adds a header sliver and `cacheExtent: 5000`. |
| `_CommunicationRowWidget` + `_CommunicationRowWidgetState` | **2 each** | **both inside the module** — `my_day_card.dart:1644/1652` and `my_childs_day_card.dart:1488/1526`. Same purpose (latest-chat preview row), different constructors (`const _CommunicationRowWidget()` vs `({studentCode, childName})`) and different fan-out (1 stream vs 2-per-type). **Not interchangeable** — §M6's *"diff each collision before merging"* applies. |
| `_LegendItem` | 2 | `dashboard/…/classroom_shifts_card.dart:512` · `scheduling/widgets/scheduling_legend.dart:80` |
| `_ShimmerCard` | 2 | `dashboard/…/attention_grid.dart:482` · `shared/common/widgets/custom_shimmer_loader.dart:1907` |
| `_ShimmerLine` | 2 | `dashboard/…/my_day_card.dart:1611` · `shared/common/widgets/custom_shimmer_loader.dart:1940` |
| `_StaffProfileHeader` | 2 | `dashboard/…/my_shifts_card.dart:395` · `scheduling/view/staff_scheduling_screen.dart:1113` |

`_ShimmerCard` and `_ShimmerLine` are the sharpest reuse failures: the shared library file that already defines both is **already imported by the module** (`custom_shimmer_loader.dart` supplies `MovementsCardShimmer`, `AvailabilityCardShimmer`, `MyChildsDayCardShimmer`, `StudentAttendanceCardShimmer`, `BillingTransactionShimmer`, `ShimmerLoader`) — the two private copies were written next to imports of their own public equivalents.

### Pure logic inside build()/State

`billing_card.dart` `_getPercentage` / `_getTotalAllAmounts` / `_toMonthlyValues`; `my_day_card.dart` `_formatStaffTime` / `_formatTime` / `_computeCountdownFromSchedule` (112 lines) / `_applyNextStaffShift`; `my_childs_day_card.dart` `_fmtHM` / `_schoolDowKey` / the whole `_buildAlignedTimerDisplay` font-fitting calculation; `student_billing_card.dart` `_formatDate` / `_isRefund` / `_isInvoice`; `movements_card.dart` `_statusColor` / `_statusBackground`; `my_attendance_cubit.dart` parses `"5 Hrs 30 Mins"` with `split(' ')` and index arithmetic. All belong on entities or in `core/extensions/`.

## M7 — One responsive source

| Metric | Count | Sites |
|---|---:|---|
| `MediaQuery.of` | **2** | `classroom_shifts_card.dart:56`, `my_childs_day_card.dart:658` |
| `MediaQuery.sizeOf` | **0** | — |
| `MediaQuery.textScalerOf` | 1 | `my_childs_day_card.dart:653` |
| `LayoutBuilder` | **5** | 3 gutter + 2 own-box |
| width literal comparisons | **4** | 3× `constraints.maxWidth < 360`, 1× `MediaQuery.of(context).size.width > 600` |
| responsive-helper imports | **0** | — |
| hardcoded pixel dimensions | **546** | see §M4 |

**Which responsive helper does each file import, and its breakpoint?**
**None. Zero files in the module import any responsive helper.** Not `core/responsive/app_breakpoints.dart` (4 importers app-wide, `medium: 600` / `expanded: 1024`), not `shared/utils/responsive_helper.dart` (**122 importers**, tablet `>= 768`), not `shared/utils/responsive_sizing.dart` (tablet `>= 600`), not `calendar_responsive_helper.dart` (tablet `> 600`). `ResponsiveScope` **is** mounted (`lib/app/app.dart:82`), so `context.screenSize` is available to every dashboard widget — and is read nowhere. The dashboard measures for itself in all four sites.

`classroom_shifts_card.dart:56` is therefore the module's **fifth live definition of "tablet"**:
```dart
double get _bodyFontSize => MediaQuery.of(context).size.width > 600 ? 16 : 14;
```
It uses `.of` (subscribes to the whole `MediaQueryData`, so this getter re-resolves on every keyboard open — §M7's named cost), it is a bare `600` literal, and it disagrees with `responsive_helper`'s 768 that 122 other files use. A 700pt device gets tablet body text in this card and phone layout in every widget around it.

`my_childs_day_card.dart:658` uses deprecated `MediaQuery.of(context).textScaleFactor` as a `catch (_)` fallback behind `MediaQuery.textScalerOf` — text scaling, not width, so it is a lesser violation.

### SEPARATELY — the gutter checks §7.2 names as legitimate own-box uses

§7.2 states: *"A `LayoutBuilder` in a feature file is allowed only when the widget must respond to its own box, not the screen… There are three of these today (the two attendance cards checking `constraints.maxWidth < 300` and **the dashboard gutter checks**) and they should stay."*

The dashboard gutter checks, all three, identical:

| File | Line | Code |
|---|---:|---|
| `view/admin_dashboard.dart` (`_DashboardCardList.build`) | 248–250 | `LayoutBuilder(builder: (context, constraints) { final double gutter = constraints.maxWidth < 360 ? 12 : 16;` |
| `view/staff_dashboard.dart` (`_DashboardCardList.build`) | 158–160 | identical |
| `view/parent_dashboard.dart` (`_DashboardCardList.build`) | 168–170 | identical |

**Verdict: these are the sanctioned ones and they stay.** They read `constraints.maxWidth` — the box the card list was given, which is not the screen width once the `ConstrainedBox(maxWidth: 640)` and any tablet chrome are in play — and they use it only to pick horizontal padding for that same box. That is exactly §7.2's "a card that reflows inside a narrow column".

Two caveats worth recording before anyone touches them: (a) the `360` literal is still a magic number and should move to `AppBreakpoints` as a named constant even though the *check* stays; (b) the three copies are byte-identical and live inside three byte-identical `_DashboardCardList` classes (§M6 collision above) — merging those classes collapses three sanctioned `LayoutBuilder`s into one.

**Two further `LayoutBuilder`s not named in §7.2, both of which I assess as legitimate own-box uses that should also stay:**

| File | Line | Why it is own-box |
|---|---:|---|
| `widgets/student_newsletters_card.dart` | 312 | `SizedBox(width: constraints.maxWidth)` inside `_MetaRow` — *"force bounded width so flex children never see unbounded constraints when the card is hosted in slivers / reorderable lists"*. Pure constraint plumbing; no breakpoint, no literal. |
| `widgets/my_childs_day_card.dart` | 634 | `_buildAlignedTimerDisplay` fits a countdown's font size to the width its own container was given, clamped `14.0…48.0`, scaled by the user's text scaler. Genuinely responds to its box, not the screen. |

So: **5 `LayoutBuilder`s, 5 legitimate, 0 to delete.** The M7 work in this module is the `600` literal at `classroom_shifts_card.dart:56`, the `.of` → `.sizeOf` swap, the `360` literals → `AppBreakpoints`, and the 546 hardcoded dimensions.

## M8 — Models, not maps

**Generated JSON models in the codebase: 18 `.g.dart` files, all under `lib/data/features/reports/models/`.** `json_annotation ^4.9.0` and `json_serializable ^6.8.0` are both wired in `pubspec.yaml`. **Zero generated models in any feature the dashboard consumes.**

### `Map<String, dynamic>` per layer

| Layer | Count | Note |
|---|---:|---|
| `lib/data` | **1,277** | correct location for most |
| `lib/presentation` | **304** | app-wide violation |
| `lib/domain` | **69** | app-wide violation |
| `lib/shared` | 42 | |
| `lib/core` | 34 | |
| **`presentation/features/dashboard`** | **3** | see below |

The dashboard itself is **near-clean on raw maps** — 3 occurrences:

| Site | Use | Verdict |
|---|---|---|
| `cubit/qr_validation_cubit.dart:244` | `static String? extractFromMap(Map<String, dynamic> map)` reading `map['qrToken'] ?? map['qrPayload']` | **violation** — a wire payload parsed in a presentation cubit |
| `view/QR_Code_scanner.dart:404` | `jsonDecode(raw) as Map<String, dynamic>` | **violation** — a view decoding JSON |
| `widgets/my_shifts_card.dart:327` | `showDialog<Map<String, dynamic>>` | **violation** — an untyped dialog result |

Plus the **8 untyped `extra:` payloads** from §M1, which are `Map<String, dynamic>` route arguments in all but name.

### Per-feature model state (the layers the dashboard reads)

| Feature | `Map<String,dynamic>` in `domain` | in `data` | hand-written `fromJson` factories | generated `.g.dart` |
|---|---:|---:|---:|---:|
| attendance | 25 | 220 | 28 | **0** |
| activity | 14 | 90 | 6 | **0** |
| staff | 12 | 151 | 20 | **0** |
| student | 12 | 223 | 14 | **0** |
| classroom | 5 | 59 | 9 | **0** |
| newsletter | 1 | 46 | 10 | **0** |
| scheduling | 0 | 46 | 4 | **0** |
| availability | 0 | 40 | 6 | **0** |
| billing | 0 | 143 | 35 | **0** |
| **total** | **69** | **1,018** | **132** | **0** |

**132 hand-written parsers, zero generated,** across the dashboard's dependency surface.

### Unchecked casts and defaulting idioms in the module

**27 cast sites.** The pattern that matters is `Future.wait` returning `List<dynamic>` and each element being blind-cast by index:

```dart
// dashboard_attention_cubit.dart:149-170 — six positional casts, all nullable-by-onError
final incidentResult      = results[0] as int?;
final movementResult      = results[1] as ({int pendingCount, int overdueCount})?;
final staffDocResult      = results[2] as ({int expiredDocumentCount, int expiringWithinWeekCount})?;
// …
// school_status_cubit.dart:164-170
final studentCounts = results[0] as ({int activeCount, int upcomingCount, int enrolledCount});
final classroomCount = results[1] as ClassroomCount;
final staffSummary  = results[2] as StudentAttendanceExpectedSummary;   // ← "staff" typed as Student…
final studentSummary= results[3] as StudentAttendanceExpectedSummary;
final fte           = results[4] as SchoolFte;
```

Six of the dashboard's repository contracts return **anonymous Dart records** rather than models — `({int pendingCount, int overdueCount})`, `({int expiredDocumentCount, int expiringWithinWeekCount})`, `({int overduePhysicalCheckupCount, int staffWithoutActivePhysicalCheckupCount})`, `({int expiredDocumentCount, int expiringWithinWeekCount, int totalDocumentsWithExpiry})`, `({int overdueExamCount, int studentsWithoutActiveExamCount})`, `({List<StaffProfileWorkSchedule> workSchedules, List<StaffProfileBreakSchedule> breakSchedules})`. §M8 requires *"a model class in `data/features/<x>/models/`… If an entity has a model, that model is the type used everywhere it travels."* A record has no name, no `fromJson`, cannot be mapped, and its structural type must be retyped in full at every cast site — `dashboard_attention_cubit.dart:152–170` spends 19 lines doing exactly that.

`classroom_shifts_cubit.dart:125–231` is worse: it casts `Future.wait` results to `List<dynamic>` and then does **untyped member access** on the elements (`c.code as String`, `raw.staffName as String? ?? ''`, `raw.isPublished as bool? ?? false`, `(raw.scheduledHours as int? ?? 0).toDouble()`) — dynamic dispatch with inline defaults, 11 casts in one method. `my_childs_day_cubit.dart:117` does `final typedProfile = profile as dynamic;` then reads `typedProfile?.fullName as String? ?? ''`.

Defaulting idioms: **`?? 0` / `?? false` / `?? ''` appear throughout these cast expressions** — every one of them converts a missing or wrong-typed field into a plausible value. See Part 4.

---

# PART 4 — CORRECTNESS PASS

## 4.1 The finding that explains everything else: `DashboardCardErrorOverlay` is a no-op

`widgets/dashboard_error_chip.dart` — 36 lines, **12 call sites across the module**:

```dart
class DashboardCardErrorOverlay extends StatelessWidget {
  const DashboardCardErrorOverlay({required this.show, required this.child, required this.onRetry, ...});
  final bool show;                              // "no longer drives any UI, retained for call-site compatibility"
  final Future<void> Function() onRetry;        // "retained for call-site compatibility; no longer invoked from here"
  @override
  Widget build(BuildContext context) => child;  // ← the entire body
}
```

Its own doc comment records the decision honestly: *"per product decision the dashboard no longer surfaces that chip, so this now renders the card unchanged."*

The consequence is that **every card that believes it handles its error state does not.** `ratio_monitoring_card`, `classroom_shifts_card`, `movements_card`, `availability_card`, `enrollment_card`, `my_attendance_card`, `my_shifts_card`, `my_childs_day_card`, `student_attendance_card`, `student_newsletters_card` all pass `show: state.isError` and a working `onRetry`, and all render their normal zero/empty layout instead. The `onRetry` callbacks — `() => context.read<MyDayCubit>().load()`, `_loadData`, `_refresh` — are dead code: the widget never calls them.

The only surviving error surfaces on the whole dashboard are:
1. `StudentBillingCard`'s inline `state.errorMessage != null && state.ledger == null` branch — real message + Retry button.
2. `MovementsCard`'s inline `board == null && errorMessage != null` branch.
3. The coordinator's `BlocListener` snackbar — which fires **only when `isAllError`**, i.e. when *every single* child cubit has failed. Its `isPartialError` branch is commented out in all three dashboards.

So: one card failing → silent zeros. Six of seven cards failing → silent zeros. All seven failing → one snackbar.

## 4.2 DEFAULTS THAT LOOK SAFE

Ranked by how convincingly a failure renders as a normal reading.

### D-1 — The ratio card. Confirmed, and worse than "a `?? 0`".

`ratio_monitoring_cubit.dart:227–228`:
```dart
studentPresent: studentEntry?.present ?? 0,
staffPresent:   staffEntry?.present   ?? 0,
```
A classroom absent from either attendance map renders as 0 students / 0 staff. Then `RatioMonitoringClassroom.isRatioGood` (`domain/features/classroom/entities/ratio_monitoring_classroom.dart:37`):
```dart
if (studentPresent == 0) return true;   // "Empty classroom — nothing to supervise."
```
**A classroom whose attendance data is missing renders green, "in ratio".** It is then excluded from `attention_grid.dart:304`'s `classrooms.where((c) => !c.isRatioGood).length`, so the "Classrooms / Not in Ratio" attention card's count drops — and at 0 the card is removed entirely by `shouldShow => count > 0`.

Two more layers on the same defect:

- **`ratio_monitoring_cubit.dart:181–199`** — Phase 1 emits **`RatioMonitoringState.loaded`** with every classroom explicitly zero-filled (`studentPresent: 0, staffPresent: 0`) *before* the attendance calls are made, specifically so the table is not empty. Status is `loaded`, not `loading`, so `showShimmer` is false and the card renders a complete, authoritative-looking, all-green ratio table during Phase 2.
- **`ratio_monitoring_cubit.dart:239–250`** — if Phase 2 throws, `shouldShowError = !state.isLoaded || state.classrooms.isEmpty` is **false** (Phase 1 already emitted `loaded` with rows), so the cubit emits `status: RatioMonitoringStatus.loaded, errorMessage: null`. The zero-filled table is permanently labelled a successful load. `state.isError` is false, so even a working error overlay would not fire.

**Net:** a ratio-monitoring attendance outage renders as *every classroom compliant*, on a compliance screen, with no error state, no shimmer, and no attention card. The comment at `ratio_monitoring_card.dart:381` — *"A zero means 'no one signed in', not 'missing classroom'"* — documents the intent; the code cannot tell the two apart.

### D-2 — The entire "Need your attention" section disappears on failure

`dashboard_attention_cubit.dart:180–212`. All six APIs are wrapped `.onError((_, __) => null)`, then:
```dart
pendingIncidents: incidentResult ?? state.pendingIncidents,
pendingMovements: movementResult?.pendingCount ?? state.pendingMovements,
// …9 more, same shape
```
On a **first** load every `state.x` is the `DashboardAttentionState` field default, which is **`0`** for all eleven counters (`dashboard_attention_state.dart:22–32`). So six failed calls → eleven zeros.

`attention_grid.dart:437` filters `.where((c) => c.shouldShow)`, and `shouldShow => count > 0`. Every card's count is 0 → `cards.isEmpty` → `attention_grid.dart:143`:
```dart
if (cards.isEmpty) return const SizedBox.shrink();
```

**A total failure of all six attention APIs is rendered identically to "nothing needs your attention": the section is not there.** The state does carry `status: partialFailure`, and `isLoaded` explicitly *includes* `partialFailure` (`dashboard_attention_state.dart:54–56`), so the coordinator counts it as loaded and the dashboard reports ready.

On a *refresh* the `?? state.x` fallback additionally freezes the previous values, so stale counts render as current with no staleness indicator.

### D-3 — A failed schedule fetch renders as "school closed today"

`my_day_cubit.dart:75–79, 109, 117–132`:
```dart
final results = await Future.wait([
  _staffRepository.getSchoolRegularSchedules(...).then<Object?>((v) => v).onError((_, __) => null),
  ...
]);
final days = results[0] as List<SchoolRegularScheduleDay>? ?? <SchoolRegularScheduleDay>[];
// …
final bool closed = todayEntry == null || !todayEntry.isActive;
emit(state.copyWith(status: MyDayStatus.loaded, schoolClosed: closed, ...));
```
`getSchoolRegularSchedules` fails → `days = []` → no `todayEntry` → **`schoolClosed: true`, `status: loaded`**. The same happens at `my_day_cubit.dart:76–88` when the school code is missing from storage — an explicit `emit(status: loaded, schoolClosed: true)`.

The card then shows the school as closed for the day. Staff self-attendance actions key off this. Nothing distinguishes it from a real closure, and `MyDayStatus.error` is never reached.

### D-4 — A failed child-profile fetch renders as a nameless child

`my_childs_day_cubit.dart:89, 117, 122–125`:
```dart
_getStudentProfileUseCase(code: code).then<Object?>((v) => v).onError((_, __) => null),
// …
final typedProfile = profile as dynamic;
_safeEmit(state.copyWith(
  status: MyChildsDayStatus.loaded,
  fullName:      (typedProfile?.fullName      as String? ?? '').trim(),
  classroomName: ((typedProfile?.classroomName as String?) ?? '').trim(),
  schoolCode:    (typedProfile?.schoolCode    as String? ?? '').trim(),
```
Profile call fails → `profile == null` → three empty strings → **`status: loaded`** with a blank name, blank classroom and blank school code on the parent's primary card. The sibling call (`getStudentRegularSchedules`) has its own `.onError((_, __) => <StudentRegularScheduleEntry>[])`, so a schedule failure yields `todayScheduleRange = ''` — rendered as no schedule today.

### D-5 — `raw == null` is a successful empty attendance record

`my_attendance_cubit.dart:271–274`:
```dart
if (raw == null) {
  emit(state.copyWith(status: _Status.loaded, attendanceLoaded: true));
  return;
}
```
The repository returning null (its documented shape for a non-2xx it chose not to throw on) emits `loaded` while `attendedDays`, `attendedHours`, `attendedMinutes`, `absentDays` all keep their `0` defaults and `totalAttendedTime` stays `''`. `my_attendance_card` renders "0 attended days, 0 Hrs 0 Mins" as a completed load.

Even on the genuine-exception path — which *does* set `_Status.error` — the card wraps its zeros in `DashboardCardErrorOverlay(show: state.isError)`, i.e. §4.1's no-op. Same pixels either way.

### D-6 — `student_attendance_card.dart:345`

```dart
// On error, fall through to the normal stats layout below — it renders
// default/empty values (e.g. "0 Hrs 0 Mins") instead of an error banner.
final attendedTime = state.totalAttendedTime.isNotEmpty ? state.totalAttendedTime : '0 Hrs 0 Mins';
final hours   = hourMatch?.group(1)   ?? '0';
final minutes = minuteMatch?.group(1) ?? '0';
```
Three defaults in four lines, and the comment states the intent explicitly. A parent sees their child's attendance as zero hours.

### D-7 — `enrollment_card.dart:96`

```dart
// On error, fall through to the normal card layout below — it
// renders whatever values are in state (zeros on a first-load
// failure) instead of replacing the card with an error banner.
```
Enrolled / Active / Upcoming / Capacity / Expected Students / Expected Staff all render 0, with percentage bars computed against a 0 denominator.

### D-8 — Silent degradations inside otherwise-working loads

| Site | Default | Rendered as |
|---|---|---|
| `classroom_shifts_cubit.dart:118` | `_getStaffShifts(...).catchError((_) => <StaffShift>[])` | classrooms with no staff assigned |
| `classroom_shifts_cubit.dart:208–216` | `raw.staffName as String? ?? ''`, `raw.isPublished as bool? ?? false`, `(raw.scheduledHours as int? ?? 0)` | unnamed staff, unpublished shifts, 0 scheduled hours |
| `classroom_shifts_cubit.dart:145–152` | `classrooms.isEmpty` → `emit(status: loaded, entries: const [])` | "no classrooms" — same as a scoping failure |
| `my_shifts_cubit.dart:64–72` | `_getClassrooms(...).catchError((_) => [])`, `getSchoolRegularSchedules(...).catchError((_) => [])` | classroom **codes** instead of names; empty school hours |
| `my_shifts_cubit.dart:139` | `status: shifts.isEmpty ? _Status.empty : _Status.loaded` | a fetch that returned nothing == a day with no shifts |
| `ratio_monitoring_cubit.dart:399–408` | shift fetch fails → `_cachedShiftClassroomCodes = const {}` **and the cache is marked valid for the week** | a staff member silently sees a narrower classroom list for up to 30 min / the rest of the week |
| `ratio_monitoring_cubit.dart:345–350` | `jsonDecode` of allowed-classroom-codes throws → `return const {}` | scope falls back to shift codes only |
| `my_day_card.dart:262` | `catch (_) { setState(() => _signInStatusLoaded = true); }` | a failed status check counts as "resolved, not signed in" — gates the geofence Sign-In sheet |
| `_CommunicationRowWidget._init` (both copies) | 8-second `Timer` sets `_loading = false` with `_items` still empty | "No recent chat" |

## 4.3 Cards whose zero/empty state is INDISTINGUISHABLE from a failed fetch

| Card | Failure renders as | Distinguishable? |
|---|---|---|
| **RatioMonitoringCard** | full classroom table, every room 0/0, all green, status `loaded` | **No** — and it is a compliance surface |
| **AttentionGrid** | section absent from the page | **No** — reads as "all clear" |
| **MyDayCard** | "school closed today"; "No recent chat" | **No** |
| **EnrollmentCard** | all six statistics 0, bars at 0% | **No** (comment admits it) |
| **MyAttendanceCard** | 0 attended days, "0 Hrs 0 Mins" | **No** |
| **StudentAttendanceCard** | 0 attended days, "0 Hrs 0 Mins" | **No** (comment admits it) |
| **StudentNewslettersCard** | `_EmptyState` "No newsletters found" + Refresh | **No** (comment admits it) |
| **MyShiftsCard** | `_Status.empty` — "no shifts today" | **No** |
| **ClassroomShiftsCard** | classrooms listed with no staff, or an empty entry list | **No** |
| **AvailabilityCard** | empty availability table | **No** |
| **MyChildsDayCard** | blank child name, blank classroom, no schedule | **Partially** — a blank name is *visibly* odd, but it is not labelled an error |
| **MovementsCard** | `_buildEmptyState()` "no movements" | **Partially** — has an inline `board == null && errorMessage != null` branch, so a hard failure does show; a soft/empty result does not |
| **BillingCard** | zeros in totals, flat chart | **No** — no error branch at all |
| **StudentBillingCard** | error text + Retry button | **Yes** — the only card in the module that gets this right |

**13 of 14 cards render a failed fetch as a normal reading.** The Retry button in `student_billing_card.dart:501–505` is the pattern the other thirteen need.

## 4.4 Cubit lifecycle — which are actually leaked

§5.5's mechanism (`serviceLocator<XCubit>()` in `initState`, no `BlocProvider` ownership, `registerFactory` so a fresh instance per open, 56 of 98 files never call `.close()`) applies to how the dashboards are constructed. The coordinators themselves, however, **are not leaked** — this module got that part right:

```dart
// admin_dashboard.dart:49        _coordinator = serviceLocator<AdminDashboardCoordinatorCubit>();
// admin_dashboard.dart:139-140   BlocProvider<AdminDashboardCoordinatorCubit>(create: (context) => _coordinator, …)
```
`BlocProvider.create` takes ownership and closes on unmount; each coordinator's `close()` then cancels its `StreamSubscription`s and closes every child cubit, deliberately skipping the `GeofenceCubit` singleton. All child cubits reach the view as `BlocProvider.value` (which correctly does *not* close them), so there is exactly one owner. `dispose()` in all three dashboards is an empty override with a comment saying so.

Per-cubit verdict:

| Cubit | DI lifetime | Owner | Closed? |
|---|---|---|---|
| `AdminDashboardCoordinatorCubit` | factory | `BlocProvider.create` (`admin_dashboard.dart:139`) | ✅ |
| `StaffDashboardCoordinatorCubit` | factory | `BlocProvider.create` (`staff_dashboard.dart:63`) | ✅ |
| `ParentDashboardCoordinatorCubit` | factory | `BlocProvider.create` (`parent_dashboard.dart:62`) | ✅ |
| `AdminDashboardCubit` / `StaffDashboardCubit` / `ParentDashboardCubit` | factory | coordinator `close()` | ✅ |
| `SchoolStatusCubit`, `RatioMonitoringCubit`, `ClassroomShiftsCubit`, `DashboardAttentionCubit`, `MyDayCubit`, `MyShiftsCubit`, `MyAttendanceCubit`, `MyChildsDayCubit`, `StudentAttendanceProfileCubit`, `StudentNewslettersCubit` | factory | coordinator `close()` | ✅ |
| `IndividualMovementsCubit`, `FutureAvailabilityCubit` (availability), `CommunicationCubit`, `ParentBillingCubit` (billing) | factory | coordinator `close()` | ✅ |
| `TransactionsCubit`, `AnalyticsCubit` (billing) | factory | `BlocProvider.create` in `billing_card.dart:37–43` | ✅ |
| `QrValidationCubit` | factory | `BlocProvider.create` in `QR_Code_scanner.dart:23–24` | ✅ |
| `GeofenceCubit` | **lazySingleton** | app | ✅ correctly never closed |
| `ParentChildCubit` | **lazySingleton** | app | ✅ correctly never closed |
| **`WorkBreakReminderCubit`** | **factory** | **nobody** | ❌ **LEAKED** |

### L-1 — `WorkBreakReminderCubit`, leaked once per tap

`my_day_card.dart:2137–2141`, inside `_ReminderToggleButtonState._toggleReminder()`:
```dart
Future<void> _toggleReminder() async {
  ...
  final cubit = serviceLocator<WorkBreakReminderCubit>();   // registerFactory — di.dart:2142
  await cubit.toggleReminder(staffCode: widget.staffCode, currentEnabled: _reminderEnabled);
  ...                                                       // never closed, not held in a field
}
```
This is §5.5's exact shape, in its worst form: not once per screen open but **once per button tap**. Each tap allocates a fresh cubit holding a `StaffRepository` reference, awaits a network write on it, reads `cubit.state`, and drops it unclosed. It is not owned by any `BlocProvider`, is never stored, and there is no `.close()` anywhere in the file. `_ReminderToggleButton` also mirrors the cubit's result into its own `setState(() => _reminderEnabled = state.enabled)` rather than listening to it — the cubit is used as a one-shot network call with a state object attached.

**Fix shape:** the toggle belongs on `MyDayCubit`, or `WorkBreakReminderCubit` must be provided once above the button.

### L-2 — `RatioMonitoringCard._notesUnreadStreams` is never torn down (medium confidence)

`ratio_monitoring_card.dart:38, 58–63, 115–119`:
```dart
final Map<String, Stream<int>> _notesUnreadStreams = {};
// …
_notesUnreadStreams[classroomCode] =
    serviceLocator<ConversationEntityRepository>()
        .watchUnreadCountForConversation(code)
        .asBroadcastStream();
// …
@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();          // ← the map and its broadcast streams are not touched
}
```
The `StreamBuilder`s cancel their own subscriptions on unmount, but a broadcast stream wrapping a live Firestore listener does not necessarily cancel its source when its last listener leaves. One such stream is opened **per classroom**, and the dashboard is re-created on every school switch and every tab-visibility change (`dashboard_screen.dart:43/53` bump `_schoolReloadEpoch`, re-keying the whole subtree). I have not traced `ConversationEntityRepository.watchUnreadCountForConversation` to its Firestore source, so I am flagging this as probable rather than confirmed.

### L-3 — Latent: `DashboardCubitFactory`'s `ParentChildCubit` fallback

If `ParentChildCubit` were ever unregistered, `_resolveSafe` hand-constructs one (`dashboard_cubit_factory.dart:43`). `ParentDashboardCoordinatorCubit.close()` deliberately does **not** close `parentChildCubit` because it assumes the singleton — so the fallback instance would leak *and* would desync child selection from the rest of the app. Latent today; all four fallback types are registered.

### Correctly-handled resources (worth recording, since §5.5 predicts otherwise)

`_MyDayCardState._ticker` (`Timer.periodic`) cancelled · `AttendanceEvents.tick` listeners removed in both cards · `WidgetsBindingObserver`s removed in all four observers · `_CommunicationRowWidgetState._sub`/`_subs` and `_timeout` cancelled in both copies · `_QrScanViewState._scanSubscription` and `_scanAnim` disposed · both `ValueNotifier`s in `my_childs_day_card` disposed · all three coordinators cancel their `_subscriptions` list. The module is disciplined about `Timer`s, `StreamSubscription`s and `AnimationController`s; the gap is cubits pulled from the locator outside a provider.

## 4.5 N+1 fetching and duplicated fetches

### N+1 — genuine, three of them

**N-1. Classroom Notes unread badges (admin + staff, `RatioMonitoringCard`).**
`ratio_monitoring_card.dart:405–406` calls `_notesUnreadStreamFor(room.code)` from `_buildDataRow`, i.e. **inside `build()`**, once per rendered classroom. Each first call schedules a post-frame `GetOrCreateClassroomChatUseCase.findExisting(classroomCode)` REST call and then opens a Firestore stream. **N REST + N Firestore listeners where N = classrooms rendered** (7 initially; every additional classroom on "Show More" fires one more). A `_notesUnreadResolving` set prevents re-firing per code per widget instance, but the whole set is rebuilt when the card is recreated on school switch or tab return. There is no batch endpoint in use; `ClassroomScreen` resolves one at a time too.

**N-2. Sibling chat rows (parent, `MyChildsDayCard`).**
`my_childs_day_card.dart:1466–1480` renders **one `_CommunicationRowWidget` per sibling**, and each one's `_watchType` runs for **both** `ConversationType.adminChat` and `roomChat`, each doing cached-read + REST `GetConversationsEntityUseCase` + `WatchConversationsUseCase`. **K children → 2K REST calls + 2K Firestore listeners**, all fetching from the same conversations collection and then filtering client-side by `c.studentCode == widget.studentCode` (`_latest`, l.1731). One unfiltered fetch would serve all siblings.

**N-3. Same data fetched by two different cards.**
`MyDayCard`'s `_CommunicationRowWidget` and `MyChildsDayCard`'s `_CommunicationRowWidget` are separate implementations of the same "recent conversations" fetch. They never co-render (different personas), so this is duplication of *code* rather than of *calls* — but `MyDayCard` and `RatioMonitoringCard` **do** co-render on both admin and staff, and both independently resolve conversation data from `serviceLocator` (`GetConversationsEntityUseCase`/`WatchConversationsUseCase` vs `GetOrCreateClassroomChatUseCase`/`ConversationEntityRepository`), neither aware of the other.

### Do several cards fetch the SAME data? Yes — five overlaps

| Data | Fetched by | Deduplicated? |
|---|---|---|
| `StorageKeys.schoolCode` | all three coordinators, `MyDayCard`, `MyChildsDayCard`, `EnrollmentCard`, `RatioMonitoringCard`, `RatioMonitoringCubit`, `ClassroomShiftsCubit`, `MyShiftsCubit`, `MyDayCubit`, `DashboardAttentionCubit`, `IndividualMovementsCubit`, `FutureAvailabilityCubit` — **~13 independent reads per open** | storage, not network — cheap but symptomatic |
| `getSchoolRegularSchedules(schoolCode)` | **`MyDayCubit` + `MyShiftsCubit` + `ClassroomShiftsCubit`** — three separate cubits, same endpoint, same argument | ❌ **not deduplicated — 3 identical requests on a staff open** |
| ratio classroom list | `RatioMonitoringCubit` (`GetRatioMonitoringClassroomsUseCase`) and `MyShiftsCubit` (`GetRatioMonitoringClassroomsUseCase` via `_getClassrooms`) | ❌ two requests |
| active classroom list | `ClassroomShiftsCubit` (`GetActiveClassroomsUseCase`) and `MyDayCard._CommunicationRowWidget` (`GetActiveClassroomsUseCase`) | ❌ two requests |
| staff shifts for the current week | `RatioMonitoringCubit._resolveShiftClassroomCodes` (`GetStaffShiftsUseCase`) and `MyShiftsCubit._getShifts` (`GetStaffShiftsUseCase`) | ❌ two requests on staff |
| `checkStaffSignInStatus()` | `GeofenceCubit.initForSchool` (coordinator) **and again** from `MyDayCard._initializeGeofencing` — `geofence_cubit.dart:217` runs it *before* the already-monitoring early-exit at `:223` | ❌ always duplicated |

`CacheManager` mitigates some of this (`school_status_cubit` and `ratio_monitoring_cubit` build cache keys and invalidate them on force-refresh), but `getSchoolRegularSchedules` goes through `StaffRepository` directly with no cache key at any of its three call sites.

### Duplicate card-vs-coordinator loads

Every card that fetches also duplicates a call the coordinator already made. In most cases the cubit's `_isFetching` guard **drops** the second one:

| Cubit | Guard | Effect |
|---|---|---|
| `SchoolStatusCubit` | `if (_isFetching) return;` | duplicate dropped |
| `RatioMonitoringCubit` | `if (_isFetching) return;` | duplicate dropped |
| `ClassroomShiftsCubit` | `_isFetching` + `_hasRequestedLoad` + `status != initial` in the card | duplicate dropped |
| `MyDayCubit` | `if (_isFetching) return;` | duplicate dropped |
| `MyShiftsCubit` | `if (_isFetching) return;` | duplicate dropped |
| `MyAttendanceCubit` | `if (_isFetching) return;` **and** `if (!forceRefresh && state.attendanceLoaded) return;` | duplicate dropped |
| `StudentAttendanceProfileCubit` | `if (_isFetching)` + a param-equality guard | duplicate dropped |
| `StudentNewslettersCubit` | `if (_isFetching) return;` | duplicate dropped |
| **`MyChildsDayCubit`** | **no `_isFetching` field at all** | ❌ **duplicate fires** |

**`MyChildsDayCubit` is the only data cubit in the module with no in-flight guard.** Its sole guard (`my_childs_day_cubit.dart:60–64`) is `if (!background && state.studentCode == code && state.status == loaded) return;` — and when `MyChildsDayCard.didChangeDependencies` (`my_childs_day_card.dart:253–260`) fires its post-frame `loadForChild()`, the coordinator's call from `_onChildSelectionChanged` (`parent_dashboard_coordinator_cubit.dart:86`) is still in flight with `status == loading`, so the guard misses and **the full 4-call sequence runs twice** (timezone `/time`, student profile, regular schedules, guardians). This is the one confirmed doubled fetch on a cold open.

**The guards are a drop, not a coalesce — which loses parameters.** `RatioMonitoringCard._load()` passes `date: _selectedDate`; the coordinator passes no `date`. Whichever arrives second is discarded silently, so which date the ratio table reflects depends on scheduling order. Same for `ClassroomShiftsCard`'s `_selectedDate`.

### Any card that fetches on every build or every scroll?

**On every build: yes, one.** `ratio_monitoring_card.dart:405` — `_notesUnreadStreamFor(room.code)` is evaluated as the `stream:` argument to `StreamBuilder` inside `_buildDataRow`, which runs on every build. The `_notesUnreadResolving` set makes the *network* call once per classroom per widget instance, but a fresh `Stream.value(0)` is allocated on every build for every unresolved row, and the method is genuinely re-entered each frame.

**On every scroll: no.** `SliverReorderableList` builds items lazily, but `admin_dashboard.dart:260` sets `cacheExtent: 5000` explicitly *"so GlobalKey scroll targets are always resolvable"* — every card is built and kept alive, so scrolling never triggers a new `initState` and never re-fires a fetch. `MyChildsDayCard`, `StudentAttendanceCard` and `StudentNewslettersCard` additionally use `AutomaticKeepAliveClientMixin`. The trade is memory and first-frame cost, not repeat fetches.

**Close calls that are guarded:**
- `MyChildsDayCard` runs a 1-second clock and `context.watch<MyChildsDayCubit>()` in `build`, so `didChangeDependencies` fires every second. A `_lastSignInStatusCodes` sorted-key comparison (l.162–172) stops the attendance API firing on each tick; the comment at l.158 records that this was a real bug.
- `MyDayCard` and `MyChildsDayCard` both listen to `AttendanceEvents.tick` and re-fire `_loadStaffIdentity()` / `_loadChildrenSignInStatus()` + `cubit.load()` on every attendance event app-wide. Correct behaviour, but it means any sign-in anywhere re-fires 2–6 dashboard calls.
- `RatioMonitoringCard.didChangeAppLifecycleState` re-fetches on every foreground, behind a 30-second `_refreshCooldown` keyed on `cubit.lastFetchAt`. `MyDayCard` and `MyChildsDayCard` do the same **with no cooldown**.

---

# PART 5 — ANALYZER AND TESTS

## 5.1 `flutter analyze lib/presentation/features/dashboard`

```
Analyzing dashboard...
No issues found! (ran in 7.7s)
```
**0 issues. Exit code 0.**

This number means very little, and the PDF says why on page 2: *"`analysis_options.yaml` exists in the repo root with every single line commented out, including the `include: package:flutter_lints/flutter.yaml` directive. `flutter analyze` currently enforces nothing."*

Verified — the file is still fully commented at HEAD:
```yaml
# # include: package:flutter_lints/flutter.yaml
# analyzer:
#   exclude: …
```
So "no issues" means "no compile errors". None of `prefer_const_constructors`, `unused_import`, `unused_field`, `avoid_print`, `use_build_context_synchronously` or `discarded_futures` is running. Two pieces of direct evidence from inside the module: `availability_card.dart:120` carries `// ignore: discarded_futures` and `my_childs_day_card.dart:657` carries `// ignore: deprecated_member_use` — ignores written for lints that are not currently enabled. `my_day_card.dart` also contains ~6 live `debugPrint` calls with box-drawing characters, and `geofence_cubit.dart:202–208` prints an ASCII banner on every init.

**Baseline to hold: 0 analyzer issues on this directory.** Any mandate work must not increase it — but note that turning `analysis_options.yaml` back on (§9) will change this number substantially and should be measured separately before the refactors, not during.

## 5.2 `flutter test test/presentation/features/dashboard`

```
00:00 +0: loading .../test/presentation/features/dashboard/view/widgets/movements_card_test.dart
00:00 +0: MovementsCard displays statuses in Overdue -> Confirmed -> Upcoming order
00:00 +1: All tests passed!
```

**The dashboard module has exactly one test file and one test case.** `test/presentation/features/dashboard/` contains only `view/widgets/movements_card_test.dart`. There are **no tests** for any of the 16 cubits, the three coordinators, `dashboard_cubit_factory`, or any of the other 13 cards. Every finding in Part 4 is currently unguarded by a test.

`test/widget_test.dart` does carry coordinator tests (see below) but sits at the test root, outside the module's directory.

## 5.3 `flutter test` (full suite)

```
02:28 +702 -33: Some tests failed.
```
**702 passing, 33 failing.** Exit code 1.

**None of the 33 failures is in `test/presentation/features/dashboard/`.** One exercises dashboard production code; the rest are in other modules. Classified:

### The one dashboard-touching failure — **STALE TEST**

```
test/widget_test.dart: ParentDashboardCoordinatorCubit Tests
  initializes and triggers loads if child is already selected [E]

  type 'Null' is not a subtype of type 'Future<void>'
  test/widget_test.dart 185:7                              MockCommunicationCubit.loadConversations
  .../parent_dashboard_coordinator_cubit.dart 98:26        ParentDashboardCoordinatorCubit._onChildSelectionChanged
  .../parent_dashboard_coordinator_cubit.dart 74:7         new ParentDashboardCoordinatorCubit
  test/widget_test.dart 620:27                             main.<fn>.<fn>
```

**Evidence it is a stale test, not a regression:**
- `test/widget_test.dart:185–195` — `MockCommunicationCubit`'s `loadConversations` override is **commented out**:
  ```dart
  class MockCommunicationCubit extends MockCubit<CommunicationState> implements CommunicationCubit {
    ...
    // @override
    // Future<void> loadConversations({
    //   String? type,
    //   String status = 'ACTIVE',
    //   int page = 0,
  ```
  With no override, `MockCubit`'s `noSuchMethod` returns `null` where the production call site expects a `Future<void>`.
- Production code is correct and unchanged in shape: `CommunicationCubit.loadConversations` is declared `Future<void> loadConversations({...})` at `communication_cubit.dart:453`, and `parent_dashboard_coordinator_cubit.dart:98` calls it plainly.
- The other two tests in the same group — *"updates state to ready when all child cubits are loaded"* and *"closes non-singleton cubits on close, but keeps geofence alive"* — **pass**, as do all `StaffDashboardCoordinatorCubit` and `AdminDashboardCoordinatorCubit` tests. Only the path that reaches `loadConversations` fails.
- Last touched by `ead5064a "fixed the integration test of communication module and others"`, which is where the override was commented out.

**Verdict: STALE TEST.** The test double is broken; the coordinator is fine. Restoring the commented override fixes it. Worth doing before any Mandate 5 work, because this is the only automated coverage the parent coordinator has.

### The other 32 — classified

| Group | Count | Class | Evidence |
|---|---:|---|---|
| `staff/cubit/*_test.dart` (5: `staff_profile`, `staff_schedule`, `staff_documents_list`, `staff_documents_download`, `important_dates`) | 5 | **STALE TEST** | `Error: No named parameter with the name 'repository'.` at `staff_profile_cubit_test.dart:53` — `StaffProfileCubit`'s constructor parameter was renamed in production; the tests were not updated. Compile failure at load. |
| `students/cubit/*_test.dart` (3: `student_health`, `student_physician`, `student_profile`) | 3 | **STALE TEST** | same shape — constructor-signature drift |
| `activities/view_model/*_test.dart` (3) | 3 | **STALE TEST** | compile failure at load |
| `messaging/cubit/feature_flag_cubit_test.dart` | 1 | **PRE-EXISTING PRODUCTION DEFECT** (§3.4) | `lib/domain/features/messaging/usecases/get_feature_flag_usecase.dart:2:8: Error: Error when reading 'core/errors/failures.dart': No such file or directory` — `import '../../../../../core/errors/failures.dart'` has **one `..` too many**. This is the exact defect §3.4 names by file: *"Breaks `feature_flag_cubit_test.dart`, which currently fails to load at all."* It compiles in the app (Dart discards excess `..` at the package root) and breaks the moment a test reaches it by file URI. Confirmed still present. |
| `communication/v2/cubit/conversation_thread_cubit_test.dart` | 10 | **STALE TEST** (probable) | assertion failures in `sendMessage with attachments`, `deleteAttachment`, `markConversationRead debounce` — behaviour tests against a cubit reworked in `ead5064a` |
| `integration/private_mode_flow_test.dart` | 5 | **STALE TEST** (probable) | API-call-shape assertions |
| `messaging/widgets/chat_input_bar_test.dart` | 2 | **STALE TEST** (probable) | widget-finder failures after a UI change |
| `core/util/api_paths_uat_test.dart` | 2 | **STALE TEST** (probable) | path-shape assertions for `staff my-profile` segments |

**Summary: 32 of 33 are stale tests; 1 is a real production defect** (the messaging excess-`..` import, already named in the PDF, outside this module). **The dashboard's own directory is green (1/1), and its coordinator tests in `widget_test.dart` are 8/9 with the one failure caused by a commented-out mock override.**

**Baselines to hold for any mandate work on this module:**
- `flutter analyze lib/presentation/features/dashboard` → **0 issues**
- `flutter test test/presentation/features/dashboard` → **1 passing, 0 failing**
- `flutter test` → **702 passing, 33 failing** (must not grow)

---

# PART 6 — SUMMARY SCORECARD

| Mandate | Dashboard count | Worst file |
|---|---|---|
| **1** GoRouter everywhere | 13 `MaterialPageRoute`, 12 raw `Navigator` pushes, **11 of 13 cross a feature boundary**; 1 `GoRoute`; 0 route constants; 8 untyped `extra` maps | `my_day_card.dart` (5) |
| **2** setState scarcely | 68 `setState`, 26 `StatefulWidget`, 2 `ValueNotifier` (both disposed ✅), 2 `ValueListenableBuilder` (neither uses `child:`), 0 `BlocSelector`; the expand/collapse boolean hand-rolled 13× | `my_day_card.dart` (20) |
| **3** Folder structure | `viewmodels/` (only feature), `cubit/` (app-wide), `services/` (§3.3 named), no `model/`; 6 relative cross-folder imports, **0 with excess `..`**; **56 imports from 8 other features' presentation layers** | `QR_Code_scanner.dart` (§3.3 named) |
| **4** Centralized theming | 378 `Colors.*`, 11 `Color(0x`, **158 inline `TextStyle`** (my_day_card **18** ✅ confirmed), 6 `fontFamily`, 0 `textTheme`, 0 `AppStrings`, 0 `AppSizes`, 546 hardcoded dimensions | `my_day_card.dart` |
| **5** Presentation → cubits only | **30 `serviceLocator`, 0 in a `GoRoute` builder** (my_day_card **10** ✅ confirmed); 10 use cases invoked from views; 1 repository type in a view; 7 of 12 cubits call repositories; **1 cubit imports `lib/data`** | `my_day_card.dart` (10) |
| **6** Reuse; pure fns out of build | 46 `Widget _build*()`, 16 files > 400 lines, 18 `catch (_)`, 287 commented-out lines, **665 lines of dead cards**; `StudentAttendanceCard` **×2** (was ×3, one deleted in `d8813e83`), `_EmptyState` **×3** ✅ confirmed, `_DashboardCardList` ×3, `_CommunicationRowWidget` ×2 | `my_day_card.dart` (2241) |
| **7** One responsive source | **0 responsive-helper imports** despite `ResponsiveScope` being mounted; 5 `LayoutBuilder` (**all 5 legitimate** — 3 gutter checks named by §7.2 + 2 own-box), 2 `MediaQuery.of`, 0 `.sizeOf`, **1 fifth definition of "tablet" at `> 600`** | `classroom_shifts_card.dart:56` |
| **8** Models, not maps | 3 `Map<String,dynamic>` in-module + 8 untyped `extra`; **6 repository contracts return anonymous records**; 27 positional/dynamic casts; **0 generated models** across 9 dependency features carrying **132 hand-written parsers** | `classroom_shifts_cubit.dart` (11 casts) |

## The five things that matter most

1. **`DashboardCardErrorOverlay` renders `child` and nothing else** (`dashboard_error_chip.dart:35`). Twelve call sites believe they handle errors. None does. Every `onRetry` is dead code. Fix this before anything else — it is 36 lines and it un-hides the other four.
2. **The ratio card renders a failed attendance fetch as every classroom compliant** (`ratio_monitoring_cubit.dart:181–199, 227–228, 239–250` + `isRatioGood`'s `studentPresent == 0 → true`). It is a compliance surface, it emits `loaded`, and the corresponding attention card disappears.
3. **The "Need your attention" section vanishes when all six of its APIs fail** (`dashboard_attention_cubit.dart:185` `?? state.x` over `0` defaults + `attention_grid.dart:143` `shouldShow => count > 0`). Total failure is pixel-identical to "all clear".
4. **~41 network requests on a cold admin open**, of which at least 6 are the same endpoint fetched by different cubits (`getSchoolRegularSchedules` ×3, classroom lists ×2, staff shifts ×2, `checkStaffSignInStatus` ×2) and 7 are a per-classroom N+1 started from `build()`.
5. **`WorkBreakReminderCubit` leaks one instance per button tap** (`my_day_card.dart:2139`) — the module's only true §5.5 leak, and the only cubit anywhere in the dashboard with no owner.

Recommended order, following `docs/mandate-rules.md`'s revised **1 → 5 → 2 → 3 → 6 → 4 → 7 → 8**, with the blockers first: fix (1), (2), (3) and (5) above as defects before any mandate refactor, and delete the 665 lines of dead cards before Mandate 4 tokenises them.

---

# APPENDIX — Mandate 1 pass: deferred cross-feature destinations

Added after the Mandate 1 refactor of this module. **Scope rule applied:** the dashboard routes
only the destinations it owns. Where a push targets a screen owned by another feature, it is
deferred to that feature's own Mandate 1 pass rather than routed from here — routing them here
would put five features' routes under `/dashboard`, and six would duplicate a route that already
exists at the router root.

## Routed (dashboard-owned) — 1

| Call site | Destination | Route created |
|---|---|---|
| `widgets/qr_scan_button.dart:17` | `QrScanScreen` | `DashboardRoutes.qrScanner` = `/dashboard/qr-scanner`, registered as a **child of `/dashboard`** so it keeps the shell branch navigator (the bottom bar stayed visible under the `Navigator.push` it replaces), with `MaterialPage(fullscreenDialog: true)` to preserve the bottom-up transition and the × leading icon. |

## Deferred — 12

**The blocking conflict is the same for all of them.** `Navigator.of(context).push` from a
dashboard card resolves to the **shell branch navigator**, so the bottom nav bar stayed visible.
Every pre-existing alternative route is registered at the **router root**, which covers it.
Switching to those routes changes what the user sees, so GUARDRAIL 6 applies: *stop and explain
the conflict, do not guess.* The owning feature must decide whether to move its route in-shell or
accept the chrome change.

| # | Call site | Destination | Owner | Existing route? |
|---|---|---|---|---|
| 1 | `widgets/my_day_card.dart:528` | `StaffTransferForm` | **attendance** | `/attendance/staff-transfer` — ROOT-level |
| 2 | `widgets/my_day_card.dart:575` | `StaffMarkAbsentForm` | **attendance** | `/attendance/staff-mark-absent` — ROOT-level |
| 3 | `widgets/my_day_card.dart:608` | `StaffSignInForm(forceSelf: true)` | **attendance** | `/attendance/staff-sign-in` and `/dashboard/staff-sign-in-form` — both ROOT-level, **neither accepts `forceSelf`** as this call site needs |
| 4 | `widgets/my_day_card.dart:638` | `StaffSignOutForm` | **attendance** | `/attendance/staff-sign-out` — ROOT-level |
| 5 | `widgets/my_day_card.dart:1909` | `ConversationThreadScreen` | **communication** | **none** |
| 6 | `widgets/my_childs_day_card.dart:907` | `StudentSignOutForm` | **attendance** | **none** |
| 7 | `widgets/my_childs_day_card.dart:947` | `StudentSignInForm` | **attendance** | **none** |
| 8 | `widgets/my_childs_day_card.dart:1667` | `ConversationThreadScreen` | **communication** | **none** |
| 9 | `widgets/my_shifts_card.dart:120` | `ViewShiftScreen` — returns `bool` | **scheduling** | **none** |
| 10 | `widgets/student_billing_card.dart:40` | `PayNowAmountScreen` — returns `bool` | **billing** | `/pay-now-amount` — ROOT-level |
| 11 | `widgets/student_newsletters_card.dart:179` | `PreviewNewsletterScreen` | **newsletter** | only `/newsletter-preview-by-code`, ROOT-level, a notification variant that **self-loads by code and takes no `initialNewsletter`** — using it blanks the preview while it refetches |
| 12 | `view/QR_Code_scanner.dart:168` | 4 selection/staff forms (`pushReplacement`) | **attendance** | `/attendance/student-selection-*` etc. — ROOT-level, **none accepts `qrToken`/`isQrScan`** |

**Result handling to preserve when these are picked up** (§1.2): #9 and #10 return `bool` that
drives a reload / ledger refresh; #6 and #7 pass a `refreshCallback` the form fires on success
*before* popping.

## Exempt (§1.2 — modals)

| Site | Why |
|---|---|
| `widgets/my_shifts_card.dart:327` | `showDialog<Map<String, dynamic>>` |
| `widgets/movements_card.dart:300,313` | `Navigator.of(ctx).pop()` inside `showDialog` |

## Done in this pass against routes that already exist

Not new routes — call sites switched to the existing constant with typed args (§1's *"Route
arguments are typed… no `Object?`, no `dynamic`, no untyped casts at the receiving end"*):

| Call site | Existing route | Typed args class |
|---|---|---|
| `ratio_monitoring_card.dart:347,369` | student/staff attendance tabbed views | `AttendanceTabbedViewArgs` |
| `enrollment_card.dart:183,233,289` | student/staff attendance tabbed views | `AttendanceStatusFilterArgs` |
| `student_attendance_card.dart:75` | `student-attendance-profile` | `StudentAttendanceProfileArgs` |
| `my_attendance_card.dart:91` | `staff-attendance-profile` | `StaffAttendanceProfileArgs` |
| `my_childs_day_card.dart:877` and `QR_Code_scanner.dart:135` | `student-sign-in-out-selection` | `ChildSignInOutSelectionArgs` |
| `admin_dashboard.dart:145` | `/activityFeed` | `IncidentFeedNonce` |

Those routes accept the typed class **alongside** the legacy `Map<String, dynamic>`, because each
has 9–11 callers across other features and only the dashboard's has been migrated. The map branch
retires when the last caller moves.
