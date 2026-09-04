import 'package:equatable/equatable.dart';

/// Pure-domain summary of a guardian/parent within a school.
///
/// Used by UI flows (e.g. the add-pickup "select from existing" dropdown) that
/// need full guardian details. JSON parsing lives in the data layer — see
/// `schoolGuardianSummaryFromMap` in
/// `data/features/student/mappers/school_guardian_summary_mapper.dart`.
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

  @override
  List<Object?> get props => [code, firstName, lastName, email, mobile];
}
