import '../../../../domain/features/notifications/repositories/fcm_registration_repository.dart';
import '../services/fcm_token_registration_service.dart';

class FcmRegistrationRepositoryImpl implements FcmRegistrationRepository {
  FcmRegistrationRepositoryImpl(this._service);

  final FcmTokenRegistrationService _service;

  @override
  Future<void> registerDeviceToken(String fcmToken) =>
      _service.registerToken(fcmToken);

  @override
  Future<void> unregisterDeviceToken(String fcmToken) =>
      _service.unregisterToken(fcmToken);
}
