import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/util/api_paths.dart';

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

    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == true) {
      return PaginatedNewslettersResponseModel.fromJson(data);
    }
    throw Exception(
      (data is Map<String, dynamic> ? data['message'] : null) ??
          'Failed to load newsletters',
    );
  }
}
