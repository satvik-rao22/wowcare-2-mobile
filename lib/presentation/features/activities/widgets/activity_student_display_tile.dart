import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/common/widgets/profile_show_widget.dart';
import '../../../../shared/common/widgets/ellipsis_tooltip_text.dart';

/// Same chrome as student tiles on the activity student picker, without checkbox.
/// Use for view/edit activity flows where the student is display-only.
class ActivityStudentDisplayTile extends StatelessWidget {
  const ActivityStudentDisplayTile({
    super.key,
    required this.name,
    this.studentCode,
    this.backgroundColor,
    this.onRemove,
  });

  final String name;

  /// Optional student code — when set, the avatar resolves the real profile
  /// photo (falling back to initials when none is available).
  final String? studentCode;

  /// Defaults to white; use selected tint when mirroring a selected row elsewhere.
  final Color? backgroundColor;

  /// When provided, a trash button is shown so the student can be removed
  /// (used in the create flow). Omit for display-only view/edit.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final display = name.trim().isEmpty ? 'Student' : name.trim();
    final code = (studentCode ?? '').trim();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.themeColor),
        borderRadius: BorderRadius.circular(8),
        color: backgroundColor ?? Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          children: [
            DocumentImageWidget(
              fileUuid: '',
              name: display,
              studentCode: code.isEmpty ? null : code,
              size: 28,
              fontSize: 12,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: EllipsisTooltipText(
                text: display,
                maxLines: 2,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
            ),
            if (onRemove != null)
              GestureDetector(
                onTap: onRemove,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.delete_outline,
                    size: 24,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
