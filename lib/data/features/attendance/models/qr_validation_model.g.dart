// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_validation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$QrValidationRequestModelToJson(
        QrValidationRequestModel instance) =>
    <String, dynamic>{
      'qrToken': instance.qrToken,
      'useCase': instance.useCase,
    };

QrValidationResponseModel _$QrValidationResponseModelFromJson(
        Map<String, dynamic> json) =>
    QrValidationResponseModel(
      valid: json['valid'] as bool? ?? false,
      schoolCode: json['schoolCode'] as String? ?? '',
      reason: json['reason'] as String?,
      validTo: _validToFromJson(json['validTo'] as String?),
    );
