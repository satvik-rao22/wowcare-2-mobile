import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/di.dart';
import '../../../../app/theme/colors.dart';
import '../../../../presentation/features/classroom/cubit/classroom_cubit.dart';
import '../cubit/scheduling_staff_list_cubit.dart';
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
    return BlocProvider<SchedulingCubit>(
      create: (_) => serviceLocator<SchedulingCubit>()..load(),
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
  void initState() {
    super.initState();
    // Kick off classroom fetch on first frame. The no-pagination scheduling
    // staff list is loaded by [SchedulingStaffListCubit] at the route level.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ClassroomCubit>().loadActiveClassrooms(
            onlyTypeClassroom: false,
          );
    });
  }

  Future<void> _onRefresh() async {
    final cubit = context.read<SchedulingCubit>();
    final staffListCubit = context.read<SchedulingStaffListCubit>();
    final classroomCubit = context.read<ClassroomCubit>();
    // Refetch today's shifts, force-refetch the no-pagination staff list,
    // and invalidate the classroom cache (per PRD pull-to-refresh).
    await Future.wait<void>([
      cubit.load(),
      staffListCubit.load(force: true),
      classroomCubit.loadActiveClassrooms(
        force: true,
        onlyTypeClassroom: false,
      ),
    ]);
  }

  void _openAddShiftScreen(DateTime selectedDay) {
    // The cubits are provided at the route level; capture them here so they
    // remain available inside the pushed [MaterialPageRoute] (which would
    // otherwise lose the provider scope).
    final classroomCubit = context.read<ClassroomCubit>();
    final schedulingStaffListCubit =
        context.read<SchedulingStaffListCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            // AddShift reads staff from the singleton scheduling cubit
            // (cached, no pagination) instead of the paginated [StaffCubit].
            BlocProvider<SchedulingStaffListCubit>.value(
              value: schedulingStaffListCubit,
            ),
            BlocProvider<ClassroomCubit>.value(value: classroomCubit),
          ],
          child: AddShiftScreen(initialDate: selectedDay),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SchedulingCubit, SchedulingState>(
      builder: (context, state) {
        final classroomState = context.watch<ClassroomCubit>().state;
        final classroomNames = classroomState.classrooms
            .map((c) => c.name)
            .where((n) => n.isNotEmpty)
            .toSet()
            .toList(growable: false);

        // Feed classroom code→name into SchedulingCubit so grouped rows show
        // names instead of codes (the staff-shifts API only returns codes).
        // The cubit no-ops when the map is unchanged.
        final namesByCode = <String, String>{
          for (final c in classroomState.classrooms)
            if (c.code.trim().isNotEmpty && c.name.trim().isNotEmpty)
              c.code.trim(): c.name.trim(),
        };
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.read<SchedulingCubit>().setClassroomNames(namesByCode);
        });

        final isWeek = state.viewMode == SchedulingViewMode.week;
        final cubit = context.read<SchedulingCubit>();
        return GlobalScaffold(
          hasBackButton: false,
          body: CustomRefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Classroom Schedule',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff573353),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DatePickerHeader(
                    selectedDay: state.selectedDay,
                    onDateSelected: cubit.selectDay,
                    viewMode: state.viewMode,
                    onViewModeChanged: cubit.setViewMode,
                    onAddTap: () => _openAddShiftScreen(state.selectedDay),
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
                  if (state.errorMessage != null) ...[
                    Text(
                      state.errorMessage!,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: AppColors.errorColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (state.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: PrimaryCircularLoader()),
                    )
                  else if (state.filteredClassrooms.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          'No shifts for the selected day.',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            color: AppColors.primaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
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
                    DayGanttTable(
                      classrooms: state.filteredClassrooms,
                      day: state.selectedDay,
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
    required this.viewMode,
    required this.onViewModeChanged,
    required this.onAddTap,
  });

  final DateTime selectedDay;
  final ValueChanged<DateTime> onDateSelected;
  final SchedulingViewMode viewMode;
  final ValueChanged<SchedulingViewMode> onViewModeChanged;
  final VoidCallback onAddTap;

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
        GradientAddButton(onTap: onAddTap),
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
