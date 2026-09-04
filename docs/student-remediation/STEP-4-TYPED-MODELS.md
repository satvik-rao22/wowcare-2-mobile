# STUDENT MODULE — STEP 4: TYPED MODELS / REMOVE RAW MAPS

> Branch `audit/student-fixes`. Goal: no raw JSON (`Map<String,dynamic>`) leaks into student
> presentation / domain entities / cubit state where a typed model fits. Serialization belongs to the
> data layer (Model → Mapper → Entity; Domain Request → Mapper → payload). Scope: **A, B, C, D** all done
> (D added in a later pass, one endpoint per commit); E kept. Test-first, each verified. The student domain
> is now raw-map-free (only doc comments reference the old shapes).

## AUDIT (classified)
Searched student domain/presentation/data for `Map<String,dynamic>`, `fromMap(`, `toMap(`, `toPayload(`,
`json*`. Established architecture confirmed: `data/features/student/{models,mappers}` already own
serialization — two domain leaks were the exception.

## DONE
### A — domain-purity leaks (the two files the prompt named) ✅
- **A1 `SchoolGuardianSummary.fromMap`** → moved to `data/.../mappers/school_guardian_summary_mapper.dart`
  (`schoolGuardianSummaryFromMap`); `student_repository_impl` calls it; entity is now pure. 3 mapper tests.
- **A2 `StudentHealthUpdateRequest.toPayload`** → moved to
  `data/.../mappers/student_health_update_request_mapper.dart` (`studentHealthUpdateRequestToPayload`);
  `student_repository_impl` calls it; entity is now pure. 1 mapper test.
  No duplicate models introduced (datasource already deals in raw maps for these endpoints).

### B — cubit-state raw map ✅
- **`StudentProfileEditState.guardianRawByCode`** `Map<String, Map<String,dynamic>>` →
  `Map<String, StudentGuardian>` (existing entity, no duplicate). Build stores the entity directly; the
  custody-PATCH submit reads typed properties (`raw.userCode`/`firstName`/…), `rawStr` helper removed.
  **Also fixed a latent bug:** the old code did `row['raw'] as Map<String,dynamic>` on a `StudentGuardian`,
  which threw and was swallowed by the surrounding `catch (_)` — so custody records silently failed to load.

### C — presentation `sibling` raw map ✅
- New typed UI view-model `presentation/features/students/models/student_sibling_info.dart`
  (`StudentSiblingInfo{names,relations,statuses}`) replaces `Map<String,dynamic> sibling` across
  `student_profile_screen`, `student_profile_tab`, `student_about_tab_card`, `student_card`, and the
  `student_screen` studentMap value. All construction/read sites typed; 4 cross-module callers of
  `StudentProfileScreen` (app_router, classroom, availability, user-profile) + 1 widget test updated. 2 tests.

### D — repository-contract raw maps ✅ (done — one endpoint per commit)
All five domain-contract raw maps are now typed request/response models with data-layer mappers:
- **`updateStudentAddress`** → `UpdateStudentAddressRequest` (schoolCode kept as a cache hint, not in body).
- **`updateStudentProfile`** → `UpdateStudentProfileRequest` (mapper omits dob/gender when null; nested classroom).
- **`updateGuardian`** → `UpdateGuardianRequest` (superset; optional code/relationshipDescription/updatedBy so
  the custody flow and the edit-guardian flow each reproduce their exact body; both cubits typed).
- **`updateStudentRegularSchedules`** → `List<StudentRegularScheduleInput>` (write model, distinct from the READ
  `StudentRegularScheduleEntry`). NOTE: step1 still calls the datasource directly (pre-existing repo bypass) —
  separate architecture concern, out of scope.
- **`getGuardianProfile`** (the one read) → `GuardianProfile`; the mapper owns the lenient key-alias parsing that
  used to live in `guardian_code_resolver`.
Each endpoint threaded repo interface → use case → cubit(s) → repo impl → callers, test-first, verified.

## DEFERRED / KEPT (authorized)
- **E (kept):** shared `CalendarDialog` `showDialog<Map<String,dynamic>>` results (shared-widget contract);
  `student_screen._studentToMap`/`_activityStudentMaps` + `student_action_panel.activityStudentMaps`
  (cross-module activity boundary — needs activity-module coordination); `student_filter_screen.jsonDecode`
  (local filter persistence, not API).

## VERIFICATION
- Student domain entities: ZERO `fromMap/toMap/toPayload/json`. Remaining domain `Map<String,dynamic>` =
  item D (repo contract) only.
- `flutter analyze` (whole app): 0 errors.
- Student + data suites: 168 pass (+7 new).
