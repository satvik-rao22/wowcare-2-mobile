part of 'kiosk_scanner_cubit.dart';

enum KioskScannerStatus {
  /// The viewfinder, waiting for a code.
  scanning,
  reading,

  /// The code is not one of ours.
  unreadable,
  accepted,
}

@immutable
class KioskScannerState extends Equatable {
  const KioskScannerState({
    this.status = KioskScannerStatus.scanning,
    this.isTorchOn = false,
    this.isFrontCamera = false,
    this.result,
  });

  final KioskScannerStatus status;
  final bool isTorchOn;
  final bool isFrontCamera;

  /// Who the scanned code resolved to. The page reads this and moves on.
  final KioskPinResult? result;

  bool get isReading => status == KioskScannerStatus.reading;
  bool get isUnreadable => status == KioskScannerStatus.unreadable;

  KioskScannerState copyWith({
    KioskScannerStatus? status,
    bool? isTorchOn,
    bool? isFrontCamera,
    KioskPinResult? result,
  }) => KioskScannerState(
    status: status ?? this.status,
    isTorchOn: isTorchOn ?? this.isTorchOn,
    isFrontCamera: isFrontCamera ?? this.isFrontCamera,
    result: result ?? this.result,
  );

  @override
  List<Object?> get props => [status, isTorchOn, isFrontCamera, result];
}
