import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

/// A selected-person chip with a remove ("x") action, shown in the working
/// list of the sign-in/sign-out/transfer/mark-absent forms (both student and
/// staff side). Deliberately takes primitive fields rather than an entity —
/// each form's submit screen defines its own local `StudentEntity`/
/// `StaffEntity` class, so a shared widget can't depend on any single one.
class AttendanceRemoveTile extends StatelessWidget {
  const AttendanceRemoveTile({
    super.key,
    required this.name,
    required this.photoUuid,
    required this.onRemove,
    this.horizontalPadding = AppSpacing.xs,
    this.deleteIconSize,
    this.canRemove = true,
  });

  final String name;
  final String photoUuid;
  final VoidCallback onRemove;

  /// The staff-side copies gated the delete affordance on there being more
  /// than one selected staff member left; the student-side copies had no
  /// such gate. Defaults to always-removable to match the student call sites.
  final bool canRemove;

  /// The 4 pre-existing copies of this widget weren't byte-identical: two
  /// used AppSpacing.sm, two used AppSpacing.xs. Preserved per call site
  /// rather than silently unified.
  final double horizontalPadding;

  /// Only one of the 4 pre-existing copies set an explicit delete-icon size
  /// (18x18); the others left it at the SVG's intrinsic size. `null` keeps
  /// that default.
  final double? deleteIconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.themeColor),
        borderRadius: BorderRadius.circular(AppRadius.r10),
        color: AppColors.attendanceSelectedTintColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                DocumentImageWidget(
                  fileUuid: photoUuid,
                  name: name,
                  size: 30,
                  fontSize: 12,
                ),
                const SizedBox(width: AppSpacing.s6),
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    style: AppTextStyles.body,
                  ),
                ),
              ],
            ),
          ),
          if (canRemove)
            GestureDetector(
              onTap: onRemove,
              child: deleteIconSize != null
                  ? SvgPicture.asset(
                      MediaRes.delete_icon,
                      height: deleteIconSize,
                      width: deleteIconSize,
                    )
                  : SvgPicture.asset(MediaRes.delete_icon),
            ),
        ],
      ),
    );
  }
}
