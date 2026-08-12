import 'package:wowcare/data/features/notifications/datasources/notification_preference_groups_remote_data_source.dart';
import 'package:wowcare/data/features/notifications/models/notification_preference_group_model.dart';
import 'package:wowcare/domain/features/notifications/entities/notification_preference_group.dart';
import 'package:wowcare/domain/features/notifications/repositories/notification_preference_groups_repository.dart';

class NotificationPreferenceGroupsRepositoryImpl
    implements NotificationPreferenceGroupsRepository {
  NotificationPreferenceGroupsRepositoryImpl(this._dataSource);

  final NotificationPreferenceGroupsRemoteDataSource _dataSource;

  @override
  Future<List<NotificationPreferenceGroup>> getGroups({
    required String userCode,
  }) async {
    final models = await _dataSource.getGroups(userCode: userCode);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> updateGroups({
    required String userCode,
    required UpdateNotificationPreferenceGroupsRequest request,
  }) {
    return _dataSource.updateGroups(userCode: userCode, request: request);
  }
}
