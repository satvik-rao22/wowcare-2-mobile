import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../core/network/api_client.dart';
import '../../core/network/network_info.dart';
import '../../data/features/onboarding/datasources/onboarding_remote_datasource.dart';
import '../../data/features/onboarding/repositories/onboarding_repository_impl.dart';
import '../../domain/features/onboarding/repositories/onboarding_repository.dart';
import '../../domain/features/onboarding/usecases/get_onboarding_content.dart';

final GetIt serviceLocator = GetIt.instance;

Future<void> configureDependencies({required String baseUrl}) async {
  // Core
  serviceLocator.registerLazySingleton<Connectivity>(() => Connectivity());
  serviceLocator.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(serviceLocator()),
  );

  serviceLocator.registerLazySingleton<ApiClient>(
    () => ApiClient(baseUrl: baseUrl, interceptors: <Interceptor>[]),
  );

  // Data sources
  serviceLocator.registerLazySingleton<OnboardingRemoteDataSource>(
    () => OnboardingRemoteDataSource(apiClient: serviceLocator()),
  );

  // Repositories
  serviceLocator.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(
      remoteDataSource: serviceLocator(),
      networkInfo: serviceLocator(),
    ),
  );

  // Use cases
  serviceLocator.registerFactory<GetOnboardingContent>(
    () => GetOnboardingContent(serviceLocator()),
  );
}
