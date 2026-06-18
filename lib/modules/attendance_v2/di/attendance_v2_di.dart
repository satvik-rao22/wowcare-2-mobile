import 'package:get_it/get_it.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';

import '../data/repositories/attendance_v2_repository_impl.dart';
import '../domain/repositories/attendance_v2_repository.dart';
import '../domain/usecases/get_staff_overtime_profile_usecase.dart';
import '../presentation/cubit/staff_detail_cubit.dart';

/// Registers the Attendance V2 module. Call once from the app's DI bootstrap:
///
///   registerAttendanceV2(serviceLocator);
///
/// Depends only on the already-registered [AttendanceRepository], so it must
/// run after the core attendance feature is registered.
void registerAttendanceV2(GetIt sl) {
  if (sl.isRegistered<AttendanceV2Repository>()) return;

  sl.registerLazySingleton<AttendanceV2Repository>(
    () => AttendanceV2RepositoryImpl(sl<AttendanceRepository>()),
  );
  sl.registerFactory<GetStaffOvertimeProfileUseCase>(
    () => GetStaffOvertimeProfileUseCase(sl<AttendanceV2Repository>()),
  );
  sl.registerFactory<StaffDetailCubit>(
    () => StaffDetailCubit(getStaffOvertimeProfileUseCase: sl()),
  );
}
