import 'package:wowcare/data/features/notifications/models/notification_preference_model.dart';
import 'package:wowcare/domain/features/notifications/entities/notification_preference.dart';

abstract class NotificationPreferencesRepository {
  Future<List<NotificationPreference>> getPreferences({
    required String userCode,
    required String schoolCode,
    required String role,
    String? organizationCode,
  });

  Future<void> updatePreferences({
    required String userCode,
    required UpdateNotificationPreferencesRequest request,
  });
}
