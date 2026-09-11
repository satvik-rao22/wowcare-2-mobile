import 'package:wowcare/domain/features/activity/entities/activity_type_summary.dart';
import 'package:wowcare/domain/features/activity/repositories/activity_repository.dart';

class GetActiveActivityTypesForSchoolUseCase {
  const GetActiveActivityTypesForSchoolUseCase(this._repo);

  final ActivityRepository _repo;

  Future<List<ActivityTypeSummary>> call({
    required String schoolCode,
  }) {
    return _repo.getActiveActivityTypesForSchool(schoolCode: schoolCode);
  }
}

