import '../entities/guardian_profile.dart';
import '../entities/guardian_profile_update.dart';

abstract class UserProfileRepository {
  /// `GET /api/v1/guardian/profile` for the logged-in guardian.
  Future<GuardianProfile> getGuardianProfile({
    required String schoolCode,
    required String userCode,
  });

  /// `PATCH /api/v1/guardian/my-profile`. Returns the backend's response
  /// message.
  Future<String> updateGuardianProfile(GuardianProfileUpdate update);
}
