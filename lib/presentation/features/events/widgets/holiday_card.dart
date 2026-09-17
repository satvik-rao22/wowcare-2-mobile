import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';

/// List card for the Holidays tab. Federal holidays expose the school's
/// observance decision (Pending / Observed / Not Observed); school
/// holidays expose edit/delete for admins.
class HolidayCard extends StatelessWidget {
  const HolidayCard({
    required this.holiday,
    this.onStatusChanged,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final Holiday holiday;

  /// Non-null enables the federal observance actions.
  final ValueChanged<HolidayStatus>? onStatusChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Reserved strictly for the destructive delete action.
  static const Color _deleteRed = AppPalette.statusError;

  @override
  Widget build(BuildContext context) {
    final isFederal = holiday.type == HolidayType.federal;
    // Plain card with a neutral outline; observance state is conveyed by
    // the status chip rather than tinting the whole card.
    final badgeColor =
        holiday.isObserved ? AppColors.themeColor : AppPalette.textMuted;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppSurfaces.card(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dateBadge(badgeColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      holiday.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _dateRangeLabel(),
                      style: const TextStyle(
                          fontSize: 12, color: AppPalette.textSecondary),
                    ),
                    if (holiday.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        holiday.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppPalette.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _typeChip(isFederal),
                  if (isFederal && holiday.status != null) ...[
                    const SizedBox(height: 4),
                    _statusChip(holiday.status!),
                  ],
                ],
              ),
            ],
          ),
          if (isFederal && onStatusChanged != null) ...[
            const SizedBox(height: 8),
            _federalActions(),
          ],
          if (!isFederal && (onEdit != null || onDelete != null)) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.themeColor,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (onDelete != null)
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 15),
                    label: const Text('Delete',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: _deleteRed,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _dateRangeLabel() {
    final start = DateFormat('EEE, MMM d, yyyy').format(holiday.startDate);
    if (holiday.startDate == holiday.endDate ||
        DateUtils.isSameDay(holiday.startDate, holiday.endDate)) {
      return start;
    }
    final end = DateFormat('EEE, MMM d, yyyy').format(holiday.endDate);
    return '$start – $end  •  $_dayCount days';
  }

  /// Inclusive number of days the holiday spans (FR-HL-10).
  int get _dayCount =>
      holiday.endDate.difference(holiday.startDate).inDays + 1;

  Widget _dateBadge(Color badgeColor) {
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            DateFormat('MMM').format(holiday.startDate).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: badgeColor,
              letterSpacing: 0.6,
            ),
          ),
          Text(
            '${holiday.startDate.day}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(bool isFederal) {
    final color = isFederal ? AppPalette.dataTeal : AppColors.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        holiday.type.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _statusChip(HolidayStatus status) {
    final color = switch (status) {
      HolidayStatus.pending => AppPalette.statusWarning,
      HolidayStatus.considered => AppPalette.statusSuccess,
      HolidayStatus.rejected => AppPalette.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  /// Actions depend on the current federal status (FR-HL-03/04/05):
  ///   pending    → Approve / Reject
  ///   considered → Reject
  ///   rejected   → Re-Approve
  Widget _federalActions() {
    Widget action(HolidayStatus target, String label, Color color) {
      return Expanded(
        child: Material(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => onStatusChanged!(target),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      );
    }

    const approveColor = AppPalette.statusSuccess;
    const rejectColor = AppPalette.statusError;

    switch (holiday.status) {
      case HolidayStatus.pending:
        return Row(
          children: [
            action(HolidayStatus.considered, 'Approve', approveColor),
            const SizedBox(width: 6),
            action(HolidayStatus.rejected, 'Reject', rejectColor),
          ],
        );
      case HolidayStatus.considered:
        return Row(
          children: [
            action(HolidayStatus.rejected, 'Reject', rejectColor),
          ],
        );
      case HolidayStatus.rejected:
        return Row(
          children: [
            action(HolidayStatus.considered, 'Re-Approve', approveColor),
          ],
        );
      case null:
        return const SizedBox.shrink();
    }
  }
}
