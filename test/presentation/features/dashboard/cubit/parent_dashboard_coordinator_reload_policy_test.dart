import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/presentation/features/billing/view_model/parent_billing_cubit.dart';
import 'package:wowcare/presentation/features/communication/view_model/communication_cubit.dart';
import 'package:wowcare/presentation/features/communication/view_model/communication_state.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/my_childs_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/parent_dashboard_coordinator_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/parent_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/student_attendance_profile_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/student_newsletters_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/model/parent_dashboard_viewmodel.dart';
import 'package:wowcare/presentation/features/geofencing/view_model/geofence_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/parent_child_cubit.dart';

/// Base fake. Returns a completed future for every un-overridden member, which
/// is what the coordinator's fire-and-forget calls need; `state` and `stream`
/// come from the real [Cubit].
class _FakeCubit<S> extends Cubit<S> {
  _FakeCubit(super.initialState);

  final List<Symbol> calls = <Symbol>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation.memberName);
    return Future<void>.value();
  }
}

class _FakeStorage implements StorageService {
  @override
  Future<String?> getString(String key) async => 'SCH_1';

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _FakeParentDashboardCubit extends _FakeCubit<ParentDashboardState>
    implements ParentDashboardCubit {
  _FakeParentDashboardCubit(super.initialState);
}

class _FakeMyChildsDayCubit extends _FakeCubit<MyChildsDayState>
    implements MyChildsDayCubit {
  _FakeMyChildsDayCubit(super.initialState);

  final List<String> loadedFor = <String>[];

  @override
  Future<void> loadForChild({
    required String studentCode,
    bool background = false,
  }) async {
    loadedFor.add(studentCode);
  }
}

class _FakeStudentAttendanceProfileCubit
    extends _FakeCubit<StudentAttendanceProfileState>
    implements StudentAttendanceProfileCubit {
  _FakeStudentAttendanceProfileCubit(super.initialState);

  int loadCount = 0;

  @override
  Future<void> loadAttendanceProfile({
    required String studentCode,
    required DateTime fromDate,
    required DateTime toDate,
    bool forceRefresh = false,
    bool background = false,
  }) async {
    loadCount++;
  }
}

class _FakeCommunicationCubit extends _FakeCubit<CommunicationState>
    implements CommunicationCubit {
  _FakeCommunicationCubit(super.initialState);
}

class _FakeStudentNewslettersCubit extends _FakeCubit<StudentNewslettersState>
    implements StudentNewslettersCubit {
  _FakeStudentNewslettersCubit(super.initialState);

  int loadCount = 0;

  @override
  Future<void> loadFirstPage({
    required String studentCode,
    int size = 10,
    String status = 'SENT',
    bool forceRefresh = false,
    bool background = false,
  }) async {
    loadCount++;
  }
}

class _FakeGeofenceCubit extends _FakeCubit<GeofenceState>
    implements GeofenceCubit {
  _FakeGeofenceCubit(super.initialState);

  @override
  Future<void> initForSchool({required String schoolCode}) async {}
}

class _FakeParentBillingCubit extends _FakeCubit<ParentBillingState>
    implements ParentBillingCubit {
  _FakeParentBillingCubit(super.initialState);

  @override
  Future<void> load({bool background = false}) async {}
}

/// A real [ParentChildCubit] whose state is driven directly, so the test
/// exercises the coordinator's reaction to real emissions (including the
/// loading-flag churn that used to cause duplicate loads).
class _DrivableParentChildCubit extends ParentChildCubit {
  void push(ParentChildState next) => emit(next);
}

const ParentChildRef _childA = ParentChildRef(
  code: 'STD_A',
  name: 'Ava',
  classroom: 'Room 1',
);
const ParentChildRef _childB = ParentChildRef(
  code: 'STD_B',
  name: 'Ben',
  classroom: 'Room 2',
);

ParentChildState _loaded(ParentChildRef selected, {int nonce = 0}) =>
    ParentChildState(
      selectedChild: selected,
      children: const <ParentChildRef>[_childA, _childB],
      isLoaded: true,
      refreshNonce: nonce,
    );

void main() {
  late _FakeMyChildsDayCubit myChildsDay;
  late _FakeStudentAttendanceProfileCubit attendance;
  late _FakeStudentNewslettersCubit newsletters;
  late _DrivableParentChildCubit parentChild;
  late ParentDashboardCoordinatorCubit coordinator;

  ParentDashboardCoordinatorCubit build() => ParentDashboardCoordinatorCubit(
    dashboardCubit: _FakeParentDashboardCubit(
      ParentDashboardState(
        cards: List<ParentDashboardCard>.of(ParentDashboardCard.values),
      ),
    ),
    myChildsDayCubit: myChildsDay,
    studentAttendanceProfileCubit: attendance,
    communicationCubit: _FakeCommunicationCubit(CommunicationInitial()),
    studentNewslettersCubit: newsletters,
    parentBillingCubit: _FakeParentBillingCubit(
      const ParentBillingState.initial(),
    ),
    geofenceCubit: _FakeGeofenceCubit(const GeofenceState.initial()),
    parentChildCubit: parentChild,
  );

  setUp(() async {
    await serviceLocator.reset();
    serviceLocator.registerSingleton<StorageService>(_FakeStorage());

    myChildsDay = _FakeMyChildsDayCubit(const MyChildsDayState.initial());
    attendance = _FakeStudentAttendanceProfileCubit(
      const StudentAttendanceProfileState.initial(),
    );
    newsletters = _FakeStudentNewslettersCubit(
      const StudentNewslettersState.initial(),
    );
    parentChild = _DrivableParentChildCubit();
  });

  tearDown(() async {
    await coordinator.close();
    await parentChild.close();
    await serviceLocator.reset();
  });

  test('loads the selected child once on construction', () async {
    parentChild.push(_loaded(_childA));
    coordinator = build();
    await Future<void>.delayed(Duration.zero);

    expect(myChildsDay.loadedFor, <String>['STD_A']);
    expect(attendance.loadCount, 1);
    expect(newsletters.loadCount, 1);
  });

  test('switching child reloads every feature for the NEW child', () async {
    parentChild.push(_loaded(_childA));
    coordinator = build();
    await Future<void>.delayed(Duration.zero);

    parentChild.push(_loaded(_childB));
    await Future<void>.delayed(Duration.zero);

    expect(myChildsDay.loadedFor, <String>['STD_A', 'STD_B']);
    expect(attendance.loadCount, 2);
    expect(newsletters.loadCount, 2);
  });

  test('loading-flag churn for the SAME child does not reload', () async {
    parentChild.push(_loaded(_childA));
    coordinator = build();
    await Future<void>.delayed(Duration.zero);

    // What a refresh emits: isLoading true, then the settled state again.
    parentChild.push(
      ParentChildState(
        selectedChild: _childA,
        children: const <ParentChildRef>[_childA, _childB],
        isLoading: true,
        isLoaded: true,
      ),
    );
    parentChild.push(_loaded(_childA));
    await Future<void>.delayed(Duration.zero);

    expect(myChildsDay.loadedFor, <String>['STD_A']);
    expect(attendance.loadCount, 1);
    expect(newsletters.loadCount, 1);
  });

  test('an explicit forceRefresh DOES reload the same child', () async {
    // The parent sign-in/sign-out forms call `forceRefresh()` so the dashboard
    // re-reads the child's day after an attendance action. Suppressing that
    // would leave a stale "My Child's Day" right after a sign-in.
    parentChild.push(_loaded(_childA));
    coordinator = build();
    await Future<void>.delayed(Duration.zero);

    parentChild.push(_loaded(_childA, nonce: 1));
    await Future<void>.delayed(Duration.zero);

    expect(myChildsDay.loadedFor, <String>['STD_A', 'STD_A']);
    expect(attendance.loadCount, 2);
    expect(newsletters.loadCount, 2);
  });

  test(
    'clearing the selection lets the same child reload afterwards',
    () async {
      parentChild.push(_loaded(_childA));
      coordinator = build();
      await Future<void>.delayed(Duration.zero);

      // Logout / school switch.
      parentChild.push(const ParentChildState());
      await Future<void>.delayed(Duration.zero);
      expect(myChildsDay.loadedFor, <String>['STD_A']);

      parentChild.push(_loaded(_childA));
      await Future<void>.delayed(Duration.zero);

      expect(myChildsDay.loadedFor, <String>['STD_A', 'STD_A']);
    },
  );
}
