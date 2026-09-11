import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_in_status_at_time_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_sign_in_status_at_time_usecase.dart';

class _FakeAttendanceRepository implements AttendanceRepository {
  String? capturedClassroomCode;
  List<String>? capturedStudentCodes;
  List<String>? capturedStaffCodes;
  DateTime? capturedInstantUtc;
  int studentCalls = 0;
  int staffCalls = 0;
  Map<String, bool> studentResult = const <String, bool>{};
  Map<String, bool> staffResult = const <String, bool>{};

  @override
  Future<Map<String, bool>> getStudentSignInStatusAtTime({
    required String classroomCode,
    required List<String> studentCodes,
    required DateTime instantUtc,
  }) async {
    studentCalls++;
    capturedClassroomCode = classroomCode;
    capturedStudentCodes = studentCodes;
    capturedInstantUtc = instantUtc;
    return studentResult;
  }

  @override
  Future<Map<String, bool>> getStaffSignInStatusAtTime({
    required String classroomCode,
    required List<String> staffCodes,
    required DateTime instantUtc,
  }) async {
    staffCalls++;
    capturedClassroomCode = classroomCode;
    capturedStaffCodes = staffCodes;
    capturedInstantUtc = instantUtc;
    return staffResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  final instant = DateTime.utc(2026, 8, 27, 10, 30);

  group('GetStudentSignInStatusAtTimeUseCase', () {
    late _FakeAttendanceRepository repo;
    late GetStudentSignInStatusAtTimeUseCase useCase;

    setUp(() {
      repo = _FakeAttendanceRepository();
      useCase = GetStudentSignInStatusAtTimeUseCase(repo);
    });

    test('delegates to the repository and returns its map', () async {
      repo.studentResult = const <String, bool>{'STU-1': true, 'STU-2': false};

      final result = await useCase(
        classroomCode: 'CLS-A',
        studentCodes: <String>['STU-1', 'STU-2'],
        instantUtc: instant,
      );

      expect(repo.studentCalls, 1);
      expect(repo.capturedClassroomCode, 'CLS-A');
      expect(repo.capturedStudentCodes, <String>['STU-1', 'STU-2']);
      expect(repo.capturedInstantUtc, instant);
      expect(result, const <String, bool>{'STU-1': true, 'STU-2': false});
    });
  });

  group('GetStaffSignInStatusAtTimeUseCase', () {
    late _FakeAttendanceRepository repo;
    late GetStaffSignInStatusAtTimeUseCase useCase;

    setUp(() {
      repo = _FakeAttendanceRepository();
      useCase = GetStaffSignInStatusAtTimeUseCase(repo);
    });

    test('delegates to the repository and returns its map', () async {
      repo.staffResult = const <String, bool>{'STF-1': true};

      final result = await useCase(
        classroomCode: 'CLS-B',
        staffCodes: <String>['STF-1'],
        instantUtc: instant,
      );

      expect(repo.staffCalls, 1);
      expect(repo.capturedClassroomCode, 'CLS-B');
      expect(repo.capturedStaffCodes, <String>['STF-1']);
      expect(repo.capturedInstantUtc, instant);
      expect(result, const <String, bool>{'STF-1': true});
    });
  });
}
