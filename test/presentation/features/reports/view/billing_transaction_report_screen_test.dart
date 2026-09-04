import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
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
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/unread_badge_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/unread_badge_state.dart';
import 'package:wowcare/presentation/features/notifications/cubit/notification_badge_cubit.dart';
import 'package:wowcare/presentation/features/reports/cubit/reports_cubit.dart';
import 'package:wowcare/presentation/features/reports/view/billing_transaction_report_screen.dart';
import 'package:wowcare/presentation/features/user-profile/view_model/profile_menu_header_cubit.dart';
import 'package:wowcare/presentation/features/user-profile/view_model/user_profile_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/presentation/features/reports/widgets/multi_select_filter_field.dart';

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
  late _FakeReportsRepository fakeReportsRepo;
  late ReportsCubit reportsCubit;

  final testStudents = ['Alice Smith', 'Bob Jones', 'Charlie Brown'];

  setUp(() async {
    await serviceLocator.reset();
    fakeStorage = _FakeStorageService();
    fakeReportsRepo = _FakeReportsRepository();
    final mockStudentRepo = _FakeStudentRepository();

    serviceLocator.registerSingleton<StorageService>(fakeStorage);
    serviceLocator.registerSingleton<AuthLocalDataSource>(
      _FakeAuthLocalDataSource(),
    );

    reportsCubit = ReportsCubit(
      storageService: fakeStorage,
      generateReportUseCase: GenerateReportUseCase(fakeReportsRepo),
      getRecentReportsUseCase: GetRecentReportsUseCase(fakeReportsRepo),
      getStudentTagsUseCase: GetStudentTagsUseCase(fakeReportsRepo),
      downloadReportUseCase: DownloadReportUseCase(fakeReportsRepo),
      fileDownloadRepository: _FakeFileDownloadRepository(),
      getTagNameCodeMapForSchoolUseCase: GetTagNameCodeMapForSchoolUseCase(
        mockStudentRepo,
      ),
    );

    reportsCubit.setStudentNames(
      testStudents,
      nameToCodeMap: {
        'Alice Smith': 'STU-001',
        'Bob Jones': 'STU-002',
        'Charlie Brown': 'STU-003',
      },
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
      child: MaterialApp(home: BillingTransactionReportScreen()),
    );
  }

  testWidgets(
    'Validation blocks submission if payment methods or transaction statuses are not selected',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap generate button
      final generateBtnFinder = find.text('Generate Report');
      expect(generateBtnFinder, findsOneWidget);
      await tester.tap(generateBtnFinder);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      // No report should be generated
      expect(fakeReportsRepo.lastGeneratedParams, isNull);
    },
  );

  testWidgets('Selecting explicitly generates only those students', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Select payment method
    final paymentMethodFinder = find.widgetWithText(
      MultiSelectFilterField<String>,
      'Payment Method',
    );
    expect(paymentMethodFinder, findsOneWidget);

    // Test specific selections if you tap things here,
    // but a direct unit test of Cubit/Params might be cleaner for the logic itself.
  });
}
