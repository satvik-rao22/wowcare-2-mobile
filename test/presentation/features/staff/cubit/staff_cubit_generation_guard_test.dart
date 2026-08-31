import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
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
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';

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

StaffPage _page(List<String> codes, {int page = 0, bool hasMore = false}) =>
    StaffPage(
      items: codes.map(_staff).toList(),
      page: page,
      size: 10,
      totalPages: hasMore ? page + 2 : page + 1,
      totalElements: codes.length,
      hasMore: hasMore,
    );

class _UnusedRepo implements StaffRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _QueueUseCase extends GetStaffPageUseCase {
  _QueueUseCase() : super(_UnusedRepo());
  final List<Object> _queue = <Object>[];
  void enqueue(Object response) => _queue.add(response);

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
  }) {
    final r = _queue.isNotEmpty ? _queue.removeAt(0) : _page(const []);
    if (r is Completer<StaffPage>) return r.future;
    return Future<StaffPage>.value(r as StaffPage);
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
  _FakeStorage(this.schoolCode);
  String schoolCode;
  @override
  Future<String?> getString(String key) async =>
      key == StorageKeys.schoolCode ? schoolCode : null;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  late _QueueUseCase page;
  late _FakeStorage storage;
  late StaffCubit cubit;

  setUp(() {
    page = _QueueUseCase();
    storage = _FakeStorage('SCH-A');
    cubit = StaffCubit(
      getStaffPageUseCase: page,
      getStaffCountUseCase: _ZeroCountUseCase(),
      // Mutation use cases are not exercised by these generation-guard tests;
      // wrap the unused repo so they are never invoked.
      getStaffProfileUseCase: GetStaffProfileUseCase(_UnusedRepo()),
      activateSchoolUserUseCase: ActivateSchoolUserUseCase(_UnusedRepo()),
      deactivateSchoolUserUseCase: DeactivateSchoolUserUseCase(_UnusedRepo()),
      activateOrganizationAdminUseCase:
          ActivateOrganizationAdminUseCase(_UnusedRepo()),
      deactivateOrganizationAdminUseCase:
          DeactivateOrganizationAdminUseCase(_UnusedRepo()),
      deleteSchoolUserUseCase: DeleteSchoolUserUseCase(_UnusedRepo()),
      repository: _UnusedRepo(),
      storageService: storage,
    );
  });

  tearDown(() => cubit.close());

  test('happy path: refresh loads a single page', () async {
    page.enqueue(_page(['A', 'B']));
    await cubit.refresh();
    expect(cubit.state.items.map((s) => s.code), ['A', 'B']);
    expect(cubit.state.isRefreshing, isFalse);
  });

  test('wrong-school: a response is DISCARDED if the school changed mid-flight',
      () async {
    final gate = Completer<StaffPage>();
    page.enqueue(gate);
    final future = cubit.refresh(); // starts under SCH-A
    await Future<void>.delayed(Duration.zero);
    storage.schoolCode = 'SCH-B'; // live switch
    gate.complete(_page(['SCH-A-STAFF']));
    await future;
    expect(cubit.state.items, isEmpty);
  });

  test('loadNextPage superseded by a filter change is DISCARDED', () async {
    page
      ..enqueue(_page(['A', 'B'], page: 0, hasMore: true))
      ..enqueue(_page(['C', 'D'], page: 1, hasMore: true));
    await cubit.refresh();
    expect(cubit.state.items.map((s) => s.code), ['A', 'B', 'C', 'D']);

    final gate = Completer<StaffPage>();
    page.enqueue(gate);
    final future = cubit.loadNextPage();
    await Future<void>.delayed(Duration.zero);
    cubit.updateFilters(status: 'INACTIVE');
    gate.complete(_page(['E', 'F'], page: 2, hasMore: true));
    await future;
    expect(cubit.state.items.map((s) => s.code), isNot(contains('E')));
  });

  test('pagination dedup: an overlapping page-1 is deduped by code', () async {
    page
      ..enqueue(_page(['A', 'B'], page: 0, hasMore: true))
      ..enqueue(_page(['B', 'C'], page: 1, hasMore: true)); // B overlaps
    await cubit.refresh();
    expect(cubit.state.items.map((s) => s.code), ['A', 'B', 'C']); // B once
  });
}
