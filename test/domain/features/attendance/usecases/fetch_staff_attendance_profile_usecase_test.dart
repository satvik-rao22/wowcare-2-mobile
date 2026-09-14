import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_profile_query.dart';
import 'package:wowcare/data/features/attendance/models/staff_attendance_profile_response_model.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_attendance_profile_response.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/fetch_staff_attendance_profile_usecase.dart';

const _query = AttendanceProfileQuery(
  staffCode: 'STF-1',
  fromAttendanceDate: '2026-08-01',
  toAttendanceDate: '2026-08-27',
  page: 0,
  size: 10,
);

class _FakeAttendanceRepository implements AttendanceRepository {
  AttendanceProfileQuery? capturedQuery;
  StaffAttendanceProfileResponse? resultToReturn;
  Object? errorToThrow;

  @override
  Future<StaffAttendanceProfileResponse?> fetchStaffAttendanceProfile({
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
  group('FetchStaffAttendanceProfileUseCase', () {
    late _FakeAttendanceRepository repo;
    late FetchStaffAttendanceProfileUseCase useCase;

    setUp(() {
      repo = _FakeAttendanceRepository();
      useCase = FetchStaffAttendanceProfileUseCase(repo);
    });

    test(
      'forwards query parameters and returns the repository result',
      () async {
        final expected = StaffAttendanceProfileResponseModel.fromJson(
          const <String, dynamic>{},
        ).toEntity();
        repo.resultToReturn = expected;

        final result = await useCase(query: _query);

        expect(result, same(expected));
        expect(repo.capturedQuery, same(_query));
      },
    );

    test('propagates repository errors unchanged', () {
      final failure = Exception('network down');
      repo.errorToThrow = failure;

      expect(() => useCase(query: _query), throwsA(same(failure)));
    });
  });
}
