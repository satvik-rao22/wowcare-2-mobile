import 'package:dio/dio.dart';
import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../models/staff_models.dart';
import '../models/staff_document_models.dart';
import '../models/staff_important_dates_models.dart';
import '../models/school_user_models.dart';

abstract class StaffRemoteDataSource {
  Future<StaffPageModel> getStaffPage({
    required String schoolCode,
    int page = 0,
    int size = 10,
    String? status,
    String? designation,
    String? search,
  });

  Future<StaffDocumentResponseModel> addStaffDocument({
    required String staffCode,
    required StaffDocumentRequestModel request,
  });

  Future<StaffDocumentsPageModel> getStaffDocuments({
    required String staffCode,
    int page = 0,
    int size = 10,
    bool? expired,
  });

  Future<StaffProfileModel> getStaffProfile({
    required String staffCode,
  });

  Future<ImportantDatesResponseModel> updateImportantDates({
    required String staffCode,
    required List<ImportantDateRequestModel> dates,
  });

  /// Creates an Admin user (school admin) via `/api/v1/school-users`.
  Future<CreateSchoolUserResponseModel> createSchoolAdminUser({
    required CreateSchoolUserRequestModel request,
  });

  /// Creates a Staff user via `/api/v1/school-users/staff`.
  Future<CreateSchoolUserResponseModel> createStaffUser({
    required CreateStaffUserRequestModel request,
  });
}

class StaffRemoteDataSourceImpl implements StaffRemoteDataSource {
  StaffRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<StaffPageModel> getStaffPage({
    required String schoolCode,
    int page = 0,
    int size = 10,
    String? status,
    String? designation,
    String? search,
  }) async {
    final queryParameters = <String, dynamic>{
      'schoolCode': schoolCode,
      'page': page,
      'size': size,
      'sort': 'asc',
    };

    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (designation != null && designation.isNotEmpty) {
      queryParameters['designation'] = designation;
    }
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffList,
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff API response format');
    }

    return StaffPageModel.fromJson(response.data! as Map<String, dynamic>);
  }

  @override
  Future<StaffDocumentResponseModel> addStaffDocument({
    required String staffCode,
    required StaffDocumentRequestModel request,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.staffDocumentAdd}/$staffCode/documents',
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.post<dynamic>(
      endpoint,
      data: request.toJson(),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff document API response format');
    }

    return StaffDocumentResponseModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StaffDocumentsPageModel> getStaffDocuments({
    required String staffCode,
    int page = 0,
    int size = 10,
    bool? expired,
  }) async {
    final queryParameters = <String, dynamic>{
      'staffCode': staffCode,
      'page': page,
      'size': size,
    };

    if (expired != null) {
      queryParameters['expired'] = expired;
    }

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffDocuments,
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff documents API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    final dataPayload = data['data'] as Map<String, dynamic>?;
    if (dataPayload == null) {
      throw Exception('Missing data field in staff documents response');
    }

    return StaffDocumentsPageModel.fromJson(dataPayload);
  }

  @override
  Future<StaffProfileModel> getStaffProfile({
    required String staffCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.staffProfile}/$staffCode/profile',
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.get<dynamic>(endpoint);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff profile API response format');
    }

    return StaffProfileModel.fromJson(response.data! as Map<String, dynamic>);
  }

  @override
  Future<ImportantDatesResponseModel> updateImportantDates({
    required String staffCode,
    required List<ImportantDateRequestModel> dates,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.staffDates}/$staffCode',
      ApiConstants.staffBaseUrl,
    );

    final requestBody = dates.map((date) => date.toJson()).toList();

    final response = await _client.patch<dynamic>(
      endpoint,
      data: requestBody,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected important dates API response format');
    }

    return ImportantDatesResponseModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<CreateSchoolUserResponseModel> createSchoolAdminUser({
    required CreateSchoolUserRequestModel request,
  }) async {
    final endpoint = ApiPaths.url(ApiPaths.schoolUsers);

    final response = await _client.post<dynamic>(
      endpoint,
      data: request.toJson(),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected create school admin user API response format');
    }

    return CreateSchoolUserResponseModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<CreateSchoolUserResponseModel> createStaffUser({
    required CreateStaffUserRequestModel request,
  }) async {
    final endpoint = ApiPaths.url(ApiPaths.schoolUsersStaff);

    final response = await _client.post<dynamic>(
      endpoint,
      data: request.toJson(),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected create staff user API response format');
    }

    return CreateSchoolUserResponseModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }
}


