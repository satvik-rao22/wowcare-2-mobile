part of 'kiosk_cubit.dart';

/// 2e's four states, in the order the frame draws them.
enum KioskQrStatus { loading, ready, notGenerated, failed }

enum KioskPinStatus { editing, verifying, rejected, accepted }

/// A notice under the PIN dots: a refusal, a cancellation, or a receipt.
enum KioskNoticeTone { danger, warn, success }

@immutable
class KioskState extends Equatable {
  const KioskState({
    this.qrStatus = KioskQrStatus.loading,
    this.qr,
    this.qrError,
    this.pin = '',
    this.pinStatus = KioskPinStatus.editing,
    this.notice,
    this.noticeTone = KioskNoticeTone.danger,
    this.result,
  });

  final KioskQrStatus qrStatus;
  final KioskQr? qr;

  /// The line 2e's red alert carries when the QR could not be fetched.
  final String? qrError;

  final String pin;
  final KioskPinStatus pinStatus;

  /// The line under the PIN dots: a refusal, or a staff member's receipt.
  final String? notice;
  final KioskNoticeTone noticeTone;

  /// Who the accepted PIN belongs to. The page reads this and moves on.
  final KioskPinResult? result;

  bool get isVerifying => pinStatus == KioskPinStatus.verifying;
  bool get isQrLoading => qrStatus == KioskQrStatus.loading;
  bool get isQrReady => qrStatus == KioskQrStatus.ready;
  bool get canSubmit => pin.length == KioskCubit.pinLength && !isVerifying;

  KioskState copyWith({
    KioskQrStatus? qrStatus,
    KioskQr? qr,
    String? qrError,
    String? pin,
    KioskPinStatus? pinStatus,
    String? notice,
    KioskNoticeTone? noticeTone,
    KioskPinResult? result,
    bool clearQrError = false,
    bool clearNotice = false,
    bool clearResult = false,
  }) => KioskState(
    qrStatus: qrStatus ?? this.qrStatus,
    qr: qr ?? this.qr,
    qrError: clearQrError ? null : (qrError ?? this.qrError),
    pin: pin ?? this.pin,
    pinStatus: pinStatus ?? this.pinStatus,
    notice: clearNotice ? null : (notice ?? this.notice),
    noticeTone: noticeTone ?? this.noticeTone,
    result: clearResult ? null : (result ?? this.result),
  );

  @override
  List<Object?> get props => [
    qrStatus,
    qr,
    qrError,
    pin,
    pinStatus,
    notice,
    noticeTone,
    result,
  ];
}
