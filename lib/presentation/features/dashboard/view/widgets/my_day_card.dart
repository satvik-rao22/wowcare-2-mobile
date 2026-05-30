import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/domain/features/staff/entities/school_regular_schedule_day.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/qr_scan_button.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

// ---------------------------------------------------------------------------
// Local mock model – kept only for the chat preview row (not yet API-backed).
// ---------------------------------------------------------------------------

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

const _MockChat _mockChat = _MockChat(
  senderName: 'Michael Torres',
  lastMessage: 'Can you cover the morning session tomorrow?',
  isSignedIn: true,
  isAbsent: false,
  profileStatus: 'Active',
);

// TODO: replace with real sign-in state from attendance cubit.
const bool _mockIsSignedIn = false;
const bool _mockIsReminder = true;
const String _mockClockInPin = '4821';

// ---------------------------------------------------------------------------
// MyDayCard
// ---------------------------------------------------------------------------

/// Dashboard card displaying the school's schedule for today, a shift
/// countdown, sign-in pin, attendance action buttons, and the latest chat
/// preview.
///
/// Schedule data comes from [MyDayCubit]; all other fields are still mocked
/// pending their respective API integrations.
class MyDayCard extends StatefulWidget {
  const MyDayCard({super.key});

  @override
  State<MyDayCard> createState() => _MyDayCardState();
}

class _MyDayCardState extends State<MyDayCard> {
  // ---- collapse state ----
  bool _minimized = false;

  // ---- shift countdown display state ----
  String _statusText = 'Loading schedule…';
  String _workTime = '- -';
  String _breakTime = '- -';
  bool _hasShifts = false;
  Duration _duration = Duration.zero;

  // ---------------------------------------------------------------------------
  // Helpers – time conversion (24h API format → 12h display / DateTime)
  // ---------------------------------------------------------------------------

  /// Pads a 24h time string to `HH:mm:ss` for `DateTime.parse`.
  static String _normalize24h(String raw) {
    final parts = raw.trim().split(':');
    if (parts.length < 2) return '00:00:00';
    final h = parts[0].padLeft(2, '0');
    final m = parts[1].padLeft(2, '0');
    final s = parts.length > 2 ? parts[2].split('.').first.padLeft(2, '0') : '00';
    return '$h:$m:$s';
  }

  /// Converts a 24h time string (`HH:mm` or `HH:mm:ss`) to `hh:mm AM/PM`.
  static String _formatDisplay(String raw) {
    final norm = _normalize24h(raw);
    final timeParts = norm.split(':');
    int h = int.parse(timeParts[0]);
    final int m = int.parse(timeParts[1]);
    final bool isPm = h >= 12;
    final String period = isPm ? 'PM' : 'AM';
    if (h == 0) h = 12;
    else if (h > 12) h -= 12;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
  }

  /// Formats the `halfDay` field. If it looks like a time, convert it;
  /// otherwise return it as-is.
  static String _formatHalfDay(String? halfDay) {
    if (halfDay == null || halfDay.isEmpty) return 'N/A';
    // Looks like a time if it contains ':'
    if (halfDay.contains(':')) return _formatDisplay(halfDay);
    return halfDay;
  }

  // ---------------------------------------------------------------------------
  // Countdown computation
  // ---------------------------------------------------------------------------

  /// Derives countdown display state from a [SchoolRegularScheduleDay].
  ///
  /// Called by [BlocConsumer]'s listener whenever the schedule is loaded so the
  /// countdown reflects the real school hours without requiring a rebuild chain.
  void _computeCountdownFromSchedule(SchoolRegularScheduleDay? schedule) {
    if (schedule == null) {
      setState(() {
        _hasShifts = false;
        _statusText = 'School Closed';
        _workTime = '- -';
        _breakTime = '- -';
        _duration = Duration.zero;
      });
      return;
    }

    final schoolTz = SchoolTimezoneResolver.lastKnownTimeZone;
    final now = SchoolZoneDateTime.dateTimeFromInstantInSchool(
      DateTime.now().toUtc(),
      schoolTz,
    );

    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final start24 = _normalize24h(schedule.startTime);
    final end24 = _normalize24h(schedule.endTime);

    final startDt = DateTime.tryParse('$dateStr $start24');
    final endDt = DateTime.tryParse('$dateStr $end24');

    if (startDt == null || endDt == null) {
      setState(() {
        _hasShifts = false;
        _statusText = 'Schedule unavailable';
        _workTime = '- -';
        _breakTime = '- -';
        _duration = Duration.zero;
      });
      return;
    }

    final displayStart = _formatDisplay(schedule.startTime);
    final displayEnd = _formatDisplay(schedule.endTime);
    final displayHalfDay = _formatHalfDay(schedule.halfDay);

    setState(() {
      _hasShifts = true;
      _workTime = '$displayStart – $displayEnd';
      _breakTime = displayHalfDay;

      if (now.isBefore(startDt)) {
        _duration = startDt.difference(now);
        _statusText = 'School starts in';
      } else if (now.isBefore(endDt)) {
        _duration = endDt.difference(now);
        _statusText = 'School ends in';
      } else {
        // School day ended — show the schedule but zero out the timer.
        _hasShifts = false;
        _statusText = 'School day ended';
        _duration = Duration.zero;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Timer display builders (unchanged from original)
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MyDayCubit, MyDayState>(
      // Re-compute countdown whenever the schedule data changes.
      listenWhen: (prev, curr) =>
          curr.isLoaded && prev.todaySchedule != curr.todaySchedule ||
          curr.isLoaded && prev.schoolClosed != curr.schoolClosed,
      listener: (context, state) {
        _computeCountdownFromSchedule(state.todaySchedule);
      },
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorderColor),
            borderRadius: BorderRadius.circular(12),
            color: AppColors.cardColor,
          ),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: DashboardCardHeader(
                  title: 'My Day',
                  minimized: _minimized,
                  onToggle: () => setState(() => _minimized = !_minimized),
                ),
              ),

              // ── Status text ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: state.isLoading
                    ? _ShimmerLine(width: 180, height: 18)
                    : Text(
                        _statusText,
                        style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),

              // ── Expanded body ────────────────────────────────────────────
              if (!_minimized) ...[
                // Countdown timer / shimmer
                if (state.isLoading)
                  _buildShimmerBody()
                else ...[
                  _buildAlignedTimerDisplay(_duration),
                  if (_hasShifts) const SizedBox(height: 12),

                  // ── Reminder toggle ──────────────────────────────────────
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(100),
                      splashColor:
                          AppColors.primaryColor.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                                MediaRes.notificationsGradientIcon),
                            const SizedBox(width: 8),
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppColors.buildPrimaryGradient()
                                      .createShader(
                                Rect.fromLTWH(
                                    0, 0, bounds.width, bounds.height),
                              ),
                              child: Text(
                                _mockIsReminder
                                    ? 'Turn off reminder'
                                    : 'Send reminder',
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

                  // ── Work time chip ───────────────────────────────────────
                  _CustomChip(
                    label: 'Work Time : $_workTime',
                    labelStyle:
                        const TextStyle(color: AppColors.secondaryColor),
                    color: const Color.fromRGBO(177, 175, 233, 0.3),
                  ),
                  const SizedBox(height: 8),

                  // ── Half-day / break time chip ───────────────────────────
                  _CustomChip(
                    label: 'Half Day : $_breakTime',
                    labelStyle:
                        const TextStyle(color: AppColors.secondaryColor),
                    color: const Color.fromRGBO(177, 175, 233, 0.3),
                  ),
                  const SizedBox(height: 8),

                  // ── Sign-in pin + QR scanner ─────────────────────────────
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
                      const QrScanButton(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── GPS-gated attendance button ──────────────────────────
                  BlocBuilder<GeofenceCubit, GeofenceState>(
                    builder: (context, geofenceState) {
                      final bool enabled = geofenceState.isWithinGeofence &&
                          geofenceState.isLocationEnabled;
                      return Column(
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: CustomButtonLayout(
                              isForm: false,
                              showCancelButton: false,
                              confirmButtonLabel:
                                  _mockIsSignedIn ? 'Sign-Out' : 'Sign-In',
                              onPressedConfirm: enabled
                                  ? () {
                                      if (_mockIsSignedIn) {
                                        context.go(
                                            '/dashboard/student-selection-sign-out-form');
                                      } else {
                                        context.go(
                                            '/dashboard/student-selection-sign-in-form');
                                      }
                                    }
                                  : null,
                            ),
                          ),
                          if (geofenceState.status ==
                              GeofenceCubitStatus.permissionDenied)
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 12, left: 24, right: 24),
                              child: GestureDetector(
                                onTap: () => context
                                    .read<GeofenceCubit>()
                                    .retryPermission(),
                                child: Text(
                                  'Location permission required. Tap to enable.',
                                  style: TextStyle(
                                    color: AppColors.primaryColor
                                        .withValues(alpha: 0.65),
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          else if (geofenceState.status ==
                              GeofenceCubitStatus.locationDisabled)
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 12, left: 24, right: 24),
                              child: Text(
                                'Location services are disabled.',
                                style: TextStyle(
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.65),
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else if (geofenceState.status ==
                              GeofenceCubitStatus.outsideRange)
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 12, left: 24, right: 24),
                              child: Text(
                                'You are not within the school sign-in zone.',
                                style: TextStyle(
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.65),
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else if (geofenceState.status ==
                                  GeofenceCubitStatus.checkingPermission ||
                              geofenceState.status ==
                                  GeofenceCubitStatus.fetchingSchoolLocation)
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 12, left: 24, right: 24),
                              child: Text(
                                'Checking location...',
                                style: TextStyle(
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.65),
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
              ],

              const SizedBox(height: 10),

              // ── Latest chat preview ──────────────────────────────────────
              const _CommunicationRowWidget(),
            ],
          ),
        );
      },
    );
  }

  // ── Shimmer body ────────────────────────────────────────────────────────────

  Widget _buildShimmerBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            // Timer placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => i.isOdd
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          width: 10,
                          height: 48,
                          color: Colors.white,
                        ),
                      )
                    : Container(
                        width: 44,
                        height: 56,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            // Work time chip placeholder
            Container(
              height: 36,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 8),
            // Half-day chip placeholder
            Container(
              height: 36,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 8),
            // Pin row placeholder
            Container(
              height: 20,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ShimmerLine helper
// ---------------------------------------------------------------------------

class _ShimmerLine extends StatelessWidget {
  const _ShimmerLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CommunicationRowWidget
// ---------------------------------------------------------------------------

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
          Stack(
            children: [
              DocumentImageWidget(
                fileUuid: '',
                name: chat.senderName,
                size: 50,
                fontSize: 20,
                disableProfileLookupFallback: true,
                disableAttendanceStatusLookup: true,
              ),
              if (chat.isSignedIn ||
                  chat.isAbsent ||
                  chat.profileStatus == 'Upcoming')
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
                    constraints:
                        const BoxConstraints(minWidth: 15, minHeight: 15),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
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
          _ChatActionButton(onPressed: () {}),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

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
          colorFilter:
              const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }
}
