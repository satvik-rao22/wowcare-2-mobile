import 'package:wowcare/domain/features/notifications/entities/notification_preference_group.dart';
import 'package:wowcare/domain/features/notifications/repositories/notification_preference_groups_repository.dart';

/// Reads the user's grouped notification preferences
/// (`GET /api/v1/notification/preferences/groups`).
class GetNotificationPreferenceGroupsUseCase {
  GetNotificationPreferenceGroupsUseCase(this._repository);

  final NotificationPreferenceGroupsRepository _repository;

  Future<List<NotificationPreferenceGroup>> call({required String userCode}) {
    return _repository.getGroups(userCode: userCode);
  }
}
