import 'package:wowcare/data/features/student/datasources/student_remote_datasource.dart';
import 'package:wowcare/data/features/user_profile/mappers/guardian_profile_mapper.dart';
import 'package:wowcare/data/features/user_profile/models/guardian_profile_model.dart';
import 'package:wowcare/domain/features/user_profile/entities/guardian_profile.dart';
import 'package:wowcare/domain/features/user_profile/entities/guardian_profile_update.dart';
import 'package:wowcare/domain/features/user_profile/repositories/user_profile_repository.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  UserProfileRepositoryImpl(this._studentRemoteDataSource);

  final StudentRemoteDataSource _studentRemoteDataSource;

  @override
  Future<GuardianProfile> getGuardianProfile({
    required String schoolCode,
    required String userCode,
  }) async {
    final json = await _studentRemoteDataSource.getGuardianProfile(
      schoolCode: schoolCode,
      userCode: userCode,
    );
    return guardianProfileFromModel(GuardianProfileModel.fromJson(json));
  }

  @override
  Future<String> updateGuardianProfile(GuardianProfileUpdate update) {
    final body = <String, dynamic>{
      'code': update.guardianCode,
      'firstName': update.firstName,
      'lastName': update.lastName,
      'mobile': update.phoneDigits,
    };

    if (update.hasAddress) {
      body['address'] = <String, dynamic>{
        'line1': update.addressStreet,
        'line2': update.addressLine2,
        'city': update.addressCity,
        'state': update.addressState,
        'country': update.addressCountry,
        'postalCode': _formatPostalCode(update.addressZipCode),
        'street': '',
      };
    }

    return _studentRemoteDataSource.updateGuardianMyProfile(body: body);
  }

  /// Formats a raw ZIP into the `12345` / `12345-6789` shape the guardian
  /// API returns (input may already contain a hyphen or be digits-only).
  String _formatPostalCode(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 5) return digits;
    return '${digits.substring(0, 5)}-${digits.substring(5, digits.length.clamp(5, 9))}';
  }
}
