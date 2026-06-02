import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
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
import 'package:wowcare/domain/features/attendance/usecases/get_student_today_sign_in_status_map_usecase.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _twoDigits(int n) => n.toString().padLeft(2, '0');

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
({String statusText, Duration duration}) _computeCountdown({
  required DateTime schoolNow,
  required String scheduleRange,
}) {
  final range = scheduleRange.trim();
  if (range.isEmpty) {
    return (statusText: 'No schedule available', duration: Duration.zero);
  }
  final parts = range.split('-');
  if (parts.length < 2) {
    return (statusText: 'No schedule available', duration: Duration.zero);
  }
  final startLabel = parts.first.trim();
  final endLabel = parts.sublist(1).join('-').trim();
  final start = _parseTime(startLabel);
  final end = _parseTime(endLabel);
  if (start == null || end == null) {
    return (statusText: 'No schedule available', duration: Duration.zero);
  }
  final todayStr =
      '${schoolNow.year}-${_twoDigits(schoolNow.month)}-${_twoDigits(schoolNow.day)}';
  final schoolStart = DateTime.parse(
    '$todayStr ${_twoDigits(start.hour)}:${_twoDigits(start.minute)}:00',
  );
  final schoolEnd = DateTime.parse(
    '$todayStr ${_twoDigits(end.hour)}:${_twoDigits(end.minute)}:00',
  );

  if (schoolNow.isBefore(schoolStart)) {
    return (
      statusText: 'School starts in',
      duration: schoolStart.difference(schoolNow),
    );
  } else if (schoolNow.isBefore(schoolEnd)) {
    return (
      statusText: 'School ends in',
      duration: schoolEnd.difference(schoolNow),
    );
  } else {
    // School done for today – show tomorrow
    final tomorrow = schoolNow.add(const Duration(days: 1));
    final tomorrowStr =
        '${tomorrow.year}-${_twoDigits(tomorrow.month)}-${_twoDigits(tomorrow.day)}';
    final nextStart = DateTime.parse(
      '$tomorrowStr ${_twoDigits(start.hour)}:${_twoDigits(start.minute)}:00',
    );
    return (
      statusText: "Tomorrow's school starts in",
      duration: nextStart.difference(schoolNow),
    );
  }
}

class MyChildsDayCard extends StatefulWidget {
  const MyChildsDayCard({super.key});

  @override
  State<MyChildsDayCard> createState() => _MyChildsDayCardState();
}

class _MyChildsDayCardState extends State<MyChildsDayCard>
    with AutomaticKeepAliveClientMixin {
  bool _isMinimized = false;
  String _selectedChildCode = '';
  bool _didLoadCommunication = false;

  // Children sign-in status map
  Map<String, String> _childrenSignInStatusMap = {};
  bool _loadingSignInStatus = false;

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

  /// Returns true when the selected child is currently signed in.
  bool get _isSelectedChildSignedIn {
    final code = _selectedChildCode;
    if (code.isEmpty) return false;
    return (_childrenSignInStatusMap[code] ?? '').toUpperCase() == 'SIGNED_IN';
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parentChildProvider = Provider.of<ParentChildCubit>(context);
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
    // Load sign-in status for all children
    final allChildCodes = parentChildProvider.children
        .map((c) => c.code)
        .toList();
    if (allChildCodes.isNotEmpty) {
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
      if (schoolCode.isEmpty || !mounted) return;

      // Initialize GPS geofencing with the school code
      await context.read<GeofenceCubit>().initForSchool(schoolCode: schoolCode);
    } catch (_) {
      // Silently fail - GPS is optional
    }
  }

  Future<void> _loadChildrenSignInStatus(List<String> childCodes) async {
    if (childCodes.isEmpty) return;
    setState(() => _loadingSignInStatus = true);
    try {
      final useCase = serviceLocator<GetStudentTodaySignInStatusMapUseCase>();
      final map = await useCase(studentCodes: childCodes);
      if (!mounted) return;
      setState(() {
        _childrenSignInStatusMap = map;
        _loadingSignInStatus = false;
      });
    } catch (_) {
      // If status check fails, keep empty map
      if (!mounted) return;
      setState(() => _loadingSignInStatus = false);
    }
  }

  void _stopCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _startCountdownTimer({
    required String schoolTimeZone,
    required String todayScheduleRange,
  }) {
    _stopCountdownTimer();

    void tick() {
      final schoolNow = SchoolZoneDateTime.dateTimeFromInstantInSchool(
        DateTime.now().toUtc(),
        schoolTimeZone,
      );
      final result = _computeCountdown(
        schoolNow: schoolNow,
        scheduleRange: todayScheduleRange,
      );
      _statusText.value = result.statusText;
      _duration.value = result.duration;
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  @override
  void dispose() {
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

  Widget _buildSignInOutButton({required GeofenceState geofenceState}) {
    final bool enabled =
        geofenceState.status == GeofenceCubitStatus.withinRange;
    final String buttonLabel = _isSelectedChildSignedIn
        ? 'Sign-Out'
        : 'Sign-In';
    final String route = _isSelectedChildSignedIn
        ? '/dashboard/student-selection-sign-out-form'
        : '/dashboard/student-selection-sign-in-form';

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
        onPressedConfirm: enabled ? () => context.go(route) : null,
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
            'Sign In/Out Pin : ',
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
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.1)),
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
                    // ── MyChildsDay state changes ──────────────────────
                    BlocListener<MyChildsDayCubit, MyChildsDayState>(
                      listenWhen: (prev, curr) =>
                          prev.status != curr.status ||
                          prev.studentCode != curr.studentCode ||
                          prev.todayScheduleRange != curr.todayScheduleRange ||
                          prev.schoolTimeZone != curr.schoolTimeZone ||
                          prev.schoolCode != curr.schoolCode,
                      listener: (context, s) {
                        AppLogger.d(
                          '[MyChildsDayCard] status=${s.status}, schoolCode=${s.schoolCode}',
                        );
                        if (s.status == MyChildsDayStatus.loaded &&
                            s.schoolTimeZone.trim().isNotEmpty) {
                          _startCountdownTimer(
                            schoolTimeZone: s.schoolTimeZone,
                            todayScheduleRange: s.todayScheduleRange,
                          );
                          // Geofence is already initialized in didChangeDependencies
                          // Don't reinitialize here to avoid duplicate setup
                        } else {
                          _stopCountdownTimer();
                          _statusText.value = 'Loading schedule...';
                          _duration.value = Duration.zero;
                        }
                      },
                    ),
                    // ── Show popup the moment the user enters the zone ──
                    BlocListener<GeofenceCubit, GeofenceState>(
                      listenWhen: (prev, curr) =>
                          prev.status != GeofenceCubitStatus.withinRange &&
                          curr.status == GeofenceCubitStatus.withinRange,
                      listener: (context, _) {
                        // GeofenceCubit already fires the notification via
                        // _triggerNotificationIfNeeded — no need to do it here.
                        if (!context.mounted) return;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          unawaited(
                            GeofenceSignInSheet.show(
                              context,
                              role: 'parent',
                              isSignedIn: _isSelectedChildSignedIn,
                              studentName: selectedChild?.name,
                            ),
                          );
                        });
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
                        prev.todayScheduleRange != curr.todayScheduleRange ||
                        prev.schoolTimeZone != curr.schoolTimeZone,
                    builder: (context, myChildsDayState) {
                      final isLoading =
                          myChildsDayState.status == MyChildsDayStatus.loading;
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
                              _buildSignInPinRow(selectedChild: selectedChild),
                              const SizedBox(height: 16),
                              BlocBuilder<GeofenceCubit, GeofenceState>(
                                builder: (context, geofenceState) {
                                  AppLogger.d(
                                    '[SignInButton-BlocBuilder] Rebuilding with state: ${geofenceState.status}',
                                  );
                                  return Column(
                                    children: [
                                      _buildSignInOutButton(
                                        geofenceState: geofenceState,
                                      ),
                                      if (geofenceState.status ==
                                          GeofenceCubitStatus.permissionDenied)
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
                                          GeofenceCubitStatus.locationDisabled)
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
