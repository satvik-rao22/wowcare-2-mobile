import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../domain/features/notifications/entities/notification_preference_group.dart';
import '../../../../shared/common/widgets/custom_checkbox.dart';

/// One row of the grouped notification-preferences screen: [group.title] on
/// the left, and an In-App / Email / Push checkbox on the right. A channel
/// the group doesn't support (absent from `group.channels`) renders as a
/// greyed-out, unticked checkbox the user cannot interact with.
class NotificationPreferenceGroupRow extends StatelessWidget {
  const NotificationPreferenceGroupRow({
    super.key,
    required this.group,
    required this.isSaving,
    required this.onChannelChanged,
  });

  final NotificationPreferenceGroup group;

  /// Disables all three checkboxes while a PATCH for this group is in flight.
  final bool isSaving;

  final void Function(String channel, bool value) onChannelChanged;

  @override
  Widget build(BuildContext context) {
    const columnWidth = 60.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                group.title,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          _channelCheckbox(NotificationChannel.inApp, columnWidth),
          _channelCheckbox(NotificationChannel.email, columnWidth),
          _channelCheckbox(NotificationChannel.push, columnWidth),
        ],
      ),
    );
  }

  Widget _channelCheckbox(String channel, double width) {
    final available = group.isChannelAvailable(channel);
    return SizedBox(
      width: width,
      child: Center(
        // Not offered for this group at all — a solid grey filled box reads
        // unmistakably as disabled, rather than just "currently unchecked".
        child: available
            ? CustomCheckbox(
                value: group.isChannelEnabled(channel),
                borderColor: AppColors.themeColor,
                onChanged: !isSaving
                    ? (value) => onChannelChanged(channel, value ?? false)
                    : null,
              )
            : const _DisabledChannelBox(),
      ),
    );
  }
}

/// Solid grey filled box standing in for a channel a group doesn't support at
/// all — visually distinct from an unchecked (but available) checkbox so it
/// reads as "not applicable" rather than "off".
class _DisabledChannelBox extends StatelessWidget {
  const _DisabledChannelBox();

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.2,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: Colors.grey.shade400, width: 1),
        ),
      ),
    );
  }
}
