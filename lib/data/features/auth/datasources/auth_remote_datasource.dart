import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:wowcare/core/network/api_logger.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/data/features/auth/models/login_request_model.dart';
import 'package:wowcare/data/features/auth/models/login_response_model.dart';
import 'package:wowcare/data/features/auth/models/logout_request_model.dart';
import 'package:wowcare/data/features/auth/models/school_names_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseModel> login(LoginRequestModel request);
  Future<void> logout(LogoutRequestModel request);
  Future<SchoolNamesResponseModel> getSchoolNamesByOrg({
    required String organizationCode,
    required List<String> schoolCodes,
    required bool isAdmin,
    required String accessToken,
  });
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
        headers: const {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: requestBody,
      );

      final response = await _dio.post<Map<String, dynamic>>(
        ApiPaths.authLogin,
        data: requestBody,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'accept': 'application/json',
          },
        ),
      );

      ApiLogger.logResponse(
        url: loginUrl,
        method: 'POST',
        statusCode: response.statusCode,
        data: response.data,
      );

      if (response.statusCode == 200 && response.data != null) {
        return LoginResponseModel.fromJson(response.data!);
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
        final errorMessage = e.response?.data?['message'] ??
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
        headers: const {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: requestBody,
      );

      final response = await _dio.post(
        ApiPaths.authLogout,
        data: requestBody,
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
  Future<SchoolNamesResponseModel> getSchoolNamesByOrg({
    required String organizationCode,
    required List<String> schoolCodes,
    required bool isAdmin,
    required String accessToken,
  }) async {
    try {
      // Use Sairam base URL for school-ms API
      final url = ApiPaths.urlWithBase(
        ApiPaths.schoolNamesByOrg,
        ApiConstants.Sairam,
      );
      
      // Build query parameters
      final queryParams = <String, dynamic>{
        'organizationCode': organizationCode,
        'isAdmin': isAdmin,
        'schoolCodes': schoolCodes, // Include even if empty array
      };

      ApiLogger.logRequest(
        url: url,
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        queryParameters: queryParams,
        body: null,
      );

      final response = await _dio.get<Map<String, dynamic>>(
        url,
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'accept': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
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
        ApiPaths.schoolNamesByOrg,
        ApiConstants.Sairam,
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
        final errorMessage = e.response?.data?['message'] ??
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
        ApiPaths.schoolNamesByOrg,
        ApiConstants.Sairam,
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
}
