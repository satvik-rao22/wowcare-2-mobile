import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// Who an avatar stands for. Teal is a student, sun is staff.
enum AvatarTone {
  student,
  staff,

  /// Navy, for the signed-in person on an impact surface or the More header.
  impact,

  /// Well grey, for a student who has not started yet (5a "Starting soon").
  neutral;

  Color fill(Colourway c) => switch (this) {
    AvatarTone.student => c.studentBg,
    AvatarTone.staff => c.staffBg,
    AvatarTone.impact => c.avatar,
    AvatarTone.neutral => c.well,
  };

  Color ink(Colourway c) => switch (this) {
    AvatarTone.student => c.student,
    AvatarTone.staff => c.staffFg,
    AvatarTone.impact => c.onAvatar,
    AvatarTone.neutral => c.ink2,
  };
}

/// A round initials bubble, 44px by default. Components page `.avatar`.
///
/// Round is a list row's leading slot; square is a badge. [attendance] draws
/// today's status as a 13px dot at the bottom-right, ringed in [ringColor]
/// (the card it sits on, by default) so it reads at a glance.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.initials,
    this.size = AppSizes.avatar,
    this.tone = AvatarTone.student,
    this.attendance,
    this.ringColor,
    this.textStyle = AppTextStyles.avatarInitials,
    super.key,
  });

  final String initials;
  final double size;
  final AvatarTone tone;

  /// Today's attendance. Null draws no dot.
  final AttendanceStatus? attendance;

  /// The ground the dot's ring is painted in. Defaults to the card colour.
  final Color? ringColor;

  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    final bubble = SurfaceBox(
      surface: AppSurfaces.avatar(c, fill: tone.fill(c), size: size),
      width: size,
      height: size,
      alignment: Alignment.center,
      child: Text(initials, style: textStyle.copyWith(color: tone.ink(c))),
    );

    if (attendance == null) return bubble;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          bubble,
          Positioned(
            right: -AppSizes.attendanceDotOverhang,
            bottom: -AppSizes.attendanceDotOverhang,
            child: AttendanceDot(status: attendance!, ringColor: ringColor),
          ),
        ],
      ),
    );
  }
}
