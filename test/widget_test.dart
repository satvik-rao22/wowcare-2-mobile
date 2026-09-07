import 'package:flutter_test/flutter_test.dart';
import 'package:bloc/bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/dashboard_coordinator_state.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/parent_dashboard_coordinator_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/staff_dashboard_coordinator_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/admin_dashboard_coordinator_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/parent_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_childs_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/student_attendance_profile_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_state.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/student_newsletters_cubit.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';
import 'package:wowcare/presentation/features/billing/view_model/parent_billing_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/staff_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/ratio_monitoring_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_attendance_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_shifts_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/admin_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/school_status_cubit.dart';
import 'package:wowcare/presentation/features/availability/cubit/individual_movements_cubit.dart';
import 'package:wowcare/presentation/features/availability/cubit/future_availability_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/classroom_shifts_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/dashboard_attention_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/model/parent_dashboard_viewmodel.dart';
import 'package:wowcare/presentation/features/dashboard/model/staff_dashboard_viewmodel.dart';
import 'package:wowcare/presentation/features/dashboard/model/admin_dashboard_viewmodel.dart';

// Mock Storage Service
class MockStorageService implements StorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> saveString(String key, String value) async => _data[key] = value;
  @override
  Future<String?> getString(String key) async => _data[key];
  @override
  Future<void> saveInt(String key, int value) async =>
      _data[key] = value.toString();
  @override
  Future<int?> getInt(String key) async => int.tryParse(_data[key] ?? '');
  @override
  Future<void> saveBool(String key, bool value) async =>
      _data[key] = value.toString();
  @override
  Future<bool?> getBool(String key) async {
    final v = _data[key];
    if (v == null) return null;
    return v == 'true';
  }

  @override
  Future<void> saveJson(String key, Map<String, dynamic> value) async {}
  @override
  Future<Map<String, dynamic>?> getJson(String key) async => null;
  @override
  Future<void> remove(String key) async => _data.remove(key);
  @override
  Future<void> clear() async => _data.clear();
  @override
  Future<Set<String>> getKeys() async => _data.keys.toSet();
}

// Helper base mock cubit class to avoid boilerplate
class MockCubit<State> extends Cubit<State> {
  MockCubit(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// Mock states to bypass private _Status enums
class MockMyAttendanceState extends MyAttendanceState {
  final bool _isLoading;
  final bool _isLoaded;
  final bool _isError;

  const MockMyAttendanceState({
    bool isLoading = false,
    bool isLoaded = false,
    bool isError = false,
  }) : _isLoading = isLoading,
       _isLoaded = isLoaded,
       _isError = isError;

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isLoaded => _isLoaded;

  @override
  bool get isError => _isError;
}

class MockMyShiftsState extends MyShiftsState {
  final bool _isLoading;
  final bool _isLoaded;
  final bool _isError;

  const MockMyShiftsState({
    bool isLoading = false,
    bool isLoaded = false,
    bool isError = false,
  }) : _isLoading = isLoading,
       _isLoaded = isLoaded,
       _isError = isError;

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isLoaded => _isLoaded;

  @override
  bool get isError => _isError;
}

// 1. Parent Dashboard Cubits
class MockParentDashboardCubit extends MockCubit<ParentDashboardState>
    implements ParentDashboardCubit {
  MockParentDashboardCubit(super.initialState);
  bool isClosedCalled = false;
  @override
  Future<void> close() async {
    isClosedCalled = true;
    return super.close();
  }
}

class MockMyChildsDayCubit extends MockCubit<MyChildsDayState>
    implements MyChildsDayCubit {
  MockMyChildsDayCubit(super.initialState);
  bool loadForChildCalled = false;
  String? lastStudentCode;
  bool isClosedCalled = false;

  @override
  Future<void> loadForChild({
    required String studentCode,
    bool background = false,
  }) async {
    loadForChildCalled = true;
    lastStudentCode = studentCode;
  }

  @override
  Future<void> close() async {
    isClosedCalled = true;
    return super.close();
  }
}

class MockStudentAttendanceProfileCubit
    extends MockCubit<StudentAttendanceProfileState>
    implements StudentAttendanceProfileCubit {
  MockStudentAttendanceProfileCubit(super.initialState);
  bool loadAttendanceProfileCalled = false;
  bool isClosedCalled = false;

  @override
  Future<void> loadAttendanceProfile({
    required String studentCode,
    required DateTime fromDate,
    required DateTime toDate,
    bool forceRefresh = false,
    bool background = false,
  }) async {
    loadAttendanceProfileCalled = true;
  }

  @override
  Future<void> close() async {
    isClosedCalled = true;
    return super.close();
  }
}

class MockCommunicationCubit extends MockCubit<CommunicationState>
    implements CommunicationCubit {
  MockCommunicationCubit(super.initialState);
  bool loadConversationsCalled = false;
  bool isClosedCalled = false;

  // This override was commented out because it had drifted from
  // CommunicationCubit's signature. Without it `MockCubit.noSuchMethod`
  // returned `null` where the coordinator awaits a `Future<void>`, so
  // ParentDashboardCoordinatorCubit's constructor threw
  // "type 'Null' is not a subtype of type 'Future<void>'". Restored against the
  // CURRENT signature.
  @override
  Future<void> loadConversations({
    String? type,
    String status = 'ACTIVE',
    int page = 0,
    int size = 20,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? designations,
    List<String>? studentStatuses,
    List<String>? staffStatuses,
    String? search,
  }) async {
    loadConversationsCalled = true;
  }

  @override
  Future<void> close() async {
    isClosedCalled = true;
    return super.close();
  }
}

class MockStudentNewslettersCubit extends MockCubit<StudentNewslettersState>
    implements StudentNewslettersCubit {
  MockStudentNewslettersCubit(super.initialState);
  bool loadFirstPageCalled = false;
  bool isClosedCalled = false;

  @override
  Future<void> loadFirstPage({
    required String studentCode,
    int size = 10,
    String status = 'SENT',
    bool forceRefresh = false,
    bool background = false,
  }) async {
    loadFirstPageCalled = true;
  }

  @override
  Future<void> close() async {
    isClosedCalled = true;
    return super.close();
  }
}

class MockGeofenceCubit extends MockCubit<GeofenceState>
    implements GeofenceCubit {
  MockGeofenceCubit(super.initialState);
  bool initForSchoolCalled = false;
  String? lastSchoolCode;
  bool isClosedCalled = false;

  @override
  Future<void> initForSchool({required String schoolCode}) async {
    initForSchoolCalled = true;
    lastSchoolCode = schoolCode;
  }

  @override
  Future<void> close() async {
    isClosedCalled = true;
    return super.close();
  }
}

class MockParentChildCubit extends MockCubit<ParentChildState>
    implements ParentChildCubit {
  MockParentChildCubit(super.initialState);
}

class MockParentBillingCubit extends MockCubit<ParentBillingState>
    implements ParentBillingCubit {
  MockParentBillingCubit(super.initialState);
  bool loadCalled = false;
  bool isClosedCalled = false;

  @override
  Future<void> load({bool background = false}) async {
    loadCalled = true;
  }

  @override
  Future<void> close() async {
    isClosedCalled = true;
    return super.close();
  }
}

// 2. Staff Dashboard Cubits
class MockStaffDashboardCubit extends MockCubit<StaffDashboardState>
    implements StaffDashboardCubit {
  MockStaffDashboardCubit(super.initialState);
  bool isClosedCalled = false;
  @override
  Future<void> close() async {
    isClosedCalled = true;
    return super.close();
  }
}

class MockMyDayCubit extends MockCubit<MyDayState> implements MyDayCubit {
  MockMyDayCubit(super.initialState);
  bool loadCalled = false;
  bool refreshCalled = false;
  bool isClosedCalled = false;

  @override
  Future<void> load({bool isSilent = false}) async {
    loadCalled = true;
  }

  @override
  Future<void> refresh() async {
    refreshCalled = true;
  }

  @override
  Future<void> close() async {
    isClosedCalled = true;
    return super.close();
  }
}

class MockRatioMonitoringCubit extends MockCubit<RatioMonitoringState>
    implements RatioMonitoringCubit {
  MockRatioMonitoringCubit(super.initialState);
  bool loadRatioMonitoringCalled = false;
  bool isClosedCalled = false;

  @override
  Future<void> loadRatioMonitoring({
    required String schoolCode,
    bool forceRefresh = false,
    bool isSilent = false,
    DateTime? date,
  }) async {
    loadRatioMonitoringCalled = true;
  }

  @override
  Future<void> close() async {
    isClosedCalled = true;
    return super.close();
  }
}

class MockMyAttendanceCubit extends MockCubit<MyAttendanceState>
    implements MyAttendanceCubit {
  MockMyAttendanceCubit(super.initialState);
  bool loadCalled = false;
  bool refreshCalled = false;
  bool isClosedCalled = false;

  @override
  Future<void> load({bool forceRefresh = false}) async {
    loadCalled = true;
  }

  @override
  Future<void> refresh() async {
    refreshCalled = true;
  }

  @override
  Future<void> close() async {
    isClosedCalled = true;
    return super.close();
  }
}

class MockMyShiftsCubit extends MockCubit<MyShiftsState>
    implements MyShiftsCubit {
  MockMyShiftsCubit(super.initialState);
  bool loadCalled = false;
  bool isClosedCalled = false;

  @override
  Future<void> load({DateTime? date, bool forceRefresh = false}) async {
    loadCalled = true;
  }

  @override
  Future<void> close() async {
    isClosedCalled = true;
    return super.close();
  }
}

// 3. Admin Dashboard Cubits
class MockAdminDashboardCubit extends MockCubit<AdminDashboardState>
    implements AdminDashboardCubit {
  MockAdminDashboardCubit(super.initialState);
  bool loadUserNameCalled = false;
  bool isClosedCalled = false;

  @override
  Future<void> loadUserName() async {
    loadUserNameCalled = true;
  }

  @override
  Future<void> close() async {
    isClosedCalled = true;
    return super.close();
  }
}

class MockSchoolStatusCubit extends MockCubit<SchoolStatusState>
    implements SchoolStatusCubit {
  MockSchoolStatusCubit(super.initialState);
  bool loadSchoolStatusCalled = false;
  bool isClosedCalled = false;

  @override
  Future<void> loadSchoolStatus({
    required String schoolCode,
    bool isSilent = false,
    bool forceRefresh = false,
  }) async {
    loadSchoolStatusCalled = true;
  }

  @override
  Future<void> close() async {
    isClosedCalled = true;
    return super.close();
  }
}

class MockIndividualMovementsCubit extends MockCubit<IndividualMovementsState>
    implements IndividualMovementsCubit {
  MockIndividualMovementsCubit(super.initialState);
  bool loadInitialCalled = false;
  bool refreshCalled = false;
  bool isClosedCalled = false;

  @override
  Future<void> loadInitial({
    List<String>? studentCodes,
    List<String>? fromClassroomCodes,
    List<String>? toClassroomCodes,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? status,
  }) async {
    loadInitialCalled = true;
  }

  @override
  Future<void> refresh({
    List<String>? studentCodes,
    List<String>? fromClassroomCodes,
    List<String>? toClassroomCodes,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? status,
  }) async {
    refreshCalled = true;
  }

  @override
  Future<void> close() async {
    isClosedCalled = true;
    return super.close();
  }
}

class MockFutureAvailabilityCubit extends MockCubit<FutureAvailabilityState>
    implements FutureAvailabilityCubit {
  MockFutureAvailabilityCubit(super.initialState);
  bool loadCalled = false;
  bool refreshCalled = false;
  bool isClosedCalled = false;

  @override
  Future<void> load({required DateTime date, required bool isTwoShifts}) async {
    loadCalled = true;
  }

  @override
  Future<void> refresh({
    required DateTime date,
    required bool isTwoShifts,
  }) async {
    refreshCalled = true;
  }

  @override
  Future<void> close() async {
    isClosedCalled = true;
    return super.close();
  }
}

class MockClassroomShiftsCubit extends MockCubit<ClassroomShiftsState>
    implements ClassroomShiftsCubit {
  MockClassroomShiftsCubit(super.initialState);
  bool loadCalled = false;
  bool isClosedCalled = false;

  @override
  Future<void> load(DateTime date) async {
    loadCalled = true;
  }

  @override
  Future<void> close() async {
    isClosedCalled = true;
    return super.close();
  }
}

class MockDashboardAttentionCubit extends MockCubit<DashboardAttentionState>
    implements DashboardAttentionCubit {
  MockDashboardAttentionCubit(super.initialState);
  bool loadCalled = false;
  bool refreshCalled = false;
  bool isClosedCalled = false;

  @override
  Future<void> load({bool isSilent = false}) async {
    loadCalled = true;
  }

  @override
  Future<void> refresh() async {
    refreshCalled = true;
  }

  @override
  Future<void> close() async {
    isClosedCalled = true;
    return super.close();
  }
}

void main() {
  late MockStorageService mockStorageService;

  setUp(() {
    mockStorageService = MockStorageService();
    if (!serviceLocator.isRegistered<StorageService>()) {
      serviceLocator.registerSingleton<StorageService>(mockStorageService);
    } else {
      serviceLocator.unregister<StorageService>();
      serviceLocator.registerSingleton<StorageService>(mockStorageService);
    }
  });

  group('ParentDashboardCoordinatorCubit Tests', () {
    late MockParentDashboardCubit dashboardCubit;
    late MockMyChildsDayCubit myChildsDayCubit;
    late MockStudentAttendanceProfileCubit studentAttendanceProfileCubit;
    late MockCommunicationCubit communicationCubit;
    late MockStudentNewslettersCubit studentNewslettersCubit;
    late MockGeofenceCubit geofenceCubit;
    late MockParentChildCubit parentChildCubit;
    late MockParentBillingCubit parentBillingCubit;

    setUp(() {
      dashboardCubit = MockParentDashboardCubit(
        ParentDashboardState(
          cards: List<ParentDashboardCard>.of(ParentDashboardCard.values),
        ),
      );
      myChildsDayCubit = MockMyChildsDayCubit(const MyChildsDayState.initial());
      studentAttendanceProfileCubit = MockStudentAttendanceProfileCubit(
        const StudentAttendanceProfileState.initial(),
      );
      communicationCubit = MockCommunicationCubit(CommunicationInitial());
      studentNewslettersCubit = MockStudentNewslettersCubit(
        const StudentNewslettersState.initial(),
      );
      geofenceCubit = MockGeofenceCubit(const GeofenceState.initial());
      parentChildCubit = MockParentChildCubit(const ParentChildState());
      parentBillingCubit = MockParentBillingCubit(
        const ParentBillingState.initial(),
      );
    });

    test('initializes and triggers loads if child is already selected', () async {
      const child = ParentChildRef(
        code: 'CHILD123',
        name: 'Child Name',
        classroom: 'Room A',
      );
      parentChildCubit.emit(
        ParentChildState(
          selectedChild: child,
          children: const [child],
          isLoaded: true,
        ),
      );

      mockStorageService.saveString(StorageKeys.schoolCode, 'SCHOOL_XYZ');

      final coordinator = ParentDashboardCoordinatorCubit(
        dashboardCubit: dashboardCubit,
        myChildsDayCubit: myChildsDayCubit,
        studentAttendanceProfileCubit: studentAttendanceProfileCubit,
        communicationCubit: communicationCubit,
        studentNewslettersCubit: studentNewslettersCubit,
        parentBillingCubit: parentBillingCubit,
        geofenceCubit: geofenceCubit,
        parentChildCubit: parentChildCubit,
      );

      // Yield event loop execution to allow geofence and other async calls to initialize
      await Future.delayed(Duration.zero);

      expect(myChildsDayCubit.loadForChildCalled, isTrue);
      expect(myChildsDayCubit.lastStudentCode, 'CHILD123');
      expect(studentAttendanceProfileCubit.loadAttendanceProfileCalled, isTrue);
      expect(studentNewslettersCubit.loadFirstPageCalled, isTrue);
      expect(communicationCubit.loadConversationsCalled, isTrue);
      expect(geofenceCubit.initForSchoolCalled, isTrue);
      expect(geofenceCubit.lastSchoolCode, 'SCHOOL_XYZ');

      coordinator.close();
    });

    test('updates state to ready when all child cubits are loaded', () async {
      final coordinator = ParentDashboardCoordinatorCubit(
        dashboardCubit: dashboardCubit,

        myChildsDayCubit: myChildsDayCubit,
        studentAttendanceProfileCubit: studentAttendanceProfileCubit,
        communicationCubit: communicationCubit,
        studentNewslettersCubit: studentNewslettersCubit,
        parentBillingCubit: parentBillingCubit,
        geofenceCubit: geofenceCubit,
        parentChildCubit: parentChildCubit,
      );

      expect(coordinator.state.status, DashboardStatus.initial);

      // Emit loading on one child cubit
      myChildsDayCubit.emit(
        const MyChildsDayState.initial().copyWith(
          status: MyChildsDayStatus.loading,
        ),
      );
      await Future.delayed(Duration.zero);
      expect(coordinator.state.status, DashboardStatus.loading);

      // Emit loaded/ready states on all sub-cubits
      myChildsDayCubit.emit(
        const MyChildsDayState.initial().copyWith(
          status: MyChildsDayStatus.loaded,
        ),
      );
      studentAttendanceProfileCubit.emit(
        StudentAttendanceProfileState.loaded(
          studentCode: 'C1',
          attendedDays: 5,
          attendedHours: 25,
          attendedMinutes: 0,
          totalAttendedTime: '25h',
          absentDays: 0,
          fromDate: DateTime.now(),
          toDate: DateTime.now(),
        ),
      );
      studentNewslettersCubit.emit(
        const StudentNewslettersState.initial().copyWith(
          status: StudentNewslettersStatus.loaded,
        ),
      );
      communicationCubit.emit(
        const CommunicationLoaded(threads: {}, activeThreadId: ''),
      );

      await Future.delayed(Duration.zero);
      expect(coordinator.state.status, DashboardStatus.ready);

      coordinator.close();
    });

    test(
      'closes non-singleton cubits on close, but keeps geofence alive',
      () async {
        final coordinator = ParentDashboardCoordinatorCubit(
          dashboardCubit: dashboardCubit,
          myChildsDayCubit: myChildsDayCubit,
          studentAttendanceProfileCubit: studentAttendanceProfileCubit,
          communicationCubit: communicationCubit,
          studentNewslettersCubit: studentNewslettersCubit,
          parentBillingCubit: parentBillingCubit,
          geofenceCubit: geofenceCubit,
          parentChildCubit: parentChildCubit,
        );

        await coordinator.close();

        expect(dashboardCubit.isClosedCalled, isTrue);
        expect(myChildsDayCubit.isClosedCalled, isTrue);
        expect(studentAttendanceProfileCubit.isClosedCalled, isTrue);
        expect(communicationCubit.isClosedCalled, isTrue);
        expect(studentNewslettersCubit.isClosedCalled, isTrue);
        expect(geofenceCubit.isClosedCalled, isFalse);
      },
    );
  });

  group('StaffDashboardCoordinatorCubit Tests', () {
    late MockStaffDashboardCubit dashboardCubit;
    late MockMyDayCubit myDayCubit;
    late MockRatioMonitoringCubit ratioMonitoringCubit;
    late MockMyAttendanceCubit myAttendanceCubit;
    late MockMyShiftsCubit myShiftsCubit;
    late MockGeofenceCubit geofenceCubit;

    setUp(() {
      dashboardCubit = MockStaffDashboardCubit(
        StaffDashboardState(
          cards: List<StaffDashboardCard>.of(StaffDashboardCard.values),
        ),
      );
      myDayCubit = MockMyDayCubit(const MyDayState());
      ratioMonitoringCubit = MockRatioMonitoringCubit(
        const RatioMonitoringState.initial(),
      );
      myAttendanceCubit = MockMyAttendanceCubit(const MockMyAttendanceState());
      myShiftsCubit = MockMyShiftsCubit(const MockMyShiftsState());
      geofenceCubit = MockGeofenceCubit(const GeofenceState.initial());
    });

    test('initializes and triggers loading on start', () async {
      mockStorageService.saveString(StorageKeys.schoolCode, 'SCHOOL_XYZ');

      final coordinator = StaffDashboardCoordinatorCubit(
        dashboardCubit: dashboardCubit,
        myDayCubit: myDayCubit,
        ratioMonitoringCubit: ratioMonitoringCubit,
        myAttendanceCubit: myAttendanceCubit,
        myShiftsCubit: myShiftsCubit,
        geofenceCubit: geofenceCubit,
      );

      // Yield event loop
      await Future.delayed(Duration.zero);

      expect(myDayCubit.loadCalled, isTrue);
      expect(myAttendanceCubit.loadCalled, isTrue);
      expect(myShiftsCubit.loadCalled, isTrue);
      expect(geofenceCubit.initForSchoolCalled, isTrue);
      expect(ratioMonitoringCubit.loadRatioMonitoringCalled, isTrue);

      coordinator.close();
    });

    test('aggregates state from staff sub-cubits correctly', () async {
      final coordinator = StaffDashboardCoordinatorCubit(
        dashboardCubit: dashboardCubit,
        myDayCubit: myDayCubit,
        ratioMonitoringCubit: ratioMonitoringCubit,
        myAttendanceCubit: myAttendanceCubit,
        myShiftsCubit: myShiftsCubit,
        geofenceCubit: geofenceCubit,
      );

      // Simulate loading state
      myDayCubit.emit(const MyDayState(status: MyDayStatus.loading));
      await Future.delayed(Duration.zero);
      expect(coordinator.state.status, DashboardStatus.loading);

      // Simulate loaded states
      myDayCubit.emit(const MyDayState(status: MyDayStatus.loaded));
      ratioMonitoringCubit.emit(
        const RatioMonitoringState.loaded(schoolCode: 'S1', classrooms: []),
      );
      myAttendanceCubit.emit(const MockMyAttendanceState(isLoaded: true));
      myShiftsCubit.emit(const MockMyShiftsState(isLoaded: true));

      await Future.delayed(Duration.zero);
      expect(coordinator.state.status, DashboardStatus.ready);

      coordinator.close();
    });
  });

  group('AdminDashboardCoordinatorCubit Tests', () {
    late MockAdminDashboardCubit dashboardCubit;
    late MockSchoolStatusCubit schoolStatusCubit;
    late MockRatioMonitoringCubit ratioMonitoringCubit;
    late MockIndividualMovementsCubit movementsCubit;
    late MockFutureAvailabilityCubit availabilityCubit;
    late MockClassroomShiftsCubit classroomShiftsCubit;
    late MockDashboardAttentionCubit attentionCubit;
    late MockMyDayCubit myDayCubit;
    late MockGeofenceCubit geofenceCubit;

    setUp(() {
      dashboardCubit = MockAdminDashboardCubit(
        AdminDashboardState(
          cards: List<AdminDashboardCard>.of(AdminDashboardCard.values),
        ),
      );
      schoolStatusCubit = MockSchoolStatusCubit(
        const SchoolStatusState.initial(),
      );
      ratioMonitoringCubit = MockRatioMonitoringCubit(
        const RatioMonitoringState.initial(),
      );
      movementsCubit = MockIndividualMovementsCubit(
        const IndividualMovementsState.initial(),
      );
      availabilityCubit = MockFutureAvailabilityCubit(
        const FutureAvailabilityState.initial(),
      );
      classroomShiftsCubit = MockClassroomShiftsCubit(
        const ClassroomShiftsState.initial(),
      );
      attentionCubit = MockDashboardAttentionCubit(
        const DashboardAttentionState(),
      );
      myDayCubit = MockMyDayCubit(const MyDayState());
      geofenceCubit = MockGeofenceCubit(const GeofenceState.initial());
    });

    test('initializes and triggers loading on start', () async {
      mockStorageService.saveString(StorageKeys.schoolCode, 'SCHOOL_XYZ');

      final coordinator = AdminDashboardCoordinatorCubit(
        dashboardCubit: dashboardCubit,
        schoolStatusCubit: schoolStatusCubit,
        ratioMonitoringCubit: ratioMonitoringCubit,
        movementsCubit: movementsCubit,
        availabilityCubit: availabilityCubit,
        classroomShiftsCubit: classroomShiftsCubit,
        attentionCubit: attentionCubit,
        myDayCubit: myDayCubit,
        geofenceCubit: geofenceCubit,
      );

      await Future.delayed(Duration.zero);

      expect(dashboardCubit.loadUserNameCalled, isTrue);
      expect(classroomShiftsCubit.loadCalled, isTrue);
      expect(attentionCubit.loadCalled, isTrue);
      expect(myDayCubit.loadCalled, isTrue);
      expect(movementsCubit.loadInitialCalled, isTrue);
      expect(availabilityCubit.loadCalled, isTrue);
      expect(schoolStatusCubit.loadSchoolStatusCalled, isTrue);
      expect(ratioMonitoringCubit.loadRatioMonitoringCalled, isTrue);
      expect(geofenceCubit.initForSchoolCalled, isTrue);

      coordinator.close();
    });
  });

  group('ParentChildCubit Tests', () {
    test('forceRefresh increments refreshNonce and emits new state', () {
      final cubit = ParentChildCubit();
      expect(cubit.state.refreshNonce, 0);
      cubit.forceRefresh();
      expect(cubit.state.refreshNonce, 1);
      cubit.close();
    });
  });
}
