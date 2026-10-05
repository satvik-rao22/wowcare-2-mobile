import 'dart:async';
import 'package:wowcare/core/router/app_routes.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/simmer_loader.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_profile_field.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_profile_stat_widgets.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/utils/attendance_attended_duration.dart';
import 'package:wowcare/presentation/features/attendance/view_model/student_attendance_profile_fetch_cubit.dart';
import 'package:wowcare/shared/common/model/bottom_navigation_item.dart';
import 'package:wowcare/shared/common/app/cubits/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/presentation/features/attendance/widgets/student_attendance_vertical_pop_up.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_permission_service.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_school_time.dart';
import 'package:wowcare/presentation/features/students/widgets/student_attendance_action_availability.dart';
import 'package:wowcare/presentation/features/attendance/model/student_entity.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/student_sign_in_form.dart'
    as student_sign_in;
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/student_sign_out_form.dart'
    as student_sign_out;
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/student_transfer_form.dart'
    as student_transfer;
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/student_mark_absent_form.dart'
    as student_absent;
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/core/utils/server_time_service.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_transfer_form_list_usecase.dart';

/// Builds the small method-tooltip icon for [AttendanceProfileField]'s
/// [AttendanceProfileField.methodIcon] slot. Kept local (rather than shared
/// with the staff profile screen) because the two personas' method sets
/// genuinely differ — staff adds pin/transfer/nfc/biometric.
Widget _absentMethodIcon(ProfileAbsentMarkMethod method) {
  const double size = 16;
  switch (method) {
    case ProfileAbsentMarkMethod.gps:
      return Tooltip(
        message: 'GPS',
        child: AppIcon(
          MediaRes.gpsMethodIcon,
          width: size,
          height: size,
          color: AppColors.themeColor,
        ),
      );
    case ProfileAbsentMarkMethod.qr:
      return Tooltip(
        message: 'QR',
        child: AppIcon(
          MediaRes.qrAttendanceIcon,
          width: size,
          height: size,
          color: AppColors.themeColor,
        ),
      );
    case ProfileAbsentMarkMethod.kiosk:
      return Tooltip(
        message: 'Kiosk',
        child: AppIcon(
          MediaRes.kioskAttendenceIcons,
          width: size,
          height: size,
          color: AppColors.themeColor,
        ),
      );
    case ProfileAbsentMarkMethod.app:
      return Tooltip(
        message: 'APP',
        child: AppIcon(
          MediaRes.appMethodIcon,
          width: size,
          height: size,
          color: AppColors.themeColor,
        ),
      );
    case ProfileAbsentMarkMethod.web:
      return Tooltip(
        message: 'WEB',
        child: AppIcon(
          MediaRes.webMethodIcon,
          width: size,
          height: size,
          color: AppColors.themeColor,
        ),
      );
    case ProfileAbsentMarkMethod.system:
      // Auto sign-out performed by the system (no person). Matches web's
      // gear/"System" indicator.
      return Tooltip(
        message: 'System',
        child: AppIcon(
          MediaRes.systemMethodIcon,
          width: size,
          height: size,
          color: AppColors.themeColor,
        ),
      );
  }
}

/// Formats many possible API time shapes into a clean 12-hour display ("hh:mm a").
/// Supports:
/// - Map: {hour, minute, second?, nano?}
/// - "HH:mm", "HH:mm:ss", "HH:mm:ss.SSSSSS"
/// - "h:mm:ss AM", "hh:mm:ss a"
/// - ISO datetime strings (e.g. "2026-04-07T13:05:00.000Z")
String _formatTime12h(dynamic value) {
  if (value == null) return '';
  final s = value.toString().trim();
  if (s.isEmpty) return '';

  try {
    if (value is Map<String, dynamic>) {
      final hour = value['hour'] as int? ?? 0;
      final minute = value['minute'] as int? ?? 0;
      final dt = DateTime(2000, 1, 1, hour, minute);
      return DateFormat('hh:mm a').format(dt);
    }

    // Render ISO instants in the school's zone (not the device zone) so
    // sign-in/out times match the backend regardless of where the user is.
    final schoolDt = attendanceDisplayDateTimeFromIso(s);
    if (schoolDt != null) {
      return DateFormat('hh:mm a').format(schoolDt);
    }

    final amPmMatch = RegExp(
      r'^\s*(\d{1,2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?\s*([aApP][mM])\s*$',
    ).firstMatch(s);
    if (amPmMatch != null) {
      final hour = int.parse(amPmMatch.group(1)!);
      final minute = int.parse(amPmMatch.group(2)!);
      final period = amPmMatch.group(4)!.toUpperCase();
      int h24 = hour % 12;
      if (period == 'PM') h24 += 12;
      final dt = DateTime(2000, 1, 1, h24, minute);
      return DateFormat('hh:mm a').format(dt);
    }

    final hms = s.split('.')[0];
    final parts = hms.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final dt = DateTime(2000, 1, 1, hour, minute);
      return DateFormat('hh:mm a').format(dt);
    }
  } catch (_) {
    // fall-through to raw string
  }

  return s;
}

String _formatAttendedTimeForCard(StudentProfileAttendanceRecord attendance) {
  final inStr = attendance.signInTime.trim();
  final outStr = attendance.signOutTime.trim();

  if (inStr.isNotEmpty && outStr.isEmpty) {
    return 'Not Yet Signed Out';
  }

  final day = DateTime(
    attendance.date.year,
    attendance.date.month,
    attendance.date.day,
  );
  final start = parseFlexibleAttendanceMoment(day, inStr);
  final end = parseFlexibleAttendanceMoment(day, outStr);
  final label = attendedLabelFromMoments(start, end);
  if (label != null && label.isNotEmpty) {
    return label;
  }
  return '';
}

String formatTime(String time) {
  if (time.trim().isEmpty) return 'Not Yet Signed Out';
  return _formatTime12h(time);
}

bool _isKioskOrPinMethodEnum(ProfileAbsentMarkMethod? method) {
  return method == ProfileAbsentMarkMethod.kiosk;
}

String _resolveSignInByDisplay(
  String signInBy,
  ProfileAbsentMarkMethod? method,
) {
  final name = signInBy.trim();
  if (name.isNotEmpty) return name;
  if (_isKioskOrPinMethodEnum(method)) return 'Kiosk';
  return '';
}

String _resolveSignOutByDisplay(
  String signOutBy,
  ProfileAbsentMarkMethod? method,
) {
  final name = signOutBy.trim();
  if (name.isNotEmpty) return name;
  if (_isKioskOrPinMethodEnum(method)) return 'Kiosk';
  return '';
}

/// Shows the full name (first + last), not just the first word.
String getFirstName(String name) {
  return name.trim();
}

class StudentAttendanceProfile extends StatefulWidget {
  static const String routeName = DashboardRoutes.studentAttendanceProfile;

  const StudentAttendanceProfile({
    super.key,
    required this.studentCode,
    required this.studentId,
    required this.studentName,
    this.studentPhotoUuid,
    required this.roomName,
    this.isSignedIn = false,
    this.isAbsent = false,
    this.isExpectedToday = true,
    this.isPresentToday = false,
    this.profileStatus = 'A',
    this.syncWithParentChildSelection = false,
    this.initialShowAbsentDays = false,
  });

  final int studentId;
  final String studentCode;
  final String studentName;
  final String? studentPhotoUuid;
  final String roomName;
  final bool isSignedIn;
  final bool isAbsent;
  final bool isExpectedToday;
  final bool isPresentToday;
  final String profileStatus;

  /// When true (e.g. parent drawer / popup), reloads when the global child dropdown changes.
  final bool syncWithParentChildSelection;

  /// When true, opens the profile with the absent-days list visible (e.g. Absent tab).
  final bool initialShowAbsentDays;

  @override
  State<StudentAttendanceProfile> createState() =>
      _StudentAttendanceProfileState();
}

class _StudentAttendanceProfileState extends State<StudentAttendanceProfile> {
  DateTime _startOfMonth(DateTime date) => DateTime(date.year, date.month, 1);

  DateTime _endOfMonth(DateTime date) => DateTime(date.year, date.month + 1, 0);

  /// Owns every fetch call this screen makes AND the loaded/loading state
  /// (View -> Cubit -> UseCase -> Repository). See the cubit's doc comment
  /// for the full state-ownership split: pure data lives here; anything
  /// needing [BuildContext] (permission checks, the ParentChildCubit stream
  /// subscription) stays in this View.
  final StudentAttendanceProfileFetchCubit _profileCubit =
      serviceLocator<StudentAttendanceProfileFetchCubit>();

  ParentChildCubit? _parentChildProvider;
  StreamSubscription<ParentChildState>? _parentChildSub;

  @override
  void initState() {
    super.initState();
    final now = ServerTimeService.instance.now();
    _profileCubit.seedFromWidget(
      studentId: widget.studentId,
      studentName: widget.studentName,
      studentPhotoUuid: widget.studentPhotoUuid,
      roomName: widget.roomName,
      isSignedIn: widget.isSignedIn,
      isAbsent: widget.isAbsent,
      isExpectedToday: widget.isExpectedToday,
      isPresentToday: widget.isPresentToday,
      profileStatus: widget.profileStatus,
      activeStudentCode: widget.studentCode.trim(),
      startDate: _startOfMonth(now),
      endDate: _endOfMonth(now),
    );
    if (widget.initialShowAbsentDays) {
      _profileCubit.toggleShowAbsentDays(true);
    }

    // Load data from API
    _profileCubit.loadData(fallbackRoomName: widget.roomName);
    // Deep-link (e.g. ATTENDANCE_NOT_MARKED) opens this screen with only a
    // studentCode — the attendance API doesn't return the student's name, so
    // the header would show empty. Fetch the student's identity by code.
    _profileCubit.ensureHeaderIdentityLoaded(
      studentName: widget.studentName,
      activeStudentCode: widget.studentCode.trim(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.syncWithParentChildSelection || _parentChildProvider != null) {
      return;
    }
    final p = context.read<ParentChildCubit>();
    _parentChildProvider = p;
    _parentChildSub = p.stream.listen((_) => _onParentChildSelectionChanged());
  }

  @override
  void dispose() {
    _parentChildSub?.cancel();
    _profileCubit.close();
    super.dispose();
  }

  void _onParentChildSelectionChanged() {
    if (!widget.syncWithParentChildSelection) return;
    final child = _parentChildProvider?.selectedChild;
    final code = child?.code.trim() ?? '';
    if (code.isEmpty || code == _profileCubit.state.activeStudentCode) return;
    _profileCubit.applyParentChildSelection(
      childCode: child!.code,
      childName: child.name,
      childClassroom: child.classroom,
      studentId: widget.studentId,
      defaultProfileStatus: widget.profileStatus,
    );
  }

  Future<void> refreshData() async {
    await _profileCubit.loadData(
      fallbackRoomName:
          _profileCubit.state.student?.roomName ?? widget.roomName,
    );
  }

  bool get _isActiveProfile {
    final status =
        (_profileCubit.state.student?.profileStatus ?? widget.profileStatus)
            .toUpperCase();
    return status == 'A' || status == 'ACTIVE';
  }

  StudentAttendanceGate get _todayGate => studentAttendanceGateFromTodayStatus(
    isActiveProfile: _isActiveProfile,
    todayStatusRaw: _profileCubit.state.todayStatusRaw,
  );

  bool get _canSignIn =>
      !_profileCubit.state.isTodayStatusLoading &&
      _todayGate.canSignIn &&
      AttendancePermissionService.hasPermissionToManageStudentAttendance(
        context,
      );
  bool get _canSignOut =>
      !_profileCubit.state.isTodayStatusLoading &&
      _todayGate.canSignOut &&
      AttendancePermissionService.hasPermissionToManageStudentAttendance(
        context,
      );
  bool get _canTransfer =>
      !_profileCubit.state.isTodayStatusLoading &&
      _todayGate.canTransfer &&
      AttendancePermissionService.hasPermissionToManageStudentAttendance(
        context,
      );
  bool get _canMarkAbsent =>
      !_profileCubit.state.isTodayStatusLoading &&
      _todayGate.canMarkAbsent &&
      AttendancePermissionService.hasPermissionToManageStudentAttendance(
        context,
      );

  Future<Map<String, String>> _loadClassroomNameToCodeMap() async {
    try {
      return await _profileCubit.fetchClassroomNameToCodeMap();
    } catch (_) {
      return const <String, String>{};
    }
  }

  Future<void> _handleStudentAction(String actionLabel) async {
    final current = _profileCubit.state.student;
    if (current == null) return;

    // Disabled actions are already non-tappable in the pop-up and explain
    // themselves via the per-action tooltip, so just no-op here instead of
    // showing a generic snackbar.
    if ((actionLabel == 'Sign-in' && !_canSignIn) ||
        (actionLabel == 'Sign-Out' && !_canSignOut) ||
        (actionLabel == 'Transfer' && !_canTransfer) ||
        (actionLabel == 'Absent' && !_canMarkAbsent)) {
      return;
    }

    final classroomMap = await _loadClassroomNameToCodeMap();
    final classroomCode = (classroomMap[current.roomName] ?? '').trim();
    final entity = StudentEntity(
      id: current.id,
      studentCode: _profileCubit.state.activeStudentCode,
      fullName: current.name,
      roomId: 0,
      roomName: current.roomName,
      classroomCode: classroomCode,
      photoUuid: current.photoUuid ?? '',
      isExpectedToday: current.isExpectedToday,
    );

    Widget? target;
    if (actionLabel == 'Sign-in') {
      target = student_sign_in.StudentSignInForm(
        students: [entity],
        refreshCallback: refreshData,
        // Actions started from this profile screen must return here, not
        // redirect to the Attendance daily tab.
        popOnSuccess: true,
      );
    } else if (actionLabel == 'Sign-Out') {
      target = student_sign_out.StudentSignOutForm(
        students: [entity],
        refreshCallback: refreshData,
        popOnSuccess: true,
      );
    } else if (actionLabel == 'Transfer') {
      // `entity.classroomCode` above is seeded from the profile header
      // (`current.roomName`), which reflects the student's static enrolled
      // classroom rather than where they're actually signed in right now —
      // it only gets updated by `ensureHeaderIdentityLoaded`'s profile fetch
      // or the guardian flow's today lookup, not for a staff-opened profile.
      // Resolve the real current classroom the same way the Student screen's
      // bulk Transfer action does: today's transfer-form-list, matched by
      // student code, whose classroomCode reflects any transfer applied so
      // far today.
      String? liveClassroomCode;
      String? liveClassroomName;
      try {
        final now = ServerTimeService.instance.now();
        final today =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final useCase = serviceLocator<GetStudentTransferFormListUseCase>();
        final page = await useCase(
          fromAttendanceDate: today,
          toAttendanceDate: today,
          page: 0,
          size: 500,
        );
        final activeCode = _profileCubit.state.activeStudentCode.trim();
        for (final item in page.items) {
          if (item.studentCode.trim() == activeCode) {
            liveClassroomCode = item.classroomCode.trim();
            liveClassroomName = item.classroomName.trim();
            break;
          }
        }
      } catch (_) {
        // Fall through to the profile-header classroom below.
      }

      target = student_transfer.StudentTransferForm(
        students: [entity],
        refreshCallback: refreshData,
        popOnSuccess: true,
        classroomNameToCode: classroomMap,
        currentClassroomCode: (liveClassroomCode ?? '').isNotEmpty
            ? liveClassroomCode
            : classroomCode,
        currentClassroomName: (liveClassroomName ?? '').isNotEmpty
            ? liveClassroomName
            : current.roomName,
      );
    } else if (actionLabel == 'Absent') {
      target = student_absent.StudentMarkAbsentForm(
        students: [entity],
        refreshCallback: refreshData,
        popOnSuccess: true,
      );
    }

    if (target == null || !mounted) return;
    // GoRouter holdout (documented): carries a refreshCallback closure and a form-local StudentEntity list, which don't fit GoRouter's URL/extra model — kept as an imperative Navigator.push.
    await Navigator.push(context, MaterialPageRoute(builder: (_) => target!));
    if (!mounted) return;
    await refreshData();
  }

  void _onDateRangeSelected(DateTime startDate, DateTime? endDate) {
    _profileCubit.setDateRange(startDate, endDate);
  }

  /// Clear All on the date range: back to the page-load default (the current
  /// month). No-op when the range is already that month, so a redundant tap
  /// doesn't refetch.
  void _onClearDateRange() {
    final now = ServerTimeService.instance.now();
    final start = _startOfMonth(now);
    final end = _endOfMonth(now);
    final state = _profileCubit.state;
    if (_isSameDay(state.startDate, start) && _isSameDay(state.endDate, end)) {
      return;
    }
    _profileCubit.setDateRange(start, end);
  }

  bool _isSameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final contentPadding = ResponsiveHelper(context).contentPadding;
    final isParentPersona = context.watch<RoleCubit>().isParent;

    return BlocBuilder<
      StudentAttendanceProfileFetchCubit,
      StudentAttendanceProfileState
    >(
      bloc: _profileCubit,
      builder: (context, state) {
        return GlobalScaffold(
          hasBackButton: true,
          showCustomNavigationBar: true,
          // Highlight the Attendance tab while a parent views their child's profile.
          activeItemOverride: isParentPersona
              ? BottomNavigationItem.attendance
              : null,
          body: CustomRefreshIndicator(
            onRefresh: () async => refreshData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: contentPadding.left,
                vertical: responsive.verticalSpacing / 2,
              ),
              child: Column(
                children: [
                  SizedBox(height: responsive.verticalSpacing),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: CustomDateTimeField(
                          hasLabel: false,
                          isRangePicker: true,
                          initialDate: state.startDate,
                          initialEndDate: state.endDate,
                          label: 'Date Range',
                          onRangeSelected: (start, end) {
                            _onDateRangeSelected(start, end);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      CustomClearAllChip(onTap: _onClearDateRange),
                      if (!isParentPersona) ...[
                        const SizedBox(width: AppSpacing.md),
                        StudentAttendanceVerticalPopUp(
                          students: const [],
                          refreshCallback: refreshData,
                          disabledActions: <String>{
                            if (!_canSignIn) 'Sign-in',
                            if (!_canSignOut) 'Sign-Out',
                            if (!_canTransfer) 'Transfer',
                            if (!_canMarkAbsent) 'Absent',
                          },
                          disabledReasons: state.isTodayStatusLoading
                              ? const <String, String>{}
                              : studentAttendanceDisabledReasons(_todayGate),
                          onActionTap: _handleStudentAction,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  state.isStudentLoading &&
                          (state.isAttendancesLoading ||
                              state.isAbsentDaysLoading)
                      ? const AttendanceProfileShimmer()
                      : Column(
                          children: [
                            _StudentCard(
                              student: state.student,
                              activeStudentCode: state.activeStudentCode,
                              isParentPersona: isParentPersona,
                              attendanceReport: state.attendanceReport,
                              onPresentTap: () {
                                context.push(
                                  StudentAttendanceTabbedView.routeName,
                                  extra: {'filter': 'Present'},
                                );
                              },
                              onAbsentTap: () {
                                context.push(
                                  StudentAttendanceTabbedView.routeName,
                                  extra: {'filter': 'Absent'},
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Toggle for showing absent days
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText.title(
                                  state.showAbsentDays
                                      ? 'Absent Days'
                                      : 'Present Days',
                                  style: AppTextStyles.heading18,
                                ),
                                CustomToggle(
                                  label: 'Show Absent',
                                  isToggled: state.showAbsentDays,
                                  onToggle: (value) {
                                    _profileCubit.toggleShowAbsentDays(value);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _StudentAttendanceListSection(
                              showAbsentDays: state.showAbsentDays,
                              isAttendancesLoading: state.isAttendancesLoading,
                              attendances: state.attendances,
                              isAbsentDaysLoading: state.isAbsentDaysLoading,
                              absentDays: state.absentDays,
                              fallbackRoomName:
                                  state.student?.roomName ?? widget.roomName,
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.activeStudentCode,
    required this.isParentPersona,
    required this.attendanceReport,
    required this.onPresentTap,
    required this.onAbsentTap,
  });

  final StudentProfileCardModel? student;
  final String activeStudentCode;
  final bool isParentPersona;
  final StudentProfileAttendanceReportModel? attendanceReport;
  final VoidCallback onPresentTap;
  final VoidCallback onAbsentTap;

  @override
  Widget build(BuildContext context) {
    if (student == null) return const SizedBox.shrink();

    final responsive = ResponsiveHelper(context);
    final currentStudent = student!;

    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.cardColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: AppColors.primaryColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
        borderRadius: AppRadius.allLg,
      ),
      elevation: 6,
      shadowColor: AppColors.primaryColor.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: AppSpacing.s5),
                DocumentImageWidget(
                  fileUuid: currentStudent.photoUuid ?? '',
                  size: 80,
                  name: currentStudent.name,
                  fontSize: 24,
                  // Drive status dot purely from attendance API using studentCode.
                  studentCode: activeStudentCode,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.title(
                        currentStudent.name,
                        style: AppTextStyles.attendanceProfileName(
                          isTablet: responsive.isTablet,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppText.body(
                              currentStudent.roomName,
                              style: AppTextStyles.mediumWeight,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: AppText.title(
                                    'Details',
                                    style: AppTextStyles.heading18,
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!currentStudent.isPhotoPermission)
                                        _StudentIconDetail(
                                          MediaRes.cameraIcon,
                                          "No Photo Permission",
                                        ),
                                      if (currentStudent.medications.isNotEmpty)
                                        _StudentIconDetail(
                                          MediaRes.healthIcon,
                                          currentStudent.medications,
                                        ),
                                      if (currentStudent.note.isNotEmpty)
                                        _StudentIconDetail(
                                          MediaRes.docsIcon,
                                          currentStudent.note,
                                        ),
                                      if (currentStudent.allergies.isNotEmpty)
                                        _StudentIconDetail(
                                          MediaRes.alertIcon,
                                          currentStudent.allergies,
                                        ),
                                      if (currentStudent
                                          .dietRestriction
                                          .isNotEmpty)
                                        _StudentIconDetail(
                                          MediaRes.foodIcon2,
                                          currentStudent.dietRestriction,
                                        ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: AppText.body(
                                        'Close',
                                        style: AppTextStyles.mediumWeight,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                if (!currentStudent.isPhotoPermission)
                                  _StudentIconItem(MediaRes.cameraIcon),
                                if (currentStudent.medications.isNotEmpty)
                                  _StudentIconItem(MediaRes.healthIcon),
                                if (currentStudent.note.isNotEmpty)
                                  _StudentIconItem(MediaRes.docsIcon),
                                if (currentStudent.allergies.isNotEmpty)
                                  _StudentIconItem(MediaRes.alertIcon),
                                if (currentStudent.dietRestriction.isNotEmpty)
                                  _StudentIconItem(MediaRes.foodIcon2),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _StudentStatsSection(
              isParentPersona: isParentPersona,
              attendedDays: attendanceReport?.attendedDays,
              absentDays: attendanceReport?.absentDays,
              totalAttendedHours: attendanceReport?.totalAttendedHours,
              onPresentTap: onPresentTap,
              onAbsentTap: onAbsentTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentStatsSection extends StatelessWidget {
  const _StudentStatsSection({
    required this.isParentPersona,
    required this.attendedDays,
    required this.absentDays,
    required this.totalAttendedHours,
    required this.onPresentTap,
    required this.onAbsentTap,
  });

  final bool isParentPersona;
  final int? attendedDays;
  final int? absentDays;
  final String? totalAttendedHours;
  final VoidCallback onPresentTap;
  final VoidCallback onAbsentTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: isParentPersona ? null : onPresentTap,
          child: AttendanceProfileStatItem(
            icon: MediaRes.calenderClockIcon,
            iconColor: AppColors.attendanceStatBlueColor,
            label: 'Attended Days',
            value: attendedDays != null ? '$attendedDays' : '',
            valueColor: AppColors.attendanceStatGreenColor,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AttendanceProfileAttendedHoursStat(
          totalAttendedHours: totalAttendedHours,
        ),
        const SizedBox(height: AppSpacing.md),
        InkWell(
          onTap: isParentPersona ? null : onAbsentTap,
          child: AttendanceProfileStatItem(
            icon: MediaRes.calenderClockIcon,
            iconColor: AppColors.attendanceStatBlueColor,
            label: 'Absent Days',
            value: absentDays != null ? '$absentDays' : '',
            valueColor: AppColors.errorColor,
          ),
        ),
      ],
    );
  }
}

class _StudentAttendanceListSection extends StatelessWidget {
  const _StudentAttendanceListSection({
    required this.showAbsentDays,
    required this.isAttendancesLoading,
    required this.attendances,
    required this.isAbsentDaysLoading,
    required this.absentDays,
    required this.fallbackRoomName,
  });

  final bool showAbsentDays;
  final bool isAttendancesLoading;
  final List<StudentProfileAttendanceRecord> attendances;
  final bool isAbsentDaysLoading;
  final List<StudentProfileAbsentDayRecord> absentDays;
  final String fallbackRoomName;

  @override
  Widget build(BuildContext context) {
    if (showAbsentDays) {
      return _absentDaysList();
    }
    return _presentDaysList();
  }

  Widget _presentDaysList() {
    if (isAttendancesLoading) {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: 5,
        itemBuilder: (context, index) {
          return const ShimmerLoaderCard(child: SizedBox(height: 50));
        },
      );
    }

    if (attendances.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.r14),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: AppText.body(
            'No attendance records found for selected date range',
            style: AppTextStyles.size16,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: List.generate(attendances.length, (index) {
        return _StudentAttendanceItemCard(attendance: attendances[index]);
      }),
    );
  }

  Widget _absentDaysList() {
    if (isAbsentDaysLoading) {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: 5,
        itemBuilder: (context, index) {
          return const ShimmerLoaderCard(child: SizedBox(height: 50));
        },
      );
    }

    if (absentDays.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.r14),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: AppText.body(
            'No absent days found for selected date range',
            style: AppTextStyles.size16,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: List.generate(absentDays.length, (index) {
        return _StudentAbsentDayItemCard(
          absentDay: absentDays[index],
          fallbackRoomName: fallbackRoomName,
        );
      }),
    );
  }
}

class _StudentAttendanceItemCard extends StatelessWidget {
  const _StudentAttendanceItemCard({required this.attendance});

  final StudentProfileAttendanceRecord attendance;

  @override
  Widget build(BuildContext context) {
    final collapsedText = _formatAttendedTimeForCard(attendance);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExpansionTile(
        title: AppText.body(
          DateFormat('MMM dd, yyyy').format(attendance.date),
          style: AppTextStyles.mediumWeight,
        ),
        trailing: AppText.body(collapsedText, style: AppTextStyles.valueLarge),
        backgroundColor: AppColors.cardColor,
        collapsedBackgroundColor: AppColors.cardColor,
        collapsedShape: RoundedRectangleBorder(
          side: BorderSide(
            color: AppColors.primaryColor.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(AppRadius.r14),
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: AppColors.primaryColor.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(AppRadius.r14),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.none,
          AppSpacing.md,
          AppSpacing.md,
        ),
        children: [
          Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),
          const SizedBox(height: AppSpacing.md),
          AttendanceProfileField(label: 'Classroom', text: attendance.roomName),
          const SizedBox(height: AppSpacing.md),
          AttendanceProfileField(
            label: 'Sign In',
            text: formatTime(attendance.signInTime),
            showTransferIcon: attendance.isTransferSignIn,
            methodIcon: attendance.signInMethod != null
                ? _absentMethodIcon(attendance.signInMethod!)
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AttendanceProfileField(
            label: 'Sign In By',
            text: _resolveSignInByDisplay(
              attendance.signInBy,
              attendance.signInMethod,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AttendanceProfileField(
            label: 'Sign Out',
            text: formatTime(attendance.signOutTime),
            showTransferIcon: attendance.isTransferSignOut,
            methodIcon: attendance.signOutMethod != null
                ? _absentMethodIcon(attendance.signOutMethod!)
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AttendanceProfileField(
            label: 'Sign Out By',
            text: _resolveSignOutByDisplay(
              attendance.signOutBy,
              attendance.signOutMethod,
            ),
          ),
          if (_formatAttendedTimeForCard(attendance).trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            AttendanceProfileField(
              label: 'Attended Time',
              text: _formatAttendedTimeForCard(attendance),
            ),
          ],
          if (attendance.notExpectedComment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            AttendanceProfileField(
              label: 'Comment',
              text: attendance.notExpectedComment,
            ),
          ],
        ],
      ),
    );
  }
}

class _StudentAbsentDayItemCard extends StatelessWidget {
  const _StudentAbsentDayItemCard({
    required this.absentDay,
    required this.fallbackRoomName,
  });

  final StudentProfileAbsentDayRecord absentDay;
  final String fallbackRoomName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExpansionTile(
        title: AppText.body(
          DateFormat('MMM dd, yyyy').format(absentDay.startDate),
          style: AppTextStyles.mediumWeight,
        ),
        backgroundColor: AppColors.cardColor,
        collapsedBackgroundColor: AppColors.cardColor,
        collapsedShape: RoundedRectangleBorder(
          side: BorderSide(
            color: AppColors.primaryColor.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(AppRadius.r14),
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: AppColors.primaryColor.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(AppRadius.r14),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.none,
          AppSpacing.md,
          AppSpacing.md,
        ),
        children: [
          Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),
          const SizedBox(height: AppSpacing.md),
          AttendanceProfileField(
            label: 'Classroom',
            text: () {
              if (absentDay.classroomName.isNotEmpty) {
                return absentDay.classroomName;
              }
              final fallback = fallbackRoomName;
              return (fallback.trim().isNotEmpty &&
                      fallback != '-' &&
                      fallback != '—')
                  ? fallback
                  : '';
            }(),
          ),
          const SizedBox(height: AppSpacing.md),
          AttendanceProfileField(
            label: 'Date',
            text:
                '${DateFormat('MMM dd, yyyy').format(absentDay.startDate)} - ${DateFormat('MMM dd, yyyy').format(absentDay.endDate)}',
          ),
          const SizedBox(height: AppSpacing.md),
          AttendanceProfileField(
            label: 'Marked By',
            text: getFirstName(absentDay.absentBy),
          ),
          const SizedBox(height: AppSpacing.md),
          AttendanceProfileField(
            label: 'Marked Absent Time',
            text: formatTime(absentDay.absentTime),
            methodIcon: absentDay.markAbsentMethod != null
                ? _absentMethodIcon(absentDay.markAbsentMethod!)
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AttendanceProfileField(
            label: 'Absent Note',
            text: absentDay.note.isNotEmpty ? absentDay.note : '-',
          ),
        ],
      ),
    );
  }
}

class _StudentIconItem extends StatelessWidget {
  const _StudentIconItem(this.icon);

  final String icon;

  @override
  Widget build(BuildContext context) {
    final bool isSvg = icon.toLowerCase().endsWith('.svg');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
      child: isSvg
          ? AppArtwork(icon, height: 20)
          : Image.asset(icon, height: 20),
    );
  }
}

class _StudentIconDetail extends StatelessWidget {
  const _StudentIconDetail(this.iconPath, this.detail);

  final String iconPath;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final bool isSvg = iconPath.toLowerCase().endsWith('.svg');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          isSvg
              ? AppArtwork(iconPath, height: 24)
              : Image.asset(iconPath, height: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppText.body(
              detail,
              style: AppTextStyles.body.copyWith(
                color: AppColors.attendanceBodyText87Color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
