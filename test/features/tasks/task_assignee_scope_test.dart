import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/staff/entities/staff_count.dart';
import 'package:wowcare/domain/features/staff/entities/staff_member.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/get_staff_count_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/get_staff_page_usecase.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_assignee_scope.dart';

/// The Task form's assignee picker must offer every ACTIVE staff member to
/// every persona that can open the form. A staff/teacher persona is NOT
/// narrowed to its own `allowedClassroomCodes` — that filter used to leave the
/// picker showing only the signed-in user. These tests pin the requests the
/// picker load actually issues.
class _FakeStorage implements StorageService {
  _FakeStorage(this._data);

  final Map<String, String> _data;

  @override
  Future<String?> getString(String key) async => _data[key];
  @override
  Future<void> saveString(String key, String value) async => _data[key] = value;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Records every staff-list request and answers from a fixed roster.
class _FakeStaffRepository implements StaffRepository {
  _FakeStaffRepository({required this.total});

  final int total;
  final List<({int page, int size, List<String>? classCodes, String? status})>
      requests = [];

  @override
  Future<StaffPage> getStaffPage({
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
    requests.add((
      page: page,
      size: size,
      classCodes: classCodes,
      status: status,
    ));
    final start = page * size;
    final end = (start + size) > total ? total : (start + size);
    final items = <StaffMember>[
      for (var i = start; i < end; i++)
        StaffMember(
          code: 'STF_$i',
          name: 'Staff $i',
          primaryClassroomCode: '',
          allowedClassroomCodes: const [],
          designation: 'TEACHER',
          phoneNumber: '',
          status: 'ACTIVE',
          email: '',
        ),
    ];
    return StaffPage(
      items: items,
      page: page,
      size: size,
      totalPages: (total / size).ceil(),
      totalElements: total,
      hasMore: end < total,
    );
  }

  @override
  Future<StaffCount> getStaffCount({
    required String organizationCode,
    required String schoolCode,
  }) async =>
      StaffCount(total: total, active: total, upcoming: 0);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

StaffCubit _cubit(_FakeStaffRepository repository) => StaffCubit(
      getStaffPageUseCase: GetStaffPageUseCase(repository),
      getStaffCountUseCase: GetStaffCountUseCase(repository),
      repository: repository,
      storageService: _FakeStorage({
        StorageKeys.schoolCode: 'SCH_1',
        StorageKeys.organizationCode: 'ORG_1',
        // A non-admin staff persona with allowed classrooms: the case that used
        // to be classroom-scoped.
        StorageKeys.activeSchoolRole: 'STAFF',
        StorageKeys.staffType: 'TEACHER',
        StorageKeys.staffAllowedClassroomCodes: '["CLS_1","CLS_2"]',
      }),
    );

void main() {
  group('loadAssignableStaff', () {
    test('never scopes the roster by classroom, even for a teacher persona',
        () async {
      final repository = _FakeStaffRepository(total: 7);
      final cubit = _cubit(repository);

      await loadAssignableStaff(cubit);

      expect(
        repository.requests.every((r) => r.classCodes == null),
        isTrue,
        reason: 'a classroom filter would hide the persona’s colleagues',
      );
      expect(
        cubit.state.items.map((s) => s.code),
        List.generate(7, (i) => 'STF_$i'),
      );
      await cubit.close();
    });

    test('loads ACTIVE staff only', () async {
      final repository = _FakeStaffRepository(total: 3);
      final cubit = _cubit(repository);

      await loadAssignableStaff(cubit);

      expect(repository.requests.map((r) => r.status), everyElement('ACTIVE'));
      await cubit.close();
    });

    test('a school that fits in one page costs a single list request', () async {
      final repository = _FakeStaffRepository(total: 42);
      final cubit = _cubit(repository);

      await loadAssignableStaff(cubit);

      expect(repository.requests.length, 1);
      expect(repository.requests.single.size, 100);
      expect(cubit.state.items, hasLength(42));
      await cubit.close();
    });

    test('a roster larger than one page is paged in completely', () async {
      final repository = _FakeStaffRepository(total: 230);
      final cubit = _cubit(repository);

      await loadAssignableStaff(cubit);

      expect(repository.requests.map((r) => r.page), [0, 1, 2]);
      expect(cubit.state.items, hasLength(230));
      expect(cubit.state.hasMore, isFalse);
      await cubit.close();
    });
  });
}
