import 'package:json_annotation/json_annotation.dart';
import 'package:wowcare/data/features/reports/models/report_request_context.dart';
import 'package:wowcare/data/features/reports/models/report_request_payload.dart';
import 'package:wowcare/domain/features/reports/usecases/annual_state_immunization_report_params.dart';

part 'annual_state_immunization_request_body.g.dart';

/// Request body for the Annual State Immunization report, which is routed to
/// the student management microservice and needs only a date range and format.
@JsonSerializable(includeIfNull: false, createFactory: false)
class AnnualStateImmunizationRequestBody extends ReportRequestPayload {
  const AnnualStateImmunizationRequestBody({
    required this.reportType,
    required this.startDate,
    required this.endDate,
    required this.format,
    required this.schoolName,
    this.schoolCode,
    this.organizationCode,
    this.generatedBy,
  });

  factory AnnualStateImmunizationRequestBody.fromParams(
    AnnualStateImmunizationReportParams params,
    ReportRequestContext context,
  ) {
    return AnnualStateImmunizationRequestBody(
      reportType: params.reportType.backendValue,
      startDate: ReportRequestPayload.ymd(params.startDate),
      endDate: ReportRequestPayload.ymd(params.endDate),
      format: params.format,
      schoolName: ReportRequestPayload.resolveSchoolName(
        params.schoolName,
        context.schoolName,
      ),
      schoolCode: context.schoolCode,
      organizationCode: context.organizationCode,
      generatedBy: context.generatedBy,
    );
  }

  final String reportType;
  final String startDate;
  final String endDate;
  final String format;
  final String schoolName;
  final String? schoolCode;
  final String? organizationCode;
  final String? generatedBy;

  @override
  Map<String, dynamic> toJson() =>
      _$AnnualStateImmunizationRequestBodyToJson(this);
}
