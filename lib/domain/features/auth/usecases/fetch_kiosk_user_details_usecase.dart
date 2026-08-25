import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/data/features/auth/datasources/auth_remote_datasource.dart';
import 'package:wowcare/data/features/auth/models/user_details_model.dart';
import 'package:wowcare/domain/features/auth/entities/user_details_entity.dart';

/// Fetches and maps user details for kiosk users.
///
/// Returns the parsed UserDetailsEntity containing school information,
/// organization name, and permissions.
class FetchKioskUserDetailsUseCase {
  FetchKioskUserDetailsUseCase({required AuthRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final AuthRemoteDataSource _remoteDataSource;

  /// Fetch user details from API and return mapped entity.
  ///
  /// For kiosk users, this provides:
  /// - schoolName (actual name, not code)
  /// - organizationName
  /// - permissions
  /// - role for each school
  Future<UserDetailsEntity?> call({required String accessToken}) async {
    try {
      AppLogger.d(
        '[KioskAuth] Fetching user details from /api/v1/users/details',
      );

      // Call the API via auth remote datasource
      final rawDataList = await _remoteDataSource.getUserDetails(
        accessToken: accessToken,
      );

      if (rawDataList.isEmpty) {
        AppLogger.w('[KioskAuth] User details API returned empty list');
        return null;
      }

      // Wrap the list in a data structure that matches the API response format
      final response = <String, dynamic>{'data': rawDataList};

      final model = UserDetailsResponseModel.fromJson(response);
      final entity = _mapToEntity(model);

      AppLogger.d(
        '[KioskAuth] User details fetched successfully: '
        'users=${entity.data.length}',
      );

      return entity;
    } catch (e) {
      AppLogger.w('[KioskAuth] Error fetching user details: $e');
      return null;
    }
  }

  /// Map the DTO model to domain entity.
  UserDetailsEntity _mapToEntity(UserDetailsResponseModel model) {
    return UserDetailsEntity(
      data: model.data
          .map(
            (user) => UserDetailEntity(
              userCode: user.userCode,
              organizationCode: user.organizationCode,
              organizationName: user.organizationName,
              schools: user.schools
                  .map(
                    (school) => SchoolDetailEntity(
                      schoolCode: school.schoolCode,
                      schoolName: school.schoolName,
                      status: school.status,
                      role: school.role,
                      permissions: school.permissions
                          .map(
                            (perm) => PermissionEntity(
                              module: perm.module,
                              read: perm.read,
                              write: perm.write,
                            ),
                          )
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }
}
