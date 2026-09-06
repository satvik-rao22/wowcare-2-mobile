import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/cache_manager.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_transfer_form_list_usecase.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/view_model/student_transfer_selection_cubit.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/student_transfer_form.dart';

/// The selection methods under test never touch any dependency — they only
/// mutate in-memory state — so these fakes throw if anything unexpectedly
/// reaches out to them.
class _FakeStorage implements StorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeCache implements CacheManager {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeActiveClassrooms implements GetActiveClassroomsUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeTagMap implements GetTagNameCodeMapForSchoolUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeTransferList implements GetStudentTransferFormListUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

StudentEntity _student(String code, {String room = 'Room A'}) => StudentEntity(
  id: code.hashCode,
  studentCode: code,
  fullName: 'Name $code',
  roomId: 0,
  roomName: room,
  classroomCode: '',
);

void main() {
  group('StudentTransferSelectionCubit selection state', () {
    late StudentTransferSelectionCubit cubit;

    setUp(() {
      cubit = StudentTransferSelectionCubit(
        storageService: _FakeStorage(),
        cacheManager: _FakeCache(),
        getActiveClassroomsUseCase: _FakeActiveClassrooms(),
        getTagNameCodeMapForSchoolUseCase: _FakeTagMap(),
        getStudentTransferFormListUseCase: _FakeTransferList(),
      );
    });

    tearDown(() => cubit.close());

    test('initial state has empty selections', () {
      expect(cubit.state.selectedStudents, isEmpty);
      expect(cubit.state.selectedClassroomNames, isEmpty);
      expect(cubit.state.selectedTagNames, isEmpty);
    });

    test('toggleStudent adds when absent and removes when present', () {
      final s = _student('STU-1');

      cubit.toggleStudent(s);
      expect(cubit.state.selectedStudents, contains(s));
      expect(cubit.state.selectedStudents, hasLength(1));

      cubit.toggleStudent(s);
      expect(cubit.state.selectedStudents, isEmpty);
    });

    test('toggleStudent matches by studentCode value-equality', () {
      cubit.toggleStudent(_student('STU-1', room: 'Room A'));
      // Same code, different instance/room — StudentEntity == is by code.
      cubit.toggleStudent(_student('STU-1', room: 'Room B'));
      expect(cubit.state.selectedStudents, isEmpty);
    });

    test(
      'setStudentsSelected(true) adds all visible; (false) removes them',
      () {
        final visible = [_student('A'), _student('B'), _student('C')];

        cubit.setStudentsSelected(visible, true);
        expect(cubit.state.selectedStudents, hasLength(3));
        expect(
          cubit.state.selectedStudents.map((s) => s.studentCode),
          containsAll(<String>['A', 'B', 'C']),
        );

        // Deselect only a subset of the visible list.
        cubit.setStudentsSelected([_student('A'), _student('C')], false);
        expect(
          cubit.state.selectedStudents.map((s) => s.studentCode).toList(),
          <String>['B'],
        );
      },
    );

    test(
      'removeStudentsWhere removes every student matching the predicate',
      () {
        cubit.setStudentsSelected([
          _student('A', room: 'Room A'),
          _student('B', room: 'Room B'),
          _student('C', room: 'Room A'),
        ], true);

        // Remove everyone NOT in Room A (i.e. keep only Room A) — mirrors the
        // View's old build-time prune `removeWhere((s) => !present)`.
        cubit.removeStudentsWhere((s) => s.roomName != 'Room A');

        expect(
          cubit.state.selectedStudents.map((s) => s.studentCode).toSet(),
          <String>{'A', 'C'},
        );
      },
    );

    test('setSelectedClassrooms replaces the classroom filter', () {
      cubit.setSelectedClassrooms(['Room A']);
      expect(cubit.state.selectedClassroomNames, <String>['Room A']);

      cubit.setSelectedClassrooms(['Room B', 'Room C']);
      expect(cubit.state.selectedClassroomNames, <String>['Room B', 'Room C']);
    });

    test('setSelectedTags replaces the tag filter', () {
      cubit.setSelectedTags(['Allergy']);
      expect(cubit.state.selectedTagNames, <String>['Allergy']);

      cubit.setSelectedTags(<String>[]);
      expect(cubit.state.selectedTagNames, isEmpty);
    });

    test('seedDefaultClassroom seeds a single classroom name', () {
      cubit.seedDefaultClassroom('Room A');
      expect(cubit.state.selectedClassroomNames, <String>['Room A']);
    });

    test('emits new state instances (equality reflects selection changes)', () {
      final before = cubit.state;
      cubit.toggleStudent(_student('X'));
      expect(cubit.state, isNot(equals(before)));
    });
  });
}
