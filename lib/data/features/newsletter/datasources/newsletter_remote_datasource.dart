import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/data/features/newsletter/models/newsletter_models.dart';

abstract class NewsletterRemoteDataSource {
  Future<NewsletterPageModel> getNewslettersBySchool({
    required String schoolCode,
    String? status,
    int page = 0,
    int size = 20,
    List<String>? sort,
  });

  Future<NewsletterModel> getNewsletterByCode(String code);
}

class NewsletterRemoteDataSourceImpl implements NewsletterRemoteDataSource {
  NewsletterRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<NewsletterPageModel> getNewslettersBySchool({
    required String schoolCode,
    String? status,
    int page = 0,
    int size = 20,
    List<String>? sort,
  }) async {
    final sortFields = sort?.where((String s) => s.trim().isNotEmpty).toList() ??
        const <String>['sentAt,desc'];

    // Backend expects Spring `Pageable` binding: pageable.page, pageable.size, pageable.sort.
    final queryParameters = <String, dynamic>{
      'pageable.page': page,
      'pageable.size': size,
      'pageable.sort': sortFields,
    };

    final normalizedStatus = (status ?? '').trim().toUpperCase();
    if (normalizedStatus.isNotEmpty) {
      queryParameters['status'] = normalizedStatus;
    }

    final path = ApiPaths.newslettersBySchool(schoolCode);
    final endpoint = ApiPaths.urlWithBase(
      path,
      ApiConstants.communicationBaseUrl,
    );

    final response = await _apiClient.client.get(
      endpoint,
      queryParameters: queryParameters,
    );

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Invalid newsletters response');
    }
    if (body['success'] != true) {
      throw Exception(body['message'] as String? ?? 'Failed to load newsletters');
    }

    return NewsletterPageModel.fromJson(body);
  }

  @override
  Future<NewsletterModel> getNewsletterByCode(String code) async {
    final normalizedCode = code.trim();
    if (normalizedCode.isEmpty) {
      throw Exception('Newsletter code is required');
    }

    final path = ApiPaths.newsletterByCode(normalizedCode);
    final endpoint = ApiPaths.urlWithBase(
      path,
      ApiConstants.communicationBaseUrl,
    );

    final response = await _apiClient.client.get(endpoint);

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Invalid newsletter response');
    }
    if (body['success'] != true) {
      throw Exception(body['message'] as String? ?? 'Failed to load newsletter');
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Newsletter data is missing');
    }

    return NewsletterModel.fromJson(data);
  }
}
