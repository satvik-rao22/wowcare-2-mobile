import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_attendance_profile_response.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/fetch_staff_attendance_profile_usecase.dart';

const _query = <String, dynamic>{
  'staffCode': 'STF-1',
  'fromAttendanceDate': '2026-08-01',
  'toAttendanceDate': '2026-08-27',
  'page': 0,
  'size': 10,
};

class _FakeAttendanceRepository implements AttendanceRepository {
  Map<String, dynamic>? capturedQuery;
  StaffAttendanceProfileResponse? resultToReturn;
  Object? errorToThrow;

  @override
  Future<StaffAttendanceProfileResponse?> fetchStaffAttendanceProfile({
    required Map<String, dynamic> queryParameters,
  }) async {
    capturedQuery = queryParameters;
    if (errorToThrow != null) throw errorToThrow!;
    return resultToReturn;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  group('FetchStaffAttendanceProfileUseCase', () {
    late _FakeAttendanceRepository repo;
    late FetchStaffAttendanceProfileUseCase useCase;

    setUp(() {
      repo = _FakeAttendanceRepository();
      useCase = FetchStaffAttendanceProfileUseCase(repo);
    });

    test('forwards query parameters and returns the repository result',
        () async {
      final expected = StaffAttendanceProfileResponse.fromJson(
        const <String, dynamic>{},
      );
      repo.resultToReturn = expected;

      final result = await useCase(queryParameters: _query);

      expect(result, same(expected));
      expect(repo.capturedQuery, same(_query));
    });

    test('propagates repository errors unchanged', () {
      final failure = Exception('network down');
      repo.errorToThrow = failure;

      expect(
        () => useCase(queryParameters: _query),
        throwsA(same(failure)),
      );
    });
  });
}
