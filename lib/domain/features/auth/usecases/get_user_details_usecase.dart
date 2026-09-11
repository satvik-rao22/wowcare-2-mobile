import 'package:wowcare/data/features/auth/datasources/auth_remote_datasource.dart';

/// Fetches raw user/role/school details from `GET /api/v1/users/details`.
///
/// Returns the same raw shape [AuthRemoteDataSource.getUserDetails] does —
/// callers that need typed access should go through
/// [FetchKioskUserDetailsUseCase] instead, which maps this same endpoint
/// into [UserDetailsEntity]. This use case exists so cubits that only need
/// the raw list (persona/school-status resolution) don't hold
/// [AuthRemoteDataSource] directly.
class GetUserDetailsUseCase {
  GetUserDetailsUseCase(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  Future<List<Map<String, dynamic>>> call({required String accessToken}) {
    return _remoteDataSource.getUserDetails(accessToken: accessToken);
  }
}
