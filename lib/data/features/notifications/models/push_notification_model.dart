import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:wowcare/core/utils/html_entities.dart';

import '../../../../domain/features/notifications/entities/push_notification.dart';

/// Maps a Firebase [RemoteMessage] into the domain [PushNotification].
class PushNotificationModel extends PushNotification {
  const PushNotificationModel({
    required super.title,
    required super.body,
    required super.action,
    required super.type,
    required super.data,
    super.messageId,
  });

  factory PushNotificationModel.fromRemoteMessage(RemoteMessage message) {
    // FCM data values arrive as strings; normalise just in case.
    final data = message.data.map(
      (key, value) => MapEntry(key, value?.toString() ?? ''),
    );
    return PushNotificationModel(
      // Decoded: the server HTML-escapes user text it templates in.
      title: HtmlEntities.decodeOrNull(message.notification?.title),
      body: HtmlEntities.decodeOrNull(message.notification?.body),
      action: data['action'],
      type: data['type'],
      data: data,
      messageId: message.messageId,
    );
  }
}
