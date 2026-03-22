import '../../../../domain/features/activity/entities/activity_type_details.dart';

class ActivityTypeDetailsModel {
  ActivityTypeDetailsModel({
    required this.code,
    required this.name,
    this.description,
    this.schoolCode,
    this.organizationCode,
    this.category,
    this.icon,
    this.color,
    required this.displayOrder,
    required this.isSystem,
    required this.isMultiStudent,
    required this.requiresStaff,
    required this.requiresPhoto,
    required this.requiresVideo,
    required this.allowsAttachments,
    required this.maxAttachments,
    this.status,
    required this.parameters,
  });

  final String code;
  final String name;
  final String? description;
  final String? schoolCode;
  final String? organizationCode;
  final String? category;
  final String? icon;
  final String? color;
  final int displayOrder;
  final bool isSystem;
  final bool isMultiStudent;
  final bool requiresStaff;
  final bool requiresPhoto;
  final bool requiresVideo;
  final bool allowsAttachments;
  final int maxAttachments;
  final String? status;
  final List<ActivityTypeParameterModel> parameters;

  factory ActivityTypeDetailsModel.fromJson(Map<String, dynamic> json) {
    final params = (json['parameters'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ActivityTypeParameterModel.fromJson)
        .toList();

    return ActivityTypeDetailsModel(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      schoolCode: json['schoolCode'] as String?,
      organizationCode: json['organizationCode'] as String?,
      category: json['category'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
      isSystem: json['isSystem'] as bool? ?? false,
      isMultiStudent: json['isMultiStudent'] as bool? ?? true,
      requiresStaff: json['requiresStaff'] as bool? ?? false,
      requiresPhoto: json['requiresPhoto'] as bool? ?? false,
      requiresVideo: json['requiresVideo'] as bool? ?? false,
      allowsAttachments: json['allowsAttachments'] as bool? ?? false,
      maxAttachments: json['maxAttachments'] as int? ?? 0,
      status: json['status'] as String?,
      parameters: params,
    );
  }

  ActivityTypeDetails toEntity() {
    return ActivityTypeDetails(
      code: code,
      name: name,
      description: description,
      schoolCode: schoolCode,
      organizationCode: organizationCode,
      category: category,
      icon: icon,
      color: color,
      displayOrder: displayOrder,
      isSystem: isSystem,
      isMultiStudent: isMultiStudent,
      requiresStaff: requiresStaff,
      requiresPhoto: requiresPhoto,
      requiresVideo: requiresVideo,
      allowsAttachments: allowsAttachments,
      maxAttachments: maxAttachments,
      status: status,
      parameters: parameters.map((p) => p.toEntity()).toList(),
    );
  }
}

class ActivityTypeParameterModel {
  ActivityTypeParameterModel({
    required this.code,
    required this.parameterName,
    this.dataType,
    this.parameterType,
    required this.isRequired,
    this.minValue,
    this.maxValue,
    this.minLength,
    this.maxLength,
    this.pattern,
    required this.displayOrder,
    this.placeholder,
    this.helpText,
    this.parentParameterCode,
    this.defaultValue,
    this.status,
    required this.options,
  });

  final String code;
  final String parameterName;
  final String? dataType;
  final String? parameterType;
  final bool isRequired;
  final num? minValue;
  final num? maxValue;
  final int? minLength;
  final int? maxLength;
  final String? pattern;
  final int displayOrder;
  final String? placeholder;
  final String? helpText;
  final String? parentParameterCode;
  final String? defaultValue;
  final String? status;
  final List<ActivityTypeParameterOptionModel> options;

  factory ActivityTypeParameterModel.fromJson(Map<String, dynamic> json) {
    final opts = (json['options'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ActivityTypeParameterOptionModel.fromJson)
        .toList();

    return ActivityTypeParameterModel(
      code: json['code'] as String? ?? '',
      parameterName: json['parameterName'] as String? ?? '',
      dataType: json['dataType'] as String?,
      parameterType: json['parameterType'] as String?,
      isRequired: json['isRequired'] as bool? ?? false,
      minValue: json['minValue'] as num?,
      maxValue: json['maxValue'] as num?,
      minLength: json['minLength'] as int?,
      maxLength: json['maxLength'] as int?,
      pattern: json['pattern'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
      placeholder: json['placeholder'] as String?,
      helpText: json['helpText'] as String?,
      parentParameterCode: json['parentParameterCode'] as String?,
      defaultValue: json['defaultValue'] as String?,
      status: json['status'] as String?,
      options: opts,
    );
  }

  ActivityTypeParameter toEntity() {
    return ActivityTypeParameter(
      code: code,
      parameterName: parameterName,
      dataType: dataType,
      parameterType: parameterType,
      isRequired: isRequired,
      minValue: minValue,
      maxValue: maxValue,
      minLength: minLength,
      maxLength: maxLength,
      pattern: pattern,
      displayOrder: displayOrder,
      placeholder: placeholder,
      helpText: helpText,
      parentParameterCode: parentParameterCode,
      defaultValue: defaultValue,
      status: status,
      options: options.map((o) => o.toEntity()).toList(),
    );
  }
}

class ActivityTypeParameterOptionModel {
  ActivityTypeParameterOptionModel({
    required this.code,
    this.optionCode,
    this.optionLabel,
    required this.displayOrder,
    this.icon,
    this.color,
    required this.isDefault,
    this.status,
    this.parentOptionCode,
  });

  final String code;
  final String? optionCode;
  final String? optionLabel;
  final int displayOrder;
  final String? icon;
  final String? color;
  final bool isDefault;
  final String? status;
  final String? parentOptionCode;

  factory ActivityTypeParameterOptionModel.fromJson(Map<String, dynamic> json) {
    return ActivityTypeParameterOptionModel(
      code: json['code'] as String? ?? '',
      optionCode: json['optionCode'] as String?,
      optionLabel: json['optionLabel'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      status: json['status'] as String?,
      parentOptionCode: json['parentOptionCode'] as String?,
    );
  }

  ActivityTypeParameterOption toEntity() {
    return ActivityTypeParameterOption(
      code: code,
      optionCode: optionCode,
      optionLabel: optionLabel,
      displayOrder: displayOrder,
      icon: icon,
      color: color,
      isDefault: isDefault,
      status: status,
      parentOptionCode: parentOptionCode,
    );
  }
}


