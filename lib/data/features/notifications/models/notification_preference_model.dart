import 'package:wowcare/domain/features/notifications/entities/notification_preference.dart';

/// One item from `GET /api/v1/notification/preferences` → `data[]`.
class NotificationPreferenceModel {
  const NotificationPreferenceModel({
    required this.definitionCode,
    required this.definitionTitle,
    required this.categoryName,
    required this.allowedChannels,
    required this.enabledInApp,
    required this.enabledPush,
    required this.enabledEmail,
  });

  final String definitionCode;
  final String definitionTitle;
  final String categoryName;
  final List<String> allowedChannels;
  final bool enabledInApp;
  final bool enabledPush;
  final bool enabledEmail;

  factory NotificationPreferenceModel.fromJson(Map<String, dynamic> json) {
    final channels = json['allowedChannels'];
    return NotificationPreferenceModel(
      definitionCode: (json['definitionCode'] ?? '').toString(),
      definitionTitle: (json['definitionTitle'] ?? '').toString(),
      categoryName: (json['categoryName'] ?? '').toString(),
      allowedChannels: channels is List
          ? channels.map((dynamic e) => e.toString()).toList()
          : const <String>[],
      enabledInApp: json['enabledInApp'] == true,
      enabledPush: json['enabledPush'] == true,
      enabledEmail: json['enabledEmail'] == true,
    );
  }

  NotificationPreference toEntity() => NotificationPreference(
        definitionCode: definitionCode,
        definitionTitle: definitionTitle,
        categoryName: categoryName,
        allowedChannels: allowedChannels,
        enabledInApp: enabledInApp,
        enabledPush: enabledPush,
        enabledEmail: enabledEmail,
      );
}

/// One entry in the `preferences` array of the PATCH body.
class NotificationPreferenceUpdate {
  const NotificationPreferenceUpdate({
    required this.definitionCode,
    required this.enabledInApp,
    required this.enabledPush,
    required this.enabledEmail,
  });

  final String definitionCode;
  final bool enabledInApp;
  final bool enabledPush;
  final bool enabledEmail;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'definitionCode': definitionCode,
        'enabledInApp': enabledInApp,
        'enabledPush': enabledPush,
        'enabledEmail': enabledEmail,
      };
}

/// Request body for `PATCH /api/v1/notification/preferences?userCode=…`.
class UpdateNotificationPreferencesRequest {
  const UpdateNotificationPreferencesRequest({
    required this.schoolCode,
    required this.role,
    required this.preferences,
    this.organizationCode,
  });

  final String schoolCode;
  final String? organizationCode;
  final String role;
  final List<NotificationPreferenceUpdate> preferences;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'schoolCode': schoolCode,
        if (organizationCode != null && organizationCode!.isNotEmpty)
          'organizationCode': organizationCode,
        'role': role,
        'preferences':
            preferences.map((p) => p.toJson()).toList(growable: false),
      };
}
