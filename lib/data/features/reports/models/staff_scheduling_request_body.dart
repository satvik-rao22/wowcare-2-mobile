import 'package:json_annotation/json_annotation.dart';
import 'package:wowcare/data/features/reports/models/report_request_context.dart';
import 'package:wowcare/data/features/reports/models/report_request_payload.dart';
import 'package:wowcare/domain/features/reports/usecases/staff_scheduling_report_params.dart';

part 'staff_scheduling_request_body.g.dart';

/// Request body for the Staff Scheduling report.
///
/// Note the key is `classroomCodes`, not `roomCodes` — this endpoint differs
/// from the staff *attendance* endpoints.
@JsonSerializable(includeIfNull: false, createFactory: false)
class StaffSchedulingRequestBody extends ReportRequestPayload {
  const StaffSchedulingRequestBody({
    required this.reportType,
    required this.startDate,
    required this.endDate,
    required this.format,
    required this.schoolName,
    this.classroomCodes,
    this.schoolCode,
    this.organizationCode,
    this.generatedBy,
  });

  factory StaffSchedulingRequestBody.fromParams(
    StaffSchedulingReportParams params,
    ReportRequestContext context,
  ) {
    return StaffSchedulingRequestBody(
      reportType: params.reportType.backendValue,
      startDate: ReportRequestPayload.ymd(params.startDate),
      endDate: ReportRequestPayload.ymd(params.endDate),
      classroomCodes: ReportRequestPayload.emptyToNull(params.classroomCodes),
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
  final List<String>? classroomCodes;
  final String format;
  final String schoolName;
  final String? schoolCode;
  final String? organizationCode;
  final String? generatedBy;

  @override
  Map<String, dynamic> toJson() => _$StaffSchedulingRequestBodyToJson(this);
}
