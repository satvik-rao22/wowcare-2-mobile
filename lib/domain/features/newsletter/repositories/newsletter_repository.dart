import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';

abstract class NewsletterRepository {
  Future<NewsletterPage> getSentNewsletters({
    required String schoolCode,
    int page = 0,
    int size = 20,
  });

  Future<Newsletter> getNewsletterByCode(String code);
}

abstract class NewsletterRepositoryWithCache {
  Future<NewsletterPage?> loadCachedSentNewsletters(String schoolCode);
}
