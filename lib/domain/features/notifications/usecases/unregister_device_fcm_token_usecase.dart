import '../repositories/fcm_registration_repository.dart';
import '../repositories/push_notification_repository.dart';

/// Removes the device FCM token from the backend on logout.
class UnregisterDeviceFcmTokenUseCase {
  UnregisterDeviceFcmTokenUseCase(this._fcmRegistration, this._pushRepository);

  final FcmRegistrationRepository _fcmRegistration;
  final PushNotificationRepository _pushRepository;

  Future<void> call({String? fcmToken}) async {
    final token = fcmToken ?? await _pushRepository.getToken();
    if (token == null || token.trim().isEmpty) return;
    await _fcmRegistration.unregisterDeviceToken(token);
  }
}
