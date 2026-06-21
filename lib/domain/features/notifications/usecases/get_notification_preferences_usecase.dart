import 'package:wowcare/domain/features/notifications/entities/notification_preference.dart';
import 'package:wowcare/domain/features/notifications/repositories/notification_preferences_repository.dart';

/// Reads the user's notification preferences
/// (`GET /api/v1/notification/preferences`).
class GetNotificationPreferencesUseCase {
  GetNotificationPreferencesUseCase(this._repository);

  final NotificationPreferencesRepository _repository;

  Future<List<NotificationPreference>> call({
    required String userCode,
    required String schoolCode,
    required String role,
    String? organizationCode,
  }) {
    return _repository.getPreferences(
      userCode: userCode,
      schoolCode: schoolCode,
      role: role,
      organizationCode: organizationCode,
    );
  }
}
