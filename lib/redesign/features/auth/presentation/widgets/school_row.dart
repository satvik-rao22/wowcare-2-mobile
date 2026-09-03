import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/auth/auth_sizes.dart';
import 'package:wowcare/redesign/features/auth/auth_strings.dart';
import 'package:wowcare/redesign/features/auth/models/models.dart';

/// One school on 1c.
///
/// The school the account last worked in wears the student tint and a teal
/// tick; the rest are plain cards showing their school code. A school that is
/// not active yet is drawn and dimmed rather than hidden, so the reviewer can
/// see that it exists and why it will not open.
class SchoolRow extends StatelessWidget {
  const SchoolRow({required this.school, required this.onTap, super.key});

  final AuthSchool school;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final isCurrent = school.isCurrent;

    final row = SurfaceBox(
      surface: AppSurfaces.radioCard(c, selected: isCurrent),
      padding: AuthSizes.schoolRowPad,
      child: Row(
        spacing: AuthSizes.schoolRowGap,
        children: <Widget>[
          AppAvatar(
            initials: school.initials,
            size: AuthSizes.schoolAvatar,
            tone: isCurrent ? AvatarTone.student : AvatarTone.neutral,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSizes.rowTextGap,
              children: <Widget>[
                Text(
                  school.name,
                  style: AppTextStyles.cardTitle.copyWith(color: c.ink),
                ),
                Text(
                  _subline,
                  style: AppTextStyles.subLine.copyWith(
                    color: isCurrent ? c.student : c.ink3,
                  ),
                ),
              ],
            ),
          ),
          if (isCurrent)
            Icon(
              AppIcons.check,
              size: AuthSizes.schoolTick,
              color: c.student,
            ),
        ],
      ),
    );

    if (school.isLocked) {
      return Semantics(
        enabled: false,
        label: '${school.name}. ${AuthStrings.pendingApproval}',
        child: Opacity(opacity: _lockedOpacity, child: row),
      );
    }

    return Semantics(
      button: true,
      selected: isCurrent,
      label: school.name,
      child: Pressable.surface(onTap: onTap, child: row),
    );
  }

  /// How far a school that cannot be opened is faded back.
  static const double _lockedOpacity = .55;

  String get _subline {
    if (school.isLocked) return AuthStrings.pendingApproval;
    return school.isCurrent ? AuthStrings.currentSchool : school.code;
  }
}
