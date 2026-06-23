import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/presentation/features/events/utils/event_ui_utils.dart';
import 'package:wowcare/presentation/features/events/widgets/event_rsvp_bar.dart';
import 'package:wowcare/presentation/features/events/widgets/event_type_chip.dart';

/// Day-list event card: colored date badge, name, type chip, time and
/// audience summary. Used by the Events screen's selected-day list.
class EventCard extends StatelessWidget {
  const EventCard({
    required this.event,
    required this.onTap,
    this.showRsvpCounts = false,
    super.key,
  });

  final Event event;
  final VoidCallback onTap;
  final bool showRsvpCounts;

  @override
  Widget build(BuildContext context) {
    final completed = event.isCompleted;
    // Completed events read as a muted "archive" entry: grey accent, faded
    // content and a "Completed" chip so they stand out from upcoming items.
    final color =
        completed ? Colors.grey : EventUiUtils.typeColor(event.type);
    final card = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.18)),
            boxShadow: completed
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dateBadge(color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  completed ? Colors.grey[700] : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (completed)
                          const _CompletedChip()
                        else
                          EventTypeChip(type: event.type, compact: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 13, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          EventUiUtils.timeLabel(event),
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                        if (event.recurring) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.repeat, size: 13, color: Colors.grey[600]),
                          const SizedBox(width: 2),
                          Text(
                            event.recurringPattern?.label ?? '',
                            style:
                                TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      EventUiUtils.audienceSummary(event),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                    ),
                    if (showRsvpCounts && event.rsvps.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          EventRsvpCounts(event: event),
                          const SizedBox(width: 8),
                          const Text(
                            'responses',
                            style: TextStyle(
                                fontSize: 11, color: Colors.black45),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return completed ? Opacity(opacity: 0.85, child: card) : card;
  }

  Widget _dateBadge(Color color) {
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            DateFormat('MMM').format(event.date).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.6,
            ),
          ),
          Text(
            '${event.date.day}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small grey "Completed" chip shown on past events in place of the type chip.
class _CompletedChip extends StatelessWidget {
  const _CompletedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 11, color: Colors.grey[600]),
          const SizedBox(width: 3),
          Text(
            'Completed',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
