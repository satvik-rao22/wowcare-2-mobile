import 'package:equatable/equatable.dart';

class QrValidationResult extends Equatable {
  const QrValidationResult({
    required this.valid,
    required this.schoolCode,
    this.reason,
    this.validTo,
  });

  final bool valid;
  final String schoolCode;
  final String? reason;
  final DateTime? validTo;

  @override
  List<Object?> get props => [valid, schoolCode, reason, validTo];
}
