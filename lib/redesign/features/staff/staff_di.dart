import 'package:get_it/get_it.dart';
import 'package:wowcare/redesign/features/staff/cubit/create_staff_cubit.dart';
import 'package:wowcare/redesign/features/staff/cubit/edit_staff_cubit.dart';
import 'package:wowcare/redesign/features/staff/cubit/staff_profile_cubit.dart';
import 'package:wowcare/redesign/features/staff/cubit/staff_roster_cubit.dart';
import 'package:wowcare/redesign/features/staff/cubit/staff_schedule_cubit.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/source/preview_staff_source.dart';
import 'package:wowcare/redesign/features/staff/source/staff_source.dart';

/// M06 Staff dependencies: preview sources during the UI phase, the real
/// usecases in the last phase. Called once from `registerRedesignDependencies`.
///
/// Every screen that belongs to one record takes its id and its [StaffLens]
/// as factory parameters, so a cubit never has to ask who is looking or what
/// it is looking at: it is built for one record and one persona, and the read
/// boundary is then arithmetic rather than something a screen must remember.
void registerStaffDependencies(GetIt sl) {
  sl.registerLazySingleton<StaffSource>(PreviewStaffSource.new);

  sl.registerFactoryParam<StaffRosterCubit, StaffLens, void>(
    (lens, _) => StaffRosterCubit(source: sl<StaffSource>(), lens: lens),
  );

  sl.registerFactoryParam<StaffProfileCubit, String, StaffLens>(
    (staffId, lens) => StaffProfileCubit(
      source: sl<StaffSource>(),
      staffId: staffId,
      lens: lens,
    ),
  );

  sl.registerFactoryParam<EditStaffCubit, String, StaffLens>(
    (staffId, lens) =>
        EditStaffCubit(source: sl<StaffSource>(), staffId: staffId, lens: lens),
  );

  sl.registerFactoryParam<StaffScheduleCubit, String, StaffLens>(
    (staffId, lens) => StaffScheduleCubit(
      source: sl<StaffSource>(),
      staffId: staffId,
      lens: lens,
    ),
  );

  sl.registerFactory<CreateStaffCubit>(
    () => CreateStaffCubit(source: sl<StaffSource>()),
  );
}
