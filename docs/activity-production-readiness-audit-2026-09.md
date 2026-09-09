# ACTIVITY MODULE — Production Readiness Audit

**Date:** 2026-09-08 · **Type:** AUDIT ONLY (no code modified) · **Branch:** `develop-refactor` (HEAD `11a34327`, working tree clean)
**Scope:** `lib/{data,domain,presentation}/features/activit*/**` — **117 files, 39,893 LOC** (presentation 36,042 · data 2,443 · domain 1,408)
**Standard:** `docs/mandate-rules.md` (WowCare 2.0 Eight Mandates) + MVVM golden rule `View → Cubit → UseCase → Repository → DataSource`

**Confidence:** *CONFIRMED* = traced in code · *PROBABLE* = strong signal, not fully traced · *BACKEND* = not observable from the client.

---

## 1. Verdict

🟠 **NOT PRODUCTION READY** — one defect writes activity records against children the teacher explicitly removed from the form.

This module is in an unusual state: its **data and feed layers are the best-hardened in the app**, while its **10 form screens are the least-audited code in the repo**. The feed path has generation-token staleness guards, per-code single-flight moderation, 401-replay opt-outs, and tests for all of it. The write path — 22,000 lines of `StatefulWidget` forms — has **zero test coverage** and is where every finding below lives.

**Blockers (must fix before release):**

1. **P0-1** — Removing a student from the **medication** or **bathroom** form does not remove them from the submitted payload. The activity is created for the removed child anyway.
2. **P1-1** — No idempotency key on any activity mutation, though the shared helper exists and attendance uses it. A timed-out create that committed server-side duplicates on the user's retry.
3. **P1-2** — 3 of 4 photo-upload forms never cancel an in-flight upload on dispose.

---

## 2. Production defects

### 🔴 P0-1 · A removed student still gets the activity — *CONFIRMED*

Every activity form keeps the student selection in **two parallel lists** that must stay index-aligned:

- `selectedStudents` — `List<String>` of display names, drives the on-screen tiles
- `selectedStudentsData` — `List<Map<String,dynamic>>` of student records, **drives the submitted `studentCodes`**

**8 of the 10 forms** remove from both lists. **Two do not:**

```dart
// medication_activity_cubit.dart:267 — removes from ONE list
void removeStudent(String name) {
  final next = List<String>.from(state.selectedStudents)..remove(name);
  emit(state.copyWith(selectedStudents: next));      // selectedStudentsData untouched
}
```

```dart
// bathroom_activity.dart:742 — same omission
void _removeStudent(String name) {
  setState(() {
    _selectedStudents.remove(name);                   // _selectedStudentsData untouched
    if (_selectedStudents.isEmpty) Navigator.of(context).pop();
  });
}
```

Compare the sibling that gets it right — `bottle_activity_cubit.dart:287` — which removes from both. The two cubits were clearly ported from one another and medication lost a line.

The submitted payload is built from the list that was **not** updated:

- [medication_activity_cubit.dart:327](lib/presentation/features/activities/view_model/medication_activity_cubit.dart#L327) — `studentCodes` from `state.selectedStudentsData`
- [bathroom_activity.dart:948](lib/presentation/features/activities/view/edit_create_activity_screens/bathroom_activity.dart#L948) → passed as `studentCodes:` at [:1095](lib/presentation/features/activities/view/edit_create_activity_screens/bathroom_activity.dart#L1095)

Both are create-mode paths, and create mode is exactly where the remove affordance renders (`onRemove:` sits in the `else if (!_layoutAsEdit)` branch — [medication_activity.dart:264](lib/presentation/features/activities/view/edit_create_activity_screens/medication_activity.dart#L264), [bathroom_activity.dart:1485](lib/presentation/features/activities/view/edit_create_activity_screens/bathroom_activity.dart#L1485)).

> A teacher opens **Medication** for 3 children, realises one is wrong, taps ✕ on their tile. The tile disappears; 2 remain. She saves. **The backend receives all 3 student codes** and logs a medication administration against the child she removed.

**There is a second, visible symptom.** The tiles pair name and code by index:

```dart
itemCount: selectedStudents.length,
itemBuilder: (context, index) => ActivityStudentDisplayTile(
  name: selectedStudents[index],
  studentCode: index < state.selectedStudentsData.length
      ? state.selectedStudentsData[index]['studentCode'] as String? : null,
```

After a removal the lists are off by one, so **every remaining tile displays the wrong student's code** — with names `[A,B,C]` and data still `[dA,dB,dC]`, removing `A` renders name `B` beside `A`'s code. On a medication screen the code is the disambiguator between two children with the same first name.

**Fix:** remove from both lists in the two outliers, matching `bottle_activity_cubit.dart:287`. Then make the pairing structural — one `List<StudentSelection>` instead of two lists held in sync by convention — because this is the third place the convention has to hold and the first two are unguarded by tests.

*Not affected:* the scoped-edit checkboxes (`studentMapsForScopedActivityUpdate`, which also assumes index alignment) render only in edit mode, where the remove affordance is absent. The misalignment is not reachable from that path today — but the helper's contract is one refactor away from it.

### 🟠 P1-1 · No idempotency key on any activity mutation — *CONFIRMED (client) / BACKEND (impact)*

`grep -i idempot` across all 117 activity files returns **zero**. The shared helper exists and is wired for the neighbouring module:

- [lib/core/util/idempotency_key.dart](lib/core/util/idempotency_key.dart) — `headerName = 'Idempotency-Key'`, v4 generator
- `attendance_repository_impl.dart` threads `idempotencyKey` through ~10 mutation signatures

Activity's creates (`POST /api/v2/activities`, both the single and shared-card variants) send none.

**One replay vector is already closed.** All non-idempotent activity mutations set `kNoAutoReplayExtraKey` ([activity_remote_datasource.dart:173](lib/data/features/activity/datasources/activity_remote_datasource.dart#L173)), so a 401 token refresh surfaces the error instead of silently replaying — and there is a test asserting it. That is the vector that blocked attendance, and here it is handled.

**The remaining vector is the ordinary one:** a create POST that times out client-side after the server committed. The form re-enables Save, the teacher taps again, and a second record is written. Nothing on either side can tell the two apart.

Note the retry loops at [:489](lib/data/features/activity/datasources/activity_remote_datasource.dart#L489) and [:545](lib/data/features/activity/datasources/activity_remote_datasource.dart#L545) re-POST up to 4 times — but only on a 409 whose message matches `must reach ready before linking`, which means the server *rejected* the write. Those are safe.

**Whether a duplicate actually lands depends on server-side dedupe, which is not observable from the client.** Get that confirmed in writing; if the server does not dedupe, this is a P0.

### 🟠 P1-2 · Three upload forms never cancel on dispose — *CONFIRMED*

Four screens call `uploadActivityPhotoAttachments`. **Only `incident_activity` passes a `cancelToken`:**

| Form | `CancelToken` created | Threaded to upload | Cancelled in `dispose()` |
|---|---|---|---|
| `incident_activity` | ✅ [:177](lib/presentation/features/activities/view/edit_create_activity_screens/incident_activity.dart#L177) | ✅ [:2329](lib/presentation/features/activities/view/edit_create_activity_screens/incident_activity.dart#L2329) | ✅ [:2457](lib/presentation/features/activities/view/edit_create_activity_screens/incident_activity.dart#L2457) |
| `photo_activity` | ✅ [:162](lib/presentation/features/activities/view/edit_create_activity_screens/photo_activity.dart#L162) | ✅ [:711](lib/presentation/features/activities/view/edit_create_activity_screens/photo_activity.dart#L711) | ✅ [:1410](lib/presentation/features/activities/view/edit_create_activity_screens/photo_activity.dart#L1410) |
| `learning_activity` | ❌ | ❌ [:527](lib/presentation/features/activities/view/edit_create_activity_screens/learning_activity.dart#L527) | ❌ |
| `notes_activity` | ❌ | ❌ [:870](lib/presentation/features/activities/view/edit_create_activity_screens/notes_activity.dart#L870) | ❌ |
| `outdoor_activity` | ❌ | ❌ [:623](lib/presentation/features/activities/view/edit_create_activity_screens/outdoor_activity.dart#L623) | ❌ |

The parameter is optional, so the three omissions compile silently. `uploadAssets` runs a **sequential** presign → PUT → complete loop per file; with no token, backing out mid-upload leaves that loop running to completion against a disposed widget. No crash — the `mounted()` guards hold — but the upload keeps consuming a teacher's mobile data, and every asset it completes is orphaned in a session no activity will ever reference.

### 🟡 P2-1 · A partial upload discards all progress — *CONFIRMED*

[activity_media_upload_repository_impl.dart:44-81](lib/data/features/activity/repositories/activity_media_upload_repository_impl.dart#L44-L81) accumulates `assetCodeByPath` inside the per-file loop, but returns it **only after every file succeeds**. If file 3 of 5 fails, the exception propagates and the codes for files 1–2 die with the stack frame.

Back in the caller, `state.assetCodeByPath.addAll(result.assetCodeByPath)` is never reached ([activity_photo_attachment_upload.dart:141](lib/presentation/features/activities/utils/activity_photo_attachment_upload.dart#L141)), so the retry cache stays empty and **the retry re-uploads all 5 from scratch** — leaving the first two orphaned server-side, twice over.

The `addAll`-after-`waitUntilAssetsReady` ordering is deliberate and correct (its comment explains the 409 it prevents). The gap is that a partial failure has no resumption path at all.

### 🟡 P2-2 · 105 silent catches, zero logger adoption — *CONFIRMED*

Of **213** catch blocks in the module, **105** are `catch (_) {}` — they discard the error entirely. Worst: `activity_custom_tab` (9), `incident_activity` (8), `photo_activity` (7), `activity_daily_tab` (7), and 3 inside `activity_feed_cubit` itself.

`AppLogger` appears **0 times** in all 117 files. Attendance routes its failures through it; activity does not, so none of these reach Crashlytics. Some are legitimately best-effort — but in production none is distinguishable from a swallowed defect.

### 🟡 P2-3 · Upload owner code bypasses its own normalisation — *CONFIRMED*

[activity_photo_attachment_upload.dart:73](lib/presentation/features/activities/utils/activity_photo_attachment_upload.dart#L73):

```dart
final ownerCode = isShared ? classroomCode.trim() : studentCodes.first;
```

`normalizedStudentCodes` (trimmed, blank-filtered, sorted) is computed 15 lines above — and used **only** to build the cache key. `ownerCode` takes the raw first element, so a leading `''` or `'  '` produces `ownerType: STUDENT, ownerCode: ''` on the presign, and an empty `studentCodes` throws `StateError: No element`. Callers guard emptiness upstream today, which is what keeps this latent.

### 🔵 P3-1 · 10 `debugPrint` calls ship to release — *CONFIRMED*

`debugPrint` is not stripped in release builds. Ten remain, eight of them in `upload_photo_video.dart` including `initState`/`dispose` lifecycle traces.

**No PII leak** — the incident one is explicitly written to log parameter *codes* and never values, with a comment saying why. This is log noise and a missed `AppLogger` migration, not a privacy defect.

### 🔵 P3-2 · The entire write path is untested — *CONFIRMED*

**42 tests across 14 files, all green.** They cover the feed cubit's staleness guards, moderation single-flight, editor single-flight, the no-replay flag, repository de-duplication, entity parsing, and deep-link keys — genuinely good tests, all of them written against the *feed* and *data* layers.

**Zero tests touch any of the 10 form screens.** P0-1 is a two-line defect that any test of `removeStudent` would have caught.

### 🔵 P3-3 · Stale comment describes a fixed bug — *CONFIRMED*

[activity_photo_attachment_upload.dart:88-95](lib/presentation/features/activities/utils/activity_photo_attachment_upload.dart#L88-L95) carries an 8-line comment explaining that declaring every photo `image/jpeg` breaks HEIC uploads — directly above code that correctly calls `lookupMimeType(photo.path)`. The bug is fixed; the comment says it isn't.

---

## 3. Mandate compliance

| # | Mandate | Status | Evidence |
|---|---|---|---|
| 1 | GoRouter everywhere | 🔴 **Fail** | **54** `Navigator.*`/`MaterialPageRoute` refs across 19 files. Exactly **one** activity route registered (`AppRoutes.activityFeed`); all 10 edit/create screens, the student selection, filter and full-screen-media screens navigate outside GoRouter. |
| 2 | setState scarcely | 🔴 **Fail** | **332** `setState` calls. Worst: `activity_daily_tab` (39), `photo_activity` (31), `incident_activity` (31), `activity_custom_tab` (27). Most are Bucket A (API results, filters, selections) — and P0-1 is a direct consequence of form state living in `State` fields. **See §4 for the `setState`-over-cubit anti-pattern in both tabs.** |
| 3 | Folder structure | 🟠 **Partial** | `model/`, `view/`, `view_model/`, `widgets/` all present and correctly used. But a **`utils/` folder (12 files)** exists, which the mandate explicitly disallows — and it holds real business logic (`activity_attendance_window_validator`, `activity_school_time`, `resolve_logged_in_staff_code`) that belongs in `domain/usecases/`. Data layer has **no `mappers/`**. **256** relative cross-folder imports where the mandate requires `package:wowcare/...`. |
| 4 | Centralized theming | 🟢 **Near-pass** | **0** raw `Color(0x…)`/`Colors.<name>` — fully tokenised through `AppColors` (189 uses). **0** inline `TextStyle(`. Residue: **3** `fontFamily:` lines (find-and-delete), **9** hardcoded user-visible strings with **0** `AppStrings` uses, and **130** `EdgeInsets` literals with **0** `AppSizes` uses. |
| 5 | Presentation talks to cubits only | 🟠 **Partial** | **28** `serviceLocator` refs in presentation, none in a `GoRoute` builder. Four `utils/` files resolve `StorageService`/`ApiClient`/`StaffRepository`/use-cases directly; `activity_custom_tab.dart:559` resolves `StorageService` inside the View. `ActivityEditorCubit` takes `ApiClient` and `StaffRepository` rather than use cases. The moderation and feed cubits are clean. |
| 6 | Reuse; ≤400 lines | 🔴 **Fail** | **25 files over 400 lines**, topping out at **5,468** (`activity_daily_tab`), 3,255 (`activity_custom_tab`), 3,090 (`incident_activity`). **20** `Widget _buildXxx()` methods remain. ✅ No duplicate class names introduced anywhere in the module. |
| 7 | One responsive source | 🟠 **Partial** | 3 `MediaQuery.of(` vs 1 `MediaQuery.sizeOf(`. 3 `LayoutBuilder`s. Small surface; the module mostly reads `responsive.isTablet` correctly. |
| 8 | Models generated, never raw maps | 🔴 **Fail** | **0** `@JsonSerializable`, **0** `.g.dart` — all serialisation hand-written, which is the mandate's central requirement. **14** `Map<String,dynamic>` in `lib/domain` and **159** in `lib/presentation`, both explicitly forbidden. The repository contract itself returns `Future<Map<String,dynamic>>` (`getActivityByCode`) and `List<Map<String,dynamic>>` (`getActiveActivityTypesForSchool`, `createSharedActivities`). The two-parallel-lists shape behind P0-1 is a direct symptom: `selectedStudentsData` is an untyped map list where a `StudentSelection` model belongs. |

---

## 4. The `setState`-over-cubit anti-pattern

Both feed tabs create their cubit manually and subscribe with a raw stream listener rather than `BlocBuilder`:

```dart
// activity_daily_tab.dart:332 (and activity_custom_tab.dart, identically)
_feedCubitSub = cubit.stream.listen((_) {
  if (mounted) setState(() {});
});
```

Every cubit emit — including each pagination append and each `isLoadingMore` toggle — rebuilds the **entire 5,468-line widget tree**. This inverts the stated rationale for Mandate 2: the migration to a cubit was completed, but the rebuild-scoping benefit that justified it was discarded at the last step. `BlocBuilder`/`BlocSelector` around the list would confine the rebuild to the rows that changed.

The lazy construction itself is well-reasoned and documented (a `BlocProvider.create` would freeze `viewerStaffDisplayName`/`schoolIana` before bootstrap resolves them) — that constraint is real, but it argues for deferring `BlocProvider`, not for bypassing `BlocBuilder`.

---

## 5. What is genuinely solid

Verified in code and by test, not assumed:

| Area | State |
|---|---|
| **Feed race safety** | `ActivityFeedCubit` bumps a monotonic `_generation` per load and checks `_isStale(gen, schoolAtStart)` before **every** emit — including a school-switch check. `loadNextPage` captures the generation *without* bumping, so a refresh discards an in-flight page. This is precisely what attendance's P0-2/P0-3 were missing. Tested, including the stale-response and school-switch cases. |
| **Pagination on short lists** | Both tabs auto-advance via a post-frame `_maybeLoadNext…Page()` after each successful load, and both handle `maxScrollExtent <= 0` explicitly — so a client-filtered list too short to scroll still paginates. This is the newsletter P1-1 defect, correctly avoided here. |
| **401 replay** | `kNoAutoReplayExtraKey` on create, shared-create, update, upload-session, presign, and all four moderation actions. Test-asserted. |
| **Moderation double-tap** | `ActivityModerationCubit` keys single-flight by activity code, so a double-tap or racing approve+reject on one card drops the duplicate while a different card stays actionable. Tested. |
| **Payload de-duplication** | The repository de-dupes and trims `studentCodes` before dispatch and derives `bindingMode` from the *deduped* set, so a duplicated single student cannot flip `PER_STUDENT` → `SHARED`. Tested. |
| **Asset readiness** | `assetCodeByPath` is committed only after the blocking ready-poll, closing the 409 "must reach ready before linking" path the comment documents. |
| **Analyzer** | **0 issues** across all three layers. |
| **Theming** | 0 colour literals, 0 inline `TextStyle` — the cleanest Mandate 4 result of any module audited so far. |

---

## 6. Recommended order

**Before release:**

1. **P0-1** — two lines in `medication_activity_cubit.removeStudent` and `bathroom_activity._removeStudent`, plus a regression test per form. Then collapse the two lists into one typed model.
2. **P1-1** — get written backend confirmation on create dedupe. If absent, thread `IdempotencyKey` through the activity mutations exactly as attendance does. **This is the release gate**; without an answer the verdict stays 🟠.
3. **P1-2** — three `cancelToken:` arguments and three `dispose()` cancels, copied from `incident_activity`.
4. **P3-2** — characterisation tests for the form write path, starting with student selection/removal. Cheapest insurance against the next P0-1.
5. **P2-1 / P2-3** — return partial upload progress on failure; use `normalizedStudentCodes.first` for `ownerCode`.

**Then, mandate debt (not release-blocking):**

6. **P2-2** — route the 105 silent catches through `AppLogger.c`, and replace the 10 `debugPrint`s. Mechanical, and it restores production visibility.
7. Mandates 1 + 5 as a pair (per `mandate-rules.md`'s revised order) — 54 `Navigator` calls, 28 `serviceLocator` refs, and the `utils/` folder's business logic all move together.
8. Mandate 2 + the §4 `BlocBuilder` fix, then Mandate 6's file splits (25 files, one of them 5,468 lines).
9. Mandate 8's `json_serializable` migration last — highest risk, and `mandate-rules.md` requires an old-vs-new fixture test per parser before any hand-written parser is deleted. Do not start it before the P0 ships.

## 7. Release call

**Hold.** P0-1 writes a medication record against a child the teacher removed from the form — on a childcare compliance record that is not a cosmetic defect, and it is a two-line fix.

Everything downstream of the forms is in good shape. The feed, moderation and data layers would pass on their own today; it is the untested 22,000-line form tier that is holding the module back, and P0-1 is the evidence that it needs tests before it needs refactoring.

---

*Audit performed against a clean working tree at `11a34327`. `flutter analyze` on the three activity directories: **0 issues**. `flutter test` on the activity test directories: **42 passing, 0 failing**. No files were modified.*
