import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/cache_manager.dart';
import '../../../../domain/features/staff/entities/staff_member.dart';
import '../../../../domain/features/staff/entities/staff_document.dart';
import '../../../../domain/features/staff/entities/staff_documents_page.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../datasources/staff_remote_datasource.dart';
import '../models/staff_models.dart';
import '../models/staff_document_models.dart';

class StaffRepositoryImpl implements StaffRepository, StaffRepositoryWithCache {
  StaffRepositoryImpl(this._remoteDataSource, this._storageService)
      : _cacheManager = CacheManager(_storageService);

  final StaffRemoteDataSource _remoteDataSource;
  final StorageService _storageService;
  final CacheManager _cacheManager;

  static String _staffListCacheKey(String schoolCode) =>
      'staff_list_cache_$schoolCode';
  static String _staffDocumentsCacheKey(String staffCode) =>
      'staff_documents_cache_$staffCode';

  @override
  Future<StaffPage> getStaffPage({
    required String schoolCode,
    int page = 0,
    int size = 10,
    String? status,
    String? designation,
    String? search,
  }) async {
    final staffPageModel = await _remoteDataSource.getStaffPage(
      schoolCode: schoolCode,
      page: page,
      size: size,
      status: status,
      designation: designation,
      search: search,
    );

    // Cache only the first page for simplicity
    if (page == 0) {
      await _cacheManager.saveCache(
        _staffListCacheKey(schoolCode),
        staffPageModel.toJson(),
      );
    }

    return _mapPageModelToEntity(staffPageModel);
  }

  @override
  Future<StaffPage?> loadCachedStaffPage(String schoolCode) async {
    final payload = await _cacheManager.loadCache(_staffListCacheKey(schoolCode));
    if (payload == null) return null;

    final model = StaffPageModel.fromCacheJson(payload);
    return _mapPageModelToEntity(model);
  }

  @override
  Future<StaffDocumentsPage?> loadCachedStaffDocuments(String staffCode) async {
    final payload = await _cacheManager.loadCache(_staffDocumentsCacheKey(staffCode));
    if (payload == null) return null;

    final model = StaffDocumentsPageModel.fromCacheJson(payload);
    return _mapDocumentsPageModelToEntity(model);
  }

  StaffPage _mapPageModelToEntity(StaffPageModel model) {
    final items = model.items
        .map(
          (m) => StaffMember(
            code: m.code,
            name: m.name,
            classroomCodes: m.classroomCodes,
            designation: m.designation,
            phoneNumber: m.phoneNumber,
            status: m.status,
          ),
        )
        .toList();

    return StaffPage(
      items: items,
      page: model.page,
      size: model.size,
      totalPages: model.totalPages,
      totalElements: model.totalElements,
      hasMore: model.hasMore,
    );
  }

  @override
  Future<String> addStaffDocument({
    required String staffCode,
    required StaffDocument document,
  }) async {
    final request = StaffDocumentRequestModel(
      documentType: document.documentType,
      documentName: document.documentName,
      documentUrl: document.documentUrl,
      documentSizeKb: document.documentSizeKb,
      mimeType: document.mimeType,
      expiryDate: document.expiryDate,
    );

    final response = await _remoteDataSource.addStaffDocument(
      staffCode: staffCode,
      request: request,
    );

    // Invalidate documents cache when a new document is added
    await _cacheManager.invalidateCache(_staffDocumentsCacheKey(staffCode));

    return response.message;
  }

  @override
  Future<StaffDocumentsPage> getStaffDocuments({
    required String staffCode,
    int page = 0,
    int size = 10,
    bool? expired,
  }) async {
    final documentsPageModel = await _remoteDataSource.getStaffDocuments(
      staffCode: staffCode,
      page: page,
      size: size,
      expired: expired,
    );

    // Cache only the first page
    if (page == 0) {
      await _cacheManager.saveCache(
        _staffDocumentsCacheKey(staffCode),
        documentsPageModel.toJson(),
      );
    }

    return _mapDocumentsPageModelToEntity(documentsPageModel);
  }

  StaffDocumentsPage _mapDocumentsPageModelToEntity(StaffDocumentsPageModel model) {
    final items = model.items
        .map(
          (m) => StaffDocument(
            documentUuid: m.documentUuid,
            documentType: m.documentType,
            documentName: m.documentName,
            documentUrl: m.documentUrl,
            documentSizeKb: m.documentSizeKb,
            mimeType: m.mimeType,
            expiryDate: m.expiryDate,
            expired: m.expired,
            createdAt: m.createdAt,
          ),
        )
        .toList();

    return StaffDocumentsPage(
      items: items,
      page: model.page,
      size: model.size,
      totalPages: model.totalPages,
      totalElements: model.totalElements,
      hasMore: model.hasMore,
    );
  }
}


