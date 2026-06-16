import 'package:dio/dio.dart';

import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../models/classroom_forecast_models.dart';
import '../models/staff_shift_hours_models.dart';
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
    String? classroomCode,
    List<String> shiftStatus = const <String>[],
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

  Future<List<StaffShiftHoursEntryModel>> getStaffShiftHoursRange({
    required StaffShiftHoursRangeRequestModel request,
  });

  /// `GET /api/v1/staff-attendance/profile/absent/toggle` — returns the list of
  /// dates the given staff was marked absent within [fromAbsenceDate]..
  /// [toAbsenceDate] (inclusive). Used pre-create to block / strip shifts on
  /// absent days.
  Future<List<DateTime>> getStaffAbsentDatesInRange({
    required String staffCode,
    required String fromAbsenceDate,
    required String toAbsenceDate,
  });

  /// `POST /api/v1/staff-shifts/absent-days` — deletes shifts the just-created
  /// recurring series produced on dates the staff is marked absent.
  Future<int> markStaffShiftAbsentDays({
    required String staffCode,
    required String schoolCode,
    required List<String> absentDates,
  });

  /// `PUT /api/v1/staff-shifts/{shiftCode}` — update a single shift occurrence.
  Future<StaffShiftModel> updateStaffShift({
    required String shiftCode,
    required Map<String, dynamic> body,
  });

  /// `PUT /api/v1/staff-shifts/series/{seriesCode}` — update an entire
  /// recurring shift series. Returns the same create-result envelope (created/
  /// skipped/overridden counts + warnings).
  Future<StaffShiftCreateResultModel> updateStaffShiftSeries({
    required String seriesCode,
    required Map<String, dynamic> body,
  });

  /// `POST /api/v1/staff-shifts/publish` — publishes draft shifts. The backend
  /// supports two orthogonal axes: which staff (all vs. an explicit list) and
  /// which dates (everything from [dateRangeStart] forward vs. up to
  /// [publishUntilDate]).
  Future<void> publishStaffShifts({required Map<String, dynamic> body});

  /// `DELETE /api/v1/staff-shifts/{shiftCode}` — remove one shift occurrence.
  Future<void> deleteStaffShift({required String shiftCode});

  /// `DELETE /api/v1/staff-shifts/series/{seriesCode}` — remove every shift
  /// in a recurring series.
  Future<void> deleteStaffShiftSeries({required String seriesCode});
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
    String? classroomCode,
    List<String> shiftStatus = const <String>[],
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffShifts,
      ApiConstants.staffBaseUrl,
    );

    final queryParameters = <String, dynamic>{
      'schoolCode': schoolCode,
      'organizationCode': organizationCode,
      'dateFrom': dateFrom,
      'dateTo': dateTo,
    };
    final code = classroomCode?.trim();
    if (code != null && code.isNotEmpty) {
      queryParameters['classroomCode'] = code;
    }
    final statuses = shiftStatus
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    if (statuses.isNotEmpty) {
      queryParameters['shiftStatus'] = statuses;
    }

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
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

  @override
  Future<List<StaffShiftHoursEntryModel>> getStaffShiftHoursRange({
    required StaffShiftHoursRangeRequestModel request,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffShiftHoursRange,
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.post<dynamic>(
      endpoint,
      data: request.toJson(),
    );

    return _parseHoursList(response.data);
  }

  @override
  Future<List<DateTime>> getStaffAbsentDatesInRange({
    required String staffCode,
    required String fromAbsenceDate,
    required String toAbsenceDate,
  }) async {
    // Attendance MS hosts the absent-toggle profile endpoint.
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceProfileAbsentToggle,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'staffCode': staffCode,
        'fromAbsenceDate': fromAbsenceDate,
        'toAbsenceDate': toAbsenceDate,
        'page': 0,
        'size': 200,
      },
    );

    final raw = response.data;
    if (raw is! Map<String, dynamic>) return const <DateTime>[];
    final data = raw['data'];
    if (data is! Map<String, dynamic>) return const <DateTime>[];
    final records = data['records'];
    if (records is! Map<String, dynamic>) return const <DateTime>[];
    final content = records['content'];
    if (content is! List) return const <DateTime>[];

    final dates = <DateTime>{};
    for (final item in content) {
      if (item is! Map<String, dynamic>) continue;
      final dateStr = item['absenceDate']?.toString().trim() ?? '';
      if (dateStr.isEmpty) continue;
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) {
        dates.add(DateTime(parsed.year, parsed.month, parsed.day));
      }
    }
    final sorted = dates.toList(growable: false)
      ..sort((a, b) => a.compareTo(b));
    return sorted;
  }

  @override
  Future<StaffShiftModel> updateStaffShift({
    required String shiftCode,
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffShiftByCode(shiftCode),
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.put<dynamic>(endpoint, data: body);

    final raw = response.data;
    if (raw is! Map<String, dynamic>) {
      throw Exception('Unexpected staff-shift update API response format');
    }
    final data = raw['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Missing data payload in staff-shift update response');
    }
    return StaffShiftModel.fromJson(data);
  }

  @override
  Future<void> publishStaffShifts({
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffShiftsPublish,
      ApiConstants.staffBaseUrl,
    );
    await _client.post<dynamic>(endpoint, data: body);
  }

  @override
  Future<void> deleteStaffShift({required String shiftCode}) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffShiftByCode(shiftCode),
      ApiConstants.staffBaseUrl,
    );
    await _client.delete<dynamic>(endpoint);
  }

  @override
  Future<void> deleteStaffShiftSeries({required String seriesCode}) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffShiftSeriesByCode(seriesCode),
      ApiConstants.staffBaseUrl,
    );
    await _client.delete<dynamic>(endpoint);
  }

  @override
  Future<StaffShiftCreateResultModel> updateStaffShiftSeries({
    required String seriesCode,
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffShiftSeriesByCode(seriesCode),
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.put<dynamic>(endpoint, data: body);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff-shift series update API response format');
    }
    final map = response.data! as Map<String, dynamic>;
    final data = map['data'];
    if (data is Map<String, dynamic>) {
      return StaffShiftCreateResultModel.fromJson(data);
    }
    return const StaffShiftCreateResultModel();
  }

  @override
  Future<int> markStaffShiftAbsentDays({
    required String staffCode,
    required String schoolCode,
    required List<String> absentDates,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffShiftsAbsentDays,
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.post<dynamic>(
      endpoint,
      data: <String, dynamic>{
        'staffCode': staffCode,
        'absentDates': absentDates,
        'schoolCode': schoolCode,
      },
    );

    final raw = response.data;
    if (raw is! Map<String, dynamic>) return 0;
    final data = raw['data'];
    if (data is! Map<String, dynamic>) return 0;
    final count = data['deletedCount'];
    if (count is num) return count.toInt();
    return int.tryParse(count?.toString() ?? '') ?? 0;
  }

  static List<StaffShiftHoursEntryModel> _parseHoursList(dynamic raw) {
    List<dynamic>? items;
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is List) items = data;
    } else if (raw is List) {
      items = raw;
    }
    if (items == null) return const <StaffShiftHoursEntryModel>[];
    return items
        .whereType<Map<String, dynamic>>()
        .map((json) {
          try {
            return StaffShiftHoursEntryModel.fromJson(json);
          } catch (_) {
            return null;
          }
        })
        .whereType<StaffShiftHoursEntryModel>()
        .toList(growable: false);
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
