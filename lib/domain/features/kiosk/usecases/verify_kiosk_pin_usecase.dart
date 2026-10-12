import 'package:wowcare/core/observability/app_events.dart';
import 'package:wowcare/domain/features/kiosk/entities/kiosk_pin_result_entity.dart';
import 'package:wowcare/domain/features/kiosk/repositories/kiosk_repository.dart';

class VerifyKioskPinUseCase {
  VerifyKioskPinUseCase(this._repository);

  final KioskRepository _repository;

  /// A wrong PIN is refused with an error status and thrown, so it is logged
  /// failed from that status. A sign-in reply naming no persona the kiosk can
  /// route is shown to the user as an invalid response, so it is logged
  /// failed too; a logout ignores the reply.
  Future<KioskPinResultEntity> call({
    required String pin,
    required String schoolCode,
    bool isLogout = false,
  }) => AppEvents.track(
    AppEvent.kioskPinVerify,
    () => _repository.verifyPin(
      pin: pin,
      schoolCode: schoolCode,
      isLogout: isLogout,
    ),
    failureOf: (result) => !isLogout && result.persona == KioskPersona.unknown
        ? EventFailure.server
        : null,
  );
}
