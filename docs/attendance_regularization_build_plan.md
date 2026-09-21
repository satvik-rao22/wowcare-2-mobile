# Attendance Regularization — Frontend Build Plan

| | |
|---|---|
| **Goal** | Ship the complete regularization frontend without waiting for BE. One flag flips it live. |
| **Contract** | [`attendance_regularization_requirements.md`](./attendance_regularization_requirements.md) — **revision 3** (approval columns renamed, `CANCELLED` dropped, edit-while-pending added) |
| **Flow map** | [`attendance_regularization_flow.md`](./attendance_regularization_flow.md) — needs a C12 rewrite (§9 below) |
| **Module** | `lib/modules/attendance_regularization/` |
| **Build order** | **domain → data → presentation** (3 phases) |
| **Status** | Domain + data + presentation **complete** · 146 tests passing · wired into the app behind `RegConfig.source = mock` |

---

## §1 · What revision 3 changes

### 1.1 The two behavioural changes

| Change | Consequence |
|---|---|
| **Cancel removed** | `RegStatus` drops to **2 values**. No cancel endpoint, no cancel usecase, no cancel button, no confirm dialog. |
| **Edit while pending** | New `PATCH /{code}` (§9.4). A wrong request is fixed in place, so the gate stays satisfied and the staff is never re-blocked by their own correction. |

> **Why edit is strictly better than cancel here.** Cancel put the day back into "gated" state — so a staff who spotted their own typo re-blocked themselves and had to re-raise. Edit keeps the `PENDING` row alive, so the gate stays satisfied while the content changes. Fewer states, fewer transitions, and the failure mode disappears rather than being handled.

### 1.2 `reason` is now mandatory on every request

Previously reason was optional when the suggested time was kept unchanged. Revision 3 §8.2
removes the "confirm" shortcut entirely, because with `suggested_sign_out_at` and
`confirmed_suggested_time` both dropped the server can no longer tell "kept the pre-filled
time" from "typed the same time deliberately".

**Client impact:** `RegResolveResult.confirmedSoftTime` is **deleted**, not renamed. The
`(optional)` / `(required)` toggle in `reg_resolve_sheet.dart:211` becomes always-required,
and `_isSoftTime` (line 89) disappears along with the two copy branches that depend on it
(lines 199, 226). Same for `RegBulkGateItem.confirmedSuggestedTime`.

### 1.3 Field renames (§13 client cleanup)

| Old (client today) | New | Where |
|---|---|---|
| `softSignOutAt` | `suggestedSignOutTime` | `MissedSignout`, `RegularizationRequest` |
| `signInAt` | `signedInAt` | `MissedSignout` |
| `requestedSignOutAt` | `requestedSignOutTime` | `RegularizationRequest`, raise payload |
| `appliedSignOutAt` | `approvedSignOutTime` | `RegularizationRequest` |
| `decidedByName` | `approvalByName` | `RegularizationRequest` |
| `decidedAt` | `approvalAt` | `RegularizationRequest` |
| `decisionNote` | `approvalNote` | `RegularizationRequest` |
| `signOutAt` | `signOutTime` | approve payload |
| `classroomName` | `classroomCode` | `MissedSignout` (code, not name) |

### 1.4 Dropped from the model entirely

`confirmed_suggested_time` · `suggested_sign_out_at` (stored) · `raised_by_role` ·
`auto_approved` · `is_regularized` · `current_classroom_code` · soft-delete columns.

**Auto-approval becomes a derived getter,** not a field:

```dart
bool get isAutoApproved =>
    approvalByCode != null && approvalByCode == raisedByCode;   // §7.2, §8.2b
```

### 1.5 New: last-session-per-day semantics (§4)

A staff can sign in and out **many times in one day**, so one day has several attendance rows.
Only the **last** session of a day is evaluated; a day whose last session was genuinely
signed out by a human is clear even if an earlier session that day was left open.

Mostly a backend query concern, but it hardens one client invariant:

> `open-sessions` returns **at most one item per `(staff, date)`**, and §5.1 guarantees at
> most one unresolved **day** per staff. So for a single staff the answer is **0 or 1 items** —
> never a list to page through.

**Design consequence:** the repository exposes `getOpenSession(staffCode) → MissedSignout?`,
not `→ List<MissedSignout>`. The datasource still parses the JSON array (that is the wire
shape), but the domain surface tells the truth about the cardinality. Every caller — gate,
dashboard, staff list — then handles one nullable object instead of each re-deciding what a
2-element list would mean.

### 1.6 New: `pendingRequestCode` (§9.1)

Returned when `hasPendingRequest = true`, so the client can go straight to **edit** instead
of attempting a duplicate create. This is what makes §1.1's edit path reachable from the
gate sheet and the dashboard banner.

---

## §2 · Keeping coupling low — the two mechanisms

Unchanged from the previous plan; revision 3 does not affect either.

### 2.1 Dependency direction is one-way

```
        host app ──────────────► regularization.dart  (the ONLY import, 6 members)
                                        │
   ApiClient · RoleCubit · CoreUtils ◄──┘  (module consumes host infra)
   Av2Colors/Spacing/Text/DateFormatter/TimeZone ◄──┘  (shared design system)
```

The module depends on host infrastructure. The host depends on the module **only** through
`regularization.dart`. Nothing in `lib/presentation/` or `lib/data/` ever imports a
regularization internal.

> **Accepted, deliberate dependency:** the module uses `attendance_v2`'s theme and utils
> (`Av2Colors`, `Av2Spacing`, `Av2Text`, `Av2DateFormatter`, `Av2TimeZone`, `Av2Avatar`,
> `Av2EmptyState`). That is a shared design-system dependency, not feature coupling — the two
> modules render the same attendance surfaces and must look identical. Duplicating the tokens
> would guarantee visual drift. Calling it out so it stays a decision rather than an accident.

### 2.2 Sign-in interception: a Dio interceptor, not 11 edits

Sign-in reaches the network from **12 paths** — 11 `StaffSignInForm` construction sites plus
kiosk v2 — all landing on just **three URLs**:

```
POST /api/v1/staff-attendance-records/sign-in            ← admin / bulk
POST /api/v1/staff-attendance-records/sign-in/self       ← staff self, QR, kiosk-via-form
POST /api/v1/attendance/staff-attendance-records/sign-in ← kiosk v2
```

| Approach | Sites touched | Boilerplate | Covers kiosk v2 |
|---|---|---|---|
| In the forms | 11 | low | no |
| Repository decorators | 0 | **50 method forwards** (`AttendanceRepository` has 46, kiosk 4) | yes |
| **Dio interceptor on the 3 URLs** | **0** | **none** | yes |

**Interceptor wins.** It also puts the §9.1 pre-check and the §8.3 `409` backstop in one
class (`onRequest` / `onError`) instead of two mechanisms that drift apart.

Anti-magic guards: it matches three URL suffixes and passes everything else straight through;
all logic lives in an injectable `RegGateCoordinator` testable with no Dio and no widgets; and
showing UI from outside the widget tree is **already** how this codebase handles session
expiry (`session_expired_coordinator.dart:33`), school switching
(`active_school_switcher.dart:99`) and geofence prompts — all via `CoreUtils.rootNavigatorKey`.

### 2.3 Footprint outside the module: 4 lines

| File | Line |
|---|---|
| `lib/app/di/di.dart` (beside 608) | `Regularization.register(serviceLocator);` |
| `lib/src/app_router.dart` | `...Regularization.routes(),` |
| `dashboard/view/staff_dashboard.dart` | `Regularization.dashboardEntry(),` |
| `dashboard/view/admin_dashboard.dart` | `Regularization.dashboardEntry(),` |

The 11 sign-in sites and kiosk v2 change by **zero lines**. A 12th entry point added later
inherits the gate automatically.

---

## §3 · Entities (domain models) — 6 files

### 3.1 `missed_signout.dart` — rewrite

Maps §9.1 / §9.1b. One object = one `(staff, date)` day's last session.

| Field | Type | Source | Note |
|---|---|---|---|
| `attendanceCode` | `String` | §9.1 | FK to `staff_attendance_record.code` — ✅ already correct |
| `attendanceDate` | `DateTime` | §9.1 | school-local calendar date |
| `signedInAt` | `DateTime?` | §9.1 | **rename** from `signInAt` |
| `signedInByCode` | `String?` | §9.1 | **new** |
| `suggestedSignOutTime` | `DateTime?` | §9.1 | **rename** from `softSignOutAt`, now nullable |
| `classroomCode` | `String?` | §9.1 | **replaces** `classroomName` |
| `hasPendingRequest` | `bool` | §9.1 | **new** — gate must not re-block (§8.3) |
| `pendingRequestCode` | `String?` | §9.1 | **new** — routes to edit instead of create (§1.6) |
| `staffCode` | `String` | §9.1b | ✅ already present, for the bulk sheet |
| `staffName` | `String` | §9.1b | ✅ already present |
| `initials` | getter | — | ✅ already present |

### 3.2 `regularization_request.dart` — rewrite

```dart
enum RegStatus { pending, approved }   // ⬅ `cancelled` deleted (§6)
```

| Field | Type | Note |
|---|---|---|
| `code` | `String` | `SREG_…` |
| `staffCode` / `staffName` | `String` | name resolved read-time (§7.5) |
| `attendanceCode` | `String` | **new** — needed to edit/approve |
| `attendanceDate` | `DateTime` | |
| `requestedSignOutTime` | `DateTime` | **rename**, now non-null (§7.2) |
| `reason` | `String` | non-null, non-blank (§8.2) |
| `status` | `RegStatus` | 2 values |
| `approvedSignOutTime` | `DateTime?` | **rename** from `appliedSignOutAt` |
| `approvalByCode` | `String?` | **new** — needed for `isAutoApproved` |
| `approvalByName` | `String?` | **rename** from `decidedByName` |
| `approvalAt` | `DateTime?` | **rename** |
| `approvalNote` | `String?` | **rename** from `decisionNote` |
| `raisedByCode` | `String` | **new** — the other half of `isAutoApproved` |
| `createdAt` / `updatedAt` | `DateTime` / `DateTime?` | `updatedAt` proves an edit happened (§9.4) |
| `isAutoApproved` | getter | `approvalByCode == raisedByCode` (§1.4) |
| `isEditable` | getter | `status == pending` (§8.6) |
| `wasModified` | getter | `approvedSignOutTime != requestedSignOutTime` |
| `initials` | getter | ✅ keep |

> `classroomName` drops off the request entirely — §7.5 removed `current_classroom_code` from
> the table, and the tile only ever used it as decoration.

### 3.3 Four small value objects

| File | Shape | Used by |
|---|---|---|
| `reg_raise_input.dart` | `{ staffCode, attendanceCode, attendanceDate, signOutLocal, reason }` | §9.2 + §9.2b — **no** `confirmedSuggestedTime` |
| `reg_edit_input.dart` | `{ code, signOutLocal?, reason? }` — at least one set | §9.4 |
| `reg_batch_gate.dart` | `{ List<MissedSignout> blocked, List<String> clear }` | §9.1b |
| `reg_batch_result.dart` | `{ int count, List<RegSkipped> skipped }`, `RegSkipped { key, reason }` | §9.2b + §9.7 — same shape, one type |

---

## §4 · DTOs and mappers

### 4.1 `data/dto/` — 5 files

| DTO | Wire source | Notes |
|---|---|---|
| `MissedSignoutDto` | §9.1 item, §9.1b `blocked` item | one DTO covers both — §9.1b just adds `staffCode`/`staffName` |
| `RegularizationRequestDto` | §7.2 row | |
| `BatchGateDto` | §9.1b `data` | `{ blocked[], clear[] }` |
| `BatchResultDto` | §9.2b + §9.7 `data` | `applied`/`approved` both read into `count` |
| `RegPageDto` | §9.3 / §9.5 | `{ items, page, size, total, hasMore }` |

### 4.2 `data/mappers/reg_mappers.dart` — one file, pure functions

| Function | Signature |
|---|---|
| `toMissedSignout` | `MissedSignoutDto → MissedSignout` |
| `toRequest` | `RegularizationRequestDto → RegularizationRequest` |
| `toBatchGate` | `BatchGateDto → RegBatchGate` |
| `toBatchResult` | `BatchResultDto → RegBatchResult` |
| `toPage` | `RegPageDto → RegPage<RegularizationRequest>` |
| `raiseBody` | `RegRaiseInput + zone → Map` (§9.2) |
| `raiseBatchBody` | `List<RegRaiseInput> + sharedReason + zone → Map` (§9.2b) |
| `editBody` | `RegEditInput + zone → Map` (§9.4) |
| `approveBody` | `DateTime? + note + zone → Map` (§9.6) |

Private helpers: `_utc(String?)`, `_status(String)` (2 values — an unknown string throws
loudly rather than silently defaulting), `_unwrapList(dynamic)` tolerating both
`data.content` and flat `data`.

> **Why body-builders live in the mapper, not the datasource.** Every payload needs
> wall-clock → UTC via `Av2TimeZone.toUtcIso` plus the `timeZone` key (§10.1). Putting that in
> one file means the timezone rule is written once and testable without HTTP. The datasource
> stays a dumb transport.

---

## §5 · Repository — 9 functions

`domain/repositories/regularization_repository.dart`

| # | Function | Endpoint | Spec |
|---|---|---|---|
| 1 | `Future<MissedSignout?> getOpenSession(String staffCode)` | `GET /open-sessions` | §9.1 — **nullable, not a list** (§1.5) |
| 2 | `Future<RegBatchGate> getOpenSessionsBatch(List<String> staffCodes)` | `POST /open-sessions/batch` | §9.1b |
| 3 | `Future<RegularizationRequest> raise(RegRaiseInput input)` | `POST /` | §9.2 |
| 4 | `Future<RegBatchResult> raiseBatch(List<RegRaiseInput> items, String sharedReason)` | `POST /raise-batch` | §9.2b |
| 5 | `Future<RegularizationRequest> edit(RegEditInput input)` | `PATCH /{code}` | §9.4 — **replaces cancel** |
| 6 | `Future<RegPage<RegularizationRequest>> getMyRequests({staffCode, status?, page, sort})` | `GET /?staffCode=` | §9.3 |
| 7 | `Future<RegPage<RegularizationRequest>> getSchoolRequests({schoolCode, status?, page, sort})` | `GET /?schoolCode=` | §9.5 — **history, not just pending** (§5.1) |
| 8 | `Future<RegularizationRequest> approve(String code, {DateTime? signOutLocal, String note})` | `POST /{code}/approve` | §9.6 |
| 9 | `Future<RegBatchResult> approveSelected(List<String> codes)` | `POST /approve-selected` | §9.7 |

`RegularizationRepositoryImpl` owns exactly two things the datasource must not:
`SchoolTimezoneResolver.resolveForCurrentSchool()` and the `Av2TimeZone` conversion (via the
mapper's body-builders). Nothing else.

### 5.1 The admin list is a history, not a pending-only inbox

§9.3 and §9.5 are **the same endpoint** — `GET /staff-attendance-regularizations` — differing
only in the scope param (`staffCode` vs `schoolCode`). `status` is a **filter**, written in §9.3
as `status={PENDING|APPROVED}`. So `schoolCode` + **no** `status` returns every request for the
school, paginated. **No new endpoint is needed.**

Two functions rather than one, because the type signature is where the authorization boundary
belongs: staff code paths cannot accidentally query by `schoolCode`.

**The sort orders are opposite, and that is not cosmetic.** §9.5 specifies `sort=createdAt,asc`
— oldest first, which is right for a work queue (act on the longest-waiting request). A history
view needs `createdAt,desc` — newest first. One fixed sort cannot serve both, so `sort` is a
parameter, not a constant:

```dart
// declared in domain/repositories/regularization_repository.dart
enum RegSortOrder { oldestFirst, newestFirst }   // → createdAt,asc | createdAt,desc
```

| View | `status` | `sort` |
|---|---|---|
| Admin · Pending (default tab) | `PENDING` | `oldestFirst` |
| Admin · Approved | `APPROVED` | `newestFirst` |
| Admin · All | `null` | `newestFirst` |
| Staff · my requests | `null` | `newestFirst` |
| Dashboard badge | `PENDING` | either — reads `total` from a `size: 1` page |

> The badge **must** keep `status: PENDING`. Counting the history would show a number that only
> ever grows and means nothing.

---

## §6 · Usecases — 9, one per repository function

`domain/usecases/` — each a single-method `call(...)` class, matching `attendance_v2`'s pattern.

| Usecase | Called from |
|---|---|
| `GetOpenSession` | gate coordinator, dashboard, staff list |
| `GetOpenSessionsBatch` | gate coordinator (bulk) |
| `RaiseRegularization` | gate coordinator, staff list |
| `RaiseRegularizationBatch` | gate coordinator (bulk) |
| **`EditRegularization`** | staff list, dashboard banner, admin inbox |
| `GetMyRequests` | staff list |
| `GetSchoolRequests` | admin list (all 3 tabs), dashboard badge |
| `ApproveRequest` | admin inbox |
| `ApproveSelected` | admin inbox |

**No `CancelRequest`.** It was in the previous plan; revision 3 deletes it.

---

## §7 · Data sources — the backend-independence seam

`data/datasources/reg_remote_datasource.dart` is **abstract** with 9 methods mirroring §5.
Two implementations, chosen by one flag:

| Impl | Purpose |
|---|---|
| `reg_http_datasource.dart` | real Dio via `sl<ApiClient>().client` — inherits auth + org/school interceptors, same as `StaffOvertimeRemoteDataSource` |
| `reg_fake_datasource.dart` | **stateful in-memory server** — the whole reason 95% ships without backend |

The fake is not fixtures. It holds `_openRows` (seeded open / SYSTEM-closed past days) and
`_requests` (the regularization table), generates `SREG_0001…`, and has `latency`,
`failNext` and `actingRole` knobs so loading and error states can be built against the real UI.

Rules it enforces, each one a test:

| Rule | Behaviour |
|---|---|
| §9.1 detection | open **or** `SYSTEM`, past days only, **last session per day** |
| §9.1 `hasPendingRequest` / `pendingRequestCode` | set once raised |
| §8.2 | staff raise → `PENDING`, **reason required (trimmed)** |
| §8.2b | admin raise → `APPROVED`, `approvalByCode == raisedByCode`, row cleared |
| §8.5 | after `signedInAt`, before the 19:00 cap — on raise, **edit**, and modified approve |
| §8.6 | idempotent raise returns existing PENDING; idempotent approve |
| §8.6 | **edit on APPROVED → 409** |
| §8.3 | throws `DioException` 409 `REGULARIZATION_REQUIRED` |
| §9.2b / §9.7 | `{count, skipped[]}` |

> The fake stays after cutover as the offline dev harness and as the executable form of the spec.

---

## §8 · Presentation — coordinator, cubits, screens

### 8.1 `presentation/gate/reg_gate_coordinator.dart` — the brain

Every gate decision lives here. The interceptor calls it; the dashboard calls it; nothing else needs to.

| Function | Purpose |
|---|---|
| `Future<RegGateOutcome> guardSingle(String staffCode, {required bool byAdmin, String? staffName})` | the single-staff gate |
| `Future<RegBulkGateOutcome> guardBulk(List<String> staffCodes)` | returns who may now sign in |
| `Future<bool> handleConflict(DioException e)` | §8.3 `409` backstop → `true` = retry |
| `Future<MissedSignout?> peek(String staffCode)` | check only, **never shows UI** — for the dashboard |
| `Future<bool> resolve(MissedSignout item, {required bool byAdmin, bool mandatory})` | open the sheet for a known day; **auto-selects create vs edit** from `pendingRequestCode` |

`RegGateOutcome { proceed, blocked }` · `RegBulkGateOutcome { List<String> allowed, int cleared, int skipped }`

### 8.2 Cubits — 3

| Cubit | Feeds | Methods |
|---|---|---|
| `RegMyRequestsCubit` | `RegStaffListScreen` | `load` · `loadMore` · `refresh` · **`edit(code, time, reason)`** · `resolveGate` |
| `RegInboxCubit` | `RegAdminInboxScreen` | `load` · `loadMore` · `refresh` · **`setFilter(RegInboxFilter)`** · `approve(code, {time, note})` · `toggleSelect` · `approveSelected` |
| `RegDashboardCubit` | `dashboardEntry()` | `load` · `refresh` — state carries `openSession` (staff) **and** `pendingCount` (admin) |

Each state: `initial · loading · loaded(…) · error(message)`, errors via
`ApiErrorHandler.extractErrorMessage`.

`RegInboxCubit.approveSelected()` handles §9.7 partials: drop the approved codes, **keep** the
skipped ones with a message naming how many and why.

`RegDashboardCubit` is one cubit rather than two because `dashboardEntry()` is itself
role-aware — one `BlocProvider`, one lifecycle, and the two reads never both run.

**`setFilter` resets pagination.** Switching tab changes both `status` and `sort` (§5.1), so
the loaded page is not a prefix of the new result set — it must refetch from `page: 0` and
clear `_selected`, not append. Keeping the old page visible while the new one loads would show
rows in the wrong order under the wrong heading.

**`approve` behaves differently per tab.** On **Pending** the approved row is removed (it left
the queue). On **Approved** / **All** it must **stay and re-render as Approved** — removing it
would make a history view lie about its own contents. One line in the cubit, but getting it
backwards is the kind of bug that only shows up in the tab nobody demoed.

### 8.3 Screens and sheets — what we actually build

| File | Status | Work |
|---|---|---|
| `reg_staff_list_screen.dart` | **modify** | add `.connected()`; **remove cancel**; add **Edit** on pending rows; pagination, pull-to-refresh, loading/empty/error |
| `reg_admin_inbox_screen.dart` | **modify** | add `.connected()`; pagination, refresh; wire approve + approve-selected; admin gate via `RoleCubit`; **filter chips + mixed-status list (§8.4)** |
| `reg_resolve_sheet.dart` | **modify** | **add `mode: create \| edit`**; reason always required; delete `confirmedSoftTime` + `_isSoftTime` |
| `reg_decision_sheet.dart` | **modify** | rename `signOutAt` → `signOutTime`; field renames; **add read-only mode for APPROVED (§8.4)** |
| **`reg_inbox_filter.dart`** | **new** | `enum RegInboxFilter { pending, approved, all }` + `label` / `status` / `sort` getters |
| `reg_bulk_signin_gate_sheet.dart` | **modify** | drop `confirmedSuggestedTime` from `RegBulkGateItem`; reason always required |
| `reg_request_tile.dart` | **modify** | `requestedSignOutAt` → `requestedSignOutTime`; add edit affordance |
| `reg_status_pill.dart` | **modify** | remove the `cancelled` case |
| `reg_admin_notification_tile.dart` | **modify** | field renames |
| `reg_staff_time_row.dart` | keep | field renames only |
| `reg_scaffold.dart` | keep | — |
| **`reg_dashboard_entry.dart`** | **new** | role-aware banner + approval card + badge + auto-appear |
| **`reg_routes.dart`** | **new** | 2 `GoRoute`s |

> **No new sheet for edit.** `reg_resolve_sheet` already has exactly the two fields §9.4 takes
> (time + reason). A `mode` flag swaps the copy — *"Finish yesterday first" / "Confirm & submit"*
> becomes *"Update your request" / "Save changes"* — and pre-fills from the existing request.
> One sheet means the §8.5 window validation is written once and cannot drift between the
> create and edit paths. A second sheet would be ~300 duplicated lines and two places to fix
> every future copy change.

### 8.4 Admin list — what a mixed-status list breaks

The screen today filters to pending and renders only those
(`reg_admin_inbox_screen.dart:29`, `:50`). Showing history alongside pending breaks four
things. All four are small, but all four are silent if missed.

| # | Break | Fix |
|---|---|---|
| 1 | **Checkboxes on approved rows** — an admin could select an already-approved request and "approve" it again | The tile already solves this: it renders a checkbox **only when `onSelectChanged != null`** (`reg_admin_notification_tile.dart:49`). Pass `null` for non-pending rows. **No tile change needed.** |
| 2 | **`_toggleAll` over the whole list** (`:36`) — "Select all" would tick approved rows | Iterate the *pending subset of the loaded page*, not `widget.requests` |
| 3 | **Header count** `'${pending.length} pending'` (`:96`) — would count history | Count the pending subset; on non-pending tabs show `'N requests'` instead |
| 4 | **`reg_decision_sheet` has an unconditional Approve button** (`:140`) | Tapping an approved row today offers to re-approve it. §8.6 makes that idempotent server-side, so it is harmless but wrong — it fires a pointless write and implies the record is still mutable. Add a read-only mode showing **requested vs approved** time, approver name, and note. |

> **Break 4 is the one worth care.** It is the only place in the module where the UI would let
> someone act on a terminal record. `RegularizationRequest.isEditable` (§3.2) already exists to
> express it — the sheet just has to read it.

Empty state also becomes per-tab: `'No pending requests'` is wrong under an Approved tab with
no history yet.

### 8.5 `reg_dashboard_entry.dart` — the auto-appear widget

One widget, dropped once into each dashboard. Reads `RoleCubit` to decide:

- **staff** → unresolved-day banner (hidden when clear); tap opens the sheet
- **admin** → "needs your approval" card + count badge (hidden at zero); tap opens the inbox

On `initState` it calls `RegGateCoordinator.peek(myStaffCode)`. If a day comes back **and**
`hasPendingRequest == false`, it opens the resolve sheet **once per app session**, guarded by
a `_shownThisSession` flag so it does not re-fire on rebuilds or tab switches. When
`hasPendingRequest == true` it renders an "awaiting approval — Edit" banner and shows no sheet.

### 8.6 `regularization.dart` — the one public file

```dart
abstract final class Regularization {
  static void register(GetIt sl);              // DI + interceptor install
  static List<RouteBase> routes();
  static Widget dashboardEntry();
  static void openMyRequests(BuildContext c);
  static void openAdminInbox(BuildContext c);
  static bool handleNotification(String action, Map<String, dynamic> data);

  static const String myRequestsRoute = '/regularization/my-requests';
  static const String adminInboxRoute = '/regularization/inbox';
}
```

---

## §9 · Flows

### 9.1 Staff taps Sign in

```
my_day_card._openSignInForm()  →  StaffSignInForm._submit()          ← both unchanged
  → AttendanceRepository.submitStaffSignIn()                          ← unchanged
    → POST /staff-attendance-records/sign-in/self
      ⇣ RegSignInGateInterceptor.onRequest — URL matches
        RegGateCoordinator.guardSingle(staffCode, byAdmin: false)
          GET /open-sessions?staffCode=…
          ├─ null ....................... proceed
          ├─ hasPendingRequest: true .... proceed  (§8.3 — request exists, never re-block)
          └─ unresolved day
               showRegResolveSheet(mode: create, mandatory: true)
                 ├─ submitted → POST /  (role STAFF → PENDING)
                 │              toast "Sent for approval"
                 │              proceed → original sign-in continues
                 └─ dismissed → handler.reject → form shows "Sign-in cancelled"
```

### 9.2 Admin signs in one staff

Same path, `byAdmin: true` (derived from the URL being `/sign-in`, not `/sign-in/self`).
Admin copy, server auto-approves (§8.2b), toast says **"Applied"** — read from the response
`status`, never guessed client-side.

### 9.3 Admin bulk sign-in

```
StaffSignInForm(staffList: […50]) → POST /sign-in { staffCodes: [50] }
  ⇣ interceptor: codes.length > 1 → guardBulk
    POST /open-sessions/batch { staffCodes: [50] }
      → { blocked: [10, with staffName + suggested time], clear: [40] }

    showRegBulkSignInGateSheet(blocked: 10, otherCount: 40)   ← built & tested
      ├─ "Close all 10 & sign them in" → POST /raise-batch (auto-approved)  → allowed = 50
      ├─ rows corrected first, shared reason required        → same call
      └─ "Skip — sign in the other 40"                       → allowed = 40

    options.data.staffCodes = allowed      ← payload rewritten in place
    → ONE sign-in call for exactly the staff who may proceed
```

**Partial success falls out of the design** — the 40 are never held up by the 10, because the
interceptor narrows the payload rather than failing the request.

### 9.4 Edit a pending request — the new flow (replaces cancel)

Reachable from three places, all going through the same coordinator call:

```
staff list "Edit" on a PENDING row
dashboard "awaiting approval — Edit" banner        ─┐
admin inbox (admin editing for their school)        │
                                                    ▼
   RegGateCoordinator.resolve(item)  or  RegMyRequestsCubit.edit(...)
     pendingRequestCode != null → showRegResolveSheet(mode: edit, prefilled)
       → PATCH /{code} { requestedSignOutTime?, reason?, timeZone }
         ├─ 200 → list refreshes, status stays PENDING, gate stays satisfied
         └─ 409 → "This request was already approved" + refresh (§8.6, §10.3)
```

The `409` branch matters: an edit that races an approval loses, and the user must be told
why their change vanished rather than seeing a silent no-op.

### 9.5 Dashboard open — auto-appear

```
StaffDashboard / AdminDashboard build
  → Regularization.dashboardEntry()                 ← the one added line
      RegDashboardCubit.load() → coordinator.peek(staffCode)
        ├─ null ....................... render nothing
        ├─ hasPendingRequest: true .... "awaiting approval — Edit" banner, no sheet
        └─ unresolved ................. banner + auto-open resolve sheet (once per session)
      admin also → GetSchoolRequests(status: PENDING, page:0, size:1) → total>0 ? card + badge : nothing
```

---

## §10 · Phases

| Phase | Weight | Cum. | Needs BE? |
|---|---|---|---|
| 0 · Contract lock — entities, renames, delete cancel | 10% | 10% | no |
| 1 · DTOs + mappers + datasource seam + **fake** | 19% | 29% | no |
| 2 · Repository + 9 usecases | 10% | 39% | no |
| 3 · DI + interceptor install + facade | 12% | 51% | no |
| 4 · Gate coordinator + flows 9.1–9.3 | 18% | 69% | no |
| 5 · Cubits + screens + **edit flow 9.4** + **admin history tabs** | 19% | 88% | no |
| 6 · Dashboard entry + routes + deep link | 7% | 95% | no |
| 7 · Live cutover + verification | 5% | 100% | **yes** |

**95% ships without backend.** Phase 4's exit is the proof: on the fake, sign-in is genuinely
blocked in the real app, the sheet raises, and the sign-in retries and succeeds.

### Phase 0 detail (start here)

- `RegStatus` → 2 values; delete `cancelled` from `reg_status_pill.dart:25` and the fixture at
  `regularization_fixtures.dart:103`
- Rewrite both entities per §3
- Delete `confirmedSoftTime` / `_isSoftTime` from `reg_resolve_sheet.dart`; reason always required
- Drop `confirmedSuggestedTime` from `RegBulkGateItem`
- Apply the §1.3 renames across all 10 widgets + fixtures + dev app
- Add `core/config/reg_config.dart` (`RegSource`, page sizes, 19:00 cap, `method: 'APP'`)
- **10/10 tests green again** — two assertions need updating (`'Cancelled'` and the
  optional-reason case)

### Progress

Regrouped into the three-layer build order actually being followed. Weights are
unchanged in total; the old Phase 0 (contract lock) landed inside the domain phase because
rewriting the entities required propagating the renames to keep the build green.

| Phase | Weight | Status | Done |
|---|---|---|---|
| **A · Domain** — entities, policy, repo interface, 9 usecases, rename propagation | **20%** | ✅ Complete | 100% |
| **B · Data** — paths, mappers, datasource seam, HTTP + mock, repo impl, timezone | **29%** | ✅ Complete | 100% |
| **C · Presentation** — DI, interceptor, gate, 3 cubits, screens, entry, facade | **46%** | ✅ Complete | 100% |
| D · Live cutover | 5% | Not started | 0% |
| **Total** | **100%** | | **95%** |

### Phase C — what landed

| File | |
|---|---|
| `presentation/gate/reg_sign_in_gate.dart` | **new** — the 3-method contract the interceptor depends on |
| `presentation/gate/reg_gate_coordinator.dart` | **new** — every gate decision; `peek` / `guardSingle` / `guardBulk` / `resolve` / `handleConflict` |
| `presentation/gate/reg_gate_outcome.dart` | **new** — `RegGateOutcome`, `RegBulkGateOutcome` |
| `data/interceptor/reg_sign_in_gate_interceptor.dart` | **new** — gates all 12 sign-in paths at the network boundary |
| `presentation/cubit/reg_my_requests_cubit.dart` + state | **new** — list, pagination, gate banner, edit |
| `presentation/cubit/reg_inbox_cubit.dart` + state | **new** — tabs, pagination, approve, multi-select, skipped reconciliation |
| `presentation/cubit/reg_dashboard_cubit.dart` | **new** — banner state + badge count + once-per-session auto-open |
| `presentation/controllers/reg_inbox_filter.dart` | **new** — status + sort per tab |
| `presentation/widgets/reg_filter_chips.dart` | **new** |
| `presentation/entry/reg_dashboard_entry.dart` | **new** — role-aware banner / card / badge |
| `di/regularization_di.dart` | **new** — the only reader of `RegConfig.source`; installs the interceptor |
| `regularization.dart` | **new** — the facade, 6 members |
| `reg_resolve_sheet.dart` | `mode: create \| edit` (§9.4 reuses the same sheet) |
| both screens | `.connected()` factories; presentation-only constructors kept for tests |
| `reg_request_tile.dart` | `busy` + edit affordance |
| 4 host files | 20 lines total |

**Three fixes made while building, beyond the plan:**

1. **`load()` was wiping its own outcome message.** `edit` reported "Request updated" (or the
   409 text) and then reloaded, and `load()` cleared `message` — so the user's confirmation, or
   the news that their edit lost to an approval, vanished. Both cubits now take
   `load(keepMessage: true)`.
2. **The mock now auto-seeds unknown staff codes.** It seeded `STF_ME`, but in the real app
   `RegContext.staffCode()` returns whatever is in storage — so the gate would never have fired
   when you actually ran it, which defeats the point of having a mock. Any staff code queried
   for the first time gets an unresolved yesterday; `autoSeedUnknownStaff: false` opts out in
   tests that assert on an exact row set.
3. **`RegSignInGate` extracted.** The interceptor was typed to the whole coordinator. Narrowing
   it to a 3-method contract states exactly what the network layer may ask of the gate, and
   makes the interceptor unit-testable with no navigator, no sheet and no datasource.

### Phase A — what landed

| File | |
|---|---|
| `domain/policy/reg_time_policy.dart` | **new** — §8.2 reason + §8.5 window in one place, shared by sheets, fake and repo |
| `domain/entities/missed_signout.dart` | rewritten — `hasPendingRequest`, `pendingRequestCode`, `signedInByCode`, `classroomCode`, renames; `suggestedOrCap`, `resolvesByEdit`, `blocksSignIn` |
| `domain/entities/regularization_request.dart` | rewritten — `RegStatus` at 2 values, `regStatusFromWire` throws on unknown, 6 approval renames, `isAutoApproved` / `isEditable` / `wasModified` / `wasEdited` / `effectiveSignOutTime` |
| `domain/entities/reg_raise_input.dart` | **new** — `.forGate()`, `validate()` |
| `domain/entities/reg_edit_input.dart` | **new** — replaces cancel; `hasChange`, `validate()` |
| `domain/entities/reg_batch_gate.dart` | **new** — `blocked` / `clear` split |
| `domain/entities/reg_batch_result.dart` | **new** — one type for §9.2b + §9.7; `skippedKeys`, `summary` |
| `domain/entities/reg_page.dart` | **new** — `hasMore`, `append`, `withItems` |
| `domain/repositories/regularization_repository.dart` | **new** — 9 functions + `RegSortOrder` |
| `domain/usecases/*` | **new** — 9 files |
| `presentation/widgets/*`, `data/fixtures/*` | renames propagated; reason now always required; `confirmedSoftTime` / `confirmedSuggestedTime` deleted |
| `test/attendance_regularization/reg_domain_test.dart` | **new** — 41 pure-Dart tests |

**Two fixes made while in there, beyond the rename:**

1. `reg_decision_sheet.dart` was seeding `_outTime` from the request and always sending it
   back, which records a modification that never happened and would make `wasModified` lie.
   Now tracks `_timeChanged` and sends `signOutTime` only when the admin actually picked a new
   time — §9.6's "omit to approve as submitted".
2. `regStatusFromWire` **throws** on an unrecognised status rather than defaulting to
   `pending`. Defaulting is how a resurrected `CANCELLED` would silently render an Approve
   button on a non-pending row.

---

## §11 · Backend asks

| # | Ask | Why |
|---|---|---|
| 1 | `staffName` in the **inbox** list DTO, batched per page like `approvalByName` | The inbox renders names. §9.1b grants `staffName` for the *batch gate* but §9.5 never grants it for the *inbox*. Same batched lookup, same N+1 risk. |
| 2 | Confirm the `409 REGULARIZATION_REQUIRED` body matches §9.1 | The backstop parses it; a differing shape silently disables the fallback. |
| 3 | Confirm list responses: `data.content` or flat `data` | Mapper tolerates both — confirmation removes a guess. |
| 4 | Guard the **kiosk** URL `/api/v1/attendance/staff-attendance-records/sign-in` | A distinct path no ticket lists. Client-side covered; server-side must be too. |
| 5 | Confirm `/open-sessions/batch`, `/raise-batch` and `PATCH /{code}` are in BE scope | All three post-date the BE-2/BE-3/BE-7 tickets, which still describe single-staff endpoints and a cancel endpoint. |
| 6 | **BE-7 needs rewriting** — it specifies `POST /{code}/cancel` | Revision 3 replaces it with `PATCH /{code}`. The ticket as written builds the wrong endpoint. |
| 7 | Confirm `status` is an **optional** filter on the list endpoint, and that **`sort` is honoured** on both `createdAt,asc` and `createdAt,desc` | §5.1 — the admin history tab needs `schoolCode` with `status` omitted (= all) and `sort=createdAt,desc`. §9.5 only ever documents `status=PENDING&sort=createdAt,asc`, so "omit = all" is the natural REST reading but is **not stated**. **Not a blocker:** the fake implements it, and if the server ends up requiring `status`, the All tab drops to two tabs with no other change. |

---

## §12 · Doc debt

`attendance_regularization_flow.md` still describes the old model and needs updating alongside
Phase 0 — it is the doc QA and the backend read:

- **C12** is "Staff cancels a pending request" → must become "Staff edits a pending request"
- The lifecycle diagram still shows `CANCELLED`
- §6's API↔case map still lists `/{code}/cancel`
- §7's field table uses the old column names
- §3's C5/C6 split ("accepts the suggested time" vs "changes the time") no longer exists —
  reason is required either way
- §9's glossary still defines **Cancelled**

---

## §13 · Working agreement

- One phase per commit series; each phase ends green (`flutter analyze` + tests).
- Validate at each phase exit before starting the next.
- Nothing outside the module imports anything but `regularization.dart`. A second import means
  the facade is missing something — extend the facade, don't add the import.
- `RegConfig.source` is never read at a call site. The flag is the only switch.

---

## §14 · Phase D — real API cutover

The backend shipped, and the shipped contract differs from the spec this module was built
against (`REGULARIZATION_API_CONTRACT.md` + the Postman collection). Twelve deltas, listed
below, drive six verifiable steps.

### 14.1 Contract deltas

| # | Shipped contract | What it changes here |
|---|---|---|
| 1 | Gate merged into `POST /open-sessions/check`, `staffCodes` optional, one `{blocked, clear}` shape either way | `getOpenSession` + `getOpenSessionsBatch` collapse into one `checkGate()`. **Self-check sends no staff code at all** — the token decides. |
| 2 | **No `timeZone` in any payload** — the school's attendance config defines the working day | Drop it from raise / edit / approve / raise-batch. Still needed *locally* to render UTC as school-local. |
| 3 | `autoApproved` is a real response field | Stop deriving it from `approvalByCode == raisedByCode`. |
| 4 | `GET /` takes no `schoolCode`; the token scopes it | `getMyRequests` + `getSchoolRequests` collapse into one `getRequests({staffCode?, status?})`. |
| 5 | `approve-selected` body is `{codes}` only | `RegContext.schoolCode()` becomes unused. |
| 6 | **`POST /sign-in` returns `{signedIn, blocked}`** — the server does bulk partial success itself | The interceptor's payload-narrowing is now redundant. See 14.3. |
| 7 | Blocked single sign-in → `409`, sessions in `error.rejectedValue` (an array) | The parser currently looks for `openSessions`. |
| 8 | `PATCH` conflict code is `REGULARIZATION_ALREADY_APPROVED` | Match the code, not a bare `409`. |
| 9 | Page carries `hasNext` / `totalPages` | Use the server's flag instead of computing from `total`. |
| 10 | Kiosk must send `staffCodes`; `{}` is a `400` | The gate must never self-check from a kiosk. **`x-role` is already sent by `AuthInterceptor`** — no header work. |
| 11 | `method` also takes `KIOSK` | |
| 12 | `skipped` carries both `attendanceCode` and `code` | |

### 14.2 The mock

Deleted — but its *test* value is replaced, not dropped. The 62 data tests move to driving the
**real `RegHttpDataSource`** through a Dio `HttpClientAdapter` that replays the contract's own
JSON samples. That is strictly better now the API exists: the tests assert against the real wire
format rather than a simulation of it.

With one implementation left, `RegRemoteDataSource` (the abstract seam) also goes — it existed
only to let the mock stand in.

### 14.3 Open decision — bulk sign-in

The server now does partial success itself. Two options:

- **A · pre-check** (what is built): `check` → sheet → `raise-batch` → sign in. The sheet appears
  before anyone is signed in, so Skip genuinely skips.
- **B · response-driven**: sign in → read `blocked` from the response → sheet → `raise-batch` →
  sign in the rest. One fewer round trip, and it is the flow the new response shape was designed
  for — but the clear staff are signed in before the admin sees the sheet.

Both need the `blocked` list surfaced either way, because today `_attendanceActionResult` reads
only `success`/`message` and would report a silent success while ten people stayed out.

### 14.4 Steps

| Step | Scope | Verified by |
|---|---|---|
| **D1** | Paths, error codes, config — the contract surface | analyze clean + error-parsing tests on the contract's literal JSON |
| **D2** | Entities + mappers to the real wire shape (deltas 2, 3, 9, 12) | mapper tests against the contract's JSON samples |
| **D3** | `RegHttpDataSource` + repository down to 7 methods; delete mock + seam (deltas 1, 4, 5) | repository tests through a recorded Dio adapter |
| **D4** | Usecases 9 → 7; cubits off `schoolCode`/`staffCode` | cubit tests |
| **D5** | Gate + interceptor for the real sign-in contract (deltas 6, 7, 10) | interceptor tests |
| **D6** | Live run against the real server | walking the flows on device |
