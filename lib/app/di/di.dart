import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
import '../../core/network/auth_interceptor.dart';
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
import '../../domain/features/attendance/repositories/attendance_repository.dart';
import '../../domain/features/attendance/usecases/get_student_attendance_daily_usecase.dart';
import '../../domain/features/attendance/usecases/get_student_attendance_custom_usecase.dart';
import '../../domain/features/student/usecases/get_student_documents_usecase.dart';
import '../../domain/features/student/usecases/add_student_document_usecase.dart';
import '../../domain/features/student/usecases/get_student_important_dates_usecase.dart';
import '../../domain/features/student/usecases/update_student_important_dates_usecase.dart';
import '../../domain/features/student/usecases/update_student_document_usecase.dart';
import '../../domain/features/student/usecases/delete_student_document_usecase.dart';
import '../../presentation/features/auth/cubit/auth_cubit.dart';
import '../../presentation/features/classroom/cubit/classroom_cubit.dart';
import '../../presentation/features/staff/cubit/staff_cubit.dart';
import '../../presentation/features/staff/cubit/staff_document_cubit.dart';
import '../../presentation/features/staff/cubit/staff_documents_list_cubit.dart';
import '../../presentation/features/staff/cubit/staff_profile_cubit.dart';
import '../../presentation/features/staff/cubit/important_dates_cubit.dart';
import '../../presentation/features/staff/cubit/create_school_user_cubit.dart';
import '../../presentation/features/student/cubit/student_cubit.dart';
import '../../presentation/features/attendance/cubit/student_attendance_daily_cubit.dart';
import '../../presentation/features/attendance/cubit/student_attendance_custom_cubit.dart';
import '../../presentation/features/students/cubit/student_documents_list_cubit.dart';
import '../../presentation/features/students/cubit/student_document_cubit.dart';
import '../../presentation/features/students/cubit/student_important_dates_cubit.dart';

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
        ],
      ));

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
  serviceLocator.registerFactory<GetStudentPageUseCase>(
    () => GetStudentPageUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentAttendanceDailyUseCase>(
    () => GetStudentAttendanceDailyUseCase(serviceLocator()),
  );
  serviceLocator.registerFactory<GetStudentAttendanceCustomUseCase>(
    () => GetStudentAttendanceCustomUseCase(serviceLocator()),
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
      repository: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory<StudentAttendanceCustomCubit>(
    () => StudentAttendanceCustomCubit(
      getStudentAttendanceCustomUseCase: serviceLocator(),
      repository: serviceLocator(),
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


