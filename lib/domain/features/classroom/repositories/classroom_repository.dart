import '../entities/classroom.dart';

abstract class ClassroomRepository {
  Future<ClassroomPage> getClassrooms({
    required String schoolCode,
    int page,
    int size,
  });
}


