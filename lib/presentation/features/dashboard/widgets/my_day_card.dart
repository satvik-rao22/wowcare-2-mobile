import 'dart:async';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/my_day_chat_preview_row.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_forms/staff_transfer_form.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_forms/staff_mark_absent_form.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_forms/staff_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_forms/staff_sign_out_form.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/domain/features/staff/entities/school_regular_schedule_day.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/my_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/work_break_reminder_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/dashboard_card_header.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/dashboard_error_chip.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/qr_scan_button.dart';
import 'package:wowcare/presentation/features/geofencing/view_model/geofence_cubit.dart';
import 'package:wowcare/presentation/features/geofencing/widgets/geofence_sign_in_sheet.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/attendance_events.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/presentation/features/attendance/model/staff_entity.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_attendance_action_availability.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';
import 'package:wowcare/core/utils/server_time_service.dart';

// ---------------------------------------------------------------------------
// MyDayCard
// ---------------------------------------------------------------------------

/// Dashboard card displaying the school's schedule for today, a shift
/// countdown, sign-in pin, attendance action buttons, and the latest chat
/// preview.
///
/// Schedule data comes from [MyDayCubit]; all other fields are still mocked
/// pending their respective API integrations.
/// Immutable snapshot of the "My Day" countdown display.
///
/// Mandate 2 bucket B. These seven values are derived presentation state, not
/// cubit state: they are recomputed once per second by [_MyDayCardState._ticker]
/// from data the cubit already owns. Holding them as `State` fields meant every
/// tick called `setState` and marked the whole 2,200-line card dirty — the
/// photo, the badges, the chat row and every const subtree in the same
/// `build()` (§2.6).
///
/// Bundled into one object rather than seven notifiers so a tick that changes
/// nothing changes nothing: [ValueNotifier] only notifies when `value !=
/// oldValue`, and this type has value equality — so the ~59 ticks per minute
/// that leave the display identical now rebuild nothing at all.
@immutable
class _CountdownView {
  const _CountdownView({
    required this.isTodayShift,
    required this.nextDayName,
    required this.hasShifts,
    required this.duration,
    required this.workTime,
    required this.breakTime,
    required this.statusText,
  });

  /// Matches the field initialisers this replaced, so the first frame is
  /// byte-identical to before.
  const _CountdownView.initial()
    : isTodayShift = true,
      nextDayName = '',
      hasShifts = false,
      duration = Duration.zero,
      workTime = '--:--',
      breakTime = '--:--',
      statusText = AppStrings.myDayLoadingSchedule;

  final bool isTodayShift;
  final String nextDayName;
  final bool hasShifts;
  final Duration duration;
  final String workTime;
  final String breakTime;
  final String statusText;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CountdownView &&
          other.isTodayShift == isTodayShift &&
          other.nextDayName == nextDayName &&
          other.hasShifts == hasShifts &&
          other.duration == duration &&
          other.workTime == workTime &&
          other.breakTime == breakTime &&
          other.statusText == statusText;

  @override
  int get hashCode => Object.hash(
    isTodayShift,
    nextDayName,
    hasShifts,
    duration,
    workTime,
    breakTime,
    statusText,
  );
}

class MyDayCard extends StatefulWidget {
  const MyDayCard({super.key});

  @override
  State<MyDayCard> createState() => _MyDayCardState();
}

class _MyDayCardState extends State<MyDayCard> with WidgetsBindingObserver {
  // Token / generation counter to invalidate stale async operations on persona switch

  // ---- collapse state ----
  // Mandate 2 bucket B: UI micro-state. A `final` ValueNotifier field (never
  // created in build(), disposed below) so toggling collapse no longer marks
  // the whole 2,200-line State dirty.
  final ValueNotifier<bool> _minimized = ValueNotifier<bool>(false);

  // Guards the geofence popup: shown at most once per app session per entry
  // transition. Resets to false when the user exits the geofence, ensuring
  // the popup appears again on the next entry (e.g. after sign-out).
  bool _geofencePopupShownThisEntry = false;

  // Prevents didChangeDependencies from stacking multiple geofence-init
  // callbacks when ancestor InheritedWidgets rebuild.
  bool _geofenceInitScheduled = false;

  /// Staff identity + today's status now live in [MyDayCubit] (Mandate 2
  /// bucket A). Handlers read them through here; `build` already has the same
  /// state from its BlocConsumer.
  MyDayState get _myDay => context.read<MyDayCubit>().state;

  // ---- sign-in status ----

  // True once the async today-sign-in-status fetch in `_loadStaffIdentity`
  // has resolved (success or failure) at least once. `_myDay.isSignedIn` defaults
  // to false until then, so the geofence-entry popup must not trust it (and
  // must not decide "show" or "don't show") until this is true — otherwise
  // an already-signed-in user restarting the app inside the geofence (e.g.
  // GeofenceCubit reporting `withinRange` from a cached last-known location
  // before the attendance API call resolves) would incorrectly see the
  // Sign-In sheet.

  // Raw today-status string from the API (e.g. SIGNED_IN, ABSENT,
  // SIGNED_OUT). Kept alongside `_myDay.isSignedIn` because the boolean alone
  // can't distinguish "not signed in" from "already marked absent today",
  // which the attendance gate below needs to disable actions correctly.

  /// Same gate used by the admin attendance pop-up
  /// ([StaffAttendanceVerticalPopupOnly] via `staff_attendance_profile.dart`)
  /// so self-service Sign-In/Sign-Out/Transfer/Mark-Absent rules stay
  /// consistent across both surfaces.
  StaffAttendanceGate get _todayGate => staffAttendanceGateFromTodayStatus(
    isActiveProfile: true,
    todayStatusRaw: _myDay.todayStatusRaw,
    // A staff member who marked themselves absent can still sign in from My
    // Day; the sign-in form clears today's absence record first.
    allowAbsentSignInOverride: true,
  );

  /// Geofencing is the first-class gate for every self-attendance action:
  /// staff must be within the school's geofence before any of Sign-In,
  /// Sign-Out, Transfer or Mark-Absent become available. Within range, the
  /// day's status (via [_todayGate]) decides which of the four apply.
  StaffAttendanceActionAvailability _availability(
    GeofenceState geofenceState,
  ) => _todayGate.availabilityWithGeofence(geofenceState.isWithinGeofence);

  Map<String, String> _disabledReasons(GeofenceState geofenceState) =>
      staffAttendanceDisabledReasonsWithGeofence(
        _todayGate,
        isWithinGeofence: geofenceState.isWithinGeofence,
      );

  bool _markAbsentDisabled(GeofenceState geofenceState) =>
      !_myDay.staffIdentityLoaded ||
      _myDay.effectiveStaffCode.isEmpty ||
      !_availability(geofenceState).absentEnabled;

  // Cached staff identity — loaded once in initState so button taps never hit
  // a timing window where storage hasn't resolved yet.
  // Pure admins (role == 'admin', not also 'staff') have no staff profile, so
  // StorageKeys.staffCode is legitimately empty for them — StorageKeys.userCode
  // is used as their self-attendance identity instead.

  /// The identity used for self-attendance actions (Sign-In/Sign-Out/Transfer/
  /// Mark Absent): the real staffCode when the user has a staff profile,
  /// falling back to their userCode for staff-less personas (pure admins).
  final ValueNotifier<_CountdownView> _countdown =
      ValueNotifier<_CountdownView>(const _CountdownView.initial());
  // ---- shift countdown display state ----

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
    WidgetsBinding.instance.addObserver(this);
    AttendanceEvents.tick.addListener(_handleAttendanceChanged);
    unawaited(context.read<MyDayCubit>().loadClockPin());
    unawaited(_loadStaffIdentity());
  }

  void _handleAttendanceChanged() {
    if (!mounted) return;
    unawaited(context.read<MyDayCubit>().loadClockPin());
    unawaited(_loadStaffIdentity());
    try {
      final myDayCubit = context.read<MyDayCubit>();
      unawaited(myDayCubit.load());
    } catch (_) {}
  }

  // Re-checks sign-in status the moment the app comes back to the
  // foreground — covers the case where this staff member was signed in/out
  // from the web (or another device) while the app was backgrounded, so the
  // Sign-In/Sign-Out button doesn't stay stuck showing the stale state.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    unawaited(_loadStaffIdentity());
    unawaited(context.read<GeofenceCubit>().checkStaffSignInStatus());
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
      debugPrint(
        '[MyDayCard] _initializeGeofencing — schoolCode="$schoolCode" mounted=$mounted',
      );
      if (schoolCode.isEmpty) {
        debugPrint(
          '[MyDayCard] ⚠️ schoolCode is empty — geofencing cannot start. Check that StorageKeys.schoolCode is saved after login.',
        );
        return;
      }
      if (!mounted) return;

      // Initialize GPS geofencing with the school code
      await context.read<GeofenceCubit>().initForSchool(schoolCode: schoolCode);
    } catch (e, st) {
      debugPrint('[MyDayCard] ❌ _initializeGeofencing error: $e\n$st');
    }
  }

  @override
  void dispose() {
    AttendanceEvents.tick.removeListener(_handleAttendanceChanged);
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _minimized.dispose();
    _countdown.dispose();
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

  /// Loads staff identity + today's sign-in status through [MyDayCubit], then
  /// does the two things that are the VIEW's job and cannot move into a cubit:
  /// syncing GeofenceCubit and re-evaluating the sign-in sheet.
  Future<void> _loadStaffIdentity() async {
    if (!mounted) return;
    final signedIn = await context.read<MyDayCubit>().loadStaffIdentity();
    if (!mounted) return;
    if (signedIn != null) {
      unawaited(
        context.read<GeofenceCubit>().updateStaffSignInStatus(signedIn),
      );
    }
    // Covers the race where the geofence-entry listener fired (and skipped
    // showing the sheet) while this fetch was still in flight — re-evaluate
    // now that the real sign-in status is known.
    _maybeShowSignInPopup();
  }

  /// Shows the geofence Sign-In sheet only when: the staff/admin is
  /// currently within the school geofence, their today-sign-in status has
  /// finished loading and shows them as not signed in, and the popup hasn't
  /// already been shown for this geofence entry. Called both from the
  /// [GeofenceCubit] entry-transition listener and right after
  /// [_loadStaffIdentity]'s async status fetch resolves, so whichever of the
  /// two finishes last is the one that actually decides whether to show it.
  void _maybeShowSignInPopup() {
    if (!mounted) return;
    if (!_myDay.signInStatusLoaded) return;
    if (!_myDay.staffIdentityLoaded) return;
    if (_myDay.effectiveStaffCode.isEmpty) return;
    if (_myDay.isSignedIn) return;
    if (_myDay.todayStatusRaw?.toUpperCase() == 'SIGNED_IN') return;
    if (_geofencePopupShownThisEntry) return;

    final geofenceState = context.read<GeofenceCubit>().state;
    if (geofenceState.isSignInStatusLoading) return;
    if (geofenceState.status != GeofenceCubitStatus.withinRange) return;
    if (geofenceState.isStaffSignedIn) return;

    _geofencePopupShownThisEntry = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_myDay.signInStatusLoaded ||
          !_myDay.staffIdentityLoaded ||
          _myDay.isSignedIn)
        return;
      unawaited(
        GeofenceSignInSheet.show(context, role: 'staff', isSignedIn: false),
      );
    });
  }

  Future<void> _openTransferForSelf() async {
    if (_myDay.effectiveStaffCode.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: AppStrings.myDayNoStaffProfileTransfer,
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
            name: _myDay.staffDisplayName.isNotEmpty
                ? _myDay.staffDisplayName
                : '—',
            primaryRoomId: 0,
            designation: _myDay.staffDesignation.isNotEmpty
                ? _myDay.staffDesignation
                : 'Staff',
            staffCode: _myDay.effectiveStaffCode,
          ),
        ),
      ),
    );
    if (mounted) {
      await _loadStaffIdentity();
      if (mounted) {
        unawaited(context.read<GeofenceCubit>().checkStaffSignInStatus());
      }
    }
  }

  void _handleMarkAbsentDisabledTap() {
    final geofenceState = context.read<GeofenceCubit>().state;
    final message = _todayGate.isAbsentToday
        ? 'Absent can only be marked for Students/Staff not yet signed in'
        : (_disabledReasons(geofenceState)['Absent'] ??
              'Mark Absent is currently unavailable.');
    CoreUtils.showTopSnackBar(
      context: context,
      message: message,
      isWarning: true,
    );
  }

  Future<void> _openMarkAbsentForSelf() async {
    final staff = _buildSelfStaffEntity();
    if (!mounted) return;
    if (staff == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: AppStrings.myDayNoStaffProfileMarkAbsent,
        isWarning: true,
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StaffMarkAbsentForm(staff: staff, popOnSuccess: true),
      ),
    );
    if (mounted) {
      await _loadStaffIdentity();
      if (mounted) {
        unawaited(context.read<GeofenceCubit>().checkStaffSignInStatus());
      }
    }
  }

  StaffEntity? _buildSelfStaffEntity() {
    if (_myDay.effectiveStaffCode.isEmpty) return null;
    return StaffEntity(
      id: 0,
      name: _myDay.staffDisplayName.isNotEmpty ? _myDay.staffDisplayName : '—',
      primaryRoomId: 0,
      designation: _myDay.staffDesignation.isNotEmpty
          ? _myDay.staffDesignation
          : 'Staff',
      staffCode: _myDay.effectiveStaffCode,
    );
  }

  Future<void> _openSignInForm() async {
    final staff = _buildSelfStaffEntity();
    if (!mounted) return;
    if (staff == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: AppStrings.myDayNoStaffProfile,
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
      await _loadStaffIdentity();
      if (mounted) {
        // Keep GeofenceCubit.isStaffSignedIn in sync immediately after sign-in —
        // it now also drives suppressing the "you can now Sign In or Sign Out"
        // notification, so leaving it stale here would let that notification
        // wrongly fire again right after the user just signed in.
        unawaited(context.read<GeofenceCubit>().checkStaffSignInStatus());
      }
    }
  }

  Future<void> _openSignOutForm() async {
    final staff = _buildSelfStaffEntity();
    if (!mounted) return;
    if (staff == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: AppStrings.myDayNoStaffProfile,
        isWarning: true,
      );
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => StaffSignOutForm(staff: staff)));
    if (mounted) {
      await _loadStaffIdentity();
      if (mounted) {
        unawaited(context.read<GeofenceCubit>().checkStaffSignInStatus());
      }
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
            ServerTimeService.instance.nowUtc(),
            schoolTimeZone,
          )
        : AppTime.now();

    final todayWeekday = now.weekday; // 1 = Monday, 7 = Sunday

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
          statusText: AppStrings.myDayShiftStartsIn,
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
          statusText: AppStrings.myDayShiftEndsIn,
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
    _countdown.value = _CountdownView(
      isTodayShift: isTodayShift,
      nextDayName: nextDayName,
      hasShifts: hasShifts,
      duration: duration,
      workTime: '$workStart - $workEnd ($dayAbbr)',
      breakTime: breakTime,
      statusText: statusText,
    );
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
        statusText: AppStrings.myDayNoSchedules,
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
        statusText: AppStrings.myDayNoSchedules,
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
        statusText: AppStrings.myDayNextShiftStartsIn,
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
      statusText: AppStrings.myDayNoUpcomingShifts,
    );
  }

  // ---------------------------------------------------------------------------
  // Timer display builders (unchanged from original)
  // ---------------------------------------------------------------------------

  Widget _buildTimeUnit(String value, String label, bool hasShifts) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.myDayCountdownDigits),
        if (hasShifts)
          Text(label, style: AppTextStyles.myDayCountdownUnitLabel),
      ],
    );
  }

  Widget _buildTimeSeparator(bool hasShifts) {
    return Padding(
      padding: hasShifts
          ? const EdgeInsets.fromLTRB(2, 0, 2, 10)
          : const EdgeInsets.fromLTRB(2, 0, 2, 5),
      child: const Text(':', style: AppTextStyles.myDayCountdownSeparator),
    );
  }

  Widget _buildAlignedTimerDisplay(_CountdownView view) {
    final Duration duration = view.duration;
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    if (!view.hasShifts) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTimeUnit('--', 'HH', view.hasShifts),
          _buildTimeSeparator(view.hasShifts),
          _buildTimeUnit('--', 'MM', view.hasShifts),
          _buildTimeSeparator(view.hasShifts),
          _buildTimeUnit('--', 'SS', view.hasShifts),
        ],
      );
    }

    final bool showDays = duration.inHours >= 24;

    // ── Upcoming shift: show full day name above the countdown ───────────────
    if (!view.isTodayShift && view.nextDayName.isNotEmpty) {
      return Column(
        children: [
          Text(view.nextDayName, style: AppTextStyles.myDayUpcomingDayName),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Show days unit when shift is more than 24 hours away.
              if (showDays) ...[
                _buildTimeUnit(
                  twoDigits(duration.inDays),
                  'DD',
                  view.hasShifts,
                ),
                _buildTimeSeparator(view.hasShifts),
              ],
              _buildTimeUnit(
                twoDigits(duration.inHours.remainder(24)),
                'HH',
                view.hasShifts,
              ),
              _buildTimeSeparator(view.hasShifts),
              _buildTimeUnit(
                twoDigits(duration.inMinutes.remainder(60)),
                'MM',
                view.hasShifts,
              ),
              _buildTimeSeparator(view.hasShifts),
              _buildTimeUnit(
                twoDigits(duration.inSeconds.remainder(60)),
                'SS',
                view.hasShifts,
              ),
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
          _buildTimeUnit(twoDigits(duration.inDays), 'DD', view.hasShifts),
          _buildTimeSeparator(view.hasShifts),
        ],
        _buildTimeUnit(
          twoDigits(duration.inHours.remainder(24)),
          'HH',
          view.hasShifts,
        ),
        _buildTimeSeparator(view.hasShifts),
        _buildTimeUnit(
          twoDigits(duration.inMinutes.remainder(60)),
          'MM',
          view.hasShifts,
        ),
        _buildTimeSeparator(view.hasShifts),
        _buildTimeUnit(
          twoDigits(duration.inSeconds.remainder(60)),
          'SS',
          view.hasShifts,
        ),
      ],
    );
  }
  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<GeofenceCubit, GeofenceState>(
          listenWhen: (prev, curr) {
            // Reset popup guard whenever we leave withinRange — covers both
            // actual zone exit (→ outsideRange) and a dashboard refresh cycle
            // (→ fetchingSchoolLocation → withinRange). Without this, the guard
            // would stay true across a refresh and block the sheet from re-showing.
            if (prev.status == GeofenceCubitStatus.withinRange &&
                curr.status != GeofenceCubitStatus.withinRange) {
              _geofencePopupShownThisEntry = false;
            }
            // Fire when transitioning into withinRange OR when sign-in status finishes loading while withinRange
            if (curr.status == GeofenceCubitStatus.withinRange) {
              if (prev.status != GeofenceCubitStatus.withinRange) return true;
              if (prev.isSignInStatusLoading && !curr.isSignInStatusLoading)
                return true;
            }
            return false;
          },
          listener: (context, _) => _maybeShowSignInPopup(),
        ),
        BlocListener<RoleCubit, RoleState>(
          listenWhen: (prev, curr) =>
              prev.activeSchoolRoleRaw != curr.activeSchoolRoleRaw,
          listener: (context, state) {
            context.read<MyDayCubit>().resetForProfileSwitch();
            // View-only guard: the popup must be re-armed for the new persona.
            _geofencePopupShownThisEntry = false;
            unawaited(_loadStaffIdentity());
            unawaited(context.read<GeofenceCubit>().checkStaffSignInStatus());
          },
        ),
      ],
      child: BlocConsumer<MyDayCubit, MyDayState>(
        // Re-compute countdown and re-sync identity whenever schedule data changes or first loads.
        listenWhen: (prev, curr) =>
            curr.isLoaded &&
            (!prev.isLoaded ||
                prev.todaySchedule != curr.todaySchedule ||
                prev.todayWorkSchedule != curr.todayWorkSchedule ||
                prev.todayBreakSchedule != curr.todayBreakSchedule ||
                prev.schoolClosed != curr.schoolClosed ||
                prev.allWorkSchedules != curr.allWorkSchedules ||
                prev.allBreakSchedules != curr.allBreakSchedules ||
                prev.schoolTimeZone != curr.schoolTimeZone ||
                prev.status != curr.status),
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
          unawaited(_loadStaffIdentity());
        },
        builder: (context, state) {
          return DashboardCardErrorOverlay(
            show: state.status == MyDayStatus.error,
            onRetry: () => context.read<MyDayCubit>().load(),
            child: Container(
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
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _minimized,
                      builder: (context, minimized, _) => DashboardCardHeader(
                        title: AppStrings.myDayTitle,
                        minimized: minimized,
                        onToggle: () => _minimized.value = !minimized,
                      ),
                    ),
                  ),

                  // ── Status text ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: state.isLoading
                        ? _MyDayShimmerLine(width: 180, height: 18)
                        : ValueListenableBuilder<_CountdownView>(
                            valueListenable: _countdown,
                            builder: (context, view, _) => Text(
                              view.statusText,
                              style: AppTextStyles.myDayStatusLine,
                            ),
                          ),
                  ),

                  // ── Expanded body ────────────────────────────────────────────
                  // Mandate 2 §2.2: the body is built ONCE per card build and handed
                  // to the builder untouched via `child:`. Toggling collapse now
                  // rebuilds only the swap — not these 300 lines, their shimmer,
                  // chips or chat row, which is what setState did on every tap (§2.6).
                  ValueListenableBuilder<bool>(
                    valueListenable: _minimized,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Countdown timer / shimmer
                        if (state.isLoading)
                          _buildShimmerBody()
                        else ...[
                          // Per-second countdown. `child:` carries the
                          // reminder toggle, which does not depend on the
                          // countdown and so is built once per card build
                          // rather than 60 times a minute (§2.2).
                          ValueListenableBuilder<_CountdownView>(
                            valueListenable: _countdown,
                            child: BlocSelector<MyDayCubit, MyDayState, String>(
                              selector: (state) => state.staffCode,
                              builder: (context, staffCode) =>
                                  _ReminderToggleButton(staffCode: staffCode),
                            ),
                            builder: (context, view, child) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildAlignedTimerDisplay(view),
                                if (view.hasShifts) const SizedBox(height: 12),

                                // ── Reminder toggle ──────────────────────────
                                child!,
                                const SizedBox(height: 8),

                                // ── Work time chip ───────────────────────────
                                _CustomChip(
                                  label:
                                      '${AppStrings.myDayWorkTimePrefix}${view.workTime}',
                                  labelStyle: AppTextStyles.myDayChipLabel,
                                  color: AppColors.myDayChipSurface,
                                ),
                                const SizedBox(height: 8),

                                // ── Break time chip ──────────────────────────
                                _CustomChip(
                                  label:
                                      '${AppStrings.myDayBreakTimePrefix}${view.breakTime}',
                                  labelStyle: AppTextStyles.myDayChipLabel,
                                  color: AppColors.myDayChipSurface,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // ── Sign-in pin + QR scanner ─────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Depends on exactly one field of MyDayState,
                              // so it is selected rather than rebuilt with
                              // the card (§2.2's BlocSelector rule).
                              BlocSelector<MyDayCubit, MyDayState, String>(
                                selector: (state) => state.clockInPin,
                                builder: (context, clockInPin) => Text(
                                  '${AppStrings.myDaySignInPinPrefix}${clockInPin.trim().isNotEmpty ? clockInPin : AppStrings.myDaySignInPinPlaceholder}',
                                  style: AppTextStyles.myDayClockInPin,
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
                              final StaffAttendanceActionAvailability
                              availability = _availability(geofenceState);
                              final Map<String, String> disabledReasons =
                                  _disabledReasons(geofenceState);
                              final bool markAbsentDisabled =
                                  _markAbsentDisabled(geofenceState);
                              // Sign button toggles Sign-In/Sign-Out depending on
                              // today's status; enable per the action it currently represents.
                              final bool signButtonEnabled =
                                  (isStaff || isAdmin) &&
                                  (_myDay.isSignedIn
                                      ? availability.signOutEnabled
                                      : availability.signInEnabled);
                              // Show attendance buttons for both staff and admin
                              final bool showSignButton = isStaff || isAdmin;
                              // Show Transfer/Mark-Absent for staff and admin equally.
                              final bool showSecondaryButtons =
                                  isStaff || isAdmin;

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
                                          if (showSecondaryButtons &&
                                              _myDay.isSignedIn)
                                            Expanded(
                                              child: Tooltip(
                                                message:
                                                    availability.transferEnabled
                                                    ? ''
                                                    : disabledReasons['Transfer'] ??
                                                          '',
                                                child: OutlinedButton.icon(
                                                  onPressed:
                                                      (!_myDay.staffIdentityLoaded ||
                                                          _myDay
                                                              .effectiveStaffCode
                                                              .isEmpty ||
                                                          !availability
                                                              .transferEnabled)
                                                      ? null
                                                      : _openTransferForSelf,
                                                  icon:
                                                      !_myDay
                                                          .staffIdentityLoaded
                                                      ? const SizedBox(
                                                          width: 14,
                                                          height: 14,
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth:
                                                                    1.5,
                                                                color: AppColors
                                                                    .themeColor,
                                                              ),
                                                        )
                                                      : const SizedBox.shrink(),
                                                  label: const Text(
                                                    'Transfer',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        AppColors.themeColor,
                                                    side: const BorderSide(
                                                      color:
                                                          AppColors.themeColor,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 14,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
                                                    ),
                                                    textStyle: AppTextStyles
                                                        .myDayActionButtonLabel,
                                                  ),
                                                ),
                                              ),
                                            )
                                          else if (showSecondaryButtons &&
                                              !_myDay.isSignedIn)
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: markAbsentDisabled
                                                    ? _handleMarkAbsentDisabledTap
                                                    : null,
                                                child: Tooltip(
                                                  message:
                                                      availability.absentEnabled
                                                      ? ''
                                                      : disabledReasons['Absent'] ??
                                                            '',
                                                  child: OutlinedButton.icon(
                                                    onPressed:
                                                        markAbsentDisabled
                                                        ? null
                                                        : _openMarkAbsentForSelf,
                                                    icon:
                                                        !_myDay
                                                            .staffIdentityLoaded
                                                        ? const SizedBox(
                                                            width: 14,
                                                            height: 14,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 1.5,
                                                              color: AppColors
                                                                  .themeColor,
                                                            ),
                                                          )
                                                        : const SizedBox.shrink(),
                                                    label: const Text(
                                                      'Mark Absent',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor:
                                                          markAbsentDisabled
                                                          ? AppColors
                                                                .disabledActionLabel
                                                          : AppColors
                                                                .themeColor,
                                                      side: BorderSide(
                                                        color:
                                                            markAbsentDisabled
                                                            ? AppColors
                                                                  .disabledActionBorder
                                                            : AppColors
                                                                  .themeColor,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 14,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              14,
                                                            ),
                                                      ),
                                                      textStyle: AppTextStyles
                                                          .myDayActionButtonLabel,
                                                    ),
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
                                              confirmButtonLabel:
                                                  _myDay.isSignedIn
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
                                                        : AppColors
                                                              .disabledActionLabel,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      _myDay.isSignedIn
                                                          ? 'Sign-Out'
                                                          : 'Sign-In',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: AppTextStyles
                                                          .myDayActionButtonLabel
                                                          .copyWith(
                                                            color:
                                                                signButtonEnabled
                                                                ? AppColors
                                                                      .billingBackgroundColor
                                                                : AppColors
                                                                      .disabledActionLabel,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              onPressedConfirm:
                                                  signButtonEnabled
                                                  ? () {
                                                      if (_myDay.isSignedIn) {
                                                        unawaited(
                                                          _openSignOutForm(),
                                                        );
                                                      } else {
                                                        unawaited(
                                                          _openSignInForm(),
                                                        );
                                                      }
                                                    }
                                                  : null,
                                              disabledConfirmTooltip:
                                                  disabledReasons[_myDay
                                                          .isSignedIn
                                                      ? 'Sign-Out'
                                                      : 'Sign-in'] ??
                                                  AppStrings.geofenceNotInRange,
                                              onDisabledConfirmTap: () {
                                                CoreUtils.showTopSnackBar(
                                                  isWarning: true,
                                                  message:
                                                      disabledReasons[_myDay
                                                              .isSignedIn
                                                          ? 'Sign-Out'
                                                          : 'Sign-in'] ??
                                                      AppStrings
                                                          .geofenceNotInRange,
                                                  context: context,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (isStaff || isAdmin)
                                    _buildGeofenceStatusLabel(
                                      context,
                                      geofenceState,
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                    builder: (context, minimized, child) =>
                        minimized ? const SizedBox.shrink() : child!,
                  ),

                  const SizedBox(height: 10),

                  // ── Latest chat preview ──────────────────────────────────────
                  const MyDayChatPreviewRow(),
                ],
              ),
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

    const style = AppTextStyles.myDayGeofenceStatus;
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
                  color: AppColors.geofenceInsideIndicator,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                AppStrings.geofenceInsideRadius,
                style: style.copyWith(
                  color: AppColors.geofenceInsideText,
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
            AppStrings.geofenceOutsideRadius,
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
            AppStrings.geofenceDisabledByAdmin,
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
              AppStrings.geofencePermissionRequired,
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
            AppStrings.geofenceServicesDisabled,
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
            AppStrings.geofenceChecking,
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
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
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
                          color: AppColors.cardColor,
                        ),
                      )
                    : Container(
                        width: 44,
                        height: 56,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cardColor,
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
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 8),
            // Half-day chip placeholder
            Container(
              height: 36,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 8),
            // Pin row placeholder
            Container(
              height: 20,
              width: 200,
              decoration: BoxDecoration(
                color: AppColors.cardColor,
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
// _MyDayShimmerLine helper
// ---------------------------------------------------------------------------

class _MyDayShimmerLine extends StatelessWidget {
  const _MyDayShimmerLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MyDayChatPreviewRow
// ---------------------------------------------------------------------------
// Shows the logged-in user's name (from StorageService) with a "Chat Not Found"
// placeholder until the real messaging API is integrated.
// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

/// Work-break reminder toggle.
///
/// Mandate 2, bucket A: every field this widget used to hold in `State`
/// (`_isLoading`, `_reminderEnabled`) is already owned by
/// [WorkBreakReminderCubit] — the widget was mirroring `cubit.state` into
/// `setState` after awaiting it, which is the "state that should never have
/// been in a widget" case (§2.4) in its purest form. It now reads the cubit
/// directly and holds no state at all, so it is a StatelessWidget.
///
/// This also closes the module's one confirmed cubit leak: the cubit used to be
/// resolved with `serviceLocator<WorkBreakReminderCubit>()` *inside the tap
/// handler*, and it is a `registerFactory` — so every tap allocated a fresh
/// cubit, awaited a network write on it, read its state, and dropped it
/// unclosed (§5.5). `BlocProvider.create` owns exactly one and closes it.
class _ReminderToggleButton extends StatelessWidget {
  const _ReminderToggleButton({required this.staffCode});

  final String staffCode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkBreakReminderCubit>(
      create: (_) => serviceLocator<WorkBreakReminderCubit>(),
      child: _ReminderToggleButtonView(staffCode: staffCode),
    );
  }
}

class _ReminderToggleButtonView extends StatelessWidget {
  const _ReminderToggleButtonView({required this.staffCode});

  final String staffCode;

  @override
  Widget build(BuildContext context) {
    // Snackbars move from post-await branches to a listener on the same state
    // transitions, so the messages and their conditions are unchanged.
    return BlocListener<WorkBreakReminderCubit, WorkBreakReminderState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.isSuccess) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: state.enabled
                ? AppStrings.reminderTurnedOnConfirmation
                : AppStrings.reminderTurnedOffConfirmation,
            isSuccess: true,
          );
        } else if (state.isFailure && state.message != null) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: state.message!,
            isWarning: true,
          );
        }
      },
      // The icon, gradient and padding never depend on cubit state, so they are
      // built once here and handed to the selectors below untouched — the same
      // `child:`-hoisting win §2.2 asks for from ValueListenableBuilder.
      child: BlocSelector<WorkBreakReminderCubit, WorkBreakReminderState, bool>(
        selector: (state) => state.isLoading,
        builder: (context, isLoading) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (isLoading || staffCode.isEmpty) return;
                final cubit = context.read<WorkBreakReminderCubit>();
                unawaited(
                  cubit.toggleReminder(
                    staffCode: staffCode,
                    currentEnabled: cubit.state.enabled,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(100),
              splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
              child: Opacity(
                opacity: isLoading ? 0.6 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon(MediaRes.notificationsGradientIcon),
                      const SizedBox(width: 8),
                      BlocSelector<
                        WorkBreakReminderCubit,
                        WorkBreakReminderState,
                        bool
                      >(
                        selector: (state) => state.enabled,
                        builder: (context, enabled) => Text(
                          enabled
                              ? AppStrings.reminderTurnOff
                              : AppStrings.reminderSend,
                          style: AppTextStyles.mediumWeight.copyWith(
                            color: AppColors.themeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

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
