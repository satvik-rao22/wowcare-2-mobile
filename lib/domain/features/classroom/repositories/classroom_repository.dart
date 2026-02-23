import '../entities/classroom.dart';

abstract class ClassroomRepository {
  Future<List<Classroom>> getActiveClassrooms({
    required String schoolCode,
    /// When true, restricts results to type=CLASSROOM.
    /// When false, omits the type filter.
    bool onlyTypeClassroom,
  });
}

