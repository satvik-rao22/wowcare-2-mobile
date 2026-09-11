# Dashboard Route — Production Readiness Audit

**Scope:** the `/dashboard` route as a routing artefact — registration, guards, entry paths, argument typing, branch behaviour, teardown. Not the cards (see [`dashboard-baseline.md`](dashboard-baseline.md)).
**Measured against:** `develop-refactor` @ `38629fc4`, clean tree.
**Router:** `lib/src/app_router.dart` — 2,778 lines, 126 `GoRoute` entries, 5 shell branches.
**No source file was modified.**

---

## Verdict

**Not production-ready.** Three release blockers, four high-severity defects.

The route itself is registered correctly and its shell wiring is thoughtful — the branch layout, the `PopScope` back behaviour, and the reports sub-tree's deliberate §5.4 avoidance are all done well and documented. The problems are at the edges: **what guards it, what the platform hands it, and what it costs to re-enter.**

| # | Finding | Severity | Ships broken? |
|---|---|---|---|
| R-1 | Android App Link host is a hardcoded ngrok tunnel, no debug/release split | **BLOCKER** | **Yes — release** |
| R-2 | iOS debug entitlements point at the same ngrok tunnel | **BLOCKER** | Debug only |
| R-3 | `RoleState.role` defaults to `'admin'`; `/dashboard`'s fallback branch is `AdminDashboard` | **BLOCKER** | Latent, specific windows |
| R-4 | No router-level authorization beyond kiosk — role/module gating is UI-only across 49 dashboard sub-routes | High | Yes |
| R-5 | Returning to the Dashboard tab destroys the subtree and re-fires the full cold-open fetch (~41 calls) | High | Yes |
| R-6 | No `errorBuilder` / `onException` — an unmatched route shows go_router's red error screen in release | High | Yes |
| R-7 | Two kiosk-allowlist entries are unreachable: the blocklist prefix `/dashboard/staff` shadows them | High | Dead config |
| R-8 | Route paths duplicated between screen `routeName` statics and router string literals, unlinked | Medium | Latent |
| R-9 | 21 eager `..load()` calls in `GoRoute` builders (§5.4 double-fire) | Medium | Partly |
| R-10 | `redirect` is `async` and awaits storage on every navigation; logs every path via `debugPrint` in release | Medium | Yes |
| R-11 | 8 untyped `Map<String, dynamic>` / `{}` `extra` payloads originate in the dashboard | Medium | Yes |

---

## 1. Registration — correct

```dart
// app_router.dart:905-910
StatefulShellBranch(
  navigatorKey: dashboardBranchKey,
  routes: [
    GoRoute(
      path: AppRoutes.dashboard,                                  // '/dashboard'
      builder: (context, state) => const DashboardScreen(),
      routes: [ /* 48 more */ ],
    ),
  ],
),
```

Branch 0 of a `StatefulShellRoute.indexedStack` with 5 branches. **49 `GoRoute` entries live under `/dashboard`** — 39% of the app's 126 routes. `initialLocation` is `AppRoutes.splash`; `/dashboard` is never the app's first location.

Three things here are done right and should survive any refactor:

- **The nesting rationale is real** (`app_router.dart:895–903`). Every non-tab destination is a *child* of `/dashboard`, so `context.go('/dashboard/staff')` from `/dashboard/students` replaces the drill-down while keeping `/dashboard` beneath it. The stack stays `[Dashboard, drill-down]` no matter how many drawer items are tapped in a row.
- **The `PopScope`** (`app_router.dart:883–890`) — `canPop: navigationShell.currentIndex == 0`, otherwise `goBranch(0)`. System back from any non-dashboard tab root returns to the dashboard rather than closing the app.
- **The reports sub-tree explicitly avoids §5.4** (`app_router.dart:1070–1075`): *"there is no `..load()` in any of these builders, so back navigation re-runs nothing."* That is the correct pattern, already applied once in this file.

`DashboardScreen` uses `builder:` (default platform transition) rather than the file's `_fastPage` helper. Correct for a branch root.

---

## 2. R-1 / R-2 — Deep-link entry is pointed at a developer's ngrok tunnel

**`android/app/src/main/AndroidManifest.xml:66–83`** — committed, with the comment admitting it:

```xml
<!-- ...
     TEMP: host below points at Sairam's ngrok tunnel for local
     testing instead of uat-wowcare.childcarewow.app. Revert
     before commit — this manifest has no debug/release split. -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https"
          android:host="fitten-vallie-forthrightly.ngrok-free.dev" />
</intent-filter>
```

The comment states the constraint that makes this a release blocker: **the manifest has no debug/release split**, so this host ships to production. Consequences:

- `autoVerify="true"` will fail verification against a dead ngrok host, so Android App Links are **unverified** — every `https://uat-wowcare.childcarewow.app/...` link from an email or SMS opens the browser, never the app.
- Any link that *does* hit the ngrok host while it happens to be alive routes a production user through a developer's tunnel.

**`ios/Runner/Runner.entitlements:9–11`** — the same override, same "Revert before commit" comment:
```xml
<string>applinks:fitten-vallie-forthrightly.ngrok-free.dev</string>
```
iOS is better off: `Runner-Release.entitlements` correctly carries `applinks:uat-wowcare.childcarewow.app`, so **release iOS is fine and only debug iOS is broken**. Android has no equivalent split.

Last touched in commit `fa3126a6 "Navigation"`.

**Fix:** restore `uat-wowcare.childcarewow.app` in the manifest and in `Runner.entitlements`; add a manifest placeholder (`manifestPlaceholders`) or a debug `AndroidManifest.xml` under `android/app/src/debug/` so the split exists and this cannot recur.

### What deep links do *not* break

Worth recording because it is the good news: **deep links cannot bypass the auth check.** `flutter_deeplinking_enabled` is not set and the app consumes the platform URI itself via `AppLinks().getInitialLink()` (`lib/core/notifications/notification_launch_handler.dart:131–147`), stashing it in the `pendingNotificationDeepLink` global rather than letting go_router consume the platform route. So `initialLocation: AppRoutes.splash` always wins, the splash always runs, and `SplashCubit.resolve()` always reaches:

```dart
// splash_cubit.dart:391-394
} else {
  // No cached login: go to sign-in. Drop any pending deep-link so it can't
  // leak into a later authenticated session.
  consumePendingNotificationDeepLink();
  _safeEmit(state.copyWith(route: SplashRoute.signIn));
}
```

Dropping the pending link on the unauthenticated path is the right call and is correctly implemented.

---

## 3. R-3 — The unresolved-role fallback is the most privileged persona

Two independent defaults compound.

**`lib/shared/common/app/cubit/role_cubit.dart:13–20`:**
```dart
class RoleState extends Equatable {
  const RoleState({
    this.role = 'admin',        // ← default persona
    ...
  });
```

**`lib/presentation/features/dashboard/view/dashboard_screen.dart:70–74`:**
```dart
final Widget dashboard = role.isParent
    ? const ParentDashboard()
    : role.isStaff
    ? const StaffDashboard()
    : const AdminDashboard();   // ← fallback for every other value
```

`isParent` is `role == 'parent'`, `isStaff` is `role == 'staff'`. **Anything else — including the `'admin'` default, an unrecognised backend role, or an unresolved state — renders `AdminDashboard`**, whose coordinator constructor immediately fires `unawaited(initialize())` and ~26 requests against admin-only endpoints (school capacity, school FTE, school-wide attendance summaries, staff-document expiry, pending incident approvals).

`RoleCubit._bootstrap()` is asynchronous — it awaits `_computeFallbackRole(storage)` before its first emit, then awaits `refreshAccessFromServer()`. The default holds until the first emit lands.

**The specific windows where this is reachable:**

1. **After logout / session reset.** Both `clearRole()` (`:126`) and `resetSessionForLogout()` (`:134`) do `_safeEmit(const RoleState())` — which resets `role` to **`'admin'`**, not to a neutral value. Any render of `/dashboard` between that reset and the next successful resolution shows the admin dashboard.
2. **`refreshAccessFromServer()` failing.** The catch at `:202` is bare (`} catch (_) {}`), then `:210–211` re-emits `_computeFallbackRole`'s result. If storage is also cold, the fallback path can land back on the default.
3. **School switch**, where `DashboardScreen.onSchoolSwitched()` re-keys the subtree and the role may be mid-refresh.

In the normal cold-start path this is masked: the splash constructs `SplashCubit` with `roleCubit: context.read<RoleCubit>()` (`app_router.dart:467`) and calls `refreshAccessFromServer` before routing, so the role is resolved before `/dashboard` is reached. **That is a sequencing accident, not a guarantee** — nothing in `DashboardScreen` checks `RoleCubit.hasResolvedAccess`, which exists (`role_cubit.dart:100`) and is not read anywhere in the dashboard module.

**Impact when it does fire:** a guardian or teacher briefly sees admin-only UI, and the app issues ~26 requests they are not authorized for. They will 403, and every one of those failures lands in a card that renders zeros indistinguishable from real data (see `dashboard-baseline.md` §4.2–4.3), so the user sees a *plausible-looking* admin dashboard rather than an error.

**Fix:** add an `unknown`/`unresolved` role value as the `RoleState` default, gate `DashboardScreen` on `hasResolvedAccess` with a loading state, and make the `else` branch explicit rather than a fallthrough.

---

## 4. R-4 — Router-level authorization stops at kiosk

There is exactly **one `redirect:` in the entire router** (`app_router.dart:376`). It does two things:

1. **Kiosk containment** — `KioskAccessControl.isKioskModeActiveDirect()` (sync cache) with an async storage fallback and an on-demand construction fallback; if kiosk and the route is not allowlisted → `return '/kiosk'`.
2. **Billing persona rewrite** — a guardian landing on `/dashboard/billing` is rewritten to `/parent-billing`, preserving query params. Well-reasoned; the comment explains the killed-state notification race it exists to fix.

**There is no auth guard and no role/module guard.** No `redirect` on the shell, none on the `/dashboard` route, none on any of its 49 children. `lib/core/router/guards/` — the folder §3.1 asks for — does not exist; `lib/core/router/` contains only `app_routes.dart`, and that file declares `ReportRoutes` only.

So at the router level, **a parent can reach `/dashboard/staff`, `/dashboard/students`, `/dashboard/reports`, `/dashboard/scheduling` and 45 other admin surfaces.** The gating that actually happens is:

- `RoleCubit.canReadModule()` / `modulesWithRead` — consulted by the drawer and the bottom nav to *hide* entries.
- Per-screen checks inside the destination widgets.

That is defence by omission of a tap target. It does not survive a notification deep-link, a `context.go` from code, or the `pendingNotificationDeepLink` path — which is precisely the scenario the *billing* redirect was written to fix. The billing rewrite is the proof that this class of bug is live; it was fixed for one route out of 49.

`RoleCubit` is already reachable from the redirect (line 433 reads it), so the mechanism to fix this exists and is one route away from being generalised.

---

## 5. R-5 — Every return to the Dashboard tab pays the full cold-open cost

`dashboard_screen.dart` mixes in `TabBecameVisibleMixin` and re-keys its entire subtree on the signal:

```dart
// dashboard_screen.dart:46-54, 76-79
@override
void onTabBecameVisible() {
  if (!mounted) return;
  setState(() => _schoolReloadEpoch++);
}
// ...
return KeyedSubtree(
  key: ValueKey<int>(_schoolReloadEpoch),
  child: dashboard,
);
```

Changing the key destroys and rebuilds the whole subtree. That means a new `AdminDashboard`/`StaffDashboard`/`ParentDashboard` element → `initState` → `serviceLocator<XDashboardCoordinatorCubit>()`, which is a **`registerFactory`** (`di.dart:2123/2127/2131`) → a brand-new coordinator whose constructor calls `unawaited(initialize())` → **the full ~41-request admin fan-out runs again** (staff ~20, parent ~19).

`TabVisibilityEvents.notifyBranchActivated(0)` fires from **four** places:

| Trigger | Site |
|---|---|
| Switching to the Dashboard tab | `custom_navigation_bar.dart:278` |
| **Re-tapping the already-active Dashboard tab** | `custom_navigation_bar.dart:268` |
| Returning to the shell from a route pushed above it | `custom_navigation_bar.dart:300` |
| `appRouterGo('/dashboard')` — drawer, notification taps, deep links | `app_router.dart:2775` |

The second one is the sharpest: a user idly tapping the Dashboard icon while already on the dashboard issues ~41 requests per tap, with no debounce anywhere in the chain.

Secondary effects:
- `AutomaticKeepAliveClientMixin` on `MyChildsDayCard`, `StudentAttendanceCard` and `StudentNewslettersCard` is defeated — the keep-alive lives *inside* the subtree being discarded.
- `admin_dashboard.dart:260`'s `cacheExtent: 5000` forces every card to build at once on each re-key.
- In-flight requests from the previous coordinator complete into a closed cubit. No crash — `_updateState()` guards with `if (isClosed) return` and the child cubits guard their emits — but the work is wasted and the responses are discarded.

**This is a house pattern, not a dashboard invention** — `classroom_screen.dart:102–110` uses the identical trick and says so. The difference is cost: `ClassroomScreen` re-keys one cubit and the selected classroom's tab cards; `/dashboard` re-keys the app's entire fan-out point. The pattern exists because `StatefulShellRoute.indexedStack` keeps branches alive and nothing tells them to refresh — a real problem, solved with the bluntest available instrument.

**Fix:** replace the re-key with a targeted `coordinator.refresh()` on the existing instance. The coordinators already expose exactly that method, it is already wired to pull-to-refresh, and every child cubit already has an `_isFetching` guard and a silent-refresh mode. School switch is the one case that genuinely needs the subtree recreated; tab return is not.

---

## 6. R-6 — No 404 handling

```
grep -n "errorBuilder\|errorPageBuilder\|onException" lib/src/app_router.dart
→ (no matches)
```

The `GoRouter` is constructed with `navigatorKey`, `initialLocation`, `redirect` and `routes` only. Any unmatched location — a malformed deep link, a stale notification payload, a renamed route segment (see R-8) — renders go_router's default `ErrorScreen`: a red page with the raw exception and the attempted URI, **in release builds**. For an app whose primary entry point is a notification-carried URL, that is a user-visible crash surface.

**Fix:** add `errorBuilder` returning a branded "not found" that offers a route back to `/dashboard`, and `onException` to log to Crashlytics.

---

## 7. R-7 — Two kiosk allowlist entries can never match

`lib/presentation/features/kiosk/utils/kiosk_access_control.dart:145–171`:

```dart
static bool isRouteAllowedForKiosk(String route) {
  if (_isBlockedForKiosk(route)) {   // ← blocklist checked FIRST
    return false;
  }
  const allowedRoutes = [
    '/kiosk', '/kiosk/',
    '/staff-sign-in-form',
    '/staff-sign-out-form',
    '/dashboard/staff-sign-in-form',      // ← line 158
    '/dashboard/staff-sign-out-form',     // ← line 159
    ...
  ];
  return allowedRoutes.any((allowed) => route.startsWith(allowed));
}
```

and `_isBlockedForKiosk` (`:174–200`) contains the prefix `'/dashboard/staff'`.

`'/dashboard/staff-sign-in-form'.startsWith('/dashboard/staff')` → **`true`**. The blocklist runs first and returns `false` before the allowlist is ever consulted. **Lines 158–159 are unreachable.**

I traced the impact and it is **latent, not live**: the only navigator to those paths is `geofence_sign_in_sheet.dart:280–281`, which renders on `MyDayCard` for staff/admin personas and never for kiosk. Kiosk staff sign-in has its own routes under `/kiosk/staff-sign-in` (`app_router.dart:670`), which the blocklist does not touch. So no kiosk user is currently blocked from anything they need.

Two smaller companions in the same list: `'/staff-sign-in-form'` and `'/staff-sign-out-form'` (lines 156–157) match no registered route at all — the registered paths are `/dashboard/staff-sign-in-form` (`:728`) and `/attendance/staff-sign-in` (`:770`). They are the screens' own `routeName` statics, which the router does not use.

**Why it still matters:** this is a security allowlist where four of thirteen entries are dead, two of them because a blocklist silently shadows them. Anyone reading it will reasonably conclude those paths are reachable for kiosk. The correct shape is to check the allowlist first, or to make the blocklist patterns exact-segment rather than `startsWith`.

The other kiosk paths verify clean: `/dashboard/student-selection-sign-in-form`, `/dashboard/student-sign-in-out-selection` and `/dashboard/student-attendance-profile` are **not** shadowed by `'/dashboard/students'` — the next character is `-`, not `s`.

---

## 8. R-8 — Route paths have two unlinked sources of truth

Every destination the dashboard navigates to is declared **twice**: once as a `static const routeName` on the screen class (which the caller uses), and once as a bare string segment in the router (which registration uses). Nothing links them.

| Caller uses | Router registers | Linked? |
|---|---|---|
| `BillingScreen.routeName` = `'/dashboard/billing'` | `path: 'billing'` (`:1005`) | ❌ |
| `SchedulingScreen.routeName` = `'/dashboard/scheduling'` | `path: 'scheduling'` (`:1279`) | ❌ |
| `StaffSchedulingScreen.routeName` = `'/dashboard/staff-scheduling'` | `path: 'staff-scheduling'` (`:1315`) | ❌ |
| `IndividualMovementScreen.routeName` = `'/dashboard/individual-movement'` | `path: 'individual-movement'` (`:1361`) | ❌ |
| `FutureAvailabilityScreen.routeName` = `'/dashboard/future-availability'` | `path: 'future-availability'` (`:1356`) | ❌ |
| `ParentNewsletterScreen.routeName` = `'/dashboard/parent-newsletter'` | `path: 'parent-newsletter'` (`:1010`) | ❌ |
| `StudentAttendanceTabbedView.routeName` = `'/dashboard/student-attendance-tabbed-view'` | `path: 'student-attendance-tabbed-view'` (`:1445`) | ❌ |
| `StaffAttendanceTabbedView.routeName` = `'/dashboard/staff-attendance-tabbed-view'` | `path: 'staff-attendance-tabbed-view'` (`:1469`) | ❌ |
| `StudentAttendanceProfile.routeName` = `'/dashboard/student-attendance-profile'` | `path: 'student-attendance-profile'` | ❌ |
| `ClassroomOverviewScreen.routeName` | `path: ClassroomOverviewScreen.routeName` (`:531`) | ✅ |
| `AppRoutes.classroom` = `ClassroomScreen.routeName` | `path: AppRoutes.classroom` (`:1759`) | ✅ |

All of them currently resolve — I verified each. But **renaming a router segment leaves the caller's constant compiling and 404-ing at runtime**, and with no `errorBuilder` (R-6) that 404 is a red screen. `AppRoutes` itself lives in `app_router.dart:180–199`, not in `lib/core/router/app_routes.dart` where §3.3 puts it, and it covers only branch roots and auth screens — none of the 49 dashboard children.

Two nesting notes verified while tracing these:

- **`ClassroomOverviewScreen.routeName` = `/classroom-overview-screen` is a top-level route outside the shell** (`:531`, above the `StatefulShellRoute` at `:863`). `attention_grid.dart:197`'s `context.go(ClassroomOverviewScreen.routeName)` would therefore **replace the whole shell and drop the bottom nav**. It is dead in practice — `AttentionGrid` is only constructed in `admin_dashboard.dart:118` with all three tap callbacks supplied, so the `context.go` fallbacks never run — but it is a live hazard the moment the widget is reused without callbacks. The same applies to the `context.go('/activityFeed')` and `context.go('/dashboard/scheduling')` fallbacks in the same switch.
- **`ClassroomScreen` is branch 1 of the shell** (`:1759`), so the ratio card's `context.go('/classroom-screen?classroomCode=…&tab=2')` is a correct cross-branch jump. `ratio_monitoring_card.dart:74–82` documents why it also calls `ClassroomScreenNav.openClassroomTab` first — go_router only calls `didUpdateWidget` on an already-alive branch screen. That reasoning is sound.

---

## 9. R-9 — 21 eager loads in `GoRoute` builders

`docs/mandate-rules.md` §5.4: *"an `..load()` inside a `GoRoute` builder re-runs on every navigation to that route, including back navigation… This has already caused duplicate-call bugs in this codebase."*

**21 occurrences in `app_router.dart`**, 13 of them under the dashboard branch:

```
:551  NotificationCenterCubit()..loadInitial()
:920  StaffCubit()..loadInitial()                    ← /dashboard/staff
:924  ClassroomCubit()..loadActiveClassrooms(...)    ← /dashboard/staff
:985  StudentCubit()..loadInitial()                  ← /dashboard/students
:989  ClassroomCubit()..loadActiveClassrooms(...)    ← /dashboard/students
:1035 ClassroomCubit()..loadActiveClassrooms(...)    ← /dashboard/reports
:1042 StudentCubit()..loadInitial()                  ← /dashboard/reports
:1046 StaffCubit()..loadInitial()                    ← /dashboard/reports
:1050 ReportsCubit()..loadTags()                     ← /dashboard/reports
:1289 ..load()                                       ← /dashboard/scheduling
:1293 ClassroomCubit()..loadActiveClassrooms(...)    ← /dashboard/scheduling
:1333 ..loadIfNeeded()                               ← /dashboard/staff-scheduling
:1337 ClassroomCubit()..loadActiveClassrooms(...)    ← /dashboard/staff-scheduling
:1540 ..loadActiveClassrooms()
:1941 ..loadMetadata(schoolCode: args.schoolCode)
:1988 ..loadActivitySettings(...)
:2055 ..init(...)
:2113 ..init(...)
:2538 ..loadInitial(staffCode)
:2551 ..loadInitial(staffCode)
```

`ClassroomCubit()..loadActiveClassrooms(...)` alone appears **five times** across five sibling routes, each in its own `BlocProvider.create`, each a separate factory instance issuing the same request.

Mitigating: these sit inside `BlocProvider(create:)`, which runs once per element rather than once per build, and the dashboard branch's nesting means sibling drill-downs *replace* each other rather than stacking — so the common drawer-hopping path does re-create them. `:1333`'s `loadIfNeeded()` is the correct shape and shows the fix is understood locally. The reports sub-tree (`:1076–1277`) deliberately has none, with a comment explaining why.

**Not yet verified:** whether any of these produces an observable duplicate request today. Confirming it needs a network-call count on back navigation into each route, which I have not run. The pattern is the one §5.4 names; the specific call counts are unmeasured.

---

## 10. R-10 — The redirect is async, unconditional, and logs in release

```dart
// app_router.dart:376-405
redirect: (context, state) async {
  debugPrint('[GoRouter] Navigating to: ${state.uri.path} (name: ${state.name})');

  bool isKioskMode = KioskAccessControl.isKioskModeActiveDirect();
  if (!isKioskMode) {
    try {
      isKioskMode = await serviceLocator<KioskAccessControl>().isKioskModeActive();
    } catch (e) {
      try {
        AppLogger.w('[KioskAccess] KioskAccessControl not in DI, creating on demand');
        final kioskAccess = KioskAccessControl(serviceLocator<StorageService>());
        isKioskMode = await kioskAccess.isKioskModeActive();
      } catch (e2) { AppLogger.e('[KioskAccess] Error checking kiosk mode: $e2'); }
    }
  }
  ...
```

Three issues:

1. **`debugPrint` runs in release builds.** Unlike `assert`-guarded code, `debugPrint` is not stripped. Every navigation in production logs its path and route name to the device log.
2. **The redirect is `async` and the storage read is on the critical path.** For every non-kiosk user, `isKioskModeActiveDirect()` returns false and the `await` runs on *every single navigation* — go_router must await it before building. The sync cache exists precisely to avoid this (its own comment says *"Use synchronous cache check to avoid race conditions from multiple redirect() calls"*) but the negative result is not cached, so the fallback fires every time.
3. **The on-demand `KioskAccessControl` construction** is a DI-failure workaround inside a security guard. If `KioskAccessControl` is genuinely unregistered, both catches swallow and `isKioskMode` stays `false` — the guard **fails open**. For a containment control on a shared-device kiosk, failing open is the wrong default.

The billing branch below it reads `context.read<RoleCubit>()` inside a `try/catch` that leaves routing untouched on failure (`:444`) — correct and documented, but it means the rewrite silently does not apply if the redirect runs before providers mount.

---

## 11. R-11 — Untyped route arguments

§M1 requires typed route arguments — path parameters or a declared class through `extra`. The dashboard originates **8 untyped payloads**:

| Site | Payload |
|---|---|
| `admin_dashboard.dart:127` | `extra: <String, dynamic>{'timestamp': DateTime.now().millisecondsSinceEpoch}` |
| `ratio_monitoring_card.dart:348` | `extra: <String, dynamic>{'initialTabIndex': 0, 'classroomFilter': filter}` |
| `ratio_monitoring_card.dart:370` | same shape |
| `student_attendance_card.dart:76` | `extra: <String, dynamic>{'studentCode':…, 'studentId': 0, 'studentName':…, 'studentPhotoUuid': null, 'roomName':…}` |
| `QR_Code_scanner.dart:136` | `extra: <String, dynamic>{'signedInCodes':…, 'signedOutCodes':…, 'isQrScan': true, 'qrToken':…}` |
| `my_childs_day_card.dart:878` | `extra: <String, dynamic>{'signedInCodes':…, 'signedOutCodes':…}` |
| `enrollment_card.dart:184/234/290` | `extra: {'filter': filter, 'hasBackButton': true}` (×3) |

There is no `model/` folder in the dashboard feature to hold typed arg classes (see `dashboard-baseline.md` §2.1). The receiving ends cast blindly — `state.extra as Map<String, dynamic>?` at `:533`, `:502`, `:509` and similar. The router *does* have one good counter-example: `(state.extra as StaffListArgs?)?.statusFilter` at `:958`, and `ReportRoutes`' typed args carried into the reports sub-tree. The pattern exists; the dashboard does not use it.

`admin_dashboard.dart:125–128` is the odd one — it passes a `timestamp` through `extra` purely to force go_router to treat the navigation as new, with a comment noting *"ActivityFeedScreen currently does not support these query parameters natively, so this sets the convention."* A convention set by a route that does not read it.

---

## Recommended order

**Before any release:**
1. **R-1/R-2** — restore the real App Link host in `AndroidManifest.xml` and `Runner.entitlements`; add a debug/release manifest split so it cannot recur. One-line fixes; highest impact.
2. **R-3** — add an `unresolved` role default and gate `DashboardScreen` on `hasResolvedAccess`. Small, and it removes an accidental privilege escalation surface.
3. **R-6** — add `errorBuilder` + `onException`. ~20 lines.

**Next:**
4. **R-5** — swap the tab-return re-key for `coordinator.refresh()`. This is the single biggest runtime win available in the module and needs no new infrastructure.
5. **R-7** — reorder the kiosk allowlist/blocklist check and delete the four dead entries.
6. **R-4** — generalise the billing persona rewrite into a role guard covering the dashboard's 49 children. This is the largest piece and belongs with the §M1 work.

**With the Mandate 1 refactor:**
7. **R-8** — move all 49 dashboard paths into `lib/core/router/app_routes.dart` and register from those constants, deleting the screen-side `routeName` statics.
8. **R-11** — declare typed arg classes in a new `dashboard/model/` folder.
9. **R-9** — audit the 21 eager loads with before/after call counts, converting to `loadIfNeeded()` where a duplicate is confirmed.
10. **R-10** — cache the negative kiosk result, strip the `debugPrint`, and decide deliberately whether the kiosk guard should fail open or closed.
