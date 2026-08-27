import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_profile_query.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_profile_response.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/fetch_student_attendance_profile_usecase.dart';

const _query = AttendanceProfileQuery(
  studentCode: 'STU-1',
  fromAttendanceDate: '2026-08-01',
  toAttendanceDate: '2026-08-27',
  page: 0,
  size: 100,
);

class _FakeAttendanceRepository implements AttendanceRepository {
  AttendanceProfileQuery? capturedQuery;
  StudentAttendanceProfileResponse? resultToReturn;
  Object? errorToThrow;

  @override
  Future<StudentAttendanceProfileResponse?> fetchStudentAttendanceProfile({
    required AttendanceProfileQuery query,
  }) async {
    capturedQuery = query;
    if (errorToThrow != null) throw errorToThrow!;
    return resultToReturn;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  group('FetchStudentAttendanceProfileUseCase', () {
    late _FakeAttendanceRepository repo;
    late FetchStudentAttendanceProfileUseCase useCase;

    setUp(() {
      repo = _FakeAttendanceRepository();
      useCase = FetchStudentAttendanceProfileUseCase(repo);
    });

    test('forwards query and returns the repository result',
        () async {
      final expected = StudentAttendanceProfileResponse.fromJson(
        const <String, dynamic>{},
      );
      repo.resultToReturn = expected;

      final result = await useCase(query: _query);

      expect(result, same(expected));
      expect(repo.capturedQuery, same(_query));
    });

    test('propagates repository errors unchanged', () {
      final failure = Exception('network down');
      repo.errorToThrow = failure;

      expect(
        () => useCase(query: _query),
        throwsA(same(failure)),
      );
    });
  });
}
