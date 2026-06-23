import 'package:get_it/get_it.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';

import '../data/datasources/staff_overtime_remote_datasource.dart';
import '../data/repositories/attendance_v2_repository_impl.dart';
import '../domain/repositories/attendance_v2_repository.dart';
import '../domain/usecases/calculate_overtime_usecase.dart';
import '../domain/usecases/get_day_detail_usecase.dart';
import '../domain/usecases/get_staff_overview_usecase.dart';
import '../presentation/cubit/staff_detail_cubit.dart';

/// Registers the Attendance V2 module. Call once after the core attendance
/// feature (it reuses [AttendanceRepository] + the shared [ApiClient]).
void registerAttendanceV2(GetIt sl) {
  if (sl.isRegistered<AttendanceV2Repository>()) return;

  sl.registerLazySingleton<StaffOvertimeRemoteDataSource>(
    () => StaffOvertimeRemoteDataSource(sl<ApiClient>().client),
  );
  sl.registerLazySingleton<AttendanceV2Repository>(
    () => AttendanceV2RepositoryImpl(
      sl<StaffOvertimeRemoteDataSource>(),
      sl<AttendanceRepository>(),
    ),
  );
  sl.registerFactory<CalculateOvertimeUseCase>(
    () => CalculateOvertimeUseCase(sl<AttendanceV2Repository>()),
  );
  sl.registerFactory<GetStaffOverviewUseCase>(
    () => GetStaffOverviewUseCase(sl<AttendanceV2Repository>()),
  );
  sl.registerFactory<GetDayDetailUseCase>(
    () => GetDayDetailUseCase(sl<AttendanceV2Repository>()),
  );
  sl.registerFactory<StaffDetailCubit>(
    () => StaffDetailCubit(
      calculateOvertimeUseCase: sl(),
      getStaffOverviewUseCase: sl(),
      getDayDetailUseCase: sl(),
    ),
  );
}
