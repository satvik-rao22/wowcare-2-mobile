import '../../../../core/network/api_client.dart';
import '../../../../core/utils/api_constants.dart';
import '../../../../core/utils/api_paths.dart';
import '../../staff/models/staff_models.dart';
import '../../communication/models/get_conversations_response.dart';

abstract class MessagingRemoteDataSource {
  Future<StaffPageModel> getFilteredStaff({
    required String organizationCode,
    required String schoolCode,
    required int page,
    required int size,
    String? status,
    String? designation,
    String? search,
    List<String>? classCodes,
  });

  Future<GetConversationsResponse> getConversationsByStaffStatus({
    required int page,
    required int size,
    required String staffStatus,
  });
}

class MessagingRemoteDataSourceImpl implements MessagingRemoteDataSource {
  final ApiClient apiClient;

  MessagingRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<StaffPageModel> getFilteredStaff({
    required String organizationCode,
    required String schoolCode,
    required int page,
    required int size,
    String? status,
    String? designation,
    String? search,
    List<String>? classCodes,
  }) async {
    final queryParameters = <String, dynamic>{
      'schoolCode': schoolCode,
      'page': page,
      'size': size,
      'sort': 'firstName,asc',
    };

    if (organizationCode.isNotEmpty) {
      queryParameters['organizationCode'] = organizationCode;
    }

    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status.trim().toUpperCase();
    } else {
      queryParameters['status'] = 'ACTIVE';
    }

    if (designation != null && designation.isNotEmpty) {
      queryParameters['designation'] = designation.trim().toUpperCase();
    }

    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    if (classCodes != null && classCodes.isNotEmpty) {
      queryParameters['classCodes'] = classCodes.map((e) => e.trim()).toList();
    }

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffList,
      ApiConstants.staffBaseUrl,
    );

    final response = await apiClient.client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff API response format');
    }

    return StaffPageModel.fromJson(response.data! as Map<String, dynamic>);
  }

  @override
  Future<GetConversationsResponse> getConversationsByStaffStatus({
    required int page,
    required int size,
    required String staffStatus,
  }) async {
    final path = ApiPaths.messagingConversationsByType('STAFF_DIRECT');
    
    final endpoint = ApiPaths.urlWithBase(
      '$path?status=ACTIVE&page=$page&size=$size&staffStatus=${staffStatus.trim().toUpperCase()}',
      ApiConstants.communicationBaseUrl,
    );

    final response = await apiClient.client.get<dynamic>(endpoint);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected conversations API response format');
    }

    return GetConversationsResponse.fromJson(response.data! as Map<String, dynamic>);
  }
}
