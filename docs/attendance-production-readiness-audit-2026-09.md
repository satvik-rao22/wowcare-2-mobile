# ATTENDANCE MODULE — Production Readiness Re-Audit

**Date:** 2026-09-06 · **Type:** AUDIT ONLY (no code modified) · **Branch:** `audit/Report-Fixes` (HEAD `6edc876a`)
**Scope:** `lib/{data,domain,presentation}/features/attendance/**` — **209 files, 43,807 LOC**
**Standard:** `docs/mandate-rules.md` (WowCare 2.0 Eight Mandates) + MVVM golden rule `View → Cubit → UseCase → Repository → DataSource`
**Relationship to prior work:** this supersedes the status table in `docs/attendance-audit-report.md` (2026-08-27). Items that audit marked ✅ were re-verified against current code; several hold, two are **partial** and one has **regressed**.

**Confidence:** *CONFIRMED* = traced in code · *PROBABLE* = strong signal, not fully traced · *BACKEND* = not observable from the client.

---

## 1. Verdict

🟠 **NOT PRODUCTION READY** — but materially closer than the August audit.

**What genuinely improved (verified, not taken on trust):**

| Prior finding | Current state |
|---|---|
| PII/PIN → Crashlytics in release | ✅ **Confirmed fixed.** `AppLogger.d/i/w` are `kDebugMode`-gated no-ops ([logger_service.dart:24-46](lib/core/util/logger_service.dart#L24-L46)). Zero `debugPrint`/`print` remain in the module. |
| Write surface bypassed MVVM | ✅ **Largely fixed.** All 6 submit flows + both deletes route View→Cubit→UseCase. 4 residual breaches remain (§3.5). |
| `Map<String,dynamic>` domain contract | ✅ **Mostly fixed.** No raw-map params/returns on the repository contract. Residue in §3.8. |
| Zero automated tests | ✅ **Fixed.** 48 test files, **174 tests, all green** (`flutter test test/**/attendance` — 1m30s). |
| No idempotency keys | 🟡 **Partial — and the gap is the dangerous half.** See P0-1. |

**Blockers (must fix before release):**

1. **P0-1** — Mark-absent has neither an idempotency key nor 401-replay protection → silent duplicate absence records.
2. **P0-2** — Filter changes are silently discarded while a refresh is in flight → the list shows data that does not match the filter chips on screen.
3. **P0-3** — `loadNextPage` is not gated against `refresh` → pagination appends stale-filter rows into a refreshed list.

---

## 2. Production defects

### 🔴 P0-1 · Mark-absent can silently duplicate records — *CONFIRMED*

`markStudentsAbsent` / `markStaffAbsent` are POSTs that take **no** `idempotencyKey` parameter at all — the datasource signature does not accept one ([attendance_remote_datasource.dart:1531-1534](lib/data/features/attendance/datasources/attendance_remote_datasource.dart#L1531-L1534)). Only the 6 sign-in/out/transfer POSTs carry `Idempotency-Key` (lines 1825, 1850, 1870, 1893, 1916, 1936).

Compounding it: the app has a 401-refresh replay opt-out (`kNoAutoReplayExtraKey`, [session_expired_interceptor.dart:13](lib/core/network/session_expired_interceptor.dart#L13)). Activity, staff, student **and** billing datasources all set it on their mutations. **The attendance datasource sets it on none** — `grep 'extra:' attendance_remote_datasource.dart` returns nothing.

So for mark-absent both defences are absent simultaneously:

> A teacher marks a classroom of 22 absent. The access token expires as the POST is in flight. The interceptor refreshes and silently replays the identical body. The server has already committed the first write. **22 duplicate absence records**, no error shown, teacher sees success.

The same replay vector exists for the 6 submit flows, but there the `Idempotency-Key` header rides along on the replayed `RequestOptions`, so a dedupe-aware server absorbs it. *(Whether the server actually honours the header is **BACKEND** — unverifiable here, and worth confirming before relying on it.)*

**Fix:** thread an `idempotencyKey` through mark-absent exactly as the submit flows do, and set `kNoAutoReplayExtraKey` on every attendance mutation. Both are additive and behaviour-neutral.

### 🔴 P0-2 · Filter changes silently dropped mid-refresh → UI/data divergence — *CONFIRMED*

[student_attendance_daily_cubit.dart:181](lib/presentation/features/attendance/view_model/student_attendance_daily_cubit.dart#L181):

```dart
Future<void> refresh({ ... }) async {
  if (state.isRefreshing) return;   // ← discards the new criteria entirely
```

Every filter change routes through this method with the new criteria ([student_attendance_daily_view.dart:419-427](lib/presentation/features/attendance/view/screens/student_attendance_daily_view.dart#L419-L427)). The re-entrancy guard returns *before* the new `classroomCodes`/`tagCodes`/`search` are recorded anywhere — they are not queued, not stored, not retried.

The filter state itself lives in the widget's `State` via `setState` ([`_selectedClassroomNames`, `_showAbsentOnly`, `_signInAtFilter`](lib/presentation/features/attendance/view/screens/student_attendance_daily_view.dart)), so the chips repaint immediately with the new selection:

> Teacher taps "Toddler Room" on a slow connection while the previous refresh is still running. Chip reads **Toddler Room**. List still shows **every classroom**. No spinner, no error — the screen looks settled and is wrong. On an attendance screen this is a safety-relevant misread: staff count heads against a list that isn't the list they asked for.

Same pattern in `student_attendance_custom_cubit`, `staff_attendance_daily_cubit`, and the absent-toggle cubits.

**Fix:** store the latest requested criteria and re-run once the in-flight call settles (last-write-wins), or drop the guard in favour of a request-generation token that discards stale responses.

### 🔴 P0-3 · Pagination race corrupts the list — *CONFIRMED*

[student_attendance_daily_cubit.dart:348](lib/presentation/features/attendance/view_model/student_attendance_daily_cubit.dart#L348):

```dart
if (state.isLoading || state.isLoadingMore || !state.hasMore) return;   // isRefreshing not checked
```

`loadNextPage` reads its filters from `state` at call time, then on completion appends via `state.copyWith(items: [...state.items, ...page.items])` — reading `state` **again**, after the await.

> Scroll triggers page 1. Pull-to-refresh (or a filter change) lands `refresh()`, which resets `items` to a fresh page 0. The page-1 response then appends rows fetched under the *old* filters onto the *new* list, and sets `currentPage: 1` — so the next scroll fetches page 2 and **page 1 of the new filter set is never loaded**. Result: duplicated rows, foreign rows, and a permanently skipped page.

**Fix:** add `isRefreshing` to the guard and capture/compare a request generation before the append emit.

### 🟠 P1-1 · Idempotency key reused across an *edited* payload — *CONFIRMED*

[student_sign_in_submit_cubit.dart:141-152](lib/presentation/features/attendance/forms/student_attendance_forms/view_model/student_sign_in_submit_cubit.dart#L141-L152) generates one key, holds it across failures, clears it on success. Correct for a plain retry — but the key is keyed to the *cubit*, not to the payload:

> Submit fails (validation, network). The user removes a student or corrects the sign-in time and submits again. Same `Idempotency-Key`, **different body**. A conforming dedupe server replays the *first* response and never applies the correction — the user is told it succeeded, with the wrong data stored.

**Fix:** rotate the key whenever the request payload differs from the one it was minted for (hash the payload, or reset on any form mutation).

### 🟠 P1-2 · Non-atomic absence-delete → sign-in sequence — *CONFIRMED*

[`clearTodaysAbsenceRecordsBeforeSignIn`](lib/presentation/features/attendance/forms/student_attendance_forms/view_model/student_sign_in_submit_cubit.dart#L64) deletes each student's absence record, then the caller POSTs the sign-in. There is no compensating action.

> Deletions succeed, sign-in POST fails. The student is now **neither absent nor present** — silently erased from the day's attendance. On a licensed-ratio childcare record that is a compliance gap, not a cosmetic one.

The lookup failure path is deliberately best-effort and documented; the *partial-success* path is not handled.

**Fix:** restore deleted absence records on sign-in failure, or move the whole override to a single server-side transaction.

### 🟠 P1-3 · Summary counts blank out on a transient failure — *CONFIRMED*

In `loadInitial`'s cache-hit path, if `_getStudentAttendanceExpectedSummaryUseCase` throws, the catch emits `StudentAttendanceDailyState.loaded(...)` **omitting** `expectedCount`/`presentCount`/`absentCount`/`signedOutCount`/`notMarkedCount` ([:144-163](lib/presentation/features/attendance/view_model/student_attendance_daily_cubit.dart#L144-L163)). Those fields are nullable with no default ([state:50](lib/presentation/features/attendance/view_model/student_attendance_daily_state.dart#L50)), so the header summary renders empty where numbers were — with no error surfaced. A blank "Present" count reads as "not loaded yet" or as zero, both misleading.

### 🟡 P2-1 · 16 silent `catch (_) {}` blocks

Of 151 catch blocks in the module, 16 discard the error entirely — including inside submit paths ([student_sign_out_form.dart:131,142,303](lib/presentation/features/attendance/forms/student_attendance_forms/student_sign_out_form.dart#L131), [staff_sign_in_form.dart:311](lib/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_in_form.dart#L311), [student_mark_absent_cubit.dart:52,67](lib/presentation/features/attendance/forms/student_attendance_forms/view_model/student_mark_absent_cubit.dart#L52)). Some are legitimately best-effort; none are distinguishable from a swallowed defect in production because nothing reaches Crashlytics. At minimum route them through `AppLogger.c` so a breadcrumb survives.

### 🟡 P2-2 · Client-supplied authorization scope — *BACKEND*

`_mergeAllowedClassroomCodes` ([:447-455](lib/data/features/attendance/datasources/attendance_remote_datasource.dart#L447-L455)) still has the client compute and send its own `allowedClassroomCodes`, sourced from `SharedPreferences`. Unchanged since the August audit and correctly deferred there — the real fix is server-side (derive scope from the token). **Flagged as a release gate:** if the backend does not independently enforce classroom scope, this is an IDOR and the verdict escalates to 🔴. Get that confirmed in writing before shipping.

---

## 3. Mandate compliance

| # | Mandate | Status | Evidence |
|---|---|---|---|
| 1 | GoRouter everywhere | 🔴 **Fail** | **91** `Navigator.*`/`MaterialPageRoute` refs across 20+ files. **Zero** attendance routes in `app_routes.dart` — the module navigates entirely outside GoRouter. Includes untyped results: `Navigator.push<Map<String,dynamic>?>` ([staff_attendance_daily_view.dart:1260](lib/presentation/features/attendance/view/screens/staff_attendance_daily_view.dart#L1260)). |
| 2 | setState scarcely | 🔴 **Fail** | **190** `setState` calls. Highest: `student_attendance_absent_view` (19), `student_attendance_daily_view` (14), `staff_attendance_daily_view` (14), `staff_attendance_profile` (13). Most are Bucket A (filters, dates, API results) — and P0-2 is the direct consequence. |
| 3 | Folder structure | 🟠 **Partial** | `view/`, `view_model/`, `widgets/` correct. But a non-canonical **`util/`** folder exists (7 files — explicitly disallowed), a non-canonical **`forms/`** tree (57 files) sits outside the four permitted folders, and there is no `model/` folder. |
| 4 | Centralized theming | 🔴 **Fail** | **392** `Color(0x…)`/`Colors.<name>` literals. Worst: `staff_attendance_profile` (32), `student_attendance_profile` (28), `student_attendance_custom_view` (18). 9 inline `TextStyle(`, 1 residual `fontFamily`. *(The 14 presentational widgets tokenised in August did hold — the debt is concentrated in screens/forms, exactly where the prior audit said the sweep was left "optional".)* |
| 5 | Presentation talks to cubits only | 🟠 **Partial** | Big improvement, 4 breaches left: 3 cubits take `AttendanceRepository` directly instead of a use case ([student_attendance_daily_cubit:23](lib/presentation/features/attendance/view_model/student_attendance_daily_cubit.dart#L23), `student_attendance_custom_cubit:19`, `staff_edit_attendance_cubit:24`); a view calls a use case directly ([student_attendance_profile.dart:473](lib/presentation/features/attendance/view/student_attendance_profile.dart#L473)); `serviceLocator` appears in 5 view/widget sites outside a `GoRoute` builder; and `attendance_school_time.dart` reaches for `serviceLocator<ApiClient>()` from presentation. |
| 6 | Reuse; ≤400 lines | 🔴 **Fail** | **24 files over 400 lines**, up to **2,026** (`attendance_remote_datasource`), 1,865 (`attendance_repository_impl`), 1,649 (`attendance_popup`), 1,628 / 1,579 / 1,502 in views. ✅ `Widget _buildXxx()` is fully eliminated (0 remaining). ❌ **`student_override_sign_in_form.dart` is 511 lines of entirely commented-out code** referencing the dead `schoolerp` package — zero classes, zero references. Mandate 6 says delete it. |
| 7 | One responsive source | 🟠 **Partial** | 14 `MediaQuery.of(` vs **0** `MediaQuery.sizeOf(` — every one re-runs on keyboard open. 2 `LayoutBuilder`s; the `maxWidth < 300` in [attendance_card_shared.dart:203](lib/presentation/features/attendance/view/screens/widgets/attendance_card_shared.dart#L203) is a legitimate box-relative keep. |
| 8 | Models generated, never raw maps | 🟠 **Partial** | ✅ Repository contract is map-free. ❌ **0 `.g.dart` files and 0 `@JsonSerializable`** in the module — all serialization is still hand-written, which is the mandate's central requirement. Residual maps: domain entities expose `toPayload() → Map<String,dynamic>` (a wire-payload builder living in `lib/domain`), `postStudentSignIn` and its 5 siblings return `Future<Map<String,dynamic>?>` to the repository, and presentation still type-probes `value is Map<String,dynamic>` on time fields in 3 places. |

---

## 4. Static analysis & tests

**`flutter analyze` on the three attendance directories: 23 issues** — 22 unused-import warnings + 1 `unnecessary_import`. Zero errors.

This is a **regression** against the prior audit's "2 pre-existing non-error issues". The pattern is diagnostic: 8 unused form imports in `staff_attendance_tabbed_view`, 4 each in `staff_attendance_profile` and `student_attendance_vertical_pop_up`, 4 in the `*_selection_*_form` files. Form screens were re-wired and the old imports were left behind — cheap to fix, but it means the module is being edited without an analyze gate.

**Tests: 174 passing, 48 files.** Genuinely good coverage of models (fromJson fidelity), use cases, submit/delete cubits, and widget smoke + responsive-overflow tests at 375/768/1024. **The gap is exactly where the P0s live:** no test drives `refresh` re-entrancy, `loadNextPage` concurrency, or mark-absent replay. Every P0 in §2 is reproducible in a unit test.

---

## 5. Recommended order

**Before release:**

1. **P0-1** — idempotency key + `kNoAutoReplayExtraKey` on mark-absent (and the flag on all attendance mutations). Additive, behaviour-neutral, ~1h.
2. **P0-3** — add `isRefreshing` to the `loadNextPage` guard. One line + a regression test.
3. **P0-2** — coalesce the dropped filter refresh. Contained to 4 cubits.
4. **P2-2** — get written backend confirmation that classroom scope and `x-school-code` are enforced server-side. **This is the release gate**; without it the verdict is 🔴.
5. **P1-1 / P1-2 / P1-3** — key rotation on payload change, absence-restore compensation, summary-count fallback.

**Then, mandate debt (not release-blocking):**

6. Delete `student_override_sign_in_form.dart` and clear the 23 analyzer warnings — 30 minutes, and it restores the analyze gate.
7. Mandate 4 sweep on screens/forms (392 literals) — mechanical, and the widget-layer precedent already exists.
8. Mandates 1 + 5 as a pair (per `mandate-rules.md`'s revised order), then 2, then 6's file-size splits.
9. Mandate 8's `json_serializable` migration last — highest risk, and `mandate-rules.md` requires an old-vs-new fixture test per parser before any hand-written parser is deleted. The 174 existing tests make this tractable; do not start it before the P0s ship.

---

*Audit performed against working tree at `6edc876a` with the `audit/Report-Fixes` modifications present. No attendance files were modified.*
