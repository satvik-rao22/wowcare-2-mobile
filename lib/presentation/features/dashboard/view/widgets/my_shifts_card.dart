import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_shifts_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

/// Height of one hour-row in the shift calendar grid.
const double cellHeightRow = 40;

// ---------------------------------------------------------------------------
// Local mock models — replace the cubit-driven schedule entities.
// ---------------------------------------------------------------------------

/// A single shift block. [start]/[end] are in `hh:mm:ss a` format.
class Shift {
  const Shift({
    required this.start,
    required this.end,
    required this.room,
    this.isBreakShift = false,
    this.shiftCode = '',
  });

  final String start;
  final String end;
  final String room;
  final bool isBreakShift;

  /// Source shift identity (empty for mock/legacy data). Lets the
  /// scheduling screen fetch full details via
  /// `GET /api/v1/staff-shifts/{shiftCode}` on tap.
  final String shiftCode;
}

/// All shifts for one day.
class DailyShifts {
  const DailyShifts({required this.shifts});

  final List<Shift> shifts;
}

/// School operating window — drives the calendar's hour rows (06 AM – 06 PM).
const String _schoolStartTime = '06:00:00 AM';
const String _schoolEndTime = '06:30:00 PM';

/// "My Shifts" dashboard card.
///
/// UI-only port of the reference card: a "My Shifts" header, a staff profile
/// row, weekly hour-summary tiles, and the day's shift calendar grid.
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
      // ignore: discarded_futures
      context.read<MyShiftsCubit>().load();
    });
  }

  List<Shift> _mapToCalendarBlocks(MyShiftsState state) {
    final shifts = state.todayShifts;
    if (shifts.isEmpty) return const <Shift>[];

    final blocks = <Shift>[];
    for (final s in shifts) {
      final classroom =
          (s.classroomName.trim().isNotEmpty
                  ? s.classroomName.trim()
                  : s.classroomCode.trim())
              .trim();
      blocks.add(
        Shift(
          start: MyShiftsCubit.formatBlockTime(s.startTime),
          end: MyShiftsCubit.formatBlockTime(s.endTime),
          room: classroom.isEmpty ? '-' : classroom,
          shiftCode: s.shiftCode,
        ),
      );

      final breakStart = s.breakStartTime;
      final breakEnd = s.breakEndTime;
      if (breakStart != null && breakEnd != null) {
        blocks.add(
          Shift(
            start: MyShiftsCubit.formatBlockTime(breakStart),
            end: MyShiftsCubit.formatBlockTime(breakEnd),
            room: 'Break',
            isBreakShift: true,
            shiftCode: s.shiftCode,
          ),
        );
      }
    }
    return blocks;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyShiftsCubit, MyShiftsState>(
      buildWhen: (p, c) =>
          p.status != c.status ||
          p.staffName != c.staffName ||
          p.designation != c.designation ||
          p.classroomLabel != c.classroomLabel ||
          p.availableHours != c.availableHours ||
          p.scheduledHours != c.scheduledHours ||
          p.unscheduledHours != c.unscheduledHours ||
          p.todayShifts != c.todayShifts,
      builder: (context, state) {
        final staffName = state.staffName.trim().isNotEmpty
            ? state.staffName.trim()
            : '—';
        final designation = state.designation.trim().isNotEmpty
            ? state.designation.trim()
            : '—';
        final classroom = state.classroomLabel.trim().isNotEmpty
            ? state.classroomLabel.trim()
            : '—';

        final blocks = _mapToCalendarBlocks(state);

        return Card(
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
                // ── Header: "My Shifts" title + collapse toggle ───────────────
                DashboardCardHeader(
                  title: 'My Shifts',
                  showRedirect: true,
                  onRedirect: () {},
                  minimized: _minimized,
                  onToggle: () => setState(() => _minimized = !_minimized),
                ),

                // ── Collapsible body ──────────────────────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _minimized
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            const SizedBox(height: 16),

                            // Staff profile row.
                            Row(
                              children: [
                                Stack(
                                  children: [
                                    DocumentImageWidget(
                                      fileUuid: '',
                                      name: staffName,
                                      size: 80,
                                      fontSize: 28,
                                      disableProfileLookupFallback: true,
                                      disableAttendanceStatusLookup: true,
                                    ),
                                    // Signed-in status indicator.
                                    Positioned(
                                      top: 3,
                                      right: 3,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: const Color.fromRGBO(
                                            0,
                                            177,
                                            21,
                                            1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        staffName,
                                        style: const TextStyle(
                                          color: AppColors.primaryColor,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              designation,
                                              style: const TextStyle(
                                                color: AppColors.primaryColor,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Flexible(
                                            child: Text(
                                              classroom,
                                              style: const TextStyle(
                                                color: AppColors.primaryColor,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Weekly hour summary.
                            ShiftHoursTile(
                              bgColor: const Color.fromRGBO(255, 250, 234, 1.0),
                              label: 'Available Hours',
                              hours: state.availableHours.toString(),
                              icon: MediaRes.availableHoursIcon,
                            ),
                            const SizedBox(height: 16),
                            ShiftHoursTile(
                              bgColor: const Color.fromRGBO(234, 255, 250, 1.0),
                              label: 'Scheduled Hours',
                              hours: state.scheduledHours.toString(),
                              icon: MediaRes.scheduledHoursIcon,
                            ),
                            const SizedBox(height: 16),
                            ShiftHoursTile(
                              bgColor: const Color.fromRGBO(22, 40, 49, 0.01),
                              label: 'Unscheduled Hours',
                              hours: state.unscheduledHours.toString(),
                              icon: MediaRes.unScheduledHoursIcon,
                            ),
                            const SizedBox(height: 20),

                            // Day shift calendar grid (Time header + grid).
                            ShiftCalendar(
                              dailyRoomSchedule: DailyShifts(shifts: blocks),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A weekly hour-summary row (icon + label + hours value).
class ShiftHoursTile extends StatelessWidget {
  const ShiftHoursTile({
    super.key,
    required this.bgColor,
    required this.label,
    required this.hours,
    required this.icon,
  });

  final Color bgColor;
  final String label;
  final String hours;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          SvgPicture.asset(icon, height: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.primaryColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            hours,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Day shift calendar — a "Time" / date-navigator header, an hourly time
/// column on the left, and the day's shift blocks positioned by time.
class ShiftCalendar extends StatefulWidget {
  const ShiftCalendar({super.key, required this.dailyRoomSchedule});

  final DailyShifts dailyRoomSchedule;

  @override
  State<ShiftCalendar> createState() => _ShiftCalendarState();
}

class _ShiftCalendarState extends State<ShiftCalendar> {
  /// Shifts sorted so work shifts paint before break shifts (break on top).
  late final List<Shift> _shifts;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _shifts = List<Shift>.of(widget.dailyRoomSchedule.shifts)
      ..sort((a, b) {
        if (a.isBreakShift == b.isBreakShift) return 0;
        return a.isBreakShift ? 1 : -1;
      });
  }

  void _changeDate(int days) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: days)));
  }

  DateTime _parseTime(String input) {
    const formats = ['h.mm a', 'hh:mm:ss a', 'hh:mm a'];
    for (final pattern in formats) {
      try {
        return DateFormat(pattern).parseStrict(input);
      } catch (_) {}
    }
    throw FormatException('Invalid time format: $input');
  }

  String _convertTimeToHHmm(String timeStr) {
    final dateTime = DateFormat('hh:mm:ss a').parse(timeStr);
    return DateFormat('hh:mm a').format(dateTime);
  }

  double _getTimeDifferenceInHours(String startTime, String endTime) {
    final format = DateFormat('hh:mm:ss a');
    final start = format.parse(startTime);
    final end = format.parse(endTime);
    return end.difference(start).inMinutes / 60.0;
  }

  List<String> _generateHourlyTimeSlots(String start, String end) {
    final outputFormat = DateFormat('hh:mm a');
    DateTime startTime = _parseTime(start);
    DateTime endTime = _parseTime(end);

    // Round start down to the hour.
    startTime = DateTime(
      startTime.year,
      startTime.month,
      startTime.day,
      startTime.hour,
    );

    // Round end up if it has loose minutes/seconds.
    if (endTime.minute > 0 || endTime.second > 0) {
      endTime = endTime.add(const Duration(hours: 1));
      endTime = DateTime(
        endTime.year,
        endTime.month,
        endTime.day,
        endTime.hour,
      );
    }

    final slots = <String>[];
    var current = startTime;
    while (current.isBefore(endTime)) {
      slots.add(outputFormat.format(current));
      current = current.add(const Duration(hours: 1));
    }
    return slots;
  }

  // ── Header: "Time" label + date navigator ────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.07),
        border: const Border(bottom: BorderSide(width: 1, color: Colors.grey)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: Center(
              child: Text(
                'Time',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(flex: 5, child: Center(child: _buildDateNavigator())),
        ],
      ),
    );
  }

  Widget _buildDateNavigator() {
    final formattedDate = DateFormat('EEE, MMM d').format(_selectedDate);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _changeDate(-1),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(
            Icons.chevron_left,
            color: AppColors.primaryColor,
            size: 24,
          ),
        ),
        Text(
          formattedDate,
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          onPressed: () => _changeDate(1),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(
            Icons.chevron_right,
            color: AppColors.primaryColor,
            size: 24,
          ),
        ),
      ],
    );
  }

  // ── Time column ──────────────────────────────────────────────────────────

  Widget _buildTimeItem(String label) {
    return Container(
      height: cellHeightRow,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 1, color: Colors.grey.shade300),
          right: BorderSide(width: 1, color: Colors.grey.shade300),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeList() {
    final slots = _generateHourlyTimeSlots(_schoolStartTime, _schoolEndTime);
    return Column(children: slots.map(_buildTimeItem).toList());
  }

  // ── Shift blocks ─────────────────────────────────────────────────────────

  Widget _buildSingleShift(Shift shift) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shift.room,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '${_convertTimeToHHmm(shift.start)} - '
            '${_convertTimeToHHmm(shift.end)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakShift(Shift shift) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color.fromRGBO(254, 241, 199, 1.0),
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(
              text: 'Lunch Break  ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            TextSpan(
              text:
                  '${_convertTimeToHHmm(shift.start)} - '
                  '${_convertTimeToHHmm(shift.end)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTimeContainer(Shift shift) {
    final double height =
        _getTimeDifferenceInHours(shift.start, shift.end) * cellHeightRow;
    final double topSpace =
        _getTimeDifferenceInHours(_schoolStartTime, shift.start) *
        cellHeightRow;
    return Positioned(
      top: topSpace,
      left: 0,
      right: 0,
      child: SizedBox(
        height: height,
        child: shift.isBreakShift
            ? _buildBreakShift(shift)
            : _buildSingleShift(shift),
      ),
    );
  }

  Widget _buildShifts() {
    final slotCount = _generateHourlyTimeSlots(
      _schoolStartTime,
      _schoolEndTime,
    ).length;
    return SizedBox(
      height: cellHeightRow * slotCount,
      // Single continuous bluish background covering the whole right side.
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromRGBO(234, 244, 255, 1.0),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            ..._shifts.map(_buildTimeContainer),
            if (_shifts.isEmpty)
              const Center(
                child: Text(
                  'No Shifts for Today',
                  style: TextStyle(
                    fontSize: 20,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildTimeList()),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _buildShifts(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
