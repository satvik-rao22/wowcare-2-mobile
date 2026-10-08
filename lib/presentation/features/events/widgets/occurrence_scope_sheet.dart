import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/app_haptics.dart';

/// Which part of a recurring series an edit/delete applies to.
enum OccurrenceScope { thisOnly, thisAndFuture, wholeSeries }

/// Google-Calendar-style chooser shown when editing/deleting a recurring
/// event: single occurrence, this-and-upcoming (splits/caps the series at
/// this date — e.g. an admin cancelling from next month onward), or the
/// whole series. Returns null when dismissed.
Future<OccurrenceScope?> showOccurrenceScopeSheet(
  BuildContext context, {
  required String title,
  required IconData icon,
}) {
  return showModalBottomSheet<OccurrenceScope>(
    context: context,
    backgroundColor: AppPalette.surfaceSunken,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.event_outlined),
            title: const Text(
              'This event only',
              style: TextStyle(fontSize: 14),
            ),
            subtitle: const Text(
              'Other events in the series stay unchanged',
              style: TextStyle(fontSize: 12),
            ),
            onTap: () {
              AppHaptics.tap();
              Navigator.pop(sheetContext, OccurrenceScope.thisOnly);
            },
          ),
          ListTile(
            leading: const Icon(Icons.fast_forward_outlined),
            title: const Text(
              'This and future events',
              style: TextStyle(fontSize: 14),
            ),
            subtitle: const Text(
              'From this date to the end of the series',
              style: TextStyle(fontSize: 12),
            ),
            onTap: () {
              AppHaptics.tap();
              Navigator.pop(sheetContext, OccurrenceScope.thisAndFuture);
            },
          ),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text(
              'All events in the series',
              style: TextStyle(fontSize: 14),
            ),
            subtitle: const Text(
              'Applies to every occurrence, including past ones',
              style: TextStyle(fontSize: 12),
            ),
            onTap: () {
              AppHaptics.tap();
              Navigator.pop(sheetContext, OccurrenceScope.wholeSeries);
            },
          ),
          const SizedBox(height: 6),
        ],
      ),
    ),
  );
}

/// Optional-reason prompt for cancelling one occurrence. Returns null when
/// aborted; the (possibly empty) reason otherwise.
Future<String?> promptOccurrenceCancelReason(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cancel this event?'),
      content: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Reason (optional)',
          hintText: 'e.g. Teacher sick',
          isDense: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            AppHaptics.tap();
            Navigator.pop(dialogContext);
          },
          child: const Text('Keep event'),
        ),
        TextButton(
          onPressed: () {
            AppHaptics.tap();
            Navigator.pop(dialogContext, controller.text.trim());
          },
          child: const Text(
            'Cancel event',
            style: TextStyle(color: AppColors.errorColor),
          ),
        ),
      ],
    ),
  );
}
