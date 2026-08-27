import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_profile_absent_toggle_query.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_attendance_profile_absent_toggle_response.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/fetch_staff_attendance_profile_absent_toggle_usecase.dart';

const _query = AttendanceProfileAbsentToggleQuery(
  staffCode: 'STF-1',
  fromAbsenceDate: '2026-08-01',
  toAbsenceDate: '2026-08-27',
  page: 0,
  size: 10,
);

class _FakeAttendanceRepository implements AttendanceRepository {
  AttendanceProfileAbsentToggleQuery? capturedQuery;
  StaffAttendanceProfileAbsentToggleResponse? resultToReturn;
  Object? errorToThrow;

  @override
  Future<StaffAttendanceProfileAbsentToggleResponse?>
      fetchStaffAttendanceProfileAbsentToggle({
    required AttendanceProfileAbsentToggleQuery query,
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
  group('FetchStaffAttendanceProfileAbsentToggleUseCase', () {
    late _FakeAttendanceRepository repo;
    late FetchStaffAttendanceProfileAbsentToggleUseCase useCase;

    setUp(() {
      repo = _FakeAttendanceRepository();
      useCase = FetchStaffAttendanceProfileAbsentToggleUseCase(repo);
    });

    test('forwards query parameters and returns the repository result',
        () async {
      final expected = StaffAttendanceProfileAbsentToggleResponse.fromJson(
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
