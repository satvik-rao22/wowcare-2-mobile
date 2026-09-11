import 'package:json_annotation/json_annotation.dart';
import 'package:wowcare/data/features/reports/models/report_request_context.dart';
import 'package:wowcare/data/features/reports/models/report_request_payload.dart';
import 'package:wowcare/domain/features/reports/usecases/school_immunization_report_params.dart';

part 'school_immunization_request_body.g.dart';

/// Request body for the School Immunization report.
///
/// Key names are the ones the web client sends: `roomCodes`/`tagCodes` and a
/// singular `statusFilter` holding a list — not `classrooms`/`tags`/`statuses`.
@JsonSerializable(includeIfNull: false, createFactory: false)
class SchoolImmunizationRequestBody extends ReportRequestPayload {
  const SchoolImmunizationRequestBody({
    required this.reportType,
    required this.startDate,
    required this.endDate,
    required this.vaccineCodes,
    required this.schoolName,
    required this.statusFilter,
    required this.includeParentName,
    required this.includeParentEmail,
    required this.format,
    this.roomCodes,
    this.tagCodes,
    this.schoolCode,
    this.organizationCode,
    this.generatedBy,
  });

  factory SchoolImmunizationRequestBody.fromParams(
    SchoolImmunizationReportParams params,
    ReportRequestContext context,
  ) {
    return SchoolImmunizationRequestBody(
      reportType: 'IMMUNIZATION',
      startDate: ReportRequestPayload.ymd(params.startDate),
      endDate: ReportRequestPayload.ymd(params.endDate),
      vaccineCodes: params.vaccineCodes,
      schoolName: ReportRequestPayload.resolveSchoolName(
        params.schoolName,
        context.schoolName,
      ),
      statusFilter: params.statusFilters,
      includeParentName: params.includeParentName,
      includeParentEmail: params.includeParentEmail,
      format: params.format,
      roomCodes: ReportRequestPayload.emptyToNull(params.classroomCodes),
      tagCodes: ReportRequestPayload.emptyToNull(params.tagCodes),
      schoolCode: context.schoolCode,
      organizationCode: context.organizationCode,
      generatedBy: context.generatedBy,
    );
  }

  final String reportType;
  final String startDate;
  final String endDate;
  final List<String> vaccineCodes;
  final String schoolName;
  final List<String> statusFilter;
  final bool includeParentName;
  final bool includeParentEmail;
  final String format;
  final List<String>? roomCodes;
  final List<String>? tagCodes;
  final String? schoolCode;
  final String? organizationCode;
  final String? generatedBy;

  @override
  Map<String, dynamic> toJson() => _$SchoolImmunizationRequestBodyToJson(this);
}
