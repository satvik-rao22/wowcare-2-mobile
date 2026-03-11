class ActivitySettingModel {
  ActivitySettingModel({
    required this.activityTypeCode,
    required this.activityTypeName,
    this.description,
    this.category,
    this.icon,
    this.color,
    required this.isSystem,
    required this.isMultiStudent,
    required this.requiresStaff,
    required this.requiresPhoto,
    required this.requiresVideo,
    required this.allowsAttachments,
    required this.maxAttachments,
    required this.isEnabled,
    required this.isFavorite,
    required this.displayOrder,
  });

  final String activityTypeCode;
  final String activityTypeName;
  final String? description;
  final String? category;
  final String? icon;
  final String? color;
  final bool isSystem;
  final bool isMultiStudent;
  final bool requiresStaff;
  final bool requiresPhoto;
  final bool requiresVideo;
  final bool allowsAttachments;
  final int maxAttachments;
  final bool isEnabled;
  final bool isFavorite;
  final int displayOrder;

  factory ActivitySettingModel.fromJson(Map<String, dynamic> json) {
    return ActivitySettingModel(
      activityTypeCode: json['activityTypeCode'] as String? ?? '',
      activityTypeName: json['activityTypeName'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isSystem: json['isSystem'] as bool? ?? false,
      isMultiStudent: json['isMultiStudent'] as bool? ?? true,
      requiresStaff: json['requiresStaff'] as bool? ?? false,
      requiresPhoto: json['requiresPhoto'] as bool? ?? false,
      requiresVideo: json['requiresVideo'] as bool? ?? false,
      allowsAttachments: json['allowsAttachments'] as bool? ?? false,
      maxAttachments: json['maxAttachments'] as int? ?? 0,
      isEnabled: json['isEnabled'] as bool? ?? true,
      isFavorite: json['isFavorite'] as bool? ?? false,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }

  /// Used for caching.
  factory ActivitySettingModel.fromCacheJson(Map<String, dynamic> json) {
    return ActivitySettingModel.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'activityTypeCode': activityTypeCode,
      'activityTypeName': activityTypeName,
      'description': description,
      'category': category,
      'icon': icon,
      'color': color,
      'isSystem': isSystem,
      'isMultiStudent': isMultiStudent,
      'requiresStaff': requiresStaff,
      'requiresPhoto': requiresPhoto,
      'requiresVideo': requiresVideo,
      'allowsAttachments': allowsAttachments,
      'maxAttachments': maxAttachments,
      'isEnabled': isEnabled,
      'isFavorite': isFavorite,
      'displayOrder': displayOrder,
    };
  }
}

/// Simple wrapper model for caching a list of settings.
class ActivitySettingsListModel {
  ActivitySettingsListModel({
    required this.items,
  });

  final List<ActivitySettingModel> items;

  factory ActivitySettingsListModel.fromCacheJson(Map<String, dynamic> json) {
    final list = json['items'] as List<dynamic>? ?? const [];
    return ActivitySettingsListModel(
      items: list
          .map((e) => ActivitySettingModel.fromCacheJson(
                (e as Map<String, dynamic>),
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

/// Request body model for creating a new activity via
/// `POST /api/v1/activities`.
class ActivityCreateRequestModel {
  ActivityCreateRequestModel({
    required this.activityTypeCode,
    required this.classroomCode,
    required this.studentCodes,
    required this.staffCode,
    required this.schoolCode,
    required this.organizationCode,
    required this.activityDate,
    required this.description,
    this.parameterValues = const [],
    this.attachments = const [],
  });

  final String activityTypeCode;
  final String classroomCode;
  final List<String> studentCodes;
  final String staffCode;
  final String schoolCode;
  final String organizationCode;
  final String activityDate;
  final String description;
  final List<Map<String, dynamic>> parameterValues;
  final List<Map<String, dynamic>> attachments;

  Map<String, dynamic> toJson() {
    return {
      'activityTypeCode': activityTypeCode,
      'classroomCode': classroomCode,
      'studentCodes': studentCodes,
      'staffCode': staffCode,
      'schoolCode': schoolCode,
      'organizationCode': organizationCode,
      'activityDate': activityDate,
      'description': description,
      if (parameterValues.isNotEmpty) 'parameterValues': parameterValues,
      if (attachments.isNotEmpty) 'attachments': attachments,
    };
  }
}

