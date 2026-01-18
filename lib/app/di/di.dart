import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
import '../../core/network/network_info.dart';
import '../../core/storage/storage_service.dart';
import '../../core/util/api_constants.dart';
import '../../data/features/auth/datasources/auth_local_datasource.dart';
import '../../data/features/auth/datasources/auth_remote_datasource.dart';
import '../../data/features/auth/repositories/auth_repository_impl.dart';
import '../../data/features/onboarding/datasources/onboarding_remote_datasource.dart';
import '../../data/features/onboarding/repositories/onboarding_repository_impl.dart';
import '../../domain/features/auth/repositories/auth_repository.dart';
import '../../domain/features/auth/usecases/login_usecase.dart';
import '../../domain/features/auth/usecases/forgot_password_usecase.dart';
import '../../domain/features/onboarding/repositories/onboarding_repository.dart';
import '../../domain/features/onboarding/usecases/get_onboarding_content.dart';
import '../../presentation/features/auth/cubit/auth_cubit.dart';

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
        interceptors: <Interceptor>[],
      ));

  // Auth Data Sources
  serviceLocator.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(serviceLocator<ApiClient>().client),
  );
  serviceLocator.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(serviceLocator()),
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

  // Cubits (factory - new instance each time for UI)
  serviceLocator.registerFactory<AuthCubit>(
    () => AuthCubit(
      loginUseCase: serviceLocator(),
      localDataSource: serviceLocator(),
      remoteDataSource: serviceLocator(),
    ),
  );
}


