/// Backend registration for device FCM tokens (push delivery).
abstract class FcmRegistrationRepository {
  Future<void> registerDeviceToken(String fcmToken);
  Future<void> unregisterDeviceToken(String fcmToken);
}
