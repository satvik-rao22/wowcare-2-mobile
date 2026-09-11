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

  /// Human-readable section label for this group's category.
  ///
  /// The API returns the raw backend enum for `categoryName` on some
  /// categories (and omits it on others), which surfaced in the section
  /// header as `STAFF_SCHEDULING`. Anything that still looks like an enum
  /// code — screaming snake case, or an all-caps word — is title-cased for
  /// display; a name the backend already wrote for humans is left as is.
  String get categoryLabel {
    final trimmedName = categoryName.trim();
    final raw = trimmedName.isNotEmpty ? trimmedName : categoryCode.trim();
    if (raw.isEmpty) return '';
    final looksLikeEnumCode = raw.contains('_') || raw == raw.toUpperCase();
    if (!looksLikeEnumCode) return raw;
    return raw
        .split(RegExp(r'[_\s]+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

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
