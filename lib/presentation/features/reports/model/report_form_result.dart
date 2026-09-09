import 'package:wowcare/domain/features/reports/entities/report_entity.dart';

/// What a report form screen hands back to the reports hub when it closes.
///
/// This replaces the untyped `Object?` protocol the forms used to pop —
/// `pop(true)` for "generated, refresh the list" and `pop(reportEntity)` for
/// "generated, here is the file", which the hub read back with `result is
/// ReportEntity` / `result == true` (§1.2 forbids exactly that).
///
/// Pushed as `context.push<ReportFormResult>(...)`, so a form that is simply
/// dismissed — back button, app-bar back, swipe — completes the push with
/// `null` and neither variant runs. That `null` is the third case the hub
/// switches on, and it is the same "user cancelled" outcome the old protocol
/// produced when the pop carried no value.
sealed class ReportFormResult {
  const ReportFormResult();
}

/// The report was generated and the endpoint returned the file with it —
/// billing reports are generated synchronously, and some student/staff
/// reports come back inline as `base64:` in [ReportEntity.assetCode].
///
/// The hub downloads and shows the file rather than only switching tabs.
final class ReportGeneratedWithEntity extends ReportFormResult {
  const ReportGeneratedWithEntity(this.report);

  final ReportEntity report;
}

/// The report was generated but the file is not attached to the result — it
/// is produced asynchronously and will appear in the Generated list.
///
/// The hub animates to the Generated tab.
final class ReportGeneratedRefreshList extends ReportFormResult {
  const ReportGeneratedRefreshList();
}
