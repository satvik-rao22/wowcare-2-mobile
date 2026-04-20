import 'package:equatable/equatable.dart';

class ActivitySetting extends Equatable {
  const ActivitySetting({
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

  @override
  List<Object?> get props => [
        activityTypeCode,
        activityTypeName,
        description,
        category,
        icon,
        color,
        isSystem,
        isMultiStudent,
        requiresStaff,
        requiresPhoto,
        requiresVideo,
        allowsAttachments,
        maxAttachments,
        isEnabled,
        isFavorite,
        displayOrder,
      ];
}


