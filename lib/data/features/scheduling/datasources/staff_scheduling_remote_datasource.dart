import 'package:dio/dio.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/data/features/staff/models/staff_shift_models.dart';

/// Staff Scheduling HTTP client — all endpoints are hosted on the **staff**
/// microservice ([ApiConstants.staffBaseUrl] / [ApiMicroservices.staff]).
abstract class StaffSchedulingRemoteDataSource {
  Future<StaffShiftsPageModel> getStaffShifts({
    required String organizationCode,
    required String schoolCode,
    required String staffCode,
    required String dateFrom,
    required String dateTo,
    String? classroomCode,
    List<String>? shiftStatus,
    int page = 0,
    int size = 50,
  });
}

class StaffSchedulingRemoteDataSourceImpl
    implements StaffSchedulingRemoteDataSource {
  StaffSchedulingRemoteDataSourceImpl(this._client);

  final Dio _client;

  /// Resolves a path on the staff MS (LOCAL tunnel / UAT gateway).
  static String staffMsEndpoint(String path) => ApiPaths.staffMicroserviceUrl(path);

  @override
  Future<StaffShiftsPageModel> getStaffShifts({
    required String organizationCode,
    required String schoolCode,
    required String staffCode,
    required String dateFrom,
    required String dateTo,
    String? classroomCode,
    List<String>? shiftStatus,
    int page = 0,
    int size = 50,
  }) async {
    final queryParameters = <String, dynamic>{
      'schoolCode': schoolCode,
      'organizationCode': organizationCode,
      'staffCode': staffCode,
      'dateFrom': dateFrom,
      'dateTo': dateTo,
      'page': page,
      'size': size,
    };

    if (classroomCode != null && classroomCode.trim().isNotEmpty) {
      queryParameters['classroomCode'] = classroomCode.trim();
    }
    final statuses = shiftStatus?.where((s) => s.trim().isNotEmpty).toList();
    if (statuses != null && statuses.isNotEmpty) {
      queryParameters['shiftStatus'] = statuses;
    }

    final response = await _client.get<dynamic>(
      staffMsEndpoint(ApiPaths.staffShifts),
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff-shifts API response format');
    }

    return StaffShiftsPageModel.fromJson(response.data! as Map<String, dynamic>);
  }
}
