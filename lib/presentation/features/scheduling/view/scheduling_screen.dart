import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../shared/common/widgets/custom_date_time_field.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../shared/common/widgets/custom_refresh_indicator.dart';
import '../../../../shared/common/widgets/custom_scaffold.dart';
import '../../../../shared/common/widgets/gradient_add_button.dart';
import '../../../../shared/common/widgets/primary_circular_loader.dart';
import '../cubit/scheduling_cubit.dart';
import '../model/scheduling_models.dart';
import '../widgets/day_classroom_section.dart';
import '../widgets/day_gantt_table.dart';
import '../widgets/scheduling_filter_bar.dart';
import '../widgets/week_classroom_row.dart';
import 'add_shift_screen.dart';

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

        final isWeek = state.viewMode == SchedulingViewMode.week;
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
                    viewMode: state.viewMode,
                    onViewModeChanged: cubit.setViewMode,
                  ),
                  const SizedBox(height: 16),
                  if (isWeek) ...[
                    SchedulingFilterBar(
                      classroomNames: classroomNames,
                      selectedClassroom: state.classroomFilter,
                      onClassroomChanged: cubit.setClassroomFilter,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (state.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: PrimaryCircularLoader()),
                    )
                  else if (isWeek)
                    _ClassroomListCard(
                      classrooms: state.filteredClassrooms,
                      dayLabel: DateFormat('EEE d').format(state.selectedDay),
                      expandAll: _expandAll,
                      onToggleExpandAll: () =>
                          setState(() => _expandAll = !_expandAll),
                    )
                  else
                    DayGanttTable(classrooms: state.filteredClassrooms),
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
    required this.viewMode,
    required this.onViewModeChanged,
  });

  final DateTime selectedDay;
  final ValueChanged<DateTime> onDateSelected;
  final SchedulingViewMode viewMode;
  final ValueChanged<SchedulingViewMode> onViewModeChanged;

  static const _viewModeLabels = <SchedulingViewMode, String>{
    SchedulingViewMode.week: 'Week',
    SchedulingViewMode.day: 'Day',
  };

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
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: CustomDropdown(
            hintText: 'View',
            items: _viewModeLabels.values.toList(growable: false),
            selectedItem: _viewModeLabels[viewMode],
            prependHintAsSelectableItem: false,
            fieldHeight: 44,
            onSelect: (label) {
              if (label == null) return;
              final next = _viewModeLabels.entries
                  .firstWhere(
                    (e) => e.value == label,
                    orElse: () => _viewModeLabels.entries.first,
                  )
                  .key;
              onViewModeChanged(next);
            },
          ),
        ),
        const SizedBox(width: 8),
        GradientAddButton(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddShiftScreen(initialDate: selectedDay),
              ),
            );
          },
        ),
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
