import 'package:wowcare/domain/features/kiosk/entities/kiosk_pin_result_entity.dart';
import 'package:wowcare/domain/features/kiosk/repositories/kiosk_repository.dart';

class VerifyKioskPinUseCase {
  VerifyKioskPinUseCase(this._repository);

  final KioskRepository _repository;

  Future<KioskPinResultEntity> call({
    required String pin,
    required String schoolCode,
  }) =>
      _repository.verifyPin(pin: pin, schoolCode: schoolCode);
}
