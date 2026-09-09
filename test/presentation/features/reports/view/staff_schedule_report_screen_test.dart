import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/reports/models/report_request_payload.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/domain/features/reports/repositories/file_download_repository.dart';
import 'package:wowcare/domain/features/reports/usecases/save_report_file_usecase.dart';
import 'package:wowcare/domain/features/reports/usecases/open_report_file_usecase.dart';
import 'package:wowcare/domain/features/reports/entities/report_entity.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/repositories/reports_repository.dart';
import 'package:wowcare/domain/features/reports/usecases/download_report_usecase.dart';
import 'package:wowcare/domain/features/reports/usecases/generate_report_usecase.dart';
import 'package:wowcare/domain/features/reports/usecases/get_recent_reports_usecase.dart';
import 'package:wowcare/domain/features/reports/usecases/get_student_tags_usecase.dart';
import 'package:wowcare/domain/features/reports/usecases/report_params.dart';
import 'package:wowcare/domain/features/reports/usecases/staff_scheduling_report_params.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/presentation/features/auth/view_model/auth_cubit.dart';
import 'package:wowcare/presentation/features/communication/view_model/unread_badge_cubit.dart';
import 'package:wowcare/presentation/features/communication/view_model/unread_badge_state.dart';
import 'package:wowcare/presentation/features/notifications/view_model/notification_badge_cubit.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/view/staff_schedule_report_screen.dart';
import 'package:wowcare/presentation/features/user_profile/view_model/profile_menu_header_cubit.dart';
import 'package:wowcare/presentation/features/user_profile/view_model/user_profile_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/domain/features/classroom/repositories/classroom_repository.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/domain/features/student_classroom/entities/student_classroom_item.dart';
import 'package:wowcare/domain/features/student_classroom/repositories/student_classroom_repository.dart';
import 'package:wowcare/domain/features/student_classroom/usecases/get_student_classroom_list_usecase.dart';
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

class _FakeAuthLocalDataSource implements AuthLocalDataSource {
  @override
  Future<List<Map<String, String>>> getOrganizationsAndSchools() async => [];

  @override
  Future<Map<String, dynamic>?> getLoginContext() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeReportsRepository implements ReportsRepository {
  ReportParams? lastGeneratedParams;

  @override
  Future<ReportEntity> generateReport(ReportParams params) async {
    lastGeneratedParams = params;
    return ReportEntity(
      reportId: 'TASK_123',
      reportType: params.reportType,
      generatedAt: DateTime.now(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStudentRepository implements StudentRepository {
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
  bool get isStaff => false;
  bool get isTeacher => false;
  @override
  bool get isAdmin => true;
  bool get isSuperAdmin => false;
  bool get isPrincipal => false;
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

  late _FakeReportsRepository fakeReportsRepo;
  late _FakeStorageService fakeStorageService;
  late ReportsCubit reportsCubit;

  final classrooms = ['1-Class A', 'Office', 'Primary Room'];
  final classroomLookup = {
    '1-Class A': 'CLS_06C3AF97-6',
    'Office': 'CLS_OFFICE_01',
    'Primary Room': 'CLS_PRIMARY_01',
  };

  setUp(() async {
    await serviceLocator.reset();
    fakeReportsRepo = _FakeReportsRepository();
    fakeStorageService = _FakeStorageService();
    final mockStudentRepo = _FakeStudentRepository();

    serviceLocator.registerSingleton<StorageService>(fakeStorageService);
    serviceLocator.registerSingleton<AuthLocalDataSource>(
      _FakeAuthLocalDataSource(),
    );

    reportsCubit = ReportsCubit(
      getSchoolCodeUseCase: GetSchoolCodeUseCase(
        _FakeSchoolContextRepository(),
      ),
      getSchoolNameUseCase: GetSchoolNameUseCase(
        _FakeSchoolContextRepository(),
      ),
      generateReportUseCase: GenerateReportUseCase(fakeReportsRepo),
      getRecentReportsUseCase: GetRecentReportsUseCase(fakeReportsRepo),
      getStudentTagsUseCase: GetStudentTagsUseCase(fakeReportsRepo),
      downloadReportUseCase: DownloadReportUseCase(fakeReportsRepo),
      saveReportFileUseCase: SaveReportFileUseCase(
        _FakeFileDownloadRepository(),
      ),
      openReportFileUseCase: OpenReportFileUseCase(
        _FakeFileDownloadRepository(),
      ),
      getActiveClassroomsUseCase: GetActiveClassroomsUseCase(
        _FakeClassroomRepository(classroomLookup),
      ),
      getStudentClassroomListUseCase: GetStudentClassroomListUseCase(
        _FakeStudentClassroomRepo(),
      ),
      getImmunizationSettingsUseCase: GetImmunizationSettingsUseCase(
        _FakeStudentRepository(),
      ),
      getTagNameCodeMapForSchoolUseCase: GetTagNameCodeMapForSchoolUseCase(
        mockStudentRepo,
      ),
    );

    reportsCubit.setClassroomNames(classrooms, nameToCodeMap: classroomLookup);
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
                  builder: (_, __) =>
                      StaffScheduleReportScreen(classrooms: classrooms),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  testWidgets(
    'A fresh form generates STAFF_SCHEDULING with no classroom filter',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final generateBtnFinder = find.text('Generate Report');
      expect(generateBtnFinder, findsOneWidget);
      await tester.tap(generateBtnFinder);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(fakeReportsRepo.lastGeneratedParams, isNotNull);
      final params =
          fakeReportsRepo.lastGeneratedParams as StaffSchedulingReportParams;
      expect(params.reportType, ReportType.staffScheduling);
      // "All classrooms" is the absence of the key, never an implicitly
      // expanded list of every code.
      expect(params.classroomCodes, isNull);

      final requestBody = ReportRequestPayload.fromParams(params).toJson();
      expect(requestBody.containsKey('classroomCodes'), isFalse);
    },
  );
}

/// Returns the fixture classrooms so the form's `loadFormClassrooms` call
/// resolves to the same list the screen was handed, matching what the old
/// in-view fetch produced.
class _FakeClassroomRepository implements ClassroomRepository {
  _FakeClassroomRepository(this.nameToCode);

  final Map<String, String> nameToCode;

  @override
  Future<List<Classroom>> getActiveClassrooms({
    required String schoolCode,
    bool onlyTypeClassroom = true,
    String? typeOverride,
  }) async => nameToCode.entries
      .map((e) => Classroom(code: e.value, name: e.key))
      .toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The reports cubit now owns the per-classroom student fetch, so it needs a
/// student-classroom source. These screens never exercise it; an empty source
/// keeps construction valid without changing what the tests assert.
class _FakeStudentClassroomRepo implements StudentClassroomRepository {
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
  }) async => const <StudentClassroomItem>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
