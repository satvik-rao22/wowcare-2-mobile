import 'package:wowcare/data/features/reports/models/annual_state_immunization_request_body.dart';
import 'package:wowcare/data/features/reports/models/generic_report_request_body.dart';
import 'package:wowcare/data/features/reports/models/report_request_context.dart';
import 'package:wowcare/data/features/reports/models/school_immunization_request_body.dart';
import 'package:wowcare/data/features/reports/models/staff_details_request_body.dart';
import 'package:wowcare/data/features/reports/models/staff_scheduling_request_body.dart';
import 'package:wowcare/data/features/reports/models/students_and_family_request_body.dart';
import 'package:wowcare/domain/features/reports/usecases/annual_state_immunization_report_params.dart';
import 'package:wowcare/domain/features/reports/usecases/report_params.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';
import 'package:wowcare/domain/features/reports/usecases/school_immunization_report_params.dart';
import 'package:wowcare/domain/features/reports/usecases/staff_details_report_params.dart';
import 'package:wowcare/domain/features/reports/usecases/staff_scheduling_report_params.dart';
import 'package:wowcare/domain/features/reports/usecases/students_and_family_report_params.dart';

/// The wire body of `POST .../reports/generate`.
///
/// Six report families send six genuinely different shapes, so each has its
/// own generated model rather than one union model where most keys are null.
/// [ReportRequestPayload.fromParams] is the single place that decides which,
/// which is why the domain params classes no longer carry a `toRequestBody()`
/// of their own (§8: a view hands typed values inward; `toJson()` happens
/// once, at the edge).
abstract class ReportRequestPayload {
  const ReportRequestPayload();

  /// Build the payload for [params], stamped with [context].
  factory ReportRequestPayload.fromParams(
    ReportParams params, {
    ReportRequestContext context = const ReportRequestContext.none(),
  }) {
    return switch (params) {
      ReportRequestParams() => GenericReportRequestBody.fromParams(
        params,
        context,
      ),
      AnnualStateImmunizationReportParams() =>
        AnnualStateImmunizationRequestBody.fromParams(params, context),
      StudentsAndFamilyReportParams() =>
        StudentsAndFamilyRequestBody.fromParams(params, context),
      StaffDetailsReportParams() => StaffDetailsRequestBody.fromParams(
        params,
        context,
      ),
      StaffSchedulingReportParams() => StaffSchedulingRequestBody.fromParams(
        params,
        context,
      ),
      SchoolImmunizationReportParams() =>
        SchoolImmunizationRequestBody.fromParams(params, context),
      _ => throw ArgumentError(
        'No request body is defined for ${params.runtimeType}',
      ),
    };
  }

  Map<String, dynamic> toJson();

  /// `yyyy-MM-dd`, the format every date-only key on this API uses.
  static String ymd(DateTime date) => date.toIso8601String().split('T')[0];

  /// Full UTC ISO-8601, used by the billing keys (`dateFrom`/`asOfDate`).
  static String isoUtc(DateTime date) => date.toUtc().toIso8601String();

  /// The resolved school name wins, but only when it is non-empty — an
  /// unresolved lookup must leave the form's own value in place.
  static String resolveSchoolName(String? fromParams, String? fromContext) {
    if (fromContext != null && fromContext.isNotEmpty) return fromContext;
    return fromParams ?? '';
  }

  /// `null` for a string that is absent or only whitespace, so
  /// `includeIfNull: false` drops the key entirely.
  static String? blankToNull(String? value) =>
      (value == null || value.trim().isEmpty) ? null : value;

  /// `null` for a list that is absent or empty, for the keys the API omits
  /// rather than sending `[]`.
  static List<String>? emptyToNull(List<String>? value) =>
      (value == null || value.isEmpty) ? null : value;
}
