import 'package:equatable/equatable.dart';

/// Pure-domain projection of `GET /api/v1/guardian/profile` — the fields the
/// guardian-code resolver needs (the guardian record code + name + photo).
/// JSON/alias parsing lives in the data layer (see
/// `data/features/student/mappers/guardian_profile_mapper.dart`).
class GuardianProfile extends Equatable {
  const GuardianProfile({
    this.code = '',
    this.firstName = '',
    this.lastName = '',
    this.photoAssetCode = '',
    this.photoUrl = '',
  });

  /// The guardian RECORD code (`data.code`), not the auth `userCode`.
  final String code;
  final String firstName;
  final String lastName;
  final String photoAssetCode;
  final String photoUrl;

  @override
  List<Object?> get props => [
        code,
        firstName,
        lastName,
        photoAssetCode,
        photoUrl,
      ];
}
