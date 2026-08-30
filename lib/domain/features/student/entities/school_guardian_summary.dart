import 'package:equatable/equatable.dart';

/// Pure-domain summary of a guardian/parent within a school.
///
/// Used by UI flows (e.g. the add-pickup "select from existing" dropdown) that
/// need full guardian details. JSON parsing lives in the data layer; the
/// repository maps raw Maps to this typed model at the domain boundary via
/// [SchoolGuardianSummary.fromMap].
class SchoolGuardianSummary extends Equatable {
  const SchoolGuardianSummary({
    required this.code,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobile,
  });

  final String code;
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;

  String get fullName => '$firstName $lastName'.trim();

  /// Extracts fields exactly as the current consumer does: coerces each key to
  /// a String (defaulting missing keys to '') and trims.
  factory SchoolGuardianSummary.fromMap(Map<String, dynamic> m) {
    return SchoolGuardianSummary(
      code: (m['code'] ?? '').toString().trim(),
      firstName: (m['firstName'] ?? '').toString().trim(),
      lastName: (m['lastName'] ?? '').toString().trim(),
      email: (m['email'] ?? '').toString().trim(),
      mobile: (m['mobile'] ?? '').toString().trim(),
    );
  }

  @override
  List<Object?> get props => [code, firstName, lastName, email, mobile];
}
