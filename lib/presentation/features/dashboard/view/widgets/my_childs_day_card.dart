import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

// ---------------------------------------------------------------------------
// Local mock model classes – plain Dart, no imports from domain/data layers.
// ---------------------------------------------------------------------------

class _MockScheduleEntry {
  const _MockScheduleEntry({
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  final String day; // e.g. 'Monday'
  final String startTime; // e.g. '08:30 AM'
  final String endTime; // e.g. '03:00 PM'
}

class _MockStudent {
  const _MockStudent({
    required this.fullName,
    required this.roomName,
    required this.isSignedIn,
    required this.isAbsent,
    this.profileStatus = 'Active',
    this.signInPin = '4829',
  });

  final String fullName;
  final String roomName;
  final bool isSignedIn;
  final bool isAbsent;
  final String profileStatus;
  final String signInPin;
}

class _MockMessage {
  const _MockMessage({
    required this.senderName,
    required this.text,
  });

  final String senderName;
  final String text;
}

// ---------------------------------------------------------------------------
// Hardcoded mock data
// ---------------------------------------------------------------------------

const _MockStudent _mockStudent = _MockStudent(
  fullName: 'Emma Johnson',
  roomName: 'Sunflower Room',
  isSignedIn: true,
  isAbsent: false,
  profileStatus: 'Active',
  signInPin: '4829',
);

const List<_MockScheduleEntry> _mockSchedule = [
  _MockScheduleEntry(day: 'Monday', startTime: '08:30 AM', endTime: '03:00 PM'),
  _MockScheduleEntry(
      day: 'Tuesday', startTime: '08:30 AM', endTime: '03:00 PM'),
  _MockScheduleEntry(
      day: 'Wednesday', startTime: '08:30 AM', endTime: '03:00 PM'),
  _MockScheduleEntry(
      day: 'Thursday', startTime: '08:30 AM', endTime: '03:00 PM'),
  _MockScheduleEntry(day: 'Friday', startTime: '08:30 AM', endTime: '02:00 PM'),
];

const _MockMessage _mockLastMessage = _MockMessage(
  senderName: 'Ms. Laura (Teacher)',
  text: 'Emma had a wonderful painting session today!',
);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _twoDigits(int n) => n.toString().padLeft(2, '0');

/// Returns today's schedule entry if available, else the next upcoming one.
_MockScheduleEntry? _resolveCurrentSchedule() {
  final now = DateTime.now();
  final dayNames = [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final todayName = dayNames[now.weekday];
  for (final entry in _mockSchedule) {
    if (entry.day.toLowerCase() == todayName.toLowerCase()) return entry;
  }
  // Fallback: return the first entry if today is weekend
  return _mockSchedule.isNotEmpty ? _mockSchedule.first : null;
}

String _currentSchoolHours() {
  final entry = _resolveCurrentSchedule();
  if (entry == null) return 'No schedule';
  return '${entry.startTime} – ${entry.endTime}';
}

TimeOfDay? _parseTime(String timeStr) {
  try {
    final parts = timeStr.split(' ');
    final timeParts = parts[0].split(':');
    int hours = int.parse(timeParts[0]);
    int minutes = int.parse(timeParts[1]);
    if (parts.length > 1) {
      final isPM = parts[1].toLowerCase() == 'pm';
      if (isPM && hours != 12) hours += 12;
      if (!isPM && hours == 12) hours = 0;
    }
    return TimeOfDay(hour: hours, minute: minutes);
  } catch (_) {
    return null;
  }
}

/// Compute the mock countdown status and duration based on current time vs
/// today's (or tomorrow's) schedule.
({String statusText, Duration duration}) _computeCountdown() {
  final entry = _resolveCurrentSchedule();
  if (entry == null) {
    return (statusText: 'No schedule available', duration: Duration.zero);
  }
  final now = DateTime.now();
  final start = _parseTime(entry.startTime);
  final end = _parseTime(entry.endTime);
  if (start == null || end == null) {
    return (statusText: 'No schedule available', duration: Duration.zero);
  }
  final todayStr = '${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}';
  final schoolStart = DateTime.parse(
      '$todayStr ${_twoDigits(start.hour)}:${_twoDigits(start.minute)}:00');
  final schoolEnd = DateTime.parse(
      '$todayStr ${_twoDigits(end.hour)}:${_twoDigits(end.minute)}:00');

  if (now.isBefore(schoolStart)) {
    return (
      statusText: 'School starts in',
      duration: schoolStart.difference(now),
    );
  } else if (now.isBefore(schoolEnd)) {
    return (
      statusText: 'School ends in',
      duration: schoolEnd.difference(now),
    );
  } else {
    // School done for today – show tomorrow
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr =
        '${tomorrow.year}-${_twoDigits(tomorrow.month)}-${_twoDigits(tomorrow.day)}';
    final nextStart = DateTime.parse(
        '$tomorrowStr ${_twoDigits(start.hour)}:${_twoDigits(start.minute)}:00');
    return (
      statusText: "Tomorrow's school starts in",
      duration: nextStart.difference(now),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// A dashboard card showing a child's daily status and quick actions.
/// All data is hardcoded mock data (UI-only, no state management / API calls).
class MyChildsDayCard extends StatefulWidget {
  const MyChildsDayCard({super.key});

  @override
  State<MyChildsDayCard> createState() => _MyChildsDayCardState();
}

class _MyChildsDayCardState extends State<MyChildsDayCard> {
  bool _isMinimized = false;

  // Countdown timer state
  String _statusText = 'Loading schedule...';
  Duration _duration = Duration.zero;

  // Mock location / geofence state
  bool _isWithinGeofence = false;
  bool _isLocationEnabled = false;

  // Mock reminder toggle
  bool _isReminder = false;

  @override
  void initState() {
    super.initState();
    _refreshCountdown();
  }

  void _refreshCountdown() {
    final result = _computeCountdown();
    setState(() {
      _statusText = result.statusText;
      _duration = result.duration;
    });
  }

  // ----- Timer display -----

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontSize: 48,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.primaryColor.withValues(alpha: 0.5),
            fontSize: 12,
            height: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSeparator() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(2, 0, 2, 10),
      child: Text(
        ':',
        style: TextStyle(
          color: AppColors.primaryColor,
          fontSize: 48,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAlignedTimerDisplay(Duration duration) {
    final bool showDays = duration.inHours >= 24;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showDays) ...[
          _buildTimeUnit(duration.inDays.toString(), 'DD'),
          _buildTimeSeparator(),
        ],
        _buildTimeUnit(
            _twoDigits(duration.inHours.remainder(24)), 'HH'),
        _buildTimeSeparator(),
        _buildTimeUnit(
            _twoDigits(duration.inMinutes.remainder(60)), 'MM'),
        _buildTimeSeparator(),
        _buildTimeUnit(
            _twoDigits(duration.inSeconds.remainder(60)), 'SS'),
      ],
    );
  }

  // ----- Student detail row -----

  Widget _buildStudentDetailContainer() {
    final student = _mockStudent;
    final statusColor = student.profileStatus == 'Upcoming'
        ? const Color.fromARGB(255, 253, 205, 22)
        : student.isSignedIn
            ? const Color.fromRGBO(0, 177, 21, 1)
            : student.isAbsent
                ? const Color.fromRGBO(200, 32, 32, 1)
                : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // LEFT: profile photo with status dot
        Stack(
          children: [
            DocumentImageWidget(
              fileUuid: '',
              name: student.fullName,
              size: 90,
              fontSize: 28,
              disableProfileLookupFallback: true,
              disableAttendanceStatusLookup: true,
            ),
            if (statusColor != null)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 20),
        // RIGHT: name, hours chip, room
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              // School hours chip
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(177, 175, 233, 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currentSchoolHours(),
                  style: const TextStyle(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Room row
              Row(
                children: [
                  // Room avatar (non-person image → Container + icon)
                  
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      student.roomName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
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

  // ----- Sign-In/Out gradient button -----

  Widget _buildSignInOutButton() {
    final bool enabled = _isWithinGeofence && _isLocationEnabled;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Tooltip(
        message: !_isLocationEnabled
            ? 'Location permission is not granted.'
            : !_isWithinGeofence
                ? 'You are not within the geofencing range.'
                : '',
        triggerMode: TooltipTriggerMode.tap,
        preferBelow: false,
        child: CustomButtonLayout(
          isForm: false,
          showCancelButton: false,
          confirmButtonLabel:
              _mockStudent.isSignedIn ? 'Sign-Out' : 'Sign-In',
          onPressedConfirm: enabled ? () {} : null,
        ),
      ),
    );
  }

  // ----- Reminder row -----

  Widget _buildReminderRow() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isReminder = !_isReminder;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isReminder
                  ? 'Remind set successfully'
                  : 'Remind timer has turned off successfully',
            ),
          ),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(MediaRes.notificationsGradientIcon),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.buildPrimaryGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            ),
            child: Text(
              _isReminder ? 'Turn off reminder' : 'Send reminder',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ----- Sign-In PIN row -----

  Widget _buildSignInPinRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.buildPrimaryGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(
            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
          ),
          child: Text(
            'Your Sign-In Pin:  ${_mockStudent.signInPin}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: () {
            // QR scan navigation – empty stub (no screen import).
          },
          icon: SvgPicture.asset(MediaRes.scannerGradientIcon),
        ),
      ],
    );
  }

  // ----- Location name row -----

  Widget _buildLocationRow() {
    return Center(
      child: Text(
        'Current Location: Riverside Elementary School, Springfield',
        style: TextStyle(
          color: AppColors.primaryColor.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ----- Build -----

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          // ---- Header + collapsible body ----
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: const BoxDecoration(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(12)),
              color: Colors.white,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardCardHeader(
                  title: "My Child's Day",
                  minimized: _isMinimized,
                  onToggle: () =>
                      setState(() => _isMinimized = !_isMinimized),
                ),
                if (!_isMinimized) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _statusText,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 17,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildAlignedTimerDisplay(_duration),
                  const SizedBox(height: 16),
                  _buildReminderRow(),
                  const SizedBox(height: 8),
                  _buildLocationRow(),
                  const SizedBox(height: 20),
                  _buildStudentDetailContainer(),
                  const SizedBox(height: 16),
                  _buildSignInPinRow(),
                  const SizedBox(height: 16),
                  _buildSignInOutButton(),
                ],
              ],
            ),
          ),
          // ---- Communication row (always shown when not minimized) ----
          if (!_isMinimized)
            _CommunicationRowWidget(
              studentName: _mockStudent.fullName,
              lastMessage: _mockLastMessage,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Communication row (inline, no Firestore / bloc)
// ---------------------------------------------------------------------------

class _CommunicationRowWidget extends StatelessWidget {
  const _CommunicationRowWidget({
    required this.studentName,
    required this.lastMessage,
  });

  final String studentName;
  final _MockMessage lastMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        color: Color.fromRGBO(44, 99, 226, 0.05),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sender profile avatar (profile photo → DocumentImageWidget)
          DocumentImageWidget(
            fileUuid: '',
            name: lastMessage.senderName,
            size: 40,
            fontSize: 16,
            disableProfileLookupFallback: true,
            disableAttendanceStatusLookup: true,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lastMessage.senderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  lastMessage.text,
                  style: TextStyle(
                    color:
                        AppColors.primaryColor.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Chat navigation button (empty stub – no screen import)
          GestureDetector(
            onTap: () {}, // navigation to StudentConversationScreen is stubbed
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.buildPrimaryGradient(),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: SvgPicture.asset(
                  MediaRes.communicationIcon,
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
