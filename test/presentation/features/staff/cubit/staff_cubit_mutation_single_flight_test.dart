import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/staff/entities/staff_count.dart';
import 'package:wowcare/domain/features/staff/entities/staff_member.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/get_staff_count_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/get_staff_page_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/get_staff_profile_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/activate_school_user_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/deactivate_school_user_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/activate_organization_admin_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/deactivate_organization_admin_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/delete_school_user_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/load_cached_staff_page_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/invalidate_cached_staff_page_usecase.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';

StaffProfile _profile() => const StaffProfile(
  staffCode: 'S1',
  userCode: 'U1',
  organizationCode: 'ORG-A',
  schoolCode: 'SCH-A',
  firstName: 'Sam',
  lastName: 'Staff',
  fullName: 'Sam Staff',
  email: 'sam@example.com',
  phoneNumber: '000',
  staffType: 'STAFF',
  status: 'ACTIVE',
  designation: 'TEACHER',
  allowedClassroomCodes: <String>[],
  address: StaffProfileAddress(),
  workSchedules: <StaffProfileWorkSchedule>[],
  breakSchedules: <StaffProfileBreakSchedule>[],
);

StaffPage _emptyPage() => const StaffPage(
  items: <StaffMember>[],
  page: 0,
  size: 10,
  totalPages: 1,
  totalElements: 0,
  hasMore: false,
);

/// Repository whose deactivateSchoolUser blocks on a gate and counts
/// invocations. getStaffProfile resolves immediately so the mutation reaches
/// the (gated) underlying deactivate call.
class _CountingRepo implements StaffRepository {
  int deactivateCalls = 0;
  int activateCalls = 0;
  int deleteCalls = 0;
  final Completer<String> gate = Completer<String>();

  @override
  Future<StaffProfile> getStaffProfile({
    required String staffCode,
    bool forEditStaff = false,
    bool forceRefresh = false,
  }) async => _profile();

  @override
  Future<String> deactivateSchoolUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  }) {
    deactivateCalls++;
    return gate.future;
  }

  @override
  Future<String> activateSchoolUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  }) async {
    activateCalls++;
    return 'activated';
  }

  @override
  Future<String> deleteSchoolUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  }) async {
    deleteCalls++;
    return 'deleted';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _PageUseCase extends GetStaffPageUseCase {
  _PageUseCase() : super(_CountingRepo());
  @override
  Future<StaffPage> call({
    required String organizationCode,
    required String schoolCode,
    String? code,
    int page = 0,
    int size = 10,
    String? status,
    String? designation,
    String? search,
    List<String>? primaryClassroomCodes,
    List<String>? classCodes,
    String? sortBy,
    List<String>? attendanceStatuses,
  }) async => _emptyPage();
}

class _CountUseCase extends GetStaffCountUseCase {
  _CountUseCase() : super(_CountingRepo());
  @override
  Future<StaffCount> call({
    required String organizationCode,
    required String schoolCode,
  }) async => const StaffCount(total: 0, active: 0, upcoming: 0);
}

class _FakeStorage implements StorageService {
  @override
  Future<String?> getString(String key) async {
    if (key == StorageKeys.schoolCode) return 'SCH-A';
    if (key == StorageKeys.organizationCode) return 'ORG-A';
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

/// Builds a StaffCubit whose mutation paths route through REAL use cases that
/// wrap the SAME counting repo, so assertions on the underlying repo call
/// counts prove the mutations flow cubit -> use case -> repository.
StaffCubit _buildCubit(_CountingRepo repo) => StaffCubit(
  getStaffPageUseCase: _PageUseCase(),
  getStaffCountUseCase: _CountUseCase(),
  getStaffProfileUseCase: GetStaffProfileUseCase(repo),
  activateSchoolUserUseCase: ActivateSchoolUserUseCase(repo),
  deactivateSchoolUserUseCase: DeactivateSchoolUserUseCase(repo),
  activateOrganizationAdminUseCase: ActivateOrganizationAdminUseCase(repo),
  deactivateOrganizationAdminUseCase: DeactivateOrganizationAdminUseCase(repo),
  deleteSchoolUserUseCase: DeleteSchoolUserUseCase(repo),
  loadCachedStaffPageUseCase: LoadCachedStaffPageUseCase(repo),
  invalidateCachedStaffPageUseCase: InvalidateCachedStaffPageUseCase(repo),
  storageService: _FakeStorage(),
);

void main() {
  test(
    'double deactivate of the same staff issues exactly ONE underlying repo call '
    '(cubit single-flight, independent of any UI disabling)',
    () async {
      final repo = _CountingRepo();
      final cubit = _buildCubit(repo);

      // Two rapid taps on the same staff member's deactivate.
      final f1 = cubit.deactivateStaff('S1');
      final f2 = cubit.deactivateStaff('S1');

      // The second call is deduped to the first's in-flight future.
      expect(identical(f1, f2), isTrue);

      // Let the first operation resolve the profile and reach the repository.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(repo.deactivateCalls, 1);

      // Complete the mutation; the ensuing refresh loads an empty page.
      repo.gate.complete('deactivated');
      await Future.wait<String>([f1, f2]);

      expect(repo.deactivateCalls, 1);
      await cubit.close();
    },
  );

  test(
    'activateStaff routes through the activate use case to the repository',
    () async {
      final repo = _CountingRepo();
      final cubit = _buildCubit(repo);

      final message = await cubit.activateStaff('S1');

      expect(repo.activateCalls, 1);
      expect(message, 'activated');
      await cubit.close();
    },
  );

  test(
    'deleteStaff routes through the delete use case to the repository',
    () async {
      final repo = _CountingRepo();
      final cubit = _buildCubit(repo);

      final message = await cubit.deleteStaff('S1');

      expect(repo.deleteCalls, 1);
      expect(message, 'deleted');
      await cubit.close();
    },
  );
}
