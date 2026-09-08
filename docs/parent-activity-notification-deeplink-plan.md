# Parent activity notification deep-link — "No Activities found" flash & multi-child mis-scoping

**Status:** implemented, except Step 4 (see §8).
**Scope:** guardian/parent persona tapping an ACTIVITY_* notification that routes to
`AppRoutes.activityFeed`.

---

## 1. What the user reports

Tapping an activity notification as a parent lands on the Activity Feed, which shows
**"No Activities found"** first, and only then starts loading the list. With more than
one child linked, the feed can additionally settle on the **wrong child** (or briefly show
the wrong child's day) before correcting itself.

---

## 2. Current implementation (traced)

### 2.1 Where the destination is built

`lib/presentation/features/notifications/routing/notification_route_resolver.dart:406`
`_activityParams()` puts three things on the URL:

| param | source | consumed by |
|---|---|---|
| `date` | `_kActivityDate` (`activityMarkedDate`, … → school-calendar `yyyy-MM-dd`) | `highlightDate` |
| `classroomCode` | `_kClassroom` | `highlightClassroomCode` (staff branch only) |
| `studentCode` | `studentCodeFor(n)` | **only the remount `ValueKey`** |

Plus `highlightCode` (`cardGroupCode ?? … ?? activityCode`).

### 2.2 Three different entry paths

| Path | Who navigates | Does it call `ParentChildCubit.selectByCode`? |
|---|---|---|
| App in foreground / background (FCM tap) | `notification_navigator.dart:96` | **Yes** |
| In-app Notification Center row tap | `notification_center_screen.dart:354` | **Yes** |
| **Killed state / cold launch** | `splash_cubit.dart:320` → `splash_screen.dart:95` `context.go(deepLink)` | **No** |

### 2.3 What the route builder does

`lib/src/app_router.dart:2162-2213` — reads `highlightCode`, `date`, `classroomCode`,
`studentCode`; `studentCode` feeds **only** `activityFeedDeepLinkKey(...)`
(`app_router.dart:3429`) so the branch remounts. It is **not** passed to
`ActivityFeedScreen`, which has no `studentCode` parameter
(`activity_feed_screen.dart:26-38`), and the parent branch builds
`ActivityDailyTab(isNotParent: false, …)` with only `highlightCode` + `highlightDate`
(`activity_feed_screen.dart:400-405`).

**Consequence:** the subject child is carried *exclusively* by `ParentChildCubit`.

### 2.4 What the Daily tab does on mount (parent branch)

`activity_daily_tab.dart`:

```
initState (1903)
  └─ addPostFrameCallback:
       await _bootstrapSchoolZone()      // storage + possible API (timezone)
       await _bootstrap()                // 4 storage reads, then…
            └─ _bootstrapParentHome()    // sets _loadingParentContext = true HERE
                 ├─ await resolveGuardianCodeForLoggedInUser()   // network
                 ├─ await _feedScope.getStudentPage(size: 500)   // network
                 ├─ narrow to ParentChildCubit.selectedChild (1143)
                 └─ await _loadDailyFeed(refresh: true)          // network
```

Display gates (`activity_daily_tab.dart:2641` portrait-sliver and `:3512` the second
layout):

```dart
if ((_displayedLoadingFeed || _loadingParentContext) && _displayedActivities.isEmpty)
   → loader
if (!_displayedLoadingFeed && !_loadingParentContext && _displayedActivities.isEmpty)
   → _displayedFeedError ?? 'No Activities found'
```

`_displayedLoadingFeed` = `_effectiveFeedState.isLoading`, and `_effectiveFeedState`
falls back to `ActivityFeedState.initial()` — `isLoading: false` — until the cubit is
lazily created inside the first `_loadDailyFeed` (`activity_daily_tab.dart:342`,
`activity_feed_state.dart:50`).

---

## 3. Root causes

### RC-1 — Empty state renders before anything is marked "loading" *(this is the flash)*

Between first paint and `_bootstrapParentHome` setting `_loadingParentContext = true`,
**both** flags are `false` and `items` is empty → the second gate matches → *"No Activities
found"*. That window is not one frame: it spans `_bootstrapSchoolZone()` (storage +
timezone API) and four `_bootstrap()` storage reads. On a cold notification launch it is
comfortably visible, and it is followed by the loader, then the list — exactly the reported
sequence.

Same shape exists in `activity_custom_tab.dart:2579`.

### RC-2 — The deep-link's student is a remount key, not a scoping input

`studentCode` never reaches the tab. `_bootstrapParentHome:1143` reads
`ParentChildCubit.selectedChild` instead. So correctness depends on *two independent things
agreeing*: the URL key and the cubit's selection. The resolver's own doc comment
(`notification_route_resolver.dart:392-405`) acknowledges this coupling.

### RC-3 — Cold launch never selects the notified child

The killed-state path (`splash_screen.dart:95`) goes straight to the deep link. Nothing
calls `selectByCode`, so `ParentChildCubit._resolveSelection` falls through its normal
precedence — persisted selection, else first child. **A parent with two children who taps
child B's notification from a killed app lands on child A's feed**, with no later
correction (the URL's `studentCode` is inert).

### RC-4 — Warm path double-loads, and can show the wrong child in between

`selectByCode` is synchronous only when `state.isLoaded` is true
(`parent_child_cubit.dart:576`). It is **not** loaded when the tap crossed a school switch
— `notification_navigator.dart:71` awaits `switchActiveSchoolIfNeeded` *before* selecting,
which resets the cubit. In that case the selection is deferred, so:

1. tab mounts → `_bootstrapParentHome` narrows to the **previous** child (or, if
   `selectedChild` is null, keeps **all** children — `:1143` only narrows when the code is
   non-empty) → fetch #1
2. cubit later emits child B → `build`'s `context.watch` (`:2391`) → post-frame
   `_syncWithGlobalChildSelection` (`:1211`) → re-scope → fetch #2

The user sees empty → wrong/merged list → correct list.

### RC-5 — Every deep link pays the full parent bootstrap

The `ValueKey` change destroys the State, so `_parentClassroomByStudentCodeAll` (the cache
that lets `_syncWithGlobalChildSelection` switch children *without* refetching, `:1216`)
is empty on arrival. Two network round-trips (guardian code + 500-student page) run before
the feed request is even built — this is the bulk of the perceived delay.

### RC-6 — `_loadingParentContext` doesn't cover the pre-bootstrap and re-scope windows

It is set true only inside `_bootstrapParentHome` and cleared before `_loadDailyFeed`
(`:1174`), and `_syncWithGlobalChildSelection`'s classroom-cached fast path never sets it
at all. So the same "no flag true, no items" hole reopens on a child switch.

---

## 4. Proposed fix

### Step 1 — Never render "No Activities found" before a load has been attempted *(fixes RC-1)*

Add a State flag, e.g. `bool _feedEverAttempted = false`, set to `true` at the top of
`_loadDailyFeed` / `_loadParentHomeDailyFeed` (both branches, including the not-ready
early-return). Change the two empty-state gates in `activity_daily_tab.dart` (`:2641`/`:2668`
and `:3512`/`:3521`) to:

- loader when `!_feedEverAttempted || _displayedLoadingFeed || _loadingParentContext`
- empty text only when `_feedEverAttempted && !loading && items.isEmpty`

Keep the error branch as-is: `_displayedFeedError` should still render immediately when
bootstrap fails (school not selected, guardian profile failed) — those are real terminal
states, not "not started yet".

Mirror in `activity_custom_tab.dart:2579`.

*Alternative considered:* set `_loadingParentContext = true` in `initState` for
`_parentHome`. Rejected — it doesn't cover the staff branch, and it lies about a flag whose
name means "parent bootstrap running". The `_feedEverAttempted` latch covers both personas
with one rule.

### Step 2 — Thread the deep-link student into the tab *(fixes RC-2, most of RC-4)*

1. `app_router.dart:2162` — pass `deepLinkStudentCode: student` into `ActivityFeedScreen`
   (new nullable field) alongside the existing key usage.
2. `activity_feed_screen.dart` — forward it to the parent-branch `ActivityDailyTab`
   (`:400`) as `deepLinkStudentCode`.
3. `activity_daily_tab.dart` `_bootstrapParentHome` (`:1141-1155`) — resolve the target as:

   ```
   widget.deepLinkStudentCode (if it is in _parentAllowedStudentCodes)
     ?? ParentChildCubit.selectedChild?.code
   ```

   The membership check against the freshly-fetched guardian student page is the
   authorization gate — an unowned code from a forged payload is ignored and we fall back
   to the selected child. This mirrors `ParentChildCubit`'s own "filtered through the
   loaded child list" contract, so no new trust is introduced.
4. Seed `_lastGlobalSelectedStudentCode` with the resolved code so the post-frame
   `_syncWithGlobalChildSelection` (`:1211`) sees no change and does **not** fire fetch #2.

Result: the feed is correct on the first fetch regardless of whether the cubit has caught
up, and the cubit's later emit is a no-op for the feed.

### Step 3 — Select the notified child on the cold-launch path *(fixes RC-3)*

In `splash_screen.dart:95` (`SplashRoute.dashboardOrDeepLink`), after
`_switchSchoolForLaunch` and before `context.go(deepLink)`: if the persona is a guardian
and the deep link carries `studentCode`, call
`context.read<ParentChildCubit>().selectByCode(code)`.

Parse the code from the URI rather than re-resolving the payload — the payload is no
longer in hand at that point, and `NotificationRouteResolver` already wrote its decision
into the URL.

This is still worth doing even with Step 2, because it fixes the **global** dropdown /
app bar / every other parent screen, not just the feed. Step 2 fixes the feed; Step 3 fixes
the app's idea of "current child". Both are needed.

*Placement note:* keep it in the splash view (which has the `BuildContext` with the cubit),
not in `SplashCubit`, matching how `_switchSchoolForLaunch` is already handled there.

### Step 4 — Make the child switch not re-bootstrap *(improves RC-5)*

`_bootstrapParentHome` currently narrows `_parentStudentClassroomByCode` to one child but
keeps the full map in `_parentClassroomByStudentCodeAll`. That cache dies with the remount.
Two options, in order of preference:

- **4a (recommended):** hoist the guardian→students map out of the tab State. It is already
  fetched by `ActivityFeedScopeCubit.getStudentPage`; cache it per `schoolCode` there (or in
  the existing `CacheManager`) so a remount hits memory instead of the network. Keeps the
  ownership check of Step 2 cheap and synchronous on the second deep link.
- **4b:** reuse `ParentChildCubit.children` (which already carries `code` + `classroom` +
  `classroomCode`) to seed `_parentStudentClassroomByCode` optimistically, and let the
  student-page fetch refine it in the background. Fewer moving parts, but only helps once
  the cubit is loaded.

### Step 5 — Close the remaining loading-flag holes *(RC-6)*

Set `_loadingParentContext = true` (or reuse the Step-1 latch) around
`_syncWithGlobalChildSelection`'s cached fast path (`:1216-1240`) so a child switch shows
the loader rather than momentarily falling into the empty branch.

### Step 6 — Don't fan out to all children when the subject is unknown

`_bootstrapParentHome:1143` narrows only `if (globalSelectedCode.isNotEmpty)`. With Step 2
the code is almost always known; for the residual case, prefer the **first** child
deterministically over querying all of them, so the first paint is one child's day rather
than a merged list that then shrinks.

---

## 5. Files to touch

| File | Change |
|---|---|
| `lib/presentation/features/activities/view/activity_daily_tab.dart` | Steps 1, 2(3–4), 5, 6 |
| `lib/presentation/features/activities/view/activity_custom_tab.dart` | Step 1 (mirror) |
| `lib/presentation/features/activities/view/activity_feed_screen.dart` | Step 2 (forward param) |
| `lib/src/app_router.dart` | Step 2 (pass `studentCode` as a param, not only into the key) |
| `lib/presentation/features/splash/view/splash_screen.dart` | Step 3 |
| `lib/presentation/features/activities/view_model/activity_feed_scope_cubit.dart` | Step 4a (optional) |

`notification_route_resolver.dart` needs **no change** — it already emits `studentCode`,
`date` and `classroomCode` correctly. The bug is entirely on the consuming side.

---

## 6. Tests

Existing: `test/src/activity_feed_deep_link_key_test.dart` covers the remount key.

Add:

1. **Empty-state gate** — widget test on the parent Daily tab: pump one frame with no load
   started, assert a loader and **no** "No Activities found"; complete the load with zero
   rows, assert the empty text appears.
2. **Deep-link student wins** — `ParentChildCubit` selected = child A, `deepLinkStudentCode`
   = child B (owned) → the guardian query is issued for B, and exactly **one** feed fetch
   occurs.
3. **Unowned code is ignored** — `deepLinkStudentCode` = a code not on the guardian student
   page → falls back to the selected child, no request for the foreign code.
4. **Cold launch selects the child** — splash routes to
   `/dashboard/activityFeed?studentCode=STU_B&…` as a guardian → `ParentChildCubit`
   selection becomes STU_B.
5. **No double fetch on the cubit's later emit** — deferred `selectByCode` resolving to the
   same child the deep link already applied must not trigger a second
   `loadDailyForGuardian`.

## 7. Manual verification matrix

Parent with **two** children, notification about child B, child A currently selected:

| App state | Expect |
|---|---|
| Foreground | loader → child B's day, no empty flash, one fetch |
| Background | same |
| Killed / cold start | same, **and** the app-bar switcher reads child B |
| Notification Center row tap | same |
| Cross-school notification (multi-school parent) | school switches, then all of the above |
| Second notification, other child, same day | remount → child A's day, no stale rows |
| Genuinely empty day | loader → "No Activities found" (correct, once) |

---

## 8. What was actually implemented

| Step | Status | Where |
|---|---|---|
| 1 — never show the empty state before a load is attempted | done | `activity_feed_display_rules.dart`, both tabs |
| 2 — thread the deep-link student into the tab | done | router → screen → tab |
| 3 — select the notified child on cold launch | done | `splash_screen.dart` |
| 4 — cache the guardian→students map across remounts | **not done** | see below |
| 5 — hold the loader across a child switch | done | `_syncWithGlobalChildSelection` |
| 6 — always narrow to one child | done | `resolveGuardianFeedStudentCode` |

Two rules were extracted as pure functions into
`lib/presentation/features/activities/utils/activity_feed_display_rules.dart` so the
Daily and Custom tabs share one definition and the behaviour is unit-testable without
building a widget tree or a DI graph:

* `shouldShowActivityFeedLoadingPlaceholder(...)` — the loader-vs-empty-state decision.
* `resolveGuardianFeedStudentCode(...)` — the child-precedence decision, including the
  ownership filter and the deep-link one-shot.

Covered by `test/presentation/features/activities/utils/activity_feed_display_rules_test.dart`
(12 tests).

**Step 4 was deliberately left out.** It is a latency optimisation, not part of the
reported defect: the two bootstrap round-trips still run on every deep link, they are just
now spent behind a loader instead of behind a false "No Activities found". Doing it
properly means moving the guardian→students map out of the tab's `State` (option 4a), which
is a wider refactor than this fix warrants and is better done on its own.

### One design point worth recording

`_bootstrapParentHome` now calls `ParentChildCubit.selectByCode(targetCode)` after
resolving the child. That is what keeps the feed and the app-bar switcher from disagreeing,
and it is also what stops the double fetch: `_syncWithGlobalChildSelection` compares the
cubit's selection against `_lastGlobalSelectedStudentCode`, so pushing the resolution into
the cubit makes both sides hold the same code and the post-frame sync becomes a no-op
instead of re-scoping to the previously selected child.

The deep-link student is consumed **once** (`_deepLinkStudentApplied`, mirroring the
existing `_deepLinkClassroomApplied`). Without that latch, the re-bootstrap triggered when
a user picks a child whose classroom isn't cached would resolve back to the notification's
child and fight the dropdown the user had just used.

---

## 9. Follow-up: the empty state was still leaking (second pass)

The first pass gated the empty state on `_feedEverAttempted` — "has a load ever been
started". That closed the cold-mount window but **not** the one users actually hit most:

`ActivityDailyTab` is `AutomaticKeepAliveClientMixin` inside the shell's `IndexedStack`, so
once Activities has been visited its `State` is reused. `activityFeedDeepLinkKey` only
forces a remount when the target actually differs (and returns null entirely when the
payload carries no `highlightCode`), so a deep link frequently lands on the **existing**
State — where `_feedEverAttempted` was already `true` and the previous visit's completed,
possibly empty, result was still on screen. `didUpdateWidget` applied the new date/room and
then called `_loadDailyFeed`, but the frame in between rendered the stale answer:
**empty → loader → list**, exactly as reported.

A second, smaller leak: `_markFeedAttempted()` was being called *before* the not-ready
guard, so any early caller (`didUpdateWidget` on a deep-link rebuild, the
`ActivityFeedInvalidation` stream, a child switch) unlocked the empty state mid-bootstrap.

### The corrected rule

The latch now tracks **whether the rows on screen answer the scope currently being asked
about**, not whether a load ever happened:

* `_feedResultIsCurrent` starts `false`.
* `_beginFeedLoad()` clears it **synchronously, before the load's first `await`**, so no
  frame can be painted between deciding to reload and the placeholder going up.
* `_endFeedLoad()` sets it when a fetch completes — on the error path too, since an errored
  load is still a completed one and the message branch renders the error.
* `didUpdateWidget` clears it inside the same `setState` that applies the new deep-link
  target, which is what covers the reused keep-alive State.
* The de-dupe early returns (`_lastFeedRequestKey == requestKey`) call `_endFeedLoad()`:
  the rows already on screen *are* the answer for that scope.
* The not-ready early returns deliberately do **not**. "Not ready" means the school, day or
  child map is still resolving — precisely when the loader must hold. This cannot spin
  forever because every genuine dead end (no school selected, guardian profile
  unresolvable, no linked children, no classrooms) sets `_feedError`, which the display
  rule treats as terminal.

Applied identically to the Daily and Custom tabs, and to both the staff and guardian
branches within each. The shared rule's parameter is renamed `feedEverAttempted` →
`hasCurrentResult` to match.

The Custom tab's `_bootstrapParentHome` also now goes through `resolveGuardianFeedStudentCode`
so it narrows to one child instead of fanning out over all of them when the dropdown
selection hasn't resolved — the same merged-list-then-shrink flash the Daily tab had.
