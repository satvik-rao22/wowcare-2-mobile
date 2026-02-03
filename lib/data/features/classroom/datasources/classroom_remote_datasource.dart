import 'package:dio/dio.dart';

import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../models/classroom_models.dart';

abstract class ClassroomRemoteDataSource {
  Future<ClassroomPageModel> getClassrooms({
    required String schoolCode,
    int page = 0,
    int size = 10,
  });
}

class ClassroomRemoteDataSourceImpl implements ClassroomRemoteDataSource {
  ClassroomRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<ClassroomPageModel> getClassrooms({
    required String schoolCode,
    int page = 0,
    int size = 10,
  }) async {
    final queryParameters = <String, dynamic>{
      'schoolCode': schoolCode,
      'page': page,
      'size': size,
    };

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.classroomList,
      ApiConstants.classroomBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected classroom API response format');
    }

    return ClassroomPageModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }
}


