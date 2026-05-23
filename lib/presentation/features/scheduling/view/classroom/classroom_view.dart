import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import '../../../../../app/di/di.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../domain/features/staff_scheduling/entities/staff_shift.dart';
import '../../../../../shared/common/widgets/app_text_styles.dart';
import '../../../../../shared/common/widgets/gradient_add_button.dart';
import '../../cubit/classroom-day-view/classroom_day_schedule_cubit.dart';
import '../../cubit/classroom-day-view/classroom_day_schedule_state.dart';
import '../../widgets/classroom_view/classroom_schedule_widget.dart';
import '../../widgets/classroom_view/all_classrooms_schedule_card.dart';

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

  static const String routeName = '/dashboard/classroom-view';

  @override
  Widget build(BuildContext context) {
    final goExtra = GoRouterState.of(context).extra;
    final argsFromGo = goExtra is ClassroomViewArgs ? goExtra : null;
    final argsFromNavigator =
        ModalRoute.of(context)?.settings.arguments as ClassroomViewArgs?;
    final args = argsFromGo ?? argsFromNavigator;

    final classroomCode = args?.classroomCode ?? 'CLS_C82D4F6F-E';
    final classroomName = args?.classroomName ?? 'Classroom';
    final date = args?.date ?? '2026-04-24';

    return BlocProvider(
      create: (context) =>
          serviceLocator<ClassroomScheduleCubit>()
            ..fetchAllSchedules(date: date),
      child: GlobalScaffold(
        hasBackButton: true,
        body: ClassroomViewBody(
          classroomName: classroomName,
          classroomCode: classroomCode,
          date: date,
        ),
      ),
    );
  }
}

class ClassroomViewBody extends StatelessWidget {
  final String classroomName;
  final String classroomCode;
  final String date;

  const ClassroomViewBody({
    super.key,
    required this.classroomName,
    required this.classroomCode,
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
                      '$date',
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
                _AllClassroomsSchedule(
                  classrooms: state.classrooms,
                  shifts: state.shifts,
                  highlightClassroomCode: classroomCode,
                )
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

class _AllClassroomsSchedule extends StatelessWidget {
  final List<ClassroomEntity> classrooms;
  final List<StaffShiftEntity> shifts;
  final String? highlightClassroomCode;

  const _AllClassroomsSchedule({
    required this.classrooms,
    required this.shifts,
    this.highlightClassroomCode,
  });

  bool _isPublishOrUnpublish(String status) {
    final s = status.trim().toUpperCase();
    // For now: show only Published / Unpublished (Draft) records.
    return s == 'PUBLISHED' || s == 'DRAFT' || s == 'UNPUBLISHED';
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<StaffShiftEntity>> shiftsByClassroom = {};
    for (final s in shifts) {
      if (!_isPublishOrUnpublish(s.shiftStatus)) continue;
      final code = s.classroomCode.trim();
      if (code.isEmpty) continue;
      shiftsByClassroom.putIfAbsent(code, () => []).add(s);
    }
    return AllClassroomsScheduleCard(
      classrooms: classrooms,
      shiftsByClassroom: shiftsByClassroom,
      highlightClassroomCode: highlightClassroomCode,
    );
  }
}
