import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
import '../../core/network/auth_interceptor.dart';
import '../../core/network/session_expired_interceptor.dart';
import '../../core/network/network_info.dart';
import '../../core/storage/storage_service.dart';
import '../../core/util/api_constants.dart';
import '../../data/features/auth/datasources/auth_local_datasource.dart';
import '../../data/features/auth/datasources/auth_remote_datasource.dart';
import '../../data/features/auth/repositories/auth_repository_impl.dart';
import '../../data/features/onboarding/datasources/onboarding_remote_datasource.dart';
import '../../data/features/classroom/datasources/classroom_remote_datasource.dart';
import '../../data/features/classroom/repositories/classroom_repository_impl.dart';
import '../../data/features/onboarding/repositories/onboarding_repository_impl.dart';
import '../../data/features/staff/datasources/staff_remote_datasource.dart';
import '../../data/features/staff/repositories/staff_repository_impl.dart';
import '../../data/features/student/datasources/student_remote_datasource.dart';
import '../../data/features/student/repositories/student_repository_impl.dart';
import '../../data/features/attendance/datasources/attendance_remote_datasource.dart';
import '../../data/features/attendance/repositories/attendance_repository_impl.dart';
import '../../domain/features/auth/repositories/auth_repository.dart';
import '../../domain/features/auth/usecases/login_usecase.dart';
import '../../domain/features/auth/usecases/forgot_password_usecase.dart';
import '../../domain/features/classroom/repositories/classroom_repository.dart';
import '../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import '../../domain/features/classroom/usecases/get_classroom_by_code_usecase.dart';
import '../../domain/features/onboarding/repositories/onboarding_repository.dart';
import '../../domain/features/onboarding/usecases/get_onboarding_content.dart';
import '../../domain/features/staff/repositories/staff_repository.dart';
import '../../domain/features/staff/usecases/get_staff_page_usecase.dart';
import '../../domain/features/staff/usecases/get_staff_count_usecase.dart';
import '../../domain/features/staff/usecases/add_staff_document_usecase.dart';
import '../../domain/features/staff/usecases/update_staff_document_usecase.dart';
import '../../domain/features/staff/usecases/delete_staff_document_usecase.dart';
import '../../domain/features/staff/usecases/get_staff_documents_usecase.dart';
import '../../domain/features/staff/usecases/get_staff_profile_usecase.dart';
import '../../domain/features/staff/usecases/get_important_dates_usecase.dart';
import '../../domain/features/staff/usecases/update_important_dates_usecase.dart';
import '../../domain/features/staff/usecases/create_school_user_usecase.dart';
import '../../domain/features/student/repositories/student_repository.dart';
import '../../domain/features/student/usecases/get_student_page_usecase.dart';
import '../../domain/features/student/usecases/get_student_counts_usecase.dart';
import '../../domain/features/student_classroom/repositories/student_classroom_repository.dart';
import '../../domain/features/student_classroom/usecases/get_student_classroom_list_usecase.dart';
import '../../domain/features/student_classroom/usecases/assign_students_to_classroom_usecase.dart';
import '../../data/features/student_classroom/datasources/student_classroom_remote_datasource.dart';
import '../../data/features/student_classroom/repositories/student_classroom_repository_impl.dart';
import '../../domain/features/staff_classroom/repositories/staff_classroom_repository.dart';
import '../../domain/features/staff_classroom/usecases/get_staff_classrooms_usecase.dart';
import '../../domain/features/staff_classroom/usecases/assign_staff_to_classroom_usecase.dart';
import '../../data/features/staff_classroom/datasources/staff_classroom_remote_datasource.dart';
import '../../data/features/staff_classroom/repositories/staff_classroom_repository_impl.dart';
import '../../domain/features/attendance/repositories/attendance_repository.dart';
import '../../domain/features/attendance/usecases/get_student_attendance_daily_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_attendance_expected_summary_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_attendance_custom_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_sign_in_form_list_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_sign_out_form_list_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_transfer_form_list_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_absent_form_list_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_attendance_absent_toggle_view_usecase.dart';
import '../../domain/features/attendance/usecases/mark_students_absent_usecase.dart';
import '../../domain/features/attendance/usecases/get_staff_attendance_daily_usecase.dart';
import '../../domain/features/attendance/usecases/get_staff_attendance_custom_usecase.dart';
import '../../domain/features/attendance/usecases/get_staff_attendance_absent_usecase.dart';
import '../../domain/features/attendance/usecases/get_staff_attendance_absent_toggle_view_usecase.dart';
import '../../domain/features/attendance/usecases/get_staff_attendance_expected_summary_usecase.dart';
import '../../domain/features/attendance/usecases/get_staff_sign_in_form_list_usecase.dart';
import '../../domain/features/attendance/usecases/get_staff_sign_out_form_list_usecase.dart';
import '../../domain/features/attendance/usecases/get_staff_transfer_form_list_usecase.dart';
import '../../domain/features/attendance/usecases/get_staff_absent_form_list_usecase.dart';
import '../../domain/features/attendance/usecases/mark_staff_absent_usecase.dart';
import '../../domain/features/attendance/usecases/get_staff_today_sign_in_status_usecase.dart';
import '../../domain/features/attendance/usecases/get_staff_today_sign_in_status_map_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_today_sign_in_status_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_today_sign_in_status_map_usecase.dart';
import '../../domain/features/attendance/usecases/update_student_attendance_record_usecase.dart';
import '../../domain/features/student/usecases/get_student_documents_usecase.dart';
import '../../domain/features/student/usecases/add_student_document_usecase.dart';
import '../../domain/features/student/usecases/get_student_important_dates_usecase.dart';
import '../../domain/features/student/usecases/update_student_important_dates_usecase.dart';
import '../../domain/features/student/usecases/update_student_document_usecase.dart';
import '../../domain/features/student/usecases/delete_student_document_usecase.dart';
import '../../domain/features/student/usecases/get_guardian_names_for_school_usecase.dart';
import '../../domain/features/student/usecases/get_tag_names_for_school_usecase.dart';
import '../../domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import '../../domain/features/student/usecases/get_guardian_name_code_map_for_school_usecase.dart';
import '../../domain/features/activity/repositories/activity_repository.dart';
import '../../domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import '../../domain/features/activity/usecases/get_activity_type_details_usecase.dart';
import '../../domain/features/activity/usecases/create_activity_usecase.dart';
import '../../domain/features/activity/usecases/get_activity_usecase.dart';
import '../../domain/features/activity/usecases/update_activity_usecase.dart';
import '../../domain/features/activity/usecases/delete_activity_usecase.dart';
import '../../domain/features/activity/usecases/create_activity_upload_sessions_usecase.dart';
import '../../domain/features/activity/usecases/create_activity_asset_presign_usecase.dart';
import '../../domain/features/activity/usecases/get_daily_activity_feed_usecase.dart';
import '../../domain/features/activity/usecases/get_range_activity_feed_usecase.dart';
import '../../data/features/activity/datasources/activity_remote_datasource.dart';
import '../../data/features/activity/repositories/activity_repository_impl.dart';
import '../../presentation/features/auth/cubit/auth_cubit.dart';
import '../../presentation/features/classroom/cubit/classroom_cubit.dart';
import '../../presentation/features/classrooom/cubit/classroom_students_cubit.dart';
import '../../presentation/features/classrooom/cubit/classroom_staff_cubit.dart';
import '../../presentation/features/staff/cubit/staff_cubit.dart';
import '../../presentation/features/staff/cubit/staff_document_cubit.dart';
import '../../presentation/features/staff/cubit/staff_documents_list_cubit.dart';
import '../../presentation/features/staff/cubit/staff_profile_cubit.dart';
import '../../presentation/features/staff/cubit/important_dates_cubit.dart';
import '../../presentation/features/staff/cubit/create_school_user_cubit.dart';
import '../../presentation/features/student/cubit/student_cubit.dart';
import '../../presentation/features/attendance/cubit/student_attendance_daily_cubit.dart';
import '../../presentation/features/attendance/cubit/student_attendance_custom_cubit.dart';
import '../../presentation/features/attendance/cubit/student_attendance_absent_toggle_cubit.dart';
import '../../presentation/features/attendance/cubit/staff_attendance_daily_cubit.dart';
import '../../presentation/features/attendance/cubit/staff_attendance_custom_cubit.dart';
import '../../presentation/features/attendance/cubit/staff_attendance_absent_cubit.dart';
import '../../presentation/features/attendance/cubit/staff_attendance_absent_toggle_cubit.dart';
import '../../presentation/features/students/cubit/student_documents_list_cubit.dart';
import '../../presentation/features/students/cubit/student_document_cubit.dart';
import '../../presentation/features/students/cubit/student_important_dates_cubit.dart';
import '../../shared/services/image_upload/image_upload_service.dart';

final GetIt serviceLocator = GetIt.instance;

Future<void> configureDependencies({String? baseUrl}) async {
  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Base URL
  final apiBaseUrl = baseUrl ?? ApiConstants.baseUrl;

  // Core
  serviceLocator.registerLazySingleton<Connectivity>(() => Connectivity());
  serviceLocator.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(serviceLocator()));
  serviceLocator.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  serviceLocator.registerLazySingleton<StorageService>(
    () => StorageServiceImpl(serviceLocator()),
  );

  serviceLocator.registerLazySingleton<ApiClient>(() => ApiClient(
        baseUrl: apiBaseUrl,
        interceptors: <Interceptor>[
          AuthInterceptor(serviceLocator<StorageService>()),
          SessionExpiredInterceptor(serviceLocator<StorageService>()),
        ],
      ));
  serviceLocator.registerLazySingleton<ImageUploadService>(
    () => ImageUploadService(serviceLocator<ApiClient>()),
  );

  // Auth Data Sources
  serviceLocator.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );
  serviceLocator.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(serviceLocator()),
  );

  // Staff Data Sources
  serviceLocator.registerLazySingleton<StaffRemoteDataSource>(
    () => StaffRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );

  // Student Data Sources
  serviceLocator.registerLazySingleton<StudentRemoteDataSource>(
    () => StudentRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );

  // Attendance Data Sources
  serviceLocator.registerLazySingleton<AttendanceRemoteDataSource>(
    () => AttendanceRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );

  // Classroom Data Sources
  serviceLocator.registerLazySingleton<ClassroomRemoteDataSource>(
    () => ClassroomRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );

  // Activity Data Sources
  serviceLocator.registerLazySingleton<ActivityRemoteDataSource>(
    () => ActivityRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );

  // Student-Classroom Data Sources
  serviceLocator.registerLazySingleton<StudentClassroomRemoteDataSource>(
    () =>
        StudentClassroomRemoteDataSourceImpl(
          serviceLocator<ApiClient>().client,
          serviceLocator<StorageService>(),
        ),
  );

  // Staff-Classroom Data Sources
  serviceLocator.registerLazySingleton<StaffClassroomRemoteDataSource>(
    () => StaffClassroomRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );

  // Onboarding Data Sources
  serviceLocator.registerLazySingleton<OnboardingRemoteDataSource>(
    () => OnboardingRemoteDataSourceMock(),
  );

  // Repositories
  serviceLocator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      serviceLocator(),
      serviceLocator(),
      serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(
      serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<StaffRepository>(
    () => StaffRepositoryImpl(
      serviceLocator(),
      serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<ClassroomRepository>(
    () => ClassroomRepositoryImpl(
      serviceLocator(),
      serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<StudentRepository>(
    () => StudentRepositoryImpl(
      serviceLocator(),
      serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(
      serviceLocator(),
      serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<StudentClassroomRepository>(
    () => StudentClassroomRepositoryImpl(
      serviceLocator(),
      serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<StaffClassroomRepository>(
    () => StaffClassroomRepositoryImpl(
      serviceLocator(),
      serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<ActivityRepository>(
    () => ActivityRepositoryImpl(
      serviceLocator(),
      serviceLocator(),
    ),
  );

  // Use cases
  serviceLocator.registerFactory<LoginUseCase>(
    () => LoginUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<ForgotPasswordUseCase>(
    () => ForgotPasswordUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetOnboardingContent>(
    () => GetOnboardingContent(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffPageUseCase>(
    () => GetStaffPageUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffCountUseCase>(
    () => GetStaffCountUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<AddStaffDocumentUseCase>(
    () => AddStaffDocumentUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<UpdateStaffDocumentUseCase>(
    () => UpdateStaffDocumentUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<DeleteStaffDocumentUseCase>(
    () => DeleteStaffDocumentUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffDocumentsUseCase>(
    () => GetStaffDocumentsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffProfileUseCase>(
    () => GetStaffProfileUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetImportantDatesUseCase>(
    () => GetImportantDatesUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<UpdateImportantDatesUseCase>(
    () => UpdateImportantDatesUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<CreateSchoolUserUseCase>(
    () => CreateSchoolUserUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetActiveClassroomsUseCase>(
    () => GetActiveClassroomsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetClassroomByCodeUseCase>(
    () => GetClassroomByCodeUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentPageUseCase>(
    () => GetStudentPageUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentAttendanceDailyUseCase>(
    () => GetStudentAttendanceDailyUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentAttendanceExpectedSummaryUseCase>(
    () => GetStudentAttendanceExpectedSummaryUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentAttendanceCustomUseCase>(
    () => GetStudentAttendanceCustomUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentSignInFormListUseCase>(
    () => GetStudentSignInFormListUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentSignOutFormListUseCase>(
    () => GetStudentSignOutFormListUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentTransferFormListUseCase>(
    () => GetStudentTransferFormListUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentAbsentFormListUseCase>(
    () => GetStudentAbsentFormListUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentAttendanceAbsentToggleViewUseCase>(
    () => GetStudentAttendanceAbsentToggleViewUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<MarkStudentsAbsentUseCase>(
    () => MarkStudentsAbsentUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffAttendanceDailyUseCase>(
    () => GetStaffAttendanceDailyUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffAttendanceExpectedSummaryUseCase>(
    () => GetStaffAttendanceExpectedSummaryUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffAttendanceCustomUseCase>(
    () => GetStaffAttendanceCustomUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffAttendanceAbsentUseCase>(
    () => GetStaffAttendanceAbsentUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffAttendanceAbsentToggleViewUseCase>(
    () => GetStaffAttendanceAbsentToggleViewUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffSignInFormListUseCase>(
    () => GetStaffSignInFormListUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffSignOutFormListUseCase>(
    () => GetStaffSignOutFormListUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffTransferFormListUseCase>(
    () => GetStaffTransferFormListUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffAbsentFormListUseCase>(
    () => GetStaffAbsentFormListUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<MarkStaffAbsentUseCase>(
    () => MarkStaffAbsentUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffTodaySignInStatusUseCase>(
    () => GetStaffTodaySignInStatusUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffTodaySignInStatusMapUseCase>(
    () => GetStaffTodaySignInStatusMapUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentTodaySignInStatusUseCase>(
    () => GetStudentTodaySignInStatusUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentTodaySignInStatusMapUseCase>(
    () => GetStudentTodaySignInStatusMapUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<UpdateStudentAttendanceRecordUseCase>(
    () => UpdateStudentAttendanceRecordUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentDocumentsUseCase>(
    () => GetStudentDocumentsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<AddStudentDocumentUseCase>(
    () => AddStudentDocumentUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentImportantDatesUseCase>(
    () => GetStudentImportantDatesUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<UpdateStudentImportantDatesUseCase>(
    () => UpdateStudentImportantDatesUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<UpdateStudentDocumentUseCase>(
    () => UpdateStudentDocumentUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<DeleteStudentDocumentUseCase>(
    () => DeleteStudentDocumentUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetGuardianNamesForSchoolUseCase>(
    () => GetGuardianNamesForSchoolUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetTagNamesForSchoolUseCase>(
    () => GetTagNamesForSchoolUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetTagNameCodeMapForSchoolUseCase>(
    () => GetTagNameCodeMapForSchoolUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetGuardianNameCodeMapForSchoolUseCase>(
    () => GetGuardianNameCodeMapForSchoolUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentCountsUseCase>(
    () => GetStudentCountsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetClassroomActivitySettingsUseCase>(
    () => GetClassroomActivitySettingsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetActivityTypeDetailsUseCase>(
    () => GetActivityTypeDetailsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<CreateActivityUseCase>(
    () => CreateActivityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetActivityUseCase>(
    () => GetActivityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<UpdateActivityUseCase>(
    () => UpdateActivityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<DeleteActivityUseCase>(
    () => DeleteActivityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<CreateActivityUploadSessionsUseCase>(
    () => CreateActivityUploadSessionsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<CreateActivityAssetPresignUseCase>(
    () => CreateActivityAssetPresignUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetDailyActivityFeedUseCase>(
    () => GetDailyActivityFeedUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetRangeActivityFeedUseCase>(
    () => GetRangeActivityFeedUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentClassroomListUseCase>(
    () => GetStudentClassroomListUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<AssignStudentsToClassroomUseCase>(
    () => AssignStudentsToClassroomUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffClassroomsUseCase>(
    () => GetStaffClassroomsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<AssignStaffToClassroomUseCase>(
    () => AssignStaffToClassroomUseCase(serviceLocator()),
  );

  // Cubits (factory - new instance each time for UI)
  serviceLocator.registerFactory<AuthCubit>(
    () => AuthCubit(
      loginUseCase: serviceLocator(),
      localDataSource: serviceLocator(),
      remoteDataSource: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StaffCubit>(
    () => StaffCubit(
      getStaffPageUseCase: serviceLocator(),
      getStaffCountUseCase: serviceLocator(),
      repository: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StaffDocumentCubit>(
    () => StaffDocumentCubit(
      addStaffDocumentUseCase: serviceLocator(),
      updateStaffDocumentUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StaffDocumentsListCubit>(
    () => StaffDocumentsListCubit(
      getStaffDocumentsUseCase: serviceLocator(),
      deleteStaffDocumentUseCase: serviceLocator(),
      repository: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StaffProfileCubit>(
    () => StaffProfileCubit(
      getStaffProfileUseCase: serviceLocator(),
      repository: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<ImportantDatesCubit>(
    () => ImportantDatesCubit(
      updateImportantDatesUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<CreateSchoolUserCubit>(
    () => CreateSchoolUserCubit(
      createSchoolUserUseCase: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<ClassroomCubit>(
    () => ClassroomCubit(
      getActiveClassroomsUseCase: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<ClassroomStudentsCubit>(
    () => ClassroomStudentsCubit(
      getStudentClassroomListUseCase: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<ClassroomStaffCubit>(
    () => ClassroomStaffCubit(
      getStaffClassroomsUseCase: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentCubit>(
    () => StudentCubit(
      getStudentPageUseCase: serviceLocator(),
      repository: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentAttendanceDailyCubit>(
    () => StudentAttendanceDailyCubit(
      getStudentAttendanceDailyUseCase: serviceLocator(),
      getStudentAttendanceExpectedSummaryUseCase: serviceLocator(),
      repository: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentAttendanceAbsentToggleCubit>(
    () => StudentAttendanceAbsentToggleCubit(
      getStudentAttendanceAbsentToggleViewUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentAttendanceCustomCubit>(
    () => StudentAttendanceCustomCubit(
      getStudentAttendanceCustomUseCase: serviceLocator(),
      repository: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StaffAttendanceDailyCubit>(
    () => StaffAttendanceDailyCubit(
      getStaffAttendanceDailyUseCase: serviceLocator(),
      getStaffAttendanceExpectedSummaryUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StaffAttendanceCustomCubit>(
    () => StaffAttendanceCustomCubit(
      getStaffAttendanceCustomUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StaffAttendanceAbsentCubit>(
    () => StaffAttendanceAbsentCubit(
      getStaffAttendanceAbsentUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StaffAttendanceAbsentToggleCubit>(
    () => StaffAttendanceAbsentToggleCubit(
      getStaffAttendanceAbsentToggleViewUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentDocumentsListCubit>(
    () => StudentDocumentsListCubit(
      getStudentDocumentsUseCase: serviceLocator(),
      deleteStudentDocumentUseCase: serviceLocator(),
      repository: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentDocumentCubit>(
    () => StudentDocumentCubit(
      addStudentDocumentUseCase: serviceLocator(),
      updateStudentDocumentUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentImportantDatesCubit>(
    () => StudentImportantDatesCubit(
      updateStudentImportantDatesUseCase: serviceLocator(),
    ),
  );
}


