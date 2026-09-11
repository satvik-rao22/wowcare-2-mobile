import 'package:equatable/equatable.dart';

/// Pure-domain representation of a student's guardian/parent.
class StudentGuardian extends Equatable {
  const StudentGuardian({
    required this.guardianCode,
    required this.userCode,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    required this.email,
    required this.relationToStudent,
    required this.primaryContact,
    required this.legalCustody,
    this.clockPin,
    this.profilePhotoUrl,
    this.profilePhotoAssetCode,
    this.displayNameOverride,
  });

  final String guardianCode;
  final String userCode;
  final String firstName;
  final String lastName;
  final String mobile;
  final String email;
  final String? clockPin;
  final String relationToStudent;
  final bool primaryContact;
  final bool legalCustody;

  /// Direct profile-photo URL, if available.
  final String? profilePhotoUrl;

  /// Document-MS asset code for the profile photo (resolved to a URL by the
  /// image widget when no direct URL is present).
  final String? profilePhotoAssetCode;

  /// Fallback display name for a malformed guardian record whose
  /// [firstName]/[lastName] are both empty — see
  /// `StudentGuardianModel.displayNameOverride` (data layer) for how it's
  /// resolved. Never overrides a genuine firstName+lastName.
  final String? displayNameOverride;

  String get fullName {
    final structured = '$firstName $lastName'.trim();
    if (structured.isNotEmpty) return structured;
    return displayNameOverride ?? '';
  }

  @override
  List<Object?> get props => [
        guardianCode,
        userCode,
        firstName,
        lastName,
        mobile,
        email,
        clockPin,
        relationToStudent,
        primaryContact,
        legalCustody,
        profilePhotoUrl,
        profilePhotoAssetCode,
        displayNameOverride,
      ];
}
