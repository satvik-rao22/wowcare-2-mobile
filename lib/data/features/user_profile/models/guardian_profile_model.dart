/// DTO for `GET /api/v1/guardian/profile`. Handwritten, matching the app's
/// existing convention (no generated models exist anywhere in this repo
/// yet — see the standards doc, Section 8.1).
///
/// This is the SINGLE parser for the guardian-profile response. Before this
/// existed, two cubits each parsed this map inline with subtly different
/// fallback chains (one dropped the `phoneNumber` key entirely, the other
/// never checked `address.line1`) — a real, live bug, not just duplication.
class GuardianProfileModel {
  const GuardianProfileModel({
    required this.code,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.photoAssetCode,
    required this.photoUrl,
  });

  factory GuardianProfileModel.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => (v ?? '').toString().trim();

    return GuardianProfileModel(
      code: str(json['code']),
      firstName: str(json['firstName']),
      lastName: str(json['lastName']),
      fullName: str(json['fullName']),
      email: str(json['email']),
      // The backend has used all three keys for this field at different
      // times — check every one of them.
      phoneNumber: str(json['mobile'] ?? json['phone'] ?? json['phoneNumber']),
      address: GuardianProfileAddressModel.fromJson(json['address']),
      photoAssetCode: str(json['profilePhotoAssetCode']),
      photoUrl: str(json['profilePhotoUrl'] ?? json['photoUrl']),
    );
  }

  final String code;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String phoneNumber;
  final GuardianProfileAddressModel address;
  final String photoAssetCode;
  final String photoUrl;
}

class GuardianProfileAddressModel {
  const GuardianProfileAddressModel({
    this.street = '',
    this.line2 = '',
    this.city = '',
    this.state = '',
    this.zipCode = '',
    this.country = '',
  });

  factory GuardianProfileAddressModel.fromJson(dynamic raw) {
    if (raw is! Map) return const GuardianProfileAddressModel();
    final m = Map<String, dynamic>.from(raw);
    String pick(List<String> keys) {
      for (final k in keys) {
        final v = (m[k] ?? '').toString().trim();
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    return GuardianProfileAddressModel(
      street: pick(['line1', 'street', 'addressStreet']),
      line2: pick(['line2', 'addressLine2']),
      city: pick(['city', 'addressCity']),
      state: pick(['state', 'addressState']),
      zipCode: pick(['postalCode', 'zipCode', 'addressZipCode']),
      country: pick(['country', 'addressCountry']),
    );
  }

  final String street;
  final String line2;
  final String city;
  final String state;
  final String zipCode;
  final String country;
}
