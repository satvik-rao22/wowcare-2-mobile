import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/staff/entities/staff_count.dart';
import 'package:wowcare/domain/features/staff/entities/staff_member.dart';
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
import 'package:wowcare/presentation/features/staff/view_model/staff_cubit.dart';

StaffMember _staff(String code) => StaffMember(
  code: code,
  name: code,
  primaryClassroomCode: '',
  allowedClassroomCodes: const <String>[],
  designation: 'TEACHER',
  phoneNumber: '',
  status: 'ACTIVE',
  email: '',
);

StaffPage _page(List<String> codes) => StaffPage(
  items: codes.map(_staff).toList(),
  page: 0,
  size: 10,
  totalPages: 1,
  totalElements: codes.length,
  hasMore: false,
);

class _UnusedRepo implements StaffRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _CountingUseCase extends GetStaffPageUseCase {
  _CountingUseCase() : super(_UnusedRepo());
  int calls = 0;
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
  }) async {
    calls++;
    return _page(['A']);
  }
}

class _ZeroCountUseCase extends GetStaffCountUseCase {
  _ZeroCountUseCase() : super(_UnusedRepo());
  @override
  Future<StaffCount> call({
    required String organizationCode,
    required String schoolCode,
  }) async => const StaffCount(total: 0, active: 0, upcoming: 0);
}

class _FakeStorage implements StorageService {
  @override
  Future<String?> getString(String key) async =>
      key == StorageKeys.schoolCode ? 'SCH-A' : null;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

StaffCubit _buildCubit(GetStaffPageUseCase page) => StaffCubit(
  getStaffPageUseCase: page,
  getStaffCountUseCase: _ZeroCountUseCase(),
  getStaffProfileUseCase: GetStaffProfileUseCase(_UnusedRepo()),
  activateSchoolUserUseCase: ActivateSchoolUserUseCase(_UnusedRepo()),
  deactivateSchoolUserUseCase: DeactivateSchoolUserUseCase(_UnusedRepo()),
  activateOrganizationAdminUseCase: ActivateOrganizationAdminUseCase(
    _UnusedRepo(),
  ),
  deactivateOrganizationAdminUseCase: DeactivateOrganizationAdminUseCase(
    _UnusedRepo(),
  ),
  deleteSchoolUserUseCase: DeleteSchoolUserUseCase(_UnusedRepo()),
  loadCachedStaffPageUseCase: LoadCachedStaffPageUseCase(_UnusedRepo()),
  invalidateCachedStaffPageUseCase: InvalidateCachedStaffPageUseCase(
    _UnusedRepo(),
  ),
  storageService: _FakeStorage(),
);

void main() {
  test('rapid onSearchChanged debounces to a single refresh; the query updates '
      'immediately', () async {
    final useCase = _CountingUseCase();
    final cubit = _buildCubit(useCase)
      ..searchDebounceDelay = const Duration(milliseconds: 30);

    cubit.onSearchChanged('a');
    cubit.onSearchChanged('ab');
    cubit.onSearchChanged('abc');

    // Query reflects the latest keystroke straight away; no request yet.
    expect(cubit.state.searchQuery, 'abc');
    expect(useCase.calls, 0);

    await Future<void>.delayed(const Duration(milliseconds: 60));

    // Exactly one settled refresh fired for the whole burst.
    expect(useCase.calls, 1);
    expect(cubit.state.searchQuery, 'abc');

    await cubit.close();
  });

  test('clearing to empty cancels a pending search fetch', () async {
    final useCase = _CountingUseCase();
    final cubit = _buildCubit(useCase)
      ..searchDebounceDelay = const Duration(milliseconds: 30);

    cubit.onSearchChanged('abc'); // schedules a fetch
    cubit.onSearchChanged(''); // supersedes it; only this one should fire

    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(useCase.calls, 1);
    expect(cubit.state.searchQuery, '');

    await cubit.close();
  });
}
