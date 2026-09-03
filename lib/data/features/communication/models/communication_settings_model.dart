import '../../../../domain/features/communication/entities/communication_settings.dart';

class CommunicationSettingsModel extends CommunicationSettings {
  const CommunicationSettingsModel({
    required super.schoolCode,
    required super.adminCanDeleteAny,
    required super.deleteTimeLimitMinutes,
    required super.notifyStaffToParent,
    required super.notifyStaffToStaff,
    required super.notifyParentToStaff,
  });

  factory CommunicationSettingsModel.fromJson(Map<String, dynamic> json) {
    return CommunicationSettingsModel(
      schoolCode: (json['schoolCode'] as String?) ?? '',
      adminCanDeleteAny: json['adminCanDeleteAny'] as bool? ?? false,
      deleteTimeLimitMinutes: (json['deleteTimeLimitMinutes'] as num?)?.toInt(),
      notifyStaffToParent: json['notifyStaffToParent'] as bool? ?? true,
      notifyStaffToStaff: json['notifyStaffToStaff'] as bool? ?? true,
      notifyParentToStaff: json['notifyParentToStaff'] as bool? ?? true,
    );
  }
}
