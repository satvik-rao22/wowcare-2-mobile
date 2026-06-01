import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/domain/features/staff/entities/school_regular_schedule_day.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/qr_scan_button.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';
import 'package:wowcare/presentation/features/geofencing/widgets/geofence_sign_in_sheet.dart';
import 'package:wowcare/shared/services/geofence_notification_service.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_usecase.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_mark_absent_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_entity.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import '../../../../../core/util/core_utils.dart';


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

  String _clockInPin = '';

  // Guards the geofence popup: shown at most once per app session per entry
  // transition. Resets to false when the user exits the geofence, ensuring
  // the popup appears again on the next entry (e.g. after sign-out).
  bool _geofencePopupShownThisEntry = false;

  // ---- sign-in status ----
  bool _isSignedIn = false;

  // ---- shift countdown display state ----
  String _statusText = 'Loading schedule…';
  String _workTime = '- -';
  String _breakTime = '- -';
  bool _hasShifts = false;
  Duration _duration = Duration.zero;

  // Ticks every second to keep the countdown live.
  Timer? _ticker;

  // ---------------------------------------------------------------------------
  // Helpers – time conversion (24h API format → 12h display / DateTime)
  // ---------------------------------------------------------------------------

  /// Pads a 24h time string to `HH:mm:ss` for `DateTime.parse`.
  static String _normalize24h(String raw) {
    final parts = raw.trim().split(':');
    if (parts.length < 2) return '00:00:00';
    final h = parts[0].padLeft(2, '0');
    final m = parts[1].padLeft(2, '0');
    final s = parts.length > 2
        ? parts[2].split('.').first.padLeft(2, '0')
        : '00';
    return '$h:$m:$s';
  }

  /// Formats a [StaffProfileTime] as `h:mm AM/PM` (space before period).
  static String _formatStaffTime(StaffProfileTime t) {
    final period = t.hour >= 12 ? 'PM' : 'AM';
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadClockPin());
    unawaited(_loadSignInStatus());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Seed display fields from whatever state the cubit already holds.
    // This covers the scroll-back case: the widget rebuilds but the cubit
    // never emits a new event, so the BlocConsumer listener never fires.
    final cubitState = context.read<MyDayCubit>().state;
    if (cubitState.isLoaded) {
      _computeCountdownFromSchedule(
        cubitState.todaySchedule,
        staffSchedule: cubitState.todayWorkSchedule,
        breakSchedule: cubitState.todayBreakSchedule,
      );
      _startTicker();
    }

    // Initialize GPS geofencing for the current school
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_initializeGeofencing());
    });
  }

  Future<void> _initializeGeofencing() async {
    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode =
          (await storage.getString(StorageKeys.schoolCode))?.trim() ?? '';
      if (schoolCode.isEmpty || !mounted) return;

      // Initialize GPS geofencing with the school code
      await context.read<GeofenceCubit>().initForSchool(schoolCode: schoolCode);
    } catch (_) {
      // Silently fail - GPS is optional
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // Starts (or restarts) a 1-second ticker that re-derives the countdown
  // every second so the display stays live without rebuilding the cubit.
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final cubitState = context.read<MyDayCubit>().state;
      if (cubitState.isLoaded) {
        _computeCountdownFromSchedule(
          cubitState.todaySchedule,
          staffSchedule: cubitState.todayWorkSchedule,
          breakSchedule: cubitState.todayBreakSchedule,
        );
      }
    });
  }

  Future<void> _loadClockPin() async {
    final storage = serviceLocator<StorageService>();
    final pin = (await storage.getString(StorageKeys.staffPin) ?? '').trim();
    if (!mounted) return;
    setState(() => _clockInPin = pin);
  }

  Future<void> _loadSignInStatus() async {
    final storage = serviceLocator<StorageService>();
    final staffCode =
        (await storage.getString(StorageKeys.staffCode))?.trim() ?? '';
    if (staffCode.isEmpty || !mounted) return;
    try {
      final useCase = serviceLocator<GetStaffTodaySignInStatusUseCase>();
      final status = await useCase(staffCode: staffCode);
      if (!mounted) return;
      setState(() => _isSignedIn = status?.toUpperCase() == 'SIGNED_IN');
    } catch (_) {
      // If status check fails, keep default (false)
    }
  }

  Future<void> _openMarkAbsentForSelf() async {
    final storage = serviceLocator<StorageService>();
    final staffCode = (await storage.getString(StorageKeys.staffCode) ?? '')
        .trim();
    if (staffCode.isEmpty) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Unable to find your staff profile to mark absent.',
        isWarning: true,
      );
      return;
    }

    final displayName = (await storage.getString(StorageKeys.displayName) ?? '')
        .trim();
    final designation =
        (await storage.getString(StorageKeys.staffDesignation) ?? '').trim();

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StaffMarkAbsentForm(
          staff: StaffEntity(
            id: 0,
            name: displayName.isNotEmpty ? displayName : '—',
            primaryRoomId: 0,
            designation: designation.isNotEmpty ? designation : 'Staff',
            staffCode: staffCode,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Countdown computation
  // ---------------------------------------------------------------------------

  /// Derives countdown display state from the staff's personal schedule or,
  /// if unavailable, from the school's regular schedule.
  ///
  /// [staffSchedule] is preferred when present — it contains the staff
  /// member's own day-specific start/end times from their profile.
  /// Uses device local time so the countdown matches the user's clock.
  void _computeCountdownFromSchedule(
    SchoolRegularScheduleDay? schedule, {
    StaffProfileWorkSchedule? staffSchedule,
    StaffProfileBreakSchedule? breakSchedule,
  }) {
    final now = DateTime.now();

    // Shared 3-letter day abbreviation — from profile when available, otherwise
    // from the device clock so the format is always "h:mm AM/PM - h:mm AM/PM (DAY)".
    const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final dayAbbr = staffSchedule != null
        ? (staffSchedule.dayOfWeek.length >= 3
              ? staffSchedule.dayOfWeek.substring(0, 3).toUpperCase()
              : staffSchedule.dayOfWeek.toUpperCase())
        : _weekdays[now.weekday - 1];

    DateTime? startDt;
    DateTime? endDt;
    String displayStart;
    String displayEnd;
    String displayBreak;

    if (staffSchedule != null) {
      startDt = DateTime(
        now.year,
        now.month,
        now.day,
        staffSchedule.workStartTime.hour,
        staffSchedule.workStartTime.minute,
        staffSchedule.workStartTime.second,
      );
      endDt = DateTime(
        now.year,
        now.month,
        now.day,
        staffSchedule.workEndTime.hour,
        staffSchedule.workEndTime.minute,
        staffSchedule.workEndTime.second,
      );
      displayStart = _formatStaffTime(staffSchedule.workStartTime);
      displayEnd = _formatStaffTime(staffSchedule.workEndTime);
      displayBreak = breakSchedule != null
          ? '${_formatStaffTime(breakSchedule.breakStartTime)} - ${_formatStaffTime(breakSchedule.breakEndTime)} ($dayAbbr)'
          : 'N/A';
    } else if (schedule != null) {
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final start24 = _normalize24h(schedule.startTime);
      final end24 = _normalize24h(schedule.endTime);
      startDt = DateTime.tryParse('$dateStr $start24');
      endDt = DateTime.tryParse('$dateStr $end24');

      // Parse hours/minutes from the normalised string so we can apply the
      // same h:mm AM/PM format (no leading zero) as the staff schedule branch.
      final sParts = start24.split(':');
      final eParts = end24.split(':');
      displayStart = _fmtHM(
        int.tryParse(sParts[0]) ?? 0,
        int.tryParse(sParts[1]) ?? 0,
      );
      displayEnd = _fmtHM(
        int.tryParse(eParts[0]) ?? 0,
        int.tryParse(eParts[1]) ?? 0,
      );

      // Half-day field: format as time if it looks like one.
      final hd = schedule.halfDay;
      if (hd != null && hd.contains(':')) {
        final hd24 = _normalize24h(hd);
        final hdParts = hd24.split(':');
        displayBreak = _fmtHM(
          int.tryParse(hdParts[0]) ?? 0,
          int.tryParse(hdParts[1]) ?? 0,
        );
      } else {
        displayBreak = (hd == null || hd.isEmpty) ? 'N/A' : hd;
      }
    } else {
      setState(() {
        _hasShifts = false;
        _statusText = 'School Closed';
        _workTime = '- -';
        _breakTime = '- -';
        _duration = Duration.zero;
      });
      return;
    }

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

    setState(() {
      _hasShifts = true;
      _workTime = '$displayStart - $displayEnd ($dayAbbr)';
      _breakTime = displayBreak;

      if (now.isBefore(startDt!)) {
        _duration = startDt.difference(now);
        _statusText = 'Your shift starts in';
      } else if (now.isBefore(endDt!)) {
        _duration = endDt.difference(now);
        _statusText = 'Your shift ends in';
      } else {
        _hasShifts = false;
        _statusText = 'School day ended';
        _duration = Duration.zero;
      }
    });
  }

  /// Formats hour + minute as `h:mm AM/PM` (no leading zero on hour,
  /// space before period) — shared by both schedule branches.
  static String _fmtHM(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$h:${minute.toString().padLeft(2, '0')} $period';
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
    return BlocListener<GeofenceCubit, GeofenceState>(
      listenWhen: (prev, curr) {
        // Reset popup guard whenever the user exits the geofence so it shows
        // again on the next entry (e.g. after signing out and re-entering).
        if (prev.status == GeofenceCubitStatus.withinRange &&
            curr.status == GeofenceCubitStatus.outsideRange) {
          _geofencePopupShownThisEntry = false;
        }
        // Fire only on the first transition INTO withinRange per entry.
        return prev.status != GeofenceCubitStatus.withinRange &&
            curr.status == GeofenceCubitStatus.withinRange;
      },
      listener: (context, _) {
        if (_geofencePopupShownThisEntry) return;
        _geofencePopupShownThisEntry = true;
        // Show push notification when entering geofence
        unawaited(
          GeofenceNotificationService().showEnteredZoneNotification(),
        );
        unawaited(
          GeofenceSignInSheet.show(
            context,
            role: 'staff',
            isSignedIn: _isSignedIn,
          ),
        );
      },
      child: BlocConsumer<MyDayCubit, MyDayState>(
        // Re-compute countdown whenever the schedule data changes.
        listenWhen: (prev, curr) =>
            curr.isLoaded &&
            (prev.todaySchedule != curr.todaySchedule ||
                prev.todayWorkSchedule != curr.todayWorkSchedule ||
                prev.schoolClosed != curr.schoolClosed),
        listener: (context, state) {
          _computeCountdownFromSchedule(
            state.todaySchedule,
            staffSchedule: state.todayWorkSchedule,
            breakSchedule: state.todayBreakSchedule,
          );
          _startTicker();
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
                        splashColor: AppColors.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                MediaRes.notificationsGradientIcon,
                              ),
                              const SizedBox(width: 8),
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    AppColors.buildPrimaryGradient()
                                        .createShader(
                                          Rect.fromLTWH(
                                            0,
                                            0,
                                            bounds.width,
                                            bounds.height,
                                          ),
                                        ),
                                child: Text(
                                  'Send reminder',
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
                      labelStyle: const TextStyle(
                        color: AppColors.secondaryColor,
                      ),
                      color: const Color.fromRGBO(177, 175, 233, 0.3),
                    ),
                    const SizedBox(height: 8),

                    // ── Break time chip ──────────────────────────────────────
                    _CustomChip(
                      label: 'Break Time : $_breakTime',
                      labelStyle: const TextStyle(
                        color: AppColors.secondaryColor,
                      ),
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
                                Rect.fromLTWH(
                                  0,
                                  0,
                                  bounds.width,
                                  bounds.height,
                                ),
                              ),
                          child: Text(
                            'Your Sign-In Pin: ${_clockInPin.trim().isNotEmpty ? _clockInPin : 'N/A'}',
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
                        final bool enabled =
                            geofenceState.status ==
                            GeofenceCubitStatus.withinRange;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isSignedIn
                                          ? null
                                          : _openMarkAbsentForSelf,

                                      label: const Text(
                                        'Mark Absent',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.themeColor,
                                        side: const BorderSide(
                                          color: AppColors.themeColor,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CustomButtonLayout(
                                      isForm: false,
                                      showCancelButton: false,
                                      confirmButtonLabel: _isSignedIn
                                          ? 'Sign-Out'
                                          : 'Sign-In',
                                      confirmButtonChild: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 18,
                                            color: AppColors
                                                .billingBackgroundColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              _isSignedIn
                                                  ? 'Sign-Out'
                                                  : 'Sign-In',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors
                                                    .billingBackgroundColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      onPressedConfirm: enabled
                                          ? () {
                                              if (_isSignedIn) {
                                                context.go(
                                                  '/dashboard/staff-sign-out-form',
                                                );
                                              } else {
                                                context.go(
                                                  '/dashboard/staff-sign-in-form',
                                                );
                                              }
                                            }
                                          : null,
                                      disabledConfirmTooltip:
                                          'You are not within  geofencing Range',
                                      onDisabledConfirmTap: () {
                                        CoreUtils.showTopSnackBar(
                                          isWarning: true,
                                          message:
                                              'You are not within geofencing Range',
                                          context: context,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildGeofenceStatusLabel(context, geofenceState),
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
      ), // BlocConsumer<MyDayCubit>
    ); // BlocListener<GeofenceCubit>
  }

  // ── Geofence status label ────────────────────────────────────────────────────

  Widget _buildGeofenceStatusLabel(BuildContext context, GeofenceState state) {
    const style = TextStyle(fontSize: 12, height: 1.4);
    const pad = EdgeInsets.only(top: 10, left: 24, right: 24);

    switch (state.status) {
      case GeofenceCubitStatus.withinRange:
        return Padding(
          padding: pad,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Inside School Radius — GPS attendance enabled',
                style: style.copyWith(
                  color: const Color(0xFF16A34A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      case GeofenceCubitStatus.outsideRange:
        return Padding(
          padding: pad,
          child: Text(
            'Outside School Radius — move closer to sign in',
            style: style.copyWith(
              color: AppColors.primaryColor.withValues(alpha: 0.65),
            ),
            textAlign: TextAlign.center,
          ),
        );
      case GeofenceCubitStatus.gpsDisabledByAdmin:
        return Padding(
          padding: pad,
          child: Text(
            'GPS sign-in is currently disabled by your school admin.',
            style: style.copyWith(
              color: AppColors.primaryColor.withValues(alpha: 0.65),
            ),
            textAlign: TextAlign.center,
          ),
        );
      case GeofenceCubitStatus.permissionDenied:
        return Padding(
          padding: pad,
          child: GestureDetector(
            onTap: () => context.read<GeofenceCubit>().retryPermission(),
            child: Text(
              'Location permission required. Tap to enable.',
              style: style.copyWith(
                color: AppColors.primaryColor.withValues(alpha: 0.65),
                decoration: TextDecoration.underline,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      case GeofenceCubitStatus.locationDisabled:
        return Padding(
          padding: pad,
          child: Text(
            'Location services are disabled. Please enable GPS.',
            style: style.copyWith(
              color: AppColors.primaryColor.withValues(alpha: 0.65),
            ),
            textAlign: TextAlign.center,
          ),
        );
      case GeofenceCubitStatus.checkingPermission:
      case GeofenceCubitStatus.fetchingSchoolLocation:
      case GeofenceCubitStatus.checking:
        return Padding(
          padding: pad,
          child: Text(
            'Checking your location...',
            style: style.copyWith(
              color: AppColors.primaryColor.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
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
// Shows the logged-in user's name (from StorageService) with a "Chat Not Found"
// placeholder until the real messaging API is integrated.
// ---------------------------------------------------------------------------

class _CommunicationRowWidget extends StatefulWidget {
  const _CommunicationRowWidget();

  @override
  State<_CommunicationRowWidget> createState() =>
      _CommunicationRowWidgetState();
}

class _CommunicationRowWidgetState extends State<_CommunicationRowWidget> {
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    unawaited(_loadDisplayName());
  }

  Future<void> _loadDisplayName() async {
    final storage = serviceLocator<StorageService>();
    final name = (await storage.getString(StorageKeys.displayName) ?? '')
        .trim();
    if (!mounted) return;
    setState(() => _displayName = name);
  }

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
          DocumentImageWidget(
            fileUuid: '',
            name: _displayName,
            size: 50,
            fontSize: 20,
            disableProfileLookupFallback: true,
            disableAttendanceStatusLookup: true,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName.isNotEmpty ? _displayName : '—',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Chat Not Found',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryColor.withValues(alpha: 0.5),
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
      child: Text(label, style: labelStyle, overflow: TextOverflow.ellipsis),
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
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }
}
