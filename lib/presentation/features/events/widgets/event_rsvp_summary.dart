import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/presentation/features/events/utils/event_ui_utils.dart';

/// Admin-only RSVP summary (PRD FR-EV-16/17/18): three tappable count
/// cards — Attending / Maybe / Not Attending — plus a total badge. Tapping
/// a card opens a bottom sheet listing the respondents with that status,
/// grouped by attendee type, with a search field for longer lists.
class EventRsvpSummary extends StatelessWidget {
  const EventRsvpSummary({required this.event, super.key});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final status in EventRsvpStatus.values) ...[
              Expanded(child: _statusCard(context, status)),
              if (status != EventRsvpStatus.values.last)
                const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '${event.rsvps.length} '
            'response${event.rsvps.length == 1 ? '' : 's'} in total',
            style: TextStyle(fontSize: 11.5, color: AppPalette.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _statusCard(BuildContext context, EventRsvpStatus status) {
    final color = EventUiUtils.rsvpColor(status);
    final count = event.rsvpCount(status);
    return Material(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: count == 0
            ? null
            : () => _showParticipants(context, status),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showParticipants(BuildContext context, EventRsvpStatus status) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.surfaceSunken,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _RsvpParticipantsSheet(event: event, status: status),
    );
  }
}

class _RsvpParticipantsSheet extends StatefulWidget {
  const _RsvpParticipantsSheet({required this.event, required this.status});

  final Event event;
  final EventRsvpStatus status;

  @override
  State<_RsvpParticipantsSheet> createState() =>
      _RsvpParticipantsSheetState();
}

class _RsvpParticipantsSheetState extends State<_RsvpParticipantsSheet> {
  String _query = '';

  /// Section order mirrors the web design's grouping.
  static const List<String> _typeOrder = ['STAFF', 'STUDENT', 'PARENT'];

  @override
  Widget build(BuildContext context) {
    final color = EventUiUtils.rsvpColor(widget.status);
    final all = widget.event.rsvps
        .where((r) => r.status == widget.status)
        .toList();
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? all
        : all
            .where((r) =>
                r.userName.toLowerCase().contains(query) ||
                r.userType.toLowerCase().contains(query))
            .toList();
    final groups = <String, List<EventRsvp>>{};
    for (final rsvp in filtered) {
      groups.putIfAbsent(rsvp.userType.toUpperCase(), () => []).add(rsvp);
    }
    final orderedTypes = [
      ..._typeOrder.where(groups.containsKey),
      ...groups.keys.where((t) => !_typeOrder.contains(t)),
    ];

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppPalette.sheetGrabber,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Icon(EventUiUtils.rsvpIcon(widget.status),
                      size: 18, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.status.label} (${all.length})',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (all.length > 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search participants…',
                    hintStyle:
                        TextStyle(fontSize: 13, color: AppPalette.textMuted),
                    prefixIcon: const Icon(Icons.search, size: 19),
                    isDense: true,
                    filled: true,
                    fillColor: AppSurfaces.fieldFill,
                    border: AppSurfaces.fieldBorder(radius: 10),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No participants match your search',
                        style: TextStyle(
                            fontSize: 13, color: AppPalette.textSecondary),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        for (final type in orderedTypes) ...[
                          _groupHeader(type, groups[type]!.length),
                          for (final rsvp in groups[type]!)
                            _participantRow(rsvp, color),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupHeader(String type, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Text(
        '${_typeLabel(type)} ($count)',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppPalette.textSecondary,
        ),
      ),
    );
  }

  Widget _participantRow(EventRsvp rsvp, Color color) {
    final name = rsvp.userName.isNotEmpty ? rsvp.userName : rsvp.userCode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.themeColor.withValues(alpha: 0.12),
            child: Text(
              _initials(name),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.themeColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, color: AppPalette.textPrimary),
                ),
                Text(
                  _typeLabel(rsvp.userType),
                  style: const TextStyle(
                      fontSize: 11, color: AppPalette.textMuted),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('MMM d').format(rsvp.respondedAt),
            style: TextStyle(fontSize: 11, color: AppPalette.textMuted),
          ),
        ],
      ),
    );
  }

  static String _typeLabel(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty) return raw;
    return lower[0].toUpperCase() + lower.substring(1);
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}
