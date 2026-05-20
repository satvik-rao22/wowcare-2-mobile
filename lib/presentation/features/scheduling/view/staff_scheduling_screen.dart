import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/my_shifts_card.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/staff_day_schedule_calendar.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

/// Staff Scheduling — single-day view with staff picker, profile summary,
/// hour totals, and day timeline. UI-only with mock data.
class StaffSchedulingScreen extends StatefulWidget {
  const StaffSchedulingScreen({super.key});

  static const String routeName = '/dashboard/staff-scheduling';

  @override
  State<StaffSchedulingScreen> createState() => _StaffSchedulingScreenState();
}

class _StaffSchedulingScreenState extends State<StaffSchedulingScreen> {
  DateTime _selectedDay = DateTime.now();
  String? _selectedStaff;

  static const List<String> _mockStaffNames = [
    'Jessica Rhodes',
    'Natasha White',
    'Michael Chen',
  ];

  static const _mockProfileByStaff = <String, ({String title, String room})>{
    'Jessica Rhodes': (title: 'Lead Teacher', room: '1-Blue-D'),
    'Natasha White': (title: 'Lead Teacher', room: '1-Blue-D'),
    'Michael Chen': (title: 'Assistant Teacher', room: '2-Green-A'),
  };

  static const String _availableHours = '45';
  static const String _scheduledHours = '35';
  static const String _unscheduledHours = '10';

  static const List<Shift> _mockShifts = [
    Shift(start: '07:00:00 AM', end: '05:30:00 PM', room: '1-Blue-D'),
    Shift(
      start: '12:00:00 PM',
      end: '12:30:00 PM',
      room: 'Lunch Break',
      isBreakShift: true,
    ),
  ];

  String get _displayStaffName =>
      _selectedStaff != null &&
              _selectedStaff != 'Select Staff' &&
              _mockStaffNames.contains(_selectedStaff)
          ? _selectedStaff!
          : _mockStaffNames.first;

  @override
  Widget build(BuildContext context) {
    final profile = _mockProfileByStaff[_displayStaffName] ??
        (title: 'Lead Teacher', room: '1-Blue-D');
    final dayColumnLabel = DateFormat('EEE, MMM d').format(_selectedDay);

    return GlobalScaffold(
      hasBackButton: true,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateHeaderRow(
              selectedDay: _selectedDay,
              onPreviousDay: () => setState(
                () => _selectedDay = _selectedDay.subtract(
                  const Duration(days: 1),
                ),
              ),
              onNextDay: () => setState(
                () => _selectedDay = _selectedDay.add(const Duration(days: 1)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0x19162831)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: CustomDropdown(
                hintText: 'Select Staff',
                items: _mockStaffNames,
                selectedItem: _selectedStaff,
                fieldHeight: 44,
                onSelect: (value) => setState(() => _selectedStaff = value),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StaffProfileHeader(
                    staffName: _displayStaffName,
                    designation: profile.title,
                    classroom: profile.room,
                  ),
                  const SizedBox(height: 16),
                  const ShiftHoursTile(
                    bgColor: Color.fromRGBO(255, 250, 234, 1),
                    label: 'Available Hours',
                    hours: _availableHours,
                    icon: MediaRes.availableHoursIcon,
                  ),
                  const SizedBox(height: 16),
                  const ShiftHoursTile(
                    bgColor: Color.fromRGBO(234, 255, 250, 1),
                    label: 'Scheduled Hours',
                    hours: _scheduledHours,
                    icon: MediaRes.scheduledHoursIcon,
                  ),
                  const SizedBox(height: 16),
                  const ShiftHoursTile(
                    bgColor: Color.fromRGBO(22, 40, 49, 0.01),
                    label: 'Unscheduled Hours',
                    hours: _unscheduledHours,
                    icon: MediaRes.unScheduledHoursIcon,
                  ),
                  const SizedBox(height: 20),
                  StaffDayScheduleCalendar(
                    key: ValueKey(
                      '${_displayStaffName}_${dayColumnLabel}_$_selectedDay',
                    ),
                    dayColumnLabel: dayColumnLabel,
                    dailyRoomSchedule: const DailyShifts(shifts: _mockShifts),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateHeaderRow extends StatelessWidget {
  const _DateHeaderRow({
    required this.selectedDay,
    required this.onPreviousDay,
    required this.onNextDay,
  });

  final DateTime selectedDay;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;

  static const Color _chevronColor = Color(0xFF9C84FF);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEE, MMM d').format(selectedDay);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onPreviousDay,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(
                Icons.chevron_left,
                color: _chevronColor,
                size: 24,
              ),
            ),
            Text(
              formattedDate,
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: AppColors.primaryColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: onNextDay,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(
                Icons.chevron_right,
                color: _chevronColor,
                size: 24,
              ),
            ),
          ],
        ),
        const Spacer(),
        GradientAddButton(onTap: () {}),
        const SizedBox(width: 8),
        _GradientPublishButton(onTap: () {}),
      ],
    );
  }
}

/// Gradient action button matching [GradientAddButton], with label text.
class _GradientPublishButton extends StatelessWidget {
  const _GradientPublishButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const height = 40.0;
    const borderRadius = 8.0;

    final child = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: AppColors.buildPrimaryGradient(),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        'Publish',
        style: TextStyle(
          fontFamily: 'Manrope',
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (onTap == null) return child;

    return GestureDetector(onTap: onTap, child: child);
  }
}

class _StaffProfileHeader extends StatelessWidget {
  const _StaffProfileHeader({
    required this.staffName,
    required this.designation,
    required this.classroom,
  });

  final String staffName;
  final String designation;
  final String classroom;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            DocumentImageWidget(
              fileUuid: staffName,
              name: staffName,
              size: 80,
              fontSize: 28,
              disableProfileLookupFallback: true,
              disableAttendanceStatusLookup: true,
            ),
            Positioned(
              top: 3,
              right: 3,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(0, 177, 21, 1),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      designation,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
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
                        fontFamily: 'Manrope',
                        color: AppColors.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
