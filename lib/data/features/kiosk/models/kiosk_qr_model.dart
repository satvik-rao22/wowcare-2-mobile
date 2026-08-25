import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/domain/features/kiosk/entities/kiosk_qr_entity.dart';

class KioskQrModel extends KioskQrEntity {
  const KioskQrModel({
    required String qrPayload,
    required String qrToken,
    required String schoolCode,
    required String organizationCode,
    required bool isActive,
    required DateTime validFrom,
    required DateTime validTo,
  }) : super(
         qrPayload: qrPayload,
         qrToken: qrToken,
         schoolCode: schoolCode,
         organizationCode: organizationCode,
         isActive: isActive,
         validFrom: validFrom,
         validTo: validTo,
       );

  factory KioskQrModel.fromJson(Map<String, dynamic> json) {
    return KioskQrModel(
      qrPayload: json['qrPayload'] as String? ?? '',
      qrToken: json['qrToken'] as String? ?? '',
      schoolCode: json['schoolCode'] as String? ?? '',
      organizationCode: json['organizationCode'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      validFrom: _parseDate(json['validFrom']),
      validTo: _parseDate(json['validTo']),
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return AppTime.nowUtc();
    if (date is DateTime) return date;
    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (_) {
        return AppTime.nowUtc();
      }
    }
    return AppTime.nowUtc();
  }

  Map<String, dynamic> toJson() {
    return {
      'qrPayload': qrPayload,
      'qrToken': qrToken,
      'schoolCode': schoolCode,
      'organizationCode': organizationCode,
      'isActive': isActive,
      'validFrom': validFrom.toIso8601String(),
      'validTo': validTo.toIso8601String(),
    };
  }
}
