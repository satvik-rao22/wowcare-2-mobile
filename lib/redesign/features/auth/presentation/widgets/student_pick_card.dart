import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_motion.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/auth/auth_sizes.dart';

/// One of a guardian's students on 2c.
///
/// Ticked, it takes the student tint and its check tile fills teal. A student
/// the chosen direction cannot move is drawn but dimmed and inert: signing in
/// somebody who is already Signed In records nothing.
class StudentPickCard extends StatelessWidget {
  const StudentPickCard({
    required this.name,
    required this.initials,
    required this.subline,
    required this.attendance,
    required this.selected,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final String name;
  final String initials;

  /// "Sunflower · Not Marked", or "Willow · in since 8:06 AM".
  final String subline;

  final AttendanceStatus attendance;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  /// How far a student who cannot move this way is faded back.
  static const double _inertOpacity = .5;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    final card = SurfaceBox(
      surface: AppSurfaces.radioCard(c, selected: selected),
      padding: AuthSizes.pickCardPad,
      child: Row(
        spacing: AuthSizes.pickCardGap,
        children: <Widget>[
          _CheckTile(selected: selected, colours: c),
          AppAvatar(
            initials: initials,
            size: AuthSizes.pickAvatar,
            attendance: attendance,
            ringColor: selected ? c.studentBg : c.card,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSizes.rowTextGap,
              children: <Widget>[
                Text(
                  name,
                  style: AppTextStyles.cardTitle.copyWith(color: c.ink),
                ),
                Text(
                  subline,
                  style: AppTextStyles.rowSub.copyWith(color: c.ink3),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!enabled) {
      return Semantics(
        enabled: false,
        label: '$name. $subline',
        child: Opacity(opacity: _inertOpacity, child: card),
      );
    }

    return Semantics(
      checked: selected,
      label: name,
      child: Pressable.surface(onTap: onTap, child: card),
    );
  }
}

/// The square tick beside the avatar. Square is a badge; round is a someone.
class _CheckTile extends StatelessWidget {
  const _CheckTile({required this.selected, required this.colours});

  final bool selected;
  final Colourway colours;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: AppMotion.fast,
    curve: AppMotion.ease,
    width: AuthSizes.pickCheck,
    height: AuthSizes.pickCheck,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: selected ? colours.student : colours.well,
      borderRadius: BorderRadius.circular(AuthSizes.pickCheckRadius),
    ),
    child: selected
        ? Icon(
            AppIcons.check,
            size: AuthSizes.pickCheckGlyph,
            color: colours.onImpact,
          )
        : null,
  );
}
