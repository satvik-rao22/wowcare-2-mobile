import 'package:flutter/material.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';
import 'package:wowcare/modules/attendance_v2/core/utils/av2_date_formatter.dart';

import '../../domain/entities/regularization_request.dart';
import 'reg_status_pill.dart';
import 'package:wowcare/shared/common/widgets/profile_avatar.dart';

/// Admin-facing notification tile for a regularization request. Reusable in
/// the approver inbox, a dashboard "needs your approval" card, or a
/// notifications list. Tap to review/decide.
class RegAdminNotificationTile extends StatelessWidget {
  const RegAdminNotificationTile({
    super.key,
    required this.request,
    this.onTap,
    this.selected = false,
    this.onSelectChanged,
  });

  final RegularizationRequest request;
  final VoidCallback? onTap;

  /// When [onSelectChanged] is provided, a leading checkbox is shown for
  /// multi-select bulk approve. Row tap still opens review via [onTap].
  final bool selected;
  final ValueChanged<bool>? onSelectChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Av2Colors.surface,
      borderRadius: BorderRadius.circular(Av2Spacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Av2Spacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(Av2Spacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Av2Spacing.radiusLg),
            border: Border.all(
              color: selected ? Av2Colors.theme : Av2Colors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onSelectChanged != null) ...[
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: selected,
                    activeColor: Av2Colors.theme,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) => onSelectChanged!(v ?? false),
                  ),
                ),
                const SizedBox(width: Av2Spacing.sm),
              ],
              ProfileAvatar(
                name: request.staffName,
                staffCode: request.staffCode,
                size: 38,
              ),
              const SizedBox(width: Av2Spacing.sm),
              Expanded(child: _body(request)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RegStatusPill(status: request.status),
                  const SizedBox(height: 6),
                  if (onTap != null)
                    Text(
                      request.status.isPending ? 'Review' : 'Details',
                      style: Av2Text.caption.copyWith(
                        color: Av2Colors.theme,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(RegularizationRequest r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          r.staffName,
          style: Av2Text.bodyMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          'Missed sign-out · ${Av2DateFormatter.monthDay(r.attendanceDate)}',
          style: Av2Text.caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          _changeLine(r),
          style: Av2Text.caption.copyWith(color: Av2Colors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// The suggested time is no longer stored on the request (spec §7.5), so a
  /// pending row shows what was asked for, and a decided row shows asked vs
  /// approved whenever the admin committed a different time (§7.4).
  String _changeLine(RegularizationRequest r) {
    final asked = Av2DateFormatter.compactTime(r.requestedSignOutTime);
    if (r.wasModified) {
      final approved = Av2DateFormatter.compactTime(r.approvedSignOutTime!);
      return 'asked $asked · approved $approved';
    }
    return 'wants out $asked';
  }
}
