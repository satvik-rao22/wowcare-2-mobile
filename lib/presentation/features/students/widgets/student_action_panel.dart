import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/domain/features/activity/entities/activity_setting.dart';
import 'package:wowcare/domain/features/activity/usecases/get_activity_type_details_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_attendance_daily_usecase.dart';
import 'package:wowcare/presentation/features/activities/view/choose_activity.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_permission_service.dart';
import 'package:wowcare/presentation/features/students/widgets/student_attendance_action_availability.dart';
import 'package:wowcare/shared/common/widgets/app_tooltip.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

enum StudentPanelType { attendance, activities, none }

/// Classroom for activity-settings API (parent often passes a new list instance each rebuild).
String? _classroomCodeForActivityMaps(List<Map<String, dynamic>>? maps) {
  if (maps == null || maps.isEmpty) return null;
  final dynamic code =
      maps.first['classroomCode'] ?? maps.first['classroomcode'];
  if (code is String && code.trim().isNotEmpty) return code.trim();
  return null;
}

class StudentActionPanel extends StatefulWidget {
  const StudentActionPanel({
    super.key,
    required this.currentPanel,
    this.onAttendanceTap,
    this.onActivitiesTap,
    this.onMessageTap,
    this.onProfileTap,
    this.onClearSelections,
    this.isProfileEnabled = false,
    this.attendanceEnabled = true,
    this.attendanceDisabledHint,
    this.activitiesEnabled = true,
    this.activitiesDisabledHint,
    this.showAttendanceActions = false,
    this.onSignInTap,
    this.onSignOutTap,
    this.onTransferTap,
    this.onMarkAbsentTap,
    this.isAttendanceActionLoading = false,
    this.attendanceAvailability =
        StudentAttendanceActionAvailability.allEnabled,

    /// Selected students in the same shape as [ChooseActivity.selectedStudents]
    /// (`classroomCode`, `studentCode`, `name`). Drives class activity list + navigation.
    this.activityStudentMaps,

    /// Invoked after an activity is successfully recorded from the Activities
    /// panel, so the host can refresh its roster + caches.
    this.onActivityRecorded,
  });

  final StudentPanelType currentPanel;
  final VoidCallback? onAttendanceTap;
  final VoidCallback? onActivitiesTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onClearSelections;
  final bool isProfileEnabled;

  /// Whether the Attendance button is tappable. Disabled (greyed) when the
  /// selection contains an inactive student.
  final bool attendanceEnabled;

  /// Message shown (tooltip + snackbar) when Attendance is tapped while disabled.
  final String? attendanceDisabledHint;
  final bool activitiesEnabled;

  /// Tooltip when Activities is greyed out (e.g. not all students signed in today).
  final String? activitiesDisabledHint;
  final bool showAttendanceActions;
  final VoidCallback? onSignInTap;
  final VoidCallback? onSignOutTap;
  final VoidCallback? onTransferTap;
  final VoidCallback? onMarkAbsentTap;
  final bool isAttendanceActionLoading;
  final StudentAttendanceActionAvailability attendanceAvailability;
  final List<Map<String, dynamic>>? activityStudentMaps;
  final VoidCallback? onActivityRecorded;

  @override
  State<StudentActionPanel> createState() => _StudentActionPanelState();
}

class _StudentActionPanelState extends State<StudentActionPanel> {
  StudentPanelType _currentPanel = StudentPanelType.none;

  late final GetClassroomActivitySettingsUseCase
  _getClassroomActivitySettingsUseCase;
  late final GetActivityTypeDetailsUseCase _getActivityTypeDetailsUseCase;
  late final GetStudentAttendanceDailyUseCase _getStudentAttendanceDailyUseCase;

  bool _activitiesLoading = false;
  List<String> _visibleActivityKeys = [];
  Set<String>? _enabledActivities;
  Set<String>? _multiStudentAllowed;
  final Map<String, String> _activityTypeCodeByName = {};
  final Map<String, String> _activityDisplayNameByKey = {};
  String? _activitiesLoadClassroomCode;
  String? _pendingNavigationKey;

  /// Avoid duplicate in-flight GET activity-settings for the same classroom.
  String? _inflightActivitySettingsClassroom;

  void _togglePanel(StudentPanelType panel) {
    setState(() {
      _currentPanel = _currentPanel == panel ? StudentPanelType.none : panel;
    });
    if (_currentPanel == StudentPanelType.activities) {
      _ensureActivitySettingsLoaded();
    }
  }

  @override
  void initState() {
    super.initState();
    _currentPanel = widget.currentPanel;
    _getClassroomActivitySettingsUseCase =
        serviceLocator<GetClassroomActivitySettingsUseCase>();
    _getActivityTypeDetailsUseCase =
        serviceLocator<GetActivityTypeDetailsUseCase>();
    _getStudentAttendanceDailyUseCase =
        serviceLocator<GetStudentAttendanceDailyUseCase>();
    if (_currentPanel == StudentPanelType.activities) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureActivitySettingsLoaded();
      });
    }
  }

  @override
  void didUpdateWidget(StudentActionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPanel != oldWidget.currentPanel) {
      _currentPanel = widget.currentPanel;
      if (_currentPanel == StudentPanelType.activities) {
        _ensureActivitySettingsLoaded();
      }
    }
    // Parents rebuild with a fresh [List<Map>] each frame (`!=` is always true).
    // Only drop cached settings when the *classroom* for those maps actually changes.
    if (widget.activityStudentMaps != oldWidget.activityStudentMaps) {
      final prevCc = _classroomCodeForActivityMaps(
        oldWidget.activityStudentMaps,
      );
      final nextCc = _classroomCodeForActivityMaps(widget.activityStudentMaps);
      if (prevCc != nextCc) {
        _activitiesLoadClassroomCode = null;
      }
      if (_currentPanel == StudentPanelType.activities ||
          widget.currentPanel == StudentPanelType.activities) {
        _ensureActivitySettingsLoaded();
      }
    }
  }

  String? _classroomCodeFromMaps() =>
      _classroomCodeForActivityMaps(widget.activityStudentMaps);

  String? _getKnownActivityKeyByNormalized(String normalizedName) {
    for (final key in ChooseActivity.activityIcons.keys) {
      if (key.toLowerCase() == normalizedName) {
        return key;
      }
    }
    return null;
  }

  Future<void> _ensureActivitySettingsLoaded() async {
    final classroomCode = _classroomCodeFromMaps();
    if (classroomCode == null || classroomCode.isEmpty) {
      if (!mounted) return;
      setState(() {
        _activitiesLoading = false;
        _visibleActivityKeys = [];
      });
      return;
    }
    if (_activitiesLoadClassroomCode == classroomCode &&
        _visibleActivityKeys.isNotEmpty) {
      return;
    }
    if (_inflightActivitySettingsClassroom == classroomCode) {
      return;
    }

    _inflightActivitySettingsClassroom = classroomCode;
    setState(() => _activitiesLoading = true);
    try {
      final List<ActivitySetting> settings =
          await _getClassroomActivitySettingsUseCase(
            classroomCode: classroomCode,
            refresh: true,
          );

      final enabled = <String>{};
      final multiAllowed = <String>{};
      final visibleKeys = <String>[];
      final seenKeys = <String>{};
      final codeByName = <String, String>{};
      final displayByKey = <String, String>{};

      for (final setting in settings) {
        final name = setting.activityTypeName.trim();
        if (name.isEmpty) continue;

        final normalized = name.toLowerCase();
        codeByName[normalized] = setting.activityTypeCode;
        final knownKey = _getKnownActivityKeyByNormalized(normalized);
        if (knownKey != null) {
          displayByKey[knownKey] = name;
        }

        if (setting.isEnabled && knownKey != null) {
          enabled.add(normalized);
          if (!seenKeys.contains(knownKey)) {
            seenKeys.add(knownKey);
            visibleKeys.add(knownKey);
          }
        }
        if (setting.isMultiStudent) {
          multiAllowed.add(normalized);
        }
      }

      if (!mounted) return;
      setState(() {
        _enabledActivities = enabled.isEmpty ? null : enabled;
        _multiStudentAllowed = multiAllowed.isEmpty ? null : multiAllowed;
        _activityTypeCodeByName
          ..clear()
          ..addAll(codeByName);
        _activityDisplayNameByKey
          ..clear()
          ..addAll(displayByKey);
        _visibleActivityKeys = visibleKeys;
        _activitiesLoadClassroomCode = classroomCode;
        _activitiesLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      final message = ApiErrorHandler.extractErrorMessage(error);
      CoreUtils.logApiError('StudentActionPanel activity settings: $message');
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isWarning: true,
      );
      setState(() {
        _activitiesLoading = false;
        _visibleActivityKeys = [];
        _activitiesLoadClassroomCode = null;
      });
    } finally {
      if (_inflightActivitySettingsClassroom == classroomCode) {
        _inflightActivitySettingsClassroom = null;
      }
    }
  }

  bool get _isMultipleStudentsSelected =>
      (widget.activityStudentMaps?.length ?? 0) > 1;

  bool _isStudentCurrentlyNapping(Map<String, dynamic> student) {
    final dynamic status = student['nappingStatus'] ?? student['isNapping'];
    if (status == true) return true;
    if (status is String && status.toLowerCase() == 'true') return true;
    return false;
  }

  /// Same rule as [ChooseActivity._hasMixedNappingSelection].
  bool _hasMixedNappingSelection() {
    final maps = widget.activityStudentMaps;
    if (maps == null || maps.isEmpty) return false;
    final hasNapping = maps.any(_isStudentCurrentlyNapping);
    final hasNotNapping = maps.any(
      (student) => !_isStudentCurrentlyNapping(student),
    );
    return hasNapping && hasNotNapping;
  }

  bool _isActivityDisabled(String activityKey, String activityName) {
    final normalized = activityName.toLowerCase();

    if (_enabledActivities != null &&
        !_enabledActivities!.contains(normalized)) {
      return true;
    }

    if (_isMultipleStudentsSelected && _multiStudentAllowed != null) {
      if (!_multiStudentAllowed!.contains(normalized)) {
        return true;
      }
    }

    if (_isMultipleStudentsSelected &&
        activityKey.toLowerCase() == 'nap' &&
        _hasMixedNappingSelection()) {
      return true;
    }

    if (_enabledActivities == null &&
        activityKey == 'Incident' &&
        _isMultipleStudentsSelected) {
      return true;
    }

    return false;
  }

  String _disabledActivityMessage(String activityKey, String activityName) {
    if (_isMultipleStudentsSelected &&
        activityKey.toLowerCase() == 'nap' &&
        _hasMixedNappingSelection()) {
      return 'Nap is disabled for mixed selection. Select either all currently napping students or all not-napping students.';
    }
    if (activityKey == 'Incident' && _isMultipleStudentsSelected) {
      return 'Incident can only be recorded for a single student.';
    }
    return 'This activity is currently disabled';
  }

  /// Re-fetches each selected student's LIVE current classroom from the
  /// ATTENDANCE service right before an activity is created from this panel.
  ///
  /// [widget.activityStudentMaps] carries whatever `classroomCode` the host
  /// screen's student list last loaded, which comes from the student
  /// directory service — a denormalized read model that can lag behind a
  /// transfer for a while (a transfer is an attendance-system write; the
  /// directory record syncs asynchronously). Querying the attendance
  /// service's own "today" view instead — the same system a transfer writes
  /// to — reflects the move immediately, so the activity gets filed under
  /// the classroom the student is ACTUALLY in right now, not the one they
  /// were transferred out of. Falls back to the original entry (best-effort)
  /// if the lookup fails or returns nothing for a given student.
  Future<List<Map<String, dynamic>>> _mapsWithFreshClassroomCodes(
    List<Map<String, dynamic>> maps,
  ) async {
    final studentCodes = maps
        .map((m) => (m['studentCode'] as String?)?.trim() ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    if (studentCodes.isEmpty) return maps;

    try {
      final schoolTimeZone = await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: serviceLocator<StorageService>(),
        apiClient: serviceLocator<ApiClient>(),
      );
      final today = SchoolZoneDateTime.schoolCalendarTodayOnly(schoolTimeZone);
      final attendanceDate =
          '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';

      final page = await _getStudentAttendanceDailyUseCase(
        attendanceDate: attendanceDate,
        studentCodes: studentCodes,
        page: 0,
        size: studentCodes.length,
      );
      final classroomByStudentCode = <String, String>{
        for (final item in page.items)
          if ((item.studentCode ?? '').trim().isNotEmpty)
            item.studentCode!.trim(): item.classroomCode.trim(),
      };
      if (classroomByStudentCode.isEmpty) return maps;

      return maps.map((m) {
        final studentCode = (m['studentCode'] as String?)?.trim() ?? '';
        final freshCode = classroomByStudentCode[studentCode] ?? '';
        return freshCode.isEmpty ? m : {...m, 'classroomCode': freshCode};
      }).toList();
    } catch (_) {
      return maps;
    }
  }

  Future<void> _onActivityItemTapped(String activityKey) async {
    final maps = widget.activityStudentMaps;
    if (maps == null || maps.isEmpty) return;

    final activityName = _activityDisplayNameByKey[activityKey] ?? activityKey;
    if (_isActivityDisabled(activityKey, activityName)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: _disabledActivityMessage(activityKey, activityName),
        isWarning: true,
      );
      return;
    }

    final selectedApiName = activityName;
    final code = _activityTypeCodeByName[selectedApiName.toLowerCase()];
    if (code == null || code.trim().isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Unable to resolve activity code.',
        isWarning: true,
      );
      return;
    }

    setState(() => _pendingNavigationKey = activityKey);
    List<Map<String, dynamic>> freshMaps;
    try {
      final results = await Future.wait([
        _getActivityTypeDetailsUseCase(code: code),
        _mapsWithFreshClassroomCodes(maps),
      ]);
      freshMaps = results[1] as List<Map<String, dynamic>>;
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isWarning: true,
      );
      return;
    }
    if (!mounted) return;
    setState(() => _pendingNavigationKey = null);
    final destinationBuilder = ChooseActivity.activityRoutes[activityKey];
    if (destinationBuilder != null) {
      final (routeName, args) = destinationBuilder(freshMaps);
      final recorded = await context.push<dynamic>(routeName, extra: args);
      // Activity screens pop `true` after a successful create/update.
      if (recorded == true) {
        widget.onActivityRecorded?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_currentPanel != StudentPanelType.none)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _StudentSidePanel(
              panel: _currentPanel,
              onSignInTap: widget.onSignInTap,
              onSignOutTap: widget.onSignOutTap,
              onTransferTap: widget.onTransferTap,
              onMarkAbsentTap: widget.onMarkAbsentTap,
              isLoading: widget.isAttendanceActionLoading,
              availability: widget.attendanceAvailability,
              activitiesLoading: _activitiesLoading,
              visibleActivityKeys: _visibleActivityKeys,
              activityDisplayNameByKey: Map<String, String>.from(
                _activityDisplayNameByKey,
              ),
              pendingNavigationKey: _pendingNavigationKey,
              onActivityTap: _onActivityItemTapped,
              isActivityDisabled: _isActivityDisabled,
              disabledActivityMessage: _disabledActivityMessage,
            ),
          ),
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Material(
              borderRadius: BorderRadius.circular(10),
              elevation: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.buildPrimaryGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(
                      svgPath: MediaRes.attendance_panel_icon,
                      label: 'Attendance',
                      onTap: () {
                        _togglePanel(StudentPanelType.attendance);
                        widget.onAttendanceTap?.call();
                      },
                      isSelected: _currentPanel == StudentPanelType.attendance,
                      isEnabled: widget.attendanceEnabled,
                      disabledTooltip: widget.attendanceEnabled
                          ? ''
                          : (widget.attendanceDisabledHint ??
                                'You cannot mark attendance for inactive student.'),
                    ),
                    const SizedBox(height: 20),
                    _ActionButton(
                      svgPath: MediaRes.activity_panel_icon,
                      label: 'Activities',
                      onTap: widget.activitiesEnabled
                          ? () {
                              _togglePanel(StudentPanelType.activities);
                              widget.onActivitiesTap?.call();
                            }
                          : null,
                      isSelected: _currentPanel == StudentPanelType.activities,
                      isEnabled: widget.activitiesEnabled,
                      disabledTooltip: widget.activitiesEnabled
                          ? ''
                          : (widget.activitiesDisabledHint ??
                                'Activities can be recorded only when all '
                                    'selected students are signed in.'),
                    ),
                    const SizedBox(height: 20),
                    _ActionButton(
                      svgPath: MediaRes.message_panel_icon,
                      label: 'Message',
                      onTap: widget.onMessageTap,
                    ),
                    const SizedBox(height: 20),
                    _ActionButton(
                      svgPath: MediaRes.profile_panel_icon,
                      label: 'Profile',
                      onTap: widget.isProfileEnabled
                          ? widget.onProfileTap
                          : null,
                      isEnabled: widget.isProfileEnabled,
                      disabledTooltip: 'Select only one to view profile',
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, 15),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color.fromRGBO(156, 132, 255, 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() => _currentPanel = StudentPanelType.none);
                      widget.onClearSelections?.call();
                    },
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AttendanceQuickActionsPanel extends StatelessWidget {
  const AttendanceQuickActionsPanel({
    super.key,
    this.onSignInTap,
    this.onSignOutTap,
    this.onTransferTap,
    this.onMarkAbsentTap,
    this.isLoading = false,
    this.attendanceAvailability =
        StudentAttendanceActionAvailability.allEnabled,
  });

  final VoidCallback? onSignInTap;
  final VoidCallback? onSignOutTap;
  final VoidCallback? onTransferTap;
  final VoidCallback? onMarkAbsentTap;
  final bool isLoading;
  final StudentAttendanceActionAvailability attendanceAvailability;

  @override
  Widget build(BuildContext context) {
    final a = attendanceAvailability;
    return Material(
      borderRadius: BorderRadius.circular(10),
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color.fromRGBO(200, 191, 255, 0.7)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xff573353),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _AttendanceChipButton(
                  label: 'Sign In',
                  onTap: isLoading || !a.signInEnabled ? null : onSignInTap,
                ),
                _AttendanceChipButton(
                  label: 'Sign Out',
                  onTap: isLoading || !a.signOutEnabled ? null : onSignOutTap,
                ),
                _AttendanceChipButton(
                  label: 'Transfer',
                  onTap: isLoading || !a.transferEnabled ? null : onTransferTap,
                ),
                _AttendanceChipButton(
                  label: 'Mark Absent',
                  onTap: isLoading || !a.absentEnabled ? null : onMarkAbsentTap,
                ),
              ],
            ),
            if (isLoading) ...[
              const SizedBox(height: 8),
              PrimaryCircularLoader(size: 16, strokeWidth: 2),
            ],
          ],
        ),
      ),
    );
  }
}

class _StudentSidePanel extends StatelessWidget {
  const _StudentSidePanel({
    required this.panel,
    required this.onSignInTap,
    required this.onSignOutTap,
    required this.onTransferTap,
    required this.onMarkAbsentTap,
    required this.isLoading,
    required this.availability,
    required this.activitiesLoading,
    required this.visibleActivityKeys,
    required this.activityDisplayNameByKey,
    required this.pendingNavigationKey,
    required this.onActivityTap,
    required this.isActivityDisabled,
    required this.disabledActivityMessage,
  });

  final StudentPanelType panel;
  final VoidCallback? onSignInTap;
  final VoidCallback? onSignOutTap;
  final VoidCallback? onTransferTap;
  final VoidCallback? onMarkAbsentTap;
  final bool isLoading;
  final StudentAttendanceActionAvailability availability;
  final bool activitiesLoading;
  final List<String> visibleActivityKeys;
  final Map<String, String> activityDisplayNameByKey;
  final String? pendingNavigationKey;
  final Future<void> Function(String activityKey) onActivityTap;
  final bool Function(String activityKey, String activityName)
  isActivityDisabled;
  final String Function(String activityKey, String activityName)
  disabledActivityMessage;

  /// Per-action message explaining why an attendance action is disabled —
  /// mirrors the attendance pop-up. Empty string means "no tooltip".
  ///
  /// Precedence: a STAFF persona that hasn't completed their own sign-in
  /// (no permission to manage student attendance) sees the self-sign-in
  /// message on every action; otherwise the message is status-based.
  String _attendanceDisabledReason(
    BuildContext context, {
    required String action,
    required bool actionEnabled,
  }) {
    if (isLoading || actionEnabled) return '';
    if (!AttendancePermissionService.hasPermissionToManageStudentAttendance(
      context,
    )) {
      return AttendancePermissionService.staffSelfSignInRequiredMessage;
    }
    switch (action) {
      case 'Sign-In':
        return 'Sign-In can only be done for Students/Staff not signed in.';
      case 'Sign-Out':
        return 'Sign-Out can only be done for Students/Staff already signed in.';
      case 'Transfer':
        return 'Transfer can only be done for Students/Staff already signed in.';
      case 'Absent':
        return 'Absent can only be marked for Students/Staff not yet signed in';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (panel == StudentPanelType.attendance) {
      return Container(
        width: 70,
        constraints: const BoxConstraints(maxHeight: 400),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: const Color.fromRGBO(111, 140, 255, 1)),
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _buildAttendanceColumn(context),
      );
    }
    return Material(
      borderRadius: BorderRadius.circular(10),
      elevation: 3,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400, maxWidth: 120),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color.fromRGBO(200, 191, 255, 0.7)),
        ),
        child: _buildActivitiesColumn(context),
      ),
    );
  }

  Widget _buildAttendanceColumn(BuildContext context) {
    final a = availability;
    bool enabled(bool allowed) => !isLoading && allowed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StudentAttendanceActionItem(
          svgPath: MediaRes.Sign_in,
          label: 'Sign-In',
          onTap: enabled(a.signInEnabled) ? onSignInTap : null,
          isEnabled: enabled(a.signInEnabled),
          disabledTooltip: _attendanceDisabledReason(
            context,
            action: 'Sign-In',
            actionEnabled: enabled(a.signInEnabled),
          ),
        ),
        const SizedBox(height: 5),
        _StudentAttendanceActionItem(
          svgPath: MediaRes.Sign_out,
          label: 'Sign-Out',
          onTap: enabled(a.signOutEnabled) ? onSignOutTap : null,
          isEnabled: enabled(a.signOutEnabled),
          disabledTooltip: _attendanceDisabledReason(
            context,
            action: 'Sign-Out',
            actionEnabled: enabled(a.signOutEnabled),
          ),
        ),
        const SizedBox(height: 5),
        _StudentAttendanceActionItem(
          svgPath: MediaRes.transfer,
          label: 'Transfer',
          onTap: enabled(a.transferEnabled) ? onTransferTap : null,
          isEnabled: enabled(a.transferEnabled),
          disabledTooltip: _attendanceDisabledReason(
            context,
            action: 'Transfer',
            actionEnabled: enabled(a.transferEnabled),
          ),
        ),
        const SizedBox(height: 5),
        _StudentAttendanceActionItem(
          svgPath: MediaRes.Mark_absent,
          label: 'Absent',
          onTap: enabled(a.absentEnabled) ? onMarkAbsentTap : null,
          isEnabled: enabled(a.absentEnabled),
          disabledTooltip: _attendanceDisabledReason(
            context,
            action: 'Absent',
            actionEnabled: enabled(a.absentEnabled),
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesColumn(BuildContext context) {
    if (activitiesLoading) {
      return const SizedBox(
        width: 100,
        height: 120,
        child: Center(child: PrimaryCircularLoader(size: 32, strokeWidth: 3)),
      );
    }
    if (visibleActivityKeys.isEmpty) {
      return const SizedBox(
        width: 100,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'No activities for this class',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < visibleActivityKeys.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Builder(
              builder: (context) {
                final key = visibleActivityKeys[i];
                final iconPath = ChooseActivity.activityIcons[key];
                if (iconPath == null) return const SizedBox.shrink();
                final displayName = activityDisplayNameByKey[key] ?? key;
                final disabled = isActivityDisabled(key, displayName);
                final pending = pendingNavigationKey == key;
                return _ActivityPngItem(
                  pngPath: iconPath,
                  label: displayName,
                  disabled: disabled,
                  busy: pending,
                  tooltip: disabled
                      ? disabledActivityMessage(key, displayName)
                      : '',
                  onTap: () => onActivityTap(key),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Matches staff [_AttendanceActionItem] in [StaffActionPanel].
class _StudentAttendanceActionItem extends StatelessWidget {
  const _StudentAttendanceActionItem({
    required this.svgPath,
    required this.label,
    this.onTap,
    this.isEnabled = true,
    this.disabledTooltip = '',
  });

  final String svgPath;
  final String label;
  final VoidCallback? onTap;
  final bool isEnabled;
  final String disabledTooltip;

  @override
  Widget build(BuildContext context) {
    final double opacity = isEnabled ? 1.0 : 0.45;
    return AppTooltip(
      message: !isEnabled ? disabledTooltip : '',
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        child: Opacity(
          opacity: opacity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(svgPath, height: 24, width: 24),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Manrope',
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityPngItem extends StatelessWidget {
  const _ActivityPngItem({
    required this.pngPath,
    required this.label,
    required this.onTap,
    this.disabled = false,
    this.busy = false,
    this.tooltip = '',
  });
  final String pngPath;
  final String label;
  final VoidCallback onTap;
  final bool disabled;
  final bool busy;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final opacity = disabled ? 0.45 : 1.0;
    return AppTooltip(
      message: disabled && tooltip.isNotEmpty ? tooltip : '',
      child: InkWell(
        onTap: disabled || busy ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: opacity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 36,
                child: busy
                    ? const Center(
                        child: PrimaryCircularLoader(size: 22, strokeWidth: 2),
                      )
                    : Image.asset(pngPath, scale: 3.5),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Manrope',
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceChipButton extends StatelessWidget {
  const _AttendanceChipButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: onTap == null
              ? const Color.fromRGBO(242, 242, 242, 1)
              : const Color.fromRGBO(241, 234, 255, 1),
          border: Border.all(color: const Color.fromRGBO(170, 141, 255, 1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: onTap == null
                ? const Color.fromRGBO(130, 130, 130, 1)
                : const Color(0xff573353),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.svgPath,
    required this.label,
    this.onTap,
    this.isSelected = false,
    this.isEnabled = true,
    this.disabledTooltip = '',
  });

  final String svgPath;
  final String label;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isEnabled;
  final String disabledTooltip;

  @override
  Widget build(BuildContext context) {
    final double opacity = isEnabled ? 1.0 : 0.5;
    return AppTooltip(
      message: !isEnabled ? disabledTooltip : '',
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        child: Opacity(
          opacity: opacity,
          child: Column(
            children: [
              SvgPicture.asset(
                svgPath,
                height: 24,
                width: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
