import '../../../../core/network/api_client.dart';
import '../../../../core/util/api_paths.dart';
import '../models/communication_settings_model.dart';

abstract class CommunicationSettingsRemoteDataSource {
  Future<CommunicationSettingsModel> getCommunicationSettings(
    String schoolCode,
  );
}

class CommunicationSettingsRemoteDataSourceImpl
    implements CommunicationSettingsRemoteDataSource {
  CommunicationSettingsRemoteDataSourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<CommunicationSettingsModel> getCommunicationSettings(
    String schoolCode,
  ) async {
    final response = await apiClient.client.get<Map<String, dynamic>>(
      ApiPaths.url(ApiPaths.communicationSettings),
      queryParameters: {'schoolCode': schoolCode},
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return CommunicationSettingsModel.fromJson(data);
  }
}
