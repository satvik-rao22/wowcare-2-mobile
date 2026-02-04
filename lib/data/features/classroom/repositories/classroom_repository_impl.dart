import '../../../../domain/features/classroom/entities/classroom.dart';
import '../../../../domain/features/classroom/repositories/classroom_repository.dart';
import '../datasources/classroom_remote_datasource.dart';
import '../models/classroom_all_models.dart';

class ClassroomRepositoryImpl implements ClassroomRepository {
  ClassroomRepositoryImpl(this._remoteDataSource);

  final ClassroomRemoteDataSource _remoteDataSource;

  @override
  Future<List<Classroom>> getActiveClassrooms({
    required String schoolCode,
  }) async {
    final response = await _remoteDataSource.getActiveClassrooms(
      schoolCode: schoolCode,
    );

    return response.items
        .map(
          (model) => Classroom(
            code: model.code,
            name: model.name,
          ),
        )
        .toList();
  }
}

