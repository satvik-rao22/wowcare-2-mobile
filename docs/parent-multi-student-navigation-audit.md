# Parent Multi-Student Navigation — Root Cause, Fix, and Production-Readiness Audit

> Branch `develop-refactor` · baseline `0d9f7d72`
> Scope: navigation / redirection / selected-student context for the **Parent**, **Staff** and **Admin** personas.

---

## Executive Summary

**Original issue.** For a guardian with two or more linked children, the selected-student
context could silently disagree with the screen the user was looking at: a notification or
in-app tap would open child B's screen while the app-bar switcher, the dashboard cards, the
activity feed and the newsletter list all stayed on child A. A cold start always reset the
selection to the first child, and two siblings whose names render identically could not be
switched between at all.

**Root cause.** Not a routing bug. The app already has a single source of truth for the
selected child (`ParentChildCubit`) and the router already has persona guards. The defect was
in the cubit's *selection contract*: `selectByCode` **silently dropped** any request it could
not satisfy at the instant it was made, `ensureLoaded` then fell back unconditionally to
`children.first`, concurrent loads did not share a future, and nothing was persisted. Three
independent multi-student failures fell out of that one contract. See [Root Cause](#root-cause).

**Fix.** The selection contract was made deterministic, ownership-checked, race-safe and
session-scoped, entirely inside the existing cubit — no new state-management mechanism, no
second source of truth, no route-shape change. A router-level guardian scope guard was added
for the two deep-link routes that take a student code straight off the URL. 501 lines changed
across 7 files; 41 new tests.

**Overall production readiness: 7.5 / 10.** The parent multi-student flow is now correct and
covered by tests. What holds the score down is *outside* this fix: a 3,600-line router with no
integration-level route tests, a persona guard model that is allow-by-default for routes
outside `/dashboard/`, and 27 pre-existing test failures unrelated to navigation.

---

## Root Cause

Everything below is read off the code at `0d9f7d72`, not inferred.

`ParentChildCubit` (`lib/shared/common/app/cubit/parent_child_cubit.dart`) is a GetIt
lazy-singleton provided at the app root (`lib/app/app_providers.dart`). It genuinely is the
single source of truth — the app-bar switcher, the dashboard coordinator, the activity feed,
the newsletter list, the parent messaging thread and the student/attendance profiles all read
from it, and the profile screens subscribe to its stream via `syncWithParentChildSelection`.
The architecture was sound. The contract was not.

### 1. Requests made before the child list was ready were silently discarded — P1

`selectByCode` looped over `state.children` and `return`ed when it found no match:

```dart
void selectByCode(String? code) {
  ...
  ParentChildRef? next;
  for (final child in state.children) { if (child.code.trim() == trimmed) { next = child; break; } }
  if (next == null) return;          // <-- indistinguishable from "not yours"
  ...
}
```

Both notification entry points call it immediately before navigating
(`notification_navigator.dart:96`, `notification_center_screen.dart:355`), as do the parent
sign-in/sign-out forms and the QR scan path. On any path where the child list had not resolved
— a warm-start FCM tap, an in-app notification-center tap, a deep link arriving right after a
school switch — the call became a **no-op with no error and no retry**.

Navigation still proceeded: `/dashboard/student-attendance-profile-by-code?code=B` self-loads
by code and does *not* set `syncWithParentChildSelection`. When the guardian fetch then
resolved, `ensureLoaded` reached its fallback:

```dart
resultSelected = matching ?? loadedChildren.first;   // child A
```

Result: the pushed screen shows child B; the app bar and every other student-scoped surface
show child A. That is precisely the reported "context switches to another student" symptom,
and it is *only* reachable with 2+ children.

### 2. Concurrent loads returned a completed future instead of the real one — P1

```dart
Future<void> ensureLoaded({bool force = false}) async {
  if (state.isLoading) return;      // completes immediately, load still running
```

Five call sites do `await parentChild.ensureLoaded()` and then read `selectedChild`:
`buildParentChildAttendanceProfile` (`attendance_popup.dart:43`), the drawer's *My Child* and
*Attendance* entries (`custom_drawer.dart:485,556`), and
`loadGuardianStudentAllowlistForSelection`. Whenever another load was already in flight —
which the drawer itself triggers from `build` via `Future.microtask(ensureLoaded)`
(`custom_drawer.dart:800`) — those reads returned `null` or the previous school's child. A
`null` read surfaces as *"No child selected. Choose a child from the menu at the top first"*
on an account that plainly has children.

### 3. Selection was never persisted, and switching was keyed on display name — P2

* Nothing wrote the selection to storage, so `ensureLoaded` had no third candidate and every
  cold start landed a 2+ child parent back on `children.first`.
* `CustomAppBar` drove the switcher with `cubit.childNames` / `cubit.selectByName`. Two
  siblings whose names render identically (same first+last on file, or both falling back to
  their code) collapsed into one dropdown entry, and `selectByName` resolved it to the first
  match — the second child was **unreachable**.

### What was NOT the cause

Ruled out by inspection, so the fix did not touch them: widget-local selection state
(none — every consumer reads the cubit); redirect loops (the top-level redirect is
side-effect free and its targets are unguarded); `push` vs `go` misuse; `_fastPage` page-key
reuse (the parent paths that re-enter the same route carry `syncWithParentChildSelection`, and
`push` allocates a fresh page key); shell-branch navigator confusion (already fixed by
`dashboardBranchKey` and `popAllShellBranchNavigators`); and cross-persona state bleed (staff
classroom selection is a per-route `ClassroomCubit` **factory**, never a singleton).

---

## Changes Made

| File | Change |
|---|---|
| `lib/shared/common/app/cubit/parent_child_cubit.dart` | Deterministic selection contract; ownership check; pending-request handling; shared in-flight load; scope-stamped persistence; `resetForLogout`; `ownedStudentCodes` / `isOwnedStudent` / `displayLabels` / `labelForCode` / `selectByLabel` |
| `lib/core/util/storage_keys.dart` | `selectedStudentCode` + `selectedStudentContext` |
| `lib/src/app_router.dart` | `_guardianStudentScopeRedirect` + testable `guardianStudentScopeDecision`; `'students'` added to `_dashboardAdminOnlySegments` |
| `lib/shared/common/widgets/custom_app_bar.dart` | Switcher driven by `displayLabels`/`selectByLabel`/`labelForCode`; `debugPrint` → `AppLogger.d` |
| `lib/presentation/features/auth/view_model/auth_cubit.dart` | `logoutSession` / `clearCache` → `resetForLogout()` |
| `lib/core/auth/session_expired_coordinator.dart` | Session expiry → `resetForLogout()` |
| `lib/presentation/features/dashboard/cubit/parent_dashboard_coordinator_cubit.dart` | Reload only on a real child switch or an explicit `forceRefresh` |

**Selection precedence** — resolved in exactly one place, `_resolveSelection`, every step
filtered through the loaded child list:

1. an explicit pending request (a deep link about child B that arrived before the list),
2. the child already selected in memory (a switch survives a refresh),
3. the child persisted for **this** `userCode|orgCode|schoolCode` scope (survives a cold start),
4. the first child.

**Rejected, not silently dropped.** `selectByCode` now returns `bool` and has three outcomes:
owned-and-loaded → selected and persisted; loaded-but-not-owned → **rejected and logged**,
selection untouched; not-loaded-yet → recorded as pending and applied the moment the list
resolves, still subject to the ownership check.

### Tests added

| File | Tests |
|---|---|
| `test/shared/common/app/cubit/parent_child_cubit_test.dart` | 25 |
| `test/src/guardian_student_scope_guard_test.dart` | 11 |
| `test/presentation/features/dashboard/cubit/parent_dashboard_coordinator_reload_policy_test.dart` | 5 |

Two of these were verified to **fail against the pre-fix code** and pass after
("loading-flag churn does not reload"; the pre-load selection tests only compile against the
new API). No existing test was modified.

### Verification

| Check | Before | After |
|---|---|---|
| `flutter analyze` | 154 issues (109 lib, 45 test, 13 errors — all in test files) | **154, byte-identical set** — zero new |
| `flutter test` | 1038 passed / 27 failed | **1079 passed / 27 failed — the same 27** |
| `dart format` | `app_router.dart` + `auth_cubit.dart` already non-clean | unchanged; every other touched file and all new files clean |

The 27 failures were confirmed pre-existing by stashing the change and re-running the affected
files: identical `+14 -21` before and after. They live in `conversation_thread_cubit_test`,
`private_mode_flow_test`, `chat_input_bar_test`, `api_paths_uat_test`, `widget_test`
(a mock with its `loadConversations` override commented out) and five staff/messaging test
files that do not compile against current constructors.

---

## Parent Audit

| Area | Status | Findings | Fix |
|---|---|---|---|
| Multi-student navigation | **Fixed** | P1 — a selection requested before the child list loaded was dropped; the list then defaulted to `children.first`, so the global context disagreed with the open screen | Pending-request handling in `selectByCode`, applied by `_resolveSelection` |
| Student switching | **Fixed** | P2 — switcher keyed on display name; identical sibling names collapsed to one unreachable entry | `displayLabels` / `selectByLabel`, index-aligned with `children` |
| Concurrent load | **Fixed** | P1 — `ensureLoaded` returned a completed future mid-load; `await`-then-read got `null`/stale | Shared `_inFlight` future |
| Cold start / restore | **Fixed** | P2 — selection never persisted; every restart reset to `children.first` | Scope-stamped persistence, restored as precedence step 3 |
| Back navigation | **Pass** | Context lives in the cubit, not the route, so pop cannot change it. App-bar back: `Navigator.pop` → `context.pop` → `go(/dashboard)`; the attendance profile is pushed on `dashboardBranchKey` so it pops within its branch | `debugPrint` on the back path replaced with `AppLogger.d` |
| Deep links | **Fixed** | P1 — `student-profile-by-code` / `student-attendance-profile-by-code` accepted any `code` with no guardian check | Router guardian scope guard |
| Notifications | **Fixed** | Same root cause as multi-student navigation; both entry points already called `selectByCode`, it just did nothing when raced | Now deferred and applied |
| Logout / reset | **Fixed** | Selection cleared in memory only; the code stayed in storage | `resetForLogout()` at both `AuthCubit` paths and session expiry |
| Authorization | **Improved** | Client-side only; see [Security Audit](#security-audit) for the residual | Ownership filter in the cubit + router guard |
| Dashboard reload | **Fixed** | P3 — every `ParentChildCubit` emission (including `isLoading` toggles) re-ran four feature loads | Reload only on child switch or `forceRefresh` |

### The critical scenario, traced

`Select A → Feature X → Y → Z → Back → still A`, then `Switch to B → X → Y → Z → Back → still B`
now holds because the selection is a single cubit value that nothing on the navigation path
writes. Screen-level staleness is handled by `syncWithParentChildSelection`, which every
parent entry point into `StudentProfileScreen` / `StudentAttendanceProfile` passes
(`custom_drawer.dart:539,588`, `attendance_popup.dart:99`,
`student_attendance_summary_card.dart:100`, `user_profile_screen.dart:381`, both sign-in/out
forms). The activity feed, newsletter list and parent messaging thread each watch the cubit
and re-fetch on a code change.

---

## Staff Audit

| Area | Status | Findings | Fix |
|---|---|---|---|
| Login / dashboard | **Pass** | Splash resolves persona before `/dashboard`; `RoleCubit.isPersonaResolved` gates the dashboard dispatch | — |
| Classroom selection | **Pass** | `ClassroomCubit` is a GetIt **factory**, created per route builder — there is no global selected-classroom state, so none can leak | — |
| Student selection | **Pass** | Staff student selection is per-screen route args, not global | — |
| Parent-state inheritance | **Pass, hardened** | `ensureLoaded` short-circuits non-guardian personas to an *empty loaded* state | Pending request also cleared on that path; covered by a test |
| Reports / attendance / messaging | **Pass** | Module-guarded via `_dashboardModuleGuards` | — |
| Deep links | **Partial — P2** | Persona guard only covers `/dashboard/*`; `/attendance/staff-*` and `/dashboard/staff-sign-in-form` have no persona guard | **Not fixed** — see below |
| Logout | **Pass** | `RoleCubit.resetSessionForLogout()` + storage clear | — |

---

## Admin Audit

| Area | Status | Findings | Fix |
|---|---|---|---|
| Login / dashboard | **Pass** | Same persona-resolution gate. `RoleState.role` defaults to `'admin'`, but `DashboardScreen` explicitly waits for a resolved persona before dispatching — already handled and documented in that file | — |
| Management modules | **Pass** | `_dashboardModuleGuards` covers staff, students, classroom-info, billing, newsletter, reports, scheduling, availability, movements, attendance views | — |
| Parent-state dependency | **Pass** | No admin surface reads `ParentChildCubit` | — |
| Student list route | **Hardened** | `/dashboard/students` was persona-open to a guardian holding a `student` read grant | `'students'` added to `_dashboardAdminOnlySegments` |
| Deep links | **Partial — P2** | Same allow-by-default gap as Staff | **Not fixed** |
| Logout | **Pass** | — | — |

---

## Cross-Persona Isolation

Verified by test (`session reset and persona isolation` group):

* Parent → logout → Staff login: `ensureLoaded` emits an empty loaded state for a non-guardian
  persona, so no child is inherited. The persisted record is erased by `resetForLogout` and,
  even if it survived, is stamped with the previous `userCode|orgCode|schoolCode`.
* Staff/Admin → Parent login: parent starts from their own fetched list.
* Staff has no global selected-classroom or selected-student state to leak in either direction.

---

## Navigation Audit

**Route architecture.** One `GoRouter` with a five-branch `StatefulShellRoute.indexedStack`
(dashboard / classroom / activity / messaging / parent-billing), stable per-branch
`GlobalKey<NavigatorState>`s declared outside the router so they survive rebuilds, plus
root-level routes for auth, kiosk, document/newsletter viewers and notification deep-links.
Paths are centralised in `core/router/app_routes.dart` (`ReportRoutes`, `StaffRoutes`,
`SchedulingRoutes`, `DashboardRoutes`, `NewsletterRoutes`, …) and `AppRoutes` in
`src/app_router.dart`.

**Redirect architecture.** A single top-level `redirect`, in order: kiosk containment (fails
**closed**), dashboard persona guard, **new** guardian student-scope guard, guardian billing
rewrite. Each is deterministic, performs no navigation of its own, and targets locations that
are not themselves guarded — so no A→B→A loop is reachable. Verified by test for the new guard.

One caveat, pre-existing: the top-level redirect is `async`. Every navigation therefore
resolves through a microtask. `KioskAccessControl.isKioskModeResolved` correctly memoises the
storage read so it is a one-time cost, but the signature keeps the whole chain asynchronous.

**Route guards.** Two policies: `_dashboardAdminOnlySegments` (persona) and
`_dashboardModuleGuards` (permission). Both are **allow-by-default outside their maps** and
both are scoped to `/dashboard/*`. Fine for the surfaces they name; see the P2 below.

**Nested navigation.** Screens reached from a branch are registered as children of that
branch's route so they render inside the nav shell; full-screen viewers are registered at the
router root so they cover it. Screens reachable from two branches are registered twice
(`ReportRoutes.fileViewer` vs `billingFileViewer`, both newsletter previews) — deliberate and
documented.

**State restoration.** Selected student now restores from storage, scope-stamped. Bottom-nav
branch state is held by `StatefulShellRoute.indexedStack`. Nothing else is restored across
process death, which matches the app's existing behaviour.

---

## Security Audit

| Area | Assessment |
|---|---|
| Role isolation | Router persona guard for `/dashboard/*`; `RoleCubit` gates the dashboard dispatch and every drawer/nav entry. Kiosk containment fails **closed** |
| Student ownership | **Now enforced in two places**: `ParentChildCubit` filters every selection through the loaded child list, and the router rejects an unowned `code` on both by-code routes. The attendance selection forms already narrowed by `loadGuardianStudentAllowlistForSelection`; the QR path already passed `guardianChildCodes` |
| Session isolation | Persisted selection scope-stamped and erased on logout / session expiry |
| Route parameter validation | Student codes on the two deep-link routes are validated against the guardian's own list before the screen mounts |
| Sensitive logging | `AppLogger.d/i/w` are compiled out of release. One `debugPrint` on the back-navigation path (which **is** emitted in release, printing the current route) was replaced |

**Residual — P3, accepted and documented.** The router guard fails open in three cases: persona
unresolved, child list not loaded, or child list loaded empty. Failing closed on the first two
would break every cold-start deep link, and the third is indistinguishable from a transient
fetch failure. The window is narrow — the splash `await`s `ensureLoaded(force: true)` for a
parent before routing a cold-start deep link — but it is real for a warm-start tap that races
the fetch. **This is a UI guard; the backend remains the authorization boundary.** The
existing `attendance_repository_scope_security_test.dart` documents the same stance for
attendance scope.

**Residual — P2, not fixed.** Persona guarding is allow-by-default and only covers
`/dashboard/*`. `/attendance/staff-sign-in`, `/dashboard/staff-sign-in-form` and ~10 sibling
attendance routes have no persona guard. Closing this properly means inverting the model to
deny-by-default with a per-persona allowlist, which is a rewrite of the guard architecture and
cannot be validated without a full persona × route matrix. Recommended as a separate,
test-first change; deliberately out of scope here.

---

## Performance Audit

| Area | Finding | Severity |
|---|---|---|
| Duplicate API calls | **Fixed.** `ParentDashboardCoordinatorCubit` re-ran four feature loads on every `ParentChildCubit` emission — including `isLoading` toggles — so one refresh fired 8–12 requests that raced each other into the same cubits. Now reloads only on a real child switch or an explicit `forceRefresh` | P3 → fixed |
| Redundant loads | **Fixed.** Concurrent `ensureLoaded` callers now share one guardian-children fetch instead of the second silently skipping | P3 → fixed |
| Redirect cost | Top-level redirect is `async`; kiosk storage read is memoised after the first navigation | P3 |
| Navigation performance | `_fastPage` uses a 180 ms slide; branch switches are instant `IndexedStack` swaps | Pass |
| Listeners | `ParentChildCubit` subscriptions are cancelled in `dispose`/`close` at every site inspected; `_safeEmit` guards emit-after-close | Pass |
| Rebuilds | `_ShellScope.updateShouldNotify` compares `currentIndex` only; `_ShellScopeContent` caches the shell reference to avoid a layout-phase GlobalKey assertion | Pass |

---

## Code Quality Audit

### P1 — Critical (all fixed)
* Selection requests dropped when the child list was not ready.
* `ensureLoaded` returning a completed future mid-load, producing `null`/stale reads at five
  `await`-then-read call sites.
* Unvalidated student code on both by-code deep-link routes.

### P2 — High
* **Fixed:** name-keyed child switching made identical-name siblings unreachable.
* **Fixed:** selection not persisted across process restarts.
* **Hardened:** `/dashboard/students` reachable by a guardian with a `student` read grant.
* **Not fixed:** persona guards are allow-by-default and cover only `/dashboard/*` (above).

### P3 — Medium
* **Fixed:** duplicate dashboard loads on every cubit emission.
* **Fixed:** `debugPrint` on the back-navigation path (release-visible route logging).
* **Not fixed:** `SplashCubit.resolve` opens with `await Future.delayed(Duration(seconds: 1))`
  before any routing decision. It is a splash-hold, not a navigation workaround, but it is
  unconditional latency on every cold start.
* **Not fixed:** `DashboardScreen.build` schedules `context.go(KioskRoutes.root)` in a
  post-frame callback for kiosk users, duplicating the router's own kiosk redirect and firing
  on every build while that state holds. Defensive and deferred, so not a bug — but a
  navigation decision in a build method.
* **Not fixed:** `custom_drawer.dart:800` fires `Future.microtask(ensureLoaded)` from `build`.
  Idempotent and guarded, but a side effect from a build method.
* **Not fixed:** `_studentProfileScreen` / `_studentAttendanceProfileScreen` still accept a
  `Map<String, dynamic>` `extra` alongside their typed args. Nine callers; the typed-args
  migration is partially done and documented in-file.
* **Not fixed:** `lib/src/app_router.dart` is 3,749 lines with three duplicate imports and no
  route-level integration tests.

### P4 — Low
* 165 `debugPrint` calls remain across `lib/` outside the navigation path.
* Cosmetic `Future.delayed` before a `pop` in `change_password_screen` /
  `forgot_password_screen`, and a 300 ms fake button spinner before a `push` in
  `student_attendance_custom_view.dart:497`.
* `app_router.dart` and `auth_cubit.dart` are not `dart format` clean at baseline; left alone
  to keep the diff reviewable.

---

## Production Readiness Score

| Category | Score | Note |
|---|---:|---|
| Navigation | 7/10 | Sound shell/branch architecture and centralised paths; router is very large and has no integration-level route tests |
| Parent multi-student handling | 9/10 | Deterministic, ownership-checked, persisted, race-safe, tested |
| Staff navigation | 7/10 | Correct and isolated; deep-link guarding is allow-by-default |
| Admin navigation | 7/10 | Same |
| State management | 8/10 | One genuine source of truth with a documented contract; `ParentChildState.props` still emits on five inputs, which consumers must each filter |
| Security | 7/10 | Client guards materially improved; the load-window fail-open and the allow-by-default route model are real residuals |
| Error handling | 7/10 | Empty list, unlinked code, malformed deep link, storage failure and fetch failure all have defined behaviour; a failed guardian fetch is still indistinguishable from "no children" |
| Performance | 8/10 | Duplicate load storms removed; async top-level redirect and the 1 s splash hold remain |
| Testing | 6/10 | 41 new unit tests on the changed contract; **no widget/integration test drives an actual multi-student navigation sequence**, and 27 pre-existing failures remain |
| Architecture | 8/10 | Clean-Architecture layering holds; the fix stayed inside the existing cubit |
| Maintainability | 7/10 | Contract is documented at the source; the router file itself remains hard to work in |

**Overall Production Readiness: 7.5 / 10**

Not higher, because the fix is verified at the unit level and by code inspection — **it has not
been exercised against a running app with a real two-child account**, and the two P2 residuals
above are genuine.

---

## Definition of Done — status

| Item | Status |
|---|---|
| Parent single- and multi-student navigation | Done, tested |
| Student A stays A / B stays B across modules and back | Done — context is a cubit value nothing on the navigation path writes |
| Switching updates dependent screens | Done — existing `syncWithParentChildSelection` + watchers, now fed a reliable selection |
| App restart restores valid context | Done, tested |
| Invalid / unowned student ID rejected | Done, tested (cubit + router guard) |
| Logout clears persona state; no cross-persona leakage | Done, tested |
| Redirects deterministic and loop-free | Done for the new guard, verified by test; existing guards inspected |
| No navigation from build methods | **Partial** — two pre-existing post-frame/microtask cases documented above, not introduced here |
| No delay-based navigation workaround | **Partial** — none introduced; pre-existing cosmetic delays documented |
| Existing functionality unchanged | Analyzer set byte-identical; same 27 pre-existing test failures; no existing test modified |
| Static analysis / formatting | Pass |
| Not verified | Device/emulator run with a real multi-child guardian account |
