import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:wowcare/core/auth/token_refresh_service.dart';
import 'package:wowcare/core/network/api_headers.dart';
import 'package:wowcare/core/network/api_logger.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/network/api_response.dart';
import 'package:wowcare/data/features/auth/models/login_request_model.dart';
import 'package:wowcare/data/features/auth/models/login_response_model.dart';
import 'package:wowcare/data/features/auth/models/logout_request_model.dart';
import 'package:wowcare/data/features/auth/models/school_names_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseModel> login(LoginRequestModel request);
  Future<void> logout(LogoutRequestModel request);
  Future<Map<String, dynamic>> getLoginContext({required String accessToken});
  Future<void> patchLoginContext({
    required String accessToken,
    required String? lastLoginOrganizationCode,
    required String? lastLoginSchoolCode,
    String? lastLoginApp,
    DateTime? lastLoginAt,
  });
  Future<SchoolNamesResponseModel> getSchoolNamesByOrg({
    required String organizationCode,
    required List<String> schoolCodes,
    required bool isAdmin,
    required String accessToken,
  });
  Future<List<String>> getOrganizationNames({
    required List<String> organizationCodes,
    required String accessToken,
  });
  Future<List<Map<String, dynamic>>> getUserDetails({
    required String accessToken,
  });
  Future<String> forgotPassword({required String email});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    try {
      final loginUrl = ApiPaths.url(ApiPaths.authLogin);
      // Encode request as a JSON string body
      final requestData = request.toJson();
      final requestBody = jsonEncode(requestData);
      ApiLogger.logRequest(
        url: loginUrl,
        method: 'POST',
        headers: ApiHeaders.json,
        body: requestBody,
      );

      final response = await _dio.post<Map<String, dynamic>>(
        loginUrl,
        data: requestBody,
        options: Options(headers: ApiHeaders.json),
      );

      ApiLogger.logResponse(
        url: loginUrl,
        method: 'POST',
        statusCode: response.statusCode,
        data: response.data,
      );

      if (response.statusCode == 200 && response.data != null) {
        final rawMap = response.data!;
        // Extract data - handle both { data: {...} } and { data: { data: {...} } }
        Object? dataPayload = rawMap['data'];
        if (dataPayload is Map<String, dynamic> &&
            dataPayload['accessToken'] == null &&
            dataPayload['access_token'] == null &&
            dataPayload['data'] != null) {
          dataPayload = dataPayload['data'];
        }
        final dataMap = dataPayload as Map<String, dynamic>?;
        if (dataMap == null) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            error: 'Login failed: Missing data in response',
          );
        }
        var loginModel = LoginResponseModel.fromJson(dataMap);
        if (loginModel.refreshToken.trim().isEmpty) {
          // Mirrors TokenRefreshService._doRefresh's own fallback: this
          // backend delivers the refresh token via `Set-Cookie` at least
          // some of the time (see that method's doc comment — the web
          // client relies on the browser echoing a JS-set, non-httpOnly
          // cookie rather than reading it out of the JSON body). If login
          // ever does the same and this JSON body simply never carries the
          // field, missing this fallback here means the session NEVER gets
          // a refresh token and force-logs-out the instant the access token
          // expires — silently, with no error, hours or minutes later.
          final cookieToken = TokenRefreshService.refreshTokenFromSetCookie(
            response.headers,
          );
          if (cookieToken.isNotEmpty) {
            AppLogger.d(
              '[TokenRefresh] login body carried no refreshToken — recovered '
              'one from Set-Cookie',
            );
            loginModel = loginModel.copyWith(refreshToken: cookieToken);
          }
        }
        if (loginModel.accessToken.isEmpty) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            error: 'Login failed: Missing accessToken in response',
          );
        }
        return loginModel;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Login failed: Invalid response',
        );
      }
    } on DioException catch (e) {
      final loginUrl = ApiPaths.url(ApiPaths.authLogin);
      ApiLogger.logError(
        url: loginUrl,
        method: 'POST',
        type: e.type.toString(),
        message: e.message,
        statusCode: e.response?.statusCode,
        errorData: e.response?.data,
      );
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final errorMessage =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Login failed';
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: DioExceptionType.badResponse,
          error: 'Status: $statusCode - $errorMessage',
        );
      } else {
        throw DioException(
          requestOptions: e.requestOptions,
          type: DioExceptionType.connectionTimeout,
          error: 'Network error: ${e.message}',
        );
      }
    } catch (e, stackTrace) {
      final loginUrl = ApiPaths.url(ApiPaths.authLogin);
      ApiLogger.logUnexpectedError(
        url: loginUrl,
        method: 'POST',
        error: e,
        stackTrace: stackTrace,
      );
      throw DioException(
        requestOptions: RequestOptions(path: ApiPaths.authLogin),
        type: DioExceptionType.unknown,
        error: 'Unexpected error: $e',
      );
    }
  }

  @override
  Future<void> logout(LogoutRequestModel request) async {
    final url = ApiPaths.url(ApiPaths.authLogout);
    final requestBody = jsonEncode(request.toJson());
    try {
      ApiLogger.logRequest(
        url: url,
        method: 'POST',
        headers: ApiHeaders.json,
        body: requestBody,
      );

      final response = await _dio.post(
        url,
        data: requestBody,
        options: Options(headers: ApiHeaders.json),
      );

      ApiLogger.logResponse(
        url: url,
        method: 'POST',
        statusCode: response.statusCode,
        data: response.data,
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Logout failed: Invalid response',
        );
      }
    } on DioException catch (e) {
      ApiLogger.logError(
        url: url,
        method: 'POST',
        type: e.type.toString(),
        message: e.message,
        statusCode: e.response?.statusCode,
        errorData: e.response?.data,
      );
      rethrow;
    } catch (e, stackTrace) {
      ApiLogger.logUnexpectedError(
        url: url,
        method: 'POST',
        error: e,
        stackTrace: stackTrace,
      );
      throw DioException(
        requestOptions: RequestOptions(path: ApiPaths.authLogout),
        type: DioExceptionType.unknown,
        error: 'Unexpected error: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getLoginContext({
    required String accessToken,
  }) async {
    final url = ApiPaths.url(ApiPaths.authLoginContext);

    try {
      // Call login-context WITH Authorization header
      final headers = ApiHeaders.authorizedJson(accessToken);
      ApiLogger.logRequest(
        url: url,
        method: 'GET',
        headers: headers,
        queryParameters: const <String, dynamic>{},
        body: null,
      );

      final response = await _dio.get<Map<String, dynamic>>(
        url,
        options: Options(headers: headers),
      );

      ApiLogger.logResponse(
        url: url,
        method: 'GET',
        statusCode: response.statusCode,
        data: response.data,
      );

      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data!;
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
          raw,
          (dataJson) =>
              (dataJson as Map<String, dynamic>? ?? <String, dynamic>{}),
        );
        // Login-context may return payload at top level (no "data" wrapper).
        // If apiResponse.data is null/empty, use raw response as context.
        final context = apiResponse.data;
        if (context != null &&
            (context['LastLoginOrganizationCode'] != null ||
                context['LastLoginSchoolCode'] != null)) {
          return context;
        }
        return raw;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to get login context: Invalid response',
        );
      }
    } on DioException catch (e) {
      ApiLogger.logError(
        url: url,
        method: 'GET',
        type: e.type.toString(),
        message: e.message,
        statusCode: e.response?.statusCode,
        errorData: e.response?.data,
      );
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final errorMessage =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Failed to get login context';
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: DioExceptionType.badResponse,
          error: 'Status: $statusCode - $errorMessage',
        );
      } else {
        throw DioException(
          requestOptions: e.requestOptions,
          type: DioExceptionType.connectionTimeout,
          error: 'Network error: ${e.message}',
        );
      }
    } catch (e, stackTrace) {
      ApiLogger.logUnexpectedError(
        url: url,
        method: 'GET',
        error: e,
        stackTrace: stackTrace,
      );
      throw DioException(
        requestOptions: RequestOptions(path: url),
        type: DioExceptionType.unknown,
        error: 'Unexpected error: $e',
      );
    }
  }

  @override
  Future<void> patchLoginContext({
    required String accessToken,
    required String? lastLoginOrganizationCode,
    required String? lastLoginSchoolCode,
    String? lastLoginApp,
    DateTime? lastLoginAt,
  }) async {
    final url = ApiPaths.url(ApiPaths.authLoginContext);
    final org = lastLoginOrganizationCode?.trim();
    final school = lastLoginSchoolCode?.trim();
    final body = <String, dynamic>{
      'lastLoginApp': lastLoginApp ?? 'wowcare',
      'lastLoginOrganizationCode': (org == null || org.isEmpty) ? null : org,
      'lastLoginSchoolCode': (school == null || school.isEmpty) ? null : school,
      'lastLoginAt': (lastLoginAt ?? AppTime.nowUtc()).toIso8601String(),
    };
    final requestBody = jsonEncode(body);

    try {
      // Call login-context PATCH WITH Authorization header
      final headers = ApiHeaders.authorizedJson(accessToken);
      ApiLogger.logRequest(
        url: url,
        method: 'PATCH',
        headers: headers,
        body: requestBody,
      );

      final response = await _dio.patch<Map<String, dynamic>>(
        url,
        data: requestBody,
        options: Options(headers: headers),
      );

      ApiLogger.logResponse(
        url: url,
        method: 'PATCH',
        statusCode: response.statusCode,
        data: response.data,
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to update login context: Invalid response',
        );
      }
    } on DioException catch (e) {
      ApiLogger.logError(
        url: url,
        method: 'PATCH',
        type: e.type.toString(),
        message: e.message,
        statusCode: e.response?.statusCode,
        errorData: e.response?.data,
      );
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final errorMessage =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Failed to update login context';
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: DioExceptionType.badResponse,
          error: 'Status: $statusCode - $errorMessage',
        );
      }
      rethrow;
    } catch (e, stackTrace) {
      ApiLogger.logUnexpectedError(
        url: url,
        method: 'PATCH',
        error: e,
        stackTrace: stackTrace,
      );
      throw DioException(
        requestOptions: RequestOptions(path: url),
        type: DioExceptionType.unknown,
        error: 'Unexpected error: $e',
      );
    }
  }

  @override
  Future<SchoolNamesResponseModel> getSchoolNamesByOrg({
    required String organizationCode,
    required List<String> schoolCodes,
    required bool isAdmin,
    required String accessToken,
  }) async {
    try {
      // GET /api/v1/schools/names-by-org/{organizationCode}?isAdmin=true|false
      final path = ApiPaths.schoolNamesByOrgPath(organizationCode);
      final url = ApiPaths.urlWithBase(path, ApiConstants.schoolMs);

      final queryParams = <String, dynamic>{'isAdmin': isAdmin};
      if (schoolCodes.isNotEmpty) {
        queryParams['schoolCodes'] = schoolCodes;
      }

      // Call school-names endpoint WITH Authorization header
      final headers = ApiHeaders.authorizedJson(accessToken);
      ApiLogger.logRequest(
        url: url,
        method: 'GET',
        headers: headers,
        queryParameters: queryParams,
        body: null,
      );

      final response = await _dio.get<Map<String, dynamic>>(
        url,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      ApiLogger.logResponse(
        url: url,
        method: 'GET',
        queryParameters: queryParams,
        statusCode: response.statusCode,
        data: response.data,
      );

      if (response.statusCode == 200 && response.data != null) {
        return SchoolNamesResponseModel.fromJson(response.data!);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to get school names: Invalid response',
        );
      }
    } on DioException catch (e) {
      final errorUrl = ApiPaths.urlWithBase(
        ApiPaths.schoolNamesByOrgPath(organizationCode),
        ApiConstants.schoolMs,
      );
      ApiLogger.logError(
        url: errorUrl,
        method: 'GET',
        type: e.type.toString(),
        message: e.message,
        statusCode: e.response?.statusCode,
        errorData: e.response?.data,
      );
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final errorMessage =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Failed to get school names';
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: DioExceptionType.badResponse,
          error: 'Status: $statusCode - $errorMessage',
        );
      } else {
        throw DioException(
          requestOptions: e.requestOptions,
          type: DioExceptionType.connectionTimeout,
          error: 'Network error: ${e.message}',
        );
      }
    } catch (e, stackTrace) {
      final errorUrl = ApiPaths.urlWithBase(
        ApiPaths.schoolNamesByOrgPath(organizationCode),
        ApiConstants.schoolMs,
      );
      ApiLogger.logUnexpectedError(
        url: errorUrl,
        method: 'GET',
        error: e,
        stackTrace: stackTrace,
      );
      throw DioException(
        requestOptions: RequestOptions(path: errorUrl),
        type: DioExceptionType.unknown,
        error: 'Unexpected error: $e',
      );
    }
  }

  @override
  Future<List<String>> getOrganizationNames({
    required List<String> organizationCodes,
    required String accessToken,
  }) async {
    try {
      final url = ApiPaths.urlWithBase(
        ApiPaths.organizationNames,
        ApiConstants.baseUrl,
      );

      final queryParams = <String, dynamic>{
        'organizationCodes': organizationCodes,
      };

      // Call organization-names endpoint WITH Authorization header
      final headers = ApiHeaders.authorizedJson(accessToken);
      ApiLogger.logRequest(
        url: url,
        method: 'GET',
        headers: headers,
        queryParameters: queryParams,
        body: null,
      );

      final response = await _dio.get<Map<String, dynamic>>(
        url,
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      ApiLogger.logResponse(
        url: url,
        method: 'GET',
        queryParameters: queryParams,
        statusCode: response.statusCode,
        data: response.data,
      );

      if (response.statusCode == 200 && response.data != null) {
        final apiResponse = ApiResponse<List<String>>.fromJson(response.data!, (
          dataJson,
        ) {
          if (dataJson is! List) return <String>[];
          final codeToName = <String, String>{};
          for (final e in dataJson) {
            if (e is Map && e['code'] != null && e['name'] != null) {
              codeToName[e['code'].toString()] = e['name'].toString();
            }
          }
          return organizationCodes.map((c) => codeToName[c] ?? c).toList();
        });
        return apiResponse.data ?? <String>[];
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to get organization names: Invalid response',
        );
      }
    } on DioException catch (e) {
      final errorUrl = ApiPaths.urlWithBase(
        ApiPaths.organizationNames,
        ApiConstants.baseUrl,
      );
      ApiLogger.logError(
        url: errorUrl,
        method: 'GET',
        type: e.type.toString(),
        message: e.message,
        statusCode: e.response?.statusCode,
        errorData: e.response?.data,
      );
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final errorMessage =
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            'Failed to get organization names';
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: DioExceptionType.badResponse,
          error: 'Status: $statusCode - $errorMessage',
        );
      } else {
        throw DioException(
          requestOptions: e.requestOptions,
          type: DioExceptionType.connectionTimeout,
          error: 'Network error: ${e.message}',
        );
      }
    } catch (e, stackTrace) {
      final errorUrl = ApiPaths.urlWithBase(
        ApiPaths.organizationNames,
        ApiConstants.baseUrl,
      );
      ApiLogger.logUnexpectedError(
        url: errorUrl,
        method: 'GET',
        error: e,
        stackTrace: stackTrace,
      );
      throw DioException(
        requestOptions: RequestOptions(path: errorUrl),
        type: DioExceptionType.unknown,
        error: 'Unexpected error: $e',
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUserDetails({
    required String accessToken,
  }) async {
    final url = ApiPaths.url(ApiPaths.userDetails);
    final headers = ApiHeaders.authorizedJson(accessToken);
    try {
      ApiLogger.logRequest(
        url: url,
        method: 'GET',
        headers: headers,
        queryParameters: const <String, dynamic>{},
        body: null,
      );

      final response = await _dio.get<Map<String, dynamic>>(
        url,
        options: Options(headers: headers),
      );

      ApiLogger.logResponse(
        url: url,
        method: 'GET',
        statusCode: response.statusCode,
        data: response.data,
      );

      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data!['data'];
        if (rawData is List) {
          return rawData
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return const <Map<String, dynamic>>[];
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: 'Failed to get user details: Invalid response',
      );
    } on DioException catch (e) {
      ApiLogger.logError(
        url: url,
        method: 'GET',
        type: e.type.toString(),
        message: e.message,
        statusCode: e.response?.statusCode,
        errorData: e.response?.data,
      );
      rethrow;
    } catch (e, stackTrace) {
      ApiLogger.logUnexpectedError(
        url: url,
        method: 'GET',
        error: e,
        stackTrace: stackTrace,
      );
      throw DioException(
        requestOptions: RequestOptions(path: url),
        type: DioExceptionType.unknown,
        error: 'Unexpected error: $e',
      );
    }
  }

  @override
  Future<String> forgotPassword({required String email}) async {
    final url = ApiPaths.url(ApiPaths.authForgotPassword);

    final queryParams = <String, dynamic>{'email': email};

    try {
      ApiLogger.logRequest(
        url: url,
        method: 'POST',
        headers: ApiHeaders.json,
        queryParameters: queryParams,
        body: null,
      );

      final response = await _dio.post<Map<String, dynamic>>(
        url,
        queryParameters: queryParams,
        data: null,
        options: Options(
          headers: const {
            'Content-Type': 'application/json',
            'accept': 'application/json',
          },
        ),
      );

      ApiLogger.logResponse(
        url: url,
        method: 'POST',
        queryParameters: queryParams,
        statusCode: response.statusCode,
        data: response.data,
      );

      if (response.statusCode == 200 && response.data != null) {
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
          response.data!,
          (dataJson) =>
              (dataJson as Map<String, dynamic>? ?? <String, dynamic>{}),
        );
        // Return the backend message so UI can display it directly.
        return apiResponse.message;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Forgot password failed: Invalid response',
        );
      }
    } on DioException catch (e) {
      ApiLogger.logError(
        url: url,
        method: 'POST',
        type: e.type.toString(),
        message: e.message,
        statusCode: e.response?.statusCode,
        errorData: e.response?.data,
      );
      // Always rethrow to preserve the original DioException with its message
      // The repository layer will extract the message properly
      rethrow;
    } catch (e, stackTrace) {
      ApiLogger.logUnexpectedError(
        url: url,
        method: 'POST',
        error: e,
        stackTrace: stackTrace,
      );
      throw DioException(
        requestOptions: RequestOptions(path: ApiPaths.authForgotPassword),
        type: DioExceptionType.unknown,
        error: 'Unexpected error: $e',
      );
    }
  }
}
