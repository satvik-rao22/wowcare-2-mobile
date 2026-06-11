import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  static const Color _holidayRed = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    final isFederal = holiday.type == HolidayType.federal;
    final accent = holiday.isObserved ? _holidayRed : Colors.grey;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dateBadge(accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      holiday.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _dateRangeLabel(),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    if (holiday.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        holiday.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11.5, color: Colors.grey[600]),
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
                      foregroundColor: _holidayRed,
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
    return '$start – ${DateFormat('EEE, MMM d, yyyy').format(holiday.endDate)}';
  }

  Widget _dateBadge(Color accent) {
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            DateFormat('MMM').format(holiday.startDate).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: 0.6,
            ),
          ),
          Text(
            '${holiday.startDate.day}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(bool isFederal) {
    final color = isFederal ? const Color(0xFF4A90D9) : _holidayRed;
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
      HolidayStatus.pending => const Color(0xFFF9A825),
      HolidayStatus.considered => const Color(0xFF388E3C),
      HolidayStatus.rejected => Colors.grey,
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

  Widget _federalActions() {
    Widget action(HolidayStatus status, String label, Color color) {
      final isActive = holiday.status == status;
      return Expanded(
        child: Material(
          color: isActive ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => onStatusChanged!(status),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : color,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        action(
            HolidayStatus.considered, 'Observe', const Color(0xFF388E3C)),
        const SizedBox(width: 6),
        action(HolidayStatus.rejected, "Don't Observe", Colors.grey),
      ],
    );
  }
}
