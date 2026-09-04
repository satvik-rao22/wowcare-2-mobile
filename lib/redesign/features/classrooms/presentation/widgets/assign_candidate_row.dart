import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/app_checkbox.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';

/// One person an assign flow could add (7g, 7h).
///
/// In step one it carries a checkbox; in step two it carries the cross that
/// takes them back out of the pick. A student outside the classroom's age
/// band is flagged, never blocked: the web client warns and still assigns.
class AssignCandidateRow extends StatelessWidget {
  const AssignCandidateRow({
    required this.candidate,
    required this.isStaff,
    this.isPicked = false,
    this.showCheckbox = true,
    this.onTap,
    this.onRemove,
    super.key,
  });

  final AssignCandidate candidate;

  /// Staff read in sun and carry a designation; students read in teal.
  final bool isStaff;

  final bool isPicked;
  final bool showCheckbox;

  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: ClassroomsSizes.candidateRowPad,
      onTap: onTap,
      child: Row(
        spacing: ClassroomsSizes.candidateGap,
        children: <Widget>[
          if (showCheckbox) AppCheckbox(checked: isPicked),
          SurfaceBox(
            surface: AppSurfaces.avatar(
              c,
              fill: isStaff ? c.staffBg : c.studentBg,
              size: ClassroomsSizes.candidateAvatar,
            ),
            width: ClassroomsSizes.candidateAvatar,
            height: ClassroomsSizes.candidateAvatar,
            alignment: Alignment.center,
            child: Text(
              candidate.initials,
              style: ClassroomsTextStyles.rosterInitials.copyWith(
                color: isStaff ? c.staffFg : c.student,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: ClassroomsSizes.staffRowTextGap,
              children: <Widget>[
                Text(
                  candidate.name,
                  style: ClassroomsTextStyles.candidateName.copyWith(
                    color: c.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _subtitle,
                  style: ClassroomsTextStyles.candidateSub.copyWith(
                    color: candidate.isOutsideAgeRange ? c.staffFg : c.ink3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (candidate.note != null)
                  Text(
                    candidate.note!,
                    style: ClassroomsTextStyles.staffMeta.copyWith(
                      color: c.ink3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (candidate.isOutsideAgeRange)
            const StatusPill(
              label: ClassroomsStrings.ageFlag,
              tone: PillTone.staff,
              small: true,
            ),
          if (onRemove != null)
            _RemoveKey(onTap: onRemove!, name: candidate.name),
        ],
      ),
    );
  }

  String get _subtitle => isStaff
      ? (candidate.designation ?? '')
      : ClassroomsStrings.candidateSub(candidate.age, candidate.group);
}

/// The small cross that takes somebody back out of the pick.
class _RemoveKey extends StatelessWidget {
  const _RemoveKey({required this.onTap, required this.name});

  final VoidCallback onTap;
  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      label: name,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: AppSurfaces.glyphTile(
            c,
            fill: c.sub,
            radius: ClassroomsSizes.removeKeyRadius,
          ),
          width: ClassroomsSizes.removeKey,
          height: ClassroomsSizes.removeKey,
          alignment: Alignment.center,
          child: Icon(
            AppIcons.close,
            size: ClassroomsSizes.removeGlyph,
            color: c.dangerFg,
          ),
        ),
      ),
    );
  }
}
