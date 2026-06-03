import '../../../../core/network/api_client.dart';
import '../../../../core/util/api_paths.dart';
import '../models/fcm_register_request_model.dart';

abstract class FcmRegistrationRemoteDataSource {
  Future<void> register(FcmRegisterRequestModel request);
  Future<void> unregisterToken(String fcmToken);
}

class FcmRegistrationRemoteDataSourceImpl
    implements FcmRegistrationRemoteDataSource {
  FcmRegistrationRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<void> register(FcmRegisterRequestModel request) async {
    final endpoint = ApiPaths.url(ApiPaths.notificationFcmRegister);
    final response = await _apiClient.client.post(
      endpoint,
      data: request.toJson(),
    );
    _ensureSuccess(response.data);
  }

  @override
  Future<void> unregisterToken(String fcmToken) async {
    if (fcmToken.trim().isEmpty) return;
    final endpoint = ApiPaths.url(ApiPaths.notificationFcmToken(fcmToken));
    final response = await _apiClient.client.delete(endpoint);
    _ensureSuccess(response.data);
  }

  void _ensureSuccess(dynamic data) {
    if (data is Map && data['success'] == false) {
      throw Exception(data['message']?.toString() ?? 'FCM request failed');
    }
  }
}
