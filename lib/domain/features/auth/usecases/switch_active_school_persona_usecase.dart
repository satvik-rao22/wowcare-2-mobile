import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';

/// Persists a persona switch (e.g. Staff -> Guardian) in local auth caches:
/// wipes persona-volatile caches, then records the new active school role.
/// Does not touch the visible profile — the cubit applies that separately
/// once sibling cubits (RoleCubit/ParentChildCubit) have refreshed.
class SwitchActiveSchoolPersonaUseCase {
  SwitchActiveSchoolPersonaUseCase(this._localDataSource);

  final AuthLocalDataSource _localDataSource;

  Future<void> call(String backendRole) async {
    await _localDataSource.clearPersonaVolatileCaches();
    await _localDataSource.persistActiveSchoolPersonaRole(backendRole);
  }
}
