import 'package:json_annotation/json_annotation.dart';
import 'package:wowcare/data/features/reports/models/report_request_context.dart';
import 'package:wowcare/data/features/reports/models/report_request_payload.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';

part 'generic_report_request_body.g.dart';

/// The request body shared by the attendance, roster and billing reports.
///
/// The date keys and the classroom key are report-type dependent, so
/// [GenericReportRequestBody.fromParams] picks which fields to populate and
/// `includeIfNull: false` drops the rest — the branching decides *values*,
/// generation decides the JSON.
@JsonSerializable(includeIfNull: false, createFactory: false)
class GenericReportRequestBody extends ReportRequestPayload {
  const GenericReportRequestBody({
    required this.reportType,
    required this.format,
    this.schoolName,
    this.periodType,
    this.date,
    this.asOfDate,
    this.dateFrom,
    this.dateTo,
    this.startDate,
    this.endDate,
    this.roomCodes,
    this.classroomCodes,
    this.studentCodes,
    this.staffCodes,
    this.tagCodes,
    this.search,
    this.grouping,
    this.invoiceStatuses,
    this.transactionStatuses,
    this.transactionTypes,
    this.paymentMethods,
    this.schoolCode,
    this.organizationCode,
    this.generatedBy,
  });

  factory GenericReportRequestBody.fromParams(
    ReportRequestParams params,
    ReportRequestContext context,
  ) {
    final type = params.reportType;

    // Exactly one date shape applies, chosen by report type.
    final isDailyAttendance = type == ReportType.studentDailyAttendance;
    final isOutstanding = type == ReportType.billingOutstanding;
    final isBillingRange =
        type == ReportType.billingTransaction ||
        type == ReportType.billingInvoice ||
        type == ReportType.billingPaymentSummary ||
        type == ReportType.billingRefund ||
        type == ReportType.billingStudentMapping;

    // These reports use `roomCodes`; everything else uses `classroomCodes`.
    //
    // STAFF_ABSENT belongs in this list: it shares
    // `ApiPaths.staffAttendanceReportsGenerate` with STAFF_ATTENDANCE_PER_STAFF,
    // which reads `roomCodes`, so sending `classroomCodes` silently dropped
    // the classroom filter and every staff-absent report covered all rooms.
    final usesRoomCodes =
        type == ReportType.studentAbsent ||
        type == ReportType.studentAttendancePerStudent ||
        type == ReportType.staffAbsent ||
        type == ReportType.staffAttendancePerStaff ||
        type == ReportType.emergencyContacts ||
        type == ReportType.studentIncident;

    // Outstanding and refund reports take no classroom filter at all.
    final acceptsClassroomCodes =
        type != ReportType.billingOutstanding &&
        type != ReportType.billingRefund;

    return GenericReportRequestBody(
      reportType: type.backendValue,
      format: params.format,
      schoolName: ReportRequestPayload.blankToNull(
        ReportRequestPayload.resolveSchoolName(
          params.schoolName,
          context.schoolName,
        ),
      ),
      periodType: ReportRequestPayload.blankToNull(params.periodType),
      date: isDailyAttendance
          ? ReportRequestPayload.ymd(params.date ?? params.startDate)
          : null,
      asOfDate: isOutstanding
          ? ReportRequestPayload.isoUtc(params.startDate)
          : null,
      dateFrom: isBillingRange
          ? ReportRequestPayload.isoUtc(params.startDate)
          : null,
      dateTo: isBillingRange && params.endDate != null
          ? ReportRequestPayload.isoUtc(params.endDate!)
          : null,
      startDate: (isDailyAttendance || isOutstanding || isBillingRange)
          ? null
          : ReportRequestPayload.ymd(params.startDate),
      endDate:
          (isDailyAttendance || isOutstanding || isBillingRange) ||
              params.endDate == null
          ? null
          : ReportRequestPayload.ymd(params.endDate!),
      // An empty list is still sent for these keys — only `null` omits them.
      roomCodes: usesRoomCodes ? params.roomCodes : null,
      classroomCodes: (!usesRoomCodes && acceptsClassroomCodes)
          ? params.roomCodes
          : null,
      studentCodes: params.studentCodes,
      staffCodes: params.staffCodes,
      tagCodes: params.tagCodes,
      search: ReportRequestPayload.blankToNull(params.search)?.trim(),
      grouping: ReportRequestPayload.blankToNull(params.folderClassGrouping),
      invoiceStatuses: ReportRequestPayload.emptyToNull(params.invoiceStatuses),
      transactionStatuses: ReportRequestPayload.emptyToNull(
        params.transactionStatuses,
      ),
      transactionTypes: ReportRequestPayload.emptyToNull(
        params.transactionTypes,
      ),
      paymentMethods: ReportRequestPayload.emptyToNull(params.paymentMethods),
      schoolCode: context.schoolCode,
      organizationCode: context.organizationCode,
      generatedBy: context.generatedBy,
    );
  }

  final String reportType;
  final String format;
  final String? schoolName;
  final String? periodType;
  final String? date;
  final String? asOfDate;
  final String? dateFrom;
  final String? dateTo;
  final String? startDate;
  final String? endDate;
  final List<String>? roomCodes;
  final List<String>? classroomCodes;
  final List<String>? studentCodes;
  final List<String>? staffCodes;
  final List<String>? tagCodes;
  final String? search;
  final String? grouping;
  final List<String>? invoiceStatuses;
  final List<String>? transactionStatuses;
  final List<String>? transactionTypes;
  final List<String>? paymentMethods;
  final String? schoolCode;
  final String? organizationCode;
  final String? generatedBy;

  @override
  Map<String, dynamic> toJson() => _$GenericReportRequestBodyToJson(this);
}
