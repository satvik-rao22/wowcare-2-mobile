import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_absent_view_response.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_attendance_absent_view_usecase.dart';

class _FakeAttendanceRepository implements AttendanceRepository {
  String? capturedFrom;
  String? capturedTo;
  List<String>? capturedClassroomCodes;
  List<String>? capturedTagCodes;
  String? capturedSearch;
  int? capturedPage;
  int? capturedSize;
  List<String>? capturedSort;
  StudentAttendanceAbsentViewResponse? resultToReturn;
  Object? errorToThrow;

  @override
  Future<StudentAttendanceAbsentViewResponse?> getStudentAttendanceAbsentView({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  }) async {
    capturedFrom = fromAbsenceDate;
    capturedTo = toAbsenceDate;
    capturedClassroomCodes = classroomCodes;
    capturedTagCodes = tagCodes;
    capturedSearch = search;
    capturedPage = page;
    capturedSize = size;
    capturedSort = sort;
    if (errorToThrow != null) throw errorToThrow!;
    return resultToReturn;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  group('GetStudentAttendanceAbsentViewUseCase', () {
    late _FakeAttendanceRepository repo;
    late GetStudentAttendanceAbsentViewUseCase useCase;

    setUp(() {
      repo = _FakeAttendanceRepository();
      useCase = GetStudentAttendanceAbsentViewUseCase(repo);
    });

    test('forwards every parameter and returns the repository result',
        () async {
      const expected =
          StudentAttendanceAbsentViewResponse(data: <String, dynamic>{'k': 'v'});
      repo.resultToReturn = expected;

      final result = await useCase(
        fromAbsenceDate: '2026-08-01',
        toAbsenceDate: '2026-08-27',
        classroomCodes: const ['CLS_1'],
        tagCodes: const ['TAG_1'],
        search: 'john',
        page: 2,
        size: 25,
        sort: const ['studentName,asc'],
      );

      expect(result, same(expected));
      expect(repo.capturedFrom, '2026-08-01');
      expect(repo.capturedTo, '2026-08-27');
      expect(repo.capturedClassroomCodes, const ['CLS_1']);
      expect(repo.capturedTagCodes, const ['TAG_1']);
      expect(repo.capturedSearch, 'john');
      expect(repo.capturedPage, 2);
      expect(repo.capturedSize, 25);
      expect(repo.capturedSort, const ['studentName,asc']);
    });

    test('forwards default page/size when omitted', () async {
      await useCase(
        fromAbsenceDate: '2026-08-01',
        toAbsenceDate: '2026-08-27',
      );

      expect(repo.capturedPage, 0);
      expect(repo.capturedSize, 10);
      expect(repo.capturedClassroomCodes, isNull);
      expect(repo.capturedSort, isNull);
    });

    test('propagates repository errors unchanged', () {
      final failure = Exception('network down');
      repo.errorToThrow = failure;

      expect(
        () => useCase(
          fromAbsenceDate: '2026-08-01',
          toAbsenceDate: '2026-08-27',
        ),
        throwsA(same(failure)),
      );
    });
  });
}
