# STUDENT MODULE — STEP 4: TYPED MODELS / REMOVE RAW MAPS

> Branch `audit/student-fixes`. Goal: no raw JSON (`Map<String,dynamic>`) leaks into student
> presentation / domain entities / cubit state where a typed model fits. Serialization belongs to the
> data layer (Model → Mapper → Entity; Domain Request → Mapper → payload). Scope chosen: **A, B, C**
> (D deferred; E kept). Test-first, each verified.

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

## DEFERRED / KEPT (authorized)
- **D (deferred):** `student_repository.dart` + its use-cases' `Map<String,dynamic> fields` / `List<..>
  schedule` / `getGuardianProfile` — typing these needs request models threaded repo→usecase→cubit→impl
  (largest, most cross-cutting). Parked by decision.
- **E (kept):** shared `CalendarDialog` `showDialog<Map<String,dynamic>>` results (shared-widget contract);
  `student_screen._studentToMap`/`_activityStudentMaps` + `student_action_panel.activityStudentMaps`
  (cross-module activity boundary — needs activity-module coordination); `student_filter_screen.jsonDecode`
  (local filter persistence, not API).

## VERIFICATION
- Student domain entities: ZERO `fromMap/toMap/toPayload/json`. Remaining domain `Map<String,dynamic>` =
  item D (repo contract) only.
- `flutter analyze` (whole app): 0 errors.
- Student + data suites: 168 pass (+7 new).
