import 'package:wowcare/domain/features/reports/repositories/school_context_repository.dart';

/// The active school name, trimmed; '' when unset.
class GetSchoolNameUseCase {
  GetSchoolNameUseCase(this._repository);

  final SchoolContextRepository _repository;

  Future<String> call() => _repository.getSchoolName();
}
