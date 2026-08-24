import 'package:wowcare/domain/features/notifications/entities/notification_preference_group.dart';

/// One item from `GET /api/v1/notification/preferences/groups` → `data[]`.
class NotificationPreferenceGroupModel {
  const NotificationPreferenceGroupModel({
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

  factory NotificationPreferenceGroupModel.fromJson(Map<String, dynamic> json) {
    final channelsJson = json['channels'];
    final channels = <String, bool>{};
    if (channelsJson is List) {
      for (final entry in channelsJson) {
        if (entry is Map) {
          final channel = entry['channel']?.toString();
          if (channel != null && channel.isNotEmpty) {
            channels[channel] = entry['enabled'] == true;
          }
        }
      }
    }
    return NotificationPreferenceGroupModel(
      groupCode: (json['groupCode'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      categoryCode: (json['categoryCode'] ?? '').toString(),
      categoryName: (json['categoryName'] ?? '').toString(),
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      channels: channels,
      overridden: json['overridden'] == true,
    );
  }

  NotificationPreferenceGroup toEntity() => NotificationPreferenceGroup(
        groupCode: groupCode,
        title: title,
        description: description,
        categoryCode: categoryCode,
        categoryName: categoryName,
        displayOrder: displayOrder,
        channels: channels,
        overridden: overridden,
      );
}

/// One entry in the `preferences` array of the
/// `PATCH /api/v1/notification/preferences/groups` body.
class NotificationPreferenceGroupUpdate {
  const NotificationPreferenceGroupUpdate({
    required this.groupCode,
    required this.channels,
  });

  final String groupCode;

  /// Only the channels this group supports — never send a channel the group
  /// doesn't offer (the backend rejects it).
  final Map<String, bool> channels;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'groupCode': groupCode,
        'channels': channels,
      };
}

/// Request body for `PATCH /api/v1/notification/preferences/groups`.
class UpdateNotificationPreferenceGroupsRequest {
  const UpdateNotificationPreferenceGroupsRequest({required this.preferences});

  final List<NotificationPreferenceGroupUpdate> preferences;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'preferences': preferences.map((p) => p.toJson()).toList(growable: false),
      };
}
