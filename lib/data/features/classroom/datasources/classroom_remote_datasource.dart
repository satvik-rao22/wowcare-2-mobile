import 'package:dio/dio.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/data/features/classroom/models/classroom_all_models.dart';

/// Data source for Classroom-related remote APIs.
abstract class ClassroomRemoteDataSource {
  Future<ClassroomAllResponseModel> getActiveClassrooms({
    required String schoolCode,
    /// When true, restricts results to type=CLASSROOM.
    /// When false, omits the type filter so the backend
    /// can return all active locations (e.g. Office, etc.).
    bool onlyTypeClassroom,
  });
}

class ClassroomRemoteDataSourceImpl implements ClassroomRemoteDataSource {
  ClassroomRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<ClassroomAllResponseModel> getActiveClassrooms({
    required String schoolCode,
    bool onlyTypeClassroom = true,
  }) async {
    // Full [Uri] so Dio does not merge this with [BaseOptions.baseUrl]
    // (which would incorrectly produce …/classroom/classroom/all).
    final qp = <String, String>{
      'school': schoolCode,
      'status': 'ACTIVE',
    };
    if (onlyTypeClassroom) {
      qp['type'] = 'CLASSROOM';
    }
    final uri = Uri.parse(ApiPaths.url(ApiPaths.classroomAll)).replace(
      queryParameters: qp,
    );

    final response = await _client.getUri<dynamic>(uri);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected classroom(all) API response format');
    }

    return ClassroomAllResponseModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }
}


