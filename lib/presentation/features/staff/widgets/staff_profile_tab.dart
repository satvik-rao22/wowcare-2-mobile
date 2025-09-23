import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';

class StaffProfileTab extends StatelessWidget {
  const StaffProfileTab({
    super.key,
    required this.name,
    required this.profileStatus, // 'A', 'I', 'Upcoming'
    required this.designation,
    required this.allowedClassrooms,
    required this.primaryClassroom,
    required this.email,
    required this.clockInPin,
    required this.phoneNumber,
    this.address = '',
    this.birthDate = '',
    this.jobTag = '',
    required this.schedules, // work/break time entries
  });

  final String name;
  final String profileStatus;
  final String designation;
  final List<String> allowedClassrooms;
  final String primaryClassroom;
  final String email;
  final String clockInPin;
  final String phoneNumber;
  final String address;
  final String birthDate; // formatted e.g. Oct 29, 2001
  final String jobTag;
  final List<ScheduleEntry> schedules;

  static const List<String> _allDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  @override
  Widget build(BuildContext context) {
    final chipColors = <Color>[
      const Color.fromRGBO(177, 175, 233, 0.3),
      const Color.fromRGBO(203, 246, 255, 0.4),
      const Color.fromRGBO(217, 255, 203, 0.4),
    ];

    final workingDays = _getWorkingDays(schedules);
    final workTimes = _getFormattedTimes(schedules, false);
    final breakTimes = _getFormattedTimes(schedules, true);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.themeColor),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(12),
            bottom: Radius.circular(16),
          ),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(label: 'Name', value: name),
            const SizedBox(height: 16),
            _Field(
              label: 'Status',
              value: null,
              trailing: _buildStatusChip(profileStatus),
            ),
            const SizedBox(height: 12),
            _Field(label: 'Designation', value: designation),
            const SizedBox(height: 16),
            _Field(label: 'Email', value: (email.isEmpty ? 'aparna12345@wiseowl.academy' : email)),
            const SizedBox(height: 16),
            _Field(
                label: 'Clock In-Out PIN',
                value: (clockInPin.isEmpty ? '497487' : clockInPin)),
            const SizedBox(height: 16),
            _Field(
              label: 'Phone Number',
              value: (phoneNumber.isEmpty ? _formatPhoneNumber('9860271627') : _formatPhoneNumber(phoneNumber)),
            ),
            const SizedBox(height: 16),
            _Field(
              label: 'Address',
              value: (address.isEmpty
                  ? '12, East Dunstable road, Nashua, NH, USA,\n03062'
                  : address),
            ),
            const SizedBox(height: 16),
            _Field(
              label: 'Birth Date',
              value: (birthDate.isEmpty ? 'Oct 29, 2001' : birthDate),
            ),
            const SizedBox(height: 16),
            _Field(
              label: 'Job Tag',
              value: (jobTag.isEmpty ? 'Full Time' : jobTag),
            ),
            const SizedBox(height: 16),
            _Field(
              label: 'Allowed Classrooms',
              value: null,
              trailing: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(
                  allowedClassrooms.length,
                  (index) => _Chip(
                    label: allowedClassrooms[index],
                    labelColor: const Color.fromRGBO(27, 35, 126, 1),
                    color: chipColors[index % chipColors.length],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _Field(
              label: 'Primary Classroom',
              value: null,
              trailing: _Chip(
                label: primaryClassroom,
                labelColor: const Color.fromRGBO(27, 35, 126, 1),
                color: chipColors.first,
              ),
            ),
          const SizedBox(height: 16),
            // Availability with edit icon like reference
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Availability',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff573353),
                  ),
                ),
                Icon(
                  Icons.edit,
                  size: 16,
                  color: Color(0x99573353),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _allDays.map((day) {
                      final isAvailable = workingDays.contains(day);
                      return Opacity(
                        opacity: isAvailable ? 1 : 0.4,
                        child: _Chip(
                          label: day,
                          labelColor: isAvailable
                              ? const Color.fromRGBO(27, 35, 126, 1)
                              : Colors.grey[700]!,
                          color: isAvailable
                              ? const Color.fromRGBO(203, 246, 255, 0.4)
                              : Colors.grey[300]!,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          _Field(
            label: 'Work Time',
            value: null,
            trailing: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allDays.map((day) {
                      final isAvailable = workingDays.contains(day);
                      return Opacity(
                        opacity: isAvailable ? 1 : 0.4,
                        child: _TimeChip(label: workTimes[day] ?? '- -'),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Field(
            label: 'Break Time',
            value: null,
            trailing: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allDays.map((day) {
                      final isAvailable = workingDays.contains(day);
                      return Opacity(
                        opacity: isAvailable ? 1 : 0.4,
                        child: _TimeChip(label: breakTimes[day] ?? '- -'),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final label = status == 'A'
        ? 'Active'
        : status == 'I'
            ? 'Inactive'
            : status == 'Upcoming'
                ? 'Upcoming'
                : 'Active';
    final labelColor = status == 'A'
        ? const Color.fromRGBO(56, 200, 32, 1)
        : status == 'Upcoming'
            ? const Color.fromARGB(255, 238, 223, 8)
            : const Color.fromRGBO(250, 65, 65, 1);
    final bgColor = status == 'A'
        ? const Color.fromRGBO(56, 200, 32, 0.1)
        : status == 'Upcoming'
            ? const Color.fromARGB(255, 242, 238, 176)
            : const Color.fromRGBO(250, 65, 65, 0.1);
    final icon = status == 'A'
        ? SvgPicture.asset(MediaRes.checkMarkIcon, height: 18)
        : null;

    return _Chip(label: label, labelColor: labelColor, color: bgColor, icon: icon);
  }

  String _formatPhoneNumber(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return number;
    return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, 10)}';
  }

  List<String> _getWorkingDays(List<ScheduleEntry> schedule) {
    return schedule
        .where((e) => !e.isBreakTime)
        .map((e) => _capitalizeFirst(e.day))
        .toSet()
        .toList();
  }

  Map<String, String> _getFormattedTimes(List<ScheduleEntry> schedule, bool isBreakTime) {
    final Map<String, String> times = {};
    for (final e in schedule.where((x) => x.isBreakTime == isBreakTime)) {
      final day = _capitalizeFirst(e.day);
      final start = _formatTime(e.startTime);
      final end = _formatTime(e.endTime);
      times[day] = '$start -\n $end';
    }
    for (final day in _allDays) {
      times.putIfAbsent(day, () => '- -');
    }
    return times;
  }

  String _formatTime(String input) {
    final parts = input.split(' '); // e.g., 09:00 AM
    final period = parts.last;
    final hhmm = parts.first.split(':');
    return '${hhmm[0]}:${hhmm[1]}$period';
  }

  String _capitalizeFirst(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

class ScheduleEntry {
  ScheduleEntry({
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.isBreakTime,
  });

  final String day; // e.g. 'monday'
  final String startTime; // e.g. '09:00 AM'
  final String endTime; // e.g. '05:00 PM'
  final bool isBreakTime;
}

class _Field extends StatelessWidget {
  const _Field({required this.label, this.value, this.trailing});
  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xff573353),
          ),
        ),
        const SizedBox(height: 6),
        if (trailing == null)
          Text(
            value ?? '- -',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              color: Color(0xff573353),
              fontWeight: FontWeight.w400,
            ),
          )
        else
          trailing!,
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.labelColor, required this.color, this.icon});
  final String label;
  final Color labelColor;
  final Color color;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4FB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF4B5B7A),
        ),
      ),
    );
  }
}


