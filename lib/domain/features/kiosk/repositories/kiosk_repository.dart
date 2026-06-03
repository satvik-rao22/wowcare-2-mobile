import 'package:wowcare/domain/features/kiosk/entities/kiosk_qr_entity.dart';

abstract class KioskRepository {
  /// Fetch the active QR code for a given school.
  /// Returns KioskQrEntity with live QR data from the server.
  Future<KioskQrEntity> getActiveQrCode({required String schoolCode});
}
