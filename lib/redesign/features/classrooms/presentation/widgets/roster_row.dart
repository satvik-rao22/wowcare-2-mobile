import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/app_checkbox.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/tone_colors.dart';

/// One student on a classroom's roster (7c, 7e), with the panel that opens
/// under it: care needs, the days they are here, their guardian, and any move
/// already booked.
///
/// Today's attendance is the ring around the avatar, which is how the whole
/// app says it. [isLocked] is the teacher's view before they are on the
/// clock: the row is readable, dimmed, and does not open.
class RosterRow extends StatelessWidget {
  const RosterRow({
    required this.student,
    this.isExpanded = false,
    this.isSelectMode = false,
    this.isSelected = false,
    this.isLocked = false,
    this.onTap,
    this.onOpenProfile,
    this.onMoreActions,
    super.key,
  });

  final RosterStudent student;
  final bool isExpanded;
  final bool isSelectMode;
  final bool isSelected;
  final bool isLocked;

  final VoidCallback? onTap;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onMoreActions;

  @override
  Widget build(BuildContext context) {
    final row = AppCard(
      padding: null,
      clipContent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Pressable.surface(
            onTap: isLocked ? null : onTap,
            child: Padding(
              padding: ClassroomsSizes.rosterRowPad,
              child: _Head(
                student: student,
                isExpanded: isExpanded,
                isSelectMode: isSelectMode,
                isSelected: isSelected,
              ),
            ),
          ),
          if (isExpanded && !isLocked)
            _Panel(
              student: student,
              onOpenProfile: onOpenProfile,
              onMoreActions: onMoreActions,
            ),
        ],
      ),
    );

    if (!isLocked) return row;
    return Opacity(opacity: ClassroomsSizes.lockedRowOpacity, child: row);
  }
}

class _Head extends StatelessWidget {
  const _Head({
    required this.student,
    required this.isExpanded,
    required this.isSelectMode,
    required this.isSelected,
  });

  final RosterStudent student;
  final bool isExpanded;
  final bool isSelectMode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Row(
      spacing: ClassroomsSizes.rosterGapInner,
      children: <Widget>[
        if (isSelectMode) AppCheckbox(checked: isSelected),
        _RingedAvatar(initials: student.initials, status: student.attendance),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSizes.rowTextGap,
            children: <Widget>[
              Text(
                student.name,
                style: AppTextStyles.rowName.copyWith(color: c.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                ClassroomsStrings.rowSub(
                  student.age,
                  _statusWord(student.attendance),
                  student.timeLabel,
                ),
                style: AppTextStyles.rowSub.copyWith(color: c.ink3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (student.flag != null)
          Container(
            padding: ClassroomsSizes.flagPillPad,
            decoration: AppSurfaces.pill(
              fill: student.flagTone.fill(c),
            ).decoration,
            child: Text(
              student.flag!,
              style: ClassroomsTextStyles.flagPill.copyWith(
                color: student.flagTone.ink(c),
              ),
            ),
          ),
        Icon(
          isExpanded ? AppIcons.chevronUp : AppIcons.chevronDown,
          size: ClassroomsSizes.rowCaret,
          color: c.ink3,
        ),
      ],
    );
  }

  static String _statusWord(AttendanceStatus status) => switch (status) {
    AttendanceStatus.signedIn => AppStrings.signedIn,
    AttendanceStatus.signedOut => AppStrings.signedOut,
    AttendanceStatus.absent => AppStrings.absent,
    AttendanceStatus.notMarked => AppStrings.notMarked,
  };
}

/// The avatar with today's attendance drawn as a ring around it rather than
/// as a dot beside it: on a roster the status is the first thing read.
class _RingedAvatar extends StatelessWidget {
  const _RingedAvatar({required this.initials, required this.status});

  final String initials;
  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Container(
      width: ClassroomsSizes.rosterAvatar,
      height: ClassroomsSizes.rosterAvatar,
      padding: const EdgeInsets.all(ClassroomsSizes.rosterRingPad),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: status.colour(c),
          width: ClassroomsSizes.rosterRing,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.studentBg),
        child: Center(
          child: Text(
            initials,
            style: ClassroomsTextStyles.rosterInitials.copyWith(
              color: c.student,
            ),
          ),
        ),
      ),
    );
  }
}

/// What opens under the row: everything the classroom needs to know about
/// this student without leaving the roster.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.student,
    required this.onOpenProfile,
    required this.onMoreActions,
  });

  final RosterStudent student;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onMoreActions;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Padding(
      padding: ClassroomsSizes.expandedPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ClassroomsSizes.expandedGap,
        children: <Widget>[
          Container(height: AppSizes.hairline, color: c.divider),
          _careNeeds(c),
          _schedule(c),
          _Fact(
            label: ClassroomsStrings.parent,
            value: student.guardianName == null
                ? ClassroomsStrings.noGuardianLinked
                : ClassroomsStrings.guardianLinked(student.guardianName!),
          ),
          _Fact(
            label: ClassroomsStrings.classroomMove,
            value: student.moveNote ?? ClassroomsStrings.noMovePlanned,
          ),
          Row(
            spacing: ClassroomsSizes.actionGap,
            children: <Widget>[
              Expanded(
                child: SecondaryKey(
                  label: ClassroomsStrings.moreActions,
                  onTap: onMoreActions,
                ),
              ),
              Expanded(
                child: PrimaryKey(
                  label: ClassroomsStrings.openProfile,
                  onTap: onOpenProfile,
                  padding: ClassroomsSizes.actionKeyPad,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _careNeeds(Colourway c) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: ClassroomsSizes.actionGap,
    children: <Widget>[
      SizedBox(
        width: ClassroomsSizes.expandedLabelWidth,
        child: Text(
          ClassroomsStrings.careNeeds,
          style: ClassroomsTextStyles.factLabel.copyWith(color: c.ink3),
        ),
      ),
      Expanded(
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: ClassroomsSizes.tagGap,
          runSpacing: ClassroomsSizes.tagGap,
          children: <Widget>[
            if (student.careNeeds.isEmpty)
              Text(
                ClassroomsStrings.noCareNeeds,
                style: ClassroomsTextStyles.factValue.copyWith(color: c.ink),
              )
            else
              for (final tag in student.careNeeds)
                Container(
                  padding: ClassroomsSizes.tagPad,
                  decoration: BoxDecoration(
                    color: tag.tone.fill(c),
                    borderRadius: BorderRadius.circular(
                      ClassroomsSizes.tagRadius,
                    ),
                  ),
                  child: Text(
                    tag.label,
                    style: ClassroomsTextStyles.tag.copyWith(
                      color: tag.tone.ink(c),
                    ),
                  ),
                ),
          ],
        ),
      ),
    ],
  );

  Widget _schedule(Colourway c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: ClassroomsSizes.factGap,
    children: <Widget>[
      Text(
        ClassroomsStrings.scheduleHere,
        style: ClassroomsTextStyles.factLabel.copyWith(color: c.ink3),
      ),
      Row(
        spacing: ClassroomsSizes.dayGap,
        children: <Widget>[
          for (final (i, label) in ClassroomsStrings.weekdayInitials.indexed)
            Expanded(
              child: _DaySquare(
                label: label,
                isOn: i < student.weekdays.length && student.weekdays[i],
              ),
            ),
        ],
      ),
      if (student.hours.isNotEmpty)
        Text(
          student.hours,
          style: ClassroomsTextStyles.hours.copyWith(color: c.ink3),
        ),
    ],
  );
}

class _DaySquare extends StatelessWidget {
  const _DaySquare({required this.label, required this.isOn});

  final String label;
  final bool isOn;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Opacity(
      opacity: isOn ? 1 : ClassroomsSizes.dayOffOpacity,
      child: Container(
        padding: ClassroomsSizes.dayPad,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isOn ? c.studentBg : c.well,
          borderRadius: BorderRadius.circular(ClassroomsSizes.dayRadius),
        ),
        child: Text(
          label,
          style: ClassroomsTextStyles.tag.copyWith(
            color: isOn ? c.student : c.ink3,
          ),
        ),
      ),
    );
  }
}

/// A label on the left, its value on the right.
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Row(
      spacing: ClassroomsSizes.actionGap,
      children: <Widget>[
        Text(
          label,
          style: ClassroomsTextStyles.factLabel.copyWith(color: c.ink3),
        ),
        Expanded(
          child: Text(
            value,
            style: ClassroomsTextStyles.factValue.copyWith(color: c.ink),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
