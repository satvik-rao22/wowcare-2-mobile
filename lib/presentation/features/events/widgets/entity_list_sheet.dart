import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/presentation/features/events/utils/event_ui_utils.dart';
import 'package:wowcare/shared/common/widgets/profile_avatar.dart';

/// One row of [showEntityListSheet].
class EntityListItem {
  const EntityListItem({required this.name, this.subtitle = '', this.rsvp});

  final String name;

  /// Secondary line — e.g. the child's name on a parent row.
  final String subtitle;
  final EventRsvpStatus? rsvp;
}

/// Generic searchable member sheet used by every attendee/responder list:
/// title + count header, search field, alphabetically sorted rows with
/// avatar initial, optional subtitle and optional RSVP chip.
Future<void> showEntityListSheet(
  BuildContext context, {
  required String title,
  required IconData icon,
  required Color color,
  required List<EntityListItem> items,
  String? emptyHint,
}) {
  final sorted = [...items]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppPalette.surfaceSunken,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      var query = '';
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final visible = query.isEmpty
              ? sorted
              : [
                  for (final item in sorted)
                    if (item.name.toLowerCase().contains(query) ||
                        item.subtitle.toLowerCase().contains(query))
                      item,
                ];
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      children: [
                        Icon(icon, size: 18, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$title (${items.length})',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppPalette.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                  ),
                  if (items.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: TextField(
                        onChanged: (value) => setSheetState(
                          () => query = value.trim().toLowerCase(),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          border: AppSurfaces.fieldBorder(radius: 10),
                        ),
                      ),
                    ),
                  const Divider(height: 1),
                  if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        items.isEmpty
                            ? (emptyHint ?? 'Nobody in this group yet.')
                            : 'No matches.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppPalette.textSecondary,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: visible.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 56),
                        itemBuilder: (_, index) {
                          final item = visible[index];
                          return ListTile(
                            dense: true,
                            leading: ProfileAvatar(name: item.name, size: 32),
                            title: Text(
                              item.name,
                              style: const TextStyle(fontSize: 13.5),
                            ),
                            subtitle: item.subtitle.isEmpty
                                ? null
                                : Text(
                                    item.subtitle,
                                    style: const TextStyle(fontSize: 11.5),
                                  ),
                            trailing: item.rsvp == null
                                ? null
                                : Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: EventUiUtils.rsvpColor(
                                        item.rsvp!,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          EventUiUtils.rsvpIcon(item.rsvp!),
                                          size: 13,
                                          color: EventUiUtils.rsvpColor(
                                            item.rsvp!,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.rsvp!.label,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: EventUiUtils.rsvpColor(
                                              item.rsvp!,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
