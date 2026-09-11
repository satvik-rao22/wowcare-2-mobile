import 'package:equatable/equatable.dart';

/// The school/user identity the repository stamps onto every report request.
///
/// These four values come from storage rather than from the form, so they are
/// passed alongside the domain params instead of being written into a payload
/// map after the fact (§8: a request body is built once, from typed values).
class ReportRequestContext extends Equatable {
  const ReportRequestContext({
    this.schoolCode,
    this.organizationCode,
    this.generatedBy,
    this.schoolName,
    this.schoolTimeZone,
  });

  /// No identity — used by tests and by any caller that only wants the
  /// form-derived half of the payload.
  const ReportRequestContext.none()
    : schoolCode = null,
      organizationCode = null,
      generatedBy = null,
      schoolName = null,
      schoolTimeZone = null;

  final String? schoolCode;
  final String? organizationCode;
  final String? generatedBy;

  /// The school's IANA zone (e.g. `America/New_York`), which the scheduling
  /// report needs to place a shift on the right calendar day — a `startDate`
  /// and `endDate` alone are ambiguous without it.
  final String? schoolTimeZone;

  /// The resolved, human-readable school name. Overrides whatever the form
  /// supplied, but only when non-empty — an unresolved name must not blank
  /// out the one the form already had.
  final String? schoolName;

  @override
  List<Object?> get props => [
    schoolCode,
    organizationCode,
    generatedBy,
    schoolName,
    schoolTimeZone,
  ];
}
