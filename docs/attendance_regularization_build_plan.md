# Attendance Regularization — Frontend Build Plan

| | |
|---|---|
| **Goal** | Ship the complete regularization frontend without waiting for BE-1…BE-7. One flag flips it live. |
| **Contract** | [`attendance_regularization_requirements.md`](./attendance_regularization_requirements.md) — schema, payloads, rules |
| **Flow map** | [`attendance_regularization_flow.md`](./attendance_regularization_flow.md) — cases C1–C25 |
| **Module** | `lib/modules/attendance_regularization/` |
| **Branch** | `Staff_Attendance_Regularization` |
| **Baseline** | 10 widget tests passing · static UI only · no data layer, DI, cubits, routes, or gate |

---

## §1 · Re-validation — what the codebase actually looks like today

### 1.1 What changed since the last pass

| Change | Impact |
|---|---|
| **C3 added** — a scheduler `SYSTEM` close now also gates | Detection is two-branch. `hasPendingRequest` and the `SYSTEM` case must both reach the client. |
| `target_record_code` → **`attendance_code`** | Renamed everywhere. `MissedSignout.attendanceCode` already correct. |
| **§9.1b `/open-sessions/batch`** added | New endpoint. Bulk gate can't be N sequential GETs. |
| **§9.2b `/raise-batch`** added | New endpoint. **API surface is now 9 endpoints, not 7.** |
| **§5.1c bulk sign-in flow** added | Consolidated sheet + partial success. |
| `reg_bulk_signin_gate_sheet.dart` + `reg_staff_time_row.dart` built | UI for §5.1c exists and is tested (2 new tests, 10 total). |
| **Kiosk v1 deleted** | `kiosk_attendance_cubit.dart` gone, DI commented at `di.dart:2145`. Only kiosk v2 remains. |

### 1.2 Every place sign-in happens

`StaffSignInForm` is constructed from **11 sites**, all funnelling into one `_submit()`
at [`staff_sign_in_form.dart:791`](../lib/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_in_form.dart):

| # | Site | Persona | Shape |
|---|---|---|---|
| 1 | `dashboard/view/widgets/my_day_card.dart:610` | Staff self | `forceSelf: true` |
| 2 | `dashboard/view/QR_Code_scanner.dart:160` | Staff self | `qrToken` |
| 3 | `attendance/forms/.../staff_selection_sign_in_form.dart:225` | Admin bulk | `staffList` |
| 4 | `staff/view/staff_screen.dart:626` | Admin bulk | `staffList` |
| 5 | `attendance/view/staff_attendance_tabbed_view.dart:548` | Admin single | `staff` |
| 6 | `attendance/view/staff_attendance_profile.dart:975` | Admin single | `staff` |
| 7 | `attendance/widgets/attendance_popup.dart:908` | Admin single | `staff` |
| 8 | `attendance/widgets/attendance_popup.dart:1107` | Admin single | `staff` |
| 9 | `classroom/views/classroom_tab_cards/classroom_staff_tab_card.dart:715` | Admin single | `staff` |
| 10 | `src/app_router.dart:585` | route | kiosk staff sign-in |
| 11 | `src/app_router.dart:644` | route | `/dashboard/staff-sign-in-form` |

Plus **kiosk v2** — `KioskAttendanceCubitV2` (live, `main.dart:427`) → `SignInStaffUseCase` →
`KioskAttendanceRepository.signInStaff`, a **different repository** hitting a **different URL**
(`/api/v1/attendance/staff-attendance-records/sign-in` — note the extra `/attendance/`).

**Every one of these ends at one of three URLs:**

```
POST /api/v1/staff-attendance-records/sign-in           ← admin / bulk
POST /api/v1/staff-attendance-records/sign-in/self      ← staff self, QR, kiosk-via-form
POST /api/v1/attendance/staff-attendance-records/sign-in ← kiosk v2
```

### 1.3 Entity gaps still open

`MissedSignout` — `attendanceCode`, `staffCode`, `staffName` are correct. Still missing/wrong:

| Spec §9.1 | Entity | Gap |
|---|---|---|
| `hasPendingRequest` | — | **missing — and it is load-bearing** |
| `suggestedSignOutAt` | `softSignOutAt` | rename |
| `signedInAt` | `signInAt` | rename |
| `classroomCode` | `classroomName` | code ≠ name |

> **Why `hasPendingRequest` is not cosmetic.** C10 says a staff with an existing PENDING request
> may sign in. Without this field the client re-gates someone who already raised, they submit
> again, and §8.6 idempotency returns the same request — so it "works", but the person is
> forced through a sheet they already completed, every morning, until an admin approves.
> That is the difference between the feature working and the feature being hated.

`RegularizationRequest` is missing `attendanceCode`, `confirmedSuggestedTime`,
`appliedSignOutAt`, `raisedByRole`, `autoApproved`; and carries `softSignOutAt`
instead of `suggestedSignOutAt`.

`RegResolveResult.confirmedSoftTime` → `confirmedSuggestedTime` (matches the §9.2 payload key).

### 1.4 Infrastructure the plan leans on (verified present)

| Need | Exists | Where |
|---|---|---|
| Show UI from a non-widget service | ✅ **established pattern** | `CoreUtils.rootNavigatorKey` — already used by `session_expired_coordinator.dart:33`, `active_school_switcher.dart:99`, `geofence_notification_service.dart:156` |
| Dio interceptor chain | ✅ | `core/network/api_client.dart` — auth, cookie, logging already stacked |
| Wall-clock → UTC | ✅ | `Av2TimeZone.toUtcIso` |
| School IANA zone | ✅ | `SchoolTimezoneResolver.resolveForCurrentSchool` |
| Error message extraction | ✅ | `ApiErrorHandler.extractErrorMessage` |
| Role | ✅ | `RoleCubit.state.role` / `activeSchoolRoleRaw` |
| Module DI precedent | ✅ | `registerAttendanceV2(serviceLocator)` at `di.dart:608` |

---

## §2 · The centralization decision

> *"outside the regularization module we don't need to change the existing code at multiple
> places… its implementation is centralized in the module."*

### 2.1 Where to intercept sign-in

Three options were considered against the 12 call paths in §1.2.

| Option | Sites touched | Boilerplate | Covers kiosk v2 | Can be bypassed later |
|---|---|---|---|---|
| Interception in the forms *(what the FE-3 ticket suggests)* | **11** | low | ❌ no | yes — every new entry point |
| Repository decorators | 0 | **50 method forwards** (`AttendanceRepository` has 46 methods, `KioskAttendanceRepository` 4) | ✅ yes, 2 decorators | no |
| **Dio interceptor on the 3 sign-in URLs** | **0** | **none** | ✅ yes, one class | no |

**Decision: a Dio interceptor.** It is the only option that is simultaneously zero-touch,
zero-boilerplate, and complete. It also puts the §9.1 pre-check and the C25 `409` backstop in
the *same* class — `onRequest` and `onError` of one interceptor — instead of two mechanisms
that can drift apart.

The usual objection to interceptors is that they are "spooky action at a distance". Three
things defuse it here:

1. It matches on **exactly three URL suffixes** and passes everything else straight through.
2. All logic lives in a plain, injectable `RegGateCoordinator` — the interceptor is ~40 lines
   of routing. The coordinator is unit-testable with no Dio and no widgets.
3. Showing UI from outside the widget tree is **already how this codebase handles**
   session expiry, school switching, and geofence prompts (§1.4).

### 2.2 The one public file

Everything the host app touches goes through a single facade. Nothing else in the module is
imported from outside it.

```dart
// lib/modules/attendance_regularization/regularization.dart
abstract final class Regularization {
  static void register(GetIt sl);              // ① DI + interceptor install
  static List<RouteBase> routes();             // ② routes
  static Widget dashboardEntry();              // ③ role-aware dashboard widget
  static void openMyRequests(BuildContext c);  // ④ navigate
  static void openAdminInbox(BuildContext c);  // ⑤ navigate
  static bool handleNotification(String action, Map<String, dynamic> data); // ⑥ deep link

  static const String myRequestsRoute = '/regularization/my-requests';
  static const String adminInboxRoute = '/regularization/inbox';
}
```

### 2.3 Total footprint outside the module: **4 lines**

| File | Line added |
|---|---|
| `lib/app/di/di.dart` (beside line 608) | `Regularization.register(serviceLocator);` |
| `lib/src/app_router.dart` | `...Regularization.routes(),` |
| `dashboard/view/staff_dashboard.dart` | `Regularization.dashboardEntry(),` |
| `dashboard/view/admin_dashboard.dart` | `Regularization.dashboardEntry(),` |

**The 11 sign-in sites and kiosk v2 change by zero lines.** A 12th entry point added next
quarter inherits the gate automatically — bypass is structurally impossible.

*(Optional 5th line: one `case` in `notification_route_resolver.dart` delegating to
`Regularization.handleNotification`.)*

---

## §3 · Module structure

```
lib/modules/attendance_regularization/
│
├── regularization.dart ......................... ⭐ THE ONLY PUBLIC IMPORT
│
├── core/
│   ├── config/reg_config.dart .................. source flag, page size, caps
│   └── errors/reg_exceptions.dart .............. RegGateBlocked, RegConflict
│
├── data/
│   ├── datasources/
│   │   ├── reg_api_paths.dart .................. the 9 endpoints
│   │   ├── reg_remote_datasource.dart .......... abstract (the seam)
│   │   ├── reg_http_datasource.dart ............ live Dio impl
│   │   └── reg_fake_datasource.dart ............ stateful in-memory impl
│   ├── dto/ .................................... 5 DTOs
│   ├── mappers/reg_mappers.dart ................ DTO → entity
│   ├── repositories/regularization_repository_impl.dart
│   ├── fixtures/regularization_fixtures.dart ... (exists — widget tests only)
│   └── interceptor/
│       └── reg_sign_in_gate_interceptor.dart ... ⭐ zero-touch interception
│
├── domain/
│   ├── entities/ ............................... 5 entities
│   ├── repositories/regularization_repository.dart
│   └── usecases/ ............................... 9 usecases
│
├── di/regularization_di.dart
│
└── presentation/
    ├── gate/
    │   ├── reg_gate_coordinator.dart ........... ⭐ the brain
    │   └── reg_gate_outcome.dart
    ├── cubit/ .................................. 3 cubits + 3 states
    ├── screens/ ................................ 2 (exist, need wiring)
    ├── widgets/ ................................ 8 (exist)
    └── entry/
        ├── reg_dashboard_entry.dart ............ role-aware banner/card
        └── reg_routes.dart
```

---

## §4 · Data layer — files and functions

### 4.1 `core/config/reg_config.dart`

```dart
enum RegSource { fake, live }

abstract final class RegConfig {
  static RegSource source = RegSource.fake;   // ⬅ the ONE line flipped at cutover
  static const int inboxPageSize = 10;        // §9.5 server default
  static const int myRequestsPageSize = 20;   // §9.3
  static const int fallbackCapHour = 19;      // §8.5
  static const String method = 'APP';         // §9.2
  static bool preCheckSingleSignIn = true;    // false once BE-5 ships → saves a round trip
}
```

### 4.2 `data/datasources/reg_api_paths.dart`

| Constant / fn | Endpoint | Spec |
|---|---|---|
| `base` | `/api/v1/staff-attendance-regularizations` | — |
| `openSessions` | `GET {base}/open-sessions?staffCode=` | §9.1 |
| `openSessionsBatch` | `POST {base}/open-sessions/batch` | §9.1b |
| `raise` | `POST {base}` | §9.2 |
| `raiseBatch` | `POST {base}/raise-batch` | §9.2b |
| `list` | `GET {base}?…` | §9.3 / §9.5 |
| `cancel(code)` | `POST {base}/{code}/cancel` | §9.4 |
| `approve(code)` | `POST {base}/{code}/approve` | §9.6 |
| `approveSelected` | `POST {base}/approve-selected` | §9.7 |
| `signInGuardPaths` | the 3 URL suffixes from §1.2 | §8.3 |

### 4.3 `data/datasources/reg_remote_datasource.dart` — the seam

```dart
abstract class RegRemoteDataSource {
  Future<List<MissedSignoutDto>> getOpenSessions({required String staffCode});
  Future<BatchGateDto>           getOpenSessionsBatch({required List<String> staffCodes});
  Future<RegularizationRequestDto> raise(Map<String, dynamic> body);
  Future<BatchApplyDto>          raiseBatch(Map<String, dynamic> body);
  Future<RegPageDto>             list(Map<String, dynamic> query);
  Future<RegularizationRequestDto> cancel(String code);
  Future<RegularizationRequestDto> approve(String code, Map<String, dynamic> body);
  Future<ApproveSelectedDto>     approveSelected(Map<String, dynamic> body);
}
```

Two implementations. **Nothing above this line knows which one is behind it.**

### 4.4 `reg_http_datasource.dart`

Constructed with `sl<ApiClient>().client`, so auth + `X-Organization-Code` / `X-School-Code`
interceptors apply automatically — same pattern as `StaffOvertimeRemoteDataSource`.
Each method is a thin `_client.get/post` + DTO parse. One private helper:

```dart
List<Map<String, dynamic>> _unwrapList(dynamic data);
// tolerates {data:{content:[...]}} and {data:[...]} — §0 of FE-1
```

### 4.5 `reg_fake_datasource.dart` — the backend-independence engine

Not fixtures. A stateful in-memory server that enforces the spec:

| Internal | Purpose |
|---|---|
| `_openRows: Map<staffCode, List<_FakeRow>>` | seeded open/SYSTEM-closed past days |
| `_requests: Map<code, RegularizationRequestDto>` | the regularization table |
| `_seq` | `SREG_0001`… code generation |
| `latency` / `failNext` | drive loading + error states in the real UI |
| `actingRole` | `STAFF` \| `ADMIN` — drives §8.2b |

Rules it enforces — each one a test:

| Rule | Case | Behaviour |
|---|---|---|
| §9.1 detection | C2, C3, C4 | open **or** `SYSTEM`+0min, past days only |
| `hasPendingRequest` | C10 | true once raised |
| §8.2 | C5, C6 | staff raise → `PENDING` |
| §8.2b | C7, C8 | admin raise → `APPROVED` + `autoApproved` + row cleared |
| §8.5 | C18, C19 | after sign-in, before the day cap |
| §8.6 | C11, C17, C24 | idempotent raise + approve |
| §8.3 | C25 | throws `DioException` 409 `REGULARIZATION_REQUIRED` |
| §9.2b | C9b, C9c | `{applied, skipped[]}` |
| §9.7 | C15, C16 | `{approved, skipped[]}` |
| §9.4 | C12 | cancel → `CANCELLED`, row gated again |

> **The fake is production code, not test scaffolding.** It stays after cutover as the offline
> dev harness and as the executable form of the spec.

### 4.6 `data/dto/` and `data/mappers/reg_mappers.dart`

DTOs: `MissedSignoutDto`, `RegularizationRequestDto`, `BatchGateDto`, `BatchApplyDto`,
`ApproveSelectedDto`, `RegPageDto`.

Mapper functions — `toMissedSignout`, `toRequest`, `toBatchGate`, `toPage`, plus
`_parseUtc(String?)` and `_status(String)`. `staffName` falls back to `staffCode` while
the §7 backend ask is open.

### 4.7 `data/interceptor/reg_sign_in_gate_interceptor.dart` ⭐

The whole zero-touch mechanism. ~40 lines of routing over `RegGateCoordinator`.

```dart
class RegSignInGateInterceptor extends Interceptor {
  RegSignInGateInterceptor(this._gate);
  final RegGateCoordinator _gate;

  @override
  Future<void> onRequest(options, handler) async {
    if (!RegApiPaths.isStaffSignIn(options.path)) return handler.next(options);

    final codes = _extractStaffCodes(options.data);

    if (codes.length > 1) {                              // ── bulk (C9a–C9d)
      final r = await _gate.guardBulk(codes);
      if (r.allowed.isEmpty) {
        return handler.reject(RegGateBlocked.asDioError(options));
      }
      options.data = _withStaffCodes(options.data, r.allowed);  // partial success
      return handler.next(options);
    }

    if (RegConfig.preCheckSingleSignIn) {                // ── single (C2/C3)
      final r = await _gate.guardSingle(codes.first, byAdmin: !_isSelfPath(options.path));
      if (r.isBlocked) return handler.reject(RegGateBlocked.asDioError(options));
    }
    handler.next(options);
  }

  @override
  Future<void> onError(err, handler) async {             // ── C25 backstop
    if (!RegApiPaths.isStaffSignIn(err.requestOptions.path)) return handler.next(err);
    if (!RegConflict.matches(err)) return handler.next(err);

    final resolved = await _gate.handleConflict(err);
    if (!resolved) return handler.next(err);
    handler.resolve(await _retry(err.requestOptions));   // auto-retry the original sign-in
  }
}
```

Helpers: `_extractStaffCodes` (reads `staffCodes` then `staffCode`), `_withStaffCodes`,
`_isSelfPath`, `_retry`.

**Installed once** in `regularization_di.dart` — appended to the attendance Dio's interceptor
chain. No form, cubit, or repository is aware it exists.

---

## §5 · Domain layer — files and functions

### 5.1 Entities

| File | Change |
|---|---|
| `missed_signout.dart` | **fix §1.3**: `softSignOutAt`→`suggestedSignOutAt` (nullable), `signInAt`→`signedInAt`, add `hasPendingRequest`, add `classroomCode`. Keep `attendanceCode`, `staffCode`, `staffName`, `initials`. |
| `regularization_request.dart` | add `attendanceCode`, `confirmedSuggestedTime`, `appliedSignOutAt`, `raisedByRole`, `autoApproved`; rename `softSignOutAt`→`suggestedSignOutAt`. Add `enum RegRaisedBy { staff, admin }`. |
| `reg_raise_input.dart` | **new** — `{ staffCode, attendanceCode, attendanceDate, signOutLocal, reason, confirmedSuggestedTime }`. What the sheets return, what the repo consumes. |
| `reg_batch_gate.dart` | **new** — `{ List<MissedSignout> blocked, List<String> clear }` (§9.1b). |
| `reg_batch_result.dart` | **new** — `{ int applied, List<RegSkipped> skipped }` (§9.2b, §9.7). |

### 5.2 `domain/repositories/regularization_repository.dart`

```dart
abstract class RegularizationRepository {
  Future<List<MissedSignout>> getOpenSessions(String staffCode);          // §9.1
  Future<RegBatchGate>        getOpenSessionsBatch(List<String> codes);   // §9.1b
  Future<RegularizationRequest> raise(RegRaiseInput input);               // §9.2
  Future<RegBatchResult>      raiseBatch(List<RegRaiseInput> items, String sharedReason); // §9.2b
  Future<RegPage>             getMyRequests({String staffCode, RegStatus? status, int page}); // §9.3
  Future<RegularizationRequest> cancel(String code);                      // §9.4
  Future<RegPage>             getPending({String schoolCode, int page});  // §9.5
  Future<RegularizationRequest> approve(String code, {DateTime? signOutLocal, String note}); // §9.6
  Future<RegBatchResult>      approveSelected(List<String> codes);        // §9.7
}
```

`RegularizationRepositoryImpl` owns the two things the datasource must not:
`Av2TimeZone.toUtcIso(local, zone)` for every wall-clock field, and
`SchoolTimezoneResolver.resolveForCurrentSchool()` for the `timeZone` payload key (§10.1).

### 5.3 Usecases (9) — one per endpoint, each a `call(...)`

`GetOpenSessions` · `GetOpenSessionsBatch` · `RaiseRegularization` · `RaiseRegularizationBatch` ·
`GetMyRequests` · `CancelRequest` · `GetPendingRequests` · `ApproveRequest` · `ApproveSelected`

---

## §6 · Presentation layer — files, functions, and who calls them

### 6.1 `presentation/gate/reg_gate_coordinator.dart` ⭐ the brain

Every gate decision in the app lives in this one class. The interceptor calls it; the
dashboard calls it; nothing else needs to.

```dart
class RegGateCoordinator {
  /// C2/C3 — one staff. Returns proceed | blocked.
  Future<RegGateOutcome> guardSingle(String staffCode, {required bool byAdmin, String? staffName});

  /// C9a–C9d — many staff. Returns who may now be signed in.
  Future<RegBulkGateOutcome> guardBulk(List<String> staffCodes);

  /// C25 — parse a 409 and resolve it. true = retry the sign-in.
  Future<bool> handleConflict(DioException error);

  /// Dashboard — check only, never shows UI.
  Future<MissedSignout?> peek(String staffCode);

  /// Dashboard — show the sheet for an already-known open day.
  Future<bool> resolve(MissedSignout item, {required bool byAdmin, bool mandatory = true});
}
```

Internals: `_context` (via `CoreUtils.rootNavigatorKey`), `_isAdmin` (via `RoleCubit`),
`_submitSingle`, `_submitBatch`, `_toast`.

`RegGateOutcome { proceed, blocked }` ·
`RegBulkGateOutcome { List<String> allowed, int cleared, int skipped }`

### 6.2 Cubits

| Cubit | Screen | Methods | States |
|---|---|---|---|
| `RegMyRequestsCubit` | `RegStaffListScreen` | `load()`, `loadMore()`, `refresh()`, `cancel(code)`, `resolveGate()` | initial · loading · loaded(items, gate, hasMore) · error |
| `RegInboxCubit` | `RegAdminInboxScreen` | `load()`, `loadMore()`, `refresh()`, `approve(code, {time, note})`, `toggleSelect(code)`, `approveSelected()` | initial · loading · loaded(items, selected, hasMore) · error |
| `RegBadgeCubit` | dashboard entry | `load()`, `refresh()` | count (0 = hidden) |

`RegInboxCubit.approveSelected()` handles C16: remove the `approved` codes, keep the
`skipped` ones with a message naming how many and why.

### 6.3 Screens — the wiring change

Both screens currently take a `List<...>` constructor arg fed by fixtures. They keep that
constructor (so the 10 widget tests and `reg_dev_app.dart` keep working) and gain a
`.connected()` factory that wraps them in a `BlocProvider`:

```dart
RegStaffListScreen.connected()   // BlocProvider<RegMyRequestsCubit> + BlocBuilder
RegAdminInboxScreen.connected()  // BlocProvider<RegInboxCubit>     + BlocBuilder
```

> Keeping the dumb constructor is deliberate: the widget tests stay fast and cubit-free, and
> the screens remain previewable in `reg_dev_app.dart`.

### 6.4 `presentation/entry/reg_dashboard_entry.dart`

One widget, dropped once into each dashboard. It decides what to render from `RoleCubit`:

- **staff** → unresolved-day banner (hidden when clear) → tap opens the resolve sheet
- **admin** → "needs your approval" card + pending badge (hidden at zero) → tap opens the inbox

It also performs the **auto-appear on dashboard** the requirement asks for: on `initState`
it calls `RegGateCoordinator.peek(myStaffCode)`; if an unresolved day comes back **and**
`hasPendingRequest == false`, it opens the resolve sheet once per app session
(guarded by a `_shownThisSession` flag so it doesn't re-fire on every rebuild or tab switch).

### 6.5 `presentation/entry/reg_routes.dart`

```dart
List<RouteBase> regRoutes() => [
  GoRoute(path: Regularization.myRequestsRoute, builder: (_, __) => RegStaffListScreen.connected()),
  GoRoute(path: Regularization.adminInboxRoute, builder: (_, __) => RegAdminInboxScreen.connected()),
];
```

---

## §7 · The four flows, end to end

### 7.1 Staff taps Sign in (single) — C1 / C2 / C3 / C5 / C6 / C10

```
my_day_card._openSignInForm()          ← unchanged
  → StaffSignInForm._submit()          ← unchanged
    → AttendanceRepository.submitStaffSignIn()   ← unchanged
      → POST /staff-attendance-records/sign-in/self
        ⇣ RegSignInGateInterceptor.onRequest — matches
          RegGateCoordinator.guardSingle(staffCode, byAdmin: false)
            GET /open-sessions?staffCode=…
            ├─ [] ......................... C1 → handler.next → sign-in proceeds
            ├─ hasPendingRequest: true .... C10 → handler.next → sign-in proceeds
            └─ open day ................... C2/C3
                 showRegResolveSheet(mandatory: true)
                   ├─ submitted → POST / (role STAFF → PENDING)
                   │              toast "Sent for approval"
                   │              handler.next → original sign-in proceeds
                   └─ dismissed → handler.reject(RegGateBlocked)
                                  form shows "Sign-in cancelled…"
```

No file outside the module participates. The form never learns the gate exists.

### 7.2 Admin signs in one staff — C7 / C8

Identical path; `byAdmin: true` because the URL is `/sign-in` not `/sign-in/self`.
The sheet switches to admin copy ("Sign-out missing", names the staff, "approved
automatically"), the server auto-approves (§8.2b), and the toast says **"Applied"** —
read from the response `status`, never guessed client-side.

### 7.3 Admin bulk sign-in — C9a / C9b / C9c / C9d

```
staff_selection_sign_in_form → StaffSignInForm(staffList: […50]) → _submit()
  → POST /sign-in  { staffCodes: [50 codes], … }
    ⇣ interceptor: codes.length > 1 → guardBulk
      POST /open-sessions/batch { staffCodes: [50] }
        → { blocked: [10 with staffName + suggested time], clear: [40] }

      showRegBulkSignInGateSheet(blocked: 10, otherCount: 40)   ← already built & tested
        ├─ "Close all 10 & sign them in"      C9b
        │    POST /raise-batch { items: 10, reason }  → all auto-approved (§8.2b)
        │    allowed = 40 + 10 = 50
        ├─ rows corrected first                C9c
        │    shared reason required            → same call, mixed confirmedSuggestedTime
        └─ "Skip — sign in the other 40"       C9d
             allowed = 40

      options.data.staffCodes = allowed        ← payload rewritten in place
      handler.next → ONE sign-in call for exactly the staff who may proceed
```

**Partial success falls out of the design** — the 40 are never held up by the 10, because
the interceptor rewrites the payload rather than failing the request.

### 7.4 Opening the dashboard — auto-appear

```
StaffDashboard / AdminDashboard build
  → Regularization.dashboardEntry()      ← the one added line
      initState → RegGateCoordinator.peek(myStaffCode)   (GET /open-sessions)
        ├─ null ....................... render nothing
        ├─ hasPendingRequest: true .... render "awaiting approval" banner, no sheet
        └─ unresolved ................. render banner
                                        + auto-open resolve sheet once per session
      admin also → RegBadgeCubit.load() → count > 0 ? approval card + badge : nothing
```

---

## §8 · Phases and progress

| Phase | Weight | Cum. | Needs BE? |
|---|---|---|---|
| 0 · Contract lock — entities, config, renames | 8% | 8% | no |
| 1 · Data layer + stateful fake | 20% | 28% | no |
| 2 · Domain layer — repo + 9 usecases | 10% | 38% | no |
| 3 · DI + interceptor install + facade | 12% | 50% | no |
| 4 · Gate coordinator + all 4 flows | 22% | 72% | no |
| 5 · Cubits + screen wiring | 14% | 86% | no |
| 6 · Dashboard entry + routes + deep link | 9% | 95% | no |
| 7 · Live cutover + verification | 5% | 100% | **yes** |

**95% ships without backend.**

### Phase detail

**Phase 0 · 8%** — §1.3 entity fixes; `reg_config.dart`; propagate renames through the 8
existing widgets, fixtures, dev app; **10/10 tests green again.** No behaviour change.

**Phase 1 · 20%** — `reg_api_paths`, 6 DTOs, mappers, abstract datasource, HTTP impl,
**fake impl**, contract tests covering C1–C25.

**Phase 2 · 10%** — repository interface + impl (timezone conversion lives here), 9 usecases.

**Phase 3 · 12%** — `regularization_di.dart`; interceptor installed on the attendance Dio;
`regularization.dart` facade; the 4 host lines added. Nothing visible yet — but
`flutter analyze` clean and the app boots unchanged.

**Phase 4 · 22%** — `RegGateCoordinator` + `RegSignInGateInterceptor` logic + the 4 flows of §7.
Tests: single staff · admin single · bulk partial · bulk skip · 409 retry · already-pending.
**Exit = the demo:** on the fake, sign-in is genuinely blocked, the sheet raises, sign-in retries and succeeds.

**Phase 5 · 14%** — 3 cubits + `.connected()` factories; pagination, refresh, cancel,
approve, multi-select, `skipped` reconciliation; admin role gating.

**Phase 6 · 9%** — `reg_dashboard_entry.dart` (banner, card, badge, auto-appear), routes,
notification deep link.

**Phase 7 · 5%** — flip `RegConfig.source`, verify all 9 endpoints, confirm response shapes,
regression across the full sign-in matrix.

### Progress

| Phase | Weight | Status | Done |
|---|---|---|---|
| 0 · Contract lock | 8% | Not started | 0% |
| 1 · Data + fake | 20% | Not started | 0% |
| 2 · Domain | 10% | Not started | 0% |
| 3 · DI + interceptor | 12% | Not started | 0% |
| 4 · Gate + flows | 22% | Not started | 0% |
| 5 · Cubits + screens | 14% | Not started | 0% |
| 6 · Entry points | 9% | Not started | 0% |
| 7 · Cutover | 5% | Not started | 0% |
| **Total** | **100%** | | **0%** |

---

## §9 · Backend asks (raise now — none block us)

| # | Ask | Ticket | Why it matters |
|---|---|---|---|
| 1 | `staffName` in the **inbox** list DTO, batched per page like `decidedByName` | BE-6 | The inbox renders names (required field, asserted in tests). §9.1b grants `staffName` for the *batch gate* but §9.5 never grants it for the *inbox*. Same batched lookup, same N+1 risk. |
| 2 | Confirm the `409` body shape matches §9.1 exactly | BE-5 | The C25 backstop parses it; a differing shape silently disables the fallback. |
| 3 | Confirm list responses: `data.content` or flat `data` | BE-6 | Mapper tolerates both — confirmation removes a guess. |
| 4 | Guard the **kiosk** URL `/api/v1/attendance/staff-attendance-records/sign-in` | BE-5 | §1.2 — a distinct path no ticket lists. Client-side it's covered; server-side it must be too. |
| 5 | Confirm `/raise-batch` and `/open-sessions/batch` are in BE scope | BE-3, BE-2 | §9.1b/§9.2b were added to the spec after BE-2/BE-3 were written. Both tickets still describe only the single-staff endpoints. |

---

## §10 · Working agreement

- One phase per commit series; each phase ends green (`flutter analyze` + tests).
- Validate at each phase exit before starting the next.
- Nothing outside `lib/modules/attendance_regularization/` imports anything but
  `regularization.dart`. If a second import appears, the facade is missing something —
  extend the facade, don't add the import.
- `RegConfig.source` is never read at a call site. The flag is the only switch.
