import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';

enum StaffPanelType { attendance, activities, none }

class StaffActionPanel extends StatefulWidget {
  const StaffActionPanel({
    super.key,
    required this.currentPanel,
    this.onAttendanceTap,
    this.onActivitiesTap,
    this.onMessageTap,
    this.onProfileTap,
    this.onClearSelections,
    this.onSignIn,
    this.onSignOut,
    this.onTransfer,
    this.onAbsent,
    this.isProfileEnabled = false,
    this.activitiesEnabled = true,
  });

  final StaffPanelType currentPanel;
  final VoidCallback? onAttendanceTap;
  final VoidCallback? onActivitiesTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onClearSelections;
  final VoidCallback? onSignIn;
  final VoidCallback? onSignOut;
  final VoidCallback? onTransfer;
  final VoidCallback? onAbsent;
  final bool isProfileEnabled;
  final bool activitiesEnabled;

  @override
  State<StaffActionPanel> createState() => _StaffActionPanelState();
}

class _StaffActionPanelState extends State<StaffActionPanel> {
  StaffPanelType _current = StaffPanelType.none;

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

  void _toggleAttendancePanel() {
    setState(() {
      _current = _current == StaffPanelType.attendance
          ? StaffPanelType.none
          : StaffPanelType.attendance;
    });
    widget.onAttendanceTap?.call();
  }

  void _toggleActivitiesPanel() {
    setState(() {
      _current = _current == StaffPanelType.activities
          ? StaffPanelType.none
          : StaffPanelType.activities;
    });
    widget.onActivitiesTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_current != StaffPanelType.none)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _current == StaffPanelType.attendance
                ? _AttendanceOptionsPanel(
                    onSignIn: widget.onSignIn,
                    onSignOut: widget.onSignOut,
                    onTransfer: widget.onTransfer,
                    onAbsent: widget.onAbsent,
                  )
                : _ActivitiesOptionsPanel(
                    activityIcons: _activityIcons,
                    onAnyActivityTap: widget.onActivitiesTap,
                  ),
          ),
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
                      onTap: _toggleAttendancePanel,
                      isSelected: _current == StaffPanelType.attendance,
                    ),
                    const SizedBox(height: 20),
                    _ActionButton(
                      svgPath: MediaRes.activity_panel_icon,
                      label: 'Activities',
                      onTap: _toggleActivitiesPanel,
                      isSelected: _current == StaffPanelType.activities,
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
                      onTap: widget.isProfileEnabled ? widget.onProfileTap : null,
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
                    setState(() => _current = StaffPanelType.none);
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

class _AttendanceOptionsPanel extends StatelessWidget {
  const _AttendanceOptionsPanel({
    this.onSignIn,
    this.onSignOut,
    this.onTransfer,
    this.onAbsent,
  });

  final VoidCallback? onSignIn;
  final VoidCallback? onSignOut;
  final VoidCallback? onTransfer;
  final VoidCallback? onAbsent;

  @override
  Widget build(BuildContext context) {
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AttendanceActionItem(
            svgPath: MediaRes.Sign_in,
            label: 'Sign-In',
            onTap: onSignIn,
          ),
          const SizedBox(height: 5),
          _AttendanceActionItem(
            svgPath: MediaRes.Sign_out,
            label: 'Sign-Out',
            onTap: onSignOut,
          ),
          const SizedBox(height: 5),
          _AttendanceActionItem(
            svgPath: MediaRes.transfer,
            label: 'Transfer',
            onTap: onTransfer,
          ),
          const SizedBox(height: 5),
          _AttendanceActionItem(
            svgPath: MediaRes.Mark_absent,
            label: 'Absent',
            onTap: onAbsent,
          ),
        ],
      ),
    );
  }
}

class _ActivitiesOptionsPanel extends StatelessWidget {
  const _ActivitiesOptionsPanel({
    required this.activityIcons,
    this.onAnyActivityTap,
  });

  final Map<String, String> activityIcons;
  final VoidCallback? onAnyActivityTap;

  @override
  Widget build(BuildContext context) {
    final items = activityIcons.entries.toList();
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: ScrollController(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < items.length; i++) ...[
              _ActivityPngItem(
                pngPath: items[i].value,
                label: _format(items[i].key),
                onTap: onAnyActivityTap,
              ),
              if (i < items.length - 1) const SizedBox(height: 5),
            ]
          ],
        ),
      ),
    );
  }

  String _format(String upper) =>
      upper.substring(0, 1) + upper.substring(1).toLowerCase();
}

class _AttendanceActionItem extends StatelessWidget {
  const _AttendanceActionItem({
    required this.svgPath,
    required this.label,
    this.onTap,
  });

  final String svgPath;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              svgPath,
              height: 24,
              width: 24,
            ),
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
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(pngPath, scale: 3.5),
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
    );
  }
}


