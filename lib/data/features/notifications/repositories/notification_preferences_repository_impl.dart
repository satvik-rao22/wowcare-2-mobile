import 'package:wowcare/data/features/notifications/datasources/notification_preferences_remote_data_source.dart';
import 'package:wowcare/data/features/notifications/models/notification_preference_model.dart';
import 'package:wowcare/domain/features/notifications/entities/notification_preference.dart';
import 'package:wowcare/domain/features/notifications/repositories/notification_preferences_repository.dart';

class NotificationPreferencesRepositoryImpl
    implements NotificationPreferencesRepository {
  NotificationPreferencesRepositoryImpl(this._dataSource);

  final NotificationPreferencesRemoteDataSource _dataSource;

  @override
  Future<List<NotificationPreference>> getPreferences({
    required String userCode,
    required String schoolCode,
    required String role,
    String? organizationCode,
  }) async {
    final models = await _dataSource.getPreferences(
      userCode: userCode,
      schoolCode: schoolCode,
      role: role,
      organizationCode: organizationCode,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> updatePreferences({
    required String userCode,
    required UpdateNotificationPreferencesRequest request,
  }) {
    return _dataSource.updatePreferences(userCode: userCode, request: request);
  }
}
