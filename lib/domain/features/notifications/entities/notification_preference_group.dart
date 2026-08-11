import 'package:equatable/equatable.dart';

/// Channel codes returned by `GET /api/v1/notification/preferences/groups`.
abstract final class NotificationChannel {
  static const String push = 'PUSH';
  static const String email = 'EMAIL';
  static const String inApp = 'IN_APP';
}

/// One group from `GET /api/v1/notification/preferences/groups` → `data[]`.
///
/// [channels] maps channel code ([NotificationChannel]) → enabled flag, and
/// only contains the channels this group actually supports — a channel
/// absent from the map is not offered for this group at all (not just off),
/// which the UI renders as a disabled checkbox.
class NotificationPreferenceGroup extends Equatable {
  const NotificationPreferenceGroup({
    required this.groupCode,
    required this.title,
    required this.categoryCode,
    this.description = '',
    this.categoryName = '',
    this.displayOrder = 0,
    this.channels = const <String, bool>{},
    this.overridden = false,
  });

  final String groupCode;
  final String title;
  final String description;
  final String categoryCode;
  final String categoryName;
  final int displayOrder;
  final Map<String, bool> channels;
  final bool overridden;

  bool isChannelAvailable(String channel) => channels.containsKey(channel);

  bool isChannelEnabled(String channel) => channels[channel] ?? false;

  NotificationPreferenceGroup copyWithChannel(String channel, bool enabled) {
    if (!channels.containsKey(channel)) return this;
    return NotificationPreferenceGroup(
      groupCode: groupCode,
      title: title,
      description: description,
      categoryCode: categoryCode,
      categoryName: categoryName,
      displayOrder: displayOrder,
      channels: <String, bool>{...channels, channel: enabled},
      overridden: overridden,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        groupCode,
        title,
        description,
        categoryCode,
        categoryName,
        displayOrder,
        channels,
        overridden,
      ];
}
