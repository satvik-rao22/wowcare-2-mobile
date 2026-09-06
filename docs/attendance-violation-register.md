# ATTENDANCE MODULE — Traced Violation Register

**Date:** 2026-09-06 · **Branch:** `audit/Report-Fixes` @ `6edc876a` · **Type:** AUDIT ONLY (no code modified)
**Scope:** `lib/{data,domain,presentation}/features/attendance/**` — 209 files, 43,807 LOC
**Companion documents:** `docs/attendance-production-readiness-audit-2026-09.md` (findings and verdict) · `docs/attendance-audit-report.md` (2026-08-27, superseded status table) · `docs/mandate-rules.md` (the standard)

This document is the line-level evidence behind the audit: **every** occurrence of every violation class, grouped by file. It is generated from the working tree, not transcribed.

---

## How to read this

**Comment-only matches are excluded from every table below.** This matters — the module contains a 511-line file that is entirely commented out (`student_override_sign_in_form.dart`), plus scattered commented blocks elsewhere, and a naive `grep` counts them as live code.

The audit's headline figures were raw grep counts. The live counts are lower, and both are given here so the difference is visible rather than quietly corrected:

| Violation class | Raw grep | **Live code** | In comments |
|---|---|---|---|
| M1 · `Navigator` / `MaterialPageRoute` | 91 | **76** | 15 |
| M2 · `setState(` | 190 | **185** | 5 |
| M4a · hardcoded colours | 392 | **379** | 13 |
| M4b · inline `TextStyle(` | 9 | **1** | 8 |
| M7 · `MediaQuery.of(` | 14 | **13** | 1 |
| M8 · `Map<String, dynamic>` in domain/presentation | 31 | **15** | 16 |
| Silent `catch (_) {}` | 16 | **16** | 0 |

The inline-`TextStyle` figure is the one that changes materially: **8 of the 9 were inside the dead file, leaving a single live occurrence.** Mandate 4's `TextStyle` clause is effectively already satisfied. The colour clause is not.

Deleting `student_override_sign_in_form.dart` alone removes 27 apparent violations across four mandates without touching a line of live code.

---

## Register contents

| Part | Class | Live count | Files |
|---|---|---|---|
| A | Runtime defects (P0/P1/P2) | 8 | — |
| B · M1 | GoRouter everywhere | 76 | 21 |
| B · M2 | setState scarcely | 185 | 23 |
| B · M4a | Hardcoded colours | 379 | 51 |
| B · M4b | Inline `TextStyle` | 1 | 1 |
| B · M4c | Residual `fontFamily` | 1 | 1 |
| B · M5a | `serviceLocator` — hard violations | 7 | 5 |
| B · M5b | `serviceLocator` — cubit construction | 47 | 28 |
| B · M5c | Cubit depends on Repository | 6 | 3 |
| B · M5d | `StorageService` in presentation | 49 | 26 |
| B · M5e | `ApiClient` / `Dio` / `SharedPreferences` | 21 | 11 |
| B · M7 | `MediaQuery.of(` | 13 | 12 |
| B · M8 | `Map<String, dynamic>` residue | 15 | 14 |
| B | Silent `catch (_) {}` | 16 | 11 |
| C | Analyzer issues | 23 | 15 |
| C | Files over 400 lines | 24 | — |

Mandates 3 and 6 are structural rather than per-line and are traced in Part A.

---

# Part A — Runtime defects

These are not mandate violations; they are defects that corrupt or misreport attendance data. Each was traced through the call chain, not pattern-matched.

## P0-1 · Mark-absent can silently duplicate records

| | |
|---|---|
| **Severity** | P0 — release blocker |
| **Confidence** | CONFIRMED (client side); server dedupe behaviour is BACKEND |

**Trace:**

1. `data/features/attendance/datasources/attendance_remote_datasource.dart:1531` — `markStudentsAbsent({required MarkAbsentRequestModel request, required List<String> allowedClassroomCodes})`. The signature accepts **no** `idempotencyKey`.
2. `:1540` — `await _client.post<dynamic>(endpoint, data: {...})`. No `Options`, therefore no `Idempotency-Key` header and no `extra` map.
3. `:1558` — `markStaffAbsent` — identical shape, identical gap.
4. `core/network/session_expired_interceptor.dart:13` — `const String kNoAutoReplayExtraKey = 'noAutoReplay'` marks a request unsafe to replay after a 401 refresh.
5. `:105-109` — a request replays unless it set that key.
6. `grep 'extra:' attendance_remote_datasource.dart` → **no matches**. The attendance datasource opts out of nothing.

**Comparison — every other mutating datasource sets the flag:**

- `data/features/activity/datasources/activity_remote_datasource.dart`
- `data/features/staff/datasources/staff_remote_datasource.dart`
- `data/features/student/datasources/student_remote_datasource.dart`
- `data/features/billing/datasources/invoice_remote_datasource.dart`
- `shared/services/image_upload/image_upload_service.dart`

Attendance is the only one missing, and it is the module where a duplicate write is a licensed-ratio record.

**Failure scenario:** a teacher marks a classroom of 22 absent; the access token expires in flight; the interceptor refreshes and silently replays the identical body; the server has already committed the first write. 22 duplicate absence records, no error surfaced, success shown.

**Coverage:** the 6 sign-in/out/transfer POSTs *do* carry `Idempotency-Key` (`:1825, :1850, :1870, :1893, :1916, :1936`), so on those the replay is absorbable by a dedupe-aware server. Mark-absent has neither defence.

**Fix:** thread `idempotencyKey` through mark-absent exactly as the submit flows do, and set `kNoAutoReplayExtraKey` on every attendance mutation. Both additive and behaviour-neutral.

## P0-2 · Filter changes silently dropped mid-refresh

| | |
|---|---|
| **Severity** | P0 — release blocker |
| **Confidence** | CONFIRMED |

**Trace:**

1. `presentation/features/attendance/view/screens/student_attendance_daily_view.dart:419` — a filter change calls `_cubit.refresh(attendanceDate:, classroomCodes:, tagCodes:, signInAtFilter:, signOutAtFilter:, isExpectedNotMarked:, search:)` with the **new** criteria.
2. `presentation/features/attendance/view_model/student_attendance_daily_cubit.dart:181` — `refresh` opens with `if (state.isRefreshing) return;`.
3. The guard returns **before** the criteria are recorded anywhere — they are not queued, not stored on state, not retried.
4. The filter values themselves live in the widget's `State` (`_selectedClassroomNames`, `_selectedTagNames`, `_showAbsentOnly`, `_signInAtFilter`, `_signOutAtFilter`, `_selectedDate`) and are committed by `setState`, so the chips repaint immediately.

**Failure scenario:** on a slow connection the chip reads "Toddler Room" while the list still shows every classroom. No spinner, no error — the screen looks settled and is wrong. Staff counting heads against that list are reading a roster they did not ask for.

**Same pattern, same defect:**

- `view_model/student_attendance_custom_cubit.dart`
- `view_model/staff_attendance_daily_cubit.dart`
- `view_model/staff_attendance_custom_cubit.dart`
- `view_model/student_attendance_absent_toggle_cubit.dart`
- `view_model/staff_attendance_absent_toggle_cubit.dart`

**Root cause:** Mandate 2. The filters are Bucket A business state sitting in a `StatefulWidget`, so the widget and the cubit hold two copies of the truth and only one of them updated.

**Fix:** store the latest requested criteria and re-run once the in-flight call settles (last-write-wins), or replace the guard with a request-generation token that discards stale responses.

## P0-3 · Pagination race corrupts the list

| | |
|---|---|
| **Severity** | P0 — release blocker |
| **Confidence** | CONFIRMED |

**Trace:**

1. `view_model/student_attendance_daily_cubit.dart:348` — `if (state.isLoading || state.isLoadingMore || !state.hasMore) return;`. **`isRefreshing` is not in the guard.**
2. `:356-367` — filters are read from `state` at call time and passed to the use case.
3. `:375` — on completion it emits `state.copyWith(items: [...state.items, ...page.items], currentPage: page.page, ...)` — reading `state` **again**, after the await.

**Failure scenario:** a scroll triggers page 1; a pull-to-refresh or filter change lands `refresh()`, which resets `items` to a fresh page 0. The page-1 response then appends rows fetched under the *old* filters onto the *new* list and sets `currentPage: 1`, so the next scroll fetches page 2 — **page 1 of the new filter set is never loaded.** Duplicated rows, foreign rows, and a permanently skipped page.

**Fix:** add `isRefreshing` to the guard and compare a captured request generation before the append emit.

## P1-1 · Idempotency key reused across an edited payload

| | |
|---|---|
| **Severity** | P1 |
| **Confidence** | CONFIRMED (client); depends on server dedupe semantics |

**Trace:** `presentation/features/attendance/forms/student_attendance_forms/view_model/student_sign_in_submit_cubit.dart`

- `:36` — `String? _idempotencyKey;` held on the **cubit**, not derived from the payload.
- `:141` — `_idempotencyKey ??= IdempotencyKey.generate();`
- `:147` — cleared only on success.

Correct for a plain retry. But a failed submit followed by an **edited** resubmit — the user removes a student or corrects the sign-in time — sends a different body under the same key. A conforming dedupe server replays the first response; the correction is never applied and the user is told it succeeded.

**Same shape:** `student_sign_out_submit_cubit`, `student_transfer_submit_cubit`, `staff_sign_in_submit_cubit`, `staff_sign_out_submit_cubit`, `staff_transfer_submit_cubit`.

**Fix:** rotate the key whenever the payload differs from the one it was minted for.

## P1-2 · Non-atomic absence-delete then sign-in

| | |
|---|---|
| **Severity** | P1 — compliance-relevant |
| **Confidence** | CONFIRMED |

**Trace:** `.../view_model/student_sign_in_submit_cubit.dart:64` — `clearTodaysAbsenceRecordsBeforeSignIn`

- `:71-92` — paginates the absent-form list. A lookup failure is deliberately best-effort (`:85` logs and returns).
- `:127` — `await _deleteStudentAbsenceRecordUseCase(...)` per student, in a loop.
- The caller then POSTs the sign-in. **There is no compensating action.**

The lookup-failure path is handled and documented; the **partial-success** path is not. Deletions succeed, sign-in fails, and the student is neither absent nor present — silently removed from the day's attendance record.

**Fix:** restore deleted absence records on sign-in failure, or move the override into a single server-side transaction.

## P1-3 · Summary counts blank out on a transient failure

| | |
|---|---|
| **Severity** | P1 |
| **Confidence** | CONFIRMED |

**Trace:** `view_model/student_attendance_daily_cubit.dart`

- `:108` — on a cache hit, `_getStudentAttendanceExpectedSummaryUseCase(forceRefresh: true)` is awaited.
- `:144-163` — its `catch` emits `StudentAttendanceDailyState.loaded(...)` **omitting** `expectedCount`, `presentCount`, `absentCount`, `signedOutCount` and `notMarkedCount`.
- `view_model/student_attendance_daily_state.dart:50` — those fields are nullable with no default.

The header summary renders empty where numbers were, with no error surfaced. A blank "Present" count reads as either "still loading" or "zero" — both misleading on an attendance screen.

**Fix:** retain the previous counts and mark them stale, or surface the failure.

## P2-1 · Silent `catch (_) {}` blocks

**16 live occurrences of 151 catch blocks.** Full list in Part B. Several sit inside submit paths. Some are legitimately best-effort, but none are distinguishable from a swallowed defect in production, because `AppLogger.d` is a release no-op and nothing reaches Crashlytics.

**Fix:** route each through `AppLogger.c` so a breadcrumb survives, even where suppression is intended.

## P2-2 · Client-supplied authorization scope

| | |
|---|---|
| **Severity** | P2 client-side — **release gate** overall |
| **Confidence** | BACKEND — not observable from a client codebase |

**Trace:** `data/features/attendance/datasources/attendance_remote_datasource.dart:447`

```dart
void _mergeAllowedClassroomCodes(Map<String, dynamic> queryParameters, List<String> allowedClassroomCodes) {
  if (allowedClassroomCodes.isEmpty) return;
  queryParameters['allowedClassroomCodes'] = List<String>.from(allowedClassroomCodes);
}
```

Called at `:535, :1455, :1480, :1496, :1521` and throughout the list endpoints. The client computes and transmits its own authorization scope, sourced from `SharedPreferences`. Unchanged since the August audit and correctly deferred there — the real fix is server-side, deriving scope from the token.

**This is the release gate.** If the backend does not independently enforce classroom scope, it is an IDOR and the verdict escalates to 🔴. Obtain written confirmation before shipping.

---

## Mandate 3 — folder structure (structural)

| Violation | Detail |
|---|---|
| Non-canonical `util/` folder | `presentation/features/attendance/util/` — **5 files**. The mandate states a presentation `util/`/`utils/` folder should not exist: pure business rules belong in `domain/.../usecases/`, mappers in `data/.../mappers/`, helpers in `widgets/` or `core/extensions/`. |
| Non-canonical `forms/` tree | `presentation/features/attendance/forms/` — **66 files**, outside the four permitted folders (`model/`, `view/`, `view_model/`, `widgets/`). This tree holds screens, entities and cubits mixed together. |
| Missing `model/` folder | Does not exist. Route-arg and screen-param classes have nowhere canonical to live — which is also why M1's route arguments are untyped. |
| Entity classes in presentation | `forms/student_attendance_forms/student_entity.dart`, `.../tag_entity.dart`, `forms/staff_attendance_forms/staff_entity.dart`. "Entities never live in presentation." |

## Mandate 6 — reuse and file size (structural)

| Violation | Detail |
|---|---|
| Files over 400 lines | **24**, peaking at 2,026. Full list in Part C appendix. |
| Fully commented-out file | `presentation/features/attendance/forms/student_attendance_forms/student_override_sign_in_form.dart` — **511 lines, zero live classes, zero references anywhere in `lib/`.** Its imports still name the pre-rename `schoolerp` package. "Delete commented-out code rather than keeping it." |
| `Widget _buildXxx()` methods | **0 remaining** — ✅ the August remediation held. |

---

# Part B — Mandate violations, traced

## M1 — GoRouter everywhere, MaterialPageRoute nowhere

**76 live occurrences across 21 files** (91 raw, 15 of them in commented-out code). Zero attendance routes are registered in `lib/core/router/app_routes.dart`, so every one of these is an unrouted navigation. `Navigator.pop` entries are included because they return values that drive refreshes — those results must survive the GoRouter migration.

**`presentation/features/attendance/forms/staff_attendance_forms/staff_mark_absent_form.dart`** — 2

| Line | Code |
|---|---|
| 81 | `Navigator.of(context).maybePop();` |
| 107 | `listener: (context, _) => Navigator.pop(context),` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_sign_in_form.dart`** — 6

| Line | Code |
|---|---|
| 158 | `Navigator.of(context).pop();` |
| 533 | `if (Navigator.of(context).canPop()) {` |
| 534 | `Navigator.of(context).popUntil((route) => route.isFirst);` |
| 541 | `if (Navigator.of(context).canPop()) {` |
| 542 | `Navigator.of(context).pop();` |
| 556 | `Navigator.pop(context);` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_sign_out_form.dart`** — 5

| Line | Code |
|---|---|
| 509 | `if (Navigator.of(context).canPop()) {` |
| 510 | `Navigator.of(context).popUntil((route) => route.isFirst);` |
| 517 | `if (Navigator.of(context).canPop()) {` |
| 518 | `Navigator.of(context).pop();` |
| 533 | `Navigator.pop(context);` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_transfer_form.dart`** — 2

| Line | Code |
|---|---|
| 442 | `Navigator.of(context).pop();` |
| 473 | `Navigator.pop(context);` |

**`presentation/features/attendance/forms/student_attendance_forms/student_mark_absent_form.dart`** — 2

| Line | Code |
|---|---|
| 95 | `Navigator.of(context).pop();` |
| 126 | `listener: (context, _) => Navigator.pop(context),` |

**`presentation/features/attendance/forms/student_attendance_forms/student_selection_mark_absent_form.dart`** — 2

| Line | Code |
|---|---|
| 184 | `Navigator.push(` |
| 186 | `MaterialPageRoute(` |

**`presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_in_form.dart`** — 2

| Line | Code |
|---|---|
| 256 | `Navigator.push(` |
| 258 | `MaterialPageRoute(` |

**`presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_out_form.dart`** — 2

| Line | Code |
|---|---|
| 221 | `Navigator.push(` |
| 223 | `MaterialPageRoute(` |

**`presentation/features/attendance/forms/student_attendance_forms/student_selection_transfer_form.dart`** — 2

| Line | Code |
|---|---|
| 326 | `Navigator.push(` |
| 328 | `MaterialPageRoute(` |

**`presentation/features/attendance/forms/student_attendance_forms/student_sign_in_form.dart`** — 6

| Line | Code |
|---|---|
| 151 | `Navigator.of(context).pop();` |
| 159 | `Navigator.pop(context);` |
| 453 | `Navigator.of(context).pop();` |
| 461 | `if (Navigator.of(context).canPop()) {` |
| 462 | `Navigator.of(context).popUntil((route) => route.isFirst);` |
| 510 | `if (isGpsParentDisabled && mounted) Navigator.of(context).pop();` |

**`presentation/features/attendance/forms/student_attendance_forms/student_sign_out_form.dart`** — 4

| Line | Code |
|---|---|
| 119 | `Navigator.pop(context);` |
| 423 | `Navigator.of(context).pop();` |
| 430 | `if (Navigator.of(context).canPop()) {` |
| 431 | `Navigator.of(context).popUntil((route) => route.isFirst);` |

**`presentation/features/attendance/forms/student_attendance_forms/student_transfer_form.dart`** — 2

| Line | Code |
|---|---|
| 220 | `Navigator.pop(context);` |
| 395 | `Navigator.of(context).pop();` |

**`presentation/features/attendance/util/attendance_redirect.dart`** — 1

| Line | Code |
|---|---|
| 16 | `final navigator = Navigator.of(context);` |

**`presentation/features/attendance/view/screens/staff_attendance_daily_view.dart`** — 4

| Line | Code |
|---|---|
| 1074 | `Navigator.of(ctx).pop();` |
| 1183 | `Navigator.of(ctx).pop();` |
| 1260 | `final result = await Navigator.push<Map<String, dynamic>?>(` |
| 1262 | `MaterialPageRoute(` |

**`presentation/features/attendance/view/screens/student_attendance_daily_view.dart`** — 4

| Line | Code |
|---|---|
| 1223 | `Navigator.of(ctx).pop();` |
| 1318 | `Navigator.of(ctx).pop();` |
| 1459 | `final result = await Navigator.push<Map<String, List<String>>>(` |
| 1461 | `MaterialPageRoute(` |

**`presentation/features/attendance/view/staff_attendance_tabbed_view.dart`** — 1

| Line | Code |
|---|---|
| 454 | `Navigator.pop(context);` |

**`presentation/features/attendance/view/student_attendance_profile.dart`** — 2

| Line | Code |
|---|---|
| 512 | `await Navigator.push(context, MaterialPageRoute(builder: (_) => target!));` |
| 769 | `Navigator.of(context).pop(),` |

**`presentation/features/attendance/widgets/attendance_popup.dart`** — 19

| Line | Code |
|---|---|
| 663 | `Navigator.of(` |
| 726 | `Navigator.of(` |
| 790 | `Navigator.of(` |
| 854 | `Navigator.of(` |
| 926 | `Navigator.of(` |
| 989 | `Navigator.of(` |
| 1053 | `Navigator.of(` |
| 1118 | `Navigator.of(` |
| 1218 | `final navigator = Navigator.of(context, rootNavigator: true);` |
| 1266 | `Navigator.push(` |
| 1268 | `MaterialPageRoute<void>(` |
| 1347 | `final navigator = Navigator.of(` |
| 1366 | `final navigator = Navigator.of(` |
| 1386 | `final navigator = Navigator.of(` |
| 1406 | `final navigator = Navigator.of(` |
| 1432 | `final navigator = Navigator.of(` |
| 1454 | `final navigator = Navigator.of(` |
| 1478 | `final navigator = Navigator.of(` |
| 1500 | `final navigator = Navigator.of(` |

**`presentation/features/attendance/widgets/staff_attendance_vertical_popup.dart`** — 4

| Line | Code |
|---|---|
| 151 | `Navigator.pop(context);` |
| 162 | `Navigator.pop(context);` |
| 173 | `Navigator.pop(context);` |
| 184 | `Navigator.pop(context);` |

**`presentation/features/attendance/widgets/student_attendance_vertical_pop_up.dart`** — 1

| Line | Code |
|---|---|
| 199 | `Navigator.pop(context);` |

**`presentation/features/attendance/widgets/unexpected_sign_in_attention_dialog.dart`** — 3

| Line | Code |
|---|---|
| 136 | `onPressed: () => Navigator.of(context).pop(` |
| 224 | `onPressedCancel: () => Navigator.of(context).pop(` |
| 235 | `onPressed: () => Navigator.of(context).pop(` |

## M2 — setState scarcely, ValueNotifier for UI micro-state

**185 live occurrences across 23 files** (190 raw). Classify each against the mandate's buckets before touching it. The filter/date/selection calls in the daily and absent views are Bucket A (business state) and are the direct cause of defect **P0-2**.

**`presentation/features/attendance/forms/staff_attendance_forms/staff_selection_mark_absent_form.dart`** — 5

| Line | Code |
|---|---|
| 86 | `setState(() {` |
| 103 | `setState(() {` |
| 183 | `setState(() {` |
| 228 | `setState(() {` |
| 246 | `setState(() {` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_in_form.dart`** — 5

| Line | Code |
|---|---|
| 137 | `setState(() {` |
| 154 | `setState(() {` |
| 197 | `setState(() {` |
| 242 | `setState(() {` |
| 260 | `setState(() {` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_out_form.dart`** — 5

| Line | Code |
|---|---|
| 136 | `setState(() {` |
| 153 | `setState(() {` |
| 197 | `setState(() {` |
| 243 | `setState(() {` |
| 261 | `setState(() {` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_selection_transfer_form.dart`** — 5

| Line | Code |
|---|---|
| 137 | `setState(() {` |
| 154 | `setState(() {` |
| 201 | `setState(() {` |
| 247 | `setState(() {` |
| 265 | `setState(() {` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_sign_out_form.dart`** — 11

| Line | Code |
|---|---|
| 107 | `setState(() {` |
| 187 | `setState(() {` |
| 213 | `setState(() {` |
| 249 | `setState(() {` |
| 264 | `setState(() {` |
| 284 | `setState(() {` |
| 314 | `setState(() {` |
| 497 | `setState(() {` |
| 530 | `setState(() {` |
| 587 | `setState(() {` |
| 625 | `setState(() {` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_transfer_form.dart`** — 13

| Line | Code |
|---|---|
| 112 | `setState(() {` |
| 163 | `setState(() => _currentClassroomCode = existingCode);` |
| 239 | `setState(() {` |
| 296 | `setState(() {` |
| 311 | `setState(() {` |
| 331 | `setState(() {` |
| 350 | `setState(() {` |
| 428 | `setState(() {` |
| 462 | `setState(() {` |
| 470 | `setState(() {` |
| 560 | `setState(() {` |
| 600 | `setState(() {` |
| 622 | `setState(() {` |

**`presentation/features/attendance/forms/student_attendance_forms/student_selection_mark_absent_form.dart`** — 6

| Line | Code |
|---|---|
| 70 | `setState(() {});` |
| 135 | `setState(() {` |
| 152 | `setState(() {` |
| 166 | `setState(() {` |
| 252 | `setState(() {` |
| 267 | `setState(() {` |

**`presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_in_form.dart`** — 6

| Line | Code |
|---|---|
| 200 | `setState(() {` |
| 217 | `setState(() {` |
| 234 | `setState(() {` |
| 285 | `setState(() {` |
| 323 | `setState(() {` |
| 337 | `setState(() {` |

**`presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_out_form.dart`** — 5

| Line | Code |
|---|---|
| 178 | `setState(() {` |
| 195 | `setState(() {` |
| 249 | `setState(() {` |
| 287 | `setState(() {` |
| 301 | `setState(() {` |

**`presentation/features/attendance/forms/student_attendance_forms/student_selection_transfer_form.dart`** — 3

| Line | Code |
|---|---|
| 72 | `setState(() {});` |
| 142 | `setState(() {` |
| 158 | `setState(() {` |

**`presentation/features/attendance/forms/student_attendance_forms/student_sign_in_out_selection_screen.dart`** — 2

| Line | Code |
|---|---|
| 59 | `setState(() => _isValidating = true);` |
| 84 | `if (mounted) setState(() => _isValidating = false);` |

**`presentation/features/attendance/forms/student_attendance_forms/student_sign_out_form.dart`** — 6

| Line | Code |
|---|---|
| 115 | `setState(() {` |
| 135 | `setState(() {` |
| 158 | `setState(() {` |
| 470 | `setState(() {` |
| 546 | `setState(() {` |
| 583 | `setState(() {` |

**`presentation/features/attendance/forms/student_attendance_forms/student_transfer_form.dart`** — 9

| Line | Code |
|---|---|
| 109 | `setState(() {` |
| 189 | `setState(() {` |
| 216 | `setState(() {` |
| 267 | `setState(() {` |
| 304 | `setState(() {` |
| 415 | `setState(() {` |
| 483 | `setState(() {` |
| 520 | `setState(() {` |
| 542 | `setState(() {` |

**`presentation/features/attendance/view/screens/staff_attendance_absent_view.dart`** — 8

| Line | Code |
|---|---|
| 136 | `setState(() {` |
| 217 | `setState(() {` |
| 275 | `setState(() {` |
| 434 | `setState(() {` |
| 463 | `setState(() {` |
| 481 | `setState(() {` |
| 492 | `setState(() {` |
| 570 | `setState(() {` |

**`presentation/features/attendance/view/screens/staff_attendance_custom_view.dart`** — 7

| Line | Code |
|---|---|
| 86 | `setState(() {` |
| 166 | `setState(() {` |
| 203 | `setState(() {` |
| 398 | `setState(() {` |
| 439 | `setState(() {` |
| 452 | `setState(() {` |
| 537 | `setState(() {` |

**`presentation/features/attendance/view/screens/staff_attendance_daily_view.dart`** — 14

| Line | Code |
|---|---|
| 167 | `setState(() => _selectedDate = schoolToday);` |
| 203 | `if (mounted) setState(() {});` |
| 214 | `setState(() {});` |
| 221 | `setState(() {` |
| 230 | `setState(() {` |
| 259 | `setState(() {` |
| 480 | `setState(() {` |
| 490 | `setState(() {` |
| 608 | `setState(() {` |
| 643 | `setState(() {` |
| 651 | `setState(() {` |
| 753 | `setState(() {` |
| 1039 | `setState(() {` |
| 1285 | `setState(() {` |

**`presentation/features/attendance/view/screens/student_attendance_absent_view.dart`** — 19

| Line | Code |
|---|---|
| 170 | `setState(() => _allowCrossClass = true);` |
| 222 | `setState(() {` |
| 228 | `setState(() {` |
| 241 | `setState(() {` |
| 253 | `setState(() {` |
| 288 | `setState(() {` |
| 332 | `setState(() {` |
| 342 | `setState(() {` |
| 399 | `setState(() => _isBackgroundFetchingStudents = true);` |
| 468 | `setState(() {` |
| 494 | `setState(() {` |
| 521 | `setState(() {` |
| 565 | `setState(() {` |
| 696 | `setState(() {` |
| 763 | `setState(() {` |
| 778 | `setState(() {` |
| 824 | `setState(() {` |
| 849 | `setState(() {` |
| 944 | `setState(() {` |

**`presentation/features/attendance/view/screens/student_attendance_custom_view.dart`** — 10

| Line | Code |
|---|---|
| 105 | `setState(() {` |
| 127 | `setState(() => _allowCrossClass = true);` |
| 207 | `setState(() {` |
| 294 | `setState(() {` |
| 307 | `setState(() {` |
| 314 | `setState(() {` |
| 342 | `setState(() {` |
| 389 | `setState(() {` |
| 496 | `setState(() => _loadingButtons[attendance.id] = true);` |
| 499 | `setState(() => _loadingButtons[attendance.id] = false);` |

**`presentation/features/attendance/view/screens/student_attendance_daily_view.dart`** — 14

| Line | Code |
|---|---|
| 227 | `setState(() => _selectedDate = schoolToday);` |
| 269 | `setState(() => _allowCrossClass = true);` |
| 291 | `setState(() {` |
| 296 | `setState(() {` |
| 306 | `setState(() {` |
| 540 | `setState(() {` |
| 921 | `setState(() {` |
| 951 | `setState(() {` |
| 958 | `setState(() {` |
| 974 | `setState(() {` |
| 1064 | `setState(() {` |
| 1152 | `setState(() => _expandedStudentIndex = index);` |
| 1178 | `setState(() {` |
| 1481 | `setState(() {` |

**`presentation/features/attendance/view/staff_attendance_profile.dart`** — 13

| Line | Code |
|---|---|
| 601 | `setState(() {` |
| 617 | `setState(() {` |
| 628 | `setState(() {` |
| 747 | `setState(() {` |
| 759 | `setState(() {` |
| 811 | `setState(() {` |
| 824 | `setState(() {` |
| 834 | `setState(() {` |
| 850 | `setState(() {` |
| 856 | `setState(() {` |
| 862 | `setState(() {` |
| 953 | `setState(() {` |
| 1057 | `setState(() {` |

**`presentation/features/attendance/view/staff_attendance_tabbed_view.dart`** — 7

| Line | Code |
|---|---|
| 84 | `setState(() => _showBars = false);` |
| 86 | `setState(() => _showBars = true);` |
| 124 | `if (mounted) setState(() {});` |
| 144 | `setState(() {` |
| 150 | `setState(() {` |
| 159 | `setState(() {` |
| 242 | `if (mounted) setState(() => _isDrawerOpen = isOpen);` |

**`presentation/features/attendance/view/student_attendance_tabbed_view.dart`** — 4

| Line | Code |
|---|---|
| 71 | `setState(() => _showBars = false);` |
| 73 | `setState(() => _showBars = true);` |
| 116 | `setState(() {` |
| 199 | `if (mounted) setState(() => _isDrawerOpen = isOpen);` |

**`presentation/features/attendance/widgets/attendance_popup.dart`** — 8

| Line | Code |
|---|---|
| 327 | `if (mounted) setState(() {});` |
| 353 | `setState(() {});` |
| 417 | `setState(() {` |
| 427 | `setState(() {` |
| 436 | `setState(() {` |
| 444 | `setState(() {` |
| 450 | `setState(() {` |
| 458 | `setState(() {` |

## M4a — Hardcoded colours

**379 live occurrences across 51 files** (392 raw). No `Color(0x…)` or `Colors.<name>` may appear outside `core/theme/app_colors.dart`. Where a hex has no matching token, the mandate requires adding the token with that exact hex — not substituting the nearest existing one.

**`presentation/features/attendance/forms/staff_attendance_forms/staff_edit_attendance_form.dart`** — 3

| Line | Code |
|---|---|
| 67 | `backgroundColor: AppColors.successColor,` |
| 86 | `? AppColors.warningColor` |
| 87 | `: AppColors.errorColor,` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_mark_absent_form.dart`** — 9

| Line | Code |
|---|---|
| 73 | `backgroundColor: AppColors.successColor,` |
| 93 | `backgroundColor: AppColors.warningColor,` |
| 190 | `color: AppColors.primaryColor.withValues(` |
| 198 | `color: AppColors.inputBorderColor,` |
| 204 | `color: AppColors.inputBorderColor,` |
| 211 | `color: AppColors.inputBorderColor,` |
| 218 | `color: AppColors.errorColor,` |
| 225 | `color: AppColors.errorColor,` |
| 230 | `fillColor: AppColors.cardColor,` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_selection_mark_absent_form.dart`** — 1

| Line | Code |
|---|---|
| 154 | `backgroundColor: AppColors.warningColor,` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_in_form.dart`** — 2

| Line | Code |
|---|---|
| 173 | `backgroundColor: AppColors.warningColor,` |
| 286 | `color: AppColors.errorColor,` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_out_form.dart`** — 2

| Line | Code |
|---|---|
| 172 | `backgroundColor: AppColors.warningColor,` |
| 289 | `color: AppColors.errorColor,` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_selection_transfer_form.dart`** — 2

| Line | Code |
|---|---|
| 173 | `backgroundColor: AppColors.warningColor,` |
| 293 | `color: AppColors.errorColor,` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_sign_in_form.dart`** — 8

| Line | Code |
|---|---|
| 182 | `backgroundColor: AppColors.warningColor,` |
| 195 | `backgroundColor: AppColors.warningColor,` |
| 210 | `backgroundColor: AppColors.warningColor,` |
| 237 | `backgroundColor: AppColors.warningColor,` |
| 456 | `? AppColors.successColor` |
| 457 | `: AppColors.errorColor,` |
| 495 | `backgroundColor: AppColors.successColor,` |
| 519 | `backgroundColor: AppColors.errorColor,` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_sign_out_form.dart`** — 7

| Line | Code |
|---|---|
| 243 | `backgroundColor: AppColors.warningColor,` |
| 260 | `backgroundColor: AppColors.warningColor,` |
| 280 | `backgroundColor: AppColors.warningColor,` |
| 310 | `backgroundColor: AppColors.warningColor,` |
| 457 | `? AppColors.successColor` |
| 458 | `: AppColors.errorColor,` |
| 492 | `backgroundColor: AppColors.errorColor,` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_transfer_form.dart`** — 9

| Line | Code |
|---|---|
| 260 | `backgroundColor: AppColors.warningColor,` |
| 270 | `backgroundColor: AppColors.warningColor,` |
| 290 | `backgroundColor: AppColors.warningColor,` |
| 307 | `backgroundColor: AppColors.warningColor,` |
| 327 | `backgroundColor: AppColors.warningColor,` |
| 346 | `backgroundColor: AppColors.warningColor,` |
| 414 | `? AppColors.successColor` |
| 415 | `: AppColors.errorColor,` |
| 457 | `backgroundColor: AppColors.errorColor,` |

**`presentation/features/attendance/forms/student_attendance_forms/student_edit_attendance_form.dart`** — 3

| Line | Code |
|---|---|
| 66 | `backgroundColor: AppColors.successColor,` |
| 85 | `? AppColors.warningColor` |
| 86 | `: AppColors.errorColor,` |

**`presentation/features/attendance/forms/student_attendance_forms/student_mark_absent_form.dart`** — 10

| Line | Code |
|---|---|
| 90 | `backgroundColor: AppColors.successColor,` |
| 112 | `backgroundColor: AppColors.warningColor,` |
| 140 | `color: AppColors.errorColor,` |
| 220 | `color: AppColors.primaryColor.withValues(` |
| 230 | `color: AppColors.inputBorderColor,` |
| 238 | `color: AppColors.inputBorderColor,` |
| 247 | `color: AppColors.inputBorderColor,` |
| 256 | `color: AppColors.errorColor,` |
| 265 | `color: AppColors.errorColor,` |
| 270 | `fillColor: AppColors.cardColor,` |

**`presentation/features/attendance/forms/student_attendance_forms/student_selection_mark_absent_form.dart`** — 3

| Line | Code |
|---|---|
| 178 | `backgroundColor: AppColors.warningColor,` |
| 208 | `style: AppTextStyles.title.copyWith(color: AppColors.errorColor),` |
| 293 | `color: AppColors.errorColor,` |

**`presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_in_form.dart`** — 2

| Line | Code |
|---|---|
| 249 | `backgroundColor: AppColors.warningColor,` |
| 365 | `color: AppColors.errorColor,` |

**`presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_out_form.dart`** — 2

| Line | Code |
|---|---|
| 214 | `backgroundColor: AppColors.warningColor,` |
| 329 | `color: AppColors.errorColor,` |

**`presentation/features/attendance/forms/student_attendance_forms/student_selection_transfer_form.dart`** — 3

| Line | Code |
|---|---|
| 175 | `style: AppTextStyles.title.copyWith(color: AppColors.errorColor),` |
| 259 | `color: AppColors.errorColor,` |
| 320 | `backgroundColor: AppColors.warningColor,` |

**`presentation/features/attendance/forms/student_attendance_forms/student_sign_in_form.dart`** — 11

| Line | Code |
|---|---|
| 177 | `backgroundColor: AppColors.warningColor,` |
| 222 | `backgroundColor: AppColors.warningColor,` |
| 247 | `backgroundColor: AppColors.warningColor,` |
| 317 | `backgroundColor: AppColors.warningColor,` |
| 331 | `backgroundColor: AppColors.warningColor,` |
| 345 | `backgroundColor: AppColors.warningColor,` |
| 440 | `? AppColors.successColor` |
| 441 | `: AppColors.errorColor,` |
| 506 | `? AppColors.warningColor` |
| 507 | `: AppColors.errorColor,` |
| 528 | `style: AppTextStyles.title.copyWith(color: AppColors.errorColor),` |

**`presentation/features/attendance/forms/student_attendance_forms/student_sign_out_form.dart`** — 12

| Line | Code |
|---|---|
| 152 | `backgroundColor: AppColors.warningColor,` |
| 198 | `backgroundColor: AppColors.warningColor,` |
| 221 | `backgroundColor: AppColors.warningColor,` |
| 240 | `backgroundColor: AppColors.warningColor,` |
| 251 | `backgroundColor: AppColors.warningColor,` |
| 321 | `backgroundColor: AppColors.warningColor,` |
| 335 | `backgroundColor: AppColors.warningColor,` |
| 349 | `backgroundColor: AppColors.warningColor,` |
| 413 | `? AppColors.successColor` |
| 414 | `: AppColors.errorColor,` |
| 465 | `backgroundColor: AppColors.errorColor,` |
| 489 | `style: AppTextStyles.title.copyWith(color: AppColors.errorColor),` |

**`presentation/features/attendance/forms/student_attendance_forms/student_transfer_form.dart`** — 11

| Line | Code |
|---|---|
| 231 | `backgroundColor: AppColors.warningColor,` |
| 241 | `backgroundColor: AppColors.warningColor,` |
| 261 | `backgroundColor: AppColors.warningColor,` |
| 301 | `backgroundColor: AppColors.warningColor,` |
| 322 | `backgroundColor: AppColors.warningColor,` |
| 337 | `backgroundColor: AppColors.warningColor,` |
| 353 | `backgroundColor: AppColors.warningColor,` |
| 387 | `? AppColors.successColor` |
| 388 | `: AppColors.errorColor,` |
| 410 | `backgroundColor: AppColors.errorColor,` |
| 434 | `style: AppTextStyles.title.copyWith(color: AppColors.errorColor),` |

**`presentation/features/attendance/view/screens/staff_attendance_absent_view.dart`** — 3

| Line | Code |
|---|---|
| 476 | `backgroundColor: AppColors.errorColor,` |
| 544 | `color: AppColors.attendanceEmptyStateIconColor,` |
| 551 | `AppColors.attendanceDialogHintTextColor,` |

**`presentation/features/attendance/view/screens/staff_attendance_custom_view.dart`** — 7

| Line | Code |
|---|---|
| 434 | `AppColors.errorColor,` |
| 512 | `AppColors.attendanceEmptyStateIconColor,` |
| 519 | `AppColors.attendanceDialogHintTextColor,` |
| 612 | `color: AppColors.cardColor,` |
| 614 | `border: Border.all(color: AppColors.cardBorderColor),` |
| 617 | `color: AppColors.attendanceCardShadowLightColor,` |
| 670 | `Divider(height: 1, color: AppColors.cardBorderColor),` |

**`presentation/features/attendance/view/screens/staff_attendance_daily_view.dart`** — 5

| Line | Code |
|---|---|
| 1068 | `AppColors.transparentColor,` |
| 1423 | `border: Border.all(color: AppColors.cardBorderColor),` |
| 1425 | `color: AppColors.cardColor,` |
| 1439 | `color: AppColors.transparentColor,` |
| 1461 | `color: AppColors.attendanceDangerAccentColor,` |

**`presentation/features/attendance/view/screens/student_attendance_absent_view.dart`** — 13

| Line | Code |
|---|---|
| 877 | `backgroundColor: AppColors.errorColor.withValues(alpha: 0.1),` |
| 882 | `color: AppColors.errorColor,` |
| 889 | `color: AppColors.errorColor,` |
| 899 | `color: AppColors.cardColor,` |
| 915 | `color: AppColors.secondaryColor.withValues(` |
| 925 | `color: AppColors.secondaryColor,` |
| 1031 | `color: AppColors.cardColor,` |
| 1033 | `border: Border.all(color: AppColors.cardBorderColor),` |
| 1036 | `color: AppColors.attendanceCardShadowLightColor,` |
| 1091 | `Divider(height: 1, color: AppColors.cardBorderColor),` |
| 1139 | `color: AppColors.cardBorderColor.withValues(` |
| 1144 | `color: AppColors.cardBorderColor,` |
| 1155 | `AppColors.primaryColor,` |

**`presentation/features/attendance/view/screens/student_attendance_custom_view.dart`** — 17

| Line | Code |
|---|---|
| 639 | `color: AppColors.attendanceTabIndicatorColor,` |
| 814 | `color: AppColors.errorColor,` |
| 821 | `color: AppColors.errorColor,` |
| 830 | `color: AppColors.secondaryColor,` |
| 840 | `style: AppTextStyles.body.copyWith(color: AppColors.cardColor),` |
| 843 | `backgroundColor: AppColors.themeColor,` |
| 844 | `foregroundColor: AppColors.cardColor,` |
| 870 | `color: AppColors.secondaryColor,` |
| 877 | `color: AppColors.secondaryColor,` |
| 886 | `color: AppColors.secondaryColor,` |
| 971 | `color: AppColors.cardColor,` |
| 973 | `border: Border.all(color: AppColors.cardBorderColor),` |
| 976 | `color: AppColors.attendanceCardShadowLightColor,` |
| 1037 | `Divider(height: 1, color: AppColors.cardBorderColor),` |
| 1057 | `color: AppColors.cardBorderColor.withValues(` |
| 1062 | `color: AppColors.cardBorderColor,` |
| 1073 | `AppColors.primaryColor,` |

**`presentation/features/attendance/view/screens/student_attendance_daily_view.dart`** — 16

| Line | Code |
|---|---|
| 998 | `backgroundColor: AppColors.errorColor.withValues(` |
| 1005 | `color: AppColors.errorColor,` |
| 1015 | `color: AppColors.errorColor,` |
| 1049 | `color: AppColors.attendanceMutedTextColor,` |
| 1124 | `color: AppColors.attendanceMutedTextColor,` |
| 1208 | `backgroundColor: AppColors.errorColor,` |
| 1217 | `AppColors.transparentColor,` |
| 1237 | `AppColors.errorColor,` |
| 1260 | `AppColors.errorColor,` |
| 1278 | `AppColors.errorColor,` |
| 1297 | `AppColors.successColor,` |
| 1312 | `AppColors.errorColor,` |
| 1549 | `border: Border.all(color: AppColors.cardBorderColor),` |
| 1551 | `color: AppColors.cardColor,` |
| 1565 | `color: AppColors.transparentColor,` |
| 1587 | `color: AppColors.attendanceDangerAccentColor,` |

**`presentation/features/attendance/view/screens/widgets/attendance_card_shared.dart`** — 17

| Line | Code |
|---|---|
| 71 | `AppColors.themeColor,` |
| 106 | `AppColors.themeColor,` |
| 119 | `AppColors.themeColor,` |
| 132 | `AppColors.themeColor,` |
| 145 | `AppColors.themeColor,` |
| 158 | `AppColors.themeColor,` |
| 171 | `AppColors.themeColor,` |
| 186 | `AppColors.themeColor,` |
| 273 | `side: const BorderSide(color: AppColors.attendanceActionAccentColor),` |
| 276 | `backgroundColor: AppColors.cardColor,` |
| 281 | `color: AppColors.attendanceActionAccentColor,` |
| 291 | `gradient: AppColors.buildPrimaryGradient(),` |
| 297 | `backgroundColor: AppColors.transparentColor,` |
| 301 | `style: AppTextStyles.title.copyWith(color: AppColors.cardColor),` |
| 361 | `color: AppColors.themeColor,` |
| 369 | `AppColors.themeColor,` |
| 379 | `AppColors.themeColor,` |

**`presentation/features/attendance/view/screens/widgets/attendance_filter_button.dart`** — 8

| Line | Code |
|---|---|
| 35 | `? AppColors.themeColor.withValues(alpha: 0.15)` |
| 36 | `: AppColors.cardColor,` |
| 40 | `? AppColors.themeColor` |
| 41 | `: AppColors.cardBorderColor,` |
| 46 | `color: AppColors.transparentColor,` |
| 63 | `? AppColors.themeColor` |
| 64 | `: AppColors.secondaryColor.withValues(alpha: 0.6),` |
| 76 | `color: AppColors.themeColor,` |

**`presentation/features/attendance/view/screens/widgets/attendance_summary_card_shimmer.dart`** — 5

| Line | Code |
|---|---|
| 31 | `color: AppColors.attendanceBorderLightColor,` |
| 40 | `color: AppColors.attendanceBorderLightColor,` |
| 53 | `color: AppColors.attendanceBorderLightColor,` |
| 64 | `color: AppColors.attendanceBorderLightColor,` |
| 74 | `color: AppColors.attendanceBorderLightColor,` |

**`presentation/features/attendance/view/screens/widgets/staff_attendance_absent_card.dart`** — 3

| Line | Code |
|---|---|
| 97 | `color: AppColors.cardColor,` |
| 100 | `color: AppColors.cardBorderColor,` |
| 161 | `color: AppColors.attendanceCardDividerColor,` |

**`presentation/features/attendance/view/screens/widgets/staff_attendance_card.dart`** — 4

| Line | Code |
|---|---|
| 128 | `color: AppColors.cardColor,` |
| 131 | `color: AppColors.cardBorderColor,` |
| 179 | `color: AppColors.primaryColor.withValues(` |
| 212 | `color: AppColors.attendanceCardDividerColor,` |

**`presentation/features/attendance/view/screens/widgets/staff_attendance_shimmer.dart`** — 17

| Line | Code |
|---|---|
| 28 | `baseColor: AppColors.attendanceShimmerBaseColor,` |
| 29 | `highlightColor: AppColors.attendanceShimmerHighlightColor,` |
| 34 | `color: AppColors.cardColor,` |
| 36 | `border: Border.all(color: AppColors.cardBorderColor, width: AppDimensions.hairline),` |
| 45 | `color: AppColors.cardColor,` |
| 59 | `color: AppColors.cardColor,` |
| 68 | `color: AppColors.cardColor,` |
| 82 | `color: AppColors.cardColor,` |
| 113 | `baseColor: AppColors.attendanceShimmerBaseColor,` |
| 114 | `highlightColor: AppColors.attendanceShimmerHighlightColor,` |
| 119 | `color: AppColors.cardColor,` |
| 121 | `border: Border.all(color: AppColors.cardBorderColor, width: AppDimensions.hairline),` |
| 130 | `color: AppColors.cardColor,` |
| 144 | `color: AppColors.cardColor,` |
| 153 | `color: AppColors.cardColor,` |
| 162 | `color: AppColors.cardColor,` |
| 176 | `color: AppColors.cardColor,` |

**`presentation/features/attendance/view/screens/widgets/staff_attendance_summary.dart`** — 6

| Line | Code |
|---|---|
| 56 | `color: AppColors.lightBlueProgressBar,` |
| 61 | `color: AppColors.mustardProgressBar,` |
| 82 | `color: AppColors.lightGreenProgressBar,` |
| 88 | `color: AppColors.redProgressBar,` |
| 94 | `color: AppColors.lightBlueProgressBar,` |
| 100 | `color: AppColors.mustardProgressBar,` |

**`presentation/features/attendance/view/screens/widgets/student_attendance_absent_card.dart`** — 3

| Line | Code |
|---|---|
| 95 | `color: AppColors.cardColor,` |
| 98 | `color: AppColors.cardBorderColor,` |
| 150 | `color: AppColors.attendanceCardDividerColor,` |

**`presentation/features/attendance/view/screens/widgets/student_attendance_card.dart`** — 3

| Line | Code |
|---|---|
| 129 | `color: AppColors.cardColor,` |
| 132 | `color: AppColors.cardBorderColor,` |
| 189 | `color: AppColors.attendanceCardDividerColor,` |

**`presentation/features/attendance/view/screens/widgets/student_attendance_shimmer.dart`** — 17

| Line | Code |
|---|---|
| 28 | `baseColor: AppColors.attendanceShimmerBaseColor,` |
| 29 | `highlightColor: AppColors.attendanceShimmerHighlightColor,` |
| 34 | `color: AppColors.cardColor,` |
| 36 | `border: Border.all(color: AppColors.cardBorderColor, width: AppDimensions.hairline),` |
| 45 | `color: AppColors.cardColor,` |
| 59 | `color: AppColors.cardColor,` |
| 68 | `color: AppColors.cardColor,` |
| 82 | `color: AppColors.cardColor,` |
| 113 | `baseColor: AppColors.attendanceShimmerBaseColor,` |
| 114 | `highlightColor: AppColors.attendanceShimmerHighlightColor,` |
| 119 | `color: AppColors.cardColor,` |
| 121 | `border: Border.all(color: AppColors.cardBorderColor, width: AppDimensions.hairline),` |
| 130 | `color: AppColors.cardColor,` |
| 144 | `color: AppColors.cardColor,` |
| 153 | `color: AppColors.cardColor,` |
| 162 | `color: AppColors.cardColor,` |
| 176 | `color: AppColors.cardColor,` |

**`presentation/features/attendance/view/screens/widgets/student_attendance_summary.dart`** — 6

| Line | Code |
|---|---|
| 56 | `color: AppColors.lightBlueProgressBar,` |
| 61 | `color: AppColors.mustardProgressBar,` |
| 82 | `color: AppColors.lightGreenProgressBar,` |
| 88 | `color: AppColors.redProgressBar,` |
| 94 | `color: AppColors.lightBlueProgressBar,` |
| 100 | `color: AppColors.mustardProgressBar,` |

**`presentation/features/attendance/view/staff_attendance_profile.dart`** — 32

| Line | Code |
|---|---|
| 70 | `AppColors.themeColor,` |
| 83 | `AppColors.themeColor,` |
| 96 | `AppColors.themeColor,` |
| 109 | `AppColors.themeColor,` |
| 122 | `AppColors.themeColor,` |
| 137 | `AppColors.themeColor,` |
| 151 | `AppColors.themeColor,` |
| 165 | `AppColors.themeColor,` |
| 179 | `AppColors.themeColor,` |
| 194 | `AppColors.themeColor,` |
| 1106 | `backgroundColor: AppColors.transparentColor,` |
| 1181 | `color: AppColors.cardColor,` |
| 1184 | `color: AppColors.primaryColor.withValues(alpha: 0.2),` |
| 1219 | `color: AppColors.cardColor,` |
| 1222 | `color: AppColors.primaryColor.withValues(alpha: 0.2),` |
| 1264 | `backgroundColor: AppColors.cardColor,` |
| 1265 | `collapsedBackgroundColor: AppColors.cardColor,` |
| 1268 | `color: AppColors.primaryColor.withValues(alpha: 0.2),` |
| 1274 | `color: AppColors.primaryColor.withValues(alpha: 0.2),` |
| 1285 | `Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),` |
| 1360 | `backgroundColor: AppColors.cardColor,` |
| 1361 | `collapsedBackgroundColor: AppColors.cardColor,` |
| 1364 | `color: AppColors.primaryColor.withValues(alpha: 0.2),` |
| 1370 | `color: AppColors.primaryColor.withValues(alpha: 0.2),` |
| 1381 | `Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),` |
| 1454 | `color: AppColors.cardColor,` |
| 1457 | `color: AppColors.primaryColor.withValues(alpha: 0.2),` |
| 1463 | `shadowColor: AppColors.primaryColor.withValues(alpha: 0.2),` |
| 1555 | `iconColor: AppColors.attendanceStatBlueColor,` |
| 1558 | `valueColor: AppColors.attendanceStatGreenColor,` |
| 1570 | `iconColor: AppColors.attendanceStatBlueColor,` |
| 1573 | `valueColor: AppColors.errorColor,` |

**`presentation/features/attendance/view/staff_attendance_tabbed_view.dart`** — 8

| Line | Code |
|---|---|
| 217 | `borderSide: BorderSide(color: AppColors.themeColor),` |
| 219 | `dividerColor: AppColors.transparentColor,` |
| 385 | `backgroundColor: AppColors.transparentColor,` |
| 399 | `gradient: AppColors.buildPrimaryGradient(),` |
| 402 | `color: AppColors.attendanceCardShadowColor,` |
| 413 | `color: AppColors.cardColor,` |
| 463 | `backgroundColor: AppColors.warningColor,` |
| 563 | `color: AppColors.attendanceInfoHighlightColor,` |

**`presentation/features/attendance/view/student_attendance_profile.dart`** — 28

| Line | Code |
|---|---|
| 60 | `AppColors.themeColor,` |
| 73 | `AppColors.themeColor,` |
| 86 | `AppColors.themeColor,` |
| 99 | `AppColors.themeColor,` |
| 112 | `AppColors.themeColor,` |
| 127 | `AppColors.themeColor,` |
| 677 | `color: AppColors.cardColor,` |
| 680 | `color: AppColors.primaryColor.withValues(alpha: 0.2),` |
| 686 | `shadowColor: AppColors.primaryColor.withValues(alpha: 0.2),` |
| 843 | `iconColor: AppColors.attendanceStatBlueColor,` |
| 846 | `valueColor: AppColors.attendanceStatGreenColor,` |
| 858 | `iconColor: AppColors.attendanceStatBlueColor,` |
| 861 | `valueColor: AppColors.errorColor,` |
| 909 | `color: AppColors.cardColor,` |
| 912 | `color: AppColors.primaryColor.withValues(alpha: 0.2),` |
| 947 | `color: AppColors.cardColor,` |
| 950 | `color: AppColors.primaryColor.withValues(alpha: 0.2),` |
| 991 | `backgroundColor: AppColors.cardColor,` |
| 992 | `collapsedBackgroundColor: AppColors.cardColor,` |
| 995 | `color: AppColors.primaryColor.withValues(alpha: 0.2),` |
| 1001 | `color: AppColors.primaryColor.withValues(alpha: 0.2),` |
| 1012 | `Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),` |
| 1087 | `backgroundColor: AppColors.cardColor,` |
| 1088 | `collapsedBackgroundColor: AppColors.cardColor,` |
| 1091 | `color: AppColors.primaryColor.withValues(alpha: 0.2),` |
| 1097 | `color: AppColors.primaryColor.withValues(alpha: 0.2),` |
| 1108 | `Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),` |
| 1192 | `color: AppColors.attendanceBodyText87Color,` |

**`presentation/features/attendance/view/student_attendance_tabbed_view.dart`** — 3

| Line | Code |
|---|---|
| 174 | `borderSide: BorderSide(color: AppColors.themeColor),` |
| 176 | `dividerColor: AppColors.transparentColor,` |
| 298 | `color: AppColors.attendanceCardShadowColor,` |

**`presentation/features/attendance/widgets/attendance_edit_form_widgets.dart`** — 1

| Line | Code |
|---|---|
| 57 | `color: AppColors.secondaryColor,` |

**`presentation/features/attendance/widgets/attendance_popup.dart`** — 10

| Line | Code |
|---|---|
| 54 | `backgroundColor: AppColors.warningColor,` |
| 107 | `backgroundColor: AppColors.errorColor,` |
| 143 | `barrierColor: AppColors.attendancePopupBarrierColor,` |
| 229 | `backgroundColor: AppColors.errorColor,` |
| 495 | `backgroundColor: AppColors.transparentColor,` |
| 504 | `color: AppColors.cardColor,` |
| 524 | `color: AppColors.themeColor,` |
| 1618 | `gradient: AppColors.buildSecondaryGradient(),` |
| 1623 | `color: AppColors.cardColor,` |
| 1631 | `AppColors.buildSecondaryGradient().createShader(bounds),` |

**`presentation/features/attendance/widgets/attendance_profile_field.dart`** — 1

| Line | Code |
|---|---|
| 57 | `AppColors.themeColor,` |

**`presentation/features/attendance/widgets/attendance_profile_stat_widgets.dart`** — 5

| Line | Code |
|---|---|
| 74 | `color: AppColors.attendanceCardBorderColor,` |
| 131 | `color: AppColors.attendanceCardBorderColor,` |
| 142 | `AppColors.attendanceStatBlueColor,` |
| 153 | `color: AppColors.attendanceStatBlueColor,` |
| 158 | `color: AppColors.attendanceStatBlueColor,` |

**`presentation/features/attendance/widgets/attendance_remove_tile.dart`** — 2

| Line | Code |
|---|---|
| 63 | `border: Border.all(color: AppColors.themeColor),` |
| 65 | `color: AppColors.attendanceSelectedTintColor,` |

**`presentation/features/attendance/widgets/attendance_search_field.dart`** — 4

| Line | Code |
|---|---|
| 31 | `color: AppColors.cardColor,` |
| 33 | `border: Border.all(color: AppColors.attendanceMutedTextColor),` |
| 41 | `color: AppColors.attendanceSearchHintColor,` |
| 46 | `color: AppColors.attendanceMutedTextColor,` |

**`presentation/features/attendance/widgets/attendance_select_all_row.dart`** — 1

| Line | Code |
|---|---|
| 28 | `borderColor: AppColors.themeColor,` |

**`presentation/features/attendance/widgets/attendance_selectable_person_tile.dart`** — 4

| Line | Code |
|---|---|
| 42 | `border: Border.all(color: AppColors.themeColor),` |
| 45 | `? AppColors.attendanceSelectedTintColor` |
| 46 | `: AppColors.cardColor,` |
| 55 | `borderColor: AppColors.themeColor,` |

**`presentation/features/attendance/widgets/attendance_staff_list_item.dart`** — 4

| Line | Code |
|---|---|
| 37 | `border: Border.all(color: AppColors.themeColor),` |
| 40 | `? AppColors.attendanceSelectedTintColor` |
| 41 | `: AppColors.cardColor,` |
| 50 | `borderColor: AppColors.themeColor,` |

**`presentation/features/attendance/widgets/staff_attendance_vertical_popup.dart`** — 7

| Line | Code |
|---|---|
| 48 | `color: AppColors.primaryColor,` |
| 53 | `child: const Icon(Icons.more_vert, color: AppColors.cardColor),` |
| 65 | `backgroundColor: AppColors.transparentColor,` |
| 127 | `color: AppColors.cardColor,` |
| 130 | `color: AppColors.classroomStudentTabColor,` |
| 135 | `color: AppColors.attendanceCardShadowColor,` |
| 223 | `color: AppColors.attendanceInfoHighlightColor,` |

**`presentation/features/attendance/widgets/student_attendance_vertical_pop_up.dart`** — 5

| Line | Code |
|---|---|
| 115 | `backgroundColor: AppColors.transparentColor,` |
| 129 | `gradient: AppColors.buildPrimaryGradient(),` |
| 132 | `color: AppColors.attendanceCardShadowColor,` |
| 150 | `color: AppColors.cardColor,` |
| 267 | `color: AppColors.attendanceInfoHighlightColor,` |

**`presentation/features/attendance/widgets/unexpected_sign_in_attention_dialog.dart`** — 14

| Line | Code |
|---|---|
| 42 | `barrierColor: AppColors.attendanceOverlayScrimColor,` |
| 80 | `const headerBg = AppColors.attendanceInfoBannerBackgroundColor;` |
| 87 | `backgroundColor: AppColors.transparentColor,` |
| 90 | `color: AppColors.transparentColor,` |
| 94 | `color: AppColors.cardColor,` |
| 98 | `color: AppColors.primaryColor.withValues(alpha: 0.12),` |
| 123 | `color: AppColors.primaryColor,` |
| 141 | `color: AppColors.primaryColor.withValues(alpha: 0.85),` |
| 158 | `color: AppColors.attendanceDialogBodyTextColor,` |
| 165 | `color: AppColors.themeColor,` |
| 174 | `color: AppColors.attendanceDialogBodyTextColor,` |
| 191 | `color: AppColors.attendanceDialogHintTextColor,` |
| 200 | `color: AppColors.attendanceBorderLightColor,` |
| 206 | `color: AppColors.attendanceBorderLightColor,` |

## M4b — Inline TextStyle

**1 live occurrence** (9 raw — the other 8 are inside the dead `student_override_sign_in_form.dart`). Mandate 4's `TextStyle` clause is effectively already met. Local variation must use `.copyWith()` on a named style, never a fresh `TextStyle(`.

**`presentation/features/attendance/view/screens/widgets/staff_attendance_card.dart`** — 1

| Line | Code |
|---|---|
| 175 | `style: TextStyle(` |

## M4c — Residual fontFamily

**1 occurrence.** The family is already on `ThemeData`; this is a find-and-delete.

Note that M4b and M4c are the *same two adjacent lines* — one `TextStyle(` block at `staff_attendance_card.dart:175-176` carrying a `fontFamily`. Once the 379 colour literals are tokenised, deleting this single block closes the whole of Mandate 4 outside colours.

**`presentation/features/attendance/view/screens/widgets/staff_attendance_card.dart`** — 1

| Line | Code |
|---|---|
| 176 | `fontFamily: Fonts.manrope,` |

## M5a — serviceLocator outside a GoRoute builder (hard violations)

**7 occurrences.** These resolve services, use cases and platform gates — not cubits — from inside presentation code. Each needs a cubit or an injected service.

**`presentation/features/attendance/forms/student_attendance_forms/student_sign_in_out_selection_screen.dart`** — 2

| Line | Code |
|---|---|
| 107 | `isKiosk = await serviceLocator<KioskAccessControl>()` |
| 165 | `isKiosk = await serviceLocator<KioskAccessControl>()` |

**`presentation/features/attendance/util/attendance_permission_service.dart`** — 1

| Line | Code |
|---|---|
| 55 | `final storage = serviceLocator<StorageService>();` |

**`presentation/features/attendance/util/attendance_school_time.dart`** — 2

| Line | Code |
|---|---|
| 28 | `storage: serviceLocator<StorageService>(),` |
| 29 | `apiClient: serviceLocator<ApiClient>(),` |

**`presentation/features/attendance/view/staff_attendance_tabbed_view.dart`** — 1

| Line | Code |
|---|---|
| 136 | `final storage = serviceLocator<StorageService>();` |

**`presentation/features/attendance/view/student_attendance_profile.dart`** — 1

| Line | Code |
|---|---|
| 473 | `final useCase = serviceLocator<GetStudentTransferFormListUseCase>();` |

## M5b — serviceLocator cubit construction in initState

**47 occurrences across 28 files.** Constructing a cubit via the locator is legal *only* in a `GoRoute` builder. Because the module has no routes, all 47 sit in `initState`. These resolve as a by-product of the M1 migration — fix M1 and M5 as a pair, per the recommended order in `docs/mandate-rules.md`.

**`presentation/features/attendance/forms/staff_attendance_forms/staff_edit_attendance_form.dart`** — 1

| Line | Code |
|---|---|
| 37 | `_cubit = serviceLocator<StaffEditAttendanceFormCubit>();` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_mark_absent_form.dart`** — 1

| Line | Code |
|---|---|
| 44 | `_cubit = serviceLocator<StaffMarkAbsentFormCubit>()` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_selection_mark_absent_form.dart`** — 2

| Line | Code |
|---|---|
| 63 | `_selectionCubit = serviceLocator<StaffMarkAbsentSelectionCubit>();` |
| 64 | `_classroomCubit = serviceLocator<ClassroomCubit>()` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_in_form.dart`** — 2

| Line | Code |
|---|---|
| 62 | `_selectionCubit = serviceLocator<StaffSignInSelectionCubit>();` |
| 63 | `_classroomCubit = serviceLocator<ClassroomCubit>()` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_out_form.dart`** — 2

| Line | Code |
|---|---|
| 61 | `_selectionCubit = serviceLocator<StaffSignOutSelectionCubit>();` |
| 62 | `_classroomCubit = serviceLocator<ClassroomCubit>()` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_selection_transfer_form.dart`** — 2

| Line | Code |
|---|---|
| 62 | `_selectionCubit = serviceLocator<StaffTransferSelectionCubit>();` |
| 63 | `_classroomCubit = serviceLocator<ClassroomCubit>()` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_sign_in_form.dart`** — 2

| Line | Code |
|---|---|
| 78 | `serviceLocator<StaffSignInSubmitCubit>();` |
| 85 | `serviceLocator<StaffSignInGateCubit>();` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_sign_out_form.dart`** — 1

| Line | Code |
|---|---|
| 78 | `serviceLocator<StaffSignOutSubmitCubit>();` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_transfer_form.dart`** — 2

| Line | Code |
|---|---|
| 51 | `serviceLocator<StaffTransferSubmitCubit>();` |
| 88 | `_classroomCubit = serviceLocator<ClassroomCubit>()` |

**`presentation/features/attendance/forms/student_attendance_forms/student_edit_attendance_form.dart`** — 1

| Line | Code |
|---|---|
| 37 | `_cubit = serviceLocator<StudentEditAttendanceFormCubit>();` |

**`presentation/features/attendance/forms/student_attendance_forms/student_mark_absent_form.dart`** — 1

| Line | Code |
|---|---|
| 51 | `_cubit = serviceLocator<StudentMarkAbsentFormCubit>();` |

**`presentation/features/attendance/forms/student_attendance_forms/student_selection_mark_absent_form.dart`** — 1

| Line | Code |
|---|---|
| 44 | `_cubit = serviceLocator<StudentMarkAbsentSelectionCubit>();` |

**`presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_in_form.dart`** — 1

| Line | Code |
|---|---|
| 91 | `_cubit = serviceLocator<StudentSignInSelectionCubit>();` |

**`presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_out_form.dart`** — 1

| Line | Code |
|---|---|
| 77 | `_cubit = serviceLocator<StudentSignOutSelectionCubit>();` |

**`presentation/features/attendance/forms/student_attendance_forms/student_selection_transfer_form.dart`** — 1

| Line | Code |
|---|---|
| 46 | `_cubit = serviceLocator<StudentTransferSelectionCubit>();` |

**`presentation/features/attendance/forms/student_attendance_forms/student_sign_in_form.dart`** — 2

| Line | Code |
|---|---|
| 90 | `serviceLocator<StudentSignInSubmitCubit>();` |
| 97 | `serviceLocator<StudentSignInGateCubit>();` |

**`presentation/features/attendance/forms/student_attendance_forms/student_sign_in_out_selection_screen.dart`** — 1

| Line | Code |
|---|---|
| 41 | `serviceLocator<QrCodeValidationCubit>();` |

**`presentation/features/attendance/forms/student_attendance_forms/student_sign_out_form.dart`** — 2

| Line | Code |
|---|---|
| 95 | `serviceLocator<StudentSignOutSubmitCubit>();` |
| 97 | `serviceLocator<QrCodeValidationCubit>();` |

**`presentation/features/attendance/forms/student_attendance_forms/student_transfer_form.dart`** — 1

| Line | Code |
|---|---|
| 79 | `serviceLocator<StudentTransferSubmitCubit>();` |

**`presentation/features/attendance/view/screens/staff_attendance_absent_view.dart`** — 2

| Line | Code |
|---|---|
| 109 | `_cubit = serviceLocator<StaffAttendanceAbsentCubit>();` |
| 110 | `_classroomCubit = serviceLocator<ClassroomCubit>();` |

**`presentation/features/attendance/view/screens/staff_attendance_custom_view.dart`** — 2

| Line | Code |
|---|---|
| 64 | `_cubit = serviceLocator<StaffAttendanceCustomCubit>();` |
| 65 | `_classroomCubit = serviceLocator<ClassroomCubit>();` |

**`presentation/features/attendance/view/screens/staff_attendance_daily_view.dart`** — 4

| Line | Code |
|---|---|
| 100 | `serviceLocator<StaffAttendanceDeleteCubit>();` |
| 135 | `_cubit = serviceLocator<StaffAttendanceDailyCubit>();` |
| 136 | `_absentToggleCubit = serviceLocator<StaffAttendanceAbsentToggleCubit>();` |
| 137 | `_classroomCubit = serviceLocator<ClassroomCubit>();` |

**`presentation/features/attendance/view/screens/student_attendance_absent_view.dart`** — 2

| Line | Code |
|---|---|
| 123 | `serviceLocator<StudentAttendanceAbsentFetchCubit>();` |
| 138 | `_classroomCubit = serviceLocator<ClassroomCubit>();` |

**`presentation/features/attendance/view/screens/student_attendance_custom_view.dart`** — 2

| Line | Code |
|---|---|
| 76 | `_cubit = serviceLocator<StudentAttendanceCustomCubit>();` |
| 80 | `_classroomCubit = serviceLocator<ClassroomCubit>();` |

**`presentation/features/attendance/view/screens/student_attendance_daily_view.dart`** — 4

| Line | Code |
|---|---|
| 134 | `serviceLocator<StudentAttendanceDeleteCubit>();` |
| 148 | `_cubit = serviceLocator<StudentAttendanceDailyCubit>();` |
| 149 | `_absentToggleCubit = serviceLocator<StudentAttendanceAbsentToggleCubit>();` |
| 153 | `_classroomCubit = serviceLocator<ClassroomCubit>();` |

**`presentation/features/attendance/view/staff_attendance_profile.dart`** — 1

| Line | Code |
|---|---|
| 519 | `serviceLocator<StaffAttendanceProfileFetchCubit>();` |

**`presentation/features/attendance/view/student_attendance_profile.dart`** — 1

| Line | Code |
|---|---|
| 297 | `serviceLocator<StudentAttendanceProfileFetchCubit>();` |

**`presentation/features/attendance/widgets/attendance_popup.dart`** — 2

| Line | Code |
|---|---|
| 65 | `final fetchCubit = serviceLocator<StudentAttendanceProfileFetchCubit>();` |
| 276 | `serviceLocator<StaffAttendanceProfileFetchCubit>();` |

## M5c — Cubits depending on a Repository instead of a UseCase

**6 occurrences across 3 cubits.** "Cubits call use cases, not repositories. If a use case is missing, create one."

**`presentation/features/attendance/forms/staff_attendance_forms/view_model/staff_edit_attendance_cubit.dart`** — 2

| Line | Code |
|---|---|
| 24 | `required AttendanceRepository attendanceRepository,` |
| 32 | `final AttendanceRepository _attendanceRepository;` |

**`presentation/features/attendance/view_model/student_attendance_custom_cubit.dart`** — 2

| Line | Code |
|---|---|
| 19 | `required AttendanceRepository repository,` |
| 29 | `final AttendanceRepository _repository;` |

**`presentation/features/attendance/view_model/student_attendance_daily_cubit.dart`** — 2

| Line | Code |
|---|---|
| 23 | `required AttendanceRepository repository,` |
| 42 | `final AttendanceRepository _repository;` |

## M5d — StorageService in presentation

**49 occurrences across 26 files.** `StorageService` is on the mandate's forbidden-types list for anything under `lib/presentation`. Every one of these is a constructor parameter plus its field on a cubit — a consistent, mechanical pattern, and the lowest-risk item in M5 to unwind behind a domain-level accessor.

**`presentation/features/attendance/forms/staff_attendance_forms/view_model/staff_edit_attendance_cubit.dart`** — 2

| Line | Code |
|---|---|
| 25 | `required StorageService storageService,` |
| 33 | `final StorageService _storageService;` |

**`presentation/features/attendance/forms/staff_attendance_forms/view_model/staff_mark_absent_cubit.dart`** — 2

| Line | Code |
|---|---|
| 24 | `required StorageService storageService,` |
| 32 | `final StorageService _storageService;` |

**`presentation/features/attendance/forms/staff_attendance_forms/view_model/staff_sign_in_gate_cubit.dart`** — 2

| Line | Code |
|---|---|
| 33 | `required StorageService storageService,` |
| 46 | `final StorageService _storage;` |

**`presentation/features/attendance/forms/staff_attendance_forms/view_model/staff_sign_out_submit_cubit.dart`** — 2

| Line | Code |
|---|---|
| 25 | `required StorageService storageService,` |
| 32 | `final StorageService _storage;` |

**`presentation/features/attendance/forms/staff_attendance_forms/view_model/staff_transfer_submit_cubit.dart`** — 2

| Line | Code |
|---|---|
| 31 | `required StorageService storageService,` |
| 42 | `final StorageService _storage;` |

**`presentation/features/attendance/forms/student_attendance_forms/view_model/student_edit_attendance_cubit.dart`** — 2

| Line | Code |
|---|---|
| 25 | `required StorageService storageService,` |
| 33 | `final StorageService _storageService;` |

**`presentation/features/attendance/forms/student_attendance_forms/view_model/student_mark_absent_cubit.dart`** — 2

| Line | Code |
|---|---|
| 26 | `required StorageService storageService,` |
| 34 | `final StorageService _storageService;` |

**`presentation/features/attendance/forms/student_attendance_forms/view_model/student_mark_absent_selection_cubit.dart`** — 2

| Line | Code |
|---|---|
| 26 | `required StorageService storageService,` |
| 39 | `final StorageService _storage;` |

**`presentation/features/attendance/forms/student_attendance_forms/view_model/student_sign_in_gate_cubit.dart`** — 2

| Line | Code |
|---|---|
| 30 | `required StorageService storageService,` |
| 43 | `final StorageService _storage;` |

**`presentation/features/attendance/forms/student_attendance_forms/view_model/student_sign_in_selection_cubit.dart`** — 2

| Line | Code |
|---|---|
| 25 | `required StorageService storageService,` |
| 38 | `final StorageService _storage;` |

**`presentation/features/attendance/forms/student_attendance_forms/view_model/student_sign_out_selection_cubit.dart`** — 2

| Line | Code |
|---|---|
| 21 | `required StorageService storageService,` |
| 34 | `final StorageService _storage;` |

**`presentation/features/attendance/forms/student_attendance_forms/view_model/student_sign_out_submit_cubit.dart`** — 2

| Line | Code |
|---|---|
| 25 | `required StorageService storageService,` |
| 32 | `final StorageService _storage;` |

**`presentation/features/attendance/forms/student_attendance_forms/view_model/student_transfer_selection_cubit.dart`** — 2

| Line | Code |
|---|---|
| 25 | `required StorageService storageService,` |
| 39 | `final StorageService _storage;` |

**`presentation/features/attendance/forms/student_attendance_forms/view_model/student_transfer_submit_cubit.dart`** — 2

| Line | Code |
|---|---|
| 30 | `required StorageService storageService,` |
| 39 | `final StorageService _storage;` |

**`presentation/features/attendance/util/attendance_permission_service.dart`** — 1

| Line | Code |
|---|---|
| 55 | `final storage = serviceLocator<StorageService>();` |

**`presentation/features/attendance/util/attendance_school_time.dart`** — 1

| Line | Code |
|---|---|
| 28 | `storage: serviceLocator<StorageService>(),` |

**`presentation/features/attendance/view/staff_attendance_tabbed_view.dart`** — 1

| Line | Code |
|---|---|
| 136 | `final storage = serviceLocator<StorageService>();` |

**`presentation/features/attendance/view_model/qr_code_validation_cubit.dart`** — 2

| Line | Code |
|---|---|
| 13 | `required StorageService storageService,` |
| 18 | `final StorageService _storageService;` |

**`presentation/features/attendance/view_model/staff_attendance_daily_cubit.dart`** — 2

| Line | Code |
|---|---|
| 21 | `required StorageService storageService,` |
| 35 | `final StorageService _storageService;` |

**`presentation/features/attendance/view_model/staff_attendance_delete_cubit.dart`** — 2

| Line | Code |
|---|---|
| 20 | `required StorageService storageService,` |
| 25 | `final StorageService _storageService;` |

**`presentation/features/attendance/view_model/staff_attendance_profile_fetch_cubit.dart`** — 2

| Line | Code |
|---|---|
| 32 | `required StorageService storageService,` |
| 45 | `final StorageService _storageService;` |

**`presentation/features/attendance/view_model/student_attendance_absent_fetch_cubit.dart`** — 2

| Line | Code |
|---|---|
| 28 | `required StorageService storageService,` |
| 42 | `final StorageService _storage;` |

**`presentation/features/attendance/view_model/student_attendance_custom_cubit.dart`** — 2

| Line | Code |
|---|---|
| 21 | `required StorageService storageService,` |
| 31 | `final StorageService _storage;` |

**`presentation/features/attendance/view_model/student_attendance_daily_cubit.dart`** — 2

| Line | Code |
|---|---|
| 27 | `required StorageService storageService,` |
| 45 | `final StorageService _storageService;` |

**`presentation/features/attendance/view_model/student_attendance_delete_cubit.dart`** — 2

| Line | Code |
|---|---|
| 20 | `required StorageService storageService,` |
| 25 | `final StorageService _storageService;` |

**`presentation/features/attendance/view_model/student_attendance_profile_fetch_cubit.dart`** — 2

| Line | Code |
|---|---|
| 202 | `required StorageService storageService,` |
| 222 | `final StorageService _storageService;` |

## M5e — ApiClient / Dio / SharedPreferences in presentation

**21 occurrences across 11 files.** `attendance_school_time.dart` reaching for `ApiClient` is the sharpest of these: a presentation helper making its own network call.

**`presentation/features/attendance/forms/staff_attendance_forms/view_model/staff_edit_attendance_cubit.dart`** — 2

| Line | Code |
|---|---|
| 26 | `required ApiClient apiClient,` |
| 34 | `final ApiClient _apiClient;` |

**`presentation/features/attendance/forms/staff_attendance_forms/view_model/staff_mark_absent_cubit.dart`** — 2

| Line | Code |
|---|---|
| 25 | `required ApiClient apiClient,` |
| 33 | `final ApiClient _apiClient;` |

**`presentation/features/attendance/forms/staff_attendance_forms/view_model/staff_sign_in_gate_cubit.dart`** — 2

| Line | Code |
|---|---|
| 34 | `required ApiClient apiClient,` |
| 47 | `final ApiClient _apiClient;` |

**`presentation/features/attendance/forms/staff_attendance_forms/view_model/staff_sign_out_submit_cubit.dart`** — 2

| Line | Code |
|---|---|
| 26 | `required ApiClient apiClient,` |
| 33 | `final ApiClient _apiClient;` |

**`presentation/features/attendance/forms/staff_attendance_forms/view_model/staff_transfer_submit_cubit.dart`** — 2

| Line | Code |
|---|---|
| 32 | `required ApiClient apiClient,` |
| 43 | `final ApiClient _apiClient;` |

**`presentation/features/attendance/forms/student_attendance_forms/view_model/student_edit_attendance_cubit.dart`** — 2

| Line | Code |
|---|---|
| 26 | `required ApiClient apiClient,` |
| 34 | `final ApiClient _apiClient;` |

**`presentation/features/attendance/forms/student_attendance_forms/view_model/student_mark_absent_cubit.dart`** — 2

| Line | Code |
|---|---|
| 27 | `required ApiClient apiClient,` |
| 35 | `final ApiClient _apiClient;` |

**`presentation/features/attendance/forms/student_attendance_forms/view_model/student_sign_in_gate_cubit.dart`** — 2

| Line | Code |
|---|---|
| 31 | `required ApiClient apiClient,` |
| 44 | `final ApiClient _apiClient;` |

**`presentation/features/attendance/forms/student_attendance_forms/view_model/student_sign_out_submit_cubit.dart`** — 2

| Line | Code |
|---|---|
| 26 | `required ApiClient apiClient,` |
| 33 | `final ApiClient _apiClient;` |

**`presentation/features/attendance/forms/student_attendance_forms/view_model/student_transfer_submit_cubit.dart`** — 2

| Line | Code |
|---|---|
| 31 | `required ApiClient apiClient,` |
| 40 | `final ApiClient _apiClient;` |

**`presentation/features/attendance/util/attendance_school_time.dart`** — 1

| Line | Code |
|---|---|
| 29 | `apiClient: serviceLocator<ApiClient>(),` |

## M7 — MediaQuery.of instead of MediaQuery.sizeOf

**13 live occurrences across 12 files** (14 raw), against 0 uses of `MediaQuery.sizeOf`. `.of` subscribes to the whole MediaQueryData, so a width read re-runs on every keyboard open.

**`presentation/features/attendance/forms/staff_attendance_forms/staff_selection_mark_absent_form.dart`** — 1

| Line | Code |
|---|---|
| 169 | `final mediaQuery = MediaQuery.of(context);` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_in_form.dart`** — 1

| Line | Code |
|---|---|
| 188 | `final mediaQuery = MediaQuery.of(context);` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_out_form.dart`** — 1

| Line | Code |
|---|---|
| 187 | `final mediaQuery = MediaQuery.of(context);` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_selection_transfer_form.dart`** — 1

| Line | Code |
|---|---|
| 188 | `final mediaQuery = MediaQuery.of(context);` |

**`presentation/features/attendance/forms/student_attendance_forms/student_selection_mark_absent_form.dart`** — 1

| Line | Code |
|---|---|
| 215 | `final mediaQuery = MediaQuery.of(context);` |

**`presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_in_form.dart`** — 1

| Line | Code |
|---|---|
| 275 | `final mediaQuery = MediaQuery.of(context);` |

**`presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_out_form.dart`** — 1

| Line | Code |
|---|---|
| 239 | `final mediaQuery = MediaQuery.of(context);` |

**`presentation/features/attendance/forms/student_attendance_forms/student_selection_transfer_form.dart`** — 1

| Line | Code |
|---|---|
| 182 | `final mediaQuery = MediaQuery.of(context);` |

**`presentation/features/attendance/view/staff_attendance_profile.dart`** — 1

| Line | Code |
|---|---|
| 1086 | `final mediaQuery = MediaQuery.of(context);` |

**`presentation/features/attendance/view/staff_attendance_tabbed_view.dart`** — 2

| Line | Code |
|---|---|
| 178 | `final mediaQuery = MediaQuery.of(context);` |
| 365 | `final mediaQuery = MediaQuery.of(context);` |

**`presentation/features/attendance/view/student_attendance_tabbed_view.dart`** — 1

| Line | Code |
|---|---|
| 135 | `final mediaQuery = MediaQuery.of(context);` |

**`presentation/features/attendance/widgets/attendance_popup.dart`** — 1

| Line | Code |
|---|---|
| 479 | `final mediaQuery = MediaQuery.of(context);` |

## M8 — Map<String, dynamic> in domain and presentation

**15 live occurrences across 14 files** (31 raw — 16 sit in doc comments describing the fix). The repository contract itself is now map-free — this is the residue: `toPayload()` wire-builders living in `lib/domain`, and `is Map<String, dynamic>` type-probing in views and cubits. Separately, the module has **0 `.g.dart` files and 0 `@JsonSerializable` annotations**: all serialisation is still hand-written, which is Mandate 8's central requirement and its largest single gap.

**`domain/features/attendance/entities/attendance_profile_absent_toggle_query.dart`** — 1

| Line | Code |
|---|---|
| 41 | `Map<String, dynamic> toQueryParameters() {` |

**`domain/features/attendance/entities/attendance_profile_query.dart`** — 1

| Line | Code |
|---|---|
| 34 | `Map<String, dynamic> toQueryParameters() {` |

**`domain/features/attendance/entities/staff_attendance_daily_update_request.dart`** — 1

| Line | Code |
|---|---|
| 32 | `Map<String, dynamic> toPayload() => <String, dynamic>{` |

**`domain/features/attendance/entities/staff_sign_in_request.dart`** — 1

| Line | Code |
|---|---|
| 78 | `Map<String, dynamic> toPayload() {` |

**`domain/features/attendance/entities/staff_sign_out_request.dart`** — 1

| Line | Code |
|---|---|
| 63 | `Map<String, dynamic> toPayload() {` |

**`domain/features/attendance/entities/staff_transfer_request.dart`** — 1

| Line | Code |
|---|---|
| 31 | `Map<String, dynamic> toPayload() => <String, dynamic>{` |

**`domain/features/attendance/entities/student_sign_in_request.dart`** — 1

| Line | Code |
|---|---|
| 66 | `Map<String, dynamic> toPayload() {` |

**`domain/features/attendance/entities/student_sign_out_request.dart`** — 1

| Line | Code |
|---|---|
| 55 | `Map<String, dynamic> toPayload() {` |

**`domain/features/attendance/entities/student_transfer_request.dart`** — 1

| Line | Code |
|---|---|
| 33 | `Map<String, dynamic> toPayload() => <String, dynamic>{` |

**`presentation/features/attendance/view/screens/staff_attendance_daily_view.dart`** — 1

| Line | Code |
|---|---|
| 1260 | `final result = await Navigator.push<Map<String, dynamic>?>(` |

**`presentation/features/attendance/view/screens/student_attendance_absent_view.dart`** — 1

| Line | Code |
|---|---|
| 635 | `if (value is Map<String, dynamic>) {` |

**`presentation/features/attendance/view/staff_attendance_profile.dart`** — 2

| Line | Code |
|---|---|
| 269 | `if (value is Map<String, dynamic>) {` |
| 532 | `if (value is Map<String, dynamic>) {` |

**`presentation/features/attendance/view/student_attendance_profile.dart`** — 1

| Line | Code |
|---|---|
| 147 | `if (value is Map<String, dynamic>) {` |

**`presentation/features/attendance/view_model/student_attendance_profile_fetch_cubit.dart`** — 1

| Line | Code |
|---|---|
| 372 | `if (value is Map<String, dynamic>) {` |

## Silent `catch (_) {}` blocks

**16 occurrences, of 151 catch blocks in the module.** Some are deliberately best-effort; none are distinguishable from a swallowed defect in production, because `AppLogger.d` is a no-op in release and nothing reaches Crashlytics.

**`presentation/features/attendance/forms/attendance_time_parse_util.dart`** — 1

| Line | Code |
|---|---|
| 30 | `} catch (_) {}` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_sign_in_form.dart`** — 1

| Line | Code |
|---|---|
| 311 | `} catch (_) {}` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_sign_out_form.dart`** — 2

| Line | Code |
|---|---|
| 209 | `} catch (_) {}` |
| 395 | `} catch (_) {}` |

**`presentation/features/attendance/forms/staff_attendance_forms/staff_transfer_form.dart`** — 1

| Line | Code |
|---|---|
| 107 | `} catch (_) {}` |

**`presentation/features/attendance/forms/staff_attendance_forms/view_model/staff_mark_absent_cubit.dart`** — 1

| Line | Code |
|---|---|
| 68 | `} catch (_) {}` |

**`presentation/features/attendance/forms/student_attendance_forms/student_sign_in_form.dart`** — 1

| Line | Code |
|---|---|
| 299 | `} catch (_) {}` |

**`presentation/features/attendance/forms/student_attendance_forms/student_sign_out_form.dart`** — 3

| Line | Code |
|---|---|
| 131 | `} catch (_) {}` |
| 142 | `} catch (_) {}` |
| 303 | `} catch (_) {}` |

**`presentation/features/attendance/forms/student_attendance_forms/student_transfer_form.dart`** — 2

| Line | Code |
|---|---|
| 105 | `} catch (_) {}` |
| 116 | `} catch (_) {}` |

**`presentation/features/attendance/forms/student_attendance_forms/view_model/student_mark_absent_cubit.dart`** — 2

| Line | Code |
|---|---|
| 52 | `} catch (_) {}` |
| 67 | `} catch (_) {}` |

**`presentation/features/attendance/view/screens/staff_attendance_daily_view.dart`** — 1

| Line | Code |
|---|---|
| 224 | `} catch (_) {}` |

**`presentation/features/attendance/view/screens/student_attendance_daily_view.dart`** — 1

| Line | Code |
|---|---|
| 309 | `} catch (_) {}` |


---

# Part C — Toolchain output

## Analyzer output — 23 issues

Full `flutter analyze` on the three attendance directories. Zero errors; 22 unused-import warnings and 1 `unnecessary_import`. This is a **regression** from the 2 issues recorded by the 2026-08-27 audit, and the shape is diagnostic: form screens were re-wired and their old imports left behind.

| Severity | File | Line | Rule | Detail |
|---|---|---|---|---|
| warning | `presentation/features/attendance/forms/staff_attendance_forms/staff_selection_mark_absent_form.dart` | 21 | `unused_import` | Unused import: `staff_mark_absent_form.dart` |
| warning | `presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_in_form.dart` | 21 | `unused_import` | Unused import: `staff_sign_in_form.dart` |
| warning | `presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_out_form.dart` | 21 | `unused_import` | Unused import: `staff_sign_out_form.dart` |
| warning | `presentation/features/attendance/forms/staff_attendance_forms/staff_selection_transfer_form.dart` | 21 | `unused_import` | Unused import: `staff_transfer_form.dart` |
| warning | `presentation/features/attendance/view/screens/staff_attendance_daily_view.dart` | 36 | `unused_import` | Unused import: `package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_edit_attendance_form.dart` |
| warning | `presentation/features/attendance/view/screens/student_attendance_daily_view.dart` | 40 | `unused_import` | Unused import: `package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_edit_attendance_form.dart` |
| warning | `presentation/features/attendance/view/staff_attendance_profile.dart` | 31 | `unused_import` | Unused import: `package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_in_form.dart` |
| warning | `presentation/features/attendance/view/staff_attendance_profile.dart` | 32 | `unused_import` | Unused import: `package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_out_form.dart` |
| warning | `presentation/features/attendance/view/staff_attendance_profile.dart` | 33 | `unused_import` | Unused import: `package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_transfer_form.dart` |
| warning | `presentation/features/attendance/view/staff_attendance_profile.dart` | 34 | `unused_import` | Unused import: `package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_mark_absent_form.dart` |
|    info | `presentation/features/attendance/view/staff_attendance_tabbed_view.dart` | 6 | `unnecessary_import` | The import of `package:provider/provider.dart` is unnecessary because all of the used elements are also provided by the import of `package:flutter_bloc/flutter_bloc.dart` |
| warning | `presentation/features/attendance/view/staff_attendance_tabbed_view.dart` | 23 | `unused_import` | Unused import: `package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_in_form.dart` |
| warning | `presentation/features/attendance/view/staff_attendance_tabbed_view.dart` | 24 | `unused_import` | Unused import: `package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_out_form.dart` |
| warning | `presentation/features/attendance/view/staff_attendance_tabbed_view.dart` | 25 | `unused_import` | Unused import: `package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_transfer_form.dart` |
| warning | `presentation/features/attendance/view/staff_attendance_tabbed_view.dart` | 26 | `unused_import` | Unused import: `package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_mark_absent_form.dart` |
| warning | `presentation/features/attendance/view/staff_attendance_tabbed_view.dart` | 27 | `unused_import` | Unused import: `package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_in_form.dart` |
| warning | `presentation/features/attendance/view/staff_attendance_tabbed_view.dart` | 28 | `unused_import` | Unused import: `package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_out_form.dart` |
| warning | `presentation/features/attendance/view/staff_attendance_tabbed_view.dart` | 29 | `unused_import` | Unused import: `package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_transfer_form.dart` |
| warning | `presentation/features/attendance/view/staff_attendance_tabbed_view.dart` | 30 | `unused_import` | Unused import: `package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_mark_absent_form.dart` |
| warning | `presentation/features/attendance/widgets/student_attendance_vertical_pop_up.dart` | 10 | `unused_import` | Unused import: `package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_in_form.dart` |
| warning | `presentation/features/attendance/widgets/student_attendance_vertical_pop_up.dart` | 11 | `unused_import` | Unused import: `package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_out_form.dart` |
| warning | `presentation/features/attendance/widgets/student_attendance_vertical_pop_up.dart` | 12 | `unused_import` | Unused import: `package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_transfer_form.dart` |
| warning | `presentation/features/attendance/widgets/student_attendance_vertical_pop_up.dart` | 13 | `unused_import` | Unused import: `package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_mark_absent_form.dart` |

## Appendix — files over the 400-line ceiling (Mandate 6)

**24 files.** The mandate says to split by extracting cohesive units, not arbitrarily at line 400.

| Lines | File |
|---|---|
| 2026 | `data/features/attendance/datasources/attendance_remote_datasource.dart` |
| 1865 | `data/features/attendance/repositories/attendance_repository_impl.dart` |
| 1649 | `presentation/features/attendance/widgets/attendance_popup.dart` |
| 1628 | `presentation/features/attendance/view/screens/student_attendance_daily_view.dart` |
| 1579 | `presentation/features/attendance/view/staff_attendance_profile.dart` |
| 1502 | `presentation/features/attendance/view/screens/staff_attendance_daily_view.dart` |
| 1295 | `data/features/attendance/models/student_attendance_models.dart` |
| 1200 | `presentation/features/attendance/view/student_attendance_profile.dart` |
| 1173 | `presentation/features/attendance/view/screens/student_attendance_absent_view.dart` |
| 1119 | `presentation/features/attendance/view/screens/student_attendance_custom_view.dart` |
| 754 | `presentation/features/attendance/view/screens/staff_attendance_custom_view.dart` |
| 743 | `presentation/features/attendance/view_model/student_attendance_profile_fetch_cubit.dart` |
| 694 | `presentation/features/attendance/forms/staff_attendance_forms/staff_sign_in_form.dart` |
| 671 | `presentation/features/attendance/view/screens/staff_attendance_absent_view.dart` |
| 665 | `presentation/features/attendance/forms/student_attendance_forms/student_sign_in_form.dart` |
| 652 | `presentation/features/attendance/forms/staff_attendance_forms/staff_sign_out_form.dart` |
| 643 | `presentation/features/attendance/forms/staff_attendance_forms/staff_transfer_form.dart` |
| 610 | `presentation/features/attendance/forms/student_attendance_forms/student_sign_out_form.dart` |
| 574 | `presentation/features/attendance/view/staff_attendance_tabbed_view.dart` |
| 558 | `presentation/features/attendance/forms/student_attendance_forms/student_transfer_form.dart` |
| 511 | `presentation/features/attendance/forms/student_attendance_forms/student_override_sign_in_form.dart` |
| 497 | `domain/features/attendance/repositories/attendance_repository.dart` |
| 447 | `presentation/features/attendance/view/screens/widgets/attendance_card_shared.dart` |
| 430 | `presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_in_form.dart` |
