import 'package:dio/dio.dart';

import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../../../../domain/features/events/entities/holiday.dart';
import '../models/holiday_models.dart';

/// Talks to the Holidays API on the scheduler microservice
/// (`/api/v1/holidays`). Org/school scoping headers are attached globally by
/// [AuthInterceptor]; only the per-request `If-Match` header is set here for
/// optimistic locking on `PATCH` endpoints.
abstract class HolidayRemoteDataSource {
  /// `GET /api/v1/holidays?year=&type=&status=`. Flattens the grouped
  /// response (`pendingFederal` + `active` + `rejectedFederal`).
  Future<List<HolidayModel>> getHolidays({
    int? year,
    String? type,
    String? status,
  });

  /// `POST /api/v1/holidays` — create a school holiday. Returns the created
  /// holiday alongside the API's `message` (e.g. "School holiday created
  /// successfully") so callers can surface it as a toast.
  Future<(HolidayModel, String)> createHoliday({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String description,
  });

  /// `PATCH /api/v1/holidays/{code}` — partial update (school holidays).
  Future<(HolidayModel, String)> updateHoliday({
    required String code,
    required int version,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
  });

  /// `PATCH /api/v1/holidays/{code}/status` — approve/reject a federal holiday.
  Future<(HolidayModel, String)> updateStatus({
    required String code,
    required int version,
    required HolidayStatusAction action,
  });

  /// `DELETE /api/v1/holidays/{code}` — remove a school holiday. Returns the
  /// API's `message`.
  Future<String> deleteHoliday(String code);
}

class HolidayRemoteDataSourceImpl implements HolidayRemoteDataSource {
  HolidayRemoteDataSourceImpl(this._client);

  final Dio _client;

  static const List<String> _listGroups = [
    'pendingFederal',
    'active',
    'rejectedFederal',
  ];

  @override
  Future<List<HolidayModel>> getHolidays({
    int? year,
    String? type,
    String? status,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.holidays,
      ApiConstants.schedulerBaseUrl,
    );

    final queryParameters = <String, dynamic>{
      if (year != null) 'year': year,
      if (type != null && type.isNotEmpty) 'type': type,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    return _parseList(response.data);
  }

  @override
  Future<(HolidayModel, String)> createHoliday({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String description = '',
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.holidays,
      ApiConstants.schedulerBaseUrl,
    );

    final response = await _client.post<dynamic>(
      endpoint,
      data: HolidayModel.createBody(
        name: name,
        startDate: startDate,
        endDate: endDate,
        description: description,
      ),
    );

    return _parseSingle(
      response.data,
      action: 'create',
      fallbackMessage: 'Holiday created successfully',
    );
  }

  @override
  Future<(HolidayModel, String)> updateHoliday({
    required String code,
    required int version,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.holidayByCode(code),
      ApiConstants.schedulerBaseUrl,
    );

    // Partial update: send only the provided fields. Per the API contract,
    // dates must be sent together and as `YYYY-MM-DD`.
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (startDate != null && endDate != null) ...{
        'startDate': HolidayModel.formatDate(startDate),
        'endDate': HolidayModel.formatDate(endDate),
      },
    };

    final response = await _client.patch<dynamic>(
      endpoint,
      data: body,
      options: _ifMatch(version),
    );

    return _parseSingle(
      response.data,
      action: 'update',
      fallbackMessage: 'Holiday updated successfully',
    );
  }

  @override
  Future<(HolidayModel, String)> updateStatus({
    required String code,
    required int version,
    required HolidayStatusAction action,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.holidayStatus(code),
      ApiConstants.schedulerBaseUrl,
    );

    final response = await _client.patch<dynamic>(
      endpoint,
      data: <String, dynamic>{'action': action.value},
      options: _ifMatch(version),
    );

    return _parseSingle(
      response.data,
      action: 'status update',
      fallbackMessage: 'Holiday status updated successfully',
    );
  }

  @override
  Future<String> deleteHoliday(String code) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.holidayByCode(code),
      ApiConstants.schedulerBaseUrl,
    );
    final response = await _client.delete<dynamic>(endpoint);
    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      final message = raw['message']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
    }
    return 'Holiday deleted successfully';
  }

  Options _ifMatch(int version) =>
      Options(headers: <String, dynamic>{'If-Match': version.toString()});

  static List<HolidayModel> _parseList(dynamic raw) {
    if (raw is! Map<String, dynamic>) return const <HolidayModel>[];
    final data = raw['data'];
    final items = <HolidayModel>[];

    void addAll(dynamic group) {
      if (group is! List) return;
      for (final entry in group) {
        if (entry is! Map) continue;
        final model = HolidayModel.fromJson(
          entry.map((k, v) => MapEntry(k.toString(), v)),
        );
        if (model.code.isNotEmpty) items.add(model);
      }
    }

    if (data is Map<String, dynamic>) {
      for (final group in _listGroups) {
        addAll(data[group]);
      }
    } else if (data is List) {
      // Defensive: tolerate a flat list payload.
      addAll(data);
    }
    return items;
  }

  static (HolidayModel, String) _parseSingle(
    dynamic raw, {
    required String action,
    required String fallbackMessage,
  }) {
    if (raw is! Map<String, dynamic>) {
      throw Exception('Unexpected holiday $action API response format');
    }
    final data = raw['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Missing data payload in holiday $action response');
    }
    final message = raw['message']?.toString().trim();
    return (
      HolidayModel.fromJson(data),
      message == null || message.isEmpty ? fallbackMessage : message,
    );
  }
}
