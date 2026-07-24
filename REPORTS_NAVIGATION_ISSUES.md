# Reports Module — Navigation & Black Screen Root Cause

## Black Screen After Opening Report and Navigating Back — ROOT CAUSE

`ReportFileViewerScreen` (`lib/presentation/features/reports/view/report_file_viewer_screen.dart`) is **not** the source of the black screen. It renders PDFs in-app using `flutter_pdfview`'s `PDFView(pdfData: widget.fileData)` (line 128) and only writes bytes to disk when the user explicitly downloads (lines 41-88). It never launches an external app, so pop/back navigation out of this screen is safe.

The real trigger is the "open externally" flow:

```
UI (ReportsScreen._downloadAndSaveReport, reports_screen.dart:704-813, open call line 787)
UI (GeneratedReportsScreen._handleDownload, generated_reports_screen.dart:51-217, open call line 182)
  → ReportsCubit.openReportFile (reports_cubit.dart:304-329)
  → FileDownloadRepository.openFile (file_download_repository.dart:56-85)
  → FileDownloadService (lib/data/services/file_download_service.dart:169-172)
  → OpenFilex.open(filePath, type: mimeType)
```

`OpenFilex.open` hands the file to the OS, which launches a **separate Android Activity** (the system/third-party PDF or Excel viewer) on top of Flutter's `FlutterActivity`. This is standard Android behavior, but it means:

- The Flutter engine's `SurfaceView`/`FlutterView` is fully covered and paused by the foreign Activity.
- When the user presses back in that external viewer, Android resumes `FlutterActivity`, but the engine does not automatically force a new frame in all cases — this is the well-documented `flutter → external activity → back` black-frame issue on Android.
- A grep of `lib/presentation/features/reports/` confirms there is **no `WidgetsBindingObserver`** and **no `AppLifecycleState.resumed` handler** anywhere in the module to force a repaint/refresh when control returns from the external Activity.

Compounding this: `GeneratedReportsScreen` uses `AutomaticKeepAliveClientMixin` (generated_reports_screen.dart:28/32), which keeps its widget subtree (including any `PDFView`) alive underneath the tab, rather than rebuilding fresh when the tab regains visibility — increasing the odds the resumed frame stays stale/black rather than repainting.

### Fix
Add a `WidgetsBindingObserver` to the screen(s) that call `openReportFile`/`OpenFilex.open`, and in `didChangeAppLifecycleState(AppLifecycleState.resumed)` trigger a `setState(() {})` (or otherwise force a rebuild, e.g. via a `ValueNotifier` tick) after returning from the external viewer. Example:

```dart
class _ReportsScreenState extends State<ReportsScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }
}
```

Apply the same pattern to `GeneratedReportsScreen`.

## Secondary Navigation Issue: Mixed Navigator.push / go_router

`reports_screen.dart` mixes imperative `Navigator.push` (used to open report forms, e.g. lines 94-109) with go_router's `context.go('/dashboard/reports?tab=0')` on generation success — a pattern repeated by every form screen (e.g. `student_immunization_report_screen.dart:185`).

`context.go` replaces the current go_router location rather than popping the imperative stack cleanly. When a form was opened via `Navigator.push` and then the form itself calls `context.go(...)` on success, the previously-pushed imperative route can be left orphaned under the fresh go_router location, corrupting the back stack. Over repeated open/generate cycles this can manifest as extra "ghost" screens in the back stack or unexpected pop targets.

### Fix
Standardize on one navigation mechanism for the reports module. Prefer go_router throughout (`context.push`/`context.pop`) for report forms instead of `Navigator.push`, so success handlers can safely use `context.go`/`context.pop` without straddling two navigation stacks.
