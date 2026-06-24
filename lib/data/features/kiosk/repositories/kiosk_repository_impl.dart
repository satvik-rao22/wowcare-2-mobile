import 'package:wowcare/data/features/kiosk/datasources/kiosk_remote_datasource.dart';
import 'package:wowcare/domain/features/kiosk/entities/kiosk_pin_result_entity.dart';
import 'package:wowcare/domain/features/kiosk/entities/kiosk_qr_entity.dart';
import 'package:wowcare/domain/features/kiosk/repositories/kiosk_repository.dart';

class KioskRepositoryImpl implements KioskRepository {
  const KioskRepositoryImpl(this._remoteDataSource);

  final KioskRemoteDataSource _remoteDataSource;

  @override
  Future<KioskQrEntity> getActiveQrCode({required String schoolCode}) =>
      _remoteDataSource.getActiveQrCode(schoolCode: schoolCode);

  @override
  Future<KioskPinResultEntity> verifyPin({
    required String pin,
    required String schoolCode,
  }) =>
      _remoteDataSource.verifyPin(pin: pin, schoolCode: schoolCode);
}
