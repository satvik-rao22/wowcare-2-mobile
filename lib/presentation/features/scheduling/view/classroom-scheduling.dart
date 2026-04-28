import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/colors.dart';
import '../../../../shared/common/widgets/app_text_styles.dart';
import '../../../../shared/common/widgets/custom_scaffold.dart';
import '../../../../shared/common/widgets/gradient_add_button.dart';
import '../cubit/staff_scheduling_cubit.dart';
import '../cubit/staff_scheduling_state.dart';
import '../widgets/schedule_card.dart';
import '../widgets/expandable_schedule_card.dart';
import 'add-schedule.dart';
import '../../../../app/di/di.dart';
import '../../classroom/cubit/classroom_cubit.dart';

class SchedulingScreen extends StatefulWidget {
  const SchedulingScreen({super.key});

  static const String routeName = '/scheduling';

  @override
  State<SchedulingScreen> createState() => _SchedulingScreenState();
}

class _SchedulingScreenState extends State<SchedulingScreen> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => StaffSchedulingCubit()),
        BlocProvider(
          create: (context) =>
              serviceLocator<ClassroomCubit>()..loadActiveClassrooms(),
        ),
      ],
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
                            Navigator.pushNamed(
                              context,
                              AddShiftScreen.routeName,
                            );
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
                    BlocBuilder<ClassroomCubit, ClassroomState>(
                      builder: (context, classroomState) {
                        return ExpandableScheduleCard(
                          title: "Tue Dec 30",
                          isInitiallyExpanded: state.expandAll,
                          classrooms: classroomState.classrooms.map((c) {
                            return ClassroomSchedule(
                              title: c.name,
                              classroomCode: c.code,
                              staffList: state.staffList,
                              showWarning: false,
                            );
                          }).toList(),
                        );
                      },
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
