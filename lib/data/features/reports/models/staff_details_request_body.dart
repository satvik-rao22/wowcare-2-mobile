import 'package:json_annotation/json_annotation.dart';
import 'package:wowcare/data/features/reports/models/report_request_context.dart';
import 'package:wowcare/data/features/reports/models/report_request_payload.dart';
import 'package:wowcare/domain/features/reports/usecases/staff_details_report_params.dart';

part 'staff_details_request_body.g.dart';

/// Request body for the Staff Details report: one `include*` flag per column
/// the user ticked, plus a status filter. This endpoint takes no date range.
@JsonSerializable(includeIfNull: false, createFactory: false)
class StaffDetailsRequestBody extends ReportRequestPayload {
  const StaffDetailsRequestBody({
    required this.reportType,
    required this.status,
    required this.includeName,
    required this.includeDateOfBirth,
    required this.includeEmailId,
    required this.includePhoneNumber,
    required this.includeAddress,
    required this.includePrimaryClassroom,
    required this.includeClockInOutPin,
    required this.includeHireDate,
    required this.includeDesignation,
    required this.includeCdaExpirationDate,
    required this.includeCprExpirationDate,
    required this.includeLastPhysicalDate,
    required this.includeIsActive,
    required this.format,
    required this.schoolName,
    this.classroomCodes,
    this.schoolCode,
    this.organizationCode,
    this.generatedBy,
  });

  factory StaffDetailsRequestBody.fromParams(
    StaffDetailsReportParams params,
    ReportRequestContext context,
  ) {
    final fields = params.staffFieldsSelected;
    return StaffDetailsRequestBody(
      reportType: 'STAFF_DETAILS',
      status: _backendStatus(params.statusFilter),
      includeName: fields.contains('Name'),
      includeDateOfBirth: fields.contains('Date Of Birth'),
      includeEmailId: fields.contains('Email ID'),
      includePhoneNumber: fields.contains('Phone Number'),
      includeAddress: fields.contains('Address'),
      includePrimaryClassroom: fields.contains('Primary Classroom'),
      includeClockInOutPin: fields.contains('Clock-In-Out Pin'),
      includeHireDate: fields.contains('Hire Date'),
      includeDesignation: fields.contains('Designation'),
      includeCdaExpirationDate: fields.contains('CDA Expiration Date'),
      includeCprExpirationDate: fields.contains('CPR Expiration Date'),
      includeLastPhysicalDate: fields.contains('Last Physical Date'),
      includeIsActive: fields.contains('Is Active'),
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

  /// Maps the UI's status label to the backend value. Anything unrecognised
  /// falls back to `ACTIVE`, which is what the form defaults to.
  static String _backendStatus(String uiStatus) {
    switch (uiStatus) {
      case 'Active Staff':
        return 'ACTIVE';
      case 'Inactive Staff':
        return 'INACTIVE';
      case 'All Staff':
        return 'ALL';
      default:
        return 'ACTIVE';
    }
  }

  final String reportType;
  final String status;
  final bool includeName;
  final bool includeDateOfBirth;
  final bool includeEmailId;
  final bool includePhoneNumber;
  final bool includeAddress;
  final bool includePrimaryClassroom;
  final bool includeClockInOutPin;
  final bool includeHireDate;
  final bool includeDesignation;
  final bool includeCdaExpirationDate;
  final bool includeCprExpirationDate;
  final bool includeLastPhysicalDate;
  final bool includeIsActive;
  final List<String>? classroomCodes;
  final String format;
  final String schoolName;
  final String? schoolCode;
  final String? organizationCode;
  final String? generatedBy;

  @override
  Map<String, dynamic> toJson() => _$StaffDetailsRequestBodyToJson(this);
}
