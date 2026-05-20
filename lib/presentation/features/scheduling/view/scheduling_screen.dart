import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../shared/common/widgets/custom_date_time_field.dart';
import '../../../../shared/common/widgets/custom_refresh_indicator.dart';
import '../../../../shared/common/widgets/custom_scaffold.dart';
import '../../../../shared/common/widgets/gradient_add_button.dart';
import '../../../../shared/common/widgets/primary_circular_loader.dart';
import '../cubit/scheduling_cubit.dart';
import '../model/scheduling_models.dart';
import '../widgets/day_classroom_section.dart';
import '../widgets/scheduling_filter_bar.dart';
import '../widgets/week_classroom_row.dart';

class SchedulingScreen extends StatelessWidget {
  const SchedulingScreen({super.key});

  static const String routeName = '/dashboard/scheduling';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SchedulingCubit()..load(),
      child: const _SchedulingScreenContent(),
    );
  }
}

class _SchedulingScreenContent extends StatefulWidget {
  const _SchedulingScreenContent();

  @override
  State<_SchedulingScreenContent> createState() =>
      _SchedulingScreenContentState();
}

class _SchedulingScreenContentState extends State<_SchedulingScreenContent> {
  bool _expandAll = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SchedulingCubit, SchedulingState>(
      builder: (context, state) {
        final cubit = context.read<SchedulingCubit>();
        final classroomNames = state.classrooms
            .map((c) => c.classroomName)
            .toSet()
            .toList(growable: false);

        return GlobalScaffold(
          hasBackButton: true,
          body: CustomRefreshIndicator(
            onRefresh: () async => cubit.load(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DatePickerHeader(
                    selectedDay: state.selectedDay,
                    onDateSelected: cubit.selectDay,
                  ),
                  const SizedBox(height: 16),
                  SchedulingFilterBar(
                    classroomNames: classroomNames,
                    selectedClassroom: state.classroomFilter,
                    onClassroomChanged: cubit.setClassroomFilter,
                  ),
                  const SizedBox(height: 16),
                  if (state.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: PrimaryCircularLoader()),
                    )
                  else
                    _ClassroomListCard(
                      classrooms: state.filteredClassrooms,
                      dayLabel: DateFormat('EEE d').format(state.selectedDay),
                      expandAll: _expandAll,
                      onToggleExpandAll: () =>
                          setState(() => _expandAll = !_expandAll),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DatePickerHeader extends StatelessWidget {
  const _DatePickerHeader({
    required this.selectedDay,
    required this.onDateSelected,
  });

  final DateTime selectedDay;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: CustomDateTimeField(
            key: ValueKey(selectedDay.toIso8601String()),
            hasLabel: false,
            fetchInitialTime: false,
            initialDate: selectedDay,
            onDateSelected: onDateSelected,
          ),
        ),
        const SizedBox(width: 12),
        GradientAddButton(onTap: () {}),
      ],
    );
  }
}

class _ClassroomListCard extends StatelessWidget {
  const _ClassroomListCard({
    required this.classrooms,
    required this.dayLabel,
    required this.expandAll,
    required this.onToggleExpandAll,
  });

  final List<ClassroomDaySchedule> classrooms;
  final String dayLabel;
  final bool expandAll;
  final VoidCallback onToggleExpandAll;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0x33162831)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WeekClassroomHeaderRow(
              dayLabel: dayLabel,
              expandAll: expandAll,
              onToggleExpandAll: onToggleExpandAll,
            ),
            for (int i = 0; i < classrooms.length; i++)
              DayClassroomSection(
                key: ValueKey('${classrooms[i].classroomCode}-$expandAll'),
                classroom: classrooms[i],
                initiallyExpanded: expandAll,
                isLast: i == classrooms.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}
