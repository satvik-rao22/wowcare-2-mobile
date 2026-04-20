import '../../../../domain/features/classroom/entities/classroom.dart';
import '../../../../domain/features/classroom/entities/classroom_details.dart';
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
  Future<ClassroomDetails> getClassroomByCode({
    required String code,
  }) async {
    final response = await _remoteDataSource.getClassroomByCode(code: code);
    final details = response.data;

    if (details == null) {
      throw Exception('Classroom details not found');
    }

    return ClassroomDetails(
      code: details.code,
      name: details.name,
      capacity: details.capacity,
      studentsPerTeacher: details.studentsPerTeacher,
      minAgeYear: details.minAgeYear,
      minAgeMonths: details.minAgeMonths,
      maxAgeYear: details.maxAgeYear,
      maxAgeMonths: details.maxAgeMonths,
      type: details.type,
      school: details.school,
      status: details.status,
      createdBy: details.createdBy,
      createdAt: details.createdAt,
      updatedBy: details.updatedBy,
      updatedAt: details.updatedAt,
    );
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

