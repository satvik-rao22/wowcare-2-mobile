import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/presentation/features/events/utils/event_ui_utils.dart';

class EventTypeChip extends StatelessWidget {
  const EventTypeChip({required this.type, this.compact = false, super.key});

  final EventType type;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = EventUiUtils.typeColor(type);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: EventUiUtils.typeBackground(type),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(EventUiUtils.typeIcon(type), size: compact ? 11 : 13, color: color),
          const SizedBox(width: 3),
          Text(
            type.label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
