import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/utils/api_paths.dart';

import 'package:wowcare/data/features/newsletter/models/newsletter_api_envelope.dart';
import '../models/paginated_newsletters_response_model.dart';

abstract class StudentNewslettersRemoteDataSource {
  Future<PaginatedNewslettersResponseModel> getStudentNewsletters({
    required String studentCode,
    required int page,
    required int size,
    String status = 'SENT',
  });
}

class StudentNewslettersRemoteDataSourceImpl
    implements StudentNewslettersRemoteDataSource {
  StudentNewslettersRemoteDataSourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<PaginatedNewslettersResponseModel> getStudentNewsletters({
    required String studentCode,
    required int page,
    required int size,
    String status = 'SENT',
  }) async {
    final code = studentCode.trim();
    final endpoint = ApiPaths.url(
      ApiPaths.studentNewslettersByStudentCode(code),
    );

    final response = await apiClient.client.get(
      endpoint,
      queryParameters: {'status': status, 'page': page, 'size': size},
    );

    final envelope = NewsletterApiEnvelope.tryFrom(response.data);
    if (envelope != null && envelope.success) {
      return PaginatedNewslettersResponseModel.fromApiResponse(envelope);
    }
    throw Exception(envelope?.message ?? 'Failed to load newsletters');
  }
}
