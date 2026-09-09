import '../../../../domain/features/student/entities/school_guardian_summary.dart';

/// Maps a raw guardian JSON map (from the guardians-by-school endpoint) into the
/// pure-domain [SchoolGuardianSummary]. Coerces each key to a trimmed String
/// (missing keys default to ''). Keeps JSON parsing out of the domain layer.
SchoolGuardianSummary schoolGuardianSummaryFromMap(Map<String, dynamic> m) {
  return SchoolGuardianSummary(
    code: (m['code'] ?? '').toString().trim(),
    firstName: (m['firstName'] ?? '').toString().trim(),
    lastName: (m['lastName'] ?? '').toString().trim(),
    email: (m['email'] ?? '').toString().trim(),
    mobile: (m['mobile'] ?? '').toString().trim(),
  );
}
