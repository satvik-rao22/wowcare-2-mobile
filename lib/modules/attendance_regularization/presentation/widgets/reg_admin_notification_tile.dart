import 'package:flutter/material.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';
import 'package:wowcare/modules/attendance_v2/core/utils/av2_date_formatter.dart';
import 'package:wowcare/modules/attendance_v2/presentation/widgets/av2_avatar.dart';

import '../../domain/entities/regularization_request.dart';
import 'reg_status_pill.dart';

/// Admin-facing notification tile for a regularization request. Reusable in
/// the approver inbox, a dashboard "needs your approval" card, or a
/// notifications list. Tap to review/decide.
class RegAdminNotificationTile extends StatelessWidget {
  const RegAdminNotificationTile({super.key, required this.request, this.onTap});

  final RegularizationRequest request;
  final VoidCallback? onTap;

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
            border: Border.all(color: Av2Colors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Av2Avatar(initials: request.initials, diameter: 38),
              const SizedBox(width: Av2Spacing.sm),
              Expanded(child: _body(request)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RegStatusPill(status: request.status),
                  const SizedBox(height: 6),
                  if (request.status.isPending)
                    Text('Review',
                        style: Av2Text.caption.copyWith(
                            color: Av2Colors.theme, fontWeight: FontWeight.w600)),
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
        Text(r.staffName,
            style: Av2Text.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(
          '${r.type.label} · ${Av2DateFormatter.monthDay(r.attendanceDate)}',
          style: Av2Text.caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (_changeLine(r) != null) ...[
          const SizedBox(height: 2),
          Text(
            _changeLine(r)!,
            style: Av2Text.caption.copyWith(color: Av2Colors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  String? _changeLine(RegularizationRequest r) {
    final out = r.requestedSignOutAt;
    final soft = r.softSignOutAt;
    if (out != null && soft != null) {
      return 'wants ${Av2DateFormatter.compactTime(out)} · was ${Av2DateFormatter.compactTime(soft)}';
    }
    if (out != null) return 'wants out ${Av2DateFormatter.compactTime(out)}';
    if (r.requestedSignInAt != null) {
      return 'wants in ${Av2DateFormatter.compactTime(r.requestedSignInAt!)}';
    }
    return null;
  }
}
