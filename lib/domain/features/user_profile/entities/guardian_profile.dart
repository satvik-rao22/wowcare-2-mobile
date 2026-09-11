import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile.dart'
    show StaffProfileAddress;

/// The logged-in guardian/parent's own profile, from
/// `GET /api/v1/guardian/profile`. Reuses [StaffProfileAddress] for its
/// address shape — same street/line2/city/state/zipCode/country fields, and
/// callers already need a [StaffProfileAddress] to render the shared
/// edit-profile form.
class GuardianProfile extends Equatable {
  const GuardianProfile({
    required this.code,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    this.photoAssetCode = '',
    this.photoUrl = '',
  });

  final String code;
  final String firstName;
  final String lastName;

  /// The API's own `fullName`, or `"$firstName $lastName"` when that's
  /// blank — never empty when either name part is present.
  final String fullName;
  final String email;
  final String phoneNumber;
  final StaffProfileAddress address;
  final String photoAssetCode;
  final String photoUrl;

  @override
  List<Object?> get props => [
    code,
    firstName,
    lastName,
    fullName,
    email,
    phoneNumber,
    address,
    photoAssetCode,
    photoUrl,
  ];
}
