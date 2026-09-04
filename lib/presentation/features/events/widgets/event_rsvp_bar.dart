import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/presentation/features/events/utils/event_ui_utils.dart';

/// Three-option RSVP selector (Attending / Maybe / Not Attending). The
/// current selection is filled; the rest are outlined.
class EventRsvpBar extends StatelessWidget {
  const EventRsvpBar({
    required this.selected,
    required this.onChanged,
    this.dense = false,
    super.key,
  });

  final EventRsvpStatus? selected;
  final ValueChanged<EventRsvpStatus> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final status in EventRsvpStatus.values) ...[
          Expanded(child: _option(status)),
          if (status != EventRsvpStatus.values.last)
            const SizedBox(width: 6),
        ],
      ],
    );
  }

  Widget _option(EventRsvpStatus status) {
    final color = EventUiUtils.rsvpColor(status);
    final isSelected = selected == status;
    // Dense mode (grid cards) is icon-only; the tooltip carries the label.
    return Tooltip(
      message: status.label,
      child: Material(
        color: isSelected ? color : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onChanged(status),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: dense ? 6 : 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  EventUiUtils.rsvpIcon(status),
                  size: dense ? 14 : 15,
                  color: isSelected ? Colors.white : color,
                ),
                if (!dense) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      status.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact read-only RSVP tallies (admin/staff view): colored dots with
/// counts for attending / maybe / not attending.
class EventRsvpCounts extends StatelessWidget {
  const EventRsvpCounts({required this.event, super.key});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final status in EventRsvpStatus.values) ...[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: EventUiUtils.rsvpColor(status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '${event.rsvpCount(status)}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          if (status != EventRsvpStatus.values.last)
            const SizedBox(width: 10),
        ],
      ],
    );
  }
}
