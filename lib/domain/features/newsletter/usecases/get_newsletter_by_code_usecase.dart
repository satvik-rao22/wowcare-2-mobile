import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';
import 'package:wowcare/domain/features/newsletter/repositories/newsletter_repository.dart';

class GetNewsletterByCodeUseCase {
  GetNewsletterByCodeUseCase(this._repository);

  final NewsletterRepository _repository;

  Future<Newsletter> call(String code) {
    return _repository.getNewsletterByCode(code);
  }
}
