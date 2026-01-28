import 'package:dio/dio.dart';
import '../models/staff_models.dart';

abstract class StaffRemoteDataSource {
  Future<StaffPageModel> getStaffPage({
    required String schoolCode,
    int page = 0,
    int size = 10,
    String? status,
    String? designation,
    String? search,
  });
}

class StaffRemoteDataSourceImpl implements StaffRemoteDataSource {
  StaffRemoteDataSourceImpl(this._client);

  final Dio _client;

  static const String _staffEndpoint =
      'https://qs176zl8-8083.inc1.devtunnels.ms/api/v1/staff';

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

    final response = await _client.get<dynamic>(
      _staffEndpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff API response format');
    }

    return StaffPageModel.fromJson(response.data! as Map<String, dynamic>);
  }
}


