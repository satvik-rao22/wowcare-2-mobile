import 'package:wowcare/domain/features/kiosk/entities/kiosk_qr_entity.dart';
import 'package:wowcare/domain/features/kiosk/entities/kiosk_pin_result_entity.dart';

abstract class KioskRepository {
  /// Fetch the active QR code for a given school.
  /// Returns KioskQrEntity with live QR data from the server.
  Future<KioskQrEntity> getActiveQrCode({required String schoolCode});

  /// Verify a 4-digit PIN and get guardian/staff details and student status.
  /// Returns KioskPinResultEntity with persona, student sign-in/out status, etc.
  /// When isLogout=true, processes this as a logout confirmation for the kiosk user.
  Future<KioskPinResultEntity> verifyPin({
    required String pin,
    required String schoolCode,
    bool isLogout = false,
  });
}
