import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

// ---------------------------------------------------------------------------
// Local mock model classes – plain Dart, no imports from domain/data layers.
// ---------------------------------------------------------------------------

/// Represents a single scheduled shift for a staff member.
class _MockShift {
  const _MockShift({
    required this.day,
    required this.startTime,
    required this.endTime,
    this.isBreakTime = false,
  });

  final String day; // e.g. 'MONDAY'
  final String startTime; // e.g. '09:00 AM'
  final String endTime; // e.g. '05:00 PM'
  final bool isBreakTime;
}

/// Represents the most-recent chat preview shown in [_CommunicationRowWidget].
class _MockChat {
  const _MockChat({
    required this.senderName,
    required this.lastMessage,
    this.isSignedIn = true,
    this.isAbsent = false,
    this.profileStatus = 'Active',
  });

  final String senderName;
  final String lastMessage;
  final bool isSignedIn;
  final bool isAbsent;
  final String profileStatus;
}

// ---------------------------------------------------------------------------
// Hardcoded mock data
// ---------------------------------------------------------------------------

/// Mock shifts for the current staff member.
const List<_MockShift> _mockSchedule = [
  _MockShift(day: 'MONDAY', startTime: '09:00 AM', endTime: '05:00 PM'),
  _MockShift(
    day: 'MONDAY',
    startTime: '12:00 PM',
    endTime: '01:00 PM',
    isBreakTime: true,
  ),
  _MockShift(day: 'TUESDAY', startTime: '09:00 AM', endTime: '05:00 PM'),
  _MockShift(
    day: 'TUESDAY',
    startTime: '12:00 PM',
    endTime: '01:00 PM',
    isBreakTime: true,
  ),
  _MockShift(day: 'WEDNESDAY', startTime: '09:00 AM', endTime: '05:00 PM'),
  _MockShift(
    day: 'WEDNESDAY',
    startTime: '12:00 PM',
    endTime: '01:00 PM',
    isBreakTime: true,
  ),
  _MockShift(day: 'THURSDAY', startTime: '09:00 AM', endTime: '05:00 PM'),
  _MockShift(
    day: 'THURSDAY',
    startTime: '12:00 PM',
    endTime: '01:00 PM',
    isBreakTime: true,
  ),
  _MockShift(day: 'FRIDAY', startTime: '09:00 AM', endTime: '03:00 PM'),
  _MockShift(
    day: 'FRIDAY',
    startTime: '12:00 PM',
    endTime: '12:30 PM',
    isBreakTime: true,
  ),
];

/// Mock current staff details used to populate labels.
const String _mockClockInPin = '4821';
const bool _mockIsSignedIn = false;
const bool _mockIsReminder = true;

/// Mock chat to show in the communication row.
const _MockChat _mockChat = _MockChat(
  senderName: 'Michael Torres',
  lastMessage: 'Can you cover the morning session tomorrow?',
  isSignedIn: true,
  isAbsent: false,
  profileStatus: 'Active',
);

// ---------------------------------------------------------------------------
// MyDayCard – StatefulWidget for collapse toggle & shift-countdown UI state.
// ---------------------------------------------------------------------------

/// Dashboard card displaying the staff member's current shift countdown,
/// sign-in pin, attendance action buttons, and the latest chat preview.
///
/// UI-only: all data is hardcoded mock; no bloc, cubit, or service calls.
class MyDayCard extends StatefulWidget {
  const MyDayCard({super.key});

  @override
  State<MyDayCard> createState() => _MyDayCardState();
}

class _MyDayCardState extends State<MyDayCard> {
  // ---- collapse state ----
  bool _minimized = false;

  // ---- shift countdown display state ----
  /// Text above the timer, e.g. "Your shift starts in" / "Your shift ends in".
  String _statusText = 'Your shift starts in';

  /// Pre-formatted work-time label, e.g. "09:00 AM - 05:00 PM".
  String _workTime = '09:00 AM - 05:00 PM';

  /// Pre-formatted break-time label.
  String _breakTime = '12:00 PM - 01:00 PM';

  /// Whether the staff has any scheduled shifts.
  bool _hasShifts = true;

  /// Remaining duration until shift start / shift end.
  Duration _duration = const Duration(hours: 2, minutes: 45, seconds: 0);

  @override
  void initState() {
    super.initState();
    // Compute mock countdown from the hardcoded schedule.
    _computeCountdown();
  }

  // ---- helpers ----

  int _getWeekdayIndex(String weekday) {
    switch (weekday.toUpperCase()) {
      case 'MONDAY':
        return 1;
      case 'TUESDAY':
        return 2;
      case 'WEDNESDAY':
        return 3;
      case 'THURSDAY':
        return 4;
      case 'FRIDAY':
        return 5;
      case 'SATURDAY':
        return 6;
      case 'SUNDAY':
        return 7;
      default:
        return 0;
    }
  }

  int _parseTimeToMinutes(String timeStr) {
    final parts = timeStr.split(' ');
    final timeParts = parts[0].split(':');
    int hours = int.parse(timeParts[0]);
    final int minutes = int.parse(timeParts[1]);
    final bool isPM = parts[1].toLowerCase() == 'pm';
    if (isPM && hours != 12) hours += 12;
    if (!isPM && hours == 12) hours = 0;
    return hours * 60 + minutes;
  }

  String _getAbbreviatedDayName(String fullDay) {
    switch (fullDay.toUpperCase()) {
      case 'MONDAY':
        return 'MON';
      case 'TUESDAY':
        return 'TUE';
      case 'WEDNESDAY':
        return 'WED';
      case 'THURSDAY':
        return 'THU';
      case 'FRIDAY':
        return 'FRI';
      case 'SATURDAY':
        return 'SAT';
      case 'SUNDAY':
        return 'SUN';
      default:
        return fullDay.substring(0, 3);
    }
  }

  /// Converts "09:00 AM" → "09:00" (removes seconds if present).
  String _stripSeconds(String time) {
    final parts = time.split(' ');
    final hm = parts[0].split(':').take(2).join(':');
    return '$hm ${parts[1]}';
  }

  /// Converts "09:00 AM" to a 24-hour time string "09:00:00".
  String _convertTo24Hour(String time) {
    final parts = time.split(' ');
    final bool isPM = parts[1].toLowerCase() == 'pm';
    final timeParts = parts[0].split(':');
    int hours = int.parse(timeParts[0]);
    final String minutes = timeParts[1];
    final String seconds = timeParts.length > 2 ? timeParts[2] : '00';
    if (isPM && hours != 12) hours += 12;
    if (!isPM && hours == 12) hours = 0;
    return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
  }

  /// Derive countdown state from [_mockSchedule] relative to school-zone "now".
  void _computeCountdown() {
    final schoolTz = SchoolTimezoneResolver.lastKnownTimeZone;
    final now = SchoolZoneDateTime.dateTimeFromInstantInSchool(DateTime.now().toUtc(), schoolTz);

    // Working shifts only (no break-time entries), Mon–Fri
    final workShifts = _mockSchedule
        .where(
          (s) => !s.isBreakTime && _getWeekdayIndex(s.day) >= 1 && _getWeekdayIndex(s.day) <= 5,
        )
        .toList();

    if (workShifts.isEmpty) {
      setState(() {
        _hasShifts = false;
        _statusText = 'No shifts scheduled';
        _workTime = '- -';
        _breakTime = '- -';
        _duration = Duration.zero;
      });
      return;
    }

    workShifts.sort((a, b) {
      final int wa = _getWeekdayIndex(a.day);
      final int wb = _getWeekdayIndex(b.day);
      if (wa != wb) return wa - wb;
      return _parseTimeToMinutes(a.startTime) - _parseTimeToMinutes(b.startTime);
    });

    // Try to find a shift today or later this week.
    _MockShift? nextShift;
    DateTime? nextStart;
    DateTime? nextEnd;
    bool isToday = true;

    // Check today first.
    for (final shift in workShifts) {
      if (_getWeekdayIndex(shift.day) == now.weekday) {
        final dateStr = now.toLocal().toString().split(' ')[0];
        final start = DateTime.parse('$dateStr ${_convertTo24Hour(shift.startTime)}');
        final end = DateTime.parse('$dateStr ${_convertTo24Hour(shift.endTime)}');
        if (now.isBefore(end)) {
          nextShift = shift;
          nextStart = start;
          nextEnd = end;
          isToday = true;
          break;
        }
      }
    }

    // If none today, look ahead up to 7 days.
    if (nextShift == null) {
      for (int daysAhead = 1; daysAhead <= 7; daysAhead++) {
        final checkDate = now.add(Duration(days: daysAhead));
        for (final shift in workShifts) {
          if (_getWeekdayIndex(shift.day) == checkDate.weekday) {
            final dateStr = checkDate.toLocal().toString().split(' ')[0];
            final start = DateTime.parse('$dateStr ${_convertTo24Hour(shift.startTime)}');
            final end = DateTime.parse('$dateStr ${_convertTo24Hour(shift.endTime)}');
            nextShift = shift;
            nextStart = start;
            nextEnd = end;
            isToday = false;
            break;
          }
        }
        if (nextShift != null) break;
      }
    }

    if (nextShift == null || nextStart == null || nextEnd == null) {
      setState(() {
        _hasShifts = false;
        _statusText = 'No upcoming shifts';
        _workTime = '- -';
        _breakTime = '- -';
        _duration = Duration.zero;
      });
      return;
    }

    // Find the corresponding break shift for the same day.
    final breakShift = _mockSchedule.where((s) => s.isBreakTime && s.day == nextShift!.day).firstOrNull;

    final daySuffix = isToday ? '' : ' (${_getAbbreviatedDayName(nextShift.day)})';

    setState(() {
      _hasShifts = true;
      _workTime = '${_stripSeconds(nextShift!.startTime)} - ${_stripSeconds(nextShift.endTime)}$daySuffix';
      _breakTime = breakShift != null
          ? '${_stripSeconds(breakShift.startTime)} - ${_stripSeconds(breakShift.endTime)}$daySuffix'
          : 'N/A$daySuffix';

      if (now.isBefore(nextStart!)) {
        _duration = nextStart.difference(now);
        _statusText = 'Your shift starts in';
      } else {
        _duration = nextEnd!.difference(now);
        _statusText = 'Your shift ends in';
      }
    });
  }

  // ---- timer display builders ----

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontSize: 44,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (_hasShifts)
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
    return Padding(
      padding: _hasShifts
          ? const EdgeInsets.fromLTRB(2, 0, 2, 10)
          : const EdgeInsets.fromLTRB(2, 0, 2, 5),
      child: const Text(
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
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    if (!_hasShifts) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTimeUnit('- -', 'HH'),
          _buildTimeSeparator(),
          _buildTimeUnit('- -', 'MM'),
          _buildTimeSeparator(),
          _buildTimeUnit('- -', 'SS'),
        ],
      );
    }

    final bool showDays = duration.inHours >= 24;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showDays) ...[
          _buildTimeUnit(twoDigits(duration.inDays), 'DD'),
          _buildTimeSeparator(),
        ],
        _buildTimeUnit(twoDigits(duration.inHours.remainder(24)), 'HH'),
        _buildTimeSeparator(),
        _buildTimeUnit(twoDigits(duration.inMinutes.remainder(60)), 'MM'),
        _buildTimeSeparator(),
        _buildTimeUnit(twoDigits(duration.inSeconds.remainder(60)), 'SS'),
      ],
    );
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorderColor),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.cardColor,
      ),
      child: Column(
        children: [
          // ── Header row: title + collapse toggle ───────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: DashboardCardHeader(
              title: 'My Day',
              minimized: _minimized,
              onToggle: () {
                setState(() {
                  _minimized = !_minimized;
                });
              },
            ),
          ),

          // ── Status text (shift starts/ends in) ────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _statusText,
              style: const TextStyle(
                color: AppColors.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // ── Expanded body (hidden when minimized) ──────────────────────
          if (!_minimized) ...[
            // Countdown timer
            _buildAlignedTimerDisplay(_duration),
            if (_hasShifts) const SizedBox(height: 12),

            // ── Reminder toggle button ────────────────────────────────────
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Reminder toggle — no-op in UI-only port
                },
                borderRadius: BorderRadius.circular(100),
                splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(MediaRes.notificationsGradientIcon),
                      const SizedBox(width: 8),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.buildPrimaryGradient().createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                        child: Text(
                          _mockIsReminder ? 'Turn off reminder' : 'Send reminder',
                          style: const TextStyle(
                            color: AppColors.cardColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Work time chip ────────────────────────────────────────────
            _CustomChip(
              label: 'Work Time : $_workTime',
              labelStyle: const TextStyle(color: AppColors.secondaryColor),
              color: const Color.fromRGBO(177, 175, 233, 0.3),
            ),
            const SizedBox(height: 8),

            // ── Break time chip ───────────────────────────────────────────
            _CustomChip(
              label: 'Break Time : $_breakTime',
              labelStyle: const TextStyle(color: AppColors.secondaryColor),
              color: const Color.fromRGBO(177, 175, 233, 0.3),
            ),
            const SizedBox(height: 8),

            // ── Sign-in pin + QR scanner row ──────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.buildPrimaryGradient().createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                  ),
                  child: Text(
                    'Your Sign-In Pin: ${_mockClockInPin.trim().isNotEmpty ? _mockClockInPin : 'N/A'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 17 * (-3 / 100),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () {
                    // QR scan navigation — no-op in UI-only port
                  },
                  icon: SvgPicture.asset(MediaRes.scannerGradientIcon),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── GPS-gated attendance action button ────────────────────────
            BlocBuilder<GeofenceCubit, GeofenceState>(
              builder: (context, geofenceState) {
                final bool enabled = geofenceState.isWithinGeofence &&
                    geofenceState.isLocationEnabled;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: CustomButtonLayout(
                        isForm: false,
                        showCancelButton: false,
                        confirmButtonLabel: _mockIsSignedIn ? 'Sign-Out' : 'Sign-In',
                        onPressedConfirm: enabled
                            ? () {
                                if (_mockIsSignedIn) {
                                  context.go('/dashboard/student-selection-sign-out-form');
                                } else {
                                  context.go('/dashboard/student-selection-sign-in-form');
                                }
                              }
                            : null,
                      ),
                    ),
                    if (geofenceState.status == GeofenceCubitStatus.permissionDenied)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, left: 24, right: 24),
                        child: GestureDetector(
                          onTap: () => context.read<GeofenceCubit>().retryPermission(),
                          child: Text(
                            'Location permission required. Tap to enable.',
                            style: TextStyle(
                              color: AppColors.primaryColor.withValues(alpha: 0.65),
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else if (geofenceState.status == GeofenceCubitStatus.locationDisabled)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, left: 24, right: 24),
                        child: Text(
                          'Location services are disabled.',
                          style: TextStyle(
                            color: AppColors.primaryColor.withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else if (geofenceState.status == GeofenceCubitStatus.outsideRange)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, left: 24, right: 24),
                        child: Text(
                          'You are not within the school sign-in zone.',
                          style: TextStyle(
                            color: AppColors.primaryColor.withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else if (geofenceState.status == GeofenceCubitStatus.checkingPermission ||
                        geofenceState.status == GeofenceCubitStatus.fetchingSchoolLocation)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, left: 24, right: 24),
                        child: Text(
                          'Checking location...',
                          style: TextStyle(
                            color: AppColors.primaryColor.withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],

          const SizedBox(height: 10),

          // ── Latest chat preview ───────────────────────────────────────
          const _CommunicationRowWidget(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CommunicationRowWidget – shows the most-recent staff chat preview.
// ---------------------------------------------------------------------------

/// Stateless communication row: displays the last chat contact's avatar,
/// name, most recent message, and a chat-action button.
///
/// Uses [_MockChat] hardcoded data; no Firestore / bloc wiring.
class _CommunicationRowWidget extends StatelessWidget {
  const _CommunicationRowWidget();

  @override
  Widget build(BuildContext context) {
    const chat = _mockChat;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        color: Color.fromRGBO(44, 99, 226, 0.05),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with online / absent status dot.
          Stack(
            children: [
              // Shared profile widget; UI-only, so profile/attendance API
              // lookups are disabled — it renders initials from [name].
              DocumentImageWidget(
                fileUuid: '',
                name: chat.senderName,
                size: 50,
                fontSize: 20,
                disableProfileLookupFallback: true,
                disableAttendanceStatusLookup: true,
              ),
              // Status indicator dot
              if (chat.isSignedIn || chat.isAbsent || chat.profileStatus == 'Upcoming')
                Positioned(
                  left: 35,
                  bottom: 35,
                  child: Container(
                    decoration: BoxDecoration(
                      color: chat.profileStatus == 'Upcoming'
                          ? const Color.fromARGB(255, 253, 205, 22)
                          : chat.isSignedIn
                              ? const Color.fromRGBO(0, 177, 21, 1)
                              : chat.isAbsent
                                  ? const Color.fromRGBO(200, 32, 32, 1)
                                  : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Sender name + last message preview.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.senderName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  chat.lastMessage,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Chat action button (replaces CustomFloatingActionButton).
          _ChatActionButton(
            onPressed: () {
              // Conversation screen navigation removed — no-op in UI-only port
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helper widgets (inline replacements for CustomChip,
// CustomCancelButton, CustomConfirmButton, CustomFloatingActionButton).
// ---------------------------------------------------------------------------

/// Inline replacement for `CustomChip` — a pill-shaped labelled container.
class _CustomChip extends StatelessWidget {
  const _CustomChip({
    required this.label,
    required this.color,
    this.labelStyle,
  });

  final String label;
  final Color color;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: labelStyle,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Inline replacement for `CustomFloatingActionButton` — a small gradient-
/// bordered circular icon button used in the communication row.
class _ChatActionButton extends StatelessWidget {
  const _ChatActionButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: AppColors.buildPrimaryGradient(),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          MediaRes.communicationIcon,
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }
}
