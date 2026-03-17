import '../../../../domain/features/classroom/entities/classroom.dart';
import '../../../../domain/features/classroom/repositories/classroom_repository.dart';
import '../../../../domain/features/student_classroom/entities/student_classroom_item.dart';
import '../../../../domain/features/student_classroom/repositories/student_classroom_repository.dart';
import '../datasources/classroom_remote_datasource.dart';

class ClassroomRepositoryImpl implements ClassroomRepository {
  ClassroomRepositoryImpl(this._remoteDataSource, this._studentClassroomRepository);

  final ClassroomRemoteDataSource _remoteDataSource;
  final StudentClassroomRepository _studentClassroomRepository;

  @override
  Future<List<Classroom>> getActiveClassrooms({
    required String schoolCode,
    bool onlyTypeClassroom = true,
  }) async {
    final response = await _remoteDataSource.getActiveClassrooms(
      schoolCode: schoolCode,
      onlyTypeClassroom: onlyTypeClassroom,
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

  @override
  Future<List<StudentClassroomItem>> getClassroomStudents({
    required String schoolCode,
    required String classroomCode,
    String? firstName,
    String? lastName,
    String? search,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    List<String>? status,
    String? attendanceStatus,
    bool refresh = false,
  }) {
    return _studentClassroomRepository.getStudentClassroomList(
      schoolCode: schoolCode,
      classroomCode: classroomCode,
      firstName: firstName,
      lastName: lastName,
      search: search,
      tagCodes: tagCodes,
      guardianCodes: guardianCodes,
      status: status,
      attendanceStatus: attendanceStatus,
      refresh: refresh,
    );
  }
}

