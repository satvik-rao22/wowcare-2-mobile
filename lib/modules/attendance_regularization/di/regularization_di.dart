import 'package:get_it/get_it.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';

import '../core/config/reg_config.dart';
import '../data/datasources/reg_http_datasource.dart';
import '../data/datasources/reg_mock_datasource.dart';
import '../data/datasources/reg_remote_datasource.dart';
import '../data/interceptor/reg_sign_in_gate_interceptor.dart';
import '../data/reg_context.dart';
import '../data/repositories/regularization_repository_impl.dart';
import '../domain/repositories/regularization_repository.dart';
import '../domain/usecases/approve_request_usecase.dart';
import '../domain/usecases/approve_selected_usecase.dart';
import '../domain/usecases/edit_regularization_usecase.dart';
import '../domain/usecases/get_my_requests_usecase.dart';
import '../domain/usecases/get_open_session_usecase.dart';
import '../domain/usecases/get_open_sessions_batch_usecase.dart';
import '../domain/usecases/get_school_requests_usecase.dart';
import '../domain/usecases/raise_regularization_batch_usecase.dart';
import '../domain/usecases/raise_regularization_usecase.dart';
import '../presentation/cubit/reg_dashboard_cubit.dart';
import '../presentation/cubit/reg_inbox_cubit.dart';
import '../presentation/cubit/reg_my_requests_cubit.dart';
import '../presentation/gate/reg_gate_coordinator.dart';

/// Registers the Attendance Regularization module. Call once at startup,
/// beside `registerAttendanceV2`.
///
/// ### The one place `RegConfig.source` is read
///
/// Swapping the mock for the real API is the single `if` below. Nothing else
/// in the module — no repository, cubit, screen or widget — knows which
/// datasource is behind [RegRemoteDataSource]. At cutover, set
/// `RegConfig.source = RegSource.live` and delete
/// `data/datasources/reg_mock_datasource.dart`; this file is its only
/// importer.
///
/// ### The one place the sign-in gate is installed
///
/// The interceptor is appended to the host's shared Dio. There is a single
/// `ApiClient` singleton, and both `AttendanceRemoteDataSourceImpl` and
/// `KioskAttendanceRemoteDataSourceImpl` use `ApiClient.client` — so this one
/// registration covers all 12 sign-in paths without editing any of them.
void registerRegularization(GetIt sl) {
  if (sl.isRegistered<RegularizationRepository>()) return;

  // —— Context ——
  sl.registerLazySingleton<RegContext>(
    () => RegHostContext(
      storage: sl<StorageService>(),
      apiClient: sl<ApiClient>(),
    ),
  );

  // —— Datasource: the mock/live seam ——
  sl.registerLazySingleton<RegRemoteDataSource>(() {
    switch (RegConfig.source) {
      case RegSource.mock:
        return RegMockDataSource();
      case RegSource.live:
        return RegHttpDataSource(sl<ApiClient>().client);
    }
  });

  // —— Repository ——
  sl.registerLazySingleton<RegularizationRepository>(
    () => RegularizationRepositoryImpl(
      sl<RegRemoteDataSource>(),
      sl<RegContext>(),
    ),
  );

  // —— Usecases ——
  sl.registerFactory<GetOpenSessionUseCase>(
    () => GetOpenSessionUseCase(sl<RegularizationRepository>()),
  );
  sl.registerFactory<GetOpenSessionsBatchUseCase>(
    () => GetOpenSessionsBatchUseCase(sl<RegularizationRepository>()),
  );
  sl.registerFactory<RaiseRegularizationUseCase>(
    () => RaiseRegularizationUseCase(sl<RegularizationRepository>()),
  );
  sl.registerFactory<RaiseRegularizationBatchUseCase>(
    () => RaiseRegularizationBatchUseCase(sl<RegularizationRepository>()),
  );
  sl.registerFactory<EditRegularizationUseCase>(
    () => EditRegularizationUseCase(sl<RegularizationRepository>()),
  );
  sl.registerFactory<GetMyRequestsUseCase>(
    () => GetMyRequestsUseCase(sl<RegularizationRepository>()),
  );
  sl.registerFactory<GetSchoolRequestsUseCase>(
    () => GetSchoolRequestsUseCase(sl<RegularizationRepository>()),
  );
  sl.registerFactory<ApproveRequestUseCase>(
    () => ApproveRequestUseCase(sl<RegularizationRepository>()),
  );
  sl.registerFactory<ApproveSelectedUseCase>(
    () => ApproveSelectedUseCase(sl<RegularizationRepository>()),
  );

  // —— Gate ——
  // A singleton so its "a sheet is already open" guard is shared: the
  // dashboard auto-open and a tapped sign-in must not stack two mandatory
  // sheets on each other.
  sl.registerLazySingleton<RegGateCoordinator>(
    () => RegGateCoordinator(
      getOpenSession: sl<GetOpenSessionUseCase>(),
      getOpenSessionsBatch: sl<GetOpenSessionsBatchUseCase>(),
      raise: sl<RaiseRegularizationUseCase>(),
      raiseBatch: sl<RaiseRegularizationBatchUseCase>(),
      edit: sl<EditRegularizationUseCase>(),
      context: sl<RegContext>(),
    ),
  );

  // —— Cubits ——
  sl.registerFactory<RegMyRequestsCubit>(
    () => RegMyRequestsCubit(
      getMyRequests: sl<GetMyRequestsUseCase>(),
      editRequest: sl<EditRegularizationUseCase>(),
      gate: sl<RegGateCoordinator>(),
      context: sl<RegContext>(),
    ),
  );
  sl.registerFactory<RegInboxCubit>(
    () => RegInboxCubit(
      getSchoolRequests: sl<GetSchoolRequestsUseCase>(),
      approveRequest: sl<ApproveRequestUseCase>(),
      approveSelected: sl<ApproveSelectedUseCase>(),
      context: sl<RegContext>(),
    ),
  );
  sl.registerFactory<RegDashboardCubit>(
    () => RegDashboardCubit(
      gate: sl<RegGateCoordinator>(),
      getSchoolRequests: sl<GetSchoolRequestsUseCase>(),
      context: sl<RegContext>(),
    ),
  );

  // —— The sign-in gate, installed once on the shared Dio ——
  _installSignInGate(sl);
}

void _installSignInGate(GetIt sl) {
  final dio = sl<ApiClient>().client;
  final already = dio.interceptors.any((i) => i is RegSignInGateInterceptor);
  if (already) return;

  // Appended, so it runs after auth has attached its headers — the pre-check
  // it performs is itself an authenticated call.
  dio.interceptors.add(RegSignInGateInterceptor(sl<RegGateCoordinator>()));
}
