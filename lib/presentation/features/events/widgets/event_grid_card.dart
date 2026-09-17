import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/presentation/features/events/utils/event_ui_utils.dart';
import 'package:wowcare/presentation/features/events/widgets/event_rsvp_bar.dart';
import 'package:wowcare/presentation/features/events/widgets/event_type_chip.dart';

/// Compact card for the grid view: type accent, name, date/time and an
/// inline RSVP bar (mirrors the web design's grid cards).
class EventGridCard extends StatelessWidget {
  const EventGridCard({
    required this.event,
    required this.onTap,
    required this.myRsvp,
    this.onRsvp,
    this.showRsvpCounts = false,
    super.key,
  });

  final Event event;
  final VoidCallback onTap;
  final EventRsvpStatus? myRsvp;

  /// Null when the current user may not RSVP to this event (e.g. a parent
  /// on an event without "invite parents"); hides the RSVP bar.
  final ValueChanged<EventRsvpStatus>? onRsvp;
  final bool showRsvpCounts;

  @override
  Widget build(BuildContext context) {
    final color = EventUiUtils.typeColor(event.type);
    return Material(
      color: AppPalette.surfaceCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: AppPalette.shadowAmbient.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EventTypeChip(type: event.type, compact: true),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  event.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 11, color: AppPalette.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      DateFormat('EEE, MMM d').format(event.date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppPalette.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 11, color: AppPalette.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      EventUiUtils.timeLabel(event),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: AppPalette.textSecondary),
                    ),
                  ),
                ],
              ),
              if (onRsvp != null) ...[
                const SizedBox(height: 8),
                EventRsvpBar(
                    selected: myRsvp, onChanged: onRsvp!, dense: true),
              ],
              if (showRsvpCounts && event.rsvps.isNotEmpty) ...[
                const SizedBox(height: 6),
                EventRsvpCounts(event: event),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
