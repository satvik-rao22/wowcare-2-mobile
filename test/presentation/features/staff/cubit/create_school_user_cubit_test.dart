import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/domain/features/staff/entities/create_school_user_result.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/create_school_user_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/get_all_staff_usecase.dart';
import 'package:wowcare/presentation/features/staff/cubit/create_school_user_cubit.dart';

/// Fake [StaffRepository] whose staff-user create parks on an optional gate,
/// then fails — the use case folds that to a Left, so the cubit's success/error
/// emit path is exercised. Everything else throws via [noSuchMethod].
class _FakeRepo implements StaffRepository {
  Completer<CreateSchoolUserResult>? gate;
  int createCalls = 0;

  @override
  Future<CreateSchoolUserResult> createStaffUser({
    String? userCode,
    required String firstName,
    required String lastName,
    required String displayName,
    required String mobile,
    required String email,
    required String organizationCode,
    required String schoolCode,
    required String role,
    required String designation,
    String? status,
    String? primaryClassroomCode,
    List<String>? allowedClassroomCodes,
  }) {
    createCalls++;
    if (gate != null) return gate!.future;
    return Future<CreateSchoolUserResult>.error(Exception('unused'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeStorage implements StorageService {
  @override
  Future<String?> getString(String key) async => 'CTX';
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

CreateSchoolUserCubit _cubit(_FakeRepo repo) => CreateSchoolUserCubit(
  createSchoolUserUseCase: CreateSchoolUserUseCase(repo),
  getAllStaffUseCase: GetAllStaffUseCase(repo),
  storageService: _FakeStorage(),
);

void main() {
  test(
    'a create whose response lands after the cubit is closed does NOT emit '
    '(isClosed guard — no emit-after-close StateError)',
    () async {
      final repo = _FakeRepo()..gate = Completer<CreateSchoolUserResult>();
      final cubit = _cubit(repo);

      // Start the create (emits loading, then parks on the in-flight gate).
      final pending = cubit.create(
        isAdmin: false,
        firstName: 'A',
        lastName: 'B',
        displayName: 'A B',
        mobile: '1',
        email: 'a@b.c',
        role: 'STAFF',
        designation: 'TEACHER',
      );
      await Future<void>.delayed(Duration.zero);
      expect(repo.createCalls, 1);

      // Tear down while the create is in flight, then let the response resolve
      // (as an error, which the use case folds to a Left → error emit that the
      // guard must skip).
      await cubit.close();
      repo.gate!.completeError(Exception('late failure'));

      await expectLater(pending, completes);
      expect(cubit.isClosed, isTrue);
    },
  );
}
