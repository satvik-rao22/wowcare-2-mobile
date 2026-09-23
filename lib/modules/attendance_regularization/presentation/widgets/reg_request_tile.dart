import 'package:flutter/material.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';
import 'package:wowcare/modules/attendance_v2/core/utils/av2_date_formatter.dart';

import '../../domain/entities/regularization_request.dart';
import 'reg_status_pill.dart';

/// One regularization request row.
///
/// Used by every regularization list, so the same request looks the same
/// wherever it appears. What the row *offers* differs by viewer and is passed
/// in: [editable] for the raiser, [onSelectChanged] for an admin who may
/// bulk-approve it.
class RegRequestTile extends StatelessWidget {
  const RegRequestTile({
    super.key,
    required this.request,
    this.onTap,
    this.busy = false,
    this.editable = false,
    this.selected = false,
    this.onSelectChanged,
  });

  final RegularizationRequest request;

  /// Non-null only when the row can be acted on — edited by its raiser (§9.4)
  /// or reviewed by an admin (§9.6).
  final VoidCallback? onTap;

  /// This row's edit is in flight.
  final bool busy;

  /// Shows the pencil, i.e. tapping opens the edit sheet rather than review.
  final bool editable;

  final bool selected;

  /// Non-null only on a pending row an admin may tick for bulk approve.
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Av2Spacing.radiusLg),
            border: Border.all(
                color: selected ? Av2Colors.theme : Av2Colors.border),
          ),
          child: Row(
            children: [
              if (onSelectChanged != null) ...[
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: selected,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) => onSelectChanged!(v ?? false),
                  ),
                ),
                const SizedBox(width: 10),
              ],
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
              if (editable && onTap != null && !busy) ...[
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
