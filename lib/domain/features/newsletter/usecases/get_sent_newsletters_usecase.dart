import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';
import 'package:wowcare/domain/features/newsletter/repositories/newsletter_repository.dart';

class GetSentNewslettersUseCase {
  GetSentNewslettersUseCase(this._repository);

  final NewsletterRepository _repository;

  Future<NewsletterPage> call({
    required String schoolCode,
    String? search,
    List<String> classroomCodes = const <String>[],
    int page = 0,
    int size = 20,
  }) {
    return _repository.getSentNewsletters(
      schoolCode: schoolCode,
      search: search,
      classroomCodes: classroomCodes,
      page: page,
      size: size,
    );
  }
}
