import 'package:wowcare/data/features/notifications/models/notification_preference_model.dart';
import 'package:wowcare/domain/features/notifications/repositories/notification_preferences_repository.dart';

/// Saves the user's notification preferences
/// (`PATCH /api/v1/notification/preferences`).
class UpdateNotificationPreferencesUseCase {
  UpdateNotificationPreferencesUseCase(this._repository);

  final NotificationPreferencesRepository _repository;

  Future<void> call({
    required String userCode,
    required UpdateNotificationPreferencesRequest request,
  }) {
    return _repository.updatePreferences(userCode: userCode, request: request);
  }
}
