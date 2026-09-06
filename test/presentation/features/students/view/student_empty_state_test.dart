import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/presentation/features/students/cubit/student_cubit.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';
import 'package:wowcare/presentation/features/students/view/student_empty_state.dart';

void main() {
  // Baseline: default roster query (Active status, no search, no filters).
  const base = StudentState.initial();

  group('studentListEmptyMessage differentiates WHY the list is empty', () {
    test('genuinely empty roster → "No students found"', () {
      expect(studentListEmptyMessage(base), StudentStrings.noStudentsFound);
    });

    test('search returned nothing → "No students match your search"', () {
      final s = base.copyWith(searchQuery: 'zzz');
      expect(studentListEmptyMessage(s), StudentStrings.noStudentsMatchYourSearch);
    });

    test('a classroom filter matched nothing → "...match the selected filters"', () {
      final s = base.copyWith(classroomCodesFilter: const ['CLS_1']);
      expect(studentListEmptyMessage(s), StudentStrings.noStudentsMatchFilters);
    });

    test('a non-default status filter counts as an active filter', () {
      final s = base.copyWith(statusFilter: 'INACTIVE');
      expect(studentListEmptyMessage(s), StudentStrings.noStudentsMatchFilters);
    });

    test('tag / guardian / attendance filters each count as active', () {
      expect(
        studentListEmptyMessage(base.copyWith(tagCodesFilter: const ['T'])),
        StudentStrings.noStudentsMatchFilters,
      );
      expect(
        studentListEmptyMessage(base.copyWith(guardianCodesFilter: const ['G'])),
        StudentStrings.noStudentsMatchFilters,
      );
      expect(
        studentListEmptyMessage(
          base.copyWith(attendanceStatusesFilter: const ['ABSENT']),
        ),
        StudentStrings.noStudentsMatchFilters,
      );
    });

    test('scoped staff with no accessible classrooms → permission message', () {
      final s = base.copyWith(noAccessibleClassrooms: true);
      expect(studentListEmptyMessage(s), StudentStrings.noClassroomsAssignedEmpty);
    });

    test('an API failure never reaches here — it is NOT "No students found"', () {
      // The screen renders the error+retry branch whenever errorMessage != null;
      // this function is only called for the empty (non-error) branch. Assert the
      // messages are distinct so an error is never shown as an empty roster.
      expect(
        StudentStrings.errorLoadingStudents,
        isNot(StudentStrings.noStudentsFound),
      );
    });
  });

  group('precedence', () {
    test('permission scope beats search and filters', () {
      final s = base.copyWith(
        noAccessibleClassrooms: true,
        searchQuery: 'q',
        statusFilter: 'INACTIVE',
      );
      expect(studentListEmptyMessage(s), StudentStrings.noClassroomsAssignedEmpty);
    });

    test('search beats filters', () {
      final s = base.copyWith(searchQuery: 'q', statusFilter: 'INACTIVE');
      expect(studentListEmptyMessage(s), StudentStrings.noStudentsMatchYourSearch);
    });
  });

  group('studentListHasActiveFilters', () {
    test('default Active-only query has no active filters', () {
      expect(studentListHasActiveFilters(base), isFalse);
    });

    test('whitespace-only field filters do not count', () {
      final s = base.copyWith(firstNameFilter: '   ');
      expect(studentListHasActiveFilters(s), isFalse);
    });
  });
}
