# STUDENT MODULE — STEP 2: STATE MANAGEMENT (AUDIT + PROGRESS)

> Branch `audit/student-fixes`. Goal: every Student business/application state has ONE
> authoritative owner (View → Cubit → State). **Scope chosen: Phases 1 → 2 → 3** (form-screen
> migration, Phase 4, deferred). This doc is the resumable checkpoint.

## AUDIT — 174 live `setState` (1 commented-out), by category
| Cat | Meaning | Count | Action |
|---|---|---|---|
| A | Business/application | 5 | migrate |
| B | Server/API state in widget | 48 | migrate |
| C | Loading | 54 | migrate |
| D | Filtering/sorting | 9 | migrate |
| E | Pagination | 0 | — (list already uses StudentCubit) |
| F | Selection | 7 | migrate |
| G | Form/validation | 43 | migrate (Phase 4, deferred) |
| H | Genuine local UI micro-state | 8 | **KEEP** |

**Keep-as-H (8) — justified local UI, do NOT migrate:**
- `student_screen.dart:1229,1241` — attendance/activities panel toggles
- `student_action_panel.dart:118,568` — panel open/close
- `student_profile_tab.dart:77`, `student_health_tab.dart:64` — empty listener rebuilds
- `student_health_tab.dart:140` — `_isImmunizationExempt` view-only toggle
- `student_card.dart:210` — `isExpanded` card expand/collapse

## PLAN
- **Phase 1 — god-view `student_screen.dart` (26 migrate).** Filter (`_currentFilters`/`_showInactive`, D) → cubit (the KNOWN ISSUE); selection (`_selectedDemo`/`_selectAll`, F) → cubit; loading (C) → cubit; server counts/maps/attendance-status (B) → cubit.
- **Phase 2 — async-state model.** Collapse `isLoading`/`isRefreshing`/`isLoadingMore` in `StudentState` into one status enum so loading/refresh/error/success can't race.
- **Phase 3 — tab-card server state (B, ~18).** The `Future + setState` refresh pattern (family/pickup/physician/immunization/health/dates cards, `student_profile_tab`) → cubit-owned list state (as `StudentPhysicianCubit.load()` already models).
- **Phase 4 (DEFERRED)** — form screens (G+C, ~60). Keep `TextEditingController`s local; move validation/submit/business-model into per-editor form cubits.

## DONE (verified: analyze clean — no new issues, all student tests pass)

### Phase 2 — async-state model ✅ (done)
`StudentState` now has a single `StudentListStatus { loading, refreshing, loadingMore, loaded, error }`
replacing the `isLoading`/`isRefreshing`/`isLoadingMore` booleans (kept as **derived getters** →
zero widget/test churn). All 10 `StudentCubit` emit sites map to one `status`; the empty-list-vs-refresh
combo is a ternary (`items.isEmpty ? loading : refreshing`). Concurrency guard stays on the
`isRefreshing` getter, backstopped by `_generation` — validated by the generation-guard / single-flight
/ pagination-dedup / search-debounce tests (all green).

### Phase 3 — tab-card server state → cubit (IN PROGRESS)
**Done + verified: ALL 6 tab cards** — physician, pickup, family, dates, immunization, health.
Each cubit lacking list state gained `items`/`isLoading` + `load({forceRefresh})`; cards render via
BlocBuilder; count/limit checks read `state`; family's 4 refreshes → one `_reload()`; dates keeps its
derived `_disableAddPhysicalExam` off `state.exams`; `StudentHealthCubit` now holds BOTH `health` and
`immunizations` (each card instance loads its half); the health card's optimistic `photoPermission`
(category A) is kept, synced from `state.health` via a `BlocConsumer` listener.
**Also done + verified:** `student_profile_screen._healthFuture` (header allergy/med/diet/photo icons) →
`StudentProfileCubit` gained `health`/`healthLoading` + `loadHealth()`; screen renders `state.health`
via BlocBuilder; `_refreshHeaderHealth` + parent-child-switch route through `loadHealth`.

**Phase 3 remaining = 1 documented exception (deferred, not a clean Step-2 move):**
`student_profile_tab._profileFuture` reads `StudentRemoteDataSource.getStudentProfile` **directly** for
the rich `StudentProfileModel` (status/dob/address/tags/fte/…). The domain `StudentProfile` entity is a
narrow projection, so this is a documented **MVVM holdout pending entity enrichment (S6 typed-models)** —
migrating it to cubit state requires enriching the entity first (separate task), so it stays as-is.
(Per card: adding `flutter_bloc` makes any `provider` import redundant → drop it; drop the entity
import once the explicit `List<X>`/`FutureBuilder<...>` types are gone.)

**Pattern (verified on physician + pickup):**
widget holds the cubit instance → `initState`/refresh call `cubit.load(code)` → `FutureBuilder` becomes
`BlocBuilder<XCubit, XState>(bloc: _cubit, ...)` reading `state.items/isLoading/errorMessage`; the
`_xFuture` field + `_buildXFuture()` + `setState` refresh are deleted. Mutations already call the
card's refresh (→ `load()`).
- **Note for the remaining cards:** physician's cubit already had a state-holding `load()` (dual path).
  The others (`student_health_tab_card`, `student_immunization_tab_card`, `student_dates_tab_card`,
  `student_family_tab_card`, `student_pickup_tab_card`, `student_profile_screen` `_healthFuture`,
  `student_profile_tab` `_profileFuture`) mostly expose only **Future** reads, so each needs a
  `list + isLoading + errorMessage` added to its state + a `load()` method **before** the same
  widget conversion. Do one cubit+card at a time, verifying analyze + that cubit's test each time.

### Phase 1 — filters + selection ✅ (done)
Known-issue **foundation** — `StudentCubit`/`StudentState` are now the single owner of the filter
selection + inactive toggle (additive, backward-compatible; widget not yet wired, so no regression):
- `student_state.dart` — added `Map<String,List<String>> selectedFilters` (default `{'Status':['Active']}`) and `bool showInactive` (constructor, `.initial()`, fields, `copyWith`, `props`).
- `student_cubit.dart` — `updateFilters(...)` now also stores `selection` + `showInactive`; new `setSelectedFilters(selection, {showInactive})` for selection-only updates.

## PHASE 1 PROGRESS
- ✅ **Filters (KNOWN ISSUE) — DONE & verified.** `student_screen` `_currentFilters`/`_showInactive` removed; now getters over `StudentCubit.state` (`selectedFilters`/`showInactive`). All writes route through `_applyFiltersToCubit(selection)` / `setSelectedFilters`. Analyzer clean, 105 tests pass.
- ✅ **Selection — DONE & verified.** `_selectedDemo`/`_selectAll` removed; `selection` now in `StudentState`; `selectAll` DERIVED. Cubit methods: `resizeSelection`, `setRowSelected`, `setSelectAll`, `clearSelection`. Analyzer clean, tests pass.
- ⏳ **Loading (C, ~3)** — `_isAttendanceActionLoading`, `_attendanceStatusLoading/_attendanceStatusError`. NOTE: these are transient *attendance-action* feedback, and there is no attendance-action cubit here; migrating into `StudentCubit` would conflate attendance loading with list loading. Recommend KEEP-with-justification unless an attendance-action owner is introduced.
- ⏳ **Server maps (B, ~13)** — `_tagNameToCode`, `_guardianNameToCode`, `_activeCount`/`_upcomingCount`, the 5 attendance-summary counters, `_attendanceStatusByStudentCode`, `_classroomNameByDetailApi`, `_classroomDetailFetchFailed`. Server-derived lookups held in the widget. Moving to `StudentCubit` is the right architecture (would also let the cubit self-resolve filter codes, dropping the widget's name→code logic) but adds ~13 state fields + relocates ~8 fetch methods — a large addition. Do as a focused pass.

## REMAINING (resume here)
**Phase 1 — filters ✅ + selection ✅ + counts/summary ✅ done. Remaining god-view server maps:**
- **Counts + attendance summary ✅ DONE** — `StudentState` gained `activeCount`/`upcomingCount`/
  `expectedTotal`/`expectedSignedIn`/`expectedAbsent`/`expectedSignedOut`/`expectedNotMarked`;
  `StudentCubit` gained **optional** `countsUseCase`/`expectedSummaryUseCase` deps (nullable +
  no-op load when absent, so the 4 test constructions still compile; DI passes them) and
  `loadCounts()`/`loadExpectedSummary()`; the two summary `LayoutBuilder`s read via
  `context.watch<StudentCubit>().state`. Pattern for the rest of the maps.
- **Name→code maps ✅ DONE & verified** — `StudentState` gained `tagNameToCode`/`guardianNameToCode`
  (`Map<String,String>`, default `{}`; constructor/`.initial()`/fields/`copyWith`/`props`);
  `StudentCubit` gained **optional** `tagNameCodeMapUseCase`/`guardianNameCodeMapUseCase` deps (nullable +
  no-op when absent) and `loadTagNameCodeMap()`/`loadGuardianNameCodeMap()`; `di.dart` passes both
  (already-registered use cases). Widget: removed the two fields + both `_load*NameCodeMap` fetch methods;
  the three call sites now invoke the cubit methods (via the in-scope `cubit`/`studentCubit`); the
  `_applyFiltersToCubit` resolution reads `context.read<StudentCubit>().state.tagNameToCode` /
  `.guardianNameToCode`. Removed now-unused imports (both use cases + `StorageService` + `StorageKeys`).
  Analyzer clean, **93 student tests pass**.
- **Attendance status ✅ DONE & verified** — `StudentState` gained `attendanceStatusByStudentCode`
  (`Map<String,String>`) + `attendanceStatusLoading`/`attendanceStatusError` (bools). `StudentCubit`
  gained **optional** `attendanceStatusUseCase` dep + `refreshAttendanceStatusForSelection()` which
  computes the selected codes from its OWN state (`selection` × `items`) — so the widget passes nothing.
  `di.dart` wires the already-registered `GetStudentTodaySignInStatusMapUseCase`. Widget: removed the 3
  fields + the whole fetch method (now a thin `Future<void>` delegator, no arg); the 6 call sites drop the
  `students` arg; `_todayStatusForStudentCode` + the two `attendanceStatusLoading/Error` gate checks read
  `context.read<StudentCubit>().state` (all inside the `BlocBuilder<StudentCubit>` → reactive). Removed the
  now-unused use-case import. Analyzer clean, **93 student tests pass**.
- **Classroom-name resolution ✅ DONE & verified** — `StudentState` gained `classroomNameByDetailApi`
  (`Map<String,String>`) + `classroomDetailFetchFailed` (`Set<String>`). `StudentCubit` gained **optional**
  `classroomByCodeUseCase` dep + `ensureClassroomDetailNames(students, cubitNameByCode)` (fingerprint-guarded,
  per-code in-flight + failed dedup as PRIVATE cubit fields — not emitted state, like `_inFlightMutations`)
  and `clearClassroomDetailCache()`. `di.dart` wires the already-registered `GetClassroomByCodeUseCase`.
  Widget: removed 5 fields (`_getClassroomByCode`, `_classroomNameByDetailApi`, `_classroomDetailFetchInFlight`,
  `_classroomDetailFetchFailed`, `_lastClassroomPrefetchFingerprint`) + both fetch methods (~60 lines);
  `_mergedClassroomDisplayNames` reads `state.classroomNameByDetailApi`; the build call site invokes
  `studentCubit.ensureClassroomDetailNames(...)` directly (no post-frame wrapper — the cubit's first `emit`
  is post-`await`, safe from build); the refresh's `setState(clear failed + reset fingerprint)` → one
  `studentCubit.clearClassroomDetailCache()`. Removed the now-unused use-case import. Analyzer clean,
  **93 student tests pass**.

### ✅ PHASE 1 — GOD-VIEW SERVER MAPS COMPLETE
All of `student_screen`'s server-derived state now lives in `StudentCubit`/`StudentState`: filters +
selection, the async status enum, counts + attendance summary, tag/guardian name→code maps, per-row
attendance status, and classroom-name resolution. The only category-B/C holdouts left are the transient
**attendance-action** flags (`_isAttendanceActionLoading`, and the row-action feedback) — KEPT-with-
justification (no attendance-action owner here; migrating would conflate with list state). Phase 4 (form
screens) remains deferred.
- **Loading (C, ~3)** — `_isAttendanceActionLoading`, `_attendanceStatusLoading/Error`: keep local
  with justification (transient attendance-action feedback; no attendance-action cubit here), OR move
  if an attendance-action owner is introduced.

**Then Phase 2** (async state), **then Phase 3** (tab-card server state). Verify each with `flutter
analyze` + student tests. Phase 4 (form screens) remains deferred.

### RISK NOTES surfaced on close inspection (read before resuming)
- **Phase 2 is NOT a naive boolean-collapse.** In `StudentState`/`StudentCubit`, the three booleans
  encode **two orthogonal concerns**: `isLoading` = *display* (full-screen loader, true at init +
  when `items.isEmpty`), `isRefreshing` = *concurrency guard* (`student_cubit.dart:227` blocks a
  second concurrent `refresh()`), `isLoadingMore` = pagination. At construction `isLoading=true` but
  `isRefreshing=false` so `loadInitial()`'s first `refresh()` is allowed; at `refresh()` start
  (cubit:251) BOTH `isLoading`(=items.isEmpty) and `isRefreshing`(=true) are set. A single mutually
  exclusive `status` enum can't represent that combo — merging breaks EITHER the initial loader OR
  the guard. Correct fix: a **display `status` enum** PLUS a **separate in-flight/concurrency flag**
  (or reuse `_generation`), not a collapse. Do it with device testing; the cubit tests
  (generation-guard / single-flight / pagination-dedup / search-debounce) are the safety net.
- **Phase 1 server-maps needs plumbing:** relocating `_loadStudentCounts` /
  `_loadExpectedStudentsSummary` / name→code maps into `StudentCubit` requires injecting
  `GetStudentCountsUseCase` + `GetStudentAttendanceExpectedSummaryUseCase` (+ tag/guardian usecases).
  Add them as **optional** ctor deps (nullable, `serviceLocator` fallback) to avoid breaking the 4
  test files that build `StudentCubit(...)`, or update `di.dart` + those tests. Also the counts/legend
  header is NOT under a `BlocBuilder<StudentCubit>` — wrap it (or keep `setState` as a rebuild trigger).
