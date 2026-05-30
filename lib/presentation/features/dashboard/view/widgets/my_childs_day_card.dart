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
import 'package:wowcare/presentation/features/communication/cubit/communication_state.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';

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

class _MockMessage {
  const _MockMessage({required this.senderName, required this.text});

  final String senderName;
  final String text;
}

const _MockMessage _mockLastMessage = _MockMessage(
  senderName: 'Ms. Laura (Teacher)',
  text: 'Emma had a wonderful painting session today!',
);

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

  Timer? _countdownTimer;
  final ValueNotifier<String> _statusText = ValueNotifier<String>(
    'Loading schedule...',
  );
  final ValueNotifier<Duration> _duration = ValueNotifier<Duration>(
    Duration.zero,
  );

  // Reminder toggle
  bool _isReminder = false;

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
        context.read<MyChildsDayCubit>().loadForChild(
          studentCode: nextChildCode,
        );
      });
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

  String _formatDayOfWeek(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'MONDAY':
        return 'Monday';
      case 'TUESDAY':
        return 'Tuesday';
      case 'WEDNESDAY':
        return 'Wednesday';
      case 'THURSDAY':
        return 'Thursday';
      case 'FRIDAY':
        return 'Friday';
      case 'SATURDAY':
        return 'Saturday';
      case 'SUNDAY':
        return 'Sunday';
    }
    return raw.trim();
  }

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

  Widget _buildStudentDetailContainer({
    required String studentName,
    required String classroomName,
    required String dayOfWeek,
    required String todayScheduleRange,
    required String schoolTimeZone,
    required DateTime? schoolNow,
    required String studentStatus,
  }) {
    final statusColor = studentStatus == 'Upcoming'
        ? const Color.fromARGB(255, 253, 205, 22)
        : studentStatus == 'Active'
        ? const Color.fromRGBO(0, 177, 21, 1)
        : null;
    final scheduleLabel = todayScheduleRange.trim().isNotEmpty
        ? todayScheduleRange.trim()
        : 'No schedule';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // LEFT: profile photo with status dot
        Stack(
          children: [
            DocumentImageWidget(
              fileUuid: '',
              name: studentName,
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
                studentName,
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
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(177, 175, 233, 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  scheduleLabel.replaceAll(' - ', ' – '),
                  style: const TextStyle(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (schoolTimeZone.trim().isNotEmpty && schoolNow != null)
                Text(
                  'School Day: ${_formatDayOfWeek(dayOfWeek)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryColor.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
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
                      classroomName.trim().isNotEmpty
                          ? classroomName.trim()
                          : '-',
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

  Widget _buildSignInOutButton({required GeofenceState geofenceState}) {
    final bool isWithin = geofenceState.isWithinGeofence;
    final bool isEnabled = geofenceState.isLocationEnabled;
    final bool enabled = isWithin && isEnabled;

    AppLogger.d('[SignInButton] ═══════════════════════════════════════');
    AppLogger.d('[SignInButton] Status: ${geofenceState.status}');
    AppLogger.d(
      '[SignInButton] isWithinGeofence (${geofenceState.status} == withinRange): $isWithin',
    );
    AppLogger.d(
      '[SignInButton] isLocationEnabled (check against denied/disabled/initial/error): $isEnabled',
    );
    AppLogger.d(
      '[SignInButton] Final enabled state ($isWithin && $isEnabled): $enabled',
    );
    AppLogger.d(
      '[SignInButton] Button will be: ${enabled ? "🟦 ENABLED (BLUE)" : "⬜ DISABLED (GREY)"}',
    );
    AppLogger.d('[SignInButton] ═══════════════════════════════════════');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: CustomButtonLayout(
        isForm: false,
        showCancelButton: false,
        confirmButtonLabel: 'Sign-In/Out',
        onPressedConfirm: enabled
            ? () {
                context.go('/dashboard/student-selection-sign-in-form');
              }
            : null,
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
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppColors.buildPrimaryGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: const Text(
            'Student Sign In/Out Pin : ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        BlocBuilder<MyChildsDayCubit, MyChildsDayState>(
          buildWhen: (prev, curr) =>
              prev.guardianClockPin != curr.guardianClockPin ||
              prev.status != curr.status,
          builder: (context, state) {
            final pin = state.guardianClockPin.trim();
            return Text(
              pin.isEmpty ? '—' : pin,
              style: TextStyle(
                color: AppColors.primaryColor.withValues(alpha: 0.75),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.center,
            );
          },
        ),
        const SizedBox(height: 12),
        const QrScanButton(),
      ],
    );
  }

  Widget _buildCommunicationSection() {
    return BlocBuilder<CommunicationCubit, CommunicationState>(
      buildWhen: (prev, curr) =>
          curr is CommunicationConversationsLoaded ||
          curr is CommunicationConversationsLoading ||
          curr is CommunicationError,
      builder: (context, state) {
        if (state is CommunicationConversationsLoading ||
            state is CommunicationInitial) {
          return const SizedBox.shrink();
        }
        if (state is CommunicationError) {
          return const SizedBox.shrink();
        }
        if (state is! CommunicationConversationsLoaded) {
          return const SizedBox.shrink();
        }

        final conversations = state.conversationsByType[null] ?? const [];
        if (conversations.isEmpty) return const SizedBox.shrink();

        final convo = conversations.first;
        final sender = (convo.lastMessageBy ?? convo.title).trim();
        final preview = convo.lastMessagePreview.trim();

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
                name: sender.isEmpty ? '—' : sender,
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
                      sender.isEmpty ? '—' : sender,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      preview.isEmpty ? '—' : preview,
                      style: TextStyle(
                        color: AppColors.primaryColor.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {},
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
      },
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
                    context.read<CommunicationCubit>().loadConversations();
                  });
                }

                return BlocListener<MyChildsDayCubit, MyChildsDayState>(
                  listenWhen: (prev, curr) =>
                      prev.status != curr.status ||
                      prev.studentCode != curr.studentCode ||
                      prev.todayScheduleRange != curr.todayScheduleRange ||
                      prev.schoolTimeZone != curr.schoolTimeZone ||
                      prev.schoolCode != curr.schoolCode,
                  listener: (context, state) {
                    AppLogger.d(
                      '[MyChildsDayCard] MyChildsDayState changed: status=${state.status}, schoolCode=${state.schoolCode}',
                    );
                    if (state.status == MyChildsDayStatus.loaded &&
                        state.schoolTimeZone.trim().isNotEmpty) {
                      AppLogger.d(
                        '[MyChildsDayCard] Dashboard loaded, triggering geofence init',
                      );
                      _startCountdownTimer(
                        schoolTimeZone: state.schoolTimeZone,
                        todayScheduleRange: state.todayScheduleRange,
                      );
                      // Trigger geofence monitoring when school code is available
                      if (state.schoolCode.isNotEmpty) {
                        AppLogger.d(
                          '[MyChildsDayCard] Calling GeofenceCubit.initForSchool with schoolCode: ${state.schoolCode}',
                        );
                        context.read<GeofenceCubit>().initForSchool(
                          schoolCode: state.schoolCode,
                        );
                      } else {
                        AppLogger.d(
                          '[MyChildsDayCard] WARNING: schoolCode is empty!',
                        );
                      }
                    } else {
                      AppLogger.d('[MyChildsDayCard] Dashboard not loaded yet');
                      _stopCountdownTimer();
                      _statusText.value = 'Loading schedule...';
                      _duration.value = Duration.zero;
                    }
                  },
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
                      final isLoaded =
                          myChildsDayState.status == MyChildsDayStatus.loaded;
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
                            if ((state.isLoading &&
                                    state.children.isEmpty) ||
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
                              _buildStudentDetailContainer(
                                studentName: isLoaded
                                    ? myChildsDayState.fullName
                                    : selectedChild.name,
                                classroomName: isLoaded
                                    ? myChildsDayState.classroomName
                                    : (selectedChild.primaryClassroomName ??
                                              selectedChild.classroom)
                                          .trim(),
                                dayOfWeek: isLoaded
                                    ? myChildsDayState.todayDayOfWeek
                                    : '',
                                todayScheduleRange: isLoaded
                                    ? myChildsDayState.todayScheduleRange
                                    : '',
                                schoolTimeZone: isLoaded
                                    ? myChildsDayState.schoolTimeZone
                                    : '',
                                schoolNow: isLoaded
                                    ? myChildsDayState.schoolNow
                                    : null,
                                studentStatus: selectedChild.status,
                              ),
                              const SizedBox(height: 16),
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
          if (!_isMinimized)
            _CommunicationRowWidget(
              studentName: '_mockStudent.fullName',
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
                    color: AppColors.primaryColor.withValues(alpha: 0.5),
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
