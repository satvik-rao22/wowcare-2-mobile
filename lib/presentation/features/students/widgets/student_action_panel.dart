import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/students/widgets/student_attendance_action_availability.dart';

enum StudentPanelType { attendance, activities, none }

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
    this.activitiesEnabled = true,
    this.showAttendanceActions = false,
    this.onSignInTap,
    this.onSignOutTap,
    this.onTransferTap,
    this.onMarkAbsentTap,
    this.isAttendanceActionLoading = false,
    this.attendanceAvailability = StudentAttendanceActionAvailability.allEnabled,
  });

  final StudentPanelType currentPanel;
  final VoidCallback? onAttendanceTap;
  final VoidCallback? onActivitiesTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onClearSelections;
  final bool isProfileEnabled;
  final bool activitiesEnabled;
  final bool showAttendanceActions;
  final VoidCallback? onSignInTap;
  final VoidCallback? onSignOutTap;
  final VoidCallback? onTransferTap;
  final VoidCallback? onMarkAbsentTap;
  final bool isAttendanceActionLoading;
  final StudentAttendanceActionAvailability attendanceAvailability;

  @override
  State<StudentActionPanel> createState() => _StudentActionPanelState();
}

class _StudentActionPanelState extends State<StudentActionPanel> {
  StudentPanelType _currentPanel = StudentPanelType.none;

  final Map<String, String> _activityIcons = const {
    'NAP START': MediaRes.napActivityIcon,
    'NAP END': MediaRes.napActivityIcon,
    'BATHROOM': MediaRes.bathroomActivityIcon,
    'BOTTLE': MediaRes.bottleActivityIcon,
    'MEAL': MediaRes.mealActivityIcon,
    'INCIDENT': MediaRes.incidentActivityIcon,
    'PHOTO': MediaRes.photoVideoActivityIcon,
    'MEDICATION': MediaRes.medicationActivityIcon,
    'NOTES': MediaRes.notesActivityIcon,
    'OUTDOOR': MediaRes.outdoorActivityIcon,
    'LEARNING': MediaRes.learningActivityIcon,
  };

  void _togglePanel(StudentPanelType panel) {
    setState(() {
      _currentPanel = _currentPanel == panel ? StudentPanelType.none : panel;
    });
  }

  @override
  void initState() {
    super.initState();
    _currentPanel = widget.currentPanel;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_currentPanel != StudentPanelType.none) ...[
          _StudentSidePanel(
            panel: _currentPanel,
            onSignInTap: widget.onSignInTap,
            onSignOutTap: widget.onSignOutTap,
            onTransferTap: widget.onTransferTap,
            onMarkAbsentTap: widget.onMarkAbsentTap,
            isLoading: widget.isAttendanceActionLoading,
            availability: widget.attendanceAvailability,
            activityIcons: _activityIcons,
            onAnyActivityTap: widget.onActivitiesTap,
          ),
          const SizedBox(width: 10),
        ],
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Material(
              borderRadius: BorderRadius.circular(10),
              elevation: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                      disabledTooltip:
                          'Select applicable items to mark an activity',
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
                      color: Colors.black.withOpacity(0.2),
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
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
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
    this.attendanceAvailability = StudentAttendanceActionAvailability.allEnabled,
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
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
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
    required this.activityIcons,
    this.onAnyActivityTap,
  });

  final StudentPanelType panel;
  final VoidCallback? onSignInTap;
  final VoidCallback? onSignOutTap;
  final VoidCallback? onTransferTap;
  final VoidCallback? onMarkAbsentTap;
  final bool isLoading;
  final StudentAttendanceActionAvailability availability;
  final Map<String, String> activityIcons;
  final VoidCallback? onAnyActivityTap;

  static const String _validationTooltip =
      'This action is not allowed for current attendance state';

  @override
  Widget build(BuildContext context) {
    if (panel == StudentPanelType.attendance) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: Container(
          width: 50,
          constraints: const BoxConstraints(maxHeight: 400),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.classroomStudentTabColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildAttendanceColumn(),
        ),
      );
    }
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
        child: _buildActivitiesColumn(),
      ),
    );
  }

  Widget _buildAttendanceColumn() {
    final a = availability;
    bool blocked(bool allowed) => isLoading || !allowed;
    String tooltip(bool allowed) =>
        isLoading ? '' : (!allowed ? _validationTooltip : '');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StudentAttendanceMenuItem(
          svgPath: MediaRes.Sign_in,
          label: 'Sign-in',
          onTap: blocked(a.signInEnabled) ? null : onSignInTap,
          isDisabled: blocked(a.signInEnabled),
          disabledTooltip: tooltip(a.signInEnabled),
        ),
        const SizedBox(height: 5),
        _StudentAttendanceMenuItem(
          svgPath: MediaRes.Sign_out,
          label: 'Sign-Out',
          onTap: blocked(a.signOutEnabled) ? null : onSignOutTap,
          isDisabled: blocked(a.signOutEnabled),
          disabledTooltip: tooltip(a.signOutEnabled),
        ),
        const SizedBox(height: 5),
        _StudentAttendanceMenuItem(
          svgPath: MediaRes.transfer,
          label: 'Transfer',
          onTap: blocked(a.transferEnabled) ? null : onTransferTap,
          isDisabled: blocked(a.transferEnabled),
          disabledTooltip: tooltip(a.transferEnabled),
        ),
        const SizedBox(height: 5),
        _StudentAttendanceMenuItem(
          svgPath: MediaRes.Mark_absent,
          label: 'Absent',
          onTap: blocked(a.absentEnabled) ? null : onMarkAbsentTap,
          isDisabled: blocked(a.absentEnabled),
          disabledTooltip: tooltip(a.absentEnabled),
        ),
      ],
    );
  }

  Widget _buildActivitiesColumn() {
    final items = activityIcons.entries.toList();
    return SizedBox(
      height: 216,
      width: 70,
      child: SingleChildScrollView(
        controller: ScrollController(),
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              _ActivityPngItem(
                pngPath: items[i].value,
                label: _format(items[i].key),
                onTap: onAnyActivityTap,
              ),
              if (i < items.length - 1) const SizedBox(height: 16),
            ]
          ],
        ),
      ),
    );
  }

  String _format(String upper) =>
      upper.substring(0, 1) + upper.substring(1).toLowerCase();
}

/// Matches [StudentAttendanceVerticalPopUp] menu row styling.
class _StudentAttendanceMenuItem extends StatelessWidget {
  const _StudentAttendanceMenuItem({
    required this.svgPath,
    required this.label,
    this.onTap,
    this.isDisabled = false,
    this.disabledTooltip = '',
  });

  final String svgPath;
  final String label;
  final VoidCallback? onTap;
  final bool isDisabled;
  final String disabledTooltip;

  @override
  Widget build(BuildContext context) {
    final showTip = isDisabled && disabledTooltip.isNotEmpty;
    return Tooltip(
      message: showTip ? disabledTooltip : '',
      preferBelow: false,
      triggerMode: TooltipTriggerMode.tap,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      showDuration: const Duration(seconds: 5),
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Opacity(
              opacity: isDisabled ? 0.45 : 1,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(svgPath, height: 24, width: 24),
              ),
            ),
            const SizedBox(height: 5),
            Opacity(
              opacity: isDisabled ? 0.5 : 1,
              child: Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Manrope',
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityPngItem extends StatelessWidget {
  const _ActivityPngItem({
    required this.pngPath,
    required this.label,
    this.onTap,
  });
  final String pngPath;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Image.asset(pngPath, scale: 3.5),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
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
          border: Border.all(
            color: const Color.fromRGBO(170, 141, 255, 1),
          ),
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
    return Tooltip(
      message: !isEnabled ? disabledTooltip : '',
      preferBelow: false,
      triggerMode: TooltipTriggerMode.tap,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      showDuration: const Duration(seconds: 5),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


