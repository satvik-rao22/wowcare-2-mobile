import 'package:wowcare/data/features/notifications/models/notification_preference_group_model.dart';
import 'package:wowcare/domain/features/notifications/repositories/notification_preference_groups_repository.dart';

/// Saves the user's grouped notification preferences
/// (`PATCH /api/v1/notification/preferences/groups`).
class UpdateNotificationPreferenceGroupsUseCase {
  UpdateNotificationPreferenceGroupsUseCase(this._repository);

  final NotificationPreferenceGroupsRepository _repository;

  Future<void> call({
    required String userCode,
    required UpdateNotificationPreferenceGroupsRequest request,
  }) {
    return _repository.updateGroups(userCode: userCode, request: request);
  }
}
