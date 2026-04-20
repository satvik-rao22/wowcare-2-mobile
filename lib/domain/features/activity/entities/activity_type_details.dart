import 'package:equatable/equatable.dart';

class ActivityTypeDetails extends Equatable {
  const ActivityTypeDetails({
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
  final List<ActivityTypeParameter> parameters;

  @override
  List<Object?> get props => [
        code,
        name,
        description,
        schoolCode,
        organizationCode,
        category,
        icon,
        color,
        displayOrder,
        isSystem,
        isMultiStudent,
        requiresStaff,
        requiresPhoto,
        requiresVideo,
        allowsAttachments,
        maxAttachments,
        status,
        parameters,
      ];
}

class ActivityTypeParameter extends Equatable {
  const ActivityTypeParameter({
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
  final List<ActivityTypeParameterOption> options;

  @override
  List<Object?> get props => [
        code,
        parameterName,
        dataType,
        parameterType,
        isRequired,
        minValue,
        maxValue,
        minLength,
        maxLength,
        pattern,
        displayOrder,
        placeholder,
        helpText,
        parentParameterCode,
        defaultValue,
        status,
        options,
      ];
}

class ActivityTypeParameterOption extends Equatable {
  const ActivityTypeParameterOption({
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

  @override
  List<Object?> get props => [
        code,
        optionCode,
        optionLabel,
        displayOrder,
        icon,
        color,
        isDefault,
        status,
        parentOptionCode,
      ];
}


