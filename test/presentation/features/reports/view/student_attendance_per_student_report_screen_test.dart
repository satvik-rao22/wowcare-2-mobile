import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/domain/features/classroom/repositories/classroom_repository.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/domain/features/reports/repositories/file_download_repository.dart';
import 'package:wowcare/domain/features/reports/usecases/save_report_file_usecase.dart';
import 'package:wowcare/domain/features/reports/usecases/open_report_file_usecase.dart';
import 'package:wowcare/domain/features/reports/repositories/reports_repository.dart';
import 'package:wowcare/domain/features/reports/usecases/download_report_usecase.dart';
import 'package:wowcare/domain/features/reports/usecases/generate_report_usecase.dart';
import 'package:wowcare/domain/features/reports/usecases/get_recent_reports_usecase.dart';
import 'package:wowcare/domain/features/reports/usecases/get_student_tags_usecase.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_names_for_school_usecase.dart';
import 'package:wowcare/domain/features/student_classroom/entities/student_classroom_item.dart';
import 'package:wowcare/domain/features/student_classroom/repositories/student_classroom_repository.dart';
import 'package:wowcare/domain/features/student_classroom/usecases/get_student_classroom_list_usecase.dart';
import 'package:wowcare/presentation/features/auth/view_model/auth_cubit.dart';
import 'package:wowcare/presentation/features/communication/view_model/unread_badge_cubit.dart';
import 'package:wowcare/presentation/features/communication/view_model/unread_badge_state.dart';
import 'package:wowcare/presentation/features/notifications/view_model/notification_badge_cubit.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/view/student_attendance_per_student_report_screen.dart';
import 'package:wowcare/presentation/features/reports/widgets/multi_select_filter_field.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/presentation/features/user_profile/view_model/profile_menu_header_cubit.dart';
import 'package:wowcare/presentation/features/user_profile/view_model/user_profile_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/domain/features/student/usecases/get_immunization_settings_usecase.dart';
import 'package:wowcare/domain/features/reports/repositories/school_context_repository.dart';
import 'package:wowcare/domain/features/reports/usecases/get_school_code_usecase.dart';
import 'package:wowcare/domain/features/reports/usecases/get_school_name_usecase.dart';

class _FakeStorageService implements StorageService {
  final Map<String, dynamic> _data = {
    StorageKeys.schoolCode: 'school-123',
    StorageKeys.schoolName: 'Test School',
    StorageKeys.organizationCode: 'org-123',
  };

  @override
  Future<void> saveString(String key, String value) async => _data[key] = value;

  @override
  Future<String?> getString(String key) async => _data[key] as String?;

  @override
  Future<void> remove(String key) async => _data.remove(key);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStudentClassroomRepository implements StudentClassroomRepository {
  final Map<String, List<StudentClassroomItem>> classroomStudents;

  _FakeStudentClassroomRepository(this.classroomStudents);

  @override
  Future<List<StudentClassroomItem>> getStudentClassroomList({
    required String schoolCode,
    required String classroomCode,
    String? firstName,
    String? lastName,
    String? search,
    List<String>? studentCodes,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    List<String>? status,
    String? attendanceStatus,
    bool refresh = false,
  }) async {
    return classroomStudents[classroomCode] ?? const <StudentClassroomItem>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeClassroomRepository implements ClassroomRepository {
  final List<Classroom> classrooms;

  _FakeClassroomRepository(this.classrooms);

  @override
  Future<List<Classroom>> getActiveClassrooms({
    required String schoolCode,
    bool onlyTypeClassroom = true,
    String? typeOverride,
  }) async {
    return classrooms;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStudentRepository implements StudentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeReportsRepository implements ReportsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFileDownloadRepository implements FileDownloadRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockRoleCubit extends Cubit<RoleState> implements RoleCubit {
  _MockRoleCubit() : super(const RoleState(role: 'admin'));

  @override
  String get role => 'admin';
  @override
  bool get isParent => false;
  @override
  bool get isGuardian => false;
  @override
  bool get isAdmin => true;
  @override
  bool get isStaff => false;
  @override
  bool get isKiosk => false;
  @override
  bool get isOrganizationAdmin => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockUnreadBadgeCubit extends Cubit<UnreadBadgeState>
    implements UnreadBadgeCubit {
  _MockUnreadBadgeCubit() : super(const UnreadBadgeState.initial());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockNotificationBadgeCubit extends Cubit<NotificationBadgeState>
    implements NotificationBadgeCubit {
  _MockNotificationBadgeCubit() : super(const NotificationBadgeState.initial());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockParentChildCubit extends Cubit<ParentChildState>
    implements ParentChildCubit {
  _MockParentChildCubit() : super(const ParentChildState());
  @override
  List<String> get childNames => const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockUserProfileCubit extends Cubit<UserProfileState>
    implements UserProfileCubit {
  _MockUserProfileCubit() : super(const UserProfileState.initial());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockProfileMenuHeaderCubit extends Cubit<ProfileMenuHeaderState>
    implements ProfileMenuHeaderCubit {
  _MockProfileMenuHeaderCubit() : super(const ProfileMenuHeaderState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockAuthCubit extends Cubit<AuthState> implements AuthCubit {
  _MockAuthCubit() : super(const AuthInitial());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeStorageService fakeStorage;
  late _FakeStudentClassroomRepository fakeStudentClassroomRepo;
  late _FakeClassroomRepository fakeClassroomRepo;
  late ReportsCubit reportsCubit;

  final testClassrooms = [
    const Classroom(code: 'ROOM-A', name: 'Toddler Room A'),
    const Classroom(code: 'ROOM-B', name: 'Preschool Room B'),
  ];

  StudentClassroomItem createStudentItem({
    required String classroomCode,
    required String studentCode,
    required String firstName,
    required String lastName,
  }) {
    return StudentClassroomItem(
      classroomCode: classroomCode,
      studentCode: studentCode,
      firstName: firstName,
      lastName: lastName,
      status: 'ACTIVE',
      expectedToday: true,
      signedIn: false,
      absent: false,
      notMarked: true,
      nap: false,
      photoPermission: true,
      notes: false,
      medication: false,
      allergies: false,
      dietaryRestriction: false,
    );
  }

  final testStudentsRoomA = [
    createStudentItem(
      classroomCode: 'ROOM-A',
      studentCode: 'STU-001',
      firstName: 'Alice',
      lastName: 'Smith',
    ),
    createStudentItem(
      classroomCode: 'ROOM-A',
      studentCode: 'STU-002',
      firstName: 'Bob',
      lastName: 'Jones',
    ),
  ];

  final testStudentsRoomB = [
    createStudentItem(
      classroomCode: 'ROOM-B',
      studentCode: 'STU-003',
      firstName: 'Charlie',
      lastName: 'Brown',
    ),
  ];

  setUp(() async {
    await serviceLocator.reset();
    fakeStorage = _FakeStorageService();
    fakeStudentClassroomRepo = _FakeStudentClassroomRepository({
      'ROOM-A': testStudentsRoomA,
      'ROOM-B': testStudentsRoomB,
    });
    fakeClassroomRepo = _FakeClassroomRepository(testClassrooms);

    serviceLocator.registerSingleton<StorageService>(fakeStorage);
    serviceLocator.registerFactory<GetStudentClassroomListUseCase>(
      () => GetStudentClassroomListUseCase(fakeStudentClassroomRepo),
    );
    serviceLocator.registerFactory<GetActiveClassroomsUseCase>(
      () => GetActiveClassroomsUseCase(fakeClassroomRepo),
    );

    final mockReportsRepo = _FakeReportsRepository();
    final mockStudentRepo = _FakeStudentRepository();
    reportsCubit = ReportsCubit(
      getSchoolCodeUseCase: GetSchoolCodeUseCase(
        _FakeSchoolContextRepository(),
      ),
      getSchoolNameUseCase: GetSchoolNameUseCase(
        _FakeSchoolContextRepository(),
      ),
      generateReportUseCase: GenerateReportUseCase(mockReportsRepo),
      getRecentReportsUseCase: GetRecentReportsUseCase(mockReportsRepo),
      getStudentTagsUseCase: GetStudentTagsUseCase(mockReportsRepo),
      downloadReportUseCase: DownloadReportUseCase(mockReportsRepo),
      saveReportFileUseCase: SaveReportFileUseCase(
        _FakeFileDownloadRepository(),
      ),
      openReportFileUseCase: OpenReportFileUseCase(
        _FakeFileDownloadRepository(),
      ),
      getActiveClassroomsUseCase: GetActiveClassroomsUseCase(fakeClassroomRepo),
      getStudentClassroomListUseCase: GetStudentClassroomListUseCase(
        fakeStudentClassroomRepo,
      ),
      getImmunizationSettingsUseCase: GetImmunizationSettingsUseCase(
        _FakeStudentRepository(),
      ),
      getTagNameCodeMapForSchoolUseCase: GetTagNameCodeMapForSchoolUseCase(
        mockStudentRepo,
      ),
    );

    reportsCubit.setClassroomNames(
      ['Toddler Room A', 'Preschool Room B'],
      nameToCodeMap: {'Toddler Room A': 'ROOM-A', 'Preschool Room B': 'ROOM-B'},
    );
  });

  tearDown(() async {
    await reportsCubit.close();
    await serviceLocator.reset();
  });

  Widget buildTestWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RoleCubit>(create: (_) => _MockRoleCubit()),
        BlocProvider<UnreadBadgeCubit>(create: (_) => _MockUnreadBadgeCubit()),
        BlocProvider<NotificationBadgeCubit>(
          create: (_) => _MockNotificationBadgeCubit(),
        ),
        BlocProvider<ParentChildCubit>(create: (_) => _MockParentChildCubit()),
        BlocProvider<UserProfileCubit>(create: (_) => _MockUserProfileCubit()),
        BlocProvider<ProfileMenuHeaderCubit>(
          create: (_) => _MockProfileMenuHeaderCubit(),
        ),
        BlocProvider<AuthCubit>(create: (_) => _MockAuthCubit()),
        BlocProvider<ReportsCubit>.value(value: reportsCubit),
      ],
      child: MaterialApp.router(
        // The form screens are GoRoute children of the reports hub,
        // so they must be hosted by a router here too: they call
        // context.pop(ReportFormResult) on success, which needs both a
        // GoRouter in scope and a page beneath them to pop back to.
        routerConfig: GoRouter(
          initialLocation: '/form',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const SizedBox.shrink(),
              routes: [
                GoRoute(
                  path: 'form',
                  builder: (_, __) => StudentAttendancePerStudentReportScreen(
                    classrooms: ['Toddler Room A', 'Preschool Room B'],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  testWidgets(
    'StudentAttendancePerStudentReportScreen fetches students for all default classrooms on load',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final studentFieldFinder = find.byType(MultiSelectFilterField<String>);
      expect(studentFieldFinder, findsOneWidget);

      final studentField = tester.widget<MultiSelectFilterField<String>>(
        studentFieldFinder,
      );

      expect(
        studentField.items,
        containsAll(['Alice Smith', 'Bob Jones', 'Charlie Brown']),
      );
    },
  );

  testWidgets('Changing selected classroom dynamically updates student list', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Find classroom dropdown and trigger selection change to only Toddler Room A
    final classroomDropdownFinder = find.byType(CustomMultiSelectDropdown);
    expect(classroomDropdownFinder, findsOneWidget);

    final classroomDropdown = tester.widget<CustomMultiSelectDropdown>(
      classroomDropdownFinder,
    );

    // Simulate user changing classroom selection to only 'Toddler Room A'
    classroomDropdown.onChanged(['Toddler Room A']);
    await tester.pumpAndSettle();

    final studentField = tester.widget<MultiSelectFilterField<String>>(
      find.byType(MultiSelectFilterField<String>),
    );

    expect(studentField.items, containsAll(['Alice Smith', 'Bob Jones']));
    expect(studentField.items.contains('Charlie Brown'), isFalse);
  });

  testWidgets(
    'Deselecting all classrooms still lists every student, and selects none',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final classroomDropdown = tester.widget<CustomMultiSelectDropdown>(
        find.byType(CustomMultiSelectDropdown),
      );

      // Simulate user deselecting all classrooms
      classroomDropdown.onChanged([]);
      await tester.pumpAndSettle();

      final studentField = tester.widget<MultiSelectFilterField<String>>(
        find.byType(MultiSelectFilterField<String>),
      );

      // An empty classroom filter means "All Classrooms", so the student
      // picker stays usable: no classroom has to be chosen to pick students.
      expect(studentField.items, isNotEmpty);
      expect(studentField.hintText, equals('All Students'));
      // ...but nothing is auto-selected on the user's behalf.
      expect(studentField.selectedItems, isEmpty);
    },
  );
}

/// Mirrors the fake storage service the tests already install: school code
/// and name resolve to the same fixture values the cubit used to read
/// straight off StorageService.
class _FakeSchoolContextRepository implements SchoolContextRepository {
  @override
  Future<String> getSchoolCode() async => 'school-123';

  @override
  Future<String> getSchoolName() async => 'Test School';
}
