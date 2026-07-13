import 'package:wowcare/domain/features/attendance/entities/qr_validation_result.dart';

class QrValidationRequestModel {
  const QrValidationRequestModel({
    required this.qrToken,
    required this.useCase,
  });

  final String qrToken;
  final String useCase;

  Map<String, dynamic> toJson() => {
        'qrToken': qrToken,
        'useCase': useCase,
      };
}

class QrValidationResponseModel {
  const QrValidationResponseModel({
    required this.valid,
    required this.schoolCode,
    this.reason,
    this.validTo,
  });

  final bool valid;
  final String schoolCode;
  final String? reason;
  final DateTime? validTo;

  factory QrValidationResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    return QrValidationResponseModel(
      valid: data['valid'] as bool? ?? false,
      schoolCode: data['schoolCode'] as String? ?? '',
      reason: data['reason'] as String?,
      validTo: data['validTo'] != null
          ? DateTime.tryParse(data['validTo'] as String)
          : null,
    );
  }

  QrValidationResult toEntity() => QrValidationResult(
        valid: valid,
        schoolCode: schoolCode,
        reason: reason,
        validTo: validTo,
      );
}
