import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/cache_manager.dart';
import 'package:wowcare/data/features/newsletter/datasources/newsletter_remote_datasource.dart';
import 'package:wowcare/data/features/newsletter/models/newsletter_models.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_attachment.dart';
import 'package:wowcare/domain/features/newsletter/repositories/newsletter_repository.dart';

class NewsletterRepositoryImpl
    implements NewsletterRepository, NewsletterRepositoryWithCache {
  NewsletterRepositoryImpl(
    this._remoteDataSource,
    StorageService storageService,
  ) : _cacheManager = CacheManager(storageService);

  final NewsletterRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  static const String _sentStatus = 'SENT';

  static String _sentNewslettersCacheKey(String schoolCode) =>
      CacheManager.buildCacheKey(
        feature: 'newsletter',
        resource: 'sent_list',
        identifier: schoolCode.trim(),
      );

  @override
  Future<NewsletterPage> getSentNewsletters({
    required String schoolCode,
    String? search,
    List<String> classroomCodes = const <String>[],
    int page = 0,
    int size = 20,
  }) async {
    final model = await _remoteDataSource.getNewslettersBySchool(
      schoolCode: schoolCode,
      status: _sentStatus,
      search: search,
      classroomCodes: classroomCodes,
      page: page,
      size: size,
      sort: const ['sentAt,desc'],
    );

    if (page == 0) {
      await _cacheManager.saveCache(
        _sentNewslettersCacheKey(schoolCode),
        model.toJson(),
      );
    }

    return _mapPageModelToEntity(model);
  }

  @override
  Future<Newsletter> getNewsletterByCode(String code) async {
    final model = await _remoteDataSource.getNewsletterByCode(code);
    return _mapModelToEntity(model);
  }

  @override
  Future<NewsletterPage?> loadCachedSentNewsletters(String schoolCode) async {
    final payload = await _cacheManager.loadCache(
      _sentNewslettersCacheKey(schoolCode),
    );
    if (payload == null) return null;
    return _mapPageModelToEntity(NewsletterPageModel.fromCacheJson(payload));
  }

  NewsletterPage _mapPageModelToEntity(NewsletterPageModel model) {
    return NewsletterPage(
      items: model.items.map(_mapModelToEntity).toList(),
      page: model.page,
      size: model.size,
      totalPages: model.totalPages,
      totalElements: model.totalElements,
      hasMore: model.hasMore,
    );
  }

  Newsletter _mapModelToEntity(NewsletterModel model) {
    return Newsletter(
      id: model.id,
      code: model.code,
      schoolCode: model.schoolCode,
      title: model.title,
      subtitle: model.subtitle,
      status: model.status,
      sentAt: model.sentAt,
      createdAt: model.createdAt,
      recipientCount: model.recipientCount,
      classroomCodes: model.classroomCodes,
      createdByName: model.createdByName,
      bodyHtml: buildNewsletterBodyHtml(
        layoutJson: model.layoutJson,
        subtitle: model.subtitle,
        components: model.components,
      ),
      attachments: model.attachments
          .map(
            (NewsletterAttachmentModel attachment) => NewsletterAttachment(
              id: attachment.id,
              mediaCode: attachment.mediaCode,
              fileName: attachment.fileName,
              mimeType: attachment.mimeType,
            ),
          )
          .toList(),
    );
  }
}
