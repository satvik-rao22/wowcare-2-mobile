import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// The live QR the door screen shows. Mirrors `KioskQrEntity`: a payload, the
/// school it belongs to, and how long it stays valid.
@immutable
class KioskQr extends Equatable {
  const KioskQr({
    required this.schoolName,
    required this.payload,
    required this.validTo,
    this.isActive = true,
  });

  final String schoolName;
  final String payload;
  final DateTime validTo;
  final bool isActive;

  @override
  List<Object?> get props => [schoolName, payload, validTo, isActive];
}

/// The QR could not be fetched. Carries the line 2e's red alert shows.
class KioskQrFailure implements Exception {
  const KioskQrFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
