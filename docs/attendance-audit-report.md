# ATTENDANCE MODULE — Production‑Grade Audit (WowCare 2.0 Eight Mandates)

**Reviewer role:** Principal Flutter Mobile Architect · **Type:** AUDIT ONLY (no code modified) · **Branch:** `audit/attendance-fixes` (off `origin/develop`, HEAD `d3284311`)
**Scope:** `lib/{data,domain,presentation}/features/attendance/**` — **126 files, ~40,182 LOC** (data 7 / 5.4k · domain 35 / 2.0k · presentation 84 / 32.7k). Generated `.g.dart`: **none exist** (all serialization hand‑written).
**Standard:** WowCare 2.0 Eight Mandates + MVVM golden rule (`View → Cubit → UseCase → Repository → DataSource`).
**Confidence labels:** *CONFIRMED* (verified in code) · *PROBABLE* (strong signal) · *UNABLE‑TO‑VERIFY* (server‑side; not observable from a client codebase).

---

# 1. Executive Summary

**Overall health:** The attendance module is **feature‑complete and, on its read/list paths, well‑architected** — typed page models, real repository→entity mapping, disciplined server‑time handling, and **clean memory hygiene (zero controller/stream leaks)**. However, the **write/action surface (sign‑in, sign‑out, transfer, mark‑absent, corrections, QR/PIN) and the profile screens bypass the module's own MVVM chain entirely**, and several confirmed client‑side security/privacy defects exist. It is **not ready for a compliant production release** without remediation.

**Major architectural risks**
- MVVM golden rule is broken on all write flows: Views/forms call `ApiClient`, `AttendanceRepository`, `StaffRepository`, and even a `RemoteDataSource` **directly** from `StatefulWidget`s. The `forms/` tree is a parallel logic layer that never adopted the Cubit→UseCase chain the read screens use correctly.
- The **domain repository contract itself is defined in `Map<String,dynamic>`** for every mutation and profile read — the abstraction that is supposed to be map‑free leaks raw JSON through all three layers.

**Major business‑integrity risks**
- **Zero idempotency keys** on any side‑effecting POST/PATCH, **no retry/timeout config**, and the **401 auto‑refresh blindly replays mutation bodies** → duplicate attendance on retry/timeout/token‑expiry (concurrency scenarios 2, 4, 8).
- **No optimistic concurrency** (version/ETag) on corrections → silent last‑write‑wins.
- Attendance timestamps are ultimately **client‑influenceable** (server‑offset applied to the live device clock; staff times user‑picked with the future‑guard removed).

**Security concerns (client‑confirmed)**
- **PII exfiltration:** full request/response bodies (student/staff names, codes, notes) are logged **unconditionally** and forwarded to **Firebase Crashlytics in release builds**; the **kiosk PIN is logged in cleartext**.
- **IDOR / tenant‑isolation trust boundary is misplaced:** the client computes and sends its own `allowedClassroomCodes` authorization scope, and sources the `x-school-code` tenant header from a request query param — both from writable `SharedPreferences`.

**Production blockers (must fix):** PII/PIN logging to Crashlytics · idempotency on mutations · confirm server‑side scope/tenant enforcement (IDOR) · View→DataSource / inline‑mutation MVVM breaches · zero automated tests.

**Verdict: 🟠 NOT PRODUCTION READY** (see §16; escalates to 🔴 if server‑side scope enforcement cannot be confirmed).

---

## Remediation Status — branch `audit/attendance-fixes` (updated 2026‑08‑27)

Fixes are being applied **safest‑first**, keeping existing functionality intact. Each item below is committed on `audit/attendance-fixes` (PR base `develop`).

| ID | Finding | Status | Notes |
|----|---------|--------|-------|
| **A‑P0‑1** | PII request/response bodies → Crashlytics in release | ✅ **Fixed** | `AppLogger.d/i/w` no‑op in release; Dio body‑logging interceptor gated to `kDebugMode`. `e`/`c` error reporting retained. |
| **A‑P0‑2** | Kiosk PIN logged in cleartext | ✅ **Fixed** | Logs `pinLength` only. Also the 24 attendance `debugPrint()` rerouted through the release‑silent logger. |
| **A.1–A.5** | No spacing/radius/dimension token layer | ✅ **Foundation + adoption** | Added `AppSpacing`/`AppRadius`/`AppDimensions` (values mirrored from real usage → pixel‑identical). Adopted across all 14 presentational attendance widgets + reference card. Screens/forms sweep is optional follow‑through (same mechanical pattern). |
| **A‑P0‑3** | IDOR: client‑supplied scope + `x-school-code` from query param | ⏸ **Backend‑coordinated** | Real fix is server‑side (derive scope/school/role from the token). The client query‑param fallback only triggers when session storage has no school code; removing it blindly risks breaking bootstrap/multi‑school flows. **Not changed client‑only** — needs backend confirmation first. |
| **A‑P1‑1 / A‑P1‑2** | No idempotency keys; 401 blindly replays mutation bodies | ⏸ **Backend‑coordinated** | Both touch the app‑wide network path and are only effective with server dedup. Planned as an additive `Idempotency‑Key` client contribution + replay gating, done with backend. |
| **A‑P0‑4 / A‑P1‑3** | Write surface bypasses MVVM (View→Repository/DataSource) | ✅ **Done** | **All 6 submit flows** (student/staff sign‑in, sign‑out, transfer) routed View→Cubit→UseCase→Repository, plus **both inline record deletes** (staff/student daily views → `…AttendanceDeleteCubit` over a shared delete state) and the **profile View→`StudentRemoteDataSource` read** (now `GetStudentProfileUseCase`). Each behaviour‑identical and unit‑tested. **Mark‑absent verified already compliant** (forms drive `…MarkAbsentFormCubit`; mutation via `MarkStaff/StudentsAbsentUseCase`). The remaining `_isSubmitting`/business‑state‑in‑widgets cleanup is tracked separately as A‑P1‑5. |
| **A‑P1‑4** | `Map<String,dynamic>` domain contract | ✅ **Write contract done** | **Every mutation/write method is now `Map`‑free**, each with a `toPayload()` fidelity test: both transfers (`Student/StaffTransferRequest`), edit‑record PATCH (`StaffAttendanceDailyUpdateRequest`, return also `Map?`→`void`), and all 4 sign‑in/out payloads (`Student/StaffSignIn/SignOutRequest` — mode‑aware, reproducing every conditional branch: parent/staff/kiosk, self/admin‑bulk, kiosk‑PIN override, pin/qr/comment). Each form handler was restructured *resolve‑then‑build*, keeping every guard/snackbar/early‑return. 74 attendance tests green; module analyze clean. *(Sign‑in/out touch critical handlers — flagged for a simulator QA pass in their commits.)* **Remaining, by design:** the 5 `fetch*Profile` **read** methods return raw `Map?` (the contract's own note: "raw backend JSON so existing screen‑level parsing is preserved") consumed by 47+ inline accesses across 2 profile screens + a dashboard cubit — typing those responses is a large, UI‑QA‑gated parser rewrite, left as a separate task. |
| **A‑P1‑6** | Zero automated tests | 🔧 **Growing** | Unit tests now cover all 6 submit flows + both delete flows (use cases + cubits) — **51 tests, green**. Grows with each write‑flow refactor as its safety net. |

---

# 2. Architecture Map

**Expected:** `View → Cubit/ViewModel → UseCase → Repository → DataSource → API`.

**Actual — two divergent paths:**

```
READ / LIST screens (COMPLIANT)
  view/screens/*_daily_view · *_custom_view · *_absent_view
      ↓
  cubit/staff|student_attendance_daily_cubit, *_custom, *_absent
      ↓
  domain/usecases/get_*_usecase   (26 use-cases, thin/SRP)
      ↓
  data/repositories/attendance_repository_impl  (maps models → entities)
      ↓
  data/datasources/attendance_remote_datasource → ApiClient (Dio)

WRITE / ACTION flows + PROFILE screens (VIOLATION)
  forms/**_sign_in|out|transfer|mark_absent · view/*_profile
      ↓  (skips UseCase entirely)
  serviceLocator<AttendanceRepository|StaffRepository|ApiClient|StudentRemoteDataSource>()  ← called from StatefulWidget.State
      ↓
  data layer / API
```

**Deviations (confirmed):**
- `view/student_attendance_profile.dart:599` → **View → `StudentRemoteDataSource`** (deepest possible skip).
- `view/screens/staff_attendance_daily_view.dart:1187` → widget `onPressed` → **`AttendanceRepository.deleteStaffAttendanceRecord()`** (destructive mutation, no Cubit).
- All 6 sign‑in/out/transfer forms + profile screens → repository/ApiClient directly.
- **No UseCase** exists for sign‑in/out/transfer or profile‑patch; the UI assembles raw request maps itself.

---

# 3. Attendance Folder Map

```
data/features/attendance/                         (7 files, 5,431 LOC — NO mapper/ , NO *.g.dart)
  datasources/  attendance_remote_datasource.dart (mutations + reads; raw-Map mutation methods)
  models/       student_attendance_models.dart, student_absence_record_models.dart,
                staff_absence_record_models.dart, qr_validation_model.dart,
                student_attendance_record_code.dart (heuristic key-probing helper)
  repositories/ attendance_repository_impl.dart    (typed read mapping + raw-Map mutation/profile passthrough)

domain/features/attendance/                        (35 files, 2,004 LOC)
  entities/     pure (equatable only) ✓
  repositories/ attendance_repository.dart          ← contract defined in Map<String,dynamic> (P0)
  usecases/     26 use-cases (reads + mark-absent + QR + record-update); NONE for sign-in/out/transfer/profile

presentation/features/attendance/                  (84 files, 32,747 LOC — 5 subfolders, non-canonical)
  cubit/        staff|student_attendance_daily|custom|absent cubits (+ *_state)  ✓ MVVM
  forms/                                            ← parallel logic tree (write surface, bypasses MVVM)
    staff_attendance_forms/{,cubit/}  student_attendance_forms/{,cubit/}
    staff_entity.dart  ← domain-ish type misplaced in presentation
  util/         attendance_permission_service.dart, attendance_school_time.dart, attendance_redirect.dart
  view/         *_profile, *_tabbed_view; view/screens/{,widgets/}
  widgets/      + view/screens/widgets/  ← student_attendance_card.dart DUPLICATED in two widget folders
```

---

# 4. Eight‑Mandate Scorecard

| Mandate | Score | Status | Key violations | Risk |
|---|---:|---|---|---|
| 1 · GoRouter everywhere | **4/10** | 🟠 | 105 `Navigator.`/58 `MaterialPageRoute` vs 33 GoRouter; route logic + untyped string dispatch in widgets/popups (`staff_attendance_tabbed_view.dart:546`, `attendance_popup.dart:636`) | Fragile nav, no typed routes |
| 2 · setState scarcely | **3/10** | 🟠 | 271 `setState` (loading/role/API‑response/multi‑select) vs 4 `ValueNotifier` (used only as refresh‑counter hack) | Business state in widgets |
| 3 · Canonical folders | **5/10** | 🟡 | `forms/` parallel tree; duplicated `student_attendance_card.dart`; `StaffEntity` in presentation | Structure drift |
| 4 · Centralized theme/constants | **5/10** | 🟡 | ~269 hardcoded colors, 147 inline `TextStyle`, no strings/i18n, no dimension tokens | No theming/i18n |
| 5 · Presentation → Cubit only | **3/10** | 🟠 | View→DataSource; inline mutations; 34 direct data‑layer calls in View/Form | MVVM broken on writes |
| 6 · Component reuse | **5/10** | 🟡 | raw `TextField` ×11, duplicated debounced search ×14, 10 near‑dup selection forms | Duplication |
| 7 · One responsive source | **5/10** | 🟡 | 3 competing helpers/breakpoints (768 vs 600 vs inline 600) | Inconsistent layouts |
| 8 · Typed generated models | **5/10** | 🟡 | 274 `Map<String,dynamic>` (domain contract + all mutations); **no code generation**; stringly‑typed status/method | Untyped API boundary |

**Eight‑Mandate total: 35 / 80**
**MVVM Golden‑Rule score: 3 / 10** — Views/forms routinely touch `ApiClient`/`AttendanceRepository`/`StaffRepository`/`RemoteDataSource`; the clean chain is honored only by the read cubits.

---

# 5. Attendance Integrity Audit

| Operation | Dup protection | Timestamp | TZ / boundary | Identity / authz | Verdict |
|---|---|---|---|---|---|
| **Student Sign‑In** (`student_sign_in_form.dart:477`) | `_isSubmitting`+button disabled | staff=picked, parent/kiosk=`utcNowInSchool` | school IANA | staffCode + `allowedClassroomCodes` from storage | No idempotency key |
| **Student Sign‑Out** (`:238`) | `_isSubmitting` | same | school IANA | QR re‑validated pre‑write (`:326`) | No idempotency key |
| **Staff Sign‑In/Out** (`staff_sign_in_form.dart:540`) | `_isSubmitting` | picked/now→UTC | school IANA | `isSelf` picks self vs admin‑bulk endpoint | No idempotency key |
| **Mark Absent (student/staff)** (`student_mark_absent_cubit.dart:116`) | `isSubmitting` | date‑range strings | school "today" | staffCode; room = first non‑empty student room | Date‑only ⇒ re‑submit dupes rows; `MarkStaffAbsentUseCase` loops **one POST per day** |
| **Transfer (student/staff)** (`student_transfer_form.dart:349`) | `_isSubmitting` | staff picked (future‑guarded `:392`) | school IANA | dest classroom validated in scope | Dup ⇒ phantom transfer leg |
| **Correction / Edit (student/staff)** (`student_edit_attendance_cubit.dart:77`) | `isSubmitting` | fully user‑picked→UTC | school IANA | staffCode + allowed rooms | **No version/ETag ⇒ last‑write‑wins** |
| **QR flow** (`student_sign_in_out_selection_screen.dart:68`) | form guard; validate itself unguarded | n/a | n/a | `validateQrCode(schoolCode from storage, qrToken)` | single‑use = server‑only (UNABLE‑TO‑VERIFY) |
| **PIN / Kiosk** (`student_sign_in_form.dart:663`) | `_isSubmitting` | `utcNowInSchool` | school IANA | guardianCode+pin → parent endpoint | No idempotency; **PIN logged (`:666`)** |
| **Daily/Weekly/History/Classroom/Student/Staff views** | read‑only | display‑only, school‑zone | school zone from/to | `allowedClassroomCodes` intersection | Read paths OK; first‑page cache stored only for unscoped personas (avoids cross‑teacher leak) |

**Authorization (CONFIRMED client behavior):** object‑level scope is enforced by sending `allowedClassroomCodes` on every list + mutation, resolved fresh from storage/profile (self‑healing from `/staff/{code}/profile`). Actual enforcement is server‑side (UNABLE‑TO‑VERIFY).

---

# 6. Concurrency / Idempotency Audit

| # | Scenario | Safe? | Duplicate risk | Wrong‑data risk | Evidence | Severity |
|---|---|---|---|---|---|---|
| 1 | Double‑tap Sign‑In | ✅ client | Low | None | `_isSubmitting`+button→null (`student_sign_in_form.dart:478,922`) | P3 |
| 2 | Timeout after server accepted, retry | ❌ | **High** | None | No idempotency key on any POST (`attendance_remote_datasource.dart:1760,1802,1507`); no reconciliation | **P1** |
| 3 | App closed mid‑submission | Partial | Low | None | No offline queue/outbox; in‑flight request abandoned; nothing replayed on reopen | P2 |
| 4 | Network reconnect / manual retry | ❌ | **High** | None | No retry interceptor for network errors; re‑tap re‑POSTs identical body | **P1** |
| 5 | School change during in‑flight | ❌ | Low | **Moderate** | Context snapshotted at build; `_attendanceActionResult` (`repository_impl.dart:1493`) doesn't re‑validate school | P2 |
| 6 | Classroom change during in‑flight | Mostly | Low | **Moderate** | `classroomCode` snapshotted into payload (`student_sign_in_form.dart:559`); no version check | P2 |
| 7 | Concurrent edit of same record | ❌ | None | **High (silent overwrite)** | Edit/correction PATCH sends no version/ETag/`If‑Match` (`repository_impl.dart:1417`, `patchStaffAttendanceDailyRecord:1860`) | P2 |
| 8 | Token expiry during submission | Partial | **Moderate** | None | 401 refresh **replays** the same mutation body (`session_expired_interceptor.dart:34‑42`), no idempotency key | **P1** |

**Idempotency table**

| Mutation | Idempotency Key | Client Protection | Server Protection | Retry Safety | Duplicate Risk |
|---|---|---|---|---|---|
| Sign‑In / Sign‑Out (student+staff) | **None** | `_isSubmitting` | UNABLE‑TO‑VERIFY | Unsafe | High |
| Mark Absent (student+staff) | **None** | `isSubmitting` | UNABLE‑TO‑VERIFY | Unsafe | High (date‑range dup rows) |
| Transfer (student+staff) | **None** | `_isSubmitting` | UNABLE‑TO‑VERIFY | Unsafe | High (phantom leg) |
| Correction/Edit | **None**; no version/ETag | `isSubmitting` | UNABLE‑TO‑VERIFY | Value‑idempotent but last‑write‑wins | Overwrite |
| QR validate → sign | **None** | form guard; validate unguarded | server‑only | Depends on token burn | Moderate |
| PIN / Kiosk | **None** | `_isSubmitting` | UNABLE‑TO‑VERIFY | Unsafe | High (+PIN logged) |

**Server time / timezone** — *Strengths:* **no raw `DateTime.now()` anywhere** (all via `ServerTimeService`); date/day/week boundaries computed in **school IANA zone** (`attendance_school_time.dart:44`). *Risk (CONFIRMED):* the server offset is fixed at last sync and applied to the live device clock, so a device‑clock change after sync (or before any successful sync, `_offset=0` ⇒ device time) shifts timestamps; staff sign‑in/out times are additionally user‑picked with the future‑guard **removed** (`student_sign_in_form.dart:534‑542`). The client is not a trustworthy timestamp source — server must bound `occurredAt`/`transferredAt` (UNABLE‑TO‑VERIFY).

---

# 7. Security Audit

| Pri | Area | Evidence | Status |
|---|---|---|---|
| **P0** cond. | **IDOR / tenant isolation** — client computes & sends its own `allowedClassroomCodes` authz scope (from writable prefs); `[]`=no‑restriction for admin/parent | `attendance_repository_impl.dart:45‑72,323‑382`; `attendance_classroom_scope.dart:127‑211` | client CONFIRMED / server UNABLE‑TO‑VERIFY |
| **P1** | `x-school-code` tenant header falls back to a **request query param** | `auth_interceptor.dart:104‑111,212‑221` | CONFIRMED client |
| **P0/P1** | **PII in logs → Crashlytics in release** — full request/response bodies (names, codes, notes) logged unconditionally; only `Authorization` masked | `api_client.dart:61‑109`, `api_logger.dart:41‑70`, `logger_service.dart:16‑24` | **CONFIRMED** |
| **P1** | **Kiosk PIN logged in cleartext** (→ Crashlytics in release) | `kiosk_logout_cubit.dart:41` | **CONFIRMED** |
| **P1** | Cross‑school correction/transfer/mark‑absent craftable client‑side (composite) | §1+§2+§3 | client CONFIRMED / server UNABLE |
| **P2** | `x-role` sourced from client storage (`activeSchoolRole`) | `auth_interceptor.dart:118‑126` | CONFIRMED client |
| **P2** | Access token + **refresh‑token mirror in plaintext `SharedPreferences`** (defeats secure‑enclave) | `token_refresh_service.dart:88`, `storage_service.dart:21‑87` | CONFIRMED |
| **P2** | QR use‑case client‑chosen; stored school used; **no client replay/expiry guard**; `validTo` not enforced | `student_sign_in_out_selection_screen.dart:48‑90`, `validate_qr_code_usecase.dart` | CONFIRMED client / server UNABLE |
| **P3** | No client gate on correction/transfer/delete (only "staff must self‑sign‑in") | `attendance_permission_service.dart:24‑32` | CONFIRMED |
| **P3** | Record/target IDs (`attendanceRecordCode`,`studentCode`,`classroomCode`) re‑sent unverified | `student_edit_attendance_cubit.dart:39‑82` | server UNABLE |
| **P3** | No client PIN throttling/lockout | `kiosk_dashboard_screen.dart:115‑128` | CONFIRMED (none) |
| **P3** | Attendance PII screens not screenshot‑protected (`screenshot_protection.dart` unused; FLAG_SECURE commented) | `pdf_view.dart:49,57` | CONFIRMED |

**Positives:** no hardcoded secrets/keys; single‑flight token refresh with logout on genuine expiry; `staffCode` re‑validated against the backend mapping (`staff_code_resolver.dart:59‑83`).

---

# 8. UI / State Audit

- **setState findings (P1/P2):** business state in widgets — role/persona + selection + API‑response map in `staff_sign_in_form.dart:183‑244` (`_isAdminRole`, `_isStaffAdminPersona`, `_selectedStaff`, `_expectedTodayFromApi`); loading flag `_isValidating` in `student_sign_in_out_selection_screen.dart:57,88`; gate/loading in `student_sign_in_form.dart:188`; bulk multi‑select in `student_selection_transfer_form.dart:134‑268` (a sibling `student_transfer_selection_cubit.dart` exists but is unused).
- **ValueNotifier misuse (P2):** the 4 `ValueNotifier<int>` are a hand‑rolled "bump an int to force cross‑screen refresh" bus (`student_attendance_tabbed_view.dart:81` → passed to absent/custom/daily views) — a workaround for a missing shared attendance Cubit.
- **Cubit findings:** read cubits are clean (UseCase‑backed); the form cubits (`student_edit_attendance_cubit`, `student_mark_absent_cubit`, staff equivalents) depend on raw `ApiClient` and bypass the domain layer (P2).
- **API calls from UI (P0/P1):** see §2 — View→DataSource and inline repository mutations.
- **Rebuild risks (P2/P3):** whole‑screen `setState` in 1000‑LOC views (`staff_sign_in_form` 23×, `student_attendance_absent_view` 21×, profiles/daily 17× each) — no `buildWhen`/`ValueListenableBuilder` scoping.

---

# 9. Theme / Color / Text / Font Audit  (central design system EXISTS: `AppColors`, `AppTextStyles`/`AppText`, `Fonts`)

- **Colors:** ~329 `AppColors.` refs (good adoption) **but ~269 hardcoded remain** — ~172 raw `Colors.*` + ~97 `Color(0x…)`/`fromRGBO`. Evidence: `student_attendance_daily_view.dart:1114,1188,1282`; `staff_attendance_profile.dart:1270,1273` (repeated ~6×). Worst: `student_override_sign_in_form.dart` (12 raw colors, 0 `AppColors`). `Colors.grey`/`Colors.red` duplicate `AppColors.dividerColor`/`errorColor`.
- **Text/Fonts:** 128 `AppTextStyles`/`AppText` refs **but 147 inline `TextStyle(`, 161 `fontSize:`, 63 inline `fontFamily:`** (e.g. `student_attendance_daily_view.dart:1080‑1082`) — duplicated, drift‑prone type scale.
- **Strings:** **no localization layer anywhere** (no `.arb`/`AppLocalizations`/strings file). 49 `Text('literal')` + **175 hardcoded `SnackBar` messages** (e.g. `student_sign_in_form.dart:483,527,552,623,636,650`).
- **Design tokens:** no `AppDimensions`/`AppSpacing` — 431 `SizedBox`, 207 `EdgeInsets`, 137 `borderRadius`, 259 hardcoded `height:`, 62 `width:` as magic numbers.

---

# 10. Responsive Audit

Responsive handling is **extensive but not unified**: 218 `isTablet`/`isLargeTablet` refs, 30 `ResponsiveHelper(...)`, 9 `MediaQuery.size`.

| Breakpoint | Assessment |
|---|---|
| 375px (phone) | Overflow risk from 259 hardcoded `height:` + 62 `width:` combined with non‑responsive `Row`/`Column` card layouts |
| 768px (tablet) | **Inconsistent** — `ResponsiveHelper` tablet ≥768 (`responsive_helper.dart:8`) vs `ResponsiveSizing` tablet ≥600 (`responsive_sizing.dart:6`) vs inline `screenWidth>=600` literals (`student_attendance_tabbed_view.dart:142`, `staff_attendance_profile.dart:1092`) — a 600–768px device is "tablet" under one, "phone" under another |
| 1024px (large) | Fixed dimensions waste space; no large‑screen‑specific layout |

**P2 — three competing responsive sources/breakpoints; P3 — fixed‑dimension overflow.** Consolidate on one helper + one breakpoint set.

---

# 11. Model / API Audit — every raw `Map`/`dynamic` at an API boundary (274 total)

**Domain contract** — `domain/features/attendance/repositories/attendance_repository.dart` (**P0** — abstraction should be map‑free):
- `submitStudentSignIn/Out/Transfer`, `submitStaffSignIn/Out/Transfer` (`355‑387`) — `Map payload` — **Request**
- `updateStaffAttendanceDailyRecord` (`390‑393`) — `Map`→`Map?` — **Request+Response**
- `fetchStudent/StaffAttendanceProfile[AbsentToggle]`, `fetchStudentAttendanceAbsentView`, `getStudentAttendanceAbsentView` (`403‑437`) — `Map`→`Map?` — **Request+Response**

**Datasource** — `data/.../attendance_remote_datasource.dart`: `updateStudentAttendanceRecord`/`createStudentSignInRecords` (`318,327`) — Request; `postStudent/StaffSignIn/Out/Transfer` (`1760‑1847`) & `patchStaffAttendanceDailyRecord` (`1860`) — Request+Response; `get*ProfileRaw`/`getStudentAttendanceAbsentViewRaw` (`377‑399`) — Request+Response; `getStaff/StudentSignInStatus[AtTime]` (`293‑313`) — `Map<String,String>` stringly‑typed — Response.

**Repository impl** — `_attendanceActionResult(Map? data)` (`1493‑1524`) hand‑parses response; 6 `submit*({Map payload})` (`1526‑1642`); profile/absent `fetch*` (`1655‑1743`); summary cache read as `cached['expected'] as int?` (`1128‑1345`, ~8×) — Internal.

**Compliant (typed):** all page/summary models, `MarkAbsentRequest/Response`, `StaffMarkAbsent*`, `QrValidationRequest/Response`. **Required typed‑model boundary:** `StudentSignInRequest`, `StudentSignOutRequest`, `StaffSignIn/Out/TransferRequest`, `AttendanceCorrectionRequest`, `AttendanceProfileQuery`, and typed profile/absent‑view **response** models + `AttendanceStatus`/`AttendanceMethod`/`AbsenceType` enums. **No `.g.dart` / code generation** anywhere (P2 — Mandate‑8 asks for *generated* models).

---

# 12. Failure Matrix

| Failure | Current handling | Risk | User impact | Data impact | Sev | Recommendation |
|---|---|---|---|---|---|---|
| Network timeout | Bare `DioException` propagates; no timeout set | Retry → dupe | Confusing error | Duplicate rows | P1 | Timeouts + idempotency key |
| Offline mode | No offline queue/outbox | Lost submission | Silent loss | None persisted | P2 | Outbox + reconcile |
| Server 500 | `ApiErrorHandler.extractErrorMessage` in only 3/26 use‑cases | Inconsistent UX | Raw error text | None | P2 | Centralize error→`Failure` |
| 401 | Auto refresh + **replay mutation body** | Duplicate on replay | Usually transparent | Duplicate rows | P1 | Exclude mutations or gate by idempotency key |
| 403 | Not specifically handled | Unclear denial | Generic error | None | P3 | Explicit unauthorized UX |
| 404 | Not specifically handled | — | Generic error | None | P3 | Explicit not‑found UX |
| Validation failure | Server message via SnackBar (where wired) | — | OK | None | P3 | Consistent surfacing |
| Duplicate request | Client `_isSubmitting` only | Server‑side dup on retry | — | Duplicate rows | P1 | Idempotency key |
| Stale state | Snapshot at build; no re‑validate | Wrong context applied | — | Wrong school/room | P2 | Validate context on response |
| Concurrent update | No version/ETag | Silent overwrite | Lost correction | Data loss | P2 | Optimistic locking |
| Token expiry | Refresh + replay | Duplicate | Transparent | Duplicate rows | P1 | Idempotency key |
| App termination | No persistence/replay | Lost/unknown | No confirmation | Unknown | P2 | Outbox + status recovery |
| School change mid‑request | Not re‑validated | Wrong tenant | — | Cross‑school write | P2 | In‑flight context token |
| Classroom change mid‑request | Snapshot only | Wrong room | — | Wrong classroom | P2 | Version/context check |
| Wrong student/staff | Client‑supplied IDs unverified | IDOR | — | Cross‑entity write | P1 (server) | Server ownership check |
| Wrong date | Staff time user‑picked, future‑guard removed on sign‑in/out | Backdated attendance | — | Integrity | P2 | Server bound check |
| Timezone mismatch | School IANA used (good) | Low | — | Low | P3 | Keep; verify DST |
| QR expiry | `validTo` not enforced client‑side | Reuse of expired QR | — | Unauthorized sign | P2 | Enforce server + client early guard |
| PIN expiry / brute force | No client throttling; PIN logged | Brute force / leak | — | Account/PII | P1 | Server rate‑limit; stop logging PIN |

---

# 13. Testing Audit

**Attendance module tests: 0.** The two files matched by "attendance" are **reports‑feature** tests (`test/presentation/features/reports/view/{staff_attendance_per_week,student_attendance_per_student}_report_screen_test.dart`), not this module. No test file imports `features/attendance` (project total: 31 test files).

| Layer | Coverage |
|---|---|
| Unit / UseCase / Repository / DataSource / Mapper | ❌ 0 |
| Cubit/ViewModel | ❌ 0 |
| Widget | ❌ 0 |
| Integration / Golden | ❌ 0 |
| Concurrency (double‑tap, retry, dup) | ❌ 0 |
| Security (wrong school/classroom/student/staff, IDOR) | ❌ 0 |
| Responsive (375/768/1024) | ❌ 0 |

**Critical untested paths:** sign‑in/out/mark‑absent/transfer; edit/correction + override sign‑in; QR re‑validation + failure branch; geofence gating (`attendance_popup.dart`); future‑date guard; code‑resolution failures; search debounce + `refreshNotifier` refresh.

---

# 14. Findings by Priority

### P0 — Production blockers
- **A‑P0‑1 — PII exfiltration to Crashlytics (release).** `api_client.dart:61‑109` + `api_logger.dart:41‑70` + `logger_service.dart:16‑24`. Full attendance request/response bodies (student/staff names, codes, absence notes, guardian codes) logged unconditionally; `AppLogger.d` forwards to `FirebaseCrashlytics` when `!kDebugMode`. *Why:* minors' PII leaves the device to a third party — privacy/compliance breach. *Fix:* gate the logging interceptor behind `kDebugMode`; never send bodies to Crashlytics; scrub PII. *CONFIRMED.*
- **A‑P0‑2 — Kiosk PIN logged in cleartext (→ Crashlytics in release).** `kiosk_logout_cubit.dart:41` (`… pin=$pin`). *Fix:* log presence/length only. *CONFIRMED.*
- **A‑P0‑3 — IDOR / tenant‑isolation trust boundary.** Client computes & sends `allowedClassroomCodes` authz scope and `x-school-code` (from a query‑param fallback), all from writable prefs. `attendance_repository_impl.dart:45‑72`, `auth_interceptor.dart:104‑111`. *Why:* if the server authorizes on these, an altered client acts cross‑school. *Fix (server, load‑bearing):* derive scope/school/role from the token; reject client‑supplied scope that exceeds it. *P0 IF server trusts; client boundary CONFIRMED misplaced / server UNABLE‑TO‑VERIFY.*
- **A‑P0‑4 — View → DataSource + inline destructive mutation.** `student_attendance_profile.dart:599` (View→`StudentRemoteDataSource`); `staff_attendance_daily_view.dart:1187` (widget `onPressed`→`AttendanceRepository.deleteStaffAttendanceRecord`). *Why:* untestable, no state machine, double‑delete possible. *Fix:* route through a Cubit + UseCase. *CONFIRMED.*

### P1 — Critical
- **A‑P1‑1 — Zero idempotency on all mutations** (`attendance_remote_datasource.dart:1507‑1860`) + no retry/timeout config → duplicate attendance on retry/timeout (scenarios 2/4/8). Worst on `MarkStaffAbsentUseCase` per‑day loop.
- **A‑P1‑2 — 401 auto‑refresh replays mutation bodies** unguarded (`session_expired_interceptor.dart:34‑42`).
- **A‑P1‑3 — Entire write surface bypasses MVVM** — sign‑in/out/transfer forms build `ApiClient`/`AttendanceRepository` and call mutations from `StatefulWidget`; **no UseCase** for these ops.
- **A‑P1‑4 — Domain repository contract in raw `Map<String,dynamic>`** (`attendance_repository.dart:355‑437`).
- **A‑P1‑5 — Business state in widgets** (role/persona/API‑response/multi‑select) — `staff_sign_in_form.dart:183‑244`, selection forms.
- **A‑P1‑6 — Zero automated tests** for the 84‑file module.

### P2 — High
- No optimistic concurrency (version/ETag) on corrections → last‑write‑wins (scenario 7).
- Tokens + refresh‑token mirror in plaintext `SharedPreferences`; `x-role` client‑sourced.
- QR: no client replay/expiry guard; use‑case client‑chosen.
- Non‑virtualized daily/absent roster (`Column`+`.map` in `SingleChildScrollView`, `student_attendance_daily_view.dart:1120`, `staff_*:1090,1367`).
- Datasource: no timeout/retry, bare `Exception`/`DioException`, error‑mapping in only 3/26 use‑cases; stringly‑typed status/method (no enums).
- Three competing responsive helpers/breakpoints.
- ~269 hardcoded colors + 147 inline `TextStyle` + no strings/dimension tokens.
- **Zero `Semantics`/`semanticLabel`** across 32.7k LOC (153 interactive + 35 icon widgets).
- Form cubits depend on raw `ApiClient` (bypass domain).
- No client gate on correction/transfer/delete.

### P3 — Medium
- Imperative `MaterialPageRoute` + route logic in widgets/popups (`staff_attendance_tabbed_view.dart:546`, `attendance_popup.dart:636`).
- Duplicated `student_attendance_card.dart` in two widget folders; `StaffEntity` in presentation; `forms/` parallel tree.
- Duplicated debounced‑search (×14) and near‑duplicate selection forms (×10); raw `TextField` ×11; inline buttons/dialogs.
- `attendanceRecordCode` heuristic key‑probing (`student_attendance_record_code.dart`).
- Domain purity: `flutter/foundation` imported in `mark_staff_absent_usecase.dart:1`.
- PII/identifier logging (`school_context_helper.dart:31‑100`); no screenshot protection; no PIN throttling.
- No `textScaler` handling with 161 fixed `fontSize:`.

### P4 — Low
- Vague file names: `attendance_permission_service.dart` ("service"), `attendance_time_parse_util.dart` ("util"), `student_signIn_out_button.dart` (bad casing + "button"), `util/` folder.
- `ValueNotifier<int>` refresh‑counter hack instead of a shared Cubit event.
- Redundant toggle/form‑list/absent‑view near‑duplicate use‑cases (parameterize).

---

# 15. Overall Score

| Category | Score |
|---|---:|
| Architecture | **8 / 20** |
| Business Integrity | **10 / 20** |
| Security | **6 / 15** |
| State Management | **4 / 10** |
| Models / API | **5 / 10** |
| Responsive UI | **3 / 5** |
| Testing | **1 / 10** |
| Maintainability | **5 / 10** |
| **TOTAL** | **42 / 100** |

**MVVM Compliance: 3 / 10** · **Eight Mandates: 35 / 80**

---

# 16. Production Readiness Verdict

## 🟠 NOT PRODUCTION READY
*(Escalates to 🔴 PRODUCTION BLOCKED if server‑side tenant/scope enforcement for A‑P0‑3 cannot be independently confirmed.)*

**Why:** Read paths and time handling are solid and there are **no memory leaks**, but the module carries **confirmed client‑side privacy breaches** (PII + PIN to Crashlytics in release), **no idempotency** on side‑effecting attendance mutations combined with **blind 401 replay** (duplicate‑attendance risk), an **IDOR/tenant trust boundary that rests entirely on unverified server enforcement**, **MVVM broken across the whole write surface** (incl. a View→DataSource call and inline destructive mutation), and **zero automated tests**. Any of the first three alone blocks a compliant release.

### Minimum P0/P1 fixes required before production
1. **A‑P0‑1 / A‑P0‑2** — Gate the API logging interceptor behind `kDebugMode`, stop sending request/response bodies to Crashlytics, and remove the cleartext PIN log. *(fast, fully client‑side)*
2. **A‑P0‑3** — Confirm (and, if needed, fix server‑side) that scope/school/role are derived from the authenticated token and that client‑supplied `allowedClassroomCodes`/`x-school-code`/`x-role` cannot widen it; stop sourcing `x-school-code` from a query param.
3. **A‑P1‑1 / A‑P1‑2** — Add a stable client idempotency key to every attendance mutation (surviving 401‑replay and manual retry) and exclude attendance mutations from blind 401‑replay (or gate replay by that key); add request timeouts.
4. **A‑P0‑4 / A‑P1‑3 / A‑P1‑4** — Route the write surface and profile screens through Cubit → UseCase → Repository; introduce typed request/response models and remove `Map<String,dynamic>` from the domain contract.
5. **A‑P1‑6** — Add automated tests for the mutation flows (happy + failure + concurrency: double‑tap, retry, wrong‑school/classroom).

# Addendum A — Global Design System, Responsive Tokens, Common Widgets & Production Security

Evaluated against the 13‑point "Global UI / Design System / Responsive Variables / Common Widgets / Production Security" criteria. **Scope note:** several gaps here are **project‑wide** (the token/strings/responsive systems don't exist anywhere), so the fix belongs in the shared design‑system layer, not inside attendance. Still audit‑only.

### A.0 — Criteria scorecard

| # | Criterion | Central system exists? | Attendance compliance | Sev |
|---|---|---|---|---|
| 1 | Global colors/theme | ✅ `AppColors` (`lib/app/theme/colors.dart`) | 🟡 partial — 329 `AppColors.` refs **but 597 hardcoded** `Colors.*`/`Color(0x…)` | P2 |
| 2 | Global typography | ✅ `AppTextStyles`/`AppText` (`lib/shared/common/widgets/app_text_styles.dart`) | 🟡 partial — 128 refs **but 147 inline `TextStyle`**, 161 `fontSize:`, 63 inline `fontFamily:` | P2 |
| 3 | Global responsive variables | ⚠️ **fragmented** — `ResponsiveHelper` (≥768) + `ResponsiveSizing` (≥600), no token set | 🟠 3 competing breakpoints + inline `width>=600` literals | P2 |
| 4 | Global spacing tokens (XS–XL) | ❌ **none exist** | ❌ 431 `SizedBox`, 207 `EdgeInsets` as magic numbers (8/12/16/20/24/32) | P2 |
| 5 | Border‑radius / component‑style tokens | ❌ **none exist** (`AppRadius`/`AppDimensions` absent) | ❌ 137 `borderRadius`, 259 `height:`, 62 `width:` literals; no shared shadow/elevation/border tokens | P2 |
| 6 | Maximum common‑widget reuse | ✅ ~80 shared widgets exist | 🟡 partial — raw `TextField` ×11, inline buttons ×25, inline dialogs ×8, no shared EmptyState | P2 |
| 7 | Reusable component architecture | ✅ shared library | 🟠 debounced‑search dup ×14, 10 near‑dup selection forms, duplicated card widget | P2 |
| 8 | No hardcoded UI values | — | ❌ pervasive (see 1,2,4,5) | P2 |
| 9 | Consistent UI across app | — | 🟡 at risk from 1–8 (mixed raw + tokenized) | P3 |
| 10 | Global configuration / single source of truth | 🟡 partial | 🟡 colors/typography centralized; spacing/radius/strings/responsive scattered | P3 |
| 11 | **Production security & logging** | ⚠️ centralized logger exists but **forwards to Crashlytics in prod** | 🔴 **see A.11 — P0** | **P0/P1** |
| 12 | Code quality / maintainability | — | 🟡 read paths good; write surface duplicated + untyped | P2 |
| 13 | Implementation rules (reuse‑first) | — | 🟠 write flows created screen‑specific instead of reusing | P2 |

### A.1–A.5 — Design tokens (colors, typography, responsive, spacing, radius)
- **Colors & typography systems EXIST and are partly used** — the module is not starting from zero. But adoption is incomplete: **597 hardcoded color usages** coexist with 329 `AppColors` references, and **147 inline `TextStyle`** with 128 `AppText`/`AppTextStyles`. Worst offender: `student_override_sign_in_form.dart` (12 raw colors, 0 tokens). `Colors.grey`/`Colors.red` duplicate `AppColors.dividerColor`/`errorColor`.
- **Spacing, radius, and dimension token files DO NOT EXIST anywhere in the project** (no `AppSpacing`/`AppDimensions`/`AppRadius`). Every 8/12/16/20/24/32 padding, every `borderRadius.circular(n)`, and every fixed `height:`/`width:` in attendance is a raw literal. This is a **project‑wide design‑system gap** — the token layer must be created centrally before attendance can consume it.
- **No strings / i18n layer exists** (0 `.arb`, no `AppStrings`/`AppLocalizations`). 49 `Text('literal')` + 175 hardcoded `SnackBar` messages in attendance.
- **Responsive is fragmented, not centralized** — two helpers with different tablet breakpoints (768 vs 600) plus inline `screenWidth>=600` literals; there is no single responsive‑variable/token source.

### A.6–A.7 — Common widgets / reusable architecture
A rich shared widget library (~80 widgets: buttons, dropdowns, bottom sheets, shimmer, date picker, text field) exists and attendance uses parts of it (button family in 23 files). Gaps: **11 files use raw `TextField`** (0 use the shared field), the **debounced‑search pattern is re‑implemented in 14 files**, the **10 selection forms are near‑duplicate student/staff pairs**, `student_attendance_card.dart` is duplicated across two widget folders, and there is **no shared EmptyState** widget (hand‑rolled inline). These should be extracted into configurable common components (a `SelectableEntitySheet`, `DebouncedSearchField`, `EmptyState`).

### A.11 — Production Security & Centralized/Environment‑Aware Logging (highest priority)

**Central logger mechanism (CONFIRMED)** — `lib/core/util/logger_service.dart` `AppLogger`:
```dart
static void d(Object? message) {
  if (kDebugMode) { print('[DEBUG] $message'); }
  else { try { FirebaseCrashlytics.instance.log('[DEBUG] $message'); } catch (_) {} }  // ← release path
}   // i(), w() identical; e() → recordError
```
- 🔴 **P0 — In production the logger does NOT suppress or sanitize; it forwards the full message to Firebase Crashlytics.** The class doc claims "suppression is handled automatically via `kDebugMode`", but the release branch actively *ships* every `d/i/w` message (whatever the caller passed — bodies, codes, PINs) to a third‑party crash service. There is **no masking, no PII scrubbing, no environment tiering** (only a binary debug‑vs‑release; no dev/staging/prod distinction).
- 🔴 **P0 — Confirmed sensitive sinks flowing through this path:** full API request/response bodies (`api_client.dart:61‑109` + `api_logger.dart:41‑70`, only `Authorization` masked) and the **cleartext kiosk PIN** (`kiosk_logout_cubit.dart:41`) → `AppLogger.d` → Crashlytics in release.
- 🟡 **P2 — 24 raw `debugPrint()` in the attendance module** bypass the central logger entirely. `debugPrint` is **not stripped from release builds** by default, so these emit to device logs unsanitized. (No `print()` or `developer.log()` in attendance — good.)
- 🟡 **P2 — Errors are not production‑sanitized:** `AppLogger.e` records stack traces to Crashlytics (acceptable) but raw `DioException`/exception strings are also surfaced to users in several flows (SnackBars), and error→user messaging is inconsistent (`ApiErrorHandler` used in only 3/26 use‑cases).

**Security Review checklist (per criterion 11):**

| Check | Result | Evidence |
|---|:--:|---|
| No complete API response printed/logged in prod | ❌ | `api_logger.dart:41‑70` full body → Crashlytics |
| No access/refresh token logged | ⚠️ | `Authorization` masked (`_maskToken`), but refresh‑token mirrored to plaintext prefs (`token_refresh_service.dart:88`) |
| No password/OTP logged | ❌ | kiosk **PIN** logged cleartext (`kiosk_logout_cubit.dart:41`) |
| No auth headers logged | ⚠️ | only `Authorization` masked; `x-school-code`/`x-role`/identity headers not scrubbed |
| No unnecessary PII logged | ❌ | student/staff names, codes, guardian codes in bodies + `school_context_helper.dart:31‑100` |
| No unrestricted `print()` | ✅ | 0 in attendance |
| No unrestricted `debugPrint()` | ❌ | 24 in attendance (not stripped in release) |
| No unrestricted `developer.log()` | ✅ | 0 in attendance |
| Prod build free of dev‑level API logging | ❌ | logging interceptor added on every build; not gated by `kDebugMode` (`api_client.dart:61‑109`) |
| Prod errors sanitized | ❌ | raw `$e`/`DioException` reach users; only 3/26 use‑cases map errors |
| Logging centralized & environment‑aware | ⚠️ | centralized (`AppLogger`) but only binary debug/release, no masking, and release = "send to Crashlytics" not "minimal/sanitized" |

**Required (production‑security) fixes:** (1) gate the Dio logging interceptor behind `kDebugMode`; (2) make `AppLogger` sanitize/mask (or drop) message content before any Crashlytics forward, and never forward request/response bodies; (3) remove the cleartext PIN log; (4) replace the 24 `debugPrint`s with the central logger; (5) map errors to safe user messages centrally; (6) keep tokens only in secure storage (drop the plaintext refresh‑token mirror). Items 1–4 are fully client‑side and low‑risk.

### A.12–A.13 — Code quality & reuse‑first rules
The read stack already embodies the target structure (Global system → Cubit → UseCase → Repository). The **write surface violates the reuse‑first rule** — each sign‑in/out/transfer/selection screen re‑implements state, navigation, request building, search, and styling instead of consuming the shared design system, common widgets, and a shared cubit/use‑case. Remediation is convergent with the §14 P0/P1 architecture fixes: routing writes through Cubit/UseCase and extracting shared components resolves the design‑system, duplication, and MVVM findings together.

---

*All findings are AUDIT‑ONLY observations of the current working tree (`audit/attendance-fixes`); no code was modified. "Server protection" cells are UNABLE‑TO‑VERIFY from a client‑only codebase. Token/spacing/strings/responsive‑system gaps are project‑wide, not attendance‑specific.*
