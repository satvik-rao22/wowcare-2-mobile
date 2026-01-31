import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/cache_manager.dart';
import '../../../../domain/features/staff/entities/staff_member.dart';
import '../../../../domain/features/staff/entities/staff_document.dart';
import '../../../../domain/features/staff/entities/staff_documents_page.dart';
import '../../../../domain/features/staff/entities/staff_profile.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../datasources/staff_remote_datasource.dart';
import '../models/staff_models.dart';
import '../models/staff_document_models.dart';
import '../models/staff_important_dates_models.dart';

class StaffRepositoryImpl implements StaffRepository, StaffRepositoryWithCache {
  StaffRepositoryImpl(this._remoteDataSource, StorageService storageService)
      : _cacheManager = CacheManager(storageService);

  final StaffRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  // Cache key helpers - following the pattern: {feature}_{resource}_cache_{identifier}
  static String _staffListCacheKey(String schoolCode) =>
      CacheManager.buildCacheKey(
        feature: 'staff',
        resource: 'list',
        identifier: schoolCode,
      );
  static String _staffDocumentsCacheKey(String staffCode) =>
      CacheManager.buildCacheKey(
        feature: 'staff',
        resource: 'documents',
        identifier: staffCode,
      );
  static String _staffProfileCacheKey(String staffCode) =>
      CacheManager.buildCacheKey(
        feature: 'staff',
        resource: 'profile',
        identifier: staffCode,
      );

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

    // IMPORTANT: Invalidate cache after any mutation (add/edit/delete)
    // This ensures the UI will fetch fresh data on next refresh
    await _cacheManager.invalidateCache(_staffDocumentsCacheKey(staffCode));

    return response.message;
  }

  // TODO: When implementing updateStaffDocument, add cache invalidation:
  // await _cacheManager.invalidateCache(_staffDocumentsCacheKey(staffCode));
  
  // TODO: When implementing deleteStaffDocument, add cache invalidation:
  // await _cacheManager.invalidateCache(_staffDocumentsCacheKey(staffCode));

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

  @override
  Future<StaffProfile> getStaffProfile({
    required String staffCode,
  }) async {
    final profileModel = await _remoteDataSource.getStaffProfile(
      staffCode: staffCode,
    );

    // Cache the profile
    await _cacheManager.saveCache(
      _staffProfileCacheKey(staffCode),
      profileModel.toJson(),
    );

    return _mapProfileModelToEntity(profileModel);
  }

  @override
  Future<StaffProfile?> loadCachedStaffProfile(String staffCode) async {
    final payload = await _cacheManager.loadCache(_staffProfileCacheKey(staffCode));
    if (payload == null) return null;

    final model = StaffProfileModel.fromCacheJson(payload);
    return _mapProfileModelToEntity(model);
  }

  StaffProfile _mapProfileModelToEntity(StaffProfileModel model) {
    return StaffProfile(
      staffCode: model.staffCode,
      userCode: model.userCode,
      organizationCode: model.organizationCode,
      schoolCode: model.schoolCode,
      firstName: model.firstName,
      lastName: model.lastName,
      fullName: model.fullName,
      email: model.email,
      phoneNumber: model.phoneNumber,
      profilePhotoUrl: model.profilePhotoUrl,
      birthDate: model.birthDate,
      staffType: model.staffType,
      status: model.status,
      designation: model.designation,
      jobTag: model.jobTag,
      clockPin: model.clockPin,
      primaryClassroomCode: model.primaryClassroomCode,
      allowedClassroomCodes: model.allowedClassroomCodes,
      address: StaffProfileAddress(
        street: model.address.street,
        line2: model.address.line2,
        city: model.address.city,
        state: model.address.state,
        zipCode: model.address.zipCode,
        country: model.address.country,
      ),
      workSchedules: model.workSchedules
          .map(
            (m) => StaffProfileWorkSchedule(
              dayOfWeek: m.dayOfWeek,
              workStartTime: StaffProfileTime(
                hour: m.workStartTime.hour,
                minute: m.workStartTime.minute,
                second: m.workStartTime.second,
                nano: m.workStartTime.nano,
              ),
              workEndTime: StaffProfileTime(
                hour: m.workEndTime.hour,
                minute: m.workEndTime.minute,
                second: m.workEndTime.second,
                nano: m.workEndTime.nano,
              ),
            ),
          )
          .toList(),
      breakSchedules: model.breakSchedules
          .map(
            (m) => StaffProfileBreakSchedule(
              dayOfWeek: m.dayOfWeek,
              breakType: m.breakType,
              breakStartTime: StaffProfileTime(
                hour: m.breakStartTime.hour,
                minute: m.breakStartTime.minute,
                second: m.breakStartTime.second,
                nano: m.breakStartTime.nano,
              ),
              breakEndTime: StaffProfileTime(
                hour: m.breakEndTime.hour,
                minute: m.breakEndTime.minute,
                second: m.breakEndTime.second,
                nano: m.breakEndTime.nano,
              ),
            ),
          )
          .toList(),
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  @override
  Future<String> updateImportantDates({
    required String staffCode,
    required List<Map<String, String>> dates,
  }) async {
    final dateRequests = dates
        .map(
          (date) => ImportantDateRequestModel(
            importantDateType: date['importantDateType']!,
            dueDate: date['dueDate']!,
            completedDate: date['completedDate'],
          ),
        )
        .toList();

    final response = await _remoteDataSource.updateImportantDates(
      staffCode: staffCode,
      dates: dateRequests,
    );

    // Invalidate profile cache since dates are part of profile
    await _cacheManager.invalidateCache(_staffProfileCacheKey(staffCode));

    return response.message;
  }
}


