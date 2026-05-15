import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

import '../../../../../app/di/di.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../shared/common/widgets/app_text_styles.dart';
import '../../../../../shared/common/widgets/gradient_add_button.dart';
import '../../cubit/classroom_schedule_cubit.dart';
import '../../cubit/classroom_schedule_state.dart';
import '../../widgets/classroom_view/classroom_schedule_widget.dart';

class ClassroomViewScreen extends StatelessWidget {
  const ClassroomViewScreen({super.key});

  static const String routeName = "/dashboard/classroom-view";

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          serviceLocator<ClassroomScheduleCubit>()..fetchSchedules(),
      child: const GlobalScaffold(
        hasBackButton: true,
        body: ClassroomViewBody(),
      ),
    );
  }
}

class ClassroomViewBody extends StatelessWidget {
  const ClassroomViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClassroomScheduleCubit, ClassroomScheduleState>(
      builder: (context, state) {
        if (state is ClassroomScheduleLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ClassroomScheduleLoaded) {
          return SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppText.body(
                        '< Dec 27 >',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    GradientAddButton(onTap: () async {}),
                  ],
                ),
                const SizedBox(height: 16),
                ClassroomScheduleWidget(entries: state.entries),
              ],
            ),
          );
        } else if (state is ClassroomScheduleError) {
          return Center(child: Text(state.message));
        }
        return const SizedBox.shrink();
      },
    );
  }
}
