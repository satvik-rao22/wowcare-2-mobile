import 'package:flutter/material.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';
import 'package:wowcare/modules/attendance_v2/core/utils/av2_date_formatter.dart';

import '../../domain/entities/missed_signout.dart';
import 'package:wowcare/shared/common/widgets/profile_avatar.dart';

/// One staff member in the bulk sign-in gate: who they are + the day being
/// closed on the left, the editable sign-out time on the right. Shows an
/// "edited" state with an undo once the suggested time is changed.
class RegStaffTimeRow extends StatelessWidget {
  const RegStaffTimeRow({
    super.key,
    required this.item,
    required this.signOutTime,
    required this.onEditTime,
    this.isEdited = false,
    this.onReset,
  });

  final MissedSignout item;
  final TimeOfDay signOutTime;
  final VoidCallback onEditTime;
  final bool isEdited;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Av2Colors.surface,
        borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
        border: Border.all(
          color: isEdited ? Av2Colors.theme : Av2Colors.border,
        ),
      ),
      child: Row(
        children: [
          ProfileAvatar(
            name: item.staffName,
            staffCode: item.staffCode,
            size: 32,
          ),
          const SizedBox(width: Av2Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.staffName.trim().isEmpty ? 'Staff' : item.staffName,
                  style: Av2Text.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _subtitle(),
                  style: Av2Text.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isEdited && onReset != null)
            InkWell(
              onTap: onReset,
              borderRadius: BorderRadius.circular(Av2Spacing.radiusPill),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.undo,
                  size: 16,
                  color: Av2Colors.textTertiary,
                ),
              ),
            ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onEditTime,
            borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isEdited ? Av2Colors.surface : Av2Colors.surfaceMuted,
                borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
                border: Border.all(
                  color: isEdited ? Av2Colors.theme : Av2Colors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isEdited ? Icons.edit_outlined : Icons.access_time,
                    size: 14,
                    color: isEdited ? Av2Colors.theme : Av2Colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    signOutTime.format(context),
                    style: Av2Text.body.copyWith(
                      color: isEdited ? Av2Colors.theme : Av2Colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle() {
    final date = Av2DateFormatter.monthDay(item.attendanceDate);
    final inAt = item.signedInAt;
    if (inAt == null) return date;
    return '$date · in ${Av2DateFormatter.compactTime(inAt)}';
  }
}
