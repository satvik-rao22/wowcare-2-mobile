import 'package:wowcare/data/features/communication/realtime/firebase_token_data_source.dart';

class RegisterFirebaseTokenUseCase {
  const RegisterFirebaseTokenUseCase(this._dataSource);

  final FirebaseTokenDataSource _dataSource;

  Future<void> call({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
  }) {
    return _dataSource.registerToken(
      userCode: userCode,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
    );
  }
}
