import '../../../../domain/features/student/entities/guardian_profile.dart';

/// Maps the raw `GET /api/v1/guardian/profile` JSON map into the pure-domain
/// [GuardianProfile], tolerating the backend's key aliases (camelCase / PascalCase
/// / snake_case). Keeps this lenient JSON parsing out of the domain + core layers.
GuardianProfile guardianProfileFromMap(Map<String, dynamic> data) {
  String pick(List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v != null) {
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return '';
  }

  return GuardianProfile(
    code: pick(const [
      'code',
      'guardianCode',
      'GuardianCode',
      'parentCode',
      'ParentCode',
    ]),
    firstName: pick(const ['firstName', 'FirstName', 'first_name']),
    lastName: pick(const ['lastName', 'LastName', 'last_name']),
    photoAssetCode: pick(const [
      'profilePhotoAssetCode',
      'photoAssetCode',
      'profileImageAssetCode',
    ]),
    photoUrl: pick(const [
      'profilePhotoUrl',
      'photoUrl',
      'profileImageUrl',
      'imageUrl',
    ]),
  );
}
