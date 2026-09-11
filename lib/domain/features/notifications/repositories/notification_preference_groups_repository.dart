import 'package:wowcare/data/features/notifications/models/notification_preference_group_model.dart';
import 'package:wowcare/domain/features/notifications/entities/notification_preference_group.dart';

abstract class NotificationPreferenceGroupsRepository {
  Future<List<NotificationPreferenceGroup>> getGroups({required String userCode});

  Future<void> updateGroups({
    required String userCode,
    required UpdateNotificationPreferenceGroupsRequest request,
  });
}
