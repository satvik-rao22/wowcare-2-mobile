import 'package:wowcare/domain/features/reports/repositories/school_context_repository.dart';

/// The active school code, trimmed; '' when unset.
class GetSchoolCodeUseCase {
  GetSchoolCodeUseCase(this._repository);

  final SchoolContextRepository _repository;

  Future<String> call() => _repository.getSchoolCode();
}
