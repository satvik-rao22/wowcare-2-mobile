import 'package:flutter/material.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';
import '../../domain/entities/staff_overtime_profile.dart';
import 'av2_pill.dart';
import 'package:wowcare/shared/common/widgets/profile_avatar.dart';

/// Avatar + name + designation·classroom + today-status pill. Used in the
/// detail header (mobile) and beside the date controls (desktop).
class Av2IdentityRow extends StatelessWidget {
  const Av2IdentityRow({
    super.key,
    required this.profile,
    this.avatarSize = 48,
    this.onTap,
  });

  final StaffOvertimeProfile profile;
  final double avatarSize;

  /// When non-null (admin), the row becomes a tappable "switch staff" control
  /// and shows a dropdown chevron next to the name.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        _avatar(),
        const SizedBox(width: Av2Spacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      profile.staffName,
                      style: Av2Text.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 22,
                      color: Av2Colors.textSecondary,
                    ),
                  ],
                ],
              ),
              Text(
                '${profile.designation} · ${profile.classroomName}',
                style: Av2Text.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: Av2Spacing.xs),
        _statusPill(),
      ],
    );

    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: Av2Spacing.xs,
          ),
          child: row,
        ),
      ),
    );
  }

  Widget _avatar() => ProfileAvatar(
    name: profile.staffName,
    staffCode: profile.staffCode,
    size: avatarSize,
  );

  Widget _statusPill() {
    switch (profile.todayStatus) {
      case TodayStatus.present:
        return const Av2Pill(
          text: 'Present today',
          fill: Av2Colors.successFill,
          textColor: Av2Colors.success,
        );
      case TodayStatus.signedOut:
        return const Av2Pill(
          text: 'Signed out',
          fill: Av2Colors.regularFill,
          textColor: Av2Colors.regular,
        );
      case TodayStatus.absent:
        return const Av2Pill(
          text: 'Absent',
          fill: Av2Colors.dangerFill,
          textColor: Av2Colors.danger,
        );
      case TodayStatus.notMarked:
        return const Av2Pill(
          text: 'Not marked',
          fill: Av2Colors.neutralFill,
          textColor: Av2Colors.neutral,
        );
    }
  }
}
