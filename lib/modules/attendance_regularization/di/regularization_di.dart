import 'package:get_it/get_it.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';

import '../data/datasources/reg_remote_datasource.dart';
import '../data/interceptor/reg_sign_in_gate_interceptor.dart';
import '../data/reg_context.dart';
import '../data/repositories/regularization_repository_impl.dart';
import '../domain/repositories/regularization_repository.dart';
import '../domain/usecases/approve_request_usecase.dart';
import '../domain/usecases/approve_selected_usecase.dart';
import '../domain/usecases/check_gate_usecase.dart';
import '../domain/usecases/edit_regularization_usecase.dart';
import '../domain/usecases/get_requests_usecase.dart';
import '../domain/usecases/raise_regularization_batch_usecase.dart';
import '../domain/usecases/raise_regularization_usecase.dart';
import '../presentation/cubit/reg_dashboard_cubit.dart';
import '../presentation/cubit/reg_inbox_cubit.dart';
import '../presentation/cubit/reg_my_requests_cubit.dart';
import '../presentation/gate/reg_gate_coordinator.dart';

/// Call once at startup, beside `registerAttendanceV2`.
void registerRegularization(GetIt sl) {
  if (sl.isRegistered<RegularizationRepository>()) return;

  sl.registerLazySingleton<RegContext>(
    () => RegHostContext(
      storage: sl<StorageService>(),
      apiClient: sl<ApiClient>(),
    ),
  );
  sl.registerLazySingleton<RegRemoteDataSource>(
    () => RegRemoteDataSource(sl<ApiClient>().client),
  );
  sl.registerLazySingleton<RegularizationRepository>(
    () => RegularizationRepositoryImpl(
      sl<RegRemoteDataSource>(),
      sl<RegContext>(),
    ),
  );

  sl.registerFactory(() => CheckGateUseCase(sl()));
  sl.registerFactory(() => RaiseRegularizationUseCase(sl()));
  sl.registerFactory(() => RaiseRegularizationBatchUseCase(sl()));
  sl.registerFactory(() => EditRegularizationUseCase(sl()));
  sl.registerFactory(() => GetRequestsUseCase(sl()));
  sl.registerFactory(() => ApproveRequestUseCase(sl()));
  sl.registerFactory(() => ApproveSelectedUseCase(sl()));

  // Singleton so its "a sheet is already open" guard is shared — a dashboard
  // auto-open and a tapped sign-in must not stack two mandatory sheets.
  sl.registerLazySingleton<RegGateCoordinator>(
    () => RegGateCoordinator(
      checkGate: sl<CheckGateUseCase>(),
      raise: sl<RaiseRegularizationUseCase>(),
      raiseBatch: sl<RaiseRegularizationBatchUseCase>(),
      edit: sl<EditRegularizationUseCase>(),
      context: sl<RegContext>(),
    ),
  );

  sl.registerFactory(() => RegMyRequestsCubit(
        getRequests: sl<GetRequestsUseCase>(),
        editRequest: sl<EditRegularizationUseCase>(),
        gate: sl<RegGateCoordinator>(),
      ));
  sl.registerFactory(() => RegInboxCubit(
        getRequests: sl<GetRequestsUseCase>(),
        approveRequest: sl<ApproveRequestUseCase>(),
        approveSelected: sl<ApproveSelectedUseCase>(),
      ));
  sl.registerFactory(() => RegDashboardCubit(
        gate: sl<RegGateCoordinator>(),
        getRequests: sl<GetRequestsUseCase>(),
      ));

  _installSignInGate(sl);
}

/// One `ApiClient` singleton backs both the attendance and kiosk datasources,
/// so this single registration covers every sign-in path.
void _installSignInGate(GetIt sl) {
  final dio = sl<ApiClient>().client;
  if (dio.interceptors.any((i) => i is RegSignInGateInterceptor)) return;
  dio.interceptors.add(RegSignInGateInterceptor(sl<RegGateCoordinator>(), dio));
}
