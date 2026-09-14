# STUDENT MODULE — STEP 0: BASELINE, DISCOVERY & SAFETY SNAPSHOT

> **Status:** READ-ONLY baseline. **No code was modified.** This document is the safety net and
> reference for all subsequent remediation steps. Nothing here is claimed as fixed.

---

## SAFETY SNAPSHOT (revert point)

| Item | Value |
|---|---|
| Repo | `git@github-atoconn:ChildcareWow/wowcare2-mobile.git` |
| Branch | `audit/student-fixes` |
| Baseline commit | `fb41d15499b394b5985cea3f657f939de120b0df` (`fb41d154`) |
| Commit subject | Merge PR #332 (attendance-refactor) — synced with `develop-refactor` |
| Flutter | 3.41.0 |
| Analyzer (student scope) | 10 info · **0 warnings · 0 errors** |

**To revert any step back to this baseline:**
```bash
git -C source/mobile stash            # park in-progress work
git -C source/mobile checkout audit/student-fixes
git -C source/mobile reset --hard fb41d154
```
> Note: the working tree also contained **out-of-scope, untracked communication-module files**
> (messaging) that floated over from `audit/messaging-fixes`. They are NOT part of the Student
> module and were not touched. No Student-module file is dirty at baseline.

**Tech stack:** `bloc`/`flutter_bloc` 8 · `equatable` · `get_it` 9 (hand-written locator, no `injectable`) ·
`dio` 5 · `go_router` 17 · `dartz` (partial) · **hand-written JSON serialization (no `freezed`/`json_serializable`; 0 `.g.dart`)**.

---

## A. STUDENT ARCHITECTURE MAP

Clean-architecture skeleton **exists** (data / domain / presentation), but the presentation layer
**routinely bypasses it**. Canonical target flow vs. reality:

```
View → Cubit/ViewModel → UseCase → Repository (contract) → RepositoryImpl → DataSource → Dio/Cache
  ✔ layers present                                   ✔                ✔ (god)        ✔ (god)
  ✘ 28 view/widget files skip the Cubit and call serviceLocator<UseCase|DataSource|Repository|StorageService> directly
```

**Per-flow conformance:**

| Flow | Follows target flow? | Break |
|---|---|---|
| Student **list** (`student_screen`) | ✘ Partial | Widget calls `serviceLocator<StudentRemoteDataSource>` + 16 locator pulls; `StudentCubit` also calls `_repository.deactivate/reactivate/delete` **bypassing usecases** |
| Student **profile shell** (`student_profile_screen`) | ✘ Partial | 10 locator pulls; `getStudentProfile` read hits datasource directly (self-described "MVVM holdout") |
| Profile **tab cards** (about/family/pickup) | ✘ | `serviceLocator<...>`, `StorageService`, `StaffRepository` used inside widgets; imperative nav |
| **Health** tab + cards | ✘ Partial | Reads Future-based via cubit but cards pull locator directly |
| **Add-student wizard** (step1/2/3) | ✘ | Orchestration + duplicate/sibling detection inline in views; 7 locator pulls in step1 |
| **Edit profile details** | ✘ | 9 locator pulls, 26 `setState`, form + validation + data access all inline |
| **Add** pickup / physician / document | ✘ | Direct usecase/datasource access from screens |
| **Documents** list | ⚠ | `StudentDocumentsListCubit` holds state but news up `FileDownloadService()` (infra leak) |
| Detail cubits (guardian/tags/pickup/exam/…) | ✔ Mostly | Correctly inject usecases; **cubit layer has 0 `serviceLocator`** ✅ |

**DI:** single hand-written locator `lib/app/di/di.dart` (`serviceLocator`). Datasources/repos = lazy
singletons; usecases + cubits = factories. Cubits are pulled **from the locator inside views**
(service-locator-as-provider) rather than injected at the widget-tree root.

**Routing (hybrid — key finding):** only 2 student destinations are in GoRouter
(`lib/src/app_router.dart`): `students` (`:888`) and `student-profile` (`:1185`). **Everything else
(wizard, all add/edit/filter/pickup/physician screens) is navigated imperatively** with
`Navigator.push` + `MaterialPageRoute`. The router's `add-document-screen` even resolves to the
**staff** screen, not the students one.

**Theme system:** full token set exists (`AppColors`, `AppSpacing`, `AppRadius`, `AppDimensions`,
`AppTextStyles`/`AppText`) but is largely unused in the module (see C). `AppText`/`AppTextStyles`:
**0 references** in sampled student files.

**Responsive system:** `ResponsiveHelper` (`lib/shared/utils/responsive_helper.dart`, breakpoints
768/600/900/360). Used by the 10 form screens; **not** used by the two biggest screens or any tab card.

---

## B. FILE INVENTORY

| Layer | Files | LOC |
|---|---|---|
| `lib/data/features/student*` (+ `student_classroom`) | 16 | 5,698 |
| `lib/domain/features/student*` (+ `student_classroom`) | 67 | 2,253 |
| `lib/presentation/features/students*` | 59 | 24,815 |
| **Total production** | **142** | **~32,766** |
| In-scope tests (`test/**/features/student[s]/…`) | 18 | — |
| (Filename-only "student" tests, actually **attendance/reports** — out of scope) | 25 | — |

**Key files:** DI `lib/app/di/di.dart`; router `lib/src/app_router.dart`; repo `student_repository_impl.dart` (1771);
datasource `student_remote_datasource.dart` (2044); god-view `student_screen.dart` (2154).

---

## C. VIOLATION COUNTS (scope: `lib/presentation/features/students/`)

### Architecture / layering (Step 1 target)
| Signal | Count | Notes |
|---|---|---|
| `serviceLocator<…>` total | **94** | view **83** · widgets **8** · util **3** · **cubit 0** ✅ |
| view/widget files doing it | **28 files** | the Step-1 work list |
| `serviceLocator<StorageService>` | 30 | persistence in UI |
| `serviceLocator<StudentRemoteDataSource>` | 6 | datasource in UI (7 view files total incl. edit) |
| `serviceLocator<…Repository>` | 3 | repo in UI (Staff etc.) |
| `serviceLocator<ApiClient>` / `Dio` | 2 / 3 | network client in UI |
| SharedPreferences/Storage/Firestore refs | 35 | |
| `GetIt` direct | 0 | (all via `serviceLocator`) |

### Navigation (later step)
`Navigator.push` **15** · `Navigator.of` **62** · `MaterialPageRoute` **32**

### State / UI hygiene
`setState(` **175** · `Widget _build` helpers **39** · commented-out code lines **17** · `TODO/FIXME` **0**

### Theme (later step)
`Colors.*` **328** · `Color(0x…)` **171** · `TextStyle(` **172** · `fontFamily:` **141** · `AppText` usage **0**

### Hardcoded strings / i18n
`Text('…')` literals **91** (23 files) · i18n framework **none** (only `intl.DateFormat`)

### Raw layout (no tokens) / responsive
`EdgeInsets.` **199** · `SizedBox(` **288** · `BorderRadius.` **122** · `Duration(` **10** ·
`MediaQuery…size.width` **9** · `constraints.maxWidth` **5** · `LayoutBuilder` **5**

### Serialization leakage into presentation
`Map<String,dynamic>` **55** · handwritten JSON calls **3**

### Imports / size
relative cross-folder `../../` **82** (21 files) · **files >400 lines: 23** (largest 2154)

---

## D. TOP PRODUCTION BLOCKERS

1. **Presentation bypasses the architecture (28 files).** Views/widgets call
   `serviceLocator<StorageService|StudentRemoteDataSource|Repository|ApiClient|UseCase>` directly —
   persistence, networking and data-fetch happen in the UI. *(Step 1)*
2. **Two ~2000-LOC data god-files** (`student_remote_datasource.dart` 2044, `student_repository_impl.dart` 1771)
   spanning ~9 sub-domains; **repo has no error abstraction** (1 try/catch in 1771 lines; raw `DioException`s propagate).
3. **`StudentCubit` god-cubit** — pagination + filters + cache + storage/school-switch + persona
   classroom-scoping + **direct repo mutations (bypassing usecases)**.
4. **God-view widgets** — `student_screen` (2154), `edit_student_profile_details` (1469),
   `student_about_tab_card` (1397), `student_profile_screen` (1343), wizard step1/2 (1330/1162),
   `student_action_panel` (1082): UI + business logic + data access co-located.
5. **Security: PII + `clockPin` written to on-device cache in plaintext** (`StudentGuardianModel.toJson`
   → `CacheManager`); `clockPin` is an auth secret. Guardian/pickup/profile blobs persisted locally unredacted.
6. **Four state idioms + three error-handling conventions + three model→entity mapping conventions** —
   no consistency; `errorMessage` clearing semantics differ between cubits.
7. **Hybrid routing** — most screens are imperative `Navigator.push`/`MaterialPageRoute`, only 2 in GoRouter.
8. **Theme not adopted** — 328 `Colors.*`, 171 `Color(0x…)`, 172 raw `TextStyle(`; `AppText` unused.
9. **Thin test coverage** — 18 tests for 142 production files / ~32.8K LOC; god-files largely untested.

---

## E. DEPENDENCY RISKS

- **Unstable/untyped backend contract** — models do extreme defensive parsing (string-or-map classroom
  parsed in 2 models; 4–5 candidate-key fallbacks for codes/photos; `firstNonEmpty`). Contract drift is absorbed silently.
- **Asymmetric serialization** — `fromJson` (wire envelope) vs `fromCacheJson` (flat) vs `toJson` diverge
  in `StudentPageModel` and `StudentDocumentsPageModel` → cache/wire drift risk.
- **Two suspicious doubled API paths** — `/student/student/{code}/siblings` and
  `/student/student/physical-checkup-count/{schoolCode}` (verify vs backend).
- **Inconsistent auth scoping** — student datasource sends `schoolCode` as query param (relies on Dio
  interceptors); classroom datasource manually sends school/org headers **3 ways each** (shotgun).
- **`Equatable` under-compare** — `StudentListItemModel.props` omits `scheduleByDay`; `StudentClassroomItemModel`
  and `StudentSettings` don't extend `Equatable` at all.
- **Cross-feature coupling** from views — student widgets reach `StaffRepository`, activity/attendance/billing usecases directly.
- **Parallel/legacy paths** — `add_student_screen.dart` (single-screen) coexists with the 3-step wizard.

---

## F. FILES THAT MUST BE MODIFIED (later steps — NOT in Step 0)

**Step 1 (presentation → cubit) — 28 view/widget files touching `serviceLocator`:** all of
`view/*` add/edit screens, `view/student_screen.dart`, `view/student_profile_screen.dart`, every
`student_profile_tab_cards/*` and `student_health_tab_cards/*` and `student_profile_screen_tabs/*`,
`view/student_filter_screen.dart`, `view/student_tags_edit_sheet.dart`, `widgets/student_action_panel.dart`,
`widgets/student_card.dart`, `widgets/_tags_loader.dart`, `util/*` (1 file). Supporting cubits/usecases/`di.dart`
as needed to move dependencies behind cubits.

**Later steps (flagged, not Step 1):** god-file splits (`student_remote_datasource.dart`,
`student_repository_impl.dart`, `student_screen.dart`, `student_cubit.dart`); theme adoption;
responsive adoption; navigation/routing consolidation; error-model unification; cache-PII hardening; test coverage.

## G. FILES THAT MUST **NOT** BE MODIFIED (in Step 1)

Per Step 1 constraints: **theme tokens**, **`app_router.dart` / routing**, **`responsive_helper.dart` /
responsive logic**, **backend/API contracts & endpoint paths**, **all other modules** (attendance,
staff, communication, classroom internals, reports), **generated files**, and **test files** (except
adding tests where a step explicitly requires). No formatting-only changes, no file moves.

## H. RECOMMENDED REMEDIATION ORDER

1. **Presentation → Cubit architecture** (remove `serviceLocator`/datasource/repo/storage from views). ← Step 1
2. God-view decomposition (extract sub-widgets; move logic to cubits/usecases).
3. Cubit/state normalization (one state idiom; unify single-flight; `StudentCubit` split).
4. Error-model unification (typed `Failure`/`Either` end-to-end; error handling in usecases).
5. Data-layer god-file split (datasource + repo by sub-domain; consistent mappers).
6. Theme adoption (`AppColors`/`AppText`/`AppSpacing`/`AppRadius`).
7. Responsive adoption on core screens + tab cards.
8. Navigation/routing consolidation into GoRouter.
9. Security: stop persisting `clockPin`/PII to plaintext cache; redact.
10. String externalization / i18n + accessibility (`Semantics`, touch targets).
11. Test coverage to match the refactor.

## I. BASELINE SCORE (production readiness)

| Dimension | Score /10 | Basis |
|---|---|---|
| Clean-arch skeleton present | 7 | layers/DI/usecases/immutable entities exist |
| Presentation layering discipline | **2** | 28 files bypass the cubit; datasource/storage in UI |
| Consistency (state/error/mapping) | 3 | 4 state idioms, 3 error conventions, 3 mapping styles |
| God-file / complexity | 3 | 23 files >400 LOC; two ~2000-LOC data files |
| Theme adoption | 2 | 328 `Colors.*`, 171 `Color(0x)`, `AppText` unused |
| Responsive adoption | 5 | forms yes; core screens/cards no |
| Navigation consistency | 4 | hybrid GoRouter + imperative push |
| Security / PII handling | 3 | `clockPin`+PII in plaintext device cache |
| Analyzer health | 9 | 0 errors/warnings (10 info) |
| Test coverage | 3 | 18 tests / 142 files |
| **Overall** | **≈ 3.8 / 10** | solid skeleton, weak presentation discipline & consistency |

---

*Generated as Step 0 (read-only). Awaiting acknowledgement before Step 1.*
