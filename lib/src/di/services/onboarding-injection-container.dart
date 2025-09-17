// part of '../injection_container.dart';

// Future<void> _onBoardingInit() async {
//   final prefs = await SharedPreferences.getInstance();

//   sl
//     ..registerFactory(
//       () =>
//           OnBoardingCubit(cacheFirstTimer: sl(), checkIfUserIsFirstTimer: sl()),
//     )
//     ..registerLazySingleton(() => CacheFirstTimer(sl()))
//     ..registerLazySingleton(() => CheckIfUserIsFirstTimer(sl()))
//     ..registerLazySingleton<OnBoardingRepo>(() => OnBoardingRepoImpl(sl()))
//     ..registerLazySingleton<OnBoardingLocalDatasource>(
//       () => OnBoardingLocalDatasourceImpl(sl()),
//     )
//     ..registerLazySingleton(() => prefs);
// }
