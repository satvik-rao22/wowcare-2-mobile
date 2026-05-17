/// =============================
/// SCREEN UPDATE
/// =============================

/// classroom_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../../app/di/di.dart';
import '../../../../../app/theme/colors.dart';

import '../../../../../domain/features/staff_scheduling/entities/staff_shift.dart';
import '../../../../../shared/common/widgets/app_text_styles.dart';
import '../../../../../shared/common/widgets/custom_scaffold.dart';
import '../../../../../shared/common/widgets/gradient_add_button.dart';

import '../../../../../shared/common/widgets/profile_show_widget.dart';
import '../../../classroom/cubit/classroom_cubit.dart';
import '../../cubit/classroom_schedule_cubit.dart';
import '../../cubit/classroom_schedule_state.dart';

import '../../model/classroom-schudle-model.dart';
import '../../model/staff_model.dart';

import '../../widgets/expandable_schedule_card.dart';

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

    final date = args?.date ?? '2026-05-11';

    return BlocProvider(
      create: (context) => serviceLocator<ClassroomScheduleCubit>()
        ..fetchSchedules(
          classroomCode: classroomCode,

          date: date,

          schoolCode: 'SCH_1A748EF9-5',
        ),

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
              /// HEADER
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '< $date >',

                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primaryColor,

                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  GradientAddButton(onTap: () {}),
                ],
              ),

              const SizedBox(height: 16),

              /// LOADING
              if (state is ClassroomScheduleLoading)
                const Center(child: CircularProgressIndicator()),

              /// LOADED
              if (state is ClassroomScheduleLoaded)
                Builder(
                  builder: (_) {
                    /// GROUP SHIFTS BY CLASSROOM
                    final Map<String, List<StaffShiftEntity>>
                    shiftsByClassroom = {};

                    for (var shift in state.shifts) {
                      shiftsByClassroom
                          .putIfAbsent(shift.classroomCode, () => [])
                          .add(shift);
                    }

                    /// MAP CLASSROOMS
                    final classrooms = state.classrooms.map((classroom) {
                      final classroomShifts =
                          shiftsByClassroom[classroom.classroomCode] ?? [];

                      /// SORT
                      classroomShifts.sort((a, b) {
                        final dateCompare = a.shiftDate.compareTo(b.shiftDate);

                        if (dateCompare != 0) {
                          return dateCompare;
                        }

                        return a.startTime.compareTo(b.startTime);
                      });

                      /// FORMAT STAFF
                      final staffList = classroomShifts.map((shift) {
                        String formatTime(String timeStr) {
                          try {
                            final parts = timeStr.split(':');

                            if (parts.length >= 2) {
                              final dt = DateTime(
                                2026,
                                1,
                                1,
                                int.parse(parts[0]),
                                int.parse(parts[1]),
                              );

                              return DateFormat('hh:mm a').format(dt);
                            }
                          } catch (_) {}

                          return timeStr;
                        }

                        return StaffModel(
                          name: '${shift.staffFirstName} ${shift.staffLastName}'
                              .trim(),

                          image: DocumentImageWidget(fileUuid: shift.image),

                          workedHours: shift.scheduledHours.toInt(),

                          totalHours:
                              (shift.scheduledHours + shift.unscheduledHours)
                                  .toInt(),

                          shift:
                              '${formatTime(shift.startTime)} - ${formatTime(shift.endTime)}',

                          shiftDate: shift.shiftDate,

                          statusColor: shift.shiftStatus == 'PUBLISHED'
                              ? Colors.green
                              : Colors.orange,
                        );
                      }).toList();

                      return ClassroomSchedule(
                        title: classroom.name,

                        classroomName: classroom.name,

                        classroomCode: classroom.classroomCode,

                        showWarning: false,

                        isExpanded: true,

                        staffList: staffList,
                      );
                    }).toList();

                    return ExpandableScheduleCard(
                      title: state.date,

                      classrooms: classrooms,

                      isInitiallyExpanded: true,
                      classroomNameMap: context
                          .read<ClassroomCubit>()
                          .codeNameMap,
                    );
                  },
                ),

              /// ERROR
              if (state is ClassroomScheduleError)
                Padding(
                  padding: const EdgeInsets.all(20),

                  child: Text(state.message),
                ),
            ],
          ),
        );
      },
    );
  }
}
