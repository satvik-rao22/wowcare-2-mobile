import '../entities/classroom.dart';

abstract class ClassroomRepository {
  Future<List<Classroom>> getActiveClassrooms({
    required String schoolCode,
  });
}

