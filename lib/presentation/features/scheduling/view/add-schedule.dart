import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di/di.dart';
import '../../classroom/cubit/classroom_cubit.dart';
import '../../staff/cubit/staff_cubit.dart';
import '../cubit/Add-Shift/cubit/add_shift_cubit.dart';
import '../cubit/Add-Shift/cubit/edit_and_publish_schedule_form_cubit.dart';
import '../widgets/add-shiftform/add-shift-form.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';

class AddShiftScreen extends StatefulWidget {
  const AddShiftScreen({super.key});

  static const String routeName = '/add-shift';

  @override
  State<AddShiftScreen> createState() => _AddShiftScreenState();
}

class _AddShiftScreenState extends State<AddShiftScreen> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => serviceLocator<ScheduleFormCubit>()),
        BlocProvider(
          create: (context) {
            final cubit = serviceLocator<StaffCubit>();
            serviceLocator<StorageService>()
                .getString(StorageKeys.schoolCode)
                .then((code) {
                  if (code != null && code.isNotEmpty) {
                    cubit.loadStaffBySchool(code);
                  } else {
                    cubit.loadInitial();
                  }
                });
            return cubit;
          },
        ),
        BlocProvider(
          create: (context) =>
              serviceLocator<ClassroomCubit>()..loadActiveClassrooms(),
        ),
      ],
      child: BlocProvider(
        create: (_) => AddShiftCubit(
          repository: serviceLocator<StaffRepository>(),

          storageService: serviceLocator<StorageService>(),
        ),

        child: const AddShiftForm(),
      ),
    );
  }
}
