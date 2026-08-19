import 'dart:async';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/domain/features/staff/entities/school_regular_schedule_day.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/work_break_reminder_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_error_chip.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/qr_scan_button.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';
import 'package:wowcare/presentation/features/geofencing/widgets/geofence_sign_in_sheet.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/attendance_classroom_scope.dart';
import 'package:wowcare/core/util/attendance_events.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/get_conversations_entity_usecase.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_transfer_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_mark_absent_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_entity.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_attendance_action_availability.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity_display.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/usecases/watch_conversations_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/get_cached_conversations_entity_usecase.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/screens/conversation_thread_screen.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';
import 'package:wowcare/src/app_router.dart';
import '../../../../../core/util/core_utils.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/server_time_service.dart';

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

class _MyDayCardState extends State<MyDayCard> with WidgetsBindingObserver {
  // Token / generation counter to invalidate stale async operations on persona switch
  int _profileGeneration = 0;

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

  void _resetForProfileSwitch() {
    _profileGeneration++;
    setState(() {
      _signInStatusLoaded = false;
      _staffIdentityLoaded = false;
      _todayStatusRaw = null;
      _isSignedIn = false;
      _staffCode = '';
      _userCode = '';
      _staffDisplayName = '';
      _staffDesignation = '';
      _geofencePopupShownThisEntry = false;
    });
  }

  // ---- sign-in status ----
  bool _isSignedIn = false;

  // True once the async today-sign-in-status fetch in `_loadStaffIdentity`
  // has resolved (success or failure) at least once. `_isSignedIn` defaults
  // to false until then, so the geofence-entry popup must not trust it (and
  // must not decide "show" or "don't show") until this is true — otherwise
  // an already-signed-in user restarting the app inside the geofence (e.g.
  // GeofenceCubit reporting `withinRange` from a cached last-known location
  // before the attendance API call resolves) would incorrectly see the
  // Sign-In sheet.
  bool _signInStatusLoaded = false;

  // Raw today-status string from the API (e.g. SIGNED_IN, ABSENT,
  // SIGNED_OUT). Kept alongside `_isSignedIn` because the boolean alone
  // can't distinguish "not signed in" from "already marked absent today",
  // which the attendance gate below needs to disable actions correctly.
  String? _todayStatusRaw;

  /// Same gate used by the admin attendance pop-up
  /// ([StaffAttendanceVerticalPopupOnly] via `staff_attendance_profile.dart`)
  /// so self-service Sign-In/Sign-Out/Transfer/Mark-Absent rules stay
  /// consistent across both surfaces.
  StaffAttendanceGate get _todayGate => staffAttendanceGateFromTodayStatus(
    isActiveProfile: true,
    todayStatusRaw: _todayStatusRaw,
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
      !_staffIdentityLoaded ||
      _effectiveStaffCode.isEmpty ||
      !_availability(geofenceState).absentEnabled;

  // Cached staff identity — loaded once in initState so button taps never hit
  // a timing window where storage hasn't resolved yet.
  String _staffCode = '';
  // Pure admins (role == 'admin', not also 'staff') have no staff profile, so
  // StorageKeys.staffCode is legitimately empty for them — StorageKeys.userCode
  // is used as their self-attendance identity instead.
  String _userCode = '';

  /// The identity used for self-attendance actions (Sign-In/Sign-Out/Transfer/
  /// Mark Absent): the real staffCode when the user has a staff profile,
  /// falling back to their userCode for staff-less personas (pure admins).
  String get _effectiveStaffCode =>
      _staffCode.isNotEmpty ? _staffCode : _userCode;
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
    WidgetsBinding.instance.addObserver(this);
    AttendanceEvents.tick.addListener(_handleAttendanceChanged);
    unawaited(_loadClockPin());
    unawaited(_loadStaffIdentity());
  }

  void _handleAttendanceChanged() {
    if (!mounted) return;
    unawaited(_loadClockPin());
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
    final generation = ++_profileGeneration;
    final storage = serviceLocator<StorageService>();
    String code = await resolveStaffCodeForLoggedInUser();
    if (code.isEmpty) {
      code = (await storage.getString(StorageKeys.staffCode))?.trim() ?? '';
    }
    final userCode =
        (await storage.getString(StorageKeys.userCode))?.trim() ?? '';
    final name = (await storage.getString(StorageKeys.displayName) ?? '')
        .trim();
    final designation =
        (await storage.getString(StorageKeys.staffDesignation) ?? '').trim();
    if (!mounted || generation != _profileGeneration) return;
    setState(() {
      _staffCode = code;
      _userCode = userCode;
      _staffDisplayName = name;
      _staffDesignation = designation;
      _staffIdentityLoaded = true;
    });
    final effectiveCode = _effectiveStaffCode;
    if (effectiveCode.isEmpty) {
      if (mounted && generation == _profileGeneration) {
        setState(() {
          _todayStatusRaw = null;
          _isSignedIn = false;
          _signInStatusLoaded = true;
        });
      }
      return;
    }
    try {
      final useCase = serviceLocator<GetStaffTodaySignInStatusUseCase>();
      final status = await useCase(staffCode: effectiveCode);
      if (!mounted || generation != _profileGeneration) return;
      final signedIn = status?.toUpperCase() == 'SIGNED_IN';
      setState(() {
        _todayStatusRaw = status;
        _isSignedIn = signedIn;
        _signInStatusLoaded = true;
      });
      unawaited(
        context.read<GeofenceCubit>().updateStaffSignInStatus(signedIn),
      );
    } catch (_) {
      // sign-in status check is best-effort
      if (mounted && generation == _profileGeneration) {
        setState(() => _signInStatusLoaded = true);
      }
    }
    if (!mounted || generation != _profileGeneration) return;
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
    if (!_signInStatusLoaded) return;
    if (!_staffIdentityLoaded) return;
    if (_effectiveStaffCode.isEmpty) return;
    if (_isSignedIn) return;
    if (_todayStatusRaw?.toUpperCase() == 'SIGNED_IN') return;
    if (_geofencePopupShownThisEntry) return;

    final geofenceState = context.read<GeofenceCubit>().state;
    if (geofenceState.isSignInStatusLoading) return;
    if (geofenceState.status != GeofenceCubitStatus.withinRange) return;
    if (geofenceState.isStaffSignedIn) return;

    _geofencePopupShownThisEntry = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_signInStatusLoaded || !_staffIdentityLoaded || _isSignedIn) return;
      unawaited(
        GeofenceSignInSheet.show(context, role: 'staff', isSignedIn: false),
      );
    });
  }

  Future<void> _openTransferForSelf() async {
    if (_effectiveStaffCode.isEmpty) {
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
            staffCode: _effectiveStaffCode,
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
        message: 'Unable to find your staff profile to mark absent.',
        isWarning: true,
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StaffMarkAbsentForm(staff: staff)),
    );
    if (mounted) {
      await _loadStaffIdentity();
      if (mounted) {
        unawaited(context.read<GeofenceCubit>().checkStaffSignInStatus());
      }
    }
  }

  StaffEntity? _buildSelfStaffEntity() {
    if (_effectiveStaffCode.isEmpty) return null;
    return StaffEntity(
      id: 0,
      name: _staffDisplayName.isNotEmpty ? _staffDisplayName : '—',
      primaryRoomId: 0,
      designation: _staffDesignation.isNotEmpty ? _staffDesignation : 'Staff',
      staffCode: _effectiveStaffCode,
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
        message: 'Unable to find your staff profile.',
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
            _resetForProfileSwitch();
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
            child: SkeuPanel(
              radius: SkeuRadius.xxl,

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
                      _ReminderToggleButton(staffCode: _staffCode),
                      const SizedBox(height: 8),

                      // ── Work time chip ───────────────────────────────────────
                      _CustomChip(
                        label: 'Work Time : $_workTime',
                        labelStyle: const TextStyle(
                          color: AppColors.secondaryColor,
                        ),
                        color: const Color.fromRGBO(172, 234, 236, 0.3),
                      ),
                      const SizedBox(height: 8),

                      // ── Break time chip ──────────────────────────────────────
                      _CustomChip(
                        label: 'Break Time : $_breakTime',
                        labelStyle: const TextStyle(
                          color: AppColors.secondaryColor,
                        ),
                        color: const Color.fromRGBO(172, 234, 236, 0.3),
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
                          final StaffAttendanceActionAvailability availability =
                              _availability(geofenceState);
                          final Map<String, String> disabledReasons =
                              _disabledReasons(geofenceState);
                          final bool markAbsentDisabled = _markAbsentDisabled(
                            geofenceState,
                          );
                          // Sign button toggles Sign-In/Sign-Out depending on
                          // today's status; enable per the action it currently represents.
                          final bool signButtonEnabled =
                              (isStaff || isAdmin) &&
                              (_isSignedIn
                                  ? availability.signOutEnabled
                                  : availability.signInEnabled);
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
                                          child: Tooltip(
                                            message:
                                                availability.transferEnabled
                                                ? ''
                                                : disabledReasons['Transfer'] ??
                                                      '',
                                            child: OutlinedButton.icon(
                                              onPressed:
                                                  (!_staffIdentityLoaded ||
                                                      _effectiveStaffCode
                                                          .isEmpty ||
                                                      !availability
                                                          .transferEnabled)
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
                                          ),
                                        )
                                      else if (showSecondaryButtons &&
                                          !_isSignedIn)
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
                                                onPressed: markAbsentDisabled
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      markAbsentDisabled
                                                      ? Colors.grey[600]
                                                      : AppColors.themeColor,
                                                  side: BorderSide(
                                                    color: markAbsentDisabled
                                                        ? Colors.grey[400]!
                                                        : AppColors.themeColor,
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
                                                  textStyle: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                              disabledReasons[_isSignedIn
                                                  ? 'Sign-Out'
                                                  : 'Sign-in'] ??
                                              'You are not within geofencing Range',
                                          onDisabledConfirmTap: () {
                                            CoreUtils.showTopSnackBar(
                                              isWarning: true,
                                              message:
                                                  disabledReasons[_isSignedIn
                                                      ? 'Sign-Out'
                                                      : 'Sign-in'] ??
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

                  const SizedBox(height: 10),

                  // ── Latest chat preview ──────────────────────────────────────
                  const _CommunicationRowWidget(),
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

// Shows the logged-in user's latest conversations (up to 2) using the same row representation as
// the messaging inbox (avatar + title + last message + time + unread). Tapping a row opens that
// conversation thread. Empty → "No recent chat".
class _CommunicationRowWidget extends StatefulWidget {
  const _CommunicationRowWidget();

  @override
  State<_CommunicationRowWidget> createState() =>
      _CommunicationRowWidgetState();
}

class _CommunicationRowWidgetState extends State<_CommunicationRowWidget> {
  StreamSubscription<List<ConversationEntity>>? _sub;
  List<ConversationEntity> _items = const [];
  bool _loading = true;
  String _currentUserCode = '';
  Timer? _timeout;

  /// The staff member's own primary classroom — its Classroom Notes
  /// conversation (if any) is always shown as the first row, regardless of
  /// recency, so a staff member never has to go hunting for their own
  /// classroom's Notes. Null for admin/unscoped personas or before this
  /// resolves; see [resolveStaffPrimaryClassroomCode]'s own fail-open
  /// contract.
  String? _primaryClassroomCode;

  /// Classroom code → name, resolved once so the primary classroom's Notes
  /// row can show the classroom's actual name instead of the generic
  /// "Classroom" fallback `displayTitle` uses for CLASSROOM_CHAT.
  final Map<String, String> _classroomNames = <String, String>{};

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timeout?.cancel();
    super.dispose();
  }

  /// Mirrors the messaging inbox: seed from the Isar cache for a fast first frame, then watch the
  /// Firestore inbox in realtime. Uses type: null so all conversation types are fetched — the REST
  /// `GET /conversations` list can come back empty for staff, but the Firestore inbox does not.
  /// [_buildDisplayItems] pins the staff member's own primary classroom's Notes (if any) as the
  /// first row and fills the rest with the most recent other conversation(s).
  Future<void> _init() async {
    final storage = serviceLocator<StorageService>();
    _currentUserCode =
        (await storage.getString(StorageKeys.userCode))?.trim() ?? '';

    // Fire-and-forget: don't block the fast cache-first-frame path below.
    // Re-applies _buildDisplayItems once either resolves so already-loaded
    // items get retroactively re-ranked.
    unawaited(
      resolveStaffPrimaryClassroomCode(storage: storage)
          .then((code) {
            if (!mounted) return;
            setState(() {
              _primaryClassroomCode = code;
              _items = _buildDisplayItems(_items);
            });
          })
          .catchError((_) {}),
    );
    unawaited(
      storage.getString(StorageKeys.schoolCode).then((schoolCode) async {
        final trimmed = (schoolCode ?? '').trim();
        if (trimmed.isEmpty) return;
        try {
          final classrooms = await serviceLocator<GetActiveClassroomsUseCase>()(
            schoolCode: trimmed,
            onlyTypeClassroom: false,
          );
          if (!mounted) return;
          setState(() {
            _classroomNames.addAll({
              for (final c in classrooms) c.code: c.name,
            });
          });
        } catch (_) {
          // Best-effort — the Notes row falls back to "Classroom".
        }
      }),
    );

    _timeout = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() => _loading = false);
      }
    });

    try {
      final cached = await serviceLocator<GetCachedConversationsEntityUseCase>()
          .call();
      cached.fold((_) {}, (list) {
        if (mounted) {
          setState(() {
            _items = _buildDisplayItems(list);
            _loading = false;
          });
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }

    // Fallback to REST API concurrently in case Firestore fails or is empty.
    unawaited(
      serviceLocator<GetConversationsEntityUseCase>().call().then((result) {
        if (!mounted) return;
        result.fold((_) {}, (list) {
          setState(() {
            // If REST API found chats, merge them with current items to ensure
            // we don't miss anything, and take the top 2 most recent.
            if (list.isNotEmpty) {
              _items = _buildDisplayItems([..._items, ...list]);
              _loading = false;
            }
          });
        });
      }),
    );

    _sub = serviceLocator<WatchConversationsUseCase>().call().listen(
      (list) {
        if (!mounted) return;
        _timeout?.cancel();
        setState(() {
          // If Firestore returns items, use them (merged to preserve names if needed).
          // If it returns empty, only overwrite if we didn't get any from REST/Cache.
          if (list.isNotEmpty) {
            _items = _buildDisplayItems([..._items, ...list]);
          }
          _loading = false;
        });
      },
      onError: (_) {
        if (!mounted) return;
        _timeout?.cancel();
        setState(() => _loading = false);
      },
      onDone: () {
        if (!mounted) return;
        _timeout?.cancel();
        setState(() => _loading = false);
      },
    );
  }

  /// Ranks a conversation by its own last MESSAGE, never `updatedAt`.
  /// `updatedAt` is a generic "last modified" stamp that background sync
  /// (unread-count reconciliation, participant/read-receipt updates, a
  /// Firestore re-sync of the per-user inbox) can bump with NO new message
  /// at all — using it as a recency fallback let a conversation nobody had
  /// actually messaged in briefly jump to the top the moment one of those
  /// unrelated fields ticked, then fall back once the next snapshot arrived
  /// — the exact "keeps changing, not actually the most recent chat"
  /// symptom. A conversation with no messages yet (`lastMessageAt == null`)
  /// ranks as the oldest possible instant instead, so it can never
  /// out-rank one with real activity.
  DateTime _rankTime(ConversationEntity conversation) =>
      conversation.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Row 1: the staff member's own primary classroom's Notes conversation —
  /// pinned regardless of recency, so it's always reachable from here
  /// rather than only when it happens to be the most recently active
  /// conversation. Row 2: the single most recent OTHER conversation
  /// (Room Chat/Staff Direct/Admin Chat, or a different classroom's Notes).
  /// Falls back to the two most recent conversations overall when this
  /// staff member has no primary classroom (admin/unscoped persona) or its
  /// Notes conversation isn't in [list] yet.
  List<ConversationEntity> _buildDisplayItems(List<ConversationEntity> list) {
    // Callers pass `[..._items, ...freshSnapshot]` — the OLD top-2 selection
    // first, the fresh cache/REST/Firestore data second. Cache, REST, and
    // the live Firestore watch all resolve independently and can arrive in
    // ANY order (a slow REST fallback can land after Firestore already
    // delivered a newer snapshot) — so dedup can't just trust arrival
    // position either way: "keep the first copy seen" freezes a
    // conversation at whatever it was the moment it first entered `_items`
    // (later messages never surface); "keep the last copy seen" is just as
    // wrong the moment a stale response resolves AFTER a fresher one,
    // silently reverting back. Compare each duplicate's own timestamp
    // instead and keep whichever is actually more recent — the only
    // ordering that can't be defeated by network/cache timing.
    final byCode = <String, ConversationEntity>{};
    for (final item in list) {
      final code = item.code.trim();
      if (code.isEmpty) continue;
      final existing = byCode[code];
      if (existing == null || !_rankTime(item).isBefore(_rankTime(existing))) {
        byCode[code] = item;
      }
    }
    final unique = byCode.values.toList();
    unique.sort((a, b) => _rankTime(b).compareTo(_rankTime(a)));

    final primaryClassroom = _primaryClassroomCode?.trim();
    ConversationEntity? primaryNotes;
    if (primaryClassroom != null && primaryClassroom.isNotEmpty) {
      for (final item in unique) {
        if (item.type == ConversationType.classroomChat &&
            item.classroomCode?.trim() == primaryClassroom) {
          primaryNotes = item;
          break;
        }
      }
    }

    if (primaryNotes == null) {
      // No primary classroom, or its Notes conversation hasn't loaded into
      // [list] yet — degrade to the two most recent conversations overall.
      return unique.take(2).toList(growable: false);
    }
    final mostRecentOther = unique
        .where((item) => item.code != primaryNotes!.code)
        .firstOrNull;

    return [
      primaryNotes,
      if (mostRecentOther != null) mostRecentOther,
    ].take(2).toList(growable: false);
  }

  String _displayTitle(ConversationEntity conversation) {
    if (conversation.type == ConversationType.classroomChat) {
      final classroomCode = conversation.classroomCode?.trim() ?? '';
      if (classroomCode.isNotEmpty) {
        final classroomName = _classroomNames[classroomCode]?.trim();
        if (classroomName != null && classroomName.isNotEmpty) {
          return classroomName;
        }
      }
      // _classroomNames is a separate, fire-and-forget fetch that races the
      // conversation list — this row could render before it resolves (or if
      // it fails, never gets it at all). The conversation's OWN stored
      // title is set to the classroom's name at creation time
      // (GetOrCreateClassroomChatUseCase) and doesn't depend on that second
      // fetch succeeding, so try it before giving up to the generic
      // "Classroom" label — displayTitle already does exactly this for
      // every other conversation type below, CLASSROOM_CHAT just never
      // reached it.
      return conversation.displayTitle(_currentUserCode, fallback: 'Classroom');
    }
    return conversation.displayTitle(_currentUserCode);
  }

  void _openConversation(ConversationEntity conversation) {
    if (conversation.type == ConversationType.classroomChat &&
        (conversation.classroomCode ?? '').trim().isNotEmpty) {
      // Classroom Notes lives on the Classroom screen's own Notes tab (tab
      // index 2 — see AppRoutes.classroom's route definition), not as a
      // standalone thread — matches how every other Notes entry point in
      // the app (notifications, the Classrooms list) opens it.
      context.go(
        '${AppRoutes.classroom}?classroomCode=${conversation.classroomCode!.trim()}&tab=2',
      );
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ConversationThreadScreen(conversation: conversation),
      ),
    );
  }

  // Compact relative time for the preview row.
  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = AppTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(local.year, local.month, local.day);
    final diff = today.difference(msgDay).inDays;
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final time = '$hh:$mm';
    if (diff == 0) return time;
    if (diff == 1) return 'Yesterday';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (diff < 7) return days[local.weekday - 1];
    return '${local.day}/${local.month}/${local.year % 100}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        color: Color.fromRGBO(39, 190, 193, 0.05),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(
              Icons.forum_outlined,
              size: 20,
              color: AppColors.primaryColor.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 10),
            Text(
              'No recent chat',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (int i = 0; i < _items.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.primaryColor.withValues(alpha: 0.06),
            ),
          _RecentChatRow(
            conversation: _items[i],
            timeLabel: _formatTime(_items[i].lastMessageAt),
            onTap: () => _openConversation(_items[i]),
            currentUserCode: _currentUserCode,
            displayTitle: _displayTitle(_items[i]),
          ),
        ],
      ],
    );
  }
}

class _RecentChatRow extends StatelessWidget {
  const _RecentChatRow({
    required this.conversation,
    required this.timeLabel,
    required this.onTap,
    required this.currentUserCode,
    required this.displayTitle,
  });

  final ConversationEntity conversation;
  final String timeLabel;
  final VoidCallback onTap;
  final String currentUserCode;
  final String displayTitle;

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            DocumentImageWidget(
              fileUuid: conversation.avatarUrl,
              name: displayTitle,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayTitle,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (timeLabel.isNotEmpty)
                        Text(
                          timeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          MessageContentProcessor.previewText(
                            conversation.lastMessagePreview,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B894),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
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

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

class _ReminderToggleButton extends StatefulWidget {
  const _ReminderToggleButton({required this.staffCode});

  final String staffCode;

  @override
  State<_ReminderToggleButton> createState() => _ReminderToggleButtonState();
}

class _ReminderToggleButtonState extends State<_ReminderToggleButton> {
  bool _isLoading = false;
  bool _reminderEnabled = false;

  Future<void> _toggleReminder() async {
    if (_isLoading || widget.staffCode.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final cubit = serviceLocator<WorkBreakReminderCubit>();
      await cubit.toggleReminder(
        staffCode: widget.staffCode,
        currentEnabled: _reminderEnabled,
      );

      if (mounted) {
        final state = cubit.state;
        if (state.isSuccess) {
          setState(() => _reminderEnabled = state.enabled);
          final message = state.enabled
              ? 'Turn on Reminder'
              : 'Turn off Reminder';
          CoreUtils.showTopSnackBar(
            context: context,
            message: message,
            isSuccess: true,
          );
        } else if (state.isFailure && state.message != null) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: state.message!,
            isWarning: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Error: ${e.toString()}',
          isWarning: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleReminder,
        borderRadius: BorderRadius.circular(100),
        splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
        child: Opacity(
          opacity: _isLoading ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    _reminderEnabled ? 'Turn off Reminder' : 'Send reminder',
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
    // A read-only figure, so it sits in a recessed well rather than on a
    // raised plate: nothing here is pressable.
    return SkeuWell(
      radius: SkeuRadius.pill,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withValues(alpha: .45)],
      ),
      insets: SkeuElevation.wellSm,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(label, style: labelStyle, overflow: TextOverflow.ellipsis),
    );
  }
}
