import '../../../../domain/features/notifications/entities/push_notification.dart';
import '../../../../domain/features/notifications/repositories/push_notification_repository.dart';
import '../datasources/fcm_remote_data_source.dart';

class PushNotificationRepositoryImpl implements PushNotificationRepository {
  PushNotificationRepositoryImpl(this._remote);

  final FcmRemoteDataSource _remote;

  @override
  Future<void> requestPermission() => _remote.requestPermission();

  @override
  Future<String?> getToken() => _remote.getToken();

  @override
  Stream<String> get onTokenRefresh => _remote.onTokenRefresh;

  @override
  Stream<PushNotification> get onMessage => _remote.onMessage;

  @override
  Stream<PushNotification> get onNotificationTap => _remote.onNotificationTap;

  @override
  Future<PushNotification?> getInitialMessage() => _remote.getInitialMessage();
}
