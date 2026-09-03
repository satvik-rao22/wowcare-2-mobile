import 'package:wowcare/domain/features/notifications/entities/notification_preference_group.dart';
import 'package:wowcare/redesign/features/profile/models/models.dart';

/// Where M13 gets its data. Fixtures during the UI phase; in the last phase
/// one implementation wraps `StaffRepository.getStaffProfile` /
/// `StudentRemoteDataSource.getGuardianProfile`, the my-profile PATCH, the
/// profile-photo upload session, `GetNotificationPreferenceGroupsUseCase` /
/// `UpdateNotificationPreferenceGroupsUseCase`, and the change-password call.
///
/// Every method takes the signed-in [SessionUser.id] rather than reading
/// storage, so the cubits stay free of the locator.
abstract interface class ProfileSource {
  /// The person's own record. Throws when neither network nor cache has it.
  Future<ProfileSnapshot> fetchProfile(String userId);

  /// Persists the validated form and returns the record as saved.
  Future<ProfileRecord> saveProfile(String userId, ProfileFormData form);

  /// Uploads a new photo, reporting progress 0 to 1 and completing when the
  /// server has finalized it. Errors surface as stream errors.
  Stream<double> uploadPhoto(String userId);

  Future<void> removePhoto(String userId);

  /// `GET /api/v1/notification/preferences/groups`, sorted by display order.
  Future<List<NotificationPreferenceGroup>> fetchPreferences(String userId);

  /// PATCHes one group's full channel map back.
  Future<void> updatePreference(
    String userId,
    NotificationPreferenceGroup group,
  );

  Future<void> changePassword({
    required String userId,
    required String current,
    required String next,
  });

  Future<AppBuildInfo> buildInfo();
}
