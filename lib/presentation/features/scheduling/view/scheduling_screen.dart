import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/di.dart';
import '../../../../app/theme/colors.dart';
import '../../../../domain/features/attendance/usecases/get_staff_today_sign_in_status_map_usecase.dart';
import '../../../../presentation/features/classroom/cubit/classroom_cubit.dart';
import '../cubit/scheduling_staff_list_cubit.dart';
import '../../../../shared/common/widgets/custom_date_time_field.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../shared/common/widgets/custom_refresh_indicator.dart';
import '../../../../shared/common/widgets/custom_scaffold.dart';
import '../../../../shared/common/widgets/custom_shimmer_loader.dart';
import '../../../../shared/common/widgets/gradient_add_button.dart';
import '../cubit/scheduling_cubit.dart';
import '../model/scheduling_models.dart';
import '../utils/scheduling_cache_gate.dart';
import '../utils/scheduling_school_time.dart';
import '../utils/scheduling_shift_navigator.dart';
import '../widgets/day_classroom_section.dart';
import '../widgets/scheduling_filter_bar.dart';
import '../widgets/week_classroom_row.dart';
import 'add_shift_screen.dart';

class SchedulingScreen extends StatelessWidget {
  const SchedulingScreen({
    super.key,
    this.highlightShiftCode,
    this.highlightClassroomCode,
    this.initialDate,
    this.forceDayView = false,
  });

  /// Shift code from a notification deep-link; the matching shift row scrolls
  /// into view and flashes.
  final String? highlightShiftCode;

  /// Classroom code from a notification deep-link (SHIFT_UNDER_RATIO); the
  /// matching classroom row in DAY view scrolls into view and flashes.
  final String? highlightClassroomCode;

  /// Notification deep-link: jump to this day on open.
  final DateTime? initialDate;

  /// Notification deep-link: force the DAY view on open (e.g. under-ratio).
  final bool forceDayView;

  static const String routeName = '/dashboard/scheduling';

  @override
  Widget build(BuildContext context) {
    // `.value` because [SchedulingCubit] is registered as a lazy singleton —
    // we don't want BlocProvider to close it when this screen is popped.
    // The `loadIfNeeded()` trigger lives in `_SchedulingScreenContent.initState`
    // so it fires exactly once per screen entry (build can run multiple
    // times mid-load, which would otherwise re-enter the full visible load).
    return BlocProvider<SchedulingCubit>.value(
      value: serviceLocator<SchedulingCubit>(),
      child: _SchedulingScreenContent(
        highlightShiftCode: highlightShiftCode,
        highlightClassroomCode: highlightClassroomCode,
        initialDate: initialDate,
        forceDayView: forceDayView,
      ),
    );
  }
}

class _SchedulingScreenContent extends StatefulWidget {
  const _SchedulingScreenContent({
    this.highlightShiftCode,
    this.highlightClassroomCode,
    this.initialDate,
    this.forceDayView = false,
  });

  final String? highlightShiftCode;
  final String? highlightClassroomCode;
  final DateTime? initialDate;
  final bool forceDayView;

  @override
  State<_SchedulingScreenContent> createState() =>
      _SchedulingScreenContentState();
}

class _SchedulingScreenContentState extends State<_SchedulingScreenContent> {
  bool _expandAll = false;

  /// Persists across screen instances so an edit that happened while this
  /// screen was off-stack still triggers a silent staff-list refresh on
  /// the next visit.
  static int _lastConsumedRevision = 0;

  /// Tracks the device-local "today" used by [SchedulingState.initial] before
  /// the school zone resolved, so we can re-seed the cubit only when the user
  /// hasn't already picked a different day.
  DateTime? _initialDeviceToday;

  /// Today's sign-in status keyed by staffCode, resolved via the bulk POST
  /// `/staff-attendance/sign-in/status`. Used to colour the avatar dot on
  /// each staff row (SIGNED_IN → green, ABSENT → red).
  Map<String, String> _staffSignInStatusByCode = const <String, String>{};

  /// Tracks the most recent set of staff codes we requested so we don't refire
  /// the POST every rebuild when the visible roster is unchanged.
  Set<String> _lastRequestedStaffCodes = const <String>{};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _initialDeviceToday = DateTime(now.year, now.month, now.day);
    // Fire the cubit's entry-load exactly once per screen entry. First time
    // runs the full visible load; subsequent entries run a silent
    // staff-only background refresh (no shimmer, no whole-page reload).
    // ignore: discarded_futures
    context.read<SchedulingCubit>().loadIfNeeded();
    // Notification deep-link: force day view + jump to the target day. Applied
    // synchronously so `_bootstrapSchoolZone` sees a non-initial day and won't
    // re-seed it back to "today".
    final cubit = context.read<SchedulingCubit>();
    if (widget.forceDayView) {
      cubit.setViewMode(SchedulingViewMode.day);
    }
    if (widget.initialDate != null) {
      cubit.selectDay(widget.initialDate!);
    }
    // Kick off classroom fetch on first frame. The no-pagination scheduling
    // staff list is loaded by [SchedulingStaffListCubit] at the route level.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ClassroomCubit>().loadActiveClassrooms(
        onlyTypeClassroom: false,
      );
      _silentlyRefreshStaffIfDirty();
      _bootstrapSchoolZone();
    });
    SchedulingCacheGate.revision.addListener(_onCacheInvalidated);
  }

  Future<void> _bootstrapSchoolZone() async {
    try {
      await bootstrapSchedulingSchoolTimezone();
      if (!mounted) return;
      final schoolToday = schedulingSchoolToday();
      final cubit = context.read<SchedulingCubit>();
      final selected = cubit.state.selectedDay;
      final initialToday = _initialDeviceToday;
      final stillOnInitialToday =
          initialToday != null &&
          selected.year == initialToday.year &&
          selected.month == initialToday.month &&
          selected.day == initialToday.day;
      if (stillOnInitialToday &&
          (selected.year != schoolToday.year ||
              selected.month != schoolToday.month ||
              selected.day != schoolToday.day)) {
        cubit.selectDay(schoolToday);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    SchedulingCacheGate.revision.removeListener(_onCacheInvalidated);
    super.dispose();
  }

  void _onCacheInvalidated() {
    if (!mounted) return;
    _silentlyRefreshStaffIfDirty();
  }

  /// Force-reload the staff list cache silently — no shimmer, no full
  /// scheduling reload. The classroom view doesn't watch
  /// [SchedulingStaffListCubit]'s loading state, so the refresh is
  /// invisible to the user.
  void _silentlyRefreshStaffIfDirty() {
    final current = SchedulingCacheGate.revision.value;
    if (current == _lastConsumedRevision) return;
    _lastConsumedRevision = current;
    // ignore: discarded_futures
    context.read<SchedulingStaffListCubit>().load(force: true);
  }

  /// Collects every staff code visible in the current classroom roster and
  /// fires the bulk POST `/staff-attendance/sign-in/status` once per distinct
  /// roster. Skips the call when the roster hasn't changed since last fetch.
  Future<void> _refreshSignInStatusForVisible(
    List<ClassroomDaySchedule> classrooms,
  ) async {
    final codes = <String>{};
    for (final c in classrooms) {
      for (final s in c.staff) {
        final code = s.staffCode.trim();
        if (code.isNotEmpty) codes.add(code);
      }
    }
    if (codes.isEmpty) {
      if (_staffSignInStatusByCode.isNotEmpty ||
          _lastRequestedStaffCodes.isNotEmpty) {
        if (mounted) {
          setState(() {
            _staffSignInStatusByCode = const <String, String>{};
            _lastRequestedStaffCodes = const <String>{};
          });
        }
      }
      return;
    }
    if (codes.length == _lastRequestedStaffCodes.length &&
        codes.containsAll(_lastRequestedStaffCodes)) {
      return;
    }
    _lastRequestedStaffCodes = codes;
    try {
      final map = await serviceLocator<GetStaffTodaySignInStatusMapUseCase>()(
        staffCodes: codes.toList(growable: false),
      );
      if (!mounted) return;
      setState(() => _staffSignInStatusByCode = map);
    } catch (_) {
      // Best-effort: a failed status fetch just keeps the previous dots.
    }
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
    // Reset the dedupe guard so the bulk sign-in status POST re-fires even
    // when the visible roster is unchanged, and await it so the pull
    // indicator stays up until every API on this screen has settled.
    if (!mounted) return;
    _lastRequestedStaffCodes = const <String>{};
    await _refreshSignInStatusForVisible(cubit.state.filteredClassrooms);
  }

  Map<String, String> _classroomNamesByCode(BuildContext context) {
    return {
      for (final c in context.read<ClassroomCubit>().state.classrooms)
        if (c.code.trim().isNotEmpty && c.name.trim().isNotEmpty)
          c.code.trim(): c.name.trim(),
    };
  }

  SchedulingShiftNavigator _shiftNavigator(
    BuildContext context,
    DateTime selectedDay,
  ) {
    return SchedulingShiftNavigator(
      classroomNamesByCode: _classroomNamesByCode(context),
      selectedDay: selectedDay,
      onDataMutated: () => context.read<SchedulingCubit>().load(),
    );
  }

  void _openStaffShiftFromEntry(
    BuildContext context,
    StaffScheduleEntry entry,
    String classroomName,
    DateTime selectedDay,
  ) {
    _shiftNavigator(
      context,
      selectedDay,
    ).openFromStaffEntry(context, entry: entry, classroomName: classroomName);
  }

  void _openStaffShiftFromSlot(
    BuildContext context,
    StaffScheduleEntry entry,
    StaffShiftSlotDetail detail,
    String classroomName,
    DateTime selectedDay,
  ) {
    _shiftNavigator(context, selectedDay).openFromSlotDetail(
      context,
      detail: detail,
      staffName: entry.staffName,
      classroomName: classroomName,
    );
  }

  Future<void> _openAddShiftScreen(DateTime selectedDay) async {
    // The cubits are provided at the route level; capture them here so they
    // remain available inside the pushed [MaterialPageRoute] (which would
    // otherwise lose the provider scope).
    final classroomCubit = context.read<ClassroomCubit>();
    final schedulingStaffListCubit = context.read<SchedulingStaffListCubit>();
    final schedulingCubit = context.read<SchedulingCubit>();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
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
    if (saved == true && mounted) {
      await schedulingCubit.load();
    }
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
          // ignore: discarded_futures
          _refreshSignInStatusForVisible(state.filteredClassrooms);
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
                    onAddTap: () {
                      // ignore: discarded_futures
                      _openAddShiftScreen(state.selectedDay);
                    },
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
                    ClassroomSchedulingShimmer(
                      showDayTimelineBlocks:
                          state.viewMode == SchedulingViewMode.day,
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
                      day: state.selectedDay,
                      dayLabel: DateFormat('EEE d').format(state.selectedDay),
                      expandAll: _expandAll,
                      onToggleExpandAll: () =>
                          setState(() => _expandAll = !_expandAll),
                      staffAttendanceStatusByCode: _staffSignInStatusByCode,
                      highlightShiftCode: widget.highlightShiftCode,
                      onStaffShiftTap: (entry, classroomName) =>
                          _openStaffShiftFromEntry(
                            context,
                            entry,
                            classroomName,
                            state.selectedDay,
                          ),
                    )
                  else
                    _DailyClassroomListCard(
                      classrooms: state.filteredClassrooms,
                      day: state.selectedDay,
                      expandAll: _expandAll,
                      onToggleExpandAll: () =>
                          setState(() => _expandAll = !_expandAll),
                      staffAttendanceStatusByCode: _staffSignInStatusByCode,
                      highlightShiftCode: widget.highlightShiftCode,
                      highlightClassroomCode: widget.highlightClassroomCode,
                      onStaffShiftTap: (entry, classroomName) =>
                          _openStaffShiftFromEntry(
                            context,
                            entry,
                            classroomName,
                            state.selectedDay,
                          ),
                      onStaffSlotTap: (entry, detail, classroomName) =>
                          _openStaffShiftFromSlot(
                            context,
                            entry,
                            detail,
                            classroomName,
                            state.selectedDay,
                          ),
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
    required this.day,
    required this.dayLabel,
    required this.expandAll,
    required this.onToggleExpandAll,
    required this.onStaffShiftTap,
    this.staffAttendanceStatusByCode,
    this.highlightShiftCode,
  });

  final List<ClassroomDaySchedule> classrooms;
  final DateTime day;
  final String dayLabel;
  final bool expandAll;
  final VoidCallback onToggleExpandAll;
  final void Function(StaffScheduleEntry entry, String classroomName)
  onStaffShiftTap;
  final Map<String, String>? staffAttendanceStatusByCode;
  final String? highlightShiftCode;

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
                key: ValueKey('week-${classrooms[i].classroomCode}-$expandAll'),
                classroom: classrooms[i],
                viewMode: SchedulingViewMode.week,
                day: day,
                initiallyExpanded: expandAll,
                isLast: i == classrooms.length - 1,
                staffAttendanceStatusByCode: staffAttendanceStatusByCode,
                highlightShiftCode: highlightShiftCode,
                onStaffShiftTap: (entry) =>
                    onStaffShiftTap(entry, classrooms[i].classroomName),
              ),
          ],
        ),
      ),
    );
  }
}

class _DailyClassroomListCard extends StatelessWidget {
  const _DailyClassroomListCard({
    required this.classrooms,
    required this.day,
    required this.expandAll,
    required this.onToggleExpandAll,
    required this.onStaffShiftTap,
    required this.onStaffSlotTap,
    this.staffAttendanceStatusByCode,
    this.highlightShiftCode,
    this.highlightClassroomCode,
  });

  final List<ClassroomDaySchedule> classrooms;
  final DateTime day;
  final bool expandAll;
  final VoidCallback onToggleExpandAll;
  final void Function(StaffScheduleEntry entry, String classroomName)
  onStaffShiftTap;
  final void Function(
    StaffScheduleEntry entry,
    StaffShiftSlotDetail detail,
    String classroomName,
  )
  onStaffSlotTap;
  final Map<String, String>? staffAttendanceStatusByCode;
  final String? highlightShiftCode;
  final String? highlightClassroomCode;

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
            DailyClassroomScheduleHeader(
              expandAll: expandAll,
              onToggleExpandAll: onToggleExpandAll,
            ),
            for (int i = 0; i < classrooms.length; i++)
              DayClassroomSection(
                key: ValueKey(
                    'day-${classrooms[i].classroomCode}-$expandAll-$highlightClassroomCode'),
                classroom: classrooms[i],
                viewMode: SchedulingViewMode.day,
                day: day,
                initiallyExpanded: expandAll,
                isLast: i == classrooms.length - 1,
                staffAttendanceStatusByCode: staffAttendanceStatusByCode,
                highlightShiftCode: highlightShiftCode,
                highlightClassroomCode: highlightClassroomCode,
                onStaffShiftTap: (entry) =>
                    onStaffShiftTap(entry, classrooms[i].classroomName),
                onStaffSlotTap: (entry, detail) =>
                    onStaffSlotTap(entry, detail, classrooms[i].classroomName),
              ),
          ],
        ),
      ),
    );
  }
}
