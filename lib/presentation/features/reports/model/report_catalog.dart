import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';
import 'package:wowcare/presentation/features/reports/widgets/report_card.dart';

/// The reports hub's catalogue: the tab labels and the cards each tab shows.
///
/// Pure configuration, so it lives in `model/` rather than inside the screen
/// (§3, §6.7). Each [ReportItem] carries a [ReportType] as its stable identity
/// — navigation switches on that, never on the display name.
class ReportCatalog {
  const ReportCatalog._();

  static const List<String> tabs = <String>[
    ReportsStrings.tabGenerated,
    ReportsStrings.tabStudent,
    ReportsStrings.tabStaff,
    ReportsStrings.tabCompliance,
    ReportsStrings.tabBilling,
  ];

  static const List<ReportItem> studentReports = <ReportItem>[
    ReportItem(
      type: ReportType.studentDailyAttendance,
      name: ReportsStrings.studentDailyAttendanceName,
      description: ReportsStrings.studentDailyAttendanceDesc,
    ),
    ReportItem(
      type: ReportType.studentAbsent,
      name: ReportsStrings.studentAbsentName,
      description: ReportsStrings.studentAbsentDesc,
    ),
    ReportItem(
      type: ReportType.studentAttendancePerStudent,
      name: ReportsStrings.studentAttendancePerStudentName,
      description: ReportsStrings.studentAttendancePerStudentDesc,
    ),
    ReportItem(
      type: ReportType.studentsAndFamily,
      name: ReportsStrings.studentsAndFamilyName,
      description: ReportsStrings.studentsAndFamilyDesc,
    ),
    ReportItem(
      type: ReportType.immunization,
      name: ReportsStrings.studentImmunizationName,
      description: ReportsStrings.studentImmunizationDesc,
    ),
    ReportItem(
      type: ReportType.emergencyContacts,
      name: ReportsStrings.studentEmergencyContactName,
      description: ReportsStrings.studentEmergencyContactDesc,
    ),
    ReportItem(
      type: ReportType.studentIncident,
      name: ReportsStrings.studentIncidentName,
      description: ReportsStrings.studentIncidentDesc,
    ),
  ];

  static const List<ReportItem> staffReports = <ReportItem>[
    ReportItem(
      type: ReportType.staffAttendancePerStaff,
      name: ReportsStrings.staffAttendancePerStaffName,
      description: ReportsStrings.staffAttendancePerStaffDesc,
    ),
    ReportItem(
      type: ReportType.staffDetails,
      name: ReportsStrings.staffDetailsName,
      description: ReportsStrings.staffDetailsDesc,
    ),
    ReportItem(
      type: ReportType.staffAbsent,
      name: ReportsStrings.staffAbsentName,
      description: ReportsStrings.staffAbsentDesc,
    ),
    ReportItem(
      type: ReportType.staffScheduling,
      name: ReportsStrings.staffSchedulingName,
      description: ReportsStrings.staffSchedulingDesc,
    ),
  ];

  static const List<ReportItem> complianceReports = <ReportItem>[
    ReportItem(
      type: ReportType.annualStateImmunization,
      name: ReportsStrings.annualStateImmunizationName,
      description: ReportsStrings.annualStateImmunizationDesc,
    ),
  ];

  static const List<ReportItem> billingReports = <ReportItem>[
    ReportItem(
      type: ReportType.billingTransaction,
      name: ReportsStrings.billingTransactionName,
      description: ReportsStrings.billingTransactionDesc,
    ),
    ReportItem(
      type: ReportType.billingInvoice,
      name: ReportsStrings.billingInvoiceName,
      description: ReportsStrings.billingInvoiceDesc,
    ),
    ReportItem(
      type: ReportType.billingPaymentSummary,
      name: ReportsStrings.billingPaymentSummaryName,
      description: ReportsStrings.billingPaymentSummaryDesc,
    ),
    ReportItem(
      type: ReportType.billingOutstanding,
      name: ReportsStrings.billingOutstandingName,
      description: ReportsStrings.billingOutstandingDesc,
    ),
    ReportItem(
      type: ReportType.billingRefund,
      name: ReportsStrings.billingRefundName,
      description: ReportsStrings.billingRefundDesc,
    ),
    ReportItem(
      type: ReportType.billingStudentMapping,
      name: ReportsStrings.billingStudentMappingName,
      description: ReportsStrings.billingStudentMappingDesc,
    ),
  ];
}
