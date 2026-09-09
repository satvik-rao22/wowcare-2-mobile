import 'package:equatable/equatable.dart';

/// Request body for `PATCH /api/v1/guardian/my-profile`. Email is
/// deliberately not a field here — that PATCH's own contract has no email
/// field; email changes go through [ChangeUserEmailUseCase] instead.
class GuardianProfileUpdate extends Equatable {
  const GuardianProfileUpdate({
    required this.guardianCode,
    required this.firstName,
    required this.lastName,
    required this.phoneDigits,
    this.addressStreet = '',
    this.addressLine2 = '',
    this.addressCity = '',
    this.addressState = '',
    this.addressZipCode = '',
    this.addressCountry = '',
  });

  final String guardianCode;
  final String firstName;
  final String lastName;

  /// Digits-only phone number — the guardian API's `mobile` field.
  final String phoneDigits;
  final String addressStreet;
  final String addressLine2;
  final String addressCity;
  final String addressState;
  final String addressZipCode;
  final String addressCountry;

  /// The address block is only included in the PATCH body when the
  /// guardian actually supplied at least one address field.
  bool get hasAddress => [
    addressStreet,
    addressLine2,
    addressCity,
    addressState,
    addressZipCode,
  ].any((s) => s.trim().isNotEmpty);

  @override
  List<Object?> get props => [
    guardianCode,
    firstName,
    lastName,
    phoneDigits,
    addressStreet,
    addressLine2,
    addressCity,
    addressState,
    addressZipCode,
    addressCountry,
  ];
}
