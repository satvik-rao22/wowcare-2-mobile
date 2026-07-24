# Reports Module — Prioritized Fix Plan

## Critical
1. **Add `WidgetsBindingObserver` resume handling to `ReportsScreen` and `GeneratedReportsScreen`** to force a repaint after returning from `OpenFilex.open`'s external Activity. File: `reports_screen.dart`, `generated_reports_screen.dart`. Why critical: this is the confirmed root cause of the reported black-screen issue — a visible crash-like failure for every user who opens a report.
2. **Fix School Immunization report date range**: replace hardcoded `AppTime.now()`/`AppTime.now()` with a real date-range picker. File: `student_immunization_report_screen.dart:79-80`. Why critical: this is the confirmed root cause of "unable to generate School Immunization Report" — the request always returns empty/near-empty data.
3. **Await `generateReport()` before popping the immunization form**, using the same `BlocListener`-driven success/error pattern as sibling screens. File: `student_immunization_report_screen.dart:89-92`. Why critical: without this, errors from fix #2 (or any future failure) will still be silently swallowed.

## High
4. **Standardize navigation on go_router** for report forms instead of mixing `Navigator.push` with `context.go`. File: `reports_screen.dart:94-109` and all form screens using `context.go` on success. Why high: risk of back-stack corruption compounds over repeated use and is hard to diagnose after the fact.

## Medium
5. **Consolidate duplicated download/open/save logic** into a single cubit method or use case shared by `ReportsScreen` and `GeneratedReportsScreen`. Files: `reports_screen.dart:704-813`, `generated_reports_screen.dart:51-217`. Why medium: not a current user-facing bug, but increases risk that fixes like #1 get applied inconsistently across call sites.
6. **Move `FileDownloadRepository` calls out of `ReportsCubit`** into a proper use case to restore strict Clean Architecture layering. File: `reports_cubit.dart:304-329`. Why medium: architectural cleanliness, not a functional defect.

## Low
7. **Verify timezone handling for Attendance Per Student report** date fields against school-local time rather than device-local time. File: `report_request_params.dart:69-76`. Why low: not confirmed as an active bug, but flagged as a risk near midnight boundaries.
8. **Re-evaluate `AutomaticKeepAliveClientMixin`** on `GeneratedReportsScreen` once the lifecycle-observer fix (#1) lands, to confirm it doesn't still contribute to stale frames. File: `generated_reports_screen.dart:28,32`.
9. **Add test coverage for the reports module** (cubit unit tests, at minimum for generate/download/open flows) — no coverage was found during this audit.
