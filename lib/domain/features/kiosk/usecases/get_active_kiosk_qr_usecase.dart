import 'package:wowcare/domain/features/kiosk/entities/kiosk_qr_entity.dart';
import 'package:wowcare/domain/features/kiosk/repositories/kiosk_repository.dart';

class GetActiveKioskQrUseCase {
  const GetActiveKioskQrUseCase(this._repository);

  final KioskRepository _repository;

  Future<KioskQrEntity> call({required String schoolCode}) =>
      _repository.getActiveQrCode(schoolCode: schoolCode);
}
