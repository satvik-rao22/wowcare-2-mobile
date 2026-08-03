import 'dart:async';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_shifts_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_error_chip.dart';
import 'package:wowcare/presentation/features/scheduling/model/shift_models.dart';
import 'package:wowcare/presentation/features/scheduling/utils/classroom_name_resolver.dart';
import 'package:wowcare/presentation/features/scheduling/view/staff_scheduling_screen.dart';
import 'package:wowcare/presentation/features/scheduling/view/view_shift_screen.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/staff_day_schedule_calendar.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/staff_schedule_tile.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

/// "My Shifts" card for dashboard. Shows staff profile, hour summary tiles, and full calendar.
/// Matches the visual style of StaffSchedulingScreen exactly.
class MyShiftsCard extends StatefulWidget {
  const MyShiftsCard({super.key});

  @override
  State<MyShiftsCard> createState() => _MyShiftsCardState();
}

class _MyShiftsCardState extends State<MyShiftsCard> {
  bool _minimized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<MyShiftsCubit>().load());
    });
  }

  Future<void> _onDateChanged(DateTime newDate) async {
    if (!mounted) return;
    await context.read<MyShiftsCubit>().changeSelectedDate(newDate);
  }

  /// Convert cubit shifts to DailyShifts format for StaffDayScheduleCalendar
  DailyShifts _mapToDailyShifts(
    MyShiftsState state,
    ClassroomNameResolver resolver,
  ) {
    final blocks = <Shift>[];

    for (final s in state.todayShifts) {
      // Resolve classroom code to human-readable name
      final classroomCode = s.classroomCode.trim();
      final classroom = resolver.resolve(
        classroomCode.isEmpty ? s.classroomName : classroomCode,
        fallback: s.classroomName.trim().isNotEmpty
            ? s.classroomName
            : classroomCode,
      );

      blocks.add(
        Shift(
          start: MyShiftsCubit.formatBlockTime(s.startTime),
          end: MyShiftsCubit.formatBlockTime(s.endTime),
          room: classroom.isEmpty ? '-' : classroom,
          isBreakShift: false,
          shiftCode: s.shiftCode,
        ),
      );

      // Add break shift if exists
      if (s.breakStartTime != null && s.breakEndTime != null) {
        blocks.add(
          Shift(
            start: MyShiftsCubit.formatBlockTime(s.breakStartTime!),
            end: MyShiftsCubit.formatBlockTime(s.breakEndTime!),
            room: 'Break',
            isBreakShift: true,
            shiftCode: s.shiftCode,
          ),
        );
      }
    }

    return DailyShifts(shifts: blocks);
  }

  /// Parse time string in `hh:mm:ss a` format to TimeOfDay
  TimeOfDay _parseTime(String timeStr) {
    final trimmed = timeStr.trim();
    final parts = trimmed.split(' ');
    if (parts.length < 2) return const TimeOfDay(hour: 0, minute: 0);

    final timePart = parts[0];
    final marker = parts[1].toUpperCase();
    final segments = timePart.split(':');
    if (segments.length < 2) return const TimeOfDay(hour: 0, minute: 0);

    var hour = int.tryParse(segments[0]) ?? 0;
    final minute = int.tryParse(segments[1]) ?? 0;

    if (marker == 'PM' && hour < 12) hour += 12;
    if (marker == 'AM' && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Open ViewShiftScreen when a shift is tapped
  Future<void> _onShiftTap(Shift shift) async {
    if (shift.shiftCode.isEmpty) return;

    final cubitState = context.read<MyShiftsCubit>().state;
    final startTime = _parseTime(shift.start);
    final endTime = _parseTime(shift.end);

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ViewShiftScreen(
          date: cubitState.selectedDate ?? AppTime.now(),
          staff: cubitState.staffName,
          classroom: shift.room,
          shiftStart: startTime,
          shiftEnd: endTime,
          breakStart: null,
          breakEnd: null,
          readOnly: true,
        ),
      ),
    );

    // Refresh data if shift was modified
    if (result == true && mounted) {
      unawaited(context.read<MyShiftsCubit>().load());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyShiftsCubit, MyShiftsState>(
      buildWhen: (p, c) =>
          p.status != c.status ||
          p.staffCode != c.staffCode ||
          p.staffName != c.staffName ||
          p.designation != c.designation ||
          p.classroomLabel != c.classroomLabel ||
          p.availableHours != c.availableHours ||
          p.scheduledHours != c.scheduledHours ||
          p.unscheduledHours != c.unscheduledHours ||
          p.todayShifts != c.todayShifts ||
          p.selectedDate != c.selectedDate ||
          p.schoolStartTime != c.schoolStartTime ||
          p.schoolEndTime != c.schoolEndTime,
      builder: (context, state) {
        // DEBUG: Log the state received from cubit
        AppLogger.d(
          '[MyShiftsCard.build] State avail=${state.availableHours}, sched=${state.scheduledHours}, unsched=${state.unscheduledHours}',
        );

        // Create resolver for classroom name lookup
        final classroomResolver = ClassroomNameResolver.fromMap(
          state.classroomNames,
        );
        final dailyShifts = _mapToDailyShifts(state, classroomResolver);
        final selectedDate = state.selectedDate ?? AppTime.now();
        final dayColumnLabel = DateFormat('EEE, MMM d').format(selectedDate);

        return DashboardCardErrorOverlay(
          show: state.isError,
          onRetry: () =>
              context.read<MyShiftsCubit>().load(date: state.selectedDate),
          child: Card(
            elevation: 0,
            color: Colors.white,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Card Header ────────────────────────────────────────────────
                  DashboardCardHeader(
                    title: 'My Shifts',
                    showRedirect: true,
                    onRedirect: () =>
                        context.go(StaffSchedulingScreen.routeName),
                    minimized: _minimized,
                    onToggle: () => setState(() => _minimized = !_minimized),
                    trailing: _DateNavRow(
                      selectedDate: selectedDate,
                      onPreviousDay: () => _onDateChanged(
                        selectedDate.subtract(const Duration(days: 1)),
                      ),
                      onNextDay: () => _onDateChanged(
                        selectedDate.add(const Duration(days: 1)),
                      ),
                      onDatePicked: _onDateChanged,
                    ),
                  ),

                  // ── Collapsible Body ───────────────────────────────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: _minimized
                        ? const SizedBox.shrink()
                        : Column(
                            children: [
                              const SizedBox(height: 16),

                              // ── Staff Profile Header (from scheduling screen) ──
                              _StaffProfileHeader(
                                staffCode: state.staffCode,
                                staffName: state.staffName,
                                designation: state.designation,
                                classroom: state.classroomLabel,
                              ),

                              const SizedBox(height: 16),

                              // ── Hour Summary Tiles (exact match) ──────────────
                              ShiftHoursTile(
                                bgColor: const Color.fromRGBO(255, 250, 234, 1),
                                label: 'Available Hours',
                                hours: formatSchedulingHours(
                                  state.availableHours.toDouble(),
                                ),
                                icon: MediaRes.availableHoursIcon,
                              ),
                              const SizedBox(height: 16),
                              ShiftHoursTile(
                                bgColor: const Color.fromRGBO(234, 255, 250, 1),
                                label: 'Scheduled Hours',
                                hours: formatSchedulingHours(
                                  state.scheduledHours.toDouble(),
                                ),
                                icon: MediaRes.scheduledHoursIcon,
                              ),
                              const SizedBox(height: 16),
                              ShiftHoursTile(
                                bgColor: const Color.fromRGBO(22, 40, 49, 0.01),
                                label: 'Unscheduled Hours',
                                hours: formatSchedulingHours(
                                  state.unscheduledHours.toDouble(),
                                ),
                                icon: MediaRes.unScheduledHoursIcon,
                              ),

                              const SizedBox(height: 20),

                              // ── Shift Calendar (from scheduling screen) ────────
                              if (state.schoolStartTime.isEmpty ||
                                  state.schoolEndTime.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      'No school hours configured for this day.',
                                      style: TextStyle(
                                        fontFamily: 'Manrope',
                                        color: AppColors.primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )
                              else
                                StaffDayScheduleCalendar(
                                  key: ValueKey(
                                    'my_shifts_${selectedDate.toString()}_'
                                    '${state.schoolStartTime}_'
                                    '${state.schoolEndTime}',
                                  ),
                                  dayColumnLabel: dayColumnLabel,
                                  schoolStartTime: state.schoolStartTime,
                                  schoolEndTime: state.schoolEndTime,
                                  classroomResolver: classroomResolver,
                                  dailyRoomSchedule: dailyShifts,
                                  highlightShiftCode: null,
                                  onShiftTap: _onShiftTap,
                                ),
                            ],
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

// ════════════════════════════════════════════════════════════════════════════
// Date Navigation Row (header trailing widget)
// ════════════════════════════════════════════════════════════════════════════

/// Compact date navigation placed in the DashboardCardHeader trailing slot.
/// Left/right arrows step by one day and re-fetch via [onPreviousDay]/[onNextDay].
/// Tapping the date label opens the reusable [CalendarDialog].
class _DateNavRow extends StatelessWidget {
  const _DateNavRow({
    required this.selectedDate,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onDatePicked,
  });

  final DateTime selectedDate;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final ValueChanged<DateTime> onDatePicked;

  Future<void> _openCalendar(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => CalendarDialog(
        isTimePicker: false,
        isRangePicker: false,
        initialDate: selectedDate,
      ),
    );
    if (result != null) {
      final picked = result['date'] as DateTime?;
      if (picked != null) onDatePicked(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE, MMM d').format(selectedDate);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Previous Day Arrow ─────────────────────────────────────────────
        GestureDetector(
          onTap: onPreviousDay,
          child: const Icon(
            Icons.chevron_left,
            color: AppColors.primaryColor,
            size: 20,
          ),
        ),

        // ── Tappable Date Label ────────────────────────────────────────────
        GestureDetector(
          onTap: () => _openCalendar(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              dateLabel,
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: AppColors.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // ── Next Day Arrow ─────────────────────────────────────────────────
        GestureDetector(
          onTap: onNextDay,
          child: const Icon(
            Icons.chevron_right,
            color: AppColors.primaryColor,
            size: 20,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Staff Profile Header (reused from scheduling screen)
// ════════════════════════════════════════════════════════════════════════════

/// Staff profile section: circular photo + name, designation, classroom.
/// Matches the visual design of _StaffProfileHeader from StaffSchedulingScreen.
class _StaffProfileHeader extends StatelessWidget {
  const _StaffProfileHeader({
    required this.staffCode,
    required this.staffName,
    required this.designation,
    required this.classroom,
  });

  final String staffCode;
  final String staffName;
  final String designation;
  final String classroom;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Circular Profile Photo ─────────────────────────────────────────
        DocumentImageWidget(
          fileUuid: staffCode,
          name: staffName,
          staffCode: staffCode.isNotEmpty ? staffCode : null,
          size: 80,
          fontSize: 28,
          disableProfileLookupFallback: false,
          disableAttendanceStatusLookup: true,
        ),

        const SizedBox(width: 24),

        // ── Staff Info (Name, Designation, Classroom) ──────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Staff Name
              Text(
                staffName,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  color: AppColors.primaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Designation (if not empty)
              if (designation.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  designation,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: AppColors.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  softWrap: true,
                ),
              ],

              // Classroom (if not empty)
              if (classroom.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  classroom,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: AppColors.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  softWrap: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
