import 'package:json_annotation/json_annotation.dart';
import 'package:wowcare/domain/features/attendance/entities/qr_validation_result.dart';

part 'qr_validation_model.g.dart';

@JsonSerializable(createFactory: false)
class QrValidationRequestModel {
  const QrValidationRequestModel({
    required this.qrToken,
    required this.useCase,
  });

  final String qrToken;
  final String useCase;

  Map<String, dynamic> toJson() => _$QrValidationRequestModelToJson(this);
}

/// [DateTime.tryParse] (not the generated default of [DateTime.parse]) is
/// deliberate: an unparseable `validTo` must become null, not throw and take
/// the whole response down with it.
DateTime? _validToFromJson(String? value) =>
    value == null ? null : DateTime.tryParse(value);

String? _validToToJson(DateTime? value) => value?.toIso8601String();

@JsonSerializable(createToJson: false)
class QrValidationResponseModel {
  const QrValidationResponseModel({
    required this.valid,
    required this.schoolCode,
    this.reason,
    this.validTo,
  });

  @JsonKey(defaultValue: false)
  final bool valid;

  @JsonKey(defaultValue: '')
  final String schoolCode;

  final String? reason;

  @JsonKey(fromJson: _validToFromJson, toJson: _validToToJson)
  final DateTime? validTo;

  /// The backend wraps the payload in a `data` envelope; unwrap it here so
  /// the generated per-field parsing below only ever sees the flat object.
  factory QrValidationResponseModel.fromJson(Map<String, dynamic> json) =>
      _$QrValidationResponseModelFromJson(
        json['data'] as Map<String, dynamic>? ?? const {},
      );

  QrValidationResult toEntity() => QrValidationResult(
        valid: valid,
        schoolCode: schoolCode,
        reason: reason,
        validTo: validTo,
      );
}
