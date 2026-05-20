import 'package:dio/dio.dart';

import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../models/staff_shift_models.dart';

abstract class StaffShiftRemoteDataSource {
  Future<List<StaffShiftModel>> getStaffShifts({
    required String staffCode,
    required String schoolCode,
    required String organizationCode,
    required String dateFrom,
    required String dateTo,
  });

  Future<StaffShiftCreateResultModel> createStaffShift({
    required Map<String, dynamic> body,
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

  /// Tolerates either `{ data: { items: [...] } }`, `{ data: [...] }`,
  /// or a raw `[...]` body. Mirrors the loose shape used by the staff service.
  static List<StaffShiftModel> _parseShiftList(dynamic raw) {
    List<dynamic>? items;
    if (raw is List) {
      items = raw;
    } else if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is List) {
        items = data;
      } else if (data is Map<String, dynamic>) {
        final inner = data['items'] ?? data['content'] ?? data['shifts'];
        if (inner is List) items = inner;
      }
    }
    if (items == null) return const <StaffShiftModel>[];
    return items
        .whereType<Map<String, dynamic>>()
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
