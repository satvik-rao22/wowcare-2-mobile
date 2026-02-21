import 'package:dio/dio.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';
import '../models/staff_models.dart';
import '../models/staff_count_models.dart';
import '../models/staff_document_models.dart';
import '../models/staff_important_dates_models.dart';
import '../models/school_user_models.dart';

abstract class StaffRemoteDataSource {
  Future<StaffCountModel> getStaffCount({
    required String organizationCode,
    required String schoolCode,
  });

  Future<StaffPageModel> getStaffPage({
    required String schoolCode,
    String? code,
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

  Future<StaffDocumentResponseModel> updateStaffDocument({
    required String documentUuid,
    required StaffDocumentRequestModel request,
  });

  Future<StaffDocumentResponseModel> deleteStaffDocument({
    required String documentUuid,
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

  /// Updates core staff profile details via `/api/v1/staff/{staffCode}/profile`.
  ///
  /// The [body] should follow the backend contract, e.g.
  /// {
  ///   "firstName": "string",
  ///   "lastName": "string",
  ///   "status": "ACTIVE",
  ///   "phoneNumber": "string",
  ///   "designation": "OWNER",
  ///   "jobTag": "FULL_TIME",
  ///   "birthdate": "2026-02-03T09:48:39.440Z",
  ///   "primaryClassroomCode": "string",
  ///   "allowedClassroomCodes": ["string"]
  /// }
  Future<String> updateStaffProfile({
    required String staffCode,
    required Map<String, dynamic> body,
  });

  /// Updates staff address via `/api/v1/staff-address/{staffCode}`.
  ///
  /// Expected body:
  /// {
  ///   "addressStreet": "string",
  ///   "addressLine2": "string",
  ///   "addressCity": "string",
  ///   "addressState": "string",
  ///   "addressZipCode": "string",
  ///   "addressCountry": "string"
  /// }
  Future<String> updateStaffAddress({
    required String staffCode,
    required Map<String, dynamic> body,
  });

  /// Fetches staff important dates via `GET /api/v1/staff-dates/{staffCode}`.
  ///
  /// Returns a list of [ImportantDateRequestModel]-shaped items:
  /// {
  ///   "importantDateType": "HIRE_DATE",
  ///   "dueDate": "2026-02-06",
  ///   "completedDate": "2026-02-06"
  /// }
  Future<List<ImportantDateRequestModel>> getImportantDates({
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

  /// Deactivates a school user via `/api/v1/school-users/deactivate`.
  Future<String> deactivateSchoolUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  });

  /// Activates a school user via `/api/v1/school-users/activate`.
  Future<String> activateSchoolUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  });

  /// Updates staff work & break schedules via `/api/v1/staff-schedules/{staffCode}`.
  ///
  /// Expected [body] shape:
  /// {
  ///   "workSchedules": [
  ///     {
  ///       "dayOfWeek": "MONDAY",
  ///       "workStartTime": { "hour": 9, "minute": 0, "second": 0, "nano": 0 },
  ///       "workEndTime":   { "hour": 17, "minute": 0, "second": 0, "nano": 0 }
  ///     }
  ///   ],
  ///   "breakSchedules": [
  ///     {
  ///       "dayOfWeek": "MONDAY",
  ///       "breakType": "LUNCH",
  ///       "breakStartTime": { "hour": 12, "minute": 0, "second": 0, "nano": 0 },
  ///       "breakEndTime":   { "hour": 13, "minute": 0, "second": 0, "nano": 0 }
  ///     }
  ///   ]
  /// }
  Future<String> updateStaffSchedules({
    required String staffCode,
    required Map<String, dynamic> body,
  });
}

class StaffRemoteDataSourceImpl implements StaffRemoteDataSource {
  StaffRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<StaffCountModel> getStaffCount({
    required String organizationCode,
    required String schoolCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffCount,
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff count API response format');
    }

    return StaffCountModel.fromJson(response.data! as Map<String, dynamic>);
  }

  @override
  Future<StaffPageModel> getStaffPage({
    required String schoolCode,
    String? code,
    int page = 0,
    int size = 10,
    String? status,
    String? designation,
    String? search,
  }) async {
    final queryParameters = <String, dynamic>{
      'schoolCode': schoolCode,
      // Backward-compatible pagination params (older backend)
      'page': page,
      'size': size,
      'sort': 'desc',
      // Newer backend contract (Swagger shows pageable as required)
      // Send as flattened keys to ensure typical Spring-style binding.
      'pageable.page': page,
      'pageable.size': size,
      // Dio encodes lists as repeated query params.
      'pageable.sort': <String>['desc'],
    };

    if (code != null && code.isNotEmpty) {
      queryParameters['code'] = code;
    }
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
      '${ApiPaths.staffDocumentAdd}/$staffCode',
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
  Future<StaffDocumentResponseModel> updateStaffDocument({
    required String documentUuid,
    required StaffDocumentRequestModel request,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.staffDocumentUpdate}/$documentUuid',
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.patch<dynamic>(
      endpoint,
      data: request.toJson(),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff document update API response format');
    }

    return StaffDocumentResponseModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StaffDocumentResponseModel> deleteStaffDocument({
    required String documentUuid,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.staffDocuments}/$documentUuid',
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.delete<dynamic>(endpoint);

    // DELETE requests might return null data or empty response
    if (response.data == null) {
      // Return a success response if DELETE returns null (common for DELETE endpoints)
      return const StaffDocumentResponseModel(
        success: true,
        message: 'Document deleted successfully',
        data: null,
        timestamp: '',
      );
    }

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff document delete API response format');
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
  Future<String> updateStaffProfile({
    required String staffCode,
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.staffProfile}/$staffCode/profile',
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.patch<dynamic>(
      endpoint,
      data: body,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff profile update API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Profile updated successfully';
  }

  @override
  Future<String> updateStaffAddress({
    required String staffCode,
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.staffAddress}/$staffCode',
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.patch<dynamic>(
      endpoint,
      data: body,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff address update API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Address updated successfully';
  }

  @override
  Future<List<ImportantDateRequestModel>> getImportantDates({
    required String staffCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.staffDates}/$staffCode',
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.get<dynamic>(endpoint);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected important dates API response format');
    }

    final data = (response.data! as Map<String, dynamic>)['data'];
    if (data is! List) {
      // Backend can return null/empty; normalize to empty list.
      return const <ImportantDateRequestModel>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => ImportantDateRequestModel(
            importantDateType: (json['importantDateType'] ?? '').toString(),
            dueDate: (json['dueDate'] ?? '').toString(),
            completedDate: json['completedDate']?.toString(),
            status: json['status']?.toString(),
          ),
        )
        .toList();
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

  @override
  Future<String> deactivateSchoolUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  }) async {
    final endpoint = ApiPaths.url(ApiPaths.schoolUsersDeactivate);

    final response = await _client.post<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'userCode': userCode,
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
        'role': role,
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected deactivate school user API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'User deactivated successfully';
  }

  @override
  Future<String> activateSchoolUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  }) async {
    final endpoint = ApiPaths.url(ApiPaths.schoolUsersActivate);

    final response = await _client.post<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'userCode': userCode,
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
        'role': role,
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected activate school user API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'User activated successfully';
  }

  @override
  Future<String> updateStaffSchedules({
    required String staffCode,
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.staffSchedules}/$staffCode',
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.patch<dynamic>(
      endpoint,
      data: body,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff schedules API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Schedule updated successfully';
  }
}


