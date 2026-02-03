import 'package:dio/dio.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/data/features/classroom/models/classroom_all_models.dart';

/// Data source for Classroom-related remote APIs.
abstract class ClassroomRemoteDataSource {
  Future<ClassroomAllResponseModel> getActiveClassrooms({
    required String schoolCode,
  });
}

class ClassroomRemoteDataSourceImpl implements ClassroomRemoteDataSource {
  ClassroomRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<ClassroomAllResponseModel> getActiveClassrooms({
    required String schoolCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.classroomAll,
      ApiConstants.classroomBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'school': schoolCode,
        'status': 'ACTIVE',
        'type': 'CLASSROOM',
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected classroom(all) API response format');
    }

    return ClassroomAllResponseModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }
}


