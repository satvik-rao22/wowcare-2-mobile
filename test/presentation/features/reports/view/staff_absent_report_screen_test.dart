import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/data/features/reports/repositories/file_download_repository.dart';
import 'package:wowcare/domain/features/reports/entities/report_entity.dart';
import 'package:wowcare/domain/features/reports/entities/report_type.dart';
import 'package:wowcare/domain/features/reports/repositories/reports_repository.dart';
import 'package:wowcare/domain/features/reports/usecases/download_report_usecase.dart';
import 'package:wowcare/domain/features/reports/usecases/generate_report_usecase.dart';
import 'package:wowcare/domain/features/reports/usecases/get_recent_reports_usecase.dart';
import 'package:wowcare/domain/features/reports/usecases/get_student_tags_usecase.dart';
import 'package:wowcare/domain/features/reports/usecases/report_params.dart';
import 'package:wowcare/domain/features/reports/usecases/report_request_params.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_names_for_school_usecase.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/unread_badge_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/unread_badge_state.dart';
import 'package:wowcare/presentation/features/notifications/cubit/notification_badge_cubit.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/view/staff_absent_report_screen.dart';
import 'package:wowcare/presentation/features/user-profile/view_model/profile_menu_header_cubit.dart';
import 'package:wowcare/presentation/features/user-profile/view_model/user_profile_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

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
  @override
  bool get isTeacher => false;
  @override
  bool get isAdmin => true;
  @override
  bool get isSuperAdmin => false;
  @override
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

  final classrooms = ['1-Class A', 'Class B'];
  final classroomLookup = {
    '1-Class A': 'CLS_06C3AF97-6',
    'Class B': 'CLS_BE1976C6-1',
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
      storageService: fakeStorageService,
      getTagNamesForSchoolUseCase: GetTagNamesForSchoolUseCase(mockStudentRepo),
      generateReportUseCase: GenerateReportUseCase(fakeReportsRepo),
      getRecentReportsUseCase: GetRecentReportsUseCase(fakeReportsRepo),
      getStudentTagsUseCase: GetStudentTagsUseCase(fakeReportsRepo),
      downloadReportUseCase: DownloadReportUseCase(fakeReportsRepo),
      fileDownloadRepository: _FakeFileDownloadRepository(),
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
      child: MaterialApp(
        home: StaffAbsentReportScreen(classrooms: classrooms),
      ),
    );
  }

  testWidgets(
    'Tapping Generate generates STAFF_ABSENT with roomCodes',
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
          fakeReportsRepo.lastGeneratedParams as ReportRequestParams;
      expect(params.reportType, ReportType.staffAbsent);
      expect(params.roomCodes, [
        'CLS_06C3AF97-6',
        'CLS_BE1976C6-1',
      ]);

      final requestBody = params.toRequestBody();
      expect(requestBody['reportType'], 'STAFF_ABSENT');
      expect(requestBody['roomCodes'], [
        'CLS_06C3AF97-6',
        'CLS_BE1976C6-1',
      ]);
      expect(requestBody.containsKey('startDate'), isTrue);
      expect(requestBody.containsKey('endDate'), isTrue);
    },
  );
}
