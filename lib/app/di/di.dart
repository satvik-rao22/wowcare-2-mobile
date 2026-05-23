import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/network/auth_interceptor.dart';
import '../../core/network/network_info.dart';
import '../../core/network/session_expired_interceptor.dart';
import '../../core/storage/storage_service.dart';
import '../../core/util/api_constants.dart';
import '../../core/cache/cache_service.dart';
import '../../core/cache/isar_cache_service.dart';
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
import '../../data/features/availability/datasources/availability_remote_datasource.dart';
import '../../data/features/availability/repositories/availability_repository_impl.dart';
import '../../data/features/scheduling/datasources/staff_shift_remote_datasource.dart';
import '../../data/features/scheduling/repositories/staff_shift_repository_impl.dart';
import '../../core/util/cache_manager.dart';
import '../../domain/features/scheduling/repositories/staff_shift_repository.dart';
import '../../domain/features/scheduling/usecases/create_staff_shift_usecase.dart';
import '../../domain/features/scheduling/usecases/delete_staff_shift_series_usecase.dart';
import '../../domain/features/scheduling/usecases/delete_staff_shift_usecase.dart';
import '../../domain/features/scheduling/usecases/update_staff_shift_series_usecase.dart';
import '../../domain/features/scheduling/usecases/update_staff_shift_usecase.dart';
import '../../domain/features/scheduling/usecases/get_staff_shift_by_code_usecase.dart';
import '../../domain/features/scheduling/usecases/get_staff_shifts_usecase.dart';
import '../../domain/features/scheduling/usecases/get_classroom_forecast_range_usecase.dart';
import '../../domain/features/scheduling/usecases/get_classroom_forecast_usecase.dart';
import '../../domain/features/scheduling/usecases/get_staff_shift_hours_range_usecase.dart';
import '../../domain/features/scheduling/usecases/get_school_staff_shifts_usecase.dart';
import '../../domain/features/scheduling/usecases/publish_staff_shifts_usecase.dart';
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
import '../../domain/features/staff/usecases/get_all_staff_usecase.dart';
import '../../data/features/scheduling/datasources/staff_scheduling_remote_datasource.dart';
import '../../data/features/scheduling/repositories/staff_scheduling_repository_impl.dart';
import '../../domain/features/scheduling/repositories/staff_scheduling_repository.dart';
import '../../domain/features/staff/usecases/get_staff_shifts_usecase.dart';
import '../../presentation/features/scheduling/cubit/scheduling_cubit.dart';
import '../../presentation/features/scheduling/cubit/staff_scheduling_cubit.dart';
import '../../presentation/features/scheduling/cubit/scheduling_staff_list_cubit.dart';
import '../../presentation/features/scheduling/cubit/publish_shifts_cubit.dart';
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
import '../../domain/features/availability/repositories/availability_repository.dart';
import '../../domain/features/availability/usecases/create_individual_movement_usecase.dart';
import '../../domain/features/availability/usecases/delete_individual_movement_usecase.dart';
import '../../domain/features/availability/usecases/get_future_availability_usecase.dart';
import '../../domain/features/availability/usecases/get_individual_movement_by_id_usecase.dart';
import '../../domain/features/availability/usecases/get_individual_movements_usecase.dart';
import '../../domain/features/availability/usecases/transition_individual_movement_status_usecase.dart';
import '../../domain/features/availability/usecases/update_individual_movement_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_attendance_expected_summary_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_attendance_custom_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_sign_in_form_list_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_sign_out_form_list_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_transfer_form_list_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_absent_form_list_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_absent_records_activity_usecase.dart';
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
import '../../domain/features/student/usecases/get_student_codes_for_activity_tag_filter_usecase.dart';
import '../../domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import '../../domain/features/student/usecases/get_guardian_name_code_map_for_school_usecase.dart';
import '../../domain/features/activity/repositories/activity_repository.dart';
import '../../domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import '../../domain/features/activity/usecases/get_active_activity_types_for_school_usecase.dart';
import '../../domain/features/activity/usecases/get_activity_type_details_usecase.dart';
import '../../domain/features/activity/usecases/create_activity_usecase.dart';
import '../../domain/features/activity/usecases/create_shared_activities_usecase.dart';
import '../../domain/features/activity/usecases/get_activity_usecase.dart';
import '../../domain/features/activity/usecases/update_activity_usecase.dart';
import '../../domain/features/activity/usecases/delete_activity_usecase.dart';
import '../../domain/features/activity/usecases/approve_activity_usecase.dart';
import '../../domain/features/activity/usecases/acknowledge_activity_usecase.dart';
import '../../domain/features/activity/usecases/guardian_parent_signature_usecase.dart';
import '../../domain/features/activity/usecases/reject_activity_usecase.dart';
import '../../domain/features/activity/usecases/create_activity_upload_sessions_usecase.dart';
import '../../domain/features/activity/usecases/create_activity_asset_presign_usecase.dart';
import '../../domain/features/activity/usecases/get_daily_activity_feed_usecase.dart';
import '../../domain/features/activity/usecases/get_range_activity_feed_usecase.dart';
import '../../domain/features/activity/usecases/get_nap_start_students_usecase.dart';
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
import '../../presentation/features/availability/cubit/future_availability_cubit.dart';
import '../../presentation/features/availability/cubit/individual_movements_cubit.dart';
import '../../presentation/features/attendance/cubit/student_attendance_custom_cubit.dart';
import '../../presentation/features/attendance/cubit/student_attendance_absent_toggle_cubit.dart';
import '../../presentation/features/attendance/cubit/staff_attendance_daily_cubit.dart';
import '../../presentation/features/attendance/cubit/staff_attendance_custom_cubit.dart';
import '../../presentation/features/attendance/cubit/staff_attendance_absent_cubit.dart';
import '../../presentation/features/attendance/cubit/staff_attendance_absent_toggle_cubit.dart';
import '../../presentation/features/students/cubit/student_documents_list_cubit.dart';
import '../../presentation/features/students/cubit/student_document_cubit.dart';
import '../../presentation/features/students/cubit/student_important_dates_cubit.dart';
import '../../domain/features/communication/repositories/communication_repository.dart';
import '../../domain/features/communication/usecases/get_messages_usecase.dart';
import '../../domain/features/communication/usecases/send_message_usecase.dart';
import '../../domain/features/communication/usecases/create_conversation_usecase.dart';
import '../../domain/features/communication/usecases/get_conversations_usecase.dart';
import '../../domain/features/communication/usecases/get_cached_conversations_usecase.dart';
import '../../data/features/communication/datasources/communication_remote_data_source.dart';
import '../../data/features/communication/repositories/communication_repository_impl.dart';
import '../../core/cache/session_local_cache_wiper.dart';
import '../../presentation/features/communication/cubit/communication_cubit.dart';
import '../../presentation/features/communication/cubit/create_conversation_cubit.dart';
import '../../shared/services/image_upload/image_upload_service.dart';

final GetIt serviceLocator = GetIt.instance;

Future<void> configureDependencies({String? baseUrl}) async {
  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Base URL
  final apiBaseUrl = baseUrl ?? ApiConstants.baseUrl;

  // Core
  serviceLocator.registerLazySingleton<Connectivity>(() => Connectivity());
  serviceLocator.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<SharedPreferences>(
    () => sharedPreferences,
  );
  serviceLocator.registerLazySingleton<StorageService>(
    () => StorageServiceImpl(serviceLocator()),
  );

  // Cache
  final isarCacheService = IsarCacheService();
  await isarCacheService.init();
  serviceLocator.registerLazySingleton<CacheService>(() => isarCacheService);

  serviceLocator.registerLazySingleton<ApiClient>(
    () => ApiClient(
      baseUrl: apiBaseUrl,
      interceptors: <Interceptor>[
        AuthInterceptor(serviceLocator<StorageService>()),
        SessionExpiredInterceptor(serviceLocator<StorageService>()),
      ],
    ),
  );
  serviceLocator.registerLazySingleton<ImageUploadService>(
    () => ImageUploadService(serviceLocator<ApiClient>()),
  );

  // Auth Data Sources
  serviceLocator.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
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
  serviceLocator.registerLazySingleton<AvailabilityRemoteDataSource>(
    () => AvailabilityRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );

  // Staff Scheduling (staff MS — `/api/v1/staff-shifts`)
  serviceLocator.registerLazySingleton<StaffSchedulingRemoteDataSource>(
    () => StaffSchedulingRemoteDataSourceImpl(
      serviceLocator<ApiClient>().client,
    ),
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
    () => StudentClassroomRemoteDataSourceImpl(
      serviceLocator<ApiClient>().client,
      serviceLocator<StorageService>(),
    ),
  );

  // Staff-Classroom Data Sources
  serviceLocator.registerLazySingleton<StaffClassroomRemoteDataSource>(
    () =>
        StaffClassroomRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );

  // Staff Shift (scheduling)
  serviceLocator.registerLazySingleton<StaffShiftRemoteDataSource>(
    () => StaffShiftRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );
  serviceLocator.registerLazySingleton<CacheManager>(
    () => CacheManager(serviceLocator<StorageService>()),
  );
  serviceLocator.registerLazySingleton<StaffShiftRepository>(
    () => StaffShiftRepositoryImpl(
      serviceLocator<StaffShiftRemoteDataSource>(),
      serviceLocator<CacheManager>(),
    ),
  );

  // Onboarding Data Sources
  serviceLocator.registerLazySingleton<OnboardingRemoteDataSource>(
    () => OnboardingRemoteDataSourceMock(),
  );

  // Communication Data Sources
  serviceLocator.registerLazySingleton<CommunicationRemoteDataSource>(
    () => CommunicationRemoteDataSourceImpl(apiClient: serviceLocator()),
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
    () => OnboardingRepositoryImpl(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<StaffRepository>(
    () => StaffRepositoryImpl(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerLazySingleton<ClassroomRepository>(
    () => ClassroomRepositoryImpl(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerLazySingleton<StudentRepository>(
    () => StudentRepositoryImpl(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(
      serviceLocator(),
      serviceLocator(),
      serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<AvailabilityRepository>(
    () => AvailabilityRepositoryImpl(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerLazySingleton<StaffSchedulingRepository>(
    () => StaffSchedulingRepositoryImpl(serviceLocator()),
  );
  serviceLocator.registerLazySingleton<StudentClassroomRepository>(
    () => StudentClassroomRepositoryImpl(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerLazySingleton<StaffClassroomRepository>(
    () => StaffClassroomRepositoryImpl(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerLazySingleton<ActivityRepository>(
    () => ActivityRepositoryImpl(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerLazySingleton<CommunicationRepository>(
    () => CommunicationRepositoryImpl(
      remoteDataSource: serviceLocator(),
      cacheService: serviceLocator(),
    ),
  );

  serviceLocator.registerLazySingleton<SessionLocalCacheWiper>(
    () => SessionLocalCacheWiper(
      cacheService: serviceLocator<CacheService>(),
      staffRepository: serviceLocator<StaffRepository>(),
    ),
  );
  serviceLocator.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      serviceLocator<StorageService>(),
      sessionLocalCacheWiper: serviceLocator<SessionLocalCacheWiper>(),
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
  serviceLocator.registerFactory<GetAllStaffUseCase>(
    () => GetAllStaffUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffShiftsForDayUseCase>(
    () => GetStaffShiftsForDayUseCase(
      serviceLocator<StaffSchedulingRepository>(),
    ),
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
  serviceLocator.registerFactory<GetIndividualMovementsUseCase>(
    () => GetIndividualMovementsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetIndividualMovementByIdUseCase>(
    () => GetIndividualMovementByIdUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetFutureAvailabilityUseCase>(
    () => GetFutureAvailabilityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<CreateIndividualMovementUseCase>(
    () => CreateIndividualMovementUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<UpdateIndividualMovementUseCase>(
    () => UpdateIndividualMovementUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<DeleteIndividualMovementUseCase>(
    () => DeleteIndividualMovementUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<TransitionIndividualMovementStatusUseCase>(
    () => TransitionIndividualMovementStatusUseCase(serviceLocator()),
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
  serviceLocator.registerFactory<GetStudentAbsentRecordsActivityUseCase>(
    () => GetStudentAbsentRecordsActivityUseCase(serviceLocator()),
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
    () => MarkStaffAbsentUseCase(
      serviceLocator(),
      serviceLocator<StaffShiftRepository>(),
      serviceLocator<StorageService>(),
    ),
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
  serviceLocator.registerFactory<GetStudentCodesForActivityTagFilterUseCase>(
    () => GetStudentCodesForActivityTagFilterUseCase(serviceLocator()),
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
  serviceLocator.registerFactory<GetActiveActivityTypesForSchoolUseCase>(
    () => GetActiveActivityTypesForSchoolUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetActivityTypeDetailsUseCase>(
    () => GetActivityTypeDetailsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<CreateActivityUseCase>(
    () => CreateActivityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<CreateSharedActivitiesUseCase>(
    () => CreateSharedActivitiesUseCase(serviceLocator()),
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
  serviceLocator.registerFactory<ApproveActivityUseCase>(
    () => ApproveActivityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<RejectActivityUseCase>(
    () => RejectActivityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<AcknowledgeActivityUseCase>(
    () => AcknowledgeActivityUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GuardianParentSignatureUseCase>(
    () => GuardianParentSignatureUseCase(serviceLocator()),
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
  serviceLocator.registerFactory<GetNapStartStudentsUseCase>(
    () => GetNapStartStudentsUseCase(serviceLocator()),
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
  serviceLocator.registerFactory<GetMessagesUseCase>(
    () => GetMessagesUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<SendMessageUseCase>(
    () => SendMessageUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<CreateConversationUseCase>(
    () => CreateConversationUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetConversationsUseCase>(
    () => GetConversationsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetCachedConversationsUseCase>(
    () => GetCachedConversationsUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStaffShiftsUseCase>(
    () => GetStaffShiftsUseCase(serviceLocator<StaffShiftRepository>()),
  );
  serviceLocator.registerFactory<CreateStaffShiftUseCase>(
    () => CreateStaffShiftUseCase(serviceLocator<StaffShiftRepository>()),
  );
  serviceLocator.registerFactory<UpdateStaffShiftUseCase>(
    () => UpdateStaffShiftUseCase(serviceLocator<StaffShiftRepository>()),
  );
  serviceLocator.registerFactory<UpdateStaffShiftSeriesUseCase>(
    () =>
        UpdateStaffShiftSeriesUseCase(serviceLocator<StaffShiftRepository>()),
  );
  serviceLocator.registerFactory<DeleteStaffShiftUseCase>(
    () => DeleteStaffShiftUseCase(serviceLocator<StaffShiftRepository>()),
  );
  serviceLocator.registerFactory<DeleteStaffShiftSeriesUseCase>(
    () =>
        DeleteStaffShiftSeriesUseCase(serviceLocator<StaffShiftRepository>()),
  );
  serviceLocator.registerFactory<GetStaffShiftByCodeUseCase>(
    () => GetStaffShiftByCodeUseCase(serviceLocator<StaffShiftRepository>()),
  );
  serviceLocator.registerFactory<GetSchoolStaffShiftsUseCase>(
    () => GetSchoolStaffShiftsUseCase(serviceLocator<StaffShiftRepository>()),
  );
  serviceLocator.registerFactory<GetClassroomForecastUseCase>(
    () => GetClassroomForecastUseCase(serviceLocator<StaffShiftRepository>()),
  );
  serviceLocator.registerFactory<GetClassroomForecastRangeUseCase>(
    () =>
        GetClassroomForecastRangeUseCase(serviceLocator<StaffShiftRepository>()),
  );
  serviceLocator.registerFactory<GetStaffShiftHoursRangeUseCase>(
    () => GetStaffShiftHoursRangeUseCase(serviceLocator<StaffShiftRepository>()),
  );
  serviceLocator.registerFactory<PublishStaffShiftsUseCase>(
    () => PublishStaffShiftsUseCase(serviceLocator<StaffShiftRepository>()),
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
    () => ImportantDatesCubit(updateImportantDatesUseCase: serviceLocator()),
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
  serviceLocator.registerFactory<IndividualMovementsCubit>(
    () => IndividualMovementsCubit(
      createIndividualMovementUseCase: serviceLocator(),
      updateIndividualMovementUseCase: serviceLocator(),
      deleteIndividualMovementUseCase: serviceLocator(),
      getIndividualMovementByIdUseCase: serviceLocator(),
      getIndividualMovementsUseCase: serviceLocator(),
      transitionIndividualMovementStatusUseCase: serviceLocator(),
      repository: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<FutureAvailabilityCubit>(
    () => FutureAvailabilityCubit(
      getFutureAvailabilityUseCase: serviceLocator(),
      repository: serviceLocator(),
      storageService: serviceLocator(),
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
  serviceLocator.registerFactory<CommunicationCubit>(
    () => CommunicationCubit(
      getMessagesUseCase: serviceLocator(),
      sendMessageUseCase: serviceLocator(),
      getConversationsUseCase: serviceLocator(),
      getCachedConversationsUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<CreateConversationCubit>(
    () => CreateConversationCubit(createConversationUseCase: serviceLocator()),
  );
  // Singleton so the scheduling staff list is loaded once per session and
  // shared between [StaffSchedulingCubit] (injected via DI) and the widget
  // tree (provided via `BlocProvider.value`). Lets AddShift reuse the cached
  // staff list instead of triggering a second fetch.
  serviceLocator.registerLazySingleton<SchedulingStaffListCubit>(
    () => SchedulingStaffListCubit(
      getAllStaffUseCase: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  // Singleton so state survives across screen entries — entering the route
  // a second time uses cached classrooms/shifts/staff and refreshes silently
  // in the background instead of flashing the full-page shimmer.
  serviceLocator.registerLazySingleton<StaffSchedulingCubit>(
    () => StaffSchedulingCubit(
      schedulingStaffListCubit: serviceLocator(),
      getSchoolStaffShiftsUseCase:
          serviceLocator<GetSchoolStaffShiftsUseCase>(),
      getStaffShiftHoursRangeUseCase:
          serviceLocator<GetStaffShiftHoursRangeUseCase>(),
      getActiveClassroomsUseCase: serviceLocator(),
      staffRepository: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<PublishShiftsCubit>(
    () => PublishShiftsCubit(
      publishStaffShiftsUseCase: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<SchedulingCubit>(
    () => SchedulingCubit(
      getSchoolStaffShiftsUseCase: serviceLocator(),
      getClassroomForecastUseCase: serviceLocator(),
      getClassroomForecastRangeUseCase: serviceLocator(),
      getStaffShiftHoursRangeUseCase: serviceLocator(),
      schedulingStaffListCubit: serviceLocator(),
      staffRepository: serviceLocator(),
      storageService: serviceLocator(),
    ),
  );
}
