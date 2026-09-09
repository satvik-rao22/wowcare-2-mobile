import 'package:flutter/material.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';
import 'package:wowcare/modules/attendance_v2/core/utils/av2_date_formatter.dart';

import '../../domain/entities/regularization_request.dart';
import 'reg_status_pill.dart';

/// One regularization request row (staff "my requests" list).
class RegRequestTile extends StatelessWidget {
  const RegRequestTile({
    super.key,
    required this.request,
    this.onTap,
    this.busy = false,
  });

  final RegularizationRequest request;

  /// Non-null only when the row can be acted on — i.e. a pending request the
  /// staff may still edit (§9.4).
  final VoidCallback? onTap;

  /// This row's edit is in flight.
  final bool busy;

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
              if (busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                RegStatusPill(status: request.status),
              if (onTap != null && !busy) ...[
                const SizedBox(width: 6),
                const Icon(Icons.edit_outlined,
                    size: 15, color: Av2Colors.textTertiary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(RegularizationRequest r) {
    final date = Av2DateFormatter.monthDay(r.attendanceDate);
    final out = Av2DateFormatter.compactTime(r.effectiveSignOutTime);
    // An approved request that was modified shows what was actually committed,
    // not what was asked for (spec §7.4 keeps both).
    return r.wasModified ? '$date · out $out (adjusted)' : '$date · out $out';
  }
}
