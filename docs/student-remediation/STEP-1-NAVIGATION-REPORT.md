# STUDENT MODULE — STEP 1: GOROUTER NAVIGATION REMEDIATION (REPORT)

> Branch `audit/student-fixes` · baseline `fb41d154`. Student navigation now uses the app's
> existing **GoRouter** architecture (path-based `GoRoute` + `state.extra`/query, verbs
> `context.push`/`go`/`pop`). No second routing system was introduced.

## BEFORE
Student presentation drove most screen transitions imperatively — **~26 `Navigator.push` /
`Navigator.of().push` sites** (all via `MaterialPageRoute`), only 2 destinations were in GoRouter
(`students`, `student-profile`). See STEP-0-BASELINE.md.

## AFTER
- **~27 call sites converted** `Navigator.push(MaterialPageRoute…)` → `context.push(routeName, extra:)`
  (25 `context.push` calls now in the module).
- **~15 route-return pops** converted `Navigator.pop(result)` → `context.pop(result)`; dialog/sheet
  pops (`showDialog`/`showModalBottomSheet` with a local `ctx`) correctly **left as `Navigator.pop`**.
- `flutter analyze` (student scope): **0 issues introduced** (9 remaining are pre-existing baseline
  noise in files this work didn't touch — legacy `add_student_screen`, `provider`/`_fteDisplay` in
  `student_profile_screen`, dialog deprecations, a test import).
- **Student tests: 105 / 105 passing.**

## ROUTES CREATED / UPDATED

**New routes (13):**
| Route (path) | Screen | Notes |
|---|---|---|
| `/edit-student-important-dates` | EditStudentImportantDates | routeName added |
| `/edit-student-health` | EditStudentHealth | routeName added |
| `/add-physician-screen` | AddPhysician | |
| `/add-pickup-screen` | AddPickup | |
| `/add-student-document-screen` | AddStudentDocument | |
| `/edit-student-physical-exam` | EditStudentPhysicalExam | routeName added |
| `/student-filter` | StudentFilter | route provides its own `ClassroomCubit` |
| `/edit-student-profile-details-screen` | EditStudentProfileDetails | provides `ClassroomCubit` (scope via extra) |
| `/student-activity-feed` | ActivityFeedScreen | dedicated student-scoped feed (doesn't disturb the Activities tab) |
| `/document-viewer` | DocumentViewerScreen (shared) | routeName added |
| `/add-student-wizard-screen` | AddStudentWizardScreen | wizard entry (wraps Step1 + `ClassroomCubit`) |
| `/add-student-step2-screen` | AddStudentStep2 | reused by wizard **and** add-sibling |
| `/add-student-step3-screen` | AddStudentStep3 | reused by wizard **and** edit-schedule |

**Reused / updated existing routes (4):**
- `/dashboard/student-profile` — helper `_studentProfileScreen` **extended** to pass `initialEnrollmentStatus`.
- `/dashboard/student-attendance-tabbed-view`, `/dashboard/student-attendance-profile` — reused.
- `TransactionDetailsScreen.routeName` — reused (typed `TransactionDetailsArgs` extra).

## PARAMETERS
- Simple editors: **`studentCode` + typed prefill** via `state.extra` (a `Map`); each returns its
  result through `context.pop(result)` (`bool` / data map / filter map).
- Screens needing classroom data (`filter`, `edit-profile`) get a **`ClassroomCubit` provided in the
  route builder** (was an inline `BlocProvider` at the call site). The old "reuse the caller's already
  loaded cubit" was a load optimisation, not a dependency — `edit-profile` preserves the exact prior
  behaviour by passing `applyAttendanceStaffScope` through extra.
- Cross-feature: `TransactionDetailsArgs` (typed), student-scoped activity via extra map.
- No large domain objects are threaded where an ID suffices; the wizard steps pass their existing
  prefill fields via extra (route-per-step, option 2).

## DEEP-LINK VERIFICATION
- Path-based routes register under the existing GoRouter tree; the app's deep-link targets remain
  (`student-profile-by-code`, `student-attendance-profile-by-code` self-load by `studentCode`).
- Modal editors / wizard steps are **intra-app flows carrying prefill state**, not cold deep-link
  targets — consistent with the app's convention (they need a live selection/state), so they are
  reached via `context.push(..., extra:)`, not linkable URLs. No deep-link regressions.
- System/AppBar back and `context.pop(result)` return values verified against each awaiting caller.

## REMAINING `Navigator.push` — and why each is legitimate (5)
| Site | Target | Justification |
|---|---|---|
| `student_screen.dart:933/981/1037/1084` | StudentSignIn/SignOut/Transfer/MarkAbsent forms | Receive a **live `refreshCallback` closure + a `List<entity>` selection**. Routing closures/entity-lists is the exact anti-pattern the spec warns against and cannot be deep-linked. Transient attendance-module action flows on a live selection. |
| `student_action_panel.dart:441` | dynamic `nextScreen` (activity) | The target widget is **resolved at runtime** (built from activity maps) and returns `true` via pop — not a fixed route; not route-serializable. |

All are cross-module, callback/entity/dynamic-widget bound — migrating them would violate the very
principles of this step. Documented as intentional exceptions.

---
*Step 1 complete. Verified: `flutter analyze` clean (no new issues) + 105/105 student tests passing.*
