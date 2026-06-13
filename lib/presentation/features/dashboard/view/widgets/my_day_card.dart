import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_usecase.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_transfer_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_mark_absent_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_entity.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import '../../../../../core/util/core_utils.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';

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

  // Prevents didChangeDependencies from stacking multiple geofence-init
  // callbacks when ancestor InheritedWidgets rebuild.
  bool _geofenceInitScheduled = false;

  // ---- sign-in status ----
  bool _isSignedIn = false;

  // Cached staff identity — loaded once in initState so button taps never hit
  // a timing window where storage hasn't resolved yet.
  String _staffCode = '';
  String _staffDisplayName = '';
  String _staffDesignation = '';
  bool _staffIdentityLoaded = false;
  String _nextDayName = ''; // For upcoming shifts
  bool _isTodayShift = true; // Important flag
  // ---- shift countdown display state ----
  String _statusText = 'Loading schedule…';
  String _workTime = '--:--';
  String _breakTime = '--:--';
  bool _hasShifts = false;
  Duration _duration = Duration.zero;

  // Ticks every second to keep the countdown live.
  Timer? _ticker;

  // ---------------------------------------------------------------------------
  // Helpers – time conversion (24h API format → 12h display / DateTime)
  // ---------------------------------------------------------------------------

  /// Robust day-of-week → Dart weekday mapping.
  /// Supports both full names (MONDAY) and 3-letter abbreviations (MON).
  static const _kDayToWeekday = <String, int>{
    'MONDAY': 1,
    'MON': 1,
    'TUESDAY': 2,
    'TUE': 2,
    'WEDNESDAY': 3,
    'WED': 3,
    'THURSDAY': 4,
    'THU': 4,
    'FRIDAY': 5,
    'FRI': 5,
    'SATURDAY': 6,
    'SAT': 6,
    'SUNDAY': 7,
    'SUN': 7,
  };

  /// Returns the 3-letter uppercase abbreviation for any day-of-week string.
  static String _dayAbbr(String dayOfWeek) {
    final upper = dayOfWeek.trim().toUpperCase();
    return upper.length >= 3 ? upper.substring(0, 3) : upper;
  }

  /// Returns the full display name for a Dart weekday integer (1 = Monday … 7 = Sunday).
  /// e.g. _getDayName(3) → "Wednesday"
  static String _getDayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    if (weekday < 1 || weekday > 7) return '';
    return names[weekday - 1];
  }

  /// Finds the work schedule for [weekday] from [all].
  /// Returns null when not found or when times are unset (all zeros).
  /// IMPORTANT: Rejects schedules where either start OR end time is all-zero.
  static StaffProfileWorkSchedule? _resolveWorkScheduleForDay(
    int weekday,
    List<StaffProfileWorkSchedule> all,
  ) {
    for (final ws in all) {
      if (_kDayToWeekday[ws.dayOfWeek.trim().toUpperCase()] != weekday)
        continue;

      // Reject if EITHER start OR end time is completely unset (0:00)
      final startTimeSet =
          ws.workStartTime.hour != 0 || ws.workStartTime.minute != 0;
      final endTimeSet = ws.workEndTime.hour != 0 || ws.workEndTime.minute != 0;

      if (!startTimeSet || !endTimeSet) {
        debugPrint(
          '[MyDayCard._resolveWorkScheduleForDay] Skipping ${ws.dayOfWeek}: '
          'start=${ws.workStartTime.hour}:${ws.workStartTime.minute}, '
          'end=${ws.workEndTime.hour}:${ws.workEndTime.minute} (unset)',
        );
        continue;
      }

      return ws;
    }
    return null;
  }

  /// Finds the break schedule for [weekday] from [all].
  static StaffProfileBreakSchedule? _resolveBreakScheduleForDay(
    int weekday,
    List<StaffProfileBreakSchedule> all,
  ) {
    for (final bs in all) {
      if (_kDayToWeekday[bs.dayOfWeek.trim().toUpperCase()] == weekday)
        return bs;
    }
    return null;
  }

  /// Returns `true` when [bs] has at least one non-zero time component.
  static bool _breakIsSet(StaffProfileBreakSchedule? bs) {
    if (bs == null) return false;
    return bs.breakStartTime.hour != 0 ||
        bs.breakStartTime.minute != 0 ||
        bs.breakEndTime.hour != 0 ||
        bs.breakEndTime.minute != 0;
  }

  /// Builds the break-time display string with day and time.
  static String _formatBreakDisplay(StaffProfileBreakSchedule? bs) {
    if (!_breakIsSet(bs)) return '--:--';
    final dayLabel = _formatDayOfWeek(bs!.dayOfWeek);
    return '$dayLabel: ${_formatStaffTime(bs.breakStartTime)} - '
        '${_formatStaffTime(bs.breakEndTime)}';
  }

  /// Formats day of week string (e.g., "MONDAY" → "Mon").
  static String _formatDayOfWeek(String dayOfWeek) {
    final day = dayOfWeek.trim().toUpperCase();
    return switch (day) {
      'MONDAY' => 'Mon',
      'TUESDAY' => 'Tue',
      'WEDNESDAY' => 'Wed',
      'THURSDAY' => 'Thu',
      'FRIDAY' => 'Fri',
      'SATURDAY' => 'Sat',
      'SUNDAY' => 'Sun',
      _ => day.substring(0, 3),
    };
  }

  /// Pads a 24h time string to `HH:mm:ss` for `DateTime.parse`.
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
    unawaited(_loadStaffIdentity());
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
        schoolTimeZone: cubitState.schoolTimeZone,
        allWorkSchedules: cubitState.allWorkSchedules,
        allBreakSchedules: cubitState.allBreakSchedules,
      );
      _startTicker();
    } else if (cubitState.isInitial) {
      // First open: load data immediately to avoid default display states
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(context.read<MyDayCubit>().load());
      });
    }

    // Initialize GPS geofencing for the current school.
    // Guard ensures exactly one callback is queued even when
    // didChangeDependencies fires multiple times per frame.
    if (!_geofenceInitScheduled) {
      _geofenceInitScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_initializeGeofencing());
      });
    }
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
          schoolTimeZone: cubitState.schoolTimeZone,
          allWorkSchedules: cubitState.allWorkSchedules,
          allBreakSchedules: cubitState.allBreakSchedules,
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

  /// Loads staff identity and sign-in status in one pass so button taps
  /// never hit a timing window where storage hasn't resolved yet.
  Future<void> _loadStaffIdentity() async {
    final storage = serviceLocator<StorageService>();
    final code = (await storage.getString(StorageKeys.staffCode))?.trim() ?? '';
    final name = (await storage.getString(StorageKeys.displayName) ?? '')
        .trim();
    final designation =
        (await storage.getString(StorageKeys.staffDesignation) ?? '').trim();
    if (!mounted) return;
    setState(() {
      _staffCode = code;
      _staffDisplayName = name;
      _staffDesignation = designation;
      _staffIdentityLoaded = true;
    });
    if (code.isEmpty) return;
    try {
      final useCase = serviceLocator<GetStaffTodaySignInStatusUseCase>();
      final status = await useCase(staffCode: code);
      if (!mounted) return;
      setState(() => _isSignedIn = status?.toUpperCase() == 'SIGNED_IN');
    } catch (_) {
      // sign-in status check is best-effort
    }
  }

  Future<void> _openTransferForSelf() async {
    if (_staffCode.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Unable to find your staff profile to transfer.',
        isWarning: true,
      );
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StaffTransferForm(
          staff: StaffEntity(
            id: 0,
            name: _staffDisplayName.isNotEmpty ? _staffDisplayName : '—',
            primaryRoomId: 0,
            designation: _staffDesignation.isNotEmpty
                ? _staffDesignation
                : 'Staff',
            staffCode: _staffCode,
          ),
        ),
      ),
    );
  }

  Future<void> _openMarkAbsentForSelf() async {
    final staff = _buildSelfStaffEntity();
    if (!mounted) return;
    if (staff == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Unable to find your staff profile to mark absent.',
        isWarning: true,
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StaffMarkAbsentForm(staff: staff)),
    );
    if (mounted) {
      unawaited(_loadStaffIdentity());
      unawaited(context.read<GeofenceCubit>().checkStaffSignInStatus());
    }
  }

  StaffEntity? _buildSelfStaffEntity() {
    if (_staffCode.isEmpty) return null;
    return StaffEntity(
      id: 0,
      name: _staffDisplayName.isNotEmpty ? _staffDisplayName : '—',
      primaryRoomId: 0,
      designation: _staffDesignation.isNotEmpty ? _staffDesignation : 'Staff',
      staffCode: _staffCode,
    );
  }

  Future<void> _openSignInForm() async {
    final staff = _buildSelfStaffEntity();
    if (!mounted) return;
    if (staff == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Unable to find your staff profile.',
        isWarning: true,
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StaffSignInForm(staff: staff, forceSelf: true),
      ),
    );
    if (mounted) {
      unawaited(_loadStaffIdentity());
      unawaited(context.read<GeofenceCubit>().checkStaffSignInStatus());
    }
  }

  Future<void> _openSignOutForm() async {
    final staff = _buildSelfStaffEntity();
    if (!mounted) return;
    if (staff == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Unable to find your staff profile.',
        isWarning: true,
      );
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => StaffSignOutForm(staff: staff)));
    if (mounted) {
      unawaited(_loadStaffIdentity());
      unawaited(context.read<GeofenceCubit>().checkStaffSignInStatus());
    }
  }

  // ---------------------------------------------------------------------------
  // Countdown computation
  // ---------------------------------------------------------------------------

  /// Countdown using ONLY staff work schedules with school timezone.
  ///
  /// Uses school timezone for calculating current time.
  /// Uses ONLY staff workSchedules API (never school regular schedule).
  /// Priority:
  ///   1. Today's staff schedule if it exists and hasn't passed
  ///   2. Today's staff schedule if currently active (count down to end)
  ///   3. Nearest upcoming staff schedule (within next 7 days)
  ///   4. Empty state if no staff schedules exist
  void _computeCountdownFromSchedule(
    SchoolRegularScheduleDay? schedule, {
    StaffProfileWorkSchedule? staffSchedule,
    StaffProfileBreakSchedule? breakSchedule,
    String schoolTimeZone = '',
    List<StaffProfileWorkSchedule> allWorkSchedules = const [],
    List<StaffProfileBreakSchedule> allBreakSchedules = const [],
  }) {
    // Get current time in SCHOOL TIMEZONE (for accurate countdown)
    final now = schoolTimeZone.isNotEmpty
        ? SchoolZoneDateTime.dateTimeFromInstantInSchool(
            DateTime.now().toUtc(),
            schoolTimeZone,
          )
        : DateTime.now();

    final todayWeekday = now.weekday; // 1 = Monday, 7 = Sunday
    final todayDateKey = _getDayName(todayWeekday); // "Monday", "Tuesday", etc.

    // debugPrint('[MyDayCard] Computing countdown: '
    //     'schoolTimezone=$schoolTimeZone, '
    //     'currentSchoolTime=${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour}:${now.minute}, '
    //     'today=$todayDateKey, '
    //     'allScheduleCount=${allWorkSchedules.length}');

    // Find today's staff schedule (ONLY from staff schedules, not school schedule)
    final todaySchedule = _resolveWorkScheduleForDay(
      todayWeekday,
      allWorkSchedules,
    );

    // ── Case 1: Today has a staff schedule ──────────────────────────────────────
    if (todaySchedule != null) {
      final startTime = todaySchedule.workStartTime;
      final endTime = todaySchedule.workEndTime;

      // Build today's schedule times using school timezone's date
      final startDt = DateTime(
        now.year,
        now.month,
        now.day,
        startTime.hour,
        startTime.minute,
        startTime.second,
      );
      final endDt = DateTime(
        now.year,
        now.month,
        now.day,
        endTime.hour,
        endTime.minute,
        endTime.second,
      );

      // debugPrint(
      //   '[MyDayCard] Today ($todayDateKey) has staff schedule: '
      //   '${startTime.hour}:${startTime.minute} - '
      //   '${endTime.hour}:${endTime.minute}',
      // );

      // If shift hasn't started yet
      if (now.isBefore(startDt)) {
        _setCountdownState(
          isTodayShift: true,
          hasShifts: true,
          duration: startDt.difference(now),
          workStart: _formatStaffTime(startTime),
          workEnd: _formatStaffTime(endTime),
          dayAbbr: _dayAbbr(todaySchedule.dayOfWeek),
          breakTime: _formatBreakDisplay(
            _resolveBreakScheduleForDay(todayWeekday, allBreakSchedules),
          ),
          statusText: 'Your shift starts in',
        );
        return;
      }

      // If shift is currently active
      if (now.isBefore(endDt)) {
        _setCountdownState(
          isTodayShift: true,
          hasShifts: true,
          duration: endDt.difference(now),
          workStart: _formatStaffTime(startTime),
          workEnd: _formatStaffTime(endTime),
          dayAbbr: _dayAbbr(todaySchedule.dayOfWeek),
          breakTime: _formatBreakDisplay(
            _resolveBreakScheduleForDay(todayWeekday, allBreakSchedules),
          ),
          statusText: 'Your shift ends in',
        );
        return;
      }

      // debugPrint(
      //   '[MyDayCard] Today ($todayDateKey) schedule already passed. Finding next schedule...',
      // );
    } else {
      // debugPrint(
      //   '[MyDayCard] Today ($todayDateKey) has no staff schedule. Finding next schedule...',
      // );
    }

    // ── Case 2: Find nearest upcoming schedule (ONLY from staff schedules) ──────
    _applyNextStaffShift(
      now,
      todayWeekday,
      allWorkSchedules,
      allBreakSchedules,
    );
  }

  /// Helper to set countdown state with all display values.
  void _setCountdownState({
    required bool isTodayShift,
    required bool hasShifts,
    required Duration duration,
    required String workStart,
    required String workEnd,
    required String dayAbbr,
    required String breakTime,
    required String statusText,
    String nextDayName = '',
  }) {
    setState(() {
      _isTodayShift = isTodayShift;
      _nextDayName = nextDayName;
      _hasShifts = hasShifts;
      _duration = duration;
      _workTime = '$workStart - $workEnd ($dayAbbr)';
      _breakTime = breakTime;
      _statusText = statusText;
    });
  }

  /// Searches forward 1–7 days for the nearest upcoming scheduled work day.
  ///
  /// Uses [_kDayToWeekday] (supports "TUESDAY" and "TUE") so no entry is ever
  /// silently dropped. Wraps the full week — e.g. today=Sunday, next=Monday.
  ///
  /// Sets [_isTodayShift] = false and [_nextDayName] to the full day name
  /// (e.g. "Wednesday") so [_buildAlignedTimerDisplay] can show it above the
  /// countdown.
  /// Finds nearest upcoming staff schedule within 7 days (using device local time).
  void _applyNextStaffShift(
    DateTime now,
    int todayWeekday,
    List<StaffProfileWorkSchedule> allWork,
    List<StaffProfileBreakSchedule> allBreak,
  ) {
    if (allWork.isEmpty) {
      _setCountdownState(
        isTodayShift: true,
        hasShifts: false,
        duration: Duration.zero,
        workStart: '--:--',
        workEnd: '--:--',
        dayAbbr: '',
        breakTime: '--:--',
        statusText: 'No schedules available',
      );
      return;
    }

    // Build maps: weekday → schedule
    final schedulesByWeekday = <int, StaffProfileWorkSchedule>{};
    final breaksByWeekday = <int, StaffProfileBreakSchedule>{};

    for (final ws in allWork) {
      final wd = _kDayToWeekday[ws.dayOfWeek.trim().toUpperCase()];
      if (wd != null) {
        schedulesByWeekday[wd] = ws;
      }
    }

    for (final bs in allBreak) {
      final wd = _kDayToWeekday[bs.dayOfWeek.trim().toUpperCase()];
      if (wd != null) {
        breaksByWeekday[wd] = bs;
      }
    }

    if (schedulesByWeekday.isEmpty) {
      _setCountdownState(
        isTodayShift: true,
        hasShifts: false,
        duration: Duration.zero,
        workStart: '--:--',
        workEnd: '--:--',
        dayAbbr: '',
        breakTime: '--:--',
        statusText: 'No schedules available',
      );
      return;
    }

    // Search next 7 days for upcoming schedule (starting tomorrow)
    for (int daysAhead = 1; daysAhead <= 7; daysAhead++) {
      final futureDate = now.add(Duration(days: daysAhead));
      final futureWeekday = futureDate.weekday;
      final schedule = schedulesByWeekday[futureWeekday];

      if (schedule == null) continue;

      final startTime = schedule.workStartTime;
      final startDt = DateTime(
        futureDate.year,
        futureDate.month,
        futureDate.day,
        startTime.hour,
        startTime.minute,
        startTime.second,
      );

      // debugPrint(
      //   '[MyDayCard] Next schedule found: '
      //   '${_getDayName(futureWeekday)} ${startTime.hour}:${startTime.minute}',
      // );

      _setCountdownState(
        isTodayShift: false,
        hasShifts: true,
        duration: startDt.difference(now),
        workStart: _formatStaffTime(startTime),
        workEnd: _formatStaffTime(schedule.workEndTime),
        dayAbbr: _dayAbbr(schedule.dayOfWeek),
        breakTime: _formatBreakDisplay(breaksByWeekday[futureWeekday]),
        statusText: 'Your next shift starts in',
        nextDayName: _getDayName(futureWeekday),
      );
      return;
    }

    // No schedule found in next 7 days
    _setCountdownState(
      isTodayShift: true,
      hasShifts: false,
      duration: Duration.zero,
      workStart: '--:--',
      workEnd: '--:--',
      dayAbbr: '',
      breakTime: '--:--',
      statusText: 'No upcoming shifts in next 7 days',
    );
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
          _buildTimeUnit('--', 'HH'),
          _buildTimeSeparator(),
          _buildTimeUnit('--', 'MM'),
          _buildTimeSeparator(),
          _buildTimeUnit('--', 'SS'),
        ],
      );
    }

    final bool showDays = duration.inHours >= 24;

    // ── Upcoming shift: show full day name above the countdown ───────────────
    if (!_isTodayShift && _nextDayName.isNotEmpty) {
      return Column(
        children: [
          Text(
            _nextDayName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Show days unit when shift is more than 24 hours away.
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
          ),
        ],
      );
    }

    // ── Today's shift ────────────────────────────────────────────────────────
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
        // GeofenceCubit already fires the notification via
        // _triggerNotificationIfNeeded — no need to do it here too.
        if (!context.mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          unawaited(
            GeofenceSignInSheet.show(
              context,
              role: 'staff',
              isSignedIn: _isSignedIn,
            ),
          );
        });
      },
      child: BlocConsumer<MyDayCubit, MyDayState>(
        // Re-compute countdown whenever schedule data changes or first loads.
        listenWhen: (prev, curr) =>
            curr.isLoaded &&
            (!prev.isLoaded ||
                prev.todaySchedule != curr.todaySchedule ||
                prev.todayWorkSchedule != curr.todayWorkSchedule ||
                prev.todayBreakSchedule != curr.todayBreakSchedule ||
                prev.schoolClosed != curr.schoolClosed ||
                prev.allWorkSchedules != curr.allWorkSchedules ||
                prev.allBreakSchedules != curr.allBreakSchedules ||
                prev.schoolTimeZone != curr.schoolTimeZone),
        listener: (context, state) {
          _computeCountdownFromSchedule(
            state.todaySchedule,
            staffSchedule: state.todayWorkSchedule,
            breakSchedule: state.todayBreakSchedule,
            schoolTimeZone: state.schoolTimeZone,
            allWorkSchedules: state.allWorkSchedules,
            allBreakSchedules: state.allBreakSchedules,
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
                            'Your Sign-In Pin: ${_clockInPin.trim().isNotEmpty ? _clockInPin : '--'}',
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
                        final roleProvider = context.watch<RoleCubit>();
                        final bool isStaff = roleProvider.isStaff;
                        final bool isAdmin = roleProvider.isAdmin;
                        final bool isWithinGeofence =
                            geofenceState.isWithinGeofence;
                        // Both staff and admin: button enabled only when within geofence.
                        final bool signButtonEnabled =
                            (isStaff || isAdmin) && isWithinGeofence;
                        // Show attendance buttons for both staff and admin
                        final bool showSignButton = isStaff || isAdmin;
                        // Show Transfer/Mark-Absent for staff and admin equally.
                        final bool showSecondaryButtons = isStaff || isAdmin;

                        return Column(
                          children: [
                            if (showSignButton)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                ),
                                child: Row(
                                  children: [
                                    // Transfer (signed-in) or Mark Absent (not signed-in)
                                    if (showSecondaryButtons && _isSignedIn)
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed:
                                              (!_staffIdentityLoaded ||
                                                  _staffCode.isEmpty)
                                                  ? null
                                                  : _openTransferForSelf,
                                          icon: !_staffIdentityLoaded
                                              ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 1.5,
                                                        color: AppColors
                                                            .themeColor,
                                                      ),
                                                )
                                              : const SizedBox.shrink(),
                                          label: const Text(
                                            'Transfer',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                AppColors.themeColor,
                                            side: const BorderSide(
                                              color: AppColors.themeColor,
                                            ),
                                            padding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 14,
                                                ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      )
                                    else if (showSecondaryButtons &&
                                        !_isSignedIn)
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed:
                                              (!_staffIdentityLoaded ||
                                                  _staffCode.isEmpty)
                                                  ? null
                                                  : _openMarkAbsentForSelf,
                                          icon: !_staffIdentityLoaded
                                              ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 1.5,
                                                        color: AppColors
                                                            .themeColor,
                                                      ),
                                                )
                                              : const SizedBox.shrink(),
                                          label: const Text(
                                            'Mark Absent',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                AppColors.themeColor,
                                            side: const BorderSide(
                                              color: AppColors.themeColor,
                                            ),
                                            padding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 14,
                                                ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (showSecondaryButtons)
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
                                            Icon(
                                              Icons.location_on_outlined,
                                              size: 18,
                                              color: signButtonEnabled
                                                  ? AppColors
                                                        .billingBackgroundColor
                                                  : Colors.grey[600],
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                _isSignedIn
                                                    ? 'Sign-Out'
                                                    : 'Sign-In',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: signButtonEnabled
                                                      ? AppColors
                                                            .billingBackgroundColor
                                                      : Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        onPressedConfirm: signButtonEnabled
                                            ? () {
                                                if (_isSignedIn) {
                                                  unawaited(_openSignOutForm());
                                                } else {
                                                  unawaited(_openSignInForm());
                                                }
                                              }
                                            : null,
                                        disabledConfirmTooltip:
                                            'You are not within geofencing Range',
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
                            if (isStaff || isAdmin)
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
    final roleProvider = context.read<RoleCubit>();
    if (!roleProvider.isStaff && !roleProvider.isAdmin) {
      return const SizedBox.shrink();
    }

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
