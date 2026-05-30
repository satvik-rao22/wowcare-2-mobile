import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../widgets/models/student_models.dart';

part 'select_students_state.dart';

/// Owns the select-students screen state: the student list, classroom/tag
/// filters, search query, and the selected-id set. Data is dummy today; swap
/// [initialize] for a repository call when billing has a backend.
class SelectStudentsCubit extends Cubit<SelectStudentsState> {
  SelectStudentsCubit() : super(const SelectStudentsState.initial());

  void initialize() {
    final reading = Tag(id: 1, name: 'Reading');
    final sports = Tag(id: 2, name: 'Sports');
    final arts = Tag(id: 3, name: 'Arts');

    final students = <Student>[
      Student(id: 1, fullName: 'Alex Johnson', roomName: 'Room 101', roomId: 101, tags: [reading, sports]),
      Student(id: 2, fullName: 'Maria Gomez', roomName: 'Room 102', roomId: 102, tags: [arts]),
      Student(id: 3, fullName: 'Liam Chen', roomName: 'Room 101', roomId: 101, tags: [sports]),
      Student(id: 4, fullName: 'Sophia Patel', roomName: 'Room 103', roomId: 103, tags: [reading, arts]),
      Student(id: 5, fullName: 'Noah Smith', roomName: 'Room 102', roomId: 102, tags: [reading]),
      Student(id: 6, fullName: 'Emma Brown', roomName: 'Room 104', roomId: 104, tags: [sports, arts]),
    ];

    final classroomSet = <String>{};
    for (final s in students) {
      if (s.roomName != null) classroomSet.add(s.roomName!);
    }
    final classrooms = ['Select Classroom', ...classroomSet.toList()..sort()];

    final tagSet = <String>{};
    for (final s in students) {
      for (final t in s.tags) {
        tagSet.add(t.name);
      }
    }
    final tags = ['Select Tags', ...tagSet.toList()..sort()];

    emit(state.copyWith(
      students: students,
      classrooms: classrooms,
      tags: tags,
      isLoading: false,
    ));
  }

  void setSearchQuery(String query) =>
      emit(state.copyWith(searchQuery: query));

  void setClassroom(String value) =>
      emit(state.copyWith(selectedClassroom: value));

  void setTag(String value) => emit(state.copyWith(selectedTag: value));

  void clearAll() {
    emit(state.copyWith(
      searchQuery: '',
      selectedClassroom: state.classrooms.first,
      selectedTag: state.tags.first,
      selectedStudentIds: const <int>{},
    ));
  }

  void toggleStudent(int id) {
    final ids = Set<int>.from(state.selectedStudentIds);
    if (!ids.add(id)) ids.remove(id);
    emit(state.copyWith(selectedStudentIds: ids));
  }

  void setStudentSelected(int id, bool selected) {
    final ids = Set<int>.from(state.selectedStudentIds);
    if (selected) {
      ids.add(id);
    } else {
      ids.remove(id);
    }
    emit(state.copyWith(selectedStudentIds: ids));
  }

  /// Selects or clears every id in [filteredIds] (the currently visible rows).
  void setAllSelected(Iterable<int> filteredIds, bool selected) {
    final ids = Set<int>.from(state.selectedStudentIds);
    if (selected) {
      ids.addAll(filteredIds);
    } else {
      ids.removeAll(filteredIds);
    }
    emit(state.copyWith(selectedStudentIds: ids));
  }

  List<Student> get selectedStudents => state.students
      .where((s) => state.selectedStudentIds.contains(s.id))
      .toList();
}
