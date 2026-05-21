import 'package:dio/dio.dart';

import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../models/classroom_forecast_models.dart';
import '../models/staff_shift_models.dart';

abstract class StaffShiftRemoteDataSource {
  Future<List<StaffShiftModel>> getStaffShifts({
    required String staffCode,
    required String schoolCode,
    required String organizationCode,
    required String dateFrom,
    required String dateTo,
  });

  /// School-wide shift list for [dateFrom]..[dateTo] (no `staffCode`).
  /// Backs the classroom scheduling table.
  Future<List<StaffShiftModel>> getSchoolStaffShifts({
    required String schoolCode,
    required String organizationCode,
    required String dateFrom,
    required String dateTo,
  });

  Future<StaffShiftModel> getStaffShiftByCode({required String shiftCode});

  Future<StaffShiftCreateResultModel> createStaffShift({
    required Map<String, dynamic> body,
  });

  Future<List<ClassroomForecastBlockModel>> getClassroomForecast({
    required String schoolCode,
    required String organizationCode,
    required ClassroomForecastRequestModel request,
  });

  Future<List<ClassroomForecastBlockModel>> getClassroomForecastRange({
    required String schoolCode,
    required String organizationCode,
    required ClassroomForecastRangeRequestModel request,
  });
}

class StaffShiftRemoteDataSourceImpl implements StaffShiftRemoteDataSource {
  StaffShiftRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<List<StaffShiftModel>> getStaffShifts({
    required String staffCode,
    required String schoolCode,
    required String organizationCode,
    required String dateFrom,
    required String dateTo,
  }) async {
    // Same canonical resource path as POST — the UAT gateway expands it to
    // `/api/v1/staff/staff-shifts` via [ApiPathsUat], local builds use it as-is.
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffShifts,
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'staffCode': staffCode,
        'schoolCode': schoolCode,
        'organizationCode': organizationCode,
        'dateFrom': dateFrom,
        'dateTo': dateTo,
      },
    );

    return _parseShiftList(response.data);
  }

  @override
  Future<List<StaffShiftModel>> getSchoolStaffShifts({
    required String schoolCode,
    required String organizationCode,
    required String dateFrom,
    required String dateTo,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffShifts,
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'schoolCode': schoolCode,
        'organizationCode': organizationCode,
        'dateFrom': dateFrom,
        'dateTo': dateTo,
      },
    );

    return _parseShiftList(response.data);
  }

  @override
  Future<StaffShiftModel> getStaffShiftByCode({
    required String shiftCode,
  }) async {
    final base = ApiPaths.urlWithBase(
      ApiPaths.staffShifts,
      ApiConstants.staffBaseUrl,
    );
    final endpoint = '$base/${Uri.encodeComponent(shiftCode)}';

    final response = await _client.get<dynamic>(endpoint);
    final raw = response.data;
    if (raw is! Map<String, dynamic>) {
      throw Exception('Unexpected staff-shift detail API response format');
    }
    final data = raw['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Missing data payload in staff-shift detail response');
    }
    return StaffShiftModel.fromJson(data);
  }

  @override
  Future<StaffShiftCreateResultModel> createStaffShift({
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffShifts,
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.post<dynamic>(endpoint, data: body);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff-shift create API response format');
    }
    final map = response.data! as Map<String, dynamic>;
    final data = map['data'];
    if (data is Map<String, dynamic>) {
      return StaffShiftCreateResultModel.fromJson(data);
    }
    // Some endpoints return success without a structured `data` body.
    return const StaffShiftCreateResultModel();
  }

  @override
  Future<List<ClassroomForecastBlockModel>> getClassroomForecast({
    required String schoolCode,
    required String organizationCode,
    required ClassroomForecastRequestModel request,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffShiftClassroomForecast,
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.post<dynamic>(
      endpoint,
      data: request.toJson(),
      options: Options(
        headers: <String, String>{
          'X-School-Code': schoolCode,
          'X-Organization-Code': organizationCode,
        },
      ),
    );

    return _parseForecastList(response.data);
  }

  @override
  Future<List<ClassroomForecastBlockModel>> getClassroomForecastRange({
    required String schoolCode,
    required String organizationCode,
    required ClassroomForecastRangeRequestModel request,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffShiftClassroomForecastRange,
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.post<dynamic>(
      endpoint,
      data: request.toJson(),
      options: Options(
        headers: <String, String>{
          'X-School-Code': schoolCode,
          'X-Organization-Code': organizationCode,
        },
      ),
    );

    return _parseForecastList(response.data);
  }

  static List<ClassroomForecastBlockModel> _parseForecastList(dynamic raw) {
    List<dynamic>? items;
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is List) {
        items = data;
      }
    } else if (raw is List) {
      items = raw;
    }
    if (items == null) return const <ClassroomForecastBlockModel>[];
    return items
        .whereType<Map<String, dynamic>>()
        .map((json) {
          try {
            return ClassroomForecastBlockModel.fromJson(json);
          } catch (_) {
            return null;
          }
        })
        .whereType<ClassroomForecastBlockModel>()
        .toList(growable: false);
  }

  /// Backend may return either the flat envelope `{ data: [...] }` or the
  /// Spring Pageable envelope `{ data: { content: [...], pageable, totalPages,
  /// ... } }`. Also tolerates a raw `[...]` body as a defensive fallback.
  static List<StaffShiftModel> _parseShiftList(dynamic raw) {
    List<dynamic>? items;
    if (raw is List) {
      items = raw;
    } else if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is List) {
        items = data;
      } else if (data is Map<String, dynamic>) {
        final content = data['content'];
        if (content is List) items = content;
      }
    }
    if (items == null) return const <StaffShiftModel>[];
    return items
        .whereType<Map<String, dynamic>>()
        // Cancelled shifts shouldn't show up in the schedule grid — the
        // backend keeps them in the same list, so filter at the boundary.
        .where((json) =>
            (json['shiftStatus']?.toString().toUpperCase() ?? '') !=
            'CANCELLED')
        .map((json) {
          try {
            return StaffShiftModel.fromJson(json);
          } catch (_) {
            return null;
          }
        })
        .whereType<StaffShiftModel>()
        .toList(growable: false);
  }
}
