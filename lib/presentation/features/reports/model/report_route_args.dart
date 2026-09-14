import 'dart:typed_data';

import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';

/// Common base for the report form route arguments, so the hub can hold a
/// route's arguments in a typed variable while it decides which form to open
/// — no `Object?` at either end of the push.
///
/// [cubit] is the reports hub's own [ReportsCubit] instance, handed to the
/// route so the form can be wrapped in a `BlocProvider.value`. It is passed
/// rather than constructed in the `GoRoute` builder because `ReportsCubit` is
/// registered as a factory and the name→code maps the forms resolve their
/// selections against (`classroomNameToCode`, `studentNameToCode`,
/// `staffNameToCode`) are populated on the hub's instance by the hub's
/// Classroom/Student/Staff listeners. A fresh instance would resolve every
/// selection to nothing.
sealed class ReportRouteArgs {
  const ReportRouteArgs({required this.cubit});

  final ReportsCubit cubit;
}

/// Arguments for standard report generation screens.
final class ReportFormArgs extends ReportRouteArgs {
  final List<String>? classrooms;
  final List<String>? students;
  final List<String>? staff;
  final List<String>? tags;

  const ReportFormArgs({
    required super.cubit,
    this.classrooms,
    this.students,
    this.staff,
    this.tags,
  });
}

/// Arguments for billing specific report generation screens.
///
/// See [ReportRouteArgs.cubit] for why the cubit instance travels with the
/// arguments.
final class BillingReportFormArgs extends ReportRouteArgs {
  final ReportType reportType;
  final String title;
  final List<String>? classrooms;
  final List<String>? students;

  const BillingReportFormArgs({
    required super.cubit,
    required this.reportType,
    required this.title,
    this.classrooms,
    this.students,
  });
}

/// Arguments for the report file viewer screen.
///
/// The single declaration of this name in the codebase (§6.5). It lives here,
/// with the screen it describes, and is used by both the reports hub and the
/// billing statements tabs. The two callers push different routes —
/// `ReportRoutes.fileViewer` renders inside the nav shell, and
/// `ReportRoutes.billingFileViewer` renders over it at the router root — but
/// both carry these same arguments.
class ReportFileViewerArgs {
  final Uint8List fileData;
  final String fileName;
  final String fileType;

  const ReportFileViewerArgs({
    required this.fileData,
    required this.fileName,
    required this.fileType,
  });
}
