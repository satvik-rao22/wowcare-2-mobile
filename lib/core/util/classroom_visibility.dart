import 'package:wowcare/domain/features/classroom/entities/classroom.dart';

const String _hiddenClassroomName = 'office';

bool isSelectableClassroomName(String name) {
  return name.trim().toLowerCase() != _hiddenClassroomName;
}

List<Classroom> filterSelectableClassrooms(Iterable<Classroom> classrooms) {
  return classrooms
      .where((c) => isSelectableClassroomName(c.name))
      .toList(growable: false);
}
