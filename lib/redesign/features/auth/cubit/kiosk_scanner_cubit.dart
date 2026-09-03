import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/features/auth/models/models.dart';
import 'package:wowcare/redesign/features/auth/source/auth_source.dart';

part 'kiosk_scanner_state.dart';

/// 2a. The scanner a signed-in phone opens from Scan QR on its dashboard.
///
/// The camera itself is not wired during the UI phase, so the viewfinder is
/// drawn and the frame's own "In range" pill stands for a code coming into
/// view. Reading the payload is the one call Scan QR adds, and it verifies the
/// same payload the kiosk pad verifies from the other end.
class KioskScannerCubit extends Cubit<KioskScannerState> {
  KioskScannerCubit({required AuthSource source})
    : _source = source,
      super(const KioskScannerState());

  final AuthSource _source;

  bool _isFetching = false;

  void toggleTorch() => emit(state.copyWith(isTorchOn: !state.isTorchOn));

  void flipCamera() => emit(state.copyWith(isFrontCamera: !state.isFrontCamera));

  Future<void> scanned(String payload) async {
    if (_isFetching) return;
    _isFetching = true;
    emit(state.copyWith(status: KioskScannerStatus.reading));

    final result = await _source.resolveScannedCode(payload);
    _isFetching = false;
    if (isClosed) return;

    emit(
      result == null
          ? state.copyWith(status: KioskScannerStatus.unreadable)
          : state.copyWith(status: KioskScannerStatus.accepted, result: result),
    );
  }

  void rescan() => emit(const KioskScannerState());
}
