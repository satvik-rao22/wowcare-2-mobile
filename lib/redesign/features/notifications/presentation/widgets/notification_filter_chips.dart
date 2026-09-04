import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/widgets/app_chip.dart';
import 'package:wowcare/redesign/core/widgets/chip_row.dart';
import 'package:wowcare/redesign/features/notifications/models/models.dart';

/// 12a's filter row, and 12e's rule about which chips it carries.
///
/// No counts on the chips: the inbox is filtered server-side and the count
/// per module is not a number any call returns, so a chip that carried one
/// would be a number the app made up.
class NotificationFilterChips extends StatelessWidget {
  const NotificationFilterChips({
    required this.filters,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final List<NotificationFilter> filters;
  final NotificationFilter selected;
  final ValueChanged<NotificationFilter> onSelect;

  @override
  Widget build(BuildContext context) => ChipRow(
    children: <Widget>[
      for (final filter in filters)
        AppChip(
          label: filter.label,
          selected: filter == selected,
          onTap: () => onSelect(filter),
        ),
    ],
  );
}
