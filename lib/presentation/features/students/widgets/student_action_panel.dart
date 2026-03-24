import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';

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
  });

  final VoidCallback? onSignInTap;
  final VoidCallback? onSignOutTap;
  final VoidCallback? onTransferTap;
  final VoidCallback? onMarkAbsentTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
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
                  onTap: isLoading ? null : onSignInTap,
                ),
                _AttendanceChipButton(
                  label: 'Sign Out',
                  onTap: isLoading ? null : onSignOutTap,
                ),
                _AttendanceChipButton(
                  label: 'Transfer',
                  onTap: isLoading ? null : onTransferTap,
                ),
                _AttendanceChipButton(
                  label: 'Mark Absent',
                  onTap: isLoading ? null : onMarkAbsentTap,
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
    required this.activityIcons,
    this.onAnyActivityTap,
  });

  final StudentPanelType panel;
  final VoidCallback? onSignInTap;
  final VoidCallback? onSignOutTap;
  final VoidCallback? onTransferTap;
  final VoidCallback? onMarkAbsentTap;
  final bool isLoading;
  final Map<String, String> activityIcons;
  final VoidCallback? onAnyActivityTap;

  @override
  Widget build(BuildContext context) {
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
        child: panel == StudentPanelType.attendance
            ? _buildAttendanceColumn()
            : _buildActivitiesColumn(),
      ),
    );
  }

  Widget _buildAttendanceColumn() {
    return Column(
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
          direction: Axis.vertical,
          spacing: 16,
          children: [
            _AttendanceIconItem(
              svgPath: MediaRes.Sign_in,
              label: 'Sign In',
              onTap: isLoading ? null : onSignInTap,
            ),
            _AttendanceIconItem(
              svgPath: MediaRes.Sign_out,
              label: 'Sign Out',
              onTap: isLoading ? null : onSignOutTap,
            ),
            _AttendanceIconItem(
              svgPath: MediaRes.transfer,
              label: 'Transfer',
              onTap: isLoading ? null : onTransferTap,
            ),
            _AttendanceIconItem(
              svgPath: MediaRes.Mark_absent,
              label: 'Absent',
              onTap: isLoading ? null : onMarkAbsentTap,
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

class _AttendanceIconItem extends StatelessWidget {
  const _AttendanceIconItem({
    required this.svgPath,
    required this.label,
    this.onTap,
  });
  final String svgPath;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          SvgPicture.asset(svgPath, height: 24, width: 24),
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


