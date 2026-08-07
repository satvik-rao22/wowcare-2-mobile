import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/my_childs_day_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/qr_scan_button.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_cubit.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';
import 'package:wowcare/presentation/features/geofencing/widgets/geofence_sign_in_sheet.dart';
import '../../../../../core/util/storage_keys.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/attendance_events.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_today_sign_in_status_map_usecase.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_sign_in_form.dart'
    as student_sign_in;
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_sign_out_form.dart'
    as student_sign_out;

import 'package:wowcare/domain/features/student/entities/student_regular_schedule.dart';

import 'dashboard_error_chip.dart';
import 'package:wowcare/core/util/server_time_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _twoDigits(int n) => n.toString().padLeft(2, '0');

/// Robust day-of-week → Dart weekday mapping.
/// Supports both full names (MONDAY) and 3-letter abbreviations (MON).
const _kDayToWeekday = <String, int>{
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

/// Returns the full display name for a Dart weekday integer.
String _getDayName(int weekday) {
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

/// Finds the schedule for [weekday] from [all].
/// Returns null when not found or when times are unset (all zeros).
StudentRegularScheduleEntry? _resolveScheduleForDay(
  int weekday,
  List<StudentRegularScheduleEntry> all,
) {
  for (final entry in all) {
    if (_kDayToWeekday[entry.dayOfWeek.trim().toUpperCase()] != weekday)
      continue;

    // Reject if EITHER start OR end time is completely unset (0:00)
    final startTimeSet = entry.startHour != 0 || entry.startMinute != 0;
    final endTimeSet = entry.endHour != 0 || entry.endMinute != 0;

    if (!startTimeSet || !endTimeSet) {
      continue;
    }

    return entry;
  }
  return null;
}

class MyChildsDayCard extends StatefulWidget {
  const MyChildsDayCard({super.key});

  @override
  State<MyChildsDayCard> createState() => _MyChildsDayCardState();
}

class _MyChildsDayCardState extends State<MyChildsDayCard>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  // Token / generation counter to invalidate stale async operations on persona switch
  int _profileGeneration = 0;

  bool _isMinimized = false;
  String _selectedChildCode = '';
  bool _didLoadCommunication = false;

  // Children sign-in status map
  Map<String, String> _childrenSignInStatusMap = {};

  // True once `_loadChildrenSignInStatus` has resolved (success or failure)
  // at least once. `_childrenSignInStatusMap` (and therefore
  // `_isSelectedChildSignedIn`) defaults to "not signed in" until then, so
  // the geofence-entry popup must not decide "show" or "don't show" based
  // on it until this is true — otherwise a guardian restarting the app
  // inside the geofence with an already-signed-in child (e.g. GeofenceCubit
  // reporting `withinRange` from a cached last-known location before the
  // attendance API call resolves) would incorrectly see the Sign-In sheet.
  bool _signInStatusLoaded = false;
  bool _geofencePopupShownThisEntry = false;

  Timer? _countdownTimer;
  final ValueNotifier<String> _statusText = ValueNotifier<String>(
    'Loading schedule...',
  );
  final ValueNotifier<Duration> _duration = ValueNotifier<Duration>(
    Duration.zero,
  );

  // Reminder toggle
  bool _isReminder = false;

  // Prevents didChangeDependencies from stacking multiple geofence-init
  // callbacks when ancestor InheritedWidgets rebuild.
  bool _geofenceInitScheduled = false;

  // Dedup guard for sign-in status loads: tracks the last set of codes we
  // fetched so that context.watch<MyChildsDayCubit>() firing every second
  // (clock timer) does not re-trigger the attendance API on each tick.
  List<String> _lastSignInStatusCodes = [];
  int _lastRefreshNonce = 0;

  // In-flight gate: prevents concurrent network requests when multiple
  // call sites (BlocListener, app-resume, post-sign-in) fire in rapid
  // succession.  Reset in finally so a failed request always unblocks.
  bool _isSignInStatusLoading = false;

  /// Returns true when the selected child is currently signed in.
  bool get _isSelectedChildSignedIn {
    final code = _selectedChildCode.trim();
    if (code.isEmpty) return false;
    return (_childrenSignInStatusMap[code] ?? '').toUpperCase() == 'SIGNED_IN';
  }

  /// Returns true when all children in the map are signed in.
  bool get _areAllChildrenSignedIn {
    if (_childrenSignInStatusMap.isEmpty) return false;
    return _childrenSignInStatusMap.values.every(
      (status) => status.toUpperCase() == 'SIGNED_IN',
    );
  }

  void _resetForProfileSwitch() {
    _profileGeneration++;
    setState(() {
      _signInStatusLoaded = false;
      _childrenSignInStatusMap = {};
      _lastSignInStatusCodes = [];
      _geofencePopupShownThisEntry = false;
      _isSignInStatusLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AttendanceEvents.tick.addListener(_handleAttendanceChanged);
  }

  void _handleAttendanceChanged() {
    if (!mounted) return;
    final childCodes = Provider.of<ParentChildCubit>(
      context,
      listen: false,
    ).children.map((c) => c.code).toList();
    if (childCodes.isNotEmpty) {
      _lastSignInStatusCodes = [];
      unawaited(_loadChildrenSignInStatus(childCodes));
    }
    if (_selectedChildCode.isNotEmpty) {
      try {
        unawaited(
          context.read<MyChildsDayCubit>().loadForChild(
            studentCode: _selectedChildCode,
          ),
        );
      } catch (_) {}
    }
  }

  // Re-checks sign-in status the moment the app comes back to the
  // foreground — covers the case where a child was signed in/out from the
  // web (or another device) while this app was backgrounded, so the button
  // doesn't stay stuck showing the stale state.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    final childCodes = Provider.of<ParentChildCubit>(
      context,
      listen: false,
    ).children.map((c) => c.code).toList();
    if (childCodes.isNotEmpty) {
      unawaited(_loadChildrenSignInStatus(childCodes));
    }
    if (_selectedChildCode.isNotEmpty) {
      unawaited(
        context.read<MyChildsDayCubit>().loadForChild(
          studentCode: _selectedChildCode,
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parentChildProvider = Provider.of<ParentChildCubit>(context);
    final parentChildState = parentChildProvider.state;
    if (parentChildState.refreshNonce != _lastRefreshNonce) {
      _lastRefreshNonce = parentChildState.refreshNonce;
      _lastSignInStatusCodes = [];
    }
    final selectedChild = parentChildProvider.selectedChild;
    final nextChildCode = (selectedChild?.code ?? '').trim();
    if (nextChildCode != _selectedChildCode) {
      _selectedChildCode = nextChildCode;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          context.read<MyChildsDayCubit>().loadForChild(
            studentCode: nextChildCode,
          ),
        );
      });
    }
    // Load sign-in status only when the set of child codes has actually
    // changed. Without this guard, context.watch<MyChildsDayCubit>() in
    // build() causes didChangeDependencies to fire every second (clock timer),
    // which would trigger the attendance API on every tick.
    final allChildCodes = parentChildProvider.children
        .map((c) => c.code)
        .toList();
    final sortedKey = (List<String>.from(allChildCodes)..sort()).join(',');
    final lastKey = (List<String>.from(
      _lastSignInStatusCodes,
    )..sort()).join(',');
    if (allChildCodes.isNotEmpty && sortedKey != lastKey) {
      _lastSignInStatusCodes = List<String>.from(allChildCodes);
      unawaited(_loadChildrenSignInStatus(allChildCodes));
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
      if (schoolCode.isEmpty) return;
      if (!mounted) return;

      // Initialize GPS geofencing with the school code
      await context.read<GeofenceCubit>().initForSchool(schoolCode: schoolCode);
    } catch (_) {
      // Geofencing is best-effort; ignore init failures.
    }
  }

  Future<void> _loadChildrenSignInStatus(List<String> childCodes) async {
    final cleanCodes = childCodes
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (cleanCodes.isEmpty || _isSignInStatusLoading) return;

    final generation = ++_profileGeneration;
    _isSignInStatusLoading = true;
    context.read<GeofenceCubit>().setSignInStatusLoading(true);
    try {
      final useCase = serviceLocator<GetStudentTodaySignInStatusMapUseCase>();
      final map = await useCase(studentCodes: cleanCodes);
      if (!mounted || generation != _profileGeneration) return;
      setState(() {
        _childrenSignInStatusMap = map;
        _signInStatusLoaded = true;
      });
      final allSignedIn = cleanCodes.every(
        (code) => (map[code] ?? '').toUpperCase() == 'SIGNED_IN',
      );
      unawaited(
        context.read<GeofenceCubit>().updateChildrenSignInStatus(allSignedIn),
      );
    } catch (_) {
      // If status check fails, keep empty map
      if (mounted && generation == _profileGeneration) {
        setState(() => _signInStatusLoaded = true);
      }
      if (mounted) {
        context.read<GeofenceCubit>().setSignInStatusLoading(false);
      }
    } finally {
      if (generation == _profileGeneration) {
        _isSignInStatusLoading = false;
      }
    }
    if (!mounted || generation != _profileGeneration) return;
    // Covers the race where the geofence-entry listener fired (and skipped
    // showing the sheet) while this fetch was still in flight — re-evaluate
    // now that the real sign-in status is known.
    _maybeShowChildSignInPopup();
  }

  /// Shows the geofence Sign-In sheet only when: the selected child is
  /// currently within the school geofence, their today-sign-in status has
  /// finished loading and shows them as not signed in. Called both from the
  /// [GeofenceCubit] entry-transition listener and right after
  /// [_loadChildrenSignInStatus]'s async fetch resolves, so whichever of the
  /// two finishes last is the one that actually decides whether to show it.
  void _maybeShowChildSignInPopup() {
    if (!mounted) return;
    if (!_signInStatusLoaded) return;
    if (_geofencePopupShownThisEntry) return;

    final parentChildProvider = Provider.of<ParentChildCubit>(
      context,
      listen: false,
    );
    if (parentChildProvider.state.isLoading) return;
    final children = parentChildProvider.children;
    if (children.isEmpty) return;

    final selectedChild = parentChildProvider.selectedChild;
    if (selectedChild == null || selectedChild.code.trim().isEmpty) return;

    final childCode = selectedChild.code.trim();
    if (!_childrenSignInStatusMap.containsKey(childCode)) return;

    if (_isSelectedChildSignedIn) return;
    if (_areAllChildrenSignedIn) return;

    final geofenceState = context.read<GeofenceCubit>().state;
    if (geofenceState.isSignInStatusLoading) return;
    if (geofenceState.status != GeofenceCubitStatus.withinRange) return;
    if (geofenceState.allChildrenSignedIn) return;

    _geofencePopupShownThisEntry = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_signInStatusLoaded ||
          _isSelectedChildSignedIn ||
          _areAllChildrenSignedIn) {
        return;
      }
      unawaited(
        GeofenceSignInSheet.show(
          context,
          role: 'parent',
          isSignedIn: false,
          studentName: selectedChild.name,
        ),
      );
    });
  }

  /// Re-checks sign-in status for [children] and reloads the selected
  /// child's schedule — called right after a sign-in/out form succeeds (via
  /// `refreshCallback`) and again once the form's route closes, so the
  /// Sign-In/Sign-Out button flips immediately instead of staying stale.
  void _refreshSignInStatusAfterAction(List<ParentChildRef> children) {
    final codes = children
        .map((c) => c.code.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (codes.isNotEmpty) {
      unawaited(_loadChildrenSignInStatus(codes));
    }
    if (_selectedChildCode.isNotEmpty) {
      unawaited(
        context.read<MyChildsDayCubit>().loadForChild(
          studentCode: _selectedChildCode,
        ),
      );
    }
  }

  void _stopCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _startCountdownTimer({
    required String schoolTimeZone,
    required List<StudentRegularScheduleEntry> allSchedules,
  }) {
    _stopCountdownTimer();

    void tick() {
      final schoolNow = SchoolZoneDateTime.dateTimeFromInstantInSchool(
        ServerTimeService.instance.nowUtc(),
        schoolTimeZone,
      );
      final result = _computeCountdownFromSchedule(
        schoolNow: schoolNow,
        schoolTimeZone: schoolTimeZone,
        allSchedules: allSchedules,
      );
      _statusText.value = result.statusText;
      _duration.value = result.duration;
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  /// Countdown using ONLY student schedules with school timezone.
  ///
  /// Uses school timezone for calculating current time.
  /// Uses ONLY student schedules API (never school regular schedule).
  /// Priority:
  ///   1. Today's student schedule if it exists and hasn't passed
  ///   2. Today's student schedule if currently active (count down to end)
  ///   3. Nearest upcoming student schedule (within next 7 days)
  ///   4. Empty state if no student schedules exist
  ({String statusText, Duration duration}) _computeCountdownFromSchedule({
    required DateTime schoolNow,
    required String schoolTimeZone,
    required List<StudentRegularScheduleEntry> allSchedules,
  }) {
    final todayWeekday = schoolNow.weekday; // 1 = Monday, 7 = Sunday

    // Find today's student schedule (ONLY from student schedules)
    final todaySchedule = _resolveScheduleForDay(todayWeekday, allSchedules);

    // ── Case 1: Today has a student schedule ──────────────────────────────
    if (todaySchedule != null) {
      // Build today's schedule times using school timezone's date
      final startDt = DateTime(
        schoolNow.year,
        schoolNow.month,
        schoolNow.day,
        todaySchedule.startHour,
        todaySchedule.startMinute,
        0,
      );
      final endDt = DateTime(
        schoolNow.year,
        schoolNow.month,
        schoolNow.day,
        todaySchedule.endHour,
        todaySchedule.endMinute,
        0,
      );

      // If schedule hasn't started yet
      if (schoolNow.isBefore(startDt)) {
        return (
          statusText: 'School starts in',
          duration: startDt.difference(schoolNow),
        );
      }

      // If schedule is currently active
      if (schoolNow.isBefore(endDt)) {
        return (
          statusText: 'School ends in',
          duration: endDt.difference(schoolNow),
        );
      }
      // Today's schedule already passed → fall through to the next-schedule search.
    }

    // ── Case 2: Find nearest upcoming schedule (ONLY from student schedules) ──
    return _findNextStudentSchedule(schoolNow, todayWeekday, allSchedules);
  }

  /// Searches forward 1–7 days for the nearest upcoming scheduled day.
  ({String statusText, Duration duration}) _findNextStudentSchedule(
    DateTime now,
    int todayWeekday,
    List<StudentRegularScheduleEntry> allSchedules,
  ) {
    if (allSchedules.isEmpty) {
      return (statusText: 'No schedules available', duration: Duration.zero);
    }

    // Build maps: weekday → schedule
    final schedulesByWeekday = <int, StudentRegularScheduleEntry>{};

    for (final entry in allSchedules) {
      final wd = _kDayToWeekday[entry.dayOfWeek.trim().toUpperCase()];
      if (wd != null) {
        schedulesByWeekday[wd] = entry;
      }
    }

    if (schedulesByWeekday.isEmpty) {
      return (statusText: 'No schedules available', duration: Duration.zero);
    }

    // Search next 7 days for upcoming schedule (starting tomorrow)
    for (int daysAhead = 1; daysAhead <= 7; daysAhead++) {
      final futureDate = now.add(Duration(days: daysAhead));
      final futureWeekday = futureDate.weekday;

      if (schedulesByWeekday.containsKey(futureWeekday)) {
        final schedule = schedulesByWeekday[futureWeekday]!;
        final startDt = DateTime(
          futureDate.year,
          futureDate.month,
          futureDate.day,
          schedule.startHour,
          schedule.startMinute,
          0,
        );

        final nextDayName = _getDayName(futureWeekday);
        final statusText = daysAhead == 1
            ? 'Tomorrow\'s school starts in'
            : '$nextDayName starts in';

        return (statusText: statusText, duration: startDt.difference(now));
      }
    }

    return (statusText: 'No schedules available', duration: Duration.zero);
  }

  @override
  void dispose() {
    AttendanceEvents.tick.removeListener(_handleAttendanceChanged);
    WidgetsBinding.instance.removeObserver(this);
    _stopCountdownTimer();
    _statusText.dispose();
    _duration.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  // ----- Timer display -----

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 48,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
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
        _buildTimeUnit(_twoDigits(duration.inHours.remainder(24)), 'HH'),
        _buildTimeSeparator(),
        _buildTimeUnit(_twoDigits(duration.inMinutes.remainder(60)), 'MM'),
        _buildTimeSeparator(),
        _buildTimeUnit(_twoDigits(duration.inSeconds.remainder(60)), 'SS'),
      ],
    );
  }

  // ----- Student detail row -----

  // Widget _buildStudentDetailContainer({
  //   required String studentName,
  //   required String classroomName,
  //   required String dayOfWeek,
  //   required String todayScheduleRange,
  //   required String schoolTimeZone,
  //   required DateTime? schoolNow,
  //   required String studentStatus,
  // }) {
  //   final statusColor = studentStatus == 'Upcoming'
  //       ? const Color.fromARGB(255, 253, 205, 22)
  //       : studentStatus == 'Active'
  //       ? const Color.fromRGBO(0, 177, 21, 1)
  //       : null;
  //   final scheduleLabel = todayScheduleRange.trim().isNotEmpty
  //       ? todayScheduleRange.trim()
  //       : 'No schedule';

  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       // LEFT: profile photo with status dot
  //       Stack(
  //         children: [
  //           DocumentImageWidget(
  //             fileUuid: '',
  //             name: studentName,
  //             size: 90,
  //             fontSize: 28,
  //             disableProfileLookupFallback: true,
  //             disableAttendanceStatusLookup: true,
  //           ),
  //           if (statusColor != null)
  //             Positioned(
  //               right: 4,
  //               top: 4,
  //               child: Container(
  //                 constraints: const BoxConstraints(
  //                   minWidth: 18,
  //                   minHeight: 18,
  //                 ),
  //                 decoration: BoxDecoration(
  //                   color: statusColor,
  //                   borderRadius: BorderRadius.circular(8),
  //                   border: Border.all(color: Colors.white, width: 2),
  //                 ),
  //               ),
  //             ),
  //         ],
  //       ),
  //       const SizedBox(width: 20),
  //       // RIGHT: name, hours chip, room
  //       Expanded(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               studentName,
  //               maxLines: 1,
  //               overflow: TextOverflow.ellipsis,
  //               style: const TextStyle(
  //                 color: AppColors.primaryColor,
  //                 fontSize: 18,
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //             const SizedBox(height: 4),
  //             // School hours chip
  //             Container(
  //               padding: const EdgeInsets.symmetric(
  //                 horizontal: 10,
  //                 vertical: 4,
  //               ),
  //               decoration: BoxDecoration(
  //                 color: const Color.fromRGBO(177, 175, 233, 0.3),
  //                 borderRadius: BorderRadius.circular(20),
  //               ),
  //               child: Text(
  //                 scheduleLabel.replaceAll(' - ', ' – '),
  //                 style: const TextStyle(
  //                   color: AppColors.secondaryColor,
  //                   fontWeight: FontWeight.w500,
  //                   fontSize: 12,
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 8),
  //             if (schoolTimeZone.trim().isNotEmpty && schoolNow != null)
  //               Text(
  //                 'School Day: ${_formatDayOfWeek(dayOfWeek)}',
  //                 maxLines: 1,
  //                 overflow: TextOverflow.ellipsis,
  //                 style: TextStyle(
  //                   color: AppColors.primaryColor.withValues(alpha: 0.65),
  //                   fontWeight: FontWeight.w500,
  //                   fontSize: 12,
  //                 ),
  //               ),
  //             const SizedBox(height: 8),
  //             // Room row
  //             Row(
  //               children: [
  //                 // Room avatar (non-person image → Container + icon)
  //                 const SizedBox(width: 8),
  //                 Expanded(
  //                   child: Text(
  //                     classroomName.trim().isNotEmpty
  //                         ? classroomName.trim()
  //                         : '-',
  //                     maxLines: 1,
  //                     overflow: TextOverflow.ellipsis,
  //                     style: const TextStyle(
  //                       color: AppColors.primaryColor,
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // ----- Sign-In/Out gradient button -----

  Widget _buildSignInOutButton({
    required GeofenceState geofenceState,
    required ParentChildState parentChildState,
  }) {
    final bool enabled =
        geofenceState.isWithinGeofence && geofenceState.parentGpsSignInEnabled;

    final children = parentChildState.children;
    final signedInCodes = <String>[];
    final signedOutCodes = <String>[];
    for (final child in children) {
      final code = child.code.trim();
      if (code.isEmpty) continue;
      final isSignedIn =
          (_childrenSignInStatusMap[code] ?? '').toUpperCase() == 'SIGNED_IN';
      if (isSignedIn) {
        signedInCodes.add(code);
      } else {
        signedOutCodes.add(code);
      }
    }

    final String buttonLabel;
    final VoidCallback? onPressed;

    final bool isMixed = signedInCodes.isNotEmpty && signedOutCodes.isNotEmpty;

    if (isMixed) {
      buttonLabel = 'Sign In / Out';
      onPressed = enabled
          ? () => context.go(
              '/dashboard/student-sign-in-out-selection',
              extra: <String, dynamic>{
                'signedInCodes': signedInCodes,
                'signedOutCodes': signedOutCodes,
              },
            )
          : null;
    } else if (signedOutCodes.isEmpty) {
      buttonLabel = 'Sign Out';
      onPressed = enabled
          ? () {
              final signedInChildren = children
                  .where((c) => signedInCodes.contains(c.code.trim()))
                  .toList();
              final students = signedInChildren.asMap().entries.map((entry) {
                final index = entry.key;
                final child = entry.value;
                return student_sign_out.StudentEntity(
                  id: index + 1,
                  studentCode: child.code,
                  fullName: child.name,
                  roomId: 0,
                  roomName: child.primaryClassroomName ?? child.classroom,
                  classroomCode: '',
                  photoUuid: '',
                );
              }).toList();

              unawaited(
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => student_sign_out.StudentSignOutForm(
                      students: students,
                      popOnSuccess: true,
                      refreshCallback: () =>
                          _refreshSignInStatusAfterAction(children),
                    ),
                  ),
                  // TODO: Temporarily disabled Sign Out bottom sheet and push notification.
                ).then((_) {
                  // if (mounted) _refreshSignInStatusAfterAction(children);
                }),
              );
            }
          : null;
    } else {
      buttonLabel = 'Sign In';
      onPressed = enabled
          ? () {
              final signedOutChildren = children
                  .where((c) => signedOutCodes.contains(c.code.trim()))
                  .toList();
              final students = signedOutChildren.asMap().entries.map((entry) {
                final index = entry.key;
                final child = entry.value;
                return student_sign_in.StudentEntity(
                  id: index + 1,
                  studentCode: child.code,
                  fullName: child.name,
                  roomId: 0,
                  roomName: child.primaryClassroomName ?? child.classroom,
                  classroomCode: '',
                  photoUuid: null,
                  isExpectedToday: true,
                );
              }).toList();

              unawaited(
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => student_sign_in.StudentSignInForm(
                      students: students,
                      refreshCallback: () =>
                          _refreshSignInStatusAfterAction(children),
                      popOnSuccess: true,
                    ),
                  ),
                  // TODO: Temporarily disabled Sign Out bottom sheet and push notification after Sign In.
                  // Status will be checked on next dashboard refresh or app resume.
                ).then((_) {
                  // if (mounted) _refreshSignInStatusAfterAction(children);
                }),
              );
            }
          : null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: CustomButtonLayout(
        isForm: false,
        showCancelButton: false,
        confirmButtonLabel: buttonLabel,
        confirmButtonChild: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 18,
              color: AppColors.billingBackgroundColor,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                buttonLabel,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.billingBackgroundColor,
                ),
              ),
            ),
          ],
        ),
        onPressedConfirm: onPressed,
        disabledConfirmTooltip: 'You are not within  geofencing Range',
        onDisabledConfirmTap: () {
          if (!mounted) return;
          CoreUtils.showTopSnackBar(
            isWarning: true,
            message: 'You are not within geofencing Range',
            context: context,
          );
        },
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
        CoreUtils.showTopSnackBar(
          context: context,
          message: _isReminder
              ? 'Remind set successfully'
              : 'Remind timer has turned off successfully',
          isSuccess: true,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(MediaRes.notificationsGradientIcon),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (bounds) => AppColors.buildPrimaryGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
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

  Widget _buildSignInPinRow({required ParentChildRef selectedChild}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppColors.buildPrimaryGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: const Text(
            'Your Sign-In Pin : ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        BlocBuilder<MyChildsDayCubit, MyChildsDayState>(
          buildWhen: (prev, curr) =>
              prev.guardianClockPin != curr.guardianClockPin ||
              prev.status != curr.status,
          builder: (context, state) {
            final pin = state.guardianClockPin.trim();
            return ShaderMask(
              shaderCallback: (bounds) => AppColors.buildPrimaryGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
              child: Text(
                pin.isEmpty ? '—' : pin,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        const QrScanButton(),
      ],
    );
  }

  // ----- Build -----

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isError =
        context.watch<MyChildsDayCubit>().state.status ==
        MyChildsDayStatus.error;
    return DashboardCardErrorOverlay(
      show: isError,
      onRetry: () => context.read<MyChildsDayCubit>().loadForChild(
        studentCode: _selectedChildCode,
      ),
      child: Card(
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                color: Colors.white,
              ),
              child: BlocBuilder<ParentChildCubit, ParentChildState>(
                builder: (context, state) {
                  final selectedChild = state.selectedChild;
                  if (!_didLoadCommunication) {
                    _didLoadCommunication = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      // fire-and-forget: errors are handled inside the cubit
                      unawaited(
                        context.read<CommunicationCubit>().loadConversations(),
                      );
                    });
                  }

                  return MultiBlocListener(
                    listeners: [
                      BlocListener<ParentChildCubit, ParentChildState>(
                        listenWhen: (prev, curr) =>
                            prev.refreshNonce != curr.refreshNonce ||
                            prev.selectedChild?.code !=
                                curr.selectedChild?.code ||
                            prev.children.length != curr.children.length,
                        listener: (context, parentState) {
                          final allChildCodes = parentState.children
                              .map((c) => c.code)
                              .toList();
                          if (allChildCodes.isNotEmpty) {
                            unawaited(_loadChildrenSignInStatus(allChildCodes));
                          }
                        },
                      ),
                      // ── MyChildsDay state changes ──────────────────────
                      BlocListener<MyChildsDayCubit, MyChildsDayState>(
                        listenWhen: (prev, curr) =>
                            prev.status != curr.status ||
                            prev.studentCode != curr.studentCode ||
                            prev.allRegularSchedules !=
                                curr.allRegularSchedules ||
                            prev.schoolTimeZone != curr.schoolTimeZone ||
                            prev.schoolCode != curr.schoolCode,
                        listener: (context, s) {
                          if (s.status == MyChildsDayStatus.loaded &&
                              s.schoolTimeZone.trim().isNotEmpty) {
                            _startCountdownTimer(
                              schoolTimeZone: s.schoolTimeZone,
                              allSchedules: s.allRegularSchedules,
                            );
                          } else {
                            _stopCountdownTimer();
                            _statusText.value = 'Loading schedule...';
                            _duration.value = Duration.zero;
                          }
                        },
                      ),
                      // ── Show popup the moment the user enters the zone ──
                      BlocListener<GeofenceCubit, GeofenceState>(
                        listenWhen: (prev, curr) {
                          if (prev.status == GeofenceCubitStatus.withinRange &&
                              curr.status != GeofenceCubitStatus.withinRange) {
                            _geofencePopupShownThisEntry = false;
                          }
                          if (curr.status == GeofenceCubitStatus.withinRange) {
                            if (prev.status != GeofenceCubitStatus.withinRange) {
                              return true;
                            }
                            if (prev.isSignInStatusLoading &&
                                !curr.isSignInStatusLoading) {
                              return true;
                            }
                          }
                          return false;
                        },
                        listener: (context, _) => _maybeShowChildSignInPopup(),
                      ),
                      // ── Reset sign-in status on profile switch ──
                      BlocListener<RoleCubit, RoleState>(
                        listenWhen: (prev, curr) =>
                            prev.activeSchoolRoleRaw != curr.activeSchoolRoleRaw,
                        listener: (context, state) {
                          _resetForProfileSwitch();
                          final parentChildProvider =
                              Provider.of<ParentChildCubit>(
                            context,
                            listen: false,
                          );
                          final allChildCodes = parentChildProvider.children
                              .map((c) => c.code)
                              .toList();
                          if (allChildCodes.isNotEmpty) {
                            unawaited(_loadChildrenSignInStatus(allChildCodes));
                          }
                        },
                      ),
                    ],
                    child: BlocBuilder<MyChildsDayCubit, MyChildsDayState>(
                      buildWhen: (prev, curr) =>
                          prev.status != curr.status ||
                          prev.studentCode != curr.studentCode ||
                          prev.fullName != curr.fullName ||
                          prev.classroomName != curr.classroomName ||
                          prev.todayDayOfWeek != curr.todayDayOfWeek ||
                          prev.allRegularSchedules !=
                              curr.allRegularSchedules ||
                          prev.schoolTimeZone != curr.schoolTimeZone,
                      builder: (context, myChildsDayState) {
                        final isLoading =
                            myChildsDayState.status ==
                            MyChildsDayStatus.loading;
                        final isError =
                            myChildsDayState.status == MyChildsDayStatus.error;

                        return Column(
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
                              if ((state.isLoading && state.children.isEmpty) ||
                                  isLoading)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: MyChildsDayCardShimmer(),
                                )
                              else if (selectedChild == null)
                                Center(
                                  child: Text(
                                    'No children linked',
                                    style: TextStyle(
                                      color: AppColors.primaryColor.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              else if (isError)
                                Center(
                                  child: Text(
                                    'Failed to load student details',
                                    style: TextStyle(
                                      color: AppColors.primaryColor.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              else ...[
                                ValueListenableBuilder<String>(
                                  valueListenable: _statusText,
                                  builder: (context, statusText, _) {
                                    return Center(
                                      child: Text(
                                        statusText,
                                        style: const TextStyle(
                                          color: AppColors.primaryColor,
                                          fontSize: 17,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                ValueListenableBuilder<Duration>(
                                  valueListenable: _duration,
                                  builder: (context, duration, _) {
                                    return _buildAlignedTimerDisplay(duration);
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildReminderRow(),
                                const SizedBox(height: 20),
                                // _buildStudentDetailContainer(
                                //   studentName: isLoaded
                                //       ? myChildsDayState.fullName
                                //       : selectedChild.name,
                                //   classroomName: isLoaded
                                //       ? myChildsDayState.classroomName
                                //       : (selectedChild.primaryClassroomName ??
                                //                 selectedChild.classroom)
                                //             .trim(),
                                //   dayOfWeek: isLoaded
                                //       ? myChildsDayState.todayDayOfWeek
                                //       : '',
                                //   todayScheduleRange: isLoaded
                                //       ? myChildsDayState.todayScheduleRange
                                //       : '',
                                //   schoolTimeZone: isLoaded
                                //       ? myChildsDayState.schoolTimeZone
                                //       : '',
                                //   schoolNow: isLoaded
                                //       ? myChildsDayState.schoolNow
                                //       : null,
                                //   studentStatus: selectedChild.status,
                                // ),
                                // const SizedBox(height: 16),
                                _buildSignInPinRow(
                                  selectedChild: selectedChild,
                                ),
                                const SizedBox(height: 16),
                                BlocBuilder<GeofenceCubit, GeofenceState>(
                                  builder: (context, geofenceState) {
                                    return Column(
                                      children: [
                                        _buildSignInOutButton(
                                          geofenceState: geofenceState,
                                          parentChildState: state,
                                        ),
                                        if (geofenceState.status ==
                                            GeofenceCubitStatus
                                                .permissionDenied)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 12.0,
                                              left: 24.0,
                                              right: 24.0,
                                            ),
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
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          )
                                        else if (geofenceState.status ==
                                            GeofenceCubitStatus
                                                .locationDisabled)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 12.0,
                                              left: 24.0,
                                              right: 24.0,
                                            ),
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
                                              top: 12.0,
                                              left: 24.0,
                                              right: 24.0,
                                            ),
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
                                                GeofenceCubitStatus
                                                    .checkingPermission ||
                                            geofenceState.status ==
                                                GeofenceCubitStatus
                                                    .fetchingSchoolLocation)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 12.0,
                                              left: 24.0,
                                              right: 24.0,
                                            ),
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
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // if (!_isMinimized) _buildCommunicationSection(),
            if (!_isMinimized) const _CommunicationRowWidget(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Communication row (inline, no Firestore / bloc)
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
