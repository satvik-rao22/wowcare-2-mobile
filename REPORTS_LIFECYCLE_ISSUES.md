# Reports Module — Lifecycle Audit

## Controllers / dispose()
All StatefulWidgets in `lib/presentation/features/reports/view/*.dart` and `widgets/*.dart` were checked for controller creation vs. disposal (TextEditingController, ScrollController, TabController, AnimationController, PageController). No missing `dispose()` calls were found for controllers that are created — the module is not leaking controllers in the classic sense.

## Missing lifecycle observer (root cause of black-screen bug)
No screen in the reports module implements `WidgetsBindingObserver` / overrides `didChangeAppLifecycleState`. This is the primary lifecycle gap in the module: after an external Activity (PDF/Excel viewer launched via `OpenFilex.open`, see `file_download_service.dart:169-172`) is dismissed, nothing in `ReportsScreen` or `GeneratedReportsScreen` reacts to `AppLifecycleState.resumed` to force a repaint. Full trace and fix in `REPORTS_NAVIGATION_ISSUES.md`.

## AutomaticKeepAliveClientMixin
`GeneratedReportsScreen` (`generated_reports_screen.dart:28,32`) uses `AutomaticKeepAliveClientMixin` to keep its tab's subtree alive across tab switches. This is a legitimate pattern for tab persistence, but combined with the missing lifecycle observer above, it increases the chance that the widget tree resumes in a stale, unpainted state after returning from an external Activity rather than triggering a natural rebuild.

## mounted checks / async gaps
- `ReportFileViewerScreen` (`report_file_viewer_screen.dart:41-88`) writes file bytes on download; this path was reviewed for `BuildContext` usage after `await` — no unguarded `setState`/context usage after dispose was found in this screen.
- `student_immunization_report_screen.dart:89-92` has a related but distinct problem, not a `mounted`-check issue: `cubit.generateReport(params)` is fired without `await` and the screen pops itself immediately afterward, meaning any subsequent state emission from the cubit has no listener. See `REPORTS_BUGS.md` #2 for the fix.

## Cubit lifecycle
`ReportsCubit` correctly guards against emitting after disposal — `isClosed` checks are present before emits following awaited work (`reports_cubit.dart`, reviewed in full). No emit-after-close risk was found in the cubit itself.

## Summary
The module's classic "controller leak" surface is clean. The real lifecycle defect is architectural: absence of `WidgetsBindingObserver`-driven resume handling for the external-file-open flow, which is the direct cause of the black-screen issue.
