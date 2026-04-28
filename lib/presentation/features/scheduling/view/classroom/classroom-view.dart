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

class ClassroomViewArgs {
  final String classroomCode;
  final String classroomName;
  final String date;

  ClassroomViewArgs({
    required this.classroomCode,
    required this.classroomName,
    required this.date,
  });
}

class ClassroomViewScreen extends StatelessWidget {
  const ClassroomViewScreen({super.key});

  static const String routeName = "/classroom-view";

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as ClassroomViewArgs?;

    final classroomCode = args?.classroomCode ?? 'CLS_C82D4F6F-E';
    final classroomName = args?.classroomName ?? 'Classroom';
    final date = args?.date ?? '2026-04-24';

    return BlocProvider(
      create: (context) =>
          serviceLocator<ClassroomScheduleCubit>()
            ..fetchSchedules(classroomCode: classroomCode, date: date),
      child: GlobalScaffold(
        hasBackButton: true,
        body: ClassroomViewBody(classroomName: classroomName, date: date),
      ),
    );
  }
}

class ClassroomViewBody extends StatelessWidget {
  final String classroomName;
  final String date;

  const ClassroomViewBody({
    super.key,
    required this.classroomName,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClassroomScheduleCubit, ClassroomScheduleState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppText.body(
                      '< $date >',
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
              if (state is ClassroomScheduleLoading)
                ClassroomScheduleWidget(shifts: const [], isLoading: true)
              else if (state is ClassroomScheduleLoaded)
                ClassroomScheduleWidget(shifts: state.shifts, isLoading: false)
              else if (state is ClassroomScheduleError)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(state.message),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
