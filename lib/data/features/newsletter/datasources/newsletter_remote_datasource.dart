import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/utils/api_constants.dart';
import 'package:wowcare/core/utils/api_paths.dart';
import 'package:wowcare/data/features/newsletter/models/newsletter_api_envelope.dart';
import 'package:wowcare/data/features/newsletter/models/newsletter_models.dart';

abstract class NewsletterRemoteDataSource {
  Future<NewsletterPageModel> getNewslettersBySchool({
    required String schoolCode,
    String? status,
    List<String>? classroomCodes,
    String? search,
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

  String _buildListEndpoint({
    required String endpoint,
    required int page,
    required int size,
    required String status,
    required String search,
    required List<String> classroomCodes,
    required List<String> sortFields,
  }) {
    final List<String> pairs = <String>[
      'page=${Uri.encodeQueryComponent(page.toString())}',
      'size=${Uri.encodeQueryComponent(size.toString())}',
    ];
    if (status.isNotEmpty) {
      pairs.add('status=${Uri.encodeQueryComponent(status)}');
    }
    if (search.isNotEmpty) {
      pairs.add('search=${Uri.encodeQueryComponent(search)}');
    }
    for (final String code in classroomCodes) {
      pairs.add('classroomCode=${Uri.encodeQueryComponent(code)}');
    }
    for (final String sortField in sortFields) {
      pairs.add('sort=${Uri.encodeQueryComponent(sortField)}');
    }
    return '$endpoint?${pairs.join('&')}';
  }

  @override
  Future<NewsletterPageModel> getNewslettersBySchool({
    required String schoolCode,
    String? status,
    List<String>? classroomCodes,
    String? search,
    int page = 0,
    int size = 20,
    List<String>? sort,
  }) async {
    final sortFields = sort?.where((String s) => s.trim().isNotEmpty).toList() ??
        const <String>['sentAt,desc'];

    final normalizedStatus = (status ?? '').trim().toUpperCase();
    final normalizedSearch = (search ?? '').trim();
    final normalizedClassroomCodes = (classroomCodes ?? const <String>[])
        .map((String c) => c.trim())
        .where((String c) => c.isNotEmpty)
        .toSet()
        .toList();

    final path = ApiPaths.newslettersBySchool(schoolCode);
    final endpoint = ApiPaths.urlWithBase(
      path,
      ApiConstants.communicationBaseUrl,
    );
    final requestUrl = _buildListEndpoint(
      endpoint: endpoint,
      page: page,
      size: size,
      status: normalizedStatus,
      search: normalizedSearch,
      classroomCodes: normalizedClassroomCodes,
      sortFields: sortFields,
    );

    final response = await _apiClient.client.get(requestUrl);

    final envelope = NewsletterApiEnvelope.tryFrom(response.data);
    if (envelope == null) {
      throw Exception('Invalid newsletters response');
    }
    if (!envelope.success) {
      throw Exception(envelope.message ?? 'Failed to load newsletters');
    }

    return NewsletterPageModel.fromApiResponse(envelope);
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

    final envelope = NewsletterApiEnvelope.tryFrom(response.data);
    if (envelope == null) {
      throw Exception('Invalid newsletter response');
    }
    if (!envelope.success) {
      throw Exception(envelope.message ?? 'Failed to load newsletter');
    }

    final data = envelope.dataAsMap;
    if (data == null) {
      throw Exception('Newsletter data is missing');
    }

    return NewsletterModel.fromJson(data);
  }
}
