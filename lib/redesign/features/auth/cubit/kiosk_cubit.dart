import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/features/auth/auth_strings.dart';
import 'package:wowcare/redesign/features/auth/models/models.dart';
import 'package:wowcare/redesign/features/auth/source/auth_source.dart';

part 'kiosk_state.dart';

/// The door screen, 2b, with 2e's four QR states inside it.
///
/// The QR and the PIN pad are one screen and one cubit: a family either scans
/// the code from a phone or types the PIN into this pad, and both roads end at
/// the same [KioskPinResult].
///
/// 2e is the QR panel's own state machine rather than a screen of its own, so
/// pulling the panel down refreshes it, which is what the frame demonstrates.
class KioskCubit extends Cubit<KioskState> {
  KioskCubit({required AuthSource source})
    : _source = source,
      super(const KioskState());

  /// A Sign-In PIN is always four digits.
  static const int pinLength = 4;

  final AuthSource _source;

  bool _isFetching = false;

  Future<void> load({String schoolCode = ''}) async {
    if (_isFetching) return;
    _isFetching = true;
    emit(state.copyWith(qrStatus: KioskQrStatus.loading, clearQrError: true));

    try {
      final qr = await _source.activeQr(schoolCode);
      if (isClosed) return;
      emit(
        state.copyWith(
          qrStatus: qr.isActive
              ? KioskQrStatus.ready
              : KioskQrStatus.notGenerated,
          qr: qr,
        ),
      );
    } on KioskQrFailure catch (failure) {
      if (isClosed) return;
      emit(
        state.copyWith(
          qrStatus: KioskQrStatus.failed,
          qrError: failure.message,
        ),
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() => load();

  // --- The pad --------------------------------------------------------------

  /// The pad verifies itself on the fourth digit, the way the frame does.
  /// Next is a retry, not the way through.
  Future<void> press(String digit) async {
    if (state.pin.length >= pinLength || state.isVerifying) return;
    final pin = state.pin + digit;
    emit(
      state.copyWith(
        pin: pin,
        pinStatus: KioskPinStatus.editing,
        clearNotice: true,
      ),
    );
    if (pin.length == pinLength) await submit();
  }

  void backspace() {
    if (state.pin.isEmpty) return;
    emit(
      state.copyWith(
        pin: state.pin.substring(0, state.pin.length - 1),
        pinStatus: KioskPinStatus.editing,
        clearNotice: true,
      ),
    );
  }

  /// Cancel. The frame says so out loud rather than clearing in silence.
  void cancel() => emit(
    state.copyWith(
      pin: '',
      pinStatus: KioskPinStatus.editing,
      notice: AuthStrings.pinCancelled,
      noticeTone: KioskNoticeTone.warn,
      clearResult: true,
    ),
  );

  void clearPin() => emit(
    state.copyWith(
      pin: '',
      pinStatus: KioskPinStatus.editing,
      clearNotice: true,
      clearResult: true,
    ),
  );

  Future<void> submit() async {
    if (state.isVerifying) return;

    if (state.pin.length < pinLength) {
      emit(
        state.copyWith(
          pinStatus: KioskPinStatus.rejected,
          notice: AuthStrings.shortPin,
        ),
      );
      return;
    }

    emit(state.copyWith(pinStatus: KioskPinStatus.verifying));
    final result = await _source.verifyPin(state.pin);
    if (isClosed) return;

    if (result == null) {
      emit(
        state.copyWith(
          pin: '',
          pinStatus: KioskPinStatus.rejected,
          notice: AuthStrings.invalidPin,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        pin: '',
        pinStatus: KioskPinStatus.accepted,
        result: result,
      ),
    );
  }

  /// A staff member's own PIN records their arrival or departure here rather
  /// than sending them on to a picker: there is nobody else to pick.
  Future<void> recordStaff({required bool isSigningIn}) async {
    final result = state.result;
    if (result == null || !result.isStaff) return;

    emit(state.copyWith(pinStatus: KioskPinStatus.verifying));
    final moved = await _source.recordStaff(
      result: result,
      isSigningIn: isSigningIn,
    );
    if (isClosed) return;

    emit(
      state.copyWith(
        pinStatus: KioskPinStatus.editing,
        clearResult: true,
        notice: isSigningIn
            ? AuthStrings.staffSignedIn(moved.personName)
            : AuthStrings.staffSignedOut(moved.personName),
        noticeTone: KioskNoticeTone.success,
      ),
    );
  }

  /// The pad shown in the leave-kiosk sheet. Admin PINs only.
  Future<bool> verifyAdminPin(String pin) => _source.isAdminPin(pin);
}
