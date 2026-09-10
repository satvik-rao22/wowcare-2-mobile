import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_map_usecase.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/domain/features/classroom/repositories/classroom_repository.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/domain/features/scheduling/entities/staff_shift.dart'
    as sched;
import 'package:wowcare/domain/features/scheduling/entities/staff_shift_hours_entry.dart';
import 'package:wowcare/domain/features/scheduling/repositories/staff_shift_repository.dart';
import 'package:wowcare/domain/features/scheduling/usecases/bootstrap_scheduling_school_timezone_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/delete_staff_shift_series_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/delete_staff_shift_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/get_school_staff_shifts_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/get_staff_shift_by_code_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/get_staff_shift_hours_range_usecase.dart';
import 'package:wowcare/domain/features/staff/entities/school_regular_schedule_day.dart';
import 'package:wowcare/domain/features/staff/entities/staff_member.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/get_all_staff_usecase.dart';
import 'package:wowcare/presentation/features/scheduling/view_model/scheduling_staff_list_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/view_model/staff_scheduling_cubit.dart';

/// Storage stub: only the keys the cubit's staff-code / school-scope
/// resolution actually reads. Anything else throws via [noSuchMethod].
class _FakeStorageService implements StorageService {
  _FakeStorageService({this.staffCode, this.staffCodeUser});

  static const String userCode = 'USR-1';

  /// Cached `staffCode` for the logged-in user (null = no staff mapping).
  String? staffCode;
  String? staffCodeUser;

  final List<String> savedKeys = <String>[];

  @override
  Future<String?> getString(String key) async {
    switch (key) {
      case StorageKeys.userCode:
        return userCode;
      case StorageKeys.organizationCode:
        return 'ORG-1';
      case StorageKeys.schoolCode:
        return 'SCH-1';
      case StorageKeys.staffCode:
        return staffCode;
      case StorageKeys.staffCodeUser:
        return staffCodeUser;
      case StorageKeys.roles:
        return '[]';
      default:
        return null;
    }
  }

  @override
  Future<void> saveString(String key, String value) async {
    savedKeys.add(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _UnusedApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _UnusedShiftRepo implements StaffShiftRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _UnusedClassroomRepo implements ClassroomRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _UnusedAttendanceRepo implements AttendanceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

/// Staff repo used for both the school-hours lookup and the `/staff/code`
/// fallback the logged-in-staff-code resolution makes on a cache miss.
class _FakeStaffRepo implements StaffRepository {
  _FakeStaffRepo({this.staffCodeForUser});

  /// Value returned by the `/staff/code` lookup (null = no mapping).
  final String? staffCodeForUser;
  int staffCodeLookups = 0;

  @override
  Future<List<SchoolRegularScheduleDay>> getSchoolRegularSchedules({
    required String schoolCode,
  }) async =>
      const <SchoolRegularScheduleDay>[];

  @override
  Future<String?> getStaffCodeForUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
  }) async {
    staffCodeLookups++;
    return staffCodeForUser;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

/// Roster source — returns a fixed list without touching the staff API.
class _FakeStaffListCubit extends SchedulingStaffListCubit {
  _FakeStaffListCubit(this.roster, StorageService storage)
      : super(
          getAllStaffUseCase: GetAllStaffUseCase(_FakeStaffRepo()),
          storageService: storage,
        );

  final List<StaffMember> roster;

  @override
  Future<List<StaffMember>> load({
    List<String> statuses = const ['ACTIVE', 'UPCOMING'],
    bool force = false,
  }) async =>
      roster;
}

class _FakeSchoolShiftsUseCase extends GetSchoolStaffShiftsUseCase {
  _FakeSchoolShiftsUseCase() : super(_UnusedShiftRepo());

  @override
  Future<List<sched.StaffShift>> call({
    required String schoolCode,
    required String organizationCode,
    required DateTime dateFrom,
    required DateTime dateTo,
    String? classroomCode,
    List<String> shiftStatus = const <String>[],
  }) async =>
      const <sched.StaffShift>[];
}

class _FakeHoursRangeUseCase extends GetStaffShiftHoursRangeUseCase {
  _FakeHoursRangeUseCase() : super(_UnusedShiftRepo());

  /// Staff codes the summary call was made for, in order.
  final List<String> requestedStaffCodes = <String>[];

  @override
  Future<List<StaffShiftHoursEntry>> call({
    required String schoolCode,
    required String organizationCode,
    required DateTime startDate,
    required DateTime endDate,
    required bool publishedOnly,
    List<String> staffCodes = const <String>[],
  }) async {
    requestedStaffCodes.addAll(staffCodes);
    return const <StaffShiftHoursEntry>[];
  }
}

class _FakeActiveClassroomsUseCase extends GetActiveClassroomsUseCase {
  _FakeActiveClassroomsUseCase() : super(_UnusedClassroomRepo());

  @override
  Future<List<Classroom>> call({
    required String schoolCode,
    bool onlyTypeClassroom = true,
    String? typeOverride,
  }) async =>
      const <Classroom>[];
}

class _FakeSignInStatusUseCase extends GetStaffTodaySignInStatusMapUseCase {
  _FakeSignInStatusUseCase() : super(_UnusedAttendanceRepo());

  @override
  Future<Map<String, String>> call({required List<String> staffCodes}) async =>
      const <String, String>{};
}

StaffMember _staff(String code, String name) => StaffMember(
      code: code,
      name: name,
      primaryClassroomCode: '',
      allowedClassroomCodes: const <String>[],
      designation: 'Teacher',
      phoneNumber: '',
      status: 'ACTIVE',
      email: '',
    );

void main() {
  late _FakeHoursRangeUseCase hoursUseCase;

  StaffSchedulingCubit buildCubit({
    required List<StaffMember> roster,
    required _FakeStorageService storage,
    _FakeStaffRepo? staffRepo,
  }) {
    hoursUseCase = _FakeHoursRangeUseCase();
    return StaffSchedulingCubit(
      schedulingStaffListCubit: _FakeStaffListCubit(roster, storage),
      getSchoolStaffShiftsUseCase: _FakeSchoolShiftsUseCase(),
      getStaffShiftHoursRangeUseCase: hoursUseCase,
      getActiveClassroomsUseCase: _FakeActiveClassroomsUseCase(),
      staffRepository: staffRepo ?? _FakeStaffRepo(),
      storageService: storage,
      getStaffTodaySignInStatusMapUseCase: _FakeSignInStatusUseCase(),
      getStaffShiftByCodeUseCase: GetStaffShiftByCodeUseCase(
        _UnusedShiftRepo(),
      ),
      deleteStaffShiftUseCase: DeleteStaffShiftUseCase(_UnusedShiftRepo()),
      deleteStaffShiftSeriesUseCase: DeleteStaffShiftSeriesUseCase(
        _UnusedShiftRepo(),
      ),
      bootstrapSchedulingSchoolTimezoneUseCase:
          BootstrapSchedulingSchoolTimezoneUseCase(
        storage: storage,
        apiClient: _UnusedApiClient(),
      ),
    );
  }

  // Deliberately NOT alphabetical-first, so "logged-in user" and "first row"
  // can't be satisfied by the same code.
  final roster = <StaffMember>[
    _staff('STF-A', 'Ashish Mhatre'),
    _staff('STF-S', 'Santosh Kondilakar'),
    _staff('STF-Z', 'Zara Khan'),
  ];

  test('initial load selects the logged-in staff member, not the first row',
      () async {
    final storage = _FakeStorageService(
      staffCode: 'STF-S',
      staffCodeUser: 'USR-1',
    );
    final cubit = buildCubit(roster: roster, storage: storage);
    addTearDown(cubit.close);

    await cubit.loadInitial();

    expect(cubit.state.selectedStaffCode, 'STF-S');
    expect(cubit.state.selectedStaff?.name, 'Santosh Kondilakar');
    // The day summary was fetched for the logged-in user, not the first row.
    expect(hoursUseCase.requestedStaffCodes, contains('STF-S'));
    expect(hoursUseCase.requestedStaffCodes, isNot(contains('STF-A')));
  });

  test('falls back to /staff/code when no staffCode is cached', () async {
    final storage = _FakeStorageService();
    final staffRepo = _FakeStaffRepo(staffCodeForUser: 'STF-Z');
    final cubit = buildCubit(
      roster: roster,
      storage: storage,
      staffRepo: staffRepo,
    );
    addTearDown(cubit.close);

    await cubit.loadInitial();

    expect(staffRepo.staffCodeLookups, greaterThan(0));
    expect(cubit.state.selectedStaffCode, 'STF-Z');
  });

  test('falls back to the first row when the user has no staff record',
      () async {
    final storage = _FakeStorageService();
    final cubit = buildCubit(roster: roster, storage: storage);
    addTearDown(cubit.close);

    await cubit.loadInitial();

    expect(cubit.state.selectedStaffCode, 'STF-A');
  });

  test('falls back to the first row when the logged-in staff is not in the '
      'roster', () async {
    final storage = _FakeStorageService(
      staffCode: 'STF-NOT-IN-SCHOOL',
      staffCodeUser: 'USR-1',
    );
    final cubit = buildCubit(roster: roster, storage: storage);
    addTearDown(cubit.close);

    await cubit.loadInitial();

    expect(cubit.state.selectedStaffCode, 'STF-A');
  });

  test('an explicit dropdown pick survives a refresh', () async {
    final storage = _FakeStorageService(
      staffCode: 'STF-S',
      staffCodeUser: 'USR-1',
    );
    final cubit = buildCubit(roster: roster, storage: storage);
    addTearDown(cubit.close);

    await cubit.loadInitial();
    cubit.selectStaffByCode('STF-Z');
    await cubit.refresh();

    expect(cubit.state.selectedStaffCode, 'STF-Z');
  });

  test('STAFF persona is still narrowed to their own row', () async {
    final storage = _FakeStorageService(
      staffCode: 'STF-S',
      staffCodeUser: 'USR-1',
    );
    final cubit = buildCubit(roster: roster, storage: storage);
    addTearDown(cubit.close);

    await cubit.applyPersonaScope(isStaffPersona: true);
    await cubit.loadInitial();

    expect(cubit.state.isStaffPersonaScope, isTrue);
    expect(cubit.state.staffList.map((s) => s.code), <String>['STF-S']);
    expect(cubit.state.selectedStaffCode, 'STF-S');
  });
}
