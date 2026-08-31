import 'package:flutter/material.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';
import 'package:wowcare/modules/attendance_v2/core/utils/av2_date_formatter.dart';

import '../../domain/entities/regularization_request.dart';
import 'reg_status_pill.dart';

/// One regularization request row (staff "my requests" list).
class RegRequestTile extends StatelessWidget {
  const RegRequestTile({super.key, required this.request, this.onTap});

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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Av2Spacing.radiusLg),
            border: Border.all(color: Av2Colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Missed sign-out', style: Av2Text.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(request),
                      style: Av2Text.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              RegStatusPill(status: request.status),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(RegularizationRequest r) {
    final date = Av2DateFormatter.monthDay(r.attendanceDate);
    final out = r.requestedSignOutAt;
    if (out != null) return '$date · out ${Av2DateFormatter.compactTime(out)}';
    return date;
  }
}
