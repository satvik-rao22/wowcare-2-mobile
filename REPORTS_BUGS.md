# Reports Module — Bug List

## Critical

### 1. School Immunization Report — hardcoded to "today only" date range
- File: `lib/presentation/features/reports/view/student_immunization_report_screen.dart:79-80`
- Root cause: the request params are built with `startDate: AppTime.now(), endDate: AppTime.now()`. There is no date-range field anywhere in this form's UI, so the params always cover a single day (today), regardless of what data the user actually wants.
- Impact: the API call succeeds, but returns empty or near-empty data for almost every request, which the user experiences as "unable to generate School Immunization Report."
- Fix: add a date-range picker to the form (matching the pattern used by other report screens, e.g. attendance reports) and pass the selected range into `ReportRequestParams` instead of `AppTime.now()` for both fields.

### 2. School Immunization Report — generation call not awaited, errors swallowed
- File: `lib/presentation/features/reports/view/student_immunization_report_screen.dart:89-92`
- Root cause: `_onGenerate()` calls `cubit.generateReport(params)` without `await` and immediately calls `Navigator.of(context).pop(true)` on the next line. Every sibling report screen instead waits for a `generationSuccess` state via `BlocListener` before popping.
- Impact: the form screen is popped before generation completes. If the API call fails, the `generationError` state is emitted after the listening screen is already disposed, so no error is ever shown to the user — it silently fails and looks like nothing happened.
- Fix: remove the premature `pop`; use the same `BlocListener`-driven `generationSuccess`/`generationError` pattern used elsewhere, popping only on confirmed success and surfacing errors via snackbar/dialog on failure.

### 3. Black screen after returning from external PDF/Excel viewer
- Files: `lib/data/services/file_download_service.dart:169-172` (`OpenFilex.open`), `lib/presentation/features/reports/cubit/reports_cubit.dart:304-329`, `lib/presentation/features/reports/view/reports_screen.dart:704-813`, `lib/presentation/features/reports/view/generated_reports_screen.dart:51-217`
- Root cause: opening a downloaded file launches a separate Android Activity via `OpenFilex.open`. No `WidgetsBindingObserver`/`AppLifecycleState.resumed` handler exists anywhere in `lib/presentation/features/reports/` to force a repaint when that Activity is dismissed and control returns to Flutter.
- Impact: users see a black screen after backing out of the opened PDF/Excel file.
- Fix: see `REPORTS_NAVIGATION_ISSUES.md` for the full trace and code fix (add `WidgetsBindingObserver` + forced rebuild on resume).

## Medium

### 4. Mixed Navigator.push and go_router navigation
- Files: `lib/presentation/features/reports/view/reports_screen.dart:94-109` (Navigator.push), various form screens e.g. `student_immunization_report_screen.dart:185` (`context.go`)
- Root cause: report forms are opened with imperative `Navigator.push` but closed/redirected with go_router's `context.go`, straddling two navigation stacks.
- Impact: potential orphaned routes / corrupted back stack after repeated open-generate cycles.
- Fix: standardize on go_router (`context.push`/`context.pop`) for the whole module.

### 5. Duplicated download/open/save logic
- Files: `reports_screen.dart:704-813`, `generated_reports_screen.dart:51-217`, and `ReportsCubit`/`FileDownloadRepository`
- Root cause: the download → save → open sequence is implemented independently in at least 3 call sites instead of a single shared helper.
- Impact: harder to fix bugs like #3 consistently; risk of the fix being applied in one place and missed in another.
- Fix: consolidate into a single method on `ReportsCubit` or a dedicated use case that all callers invoke.

## Low

### 6. `AutomaticKeepAliveClientMixin` on `GeneratedReportsScreen` keeps stale widget tree alive
- File: `lib/presentation/features/reports/view/generated_reports_screen.dart:28,32`
- Root cause: keeping the tab's subtree alive across tab switches/external-app returns increases the chance a stale (unpainted) frame is shown rather than a fresh rebuild.
- Impact: contributes to, but is not solely responsible for, bug #3.
- Fix: after implementing the lifecycle-observer fix in #3, verify this mixin is still necessary; if kept, ensure resume handling forces a repaint of the kept-alive subtree too.

## Notes on Attendance Per Student report
`student_attendance_per_student_report_screen.dart` and `ReportRequestParams` (`report_request_params.dart:69-76`) are wired correctly — correct endpoint, correct field names (`roomCodes` for this report type). Only a minor risk was noted: local-device-time vs. school-timezone date handling was not explicitly normalized, which could cause off-by-one-day results near midnight for schools in a different timezone than the device. Not confirmed as an active bug, flagged for verification.
