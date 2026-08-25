import '../repositories/fcm_registration_repository.dart';
import '../repositories/push_notification_repository.dart';

/// Sends the current device FCM token to the notification backend when logged in.
class RegisterDeviceFcmTokenUseCase {
  RegisterDeviceFcmTokenUseCase(this._fcmRegistration, this._pushRepository);

  final FcmRegistrationRepository _fcmRegistration;
  final PushNotificationRepository _pushRepository;

  Future<void> call({String? fcmToken}) async {
    final token = fcmToken ?? await _pushRepository.getToken();
    if (token == null || token.trim().isEmpty) return;
    await _fcmRegistration.registerDeviceToken(token);
  }
}
