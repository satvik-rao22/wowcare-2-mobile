import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/presentation/features/reports/model/report_form_result.dart';
import 'package:wowcare/presentation/features/reports/model/report_route_args.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_card.dart';

/// Opens the report form routes and applies whatever each form hands back.
///
/// Extracted from `reports_screen.dart` (§6.7): ~290 lines of push-and-handle
/// that the screen only needed to delegate to. Every branch switches on
/// [ReportItem.type], never on the display name.
class ReportFormLauncher {
  const ReportFormLauncher({
    required this.onReportGenerated,
    required this.onViewReport,
    required this.onDownloadReport,
  });

  /// Bring the Generated tab forward.
  final VoidCallback onReportGenerated;

  /// Download the asset and preview it in-app.
  final void Function(BuildContext context, String assetCode, String fileName)
  onViewReport;

  /// Download, save and hand the asset to the OS.
  final Future<void> Function(
    BuildContext context,
    String assetCode,
    String fileName, {
    bool previewPdfInApp,
  })
  onDownloadReport;

  void _handleReportFormResult(BuildContext context, ReportFormResult? result) {
    if (!context.mounted) return;
    switch (result) {
      case ReportGeneratedWithEntity(:final report):
        if (report.assetCode?.startsWith('base64:') == true) {
          onViewReport(
            context,
            report.assetCode!,
            report.fileName ?? 'report.xlsx',
          );
        } else {
          onReportGenerated();
        }
      case ReportGeneratedRefreshList():
        onReportGenerated();
      case null:
        break;
    }
  }

  void openStudentReportForm(BuildContext context, ReportItem item) {
    final cubit = context.read<ReportsCubit>();
    final reports = cubit.state;
    String? path;
    ReportFormArgs? args;
    switch (item.type) {
      case ReportType.studentDailyAttendance:
        path = ReportRoutes.studentDailyAttendance;
        args = ReportFormArgs(cubit: cubit, classrooms: reports.classroomNames);
        break;
      case ReportType.studentAbsent:
        path = ReportRoutes.studentAbsent;
        args = ReportFormArgs(cubit: cubit, classrooms: reports.classroomNames);
        break;
      case ReportType.studentAttendancePerStudent:
        path = ReportRoutes.studentAttendancePerStudent;
        args = ReportFormArgs(
          cubit: cubit,
          students: reports.studentNames,
          classrooms: reports.classroomNames,
        );
        break;
      case ReportType.studentsAndFamily:
        path = ReportRoutes.studentsAndFamily;
        args = ReportFormArgs(
          cubit: cubit,
          classrooms: reports.classroomNames,
          tags: reports.tagNames,
        );
        break;
      case ReportType.immunization:
        path = ReportRoutes.studentImmunization;
        args = ReportFormArgs(
          cubit: cubit,
          classrooms: reports.classroomNames,
          tags: reports.tagNames,
        );
        break;
      case ReportType.emergencyContacts:
        path = ReportRoutes.studentEmergencyContact;
        args = ReportFormArgs(cubit: cubit, classrooms: reports.classroomNames);
        break;
      case ReportType.studentIncident:
        path = ReportRoutes.studentIncident;
        args = ReportFormArgs(
          cubit: cubit,
          students: reports.studentNames,
          classrooms: reports.classroomNames,
        );
        break;
      default:
        // Every other ReportType belongs to another tab, or has no
        // form yet — falls through to the 'coming soon' notice, the
        // same outcome an unmatched name produced before.
        break;
    }

    if (path == null || args == null) {
      _showComingSoon(context, ReportsStrings.generateAction);
      return;
    }

    unawaited(
      context
          .push<ReportFormResult>(path, extra: args)
          .then((result) => _handleReportFormResult(context, result)),
    );
  }

  void openStaffReportForm(BuildContext context, ReportItem item) {
    final cubit = context.read<ReportsCubit>();
    final reports = cubit.state;
    String? path;
    ReportFormArgs? args;
    switch (item.type) {
      case ReportType.staffAttendancePerStaff:
        path = ReportRoutes.staffAttendancePerWeek;
        args = ReportFormArgs(
          cubit: cubit,
          staff: reports.staffNames,
          classrooms: reports.classroomNames,
        );
        break;
      case ReportType.staffDetails:
        path = ReportRoutes.staffDetails;
        args = ReportFormArgs(cubit: cubit, classrooms: reports.classroomNames);
        break;
      case ReportType.staffAbsent:
        path = ReportRoutes.staffAbsent;
        args = ReportFormArgs(cubit: cubit, classrooms: reports.classroomNames);
        break;
      case ReportType.staffScheduling:
        path = ReportRoutes.staffSchedule;
        args = ReportFormArgs(cubit: cubit, classrooms: reports.classroomNames);
        break;
      default:
        // Every other ReportType belongs to another tab, or has no
        // form yet — falls through to the 'coming soon' notice, the
        // same outcome an unmatched name produced before.
        break;
    }

    if (path == null || args == null) {
      _showComingSoon(context, ReportsStrings.generateAction);
      return;
    }

    unawaited(
      context
          .push<ReportFormResult>(path, extra: args)
          .then((result) => _handleReportFormResult(context, result)),
    );
  }

  void openComplianceReportForm(BuildContext context, ReportItem item) {
    final cubit = context.read<ReportsCubit>();
    String? path;
    switch (item.type) {
      case ReportType.annualStateImmunization:
        // Both PDF and Excel buttons open the same form; format selection
        // happens on the backend when Generate is pressed.
        path = ReportRoutes.complianceAnnualStateImmunization;
        break;
      default:
        // Every other ReportType belongs to another tab, or has no
        // form yet — falls through to the 'coming soon' notice, the
        // same outcome an unmatched name produced before.
        break;
    }

    if (path == null) {
      _showComingSoon(context, ReportsStrings.generateAction);
      return;
    }

    unawaited(
      context
          .push<ReportFormResult>(path, extra: ReportFormArgs(cubit: cubit))
          .then((result) => _handleReportFormResult(context, result)),
    );
  }

  /// Billing reports are generated synchronously: the endpoint streams the
  /// file back, so save it and show it right away instead of only bouncing
  /// back to the Generated tab.
  void _handleBillingReportFormResult(
    BuildContext context,
    ReportFormResult? result,
  ) {
    if (!context.mounted) return;
    switch (result) {
      case ReportGeneratedWithEntity(:final report):
        final assetCode = report.assetCode;
        if (assetCode != null && assetCode.isNotEmpty) {
          unawaited(
            onDownloadReport(
              context,
              assetCode,
              report.fileName ?? 'report.xlsx',
              previewPdfInApp: true,
            ),
          );
        } else {
          onReportGenerated();
        }
      case ReportGeneratedRefreshList():
        onReportGenerated();
      case null:
        break;
    }
  }

  void openBillingReportForm(BuildContext context, ReportItem item) {
    final cubit = context.read<ReportsCubit>();
    final reports = cubit.state;

    // The five form-screen variants differ only by report type and title.
    BillingReportFormArgs billingArgs(ReportType type, String title) =>
        BillingReportFormArgs(
          cubit: cubit,
          reportType: type,
          title: title,
          classrooms: reports.classroomNames,
          students: reports.studentNames,
        );

    String? path;
    ReportRouteArgs? args;
    switch (item.type) {
      case ReportType.billingTransaction:
        path = ReportRoutes.billingTransaction;
        args = ReportFormArgs(cubit: cubit);
        break;
      case ReportType.billingInvoice:
        path = ReportRoutes.billingForm;
        args = billingArgs(ReportType.billingInvoice, item.name);
        break;
      case ReportType.billingPaymentSummary:
        path = ReportRoutes.billingForm;
        args = billingArgs(ReportType.billingPaymentSummary, item.name);
        break;
      case ReportType.billingOutstanding:
        path = ReportRoutes.billingForm;
        args = billingArgs(ReportType.billingOutstanding, item.name);
        break;
      case ReportType.billingRefund:
        path = ReportRoutes.billingForm;
        args = billingArgs(ReportType.billingRefund, item.name);
        break;
      case ReportType.billingStudentMapping:
        path = ReportRoutes.billingForm;
        args = billingArgs(ReportType.billingStudentMapping, item.name);
        break;
      default:
        // Every other ReportType belongs to another tab, or has no
        // form yet — falls through to the 'coming soon' notice, the
        // same outcome an unmatched name produced before.
        break;
    }

    if (path == null || args == null) {
      _showComingSoon(context, ReportsStrings.generateAction);
      return;
    }

    unawaited(
      context
          .push<ReportFormResult>(path, extra: args)
          .then((result) => _handleBillingReportFormResult(context, result)),
    );
  }

  void _showComingSoon(BuildContext context, String action) {
    CoreUtils.showTopSnackBar(
      context: context,
      message: ReportsStrings.comingSoon(action),
      isWarning: true,
    );
  }
}
