import 'package:json_annotation/json_annotation.dart';
import '../../../../domain/features/communication/entities/communication_settings.dart';

part 'communication_settings_model.g.dart';

/// API model for `GET /api/v1/messaging/communication-settings`.
///
/// Serialisation is generated (`json_serializable`); the `@JsonKey` defaults
/// preserve the previous hand-written `fromJson` behaviour exactly — missing
/// or null `schoolCode` → `''`, missing/null notify flags → `true`,
/// `adminCanDeleteAny` → `false`, and `deleteTimeLimitMinutes` stays nullable
/// (parsed as `num?` then `.toInt()` so a double-encoded value never throws).
///
/// The model is a plain DTO; [toEntity] maps it to the pure-Dart
/// [CommunicationSettings] entity (mandate: entities carry no serialisation).
@JsonSerializable()
class CommunicationSettingsModel {
  const CommunicationSettingsModel({
    required this.schoolCode,
    required this.adminCanDeleteAny,
    required this.deleteTimeLimitMinutes,
    required this.notifyStaffToParent,
    required this.notifyStaffToStaff,
    required this.notifyParentToStaff,
  });

  @JsonKey(defaultValue: '')
  final String schoolCode;

  @JsonKey(defaultValue: false)
  final bool adminCanDeleteAny;

  final int? deleteTimeLimitMinutes;

  @JsonKey(defaultValue: true)
  final bool notifyStaffToParent;

  @JsonKey(defaultValue: true)
  final bool notifyStaffToStaff;

  @JsonKey(defaultValue: true)
  final bool notifyParentToStaff;

  factory CommunicationSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$CommunicationSettingsModelFromJson(json);

  Map<String, dynamic> toJson() => _$CommunicationSettingsModelToJson(this);

  CommunicationSettings toEntity() => CommunicationSettings(
    schoolCode: schoolCode,
    adminCanDeleteAny: adminCanDeleteAny,
    deleteTimeLimitMinutes: deleteTimeLimitMinutes,
    notifyStaffToParent: notifyStaffToParent,
    notifyStaffToStaff: notifyStaffToStaff,
    notifyParentToStaff: notifyParentToStaff,
  );
}
