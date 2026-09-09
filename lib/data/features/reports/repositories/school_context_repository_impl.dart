import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/reports/repositories/school_context_repository.dart';

class SchoolContextRepositoryImpl implements SchoolContextRepository {
  SchoolContextRepositoryImpl(this._storageService);

  final StorageService _storageService;

  @override
  Future<String> getSchoolCode() async =>
      (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();

  @override
  Future<String> getSchoolName() async =>
      (await _storageService.getString(StorageKeys.schoolName) ?? '').trim();
}
