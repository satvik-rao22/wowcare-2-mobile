import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/profile/models/models.dart';
import 'package:wowcare/redesign/features/profile/profile_sizes.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';
import 'package:wowcare/redesign/features/profile/profile_text_styles.dart';

/// One of a guardian's students, on 13c's "Your children" card.
///
/// A student who is in today sits on the student teal; anyone else sits on
/// the quiet ground. Teal means students here, not "good".
class ProfileChildRow extends StatelessWidget {
  const ProfileChildRow({required this.child, required this.onOpen, super.key});

  final ProfileChild child;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final isIn = child.attendance == AttendanceStatus.signedIn;
    final ink = isIn ? c.student : c.ink3;

    return Pressable.surface(
      onTap: onOpen,
      child: SurfaceBox(
        surface: _ground(c, isIn: isIn),
        padding: ProfileSizes.childRowPad,
        child: Row(
          spacing: ProfileSizes.childRowGap,
          children: <Widget>[
            AppAvatar(
              initials: child.initials,
              size: ProfileSizes.childAvatar,
              tone: isIn ? AvatarTone.student : AvatarTone.neutral,
              textStyle: ProfileTextStyles.childInitials,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    child.name,
                    style: ProfileTextStyles.actionRow.copyWith(color: c.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _line,
                    style: ProfileTextStyles.childSub.copyWith(color: ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SurfaceBox(
              surface: AppSurfaces.pill(fill: c.card),
              padding: ProfileSizes.openPillPad,
              child: Text(
                ProfileStrings.open,
                style: ProfileTextStyles.openPill.copyWith(color: ink),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Bluebell · Signed In 9:12 AM", or the status on its own.
  String get _line {
    final status = switch (child.attendance) {
      AttendanceStatus.signedIn => AppStrings.signedIn,
      AttendanceStatus.signedOut => AppStrings.signedOut,
      AttendanceStatus.absent => AppStrings.absent,
      AttendanceStatus.notMarked => AppStrings.notMarked,
    };
    return child.timeLabel.isEmpty
        ? ProfileStrings.childLine(child.classroomName, status)
        : ProfileStrings.childTimedLine(
            child.classroomName,
            status,
            child.timeLabel,
          );
  }

  static Surface _ground(Colourway c, {required bool isIn}) => Surface(
    borderRadius: AppSurfaces.altWell(c).borderRadius,
    decoration: AppSurfaces.altWell(c).decoration.copyWith(
      color: isIn ? c.studentBg : c.sub,
      border: isIn ? Border.all(color: c.studentRim) : null,
    ),
  );
}
