# STUDENT MODULE — STEP 2 / PHASE 4: FORM SCREENS (SCOPE)

> Branch `audit/student-fixes`. Phases 1–3 (read/list surface) are DONE & verified. Phase 4 is the
> **write surface** — the editor/wizard/add form screens. This doc scopes it; **no code yet**.

## ✅ PHASE 4 COMPLETE (all form screens migrated; +68 form-cubit tests, suite 93 → 161)
Tier A (5) + Tier D-document + Tier B (3) + Tier D-step3 (new StudentScheduleCubit) + Tier C
(edit_profile_details) all done, test-first, each verified. Legacy dead `add_student_screen` (499 lines,
unrouted single-page variant) deleted. Only the deferred `student_profile_tab._profileFuture` MVVM holdout
remains (needs entity enrichment first — out of Phase 4 scope).

## HEADLINE FINDING — this is smaller than the audit feared
Phase 4 was estimated at "~60 `setState` across form screens, build per-editor form cubits." On
inspection, **the form cubits already exist and are already wired** to every form screen except one.
So Phase 4 is mostly **"move the remaining view-held form-model + submit/fetch state INTO the existing
cubit"**, NOT "build cubits from scratch." That materially lowers effort and risk.

- **11 of 12 form screens already read/write a cubit** (create / profile-edit / pickup / physician /
  document / health / important-dates / physical-exam / tags). Those cubits handle the actual API
  mutation + list — but the **form field model, the `_isSubmitting`/`_isUploadingFile` flag, and the
  server-fetched dropdown lists still live in the View as `setState`.**
- **1 gap:** `add_student_step3_screen` (schedule step) has **no cubit** — it holds `_schedule` /
  `_schoolMinutesByDay` / `_copyToAllDays` locally and returns the schedule via `context.pop(_schedule)`.
- **1 likely-dead screen:** `add_student_screen` (a separate single-page StatefulWidget, 6 `setState`).
  The LIVE add path is `add_student_wizard_screen` → step1 → step2 → step3. **Confirm routing before
  touching** — if unrouted, delete rather than migrate.

## THE RULE — what moves vs. what stays
| Moves INTO the cubit (this phase) | Stays LOCAL in the View (category H) |
|---|---|
| Submit/upload in-flight: `_isSubmitting`, `_isUploadingFile` | `TextEditingController`s + their `.text` syncs |
| Server-fetched dropdown data: `_existingParents`, `_existingCarers`, `_availableTagNames`, `_availableStudentNames`, `_availableGuardianNames`, `_schoolMinutesByDay` | `FocusNode`s |
| Upload result: `_uploadedAssetCode`, `_selectedFile` | Ephemeral pure-view toggles (e.g. a picker's open state) |
| Form field model: `_selectedStatus/Classroom/Relation/Carer/BirthDate/ExpiryDate/ExamDate`, `_selectFromExisting`, `_selectedExistingParents`, `_isEmergencyContact`, `_isChildCustody`, `_copyToAllDays`, `_schedule`, `_profilePhoto` | — |
| Server-derived gate: `_isSignedInToday` | — |
| Validation + submit orchestration (`_validate*`, `_onNext`, create/update calls) | — |

Controllers are legitimately local (like the Phase-2/3 keep-set) — Phase 4 does NOT try to remove them.
It moves the **data model + async status + validation** behind the cubit; the widget binds controllers to
cubit state and reads `state` via BlocBuilder.

## INVENTORY (form screens, by setState count)
| # | Screen | setState | Cubit (wired) | Cubit test? | Tier |
|--:|---|--:|---|:--:|:--:|
| 1 | `edit_student_profile_details_screen` | 18 | StudentProfileEditCubit | ✅ | C |
| 2 | `add_student_step2_screen` | 10 | StudentCreateCubit | ✅ | B |
| 3 | `add_pickup_screen` | 9 | StudentPickupCubit | ✅ | B |
| 4 | `add_student_step1_screen` | 8 | StudentCreateCubit | ✅ | B |
| 5 | `add_document_screen` | 8 | StudentDocumentCubit | ❌ (only download test) | D |
| 6 | `add_student_step3_screen` | 6 | **none** | ❌ | D |
| 7 | `add_student_screen` (legacy?) | 6 | none | ❌ | — verify/delete |
| 8 | `student_tags_edit_sheet` | 5 | StudentTagsCubit | ✅ | A |
| 9 | `edit_student_physical_exam_screen` | 4 | StudentPhysicalExamCubit | ✅ | A |
| 10 | `edit_student_health_screen` | 3 | StudentHealthCubit | ✅ | A |
| 11 | `add_physician_screen` | 2 | StudentPhysicianCubit | ✅ | A |
| 12 | `edit_student_important_dates_screen` | 1 | StudentImportantDatesCubit | ❌ | A (fill test first) |

## PROGRESS
### Tier A
- ✅ **`edit_student_important_dates_screen` — DONE & verified (TDD).** Wrote the missing
  `student_important_dates_cubit_test.dart` FIRST (9 tests: initial/seed/edit/save-success/save-error/
  latest-values) → confirmed RED → implemented. `StudentImportantDatesState` gained the form model
  (`enrollDate`/`schoolStartDate` + `_unset`-sentinel `copyWith`, dates preserved through
  loading/success/error); cubit gained `initialize()`, `setEnrollDate()`, `setSchoolStartDate()`, and
  `save({studentCode})` (builds the entity from its own state). Screen: removed both `_enrollDate`/
  `_schoolStartDate` fields + the lone `setState`; `initState` seeds via `initialize()`; date picks call
  the cubit setters; date fields read `state.enrollDate`/`state.schoolStartDate` (already inside the
  `BlocBuilder`); `_save` → `cubit.save(...)`. Removed the now-unused entity import. Analyzer clean,
  **student suite 93 → 102 tests, all pass.**
- ✅ **`add_physician_screen` — DONE & verified (TDD).** The cubit ALREADY tracked `mutationInProgress`
  in state around add/update (redundant with the view's `_isSubmitting`) — so this was a delete-the-dup
  slice. Added the missing test first (`add flips mutationInProgress true→false`, gated Completer on the
  add fake) → then removed `_isSubmitting` + both its `setState`; the re-entry guard now reads
  `_physicianCubit.state.mutationInProgress` (backed by the cubit's single-flight dedup); the Save button
  is driven by a `BlocBuilder(buildWhen: mutationInProgress)`; dropped the now-redundant try/finally.
  Controllers + snackbar validation stay local (correct — category H / UI-bound). Analyzer clean,
  **student suite 102 → 103, all pass.**
- ✅ **`edit_student_health_screen` — DONE & verified (TDD).** Same shape as physician: cubit already
  tracked `mutationInProgress` around `updateHealth`. Added the gated `updateHealth flips
  mutationInProgress` test → removed `_isSaving` + its two `setState`; re-entry guard reads
  `_healthCubit.state.mutationInProgress` (+ existing single-flight); Save button via
  `BlocBuilder(buildWhen: mutationInProgress)`; kept the try/catch error snackbar (moved the success
  snackbar behind a `mounted` guard — fixes a latent use-context-after-await). Of the 3 `setState`, the
  third was already **dead code** (the commented-out photo-permission `Switch`), so `_photoPermission`
  stays a local seed value with a comment (moves to cubit form model only if the switch is re-enabled).
  Analyzer clean, **student suite 103 → 104, all pass.**
- ✅ **`edit_student_physical_exam_screen` — DONE & verified (TDD).** First slice to move real FORM MODEL
  (not just a submit flag): `StudentPhysicalExamState` gained `formExamDate`/`formStatus` (`_unset`-sentinel
  `copyWith`); cubit gained `initializeForm()`, `setFormExamDate()`, `setFormStatus()`. Wrote 6 tests first
  (form init/seed/edit + gated `add` `mutationInProgress`) → RED → implemented. Screen: removed `_examDate`/
  `_status`/`_isSaving` (all 4 `setState`); `initState` seeds via `initializeForm` (kept the API→display
  status map as a `static` helper); date pick → `setFormExamDate`; dropdown → `setFormStatus`; `_save` reads
  the model from `_examCubit.state` and guards on `mutationInProgress`; build wrapped in `BlocBuilder`.
  The timezone/date validation + snackbars correctly STAY in the widget (context-coupled UI feedback).
  Analyzer clean, `dart format`ed, **student suite 104 → 110, all pass.**
- ✅ **`student_tags_edit_sheet` — DONE & verified (TDD). Richest Tier-A slice** (fetch + selection +
  load/submit all moved). `StudentTagsState` gained `isLoading`/`availableTagNames`/`tagNameToCode`/
  `selectedTags`/`schoolCode`; cubit gained `beginLoading()`, `load({schoolCode, initialTagNames})`
  (fetches names+map, drops preselected tags no longer valid, emits), `setSelectedTags()`, and
  `saveTags({studentCode})` (resolves selected names→codes off state, routes through existing `updateTags`
  single-flight). Wrote 7 tests first (init/beginLoading/load-success+filter/load-error/setSelected/
  saveTags-codes/saveTags-mutationInProgress) → RED → implemented. Sheet: removed all 6 fields + all 5
  `setState`; school resolution (StorageService) stays widget-side, passed into `load`; `beginLoading()`
  in initState avoids a first-frame form flash; build wrapped in `BlocBuilder`; dropdown → `setSelectedTags`;
  Save button → `state.mutationInProgress`; load error surfaced via `state.errorMessage` after the awaited
  `load`. Analyzer clean, `dart format`ed, **student suite 110 → 117, all pass.**

### Tier D
- ✅ **`add_document_screen` — DONE & verified (TDD). FULL MOVE** (user-chosen scope: orchestration too).
  Flattened `StudentDocumentState` from a subclass hierarchy into one status-based state carrying the form
  model + file-upload progress/result + submit phase (`DocumentSubmitStatus`/`DocumentUploadStatus` enums;
  `_unset`-sentinel `copyWith`; back-compat `isLoading/isSuccess/isError/message` getters). Injected
  `ImageUploadService` + `StorageService` into the cubit; moved the **entire upload orchestration**
  (session → presign → PUT-with-progress → complete → asset-ready + background URL resolve) plus
  `setDocumentType`/`setExpiryDate`/`initializeForEdit`/`submit` into it. Wrote 9 tests first (form setters,
  upload happy-path w/ progress + bg-url, missing-context fail, service-error fail, submit add/edit/error/
  no-file) using `implements` fakes for the services (avoids the ApiClient ctor) + a real temp file. Widget:
  held the cubit as a field (seeds edit in initState), removed all 8 `setState` + the whole
  `_uploadSelectedFile` (~100 lines); file pick → `cubit.uploadFile`; `_buildX` read via `context.watch`;
  upload failures surfaced through a `BlocListener` on `uploadErrorMessage`; controllers + snackbar
  validation stay local. DI updated. Removed 4 now-unused imports. Analyzer clean, `dart format`ed,
  **student suite 117 → 126, all pass.**

### Tier B
- ✅ **`add_pickup_screen` — DONE & verified (TDD).** Same rich shape as tags (submit flag + server fetch +
  selection). `StudentPickupState` gained `selectFromExisting`/`selectedCarer`/`selectedRelation`/
  `existingCarers`/`guardianDetailsByName` (`_unset`-sentinel `copyWith`); cubit gained `initializeForm`,
  `setSelectFromExisting`/`setSelectedCarer`/`setSelectedRelation`, and `loadCarers({schoolCode, names})`
  (fetches raw guardians via its own use case, builds the name→details lookup, drops a stale selection —
  names still come from the widget's use case). Wrote 7 tests first (form defaults/init/setters/loadCarers
  success+drop+error/`add` mutationInProgress) → then removed all 6 `setState` targets; guards read
  `state.mutationInProgress` (single-flighted); `_onSave` reads the form model from `state`; build wrapped
  in one `BlocBuilder`; toggle/dropdown/relation call the cubit setters. One `setState` KEPT (H) — the
  manual-entry `RelationSelector`'s controller-text sync. Analyzer clean, `dart format`ed, **student suite
  126 → 133, all pass.**
- ✅ **`add_student_step1_screen` — DONE & verified (TDD, FULL MOVE).** `StudentCreateState` gained the
  step-1 form model (`step1Status`/`step1Classroom`/`step1Birthdate`/`step1SchoolStartDate`/
  `step1ProfilePhoto`(File?)/`step1AgeLabel`/`step1Submitting`, `_unset`-sentinel `copyWith`); cubit gained
  `initializeStep1`, five setters (`setStep1Birthdate` derives the age label via the new static
  `ageLabelFor`), and `setStep1Submitting`. **Key nuance:** `_isSubmitting` here is a FLOW-level guard
  spanning create → sibling-link → step-2 hand-off, so it maps to a dedicated `step1Submitting` flag, NOT
  per-call `mutationInProgress`. Wrote 7 tests first → then removed all 8 `setState` + the `_calculateAge`/
  `_formatAgeLabel` helpers; dropdowns/date-pickers/photo call cubit setters; validation/submit read
  `_createCubit.state.step1*`; build wrapped in a `BlocBuilder<StudentCreateCubit>` (nested over the
  existing `ClassroomCubit` builder) for reactivity. Analyzer clean, `dart format`ed, **student suite
  133 → 140, all pass.**
- ✅ **`add_student_step2_screen` — DONE & verified (TDD, FULL MOVE).** `StudentCreateState` gained the
  step-2 parent sub-form model (`step2SelectFromExisting`/`step2SelectedExistingParents`/`step2Relation`/
  `step2IsEmergencyContact`/`step2IsChildCustody`/`step2ProfilePhoto`(File?)/`step2ExistingParents`/
  `step2Submitting`); cubit gained `initializeStep2`, seven setters, and `setStep2ExistingParents` (stores
  names + prunes a stale selection). `step2Submitting` is again a FLOW flag (guardian create/link + bg photo
  upload). Wrote 4 tests first → then removed all 10 `setState`; toggles (select-existing / emergency /
  custody), both relation dropdowns, existing-parent dropdown, and photo call cubit setters; validation/
  submit/`_buildStep2Data` read `_createCubit.state.step2*`; build wrapped in a `BlocBuilder<StudentCreateCubit>`.
  Analyzer clean (the 6 remaining feature-wide warnings pre-date this work — `student_profile_screen._fteDisplay`
  + deprecated Radio in `same_last_name_siblings_dialog`, neither touched here), `dart format`ed, **student
  suite 140 → 144, all pass.**

### Tier D-step3
- ✅ **`add_student_step3_screen` — DONE & verified (TDD). NEW `StudentScheduleCubit`** (the one true cubit
  gap). Created `StudentScheduleCubit` + `StudentScheduleState` (owns `schedule`/`copyToAllDays`/
  `schoolMinutesByDay`/`hasInitialSchedule`) and moved ALL the schedule logic in: `initialize` (deep-copy),
  `loadSchoolSchedules` (via `GetSchoolRegularSchedulesUseCase`, prunes now-closed days, returns removed
  days), `applyPickedTime`/`removeDay`/`enableDay`/`setCopyToAllDays`, the working-hours validation
  (`validateDaySchedule`/`validateAllScheduledDays`/`validateForSubmit`, each returning an error string the
  view shows), plus the time/default helpers. Wrote 12 tests first (init deep-copy, load keep/exclude/prune/
  error, applyPickedTime valid/out-of-hours/copy-all, enable/remove, submit validation). DI-registered.
  Widget rewritten to a thin renderer (~730 → ~470 lines): held cubit as a field, `initState` seeds+loads,
  build wrapped in `BlocBuilder`, time-picks/toggle/remove/enable call cubit methods and snackbar returned
  errors, `_onNext` = `validateForSubmit` then `pop(state.schedule)`. Removed the now-unused `StaffRepository`
  import. Analyzer clean, `dart format`ed, **student suite 144 → 156, all pass.**

### ✅ TIER C — `edit_student_profile_details_screen` DONE & verified (TDD, FULL MOVE, the biggest screen)
1470-line screen, ~23 form-model fields → all moved into `StudentProfileEditState` (`_unset`-sentinel
`copyWith`): status/gender/classroom(+`classroomChangedByUser`)/birthDate/state/country/subsidy, the three
multi-selects (tags/siblings/custody), the flow `submitting` flag, the attendance gate
(`isTodayStatusLoading`/`isSignedInToday`), and the three server option lists + their code-maps +
`guardianInitialCustody` + `guardianRawByCode`. Cubit gained `initialize`, per-field setters (`setClassroom`
flags the user change; `setTodayStatus` resolves the gate) and three `apply*Loaded` methods; the view keeps
the fetch+mapping orchestration and calls them. Wrote 5 tests first (init/setters/classroom-flag/gate/
apply-loaded). Widget: removed all 22 fields + all 18 `setState`; **read sites kept working via read-through
getters onto `_profileEditCubit.state`** (lowest-risk — only writes changed); dropdowns/date/submit call
cubit setters; the load methods compute pruned/mapped values then `apply*Loaded`; `_buildScreen` wrapped in
a `BlocBuilder<StudentProfileEditCubit>` for reactivity. Analyzer clean, `dart format`ed, **student suite
156 → 161, all pass.**

### ✅ TIER B COMPLETE (3 screens: add_pickup, add_student_step1, add_student_step2)
The shared `StudentCreateCubit` now owns both wizard steps' form models (step1 + step2) via a `step1*`/
`step2*` namespaced state; each step's FLOW submit flag (`step1Submitting`/`step2Submitting`) is distinct
from per-call `mutationInProgress`. Remaining Phase 4: **step3** (new `StudentScheduleCubit`), **Tier C**
(`edit_student_profile_details_screen`, 18 setState), and the legacy `add_student_screen` cleanup.

### ✅ TIER A COMPLETE (5 screens: important_dates, physician, health, physical_exam, tags)
Student test suite grew **93 → 117** (+24 form-cubit tests). Pattern proven across all three shapes:
pure submit-flag dedup (physician/health), form-model move (important_dates/physical_exam), and full
fetch+selection+submit ownership (tags). Next: **Tier D — `add_document`** (write the upload-state test
first), then Tier B (create steps + pickup), Tier D-step3, Tier C (profile-details), cleanup.

## PROPOSED ORDER (test-first, ascending risk)
Each screen is its own decision-gated slice: **(a)** ensure/extend the cubit's state to hold the moved
fields, writing the cubit test FIRST for the new state/validation; **(b)** move the fetch/submit/model off
the View into the cubit; **(c)** widget binds controllers + `BlocBuilder`; **(d)** verify `flutter analyze`
+ that cubit's test + the student suite each time.

1. **Tier A — warm-ups (cubit + test exist, 1–5 setState).** `important_dates` (write test first — none yet),
   `physician`, `health`, `physical_exam`, `tags`. Small, low blast-radius; establishes the exact
   form-migration pattern on safe ground.
2. **Tier D-doc — `add_document`.** Cubit exists but has NO form test — write the upload/submit-state test
   first, then move `_isUploadingFile`/`_uploadedAssetCode`/`_selectedFile`/`_selectedExpiryDate` in.
3. **Tier B — the create-flow steps + pickup (8–10 setState, cubit + test exist).** `step1`, `step2`,
   `pickup`. These share `StudentCreateCubit`; extend its state with the step field models rather than
   new cubits.
4. **Tier D-step3 — `add_student_step3_screen` (the one true cubit gap).** Introduce a
   `StudentScheduleCubit` (state = `schedule` + `schoolMinutesByDay` + `copyToAllDays`; methods =
   `setDay/clearDay/copyToAll/validate`), test-first, then convert the screen. It's a self-contained
   value-returning editor, so this is contained.
5. **Tier C — `edit_student_profile_details_screen` (18 setState, the largest).** Do LAST, once the
   pattern is proven — it mixes the attendance gate (`_isSignedInToday`), three server dropdown fetches,
   the full profile field model, and submit. Highest blast-radius edit on the write path.
6. **Cleanup — `add_student_screen`.** Verify it's routed; if it's the dead single-page variant, delete
   it (don't migrate dead code).

## RISK NOTES (read before starting Phase 4)
- **Forms are the write surface → a state bug = lost user input or a bad backend write** (student/guardian
  creation). This is why every slice is **test-first**, unlike the Phase 1–3 read-path work which the
  existing 93 tests backstopped.
- **Controllers must stay local and stay the source of text truth.** Don't mirror every keystroke into
  cubit state (rebuild storms + cursor jumps). Bind controller→cubit on commit points (onChanged debounced,
  or onSubmit), and seed controllers from cubit state on init only.
- **`StudentCreateCubit` is shared across step1/step2/(step3 submit).** Extending its state for step field
  models is correct, but keep the steps' slices additive/backward-compatible (same optional-dep discipline
  used in Phase 1) so a partially-migrated wizard still compiles and the create test stays green.
- **Two cubits lack form tests** (`document`, `important_dates`) — those tests are the FIRST deliverable of
  their slice, not an afterthought.
- **Scope guard:** `add_student_screen` and any other unrouted legacy form must be confirmed dead before
  deletion; if still routed, it gets migrated like the rest.

## OUT OF SCOPE for Phase 4
- The Phase-1 attendance-action holdouts in `student_screen` (`_isAttendanceActionLoading` + row-action
  feedback) — those are read-surface, KEEP-with-justification (documented in STEP-2-STATE-AUDIT.md).
- `student_profile_tab._profileFuture` — the documented MVVM/S6 typed-model holdout (needs entity
  enrichment first).
