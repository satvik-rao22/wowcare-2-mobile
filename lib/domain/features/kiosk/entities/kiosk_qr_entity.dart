import 'package:equatable/equatable.dart';

class KioskQrEntity extends Equatable {
  const KioskQrEntity({
    required this.qrPayload,
    required this.qrToken,
    required this.schoolCode,
    required this.organizationCode,
    required this.isActive,
    required this.validFrom,
    required this.validTo,
  });

  final String qrPayload;
  final String qrToken;
  final String schoolCode;
  final String organizationCode;
  final bool isActive;
  final DateTime validFrom;
  final DateTime validTo;

  @override
  List<Object?> get props => [
    qrPayload,
    qrToken,
    schoolCode,
    organizationCode,
    isActive,
    validFrom,
    validTo,
  ];
}
