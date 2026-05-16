import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di/di.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../domain/features/staff_scheduling/repositories/staff_scheduling_repository.dart';
import '../../../../shared/common/widgets/app_text_styles.dart';
import '../../../../shared/common/widgets/custom_scaffold.dart';
import '../../../../shared/common/widgets/gradient_add_button.dart';
import '../../scheduling/cubit/staff_scheduling_cubit.dart';
import '../../scheduling/cubit/staff_scheduling_state.dart';
import '../../scheduling/model/classroom-schudle-model.dart';
import '../../scheduling/widgets/expandable_schedule_card.dart';
import '../../scheduling/widgets/schedule_card.dart';
import 'add-schedule.dart';

class StaffSchedulingScreen extends StatefulWidget {
  const StaffSchedulingScreen({super.key});

  static const String routeName = '/dashboard/staff-scheduling';

  @override
  State<StaffSchedulingScreen> createState() => _StaffSchedulingScreenState();
}

class _StaffSchedulingScreenState extends State<StaffSchedulingScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StaffSchedulingCubit(
        serviceLocator<StaffSchedulingRepository>(),
        serviceLocator<StorageService>(),
      ),
      child: GlobalScaffold(
        hasBackButton: true,
        body: BlocBuilder<StaffSchedulingCubit, StaffSchedulingState>(
          builder: (context, state) {
            if (state is StaffSchedulingLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔹 Header Row
                    Row(
                      children: [
                        Expanded(
                          child: AppText.body(
                            'Mon, Dec 27 - Fri, Dec 31',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        GradientAddButton(
                          onTap: () async {
                            context.push(AddShiftScreen.routeName);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    /// 🔹 Filters
                    const ScheduleCard(),

                    const SizedBox(height: 16),

                    // /// 🔹 Cards
                    // ExpandableScheduleCard(
                    //   title: "1-Blue-D",
                    //   date: "Thu Dec 30",
                    //   isInitiallyExpanded: state.expandAll,
                    //   staffList: state.staffList,
                    //   showWarning: true,
                    // ),
                    ExpandableScheduleCard(
                      title: "Tue Dec 30",

                      isInitiallyExpanded: state.expandAll,
                      classrooms: [
                        ClassroomSchedule(
                          title: "1-Blue-D",
                          staffList: state.staffList,
                          showWarning: true,
                          classroomCode: '',
                          classroomName: '',
                        ),
                        ClassroomSchedule(
                          title: "2-Yellow-C",
                          staffList: state.staffList,
                          showWarning: false,
                          classroomCode: '',
                          classroomName: '',
                        ),
                        ClassroomSchedule(
                          title: "1-Red-B",
                          staffList: state.staffList,
                          showWarning: false,
                          classroomCode: '',
                          classroomName: '',
                        ),
                        ClassroomSchedule(
                          title: "1-Green-A",
                          staffList: state.staffList,
                          showWarning: false,
                          classroomCode: '',
                          classroomName: '',
                        ),
                        ClassroomSchedule(
                          title: "1-Orange-A",
                          staffList: state.staffList,
                          showWarning: false,
                          classroomCode: '',
                          classroomName: '',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
