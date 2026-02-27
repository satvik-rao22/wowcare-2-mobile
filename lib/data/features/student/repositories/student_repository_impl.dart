import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_constants.dart';
import '../../../../core/util/cache_manager.dart';
import '../../../../domain/features/student/entities/student.dart';
import '../../../../domain/features/student/entities/student_document.dart';
import '../../../../domain/features/student/entities/student_documents_page.dart';
import '../../../../domain/features/student/repositories/student_repository.dart';
import '../datasources/student_remote_datasource.dart';
import '../models/student_models.dart';
import '../models/student_document_models.dart';

class StudentRepositoryImpl implements StudentRepository, StudentRepositoryWithCache {
  StudentRepositoryImpl(this._remoteDataSource, StorageService storageService)
      : _cacheManager = CacheManager(storageService);

  final StudentRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  // Cache key helpers - following the pattern: {feature}_{resource}_cache_{identifier}
  static String _studentListCacheKey(String schoolCode) =>
      CacheManager.buildCacheKey(
        feature: 'student',
        resource: 'list',
        identifier: schoolCode,
      );

  static String _studentDocumentsCacheKey(String studentCode) =>
      CacheManager.buildCacheKey(
        feature: 'student',
        resource: 'documents',
        identifier: studentCode,
      );

  @override
  Future<StudentPage> getStudentPage({
    required String schoolCode,
    String? code,
    String? firstName,
    String? lastName,
    String? status,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final studentPageModel = await _remoteDataSource.getStudentPage(
      schoolCode: schoolCode,
      code: code,
      firstName: firstName,
      lastName: lastName,
      status: status,
      search: search,
      page: page,
      size: size,
    );

    // Cache only the first page for simplicity
    if (page == 0) {
      await _cacheManager.saveCache(
        _studentListCacheKey(schoolCode),
        studentPageModel.toJson(),
      );
    }

    return _mapPageModelToEntity(studentPageModel);
  }

  @override
  Future<StudentDocumentsPage?> loadCachedStudentDocuments(String studentCode) async {
    final payload = await _cacheManager.loadCache(_studentDocumentsCacheKey(studentCode));
    if (payload == null) return null;

    final model = StudentDocumentsPageModel.fromCacheJson(payload);
    return _mapDocumentsPageModelToEntity(model);
  }

  @override
  Future<StudentDocumentsPage> getStudentDocuments({
    required String studentCode,
    int page = 0,
    int size = 10,
    bool? expiredOnly,
  }) async {
    final documentsPageModel = await _remoteDataSource.getStudentDocuments(
      ownerId: studentCode,
      page: page,
      size: size,
      expiredOnly: expiredOnly,
    );

    if (page == 0) {
      await _cacheManager.saveCache(
        _studentDocumentsCacheKey(studentCode),
        documentsPageModel.toJson(),
      );
    }

    return _mapDocumentsPageModelToEntity(documentsPageModel);
  }

  StudentDocumentsPage _mapDocumentsPageModelToEntity(StudentDocumentsPageModel model) {
    final items = model.items.map((m) {
      final storagePath = m.storagePath;
      final documentUrl = storagePath.startsWith('http')
          ? storagePath
          : '${ApiConstants.studentBaseUrl}${storagePath.startsWith('/') ? '' : '/'}$storagePath';
      return StudentDocument(
        documentUuid: m.code,
        documentType: m.type,
        documentName: m.name,
        documentUrl: documentUrl,
        documentSizeKb: m.size > 0 ? (m.size / 1024).ceil() : 0,
        mimeType: m.mimeType,
        expiryDate: m.expiryDate,
        expired: false,
        createdAt: m.createdAt,
      );
    }).toList();

    return StudentDocumentsPage(
      items: items,
      page: model.page,
      size: model.size,
      totalPages: model.totalPages,
      totalElements: model.totalElements,
      hasMore: model.hasMore,
    );
  }

  @override
  Future<String> addStudentDocument({
    required String studentCode,
    required String name,
    required String type,
    required String expiryDate,
    required String storagePath,
    required String mimeType,
    required int size,
    String? notes,
  }) async {
    final request = StudentDocumentRequestModel(
      name: name,
      type: type,
      expiryDate: expiryDate,
      storagePath: storagePath,
      mimeType: mimeType,
      size: size,
      ownerType: 'STUDENT',
      ownerId: studentCode,
      notes: notes,
    );

    final response = await _remoteDataSource.addStudentDocument(request: request);

    await _cacheManager.invalidateCache(_studentDocumentsCacheKey(studentCode));

    return response.message;
  }

  @override
  Future<String> createGuardianUser({
    required String schoolCode,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String relationToStudent,
    required bool primaryContact,
    required bool legalCustody,
    String? profilePhotoUrl,
    String? userCode,
    String? organizationCode,
  }) {
    return _remoteDataSource.createGuardianUser(
      schoolCode: schoolCode,
      studentCode: studentCode,
      firstName: firstName,
      lastName: lastName,
      email: email,
      mobile: mobile,
      relationToStudent: relationToStudent,
      primaryContact: primaryContact,
      legalCustody: legalCustody,
      profilePhotoUrl: profilePhotoUrl,
      userCode: userCode,
      organizationCode: organizationCode,
    );
  }

  @override
  Future<StudentPage?> loadCachedStudentPage(String schoolCode) async {
    final payload = await _cacheManager.loadCache(_studentListCacheKey(schoolCode));
    if (payload == null) return null;

    final model = StudentPageModel.fromCacheJson(payload);
    return _mapPageModelToEntity(model);
  }

  // Map model to entity
  StudentPage _mapPageModelToEntity(StudentPageModel model) {
    return StudentPage(
      items: model.items.map((m) => Student(
        code: m.code,
        firstName: m.firstName,
        lastName: m.lastName,
        status: m.status,
        classroom: m.classroom,
        dob: m.dob,
        movementDate: m.movementDate,
      )).toList(),
      page: model.page,
      size: model.size,
      totalPages: model.totalPages,
      totalElements: model.totalElements,
      hasMore: model.hasMore,
    );
  }

  @override
  Future<String> deactivateStudent({
    required String code,
    required String schoolCode,
  }) async {
    final message = await _remoteDataSource.deactivateStudent(code);
    // Invalidate student list cache since status change affects listing.
    await _cacheManager.invalidateCache(_studentListCacheKey(schoolCode));
    return message;
  }

  @override
  Future<String> reactivateStudent({
    required String code,
    required String schoolCode,
  }) async {
    final message = await _remoteDataSource.reactivateStudent(code);
    // Invalidate student list cache since status change affects listing.
    await _cacheManager.invalidateCache(_studentListCacheKey(schoolCode));
    return message;
  }

  @override
  Future<Student> createStudent({
    required String schoolCode,
    required String firstName,
    required String lastName,
    required String status,
    required String classroom,
    String? profilePhotoUrl,
    DateTime? dob,
    DateTime? schoolStartDate,
  }) async {
    final model = await _remoteDataSource.createStudent(
      schoolCode: schoolCode,
      firstName: firstName,
      lastName: lastName,
      status: status,
      classroom: classroom,
      profilePhotoUrl: profilePhotoUrl,
      dob: dob,
      schoolStartDate: schoolStartDate,
    );

    // New student created – invalidate first-page cache so next load/refresh sees it.
    await _cacheManager.invalidateCache(_studentListCacheKey(schoolCode));

    return Student(
      code: model.code,
      firstName: model.firstName,
      lastName: model.lastName,
      status: model.status,
      classroom: model.classroom,
      dob: model.dob,
      movementDate: model.movementDate,
    );
  }

  @override
  Future<String> updateStudentProfile({
    required String code,
    required Map<String, dynamic> fields,
  }) async {
    final message = await _remoteDataSource.updateStudentProfile(
      code: code,
      body: fields,
    );

    // Invalidate cached profile so subsequent loads use fresh data.
    // Note: We don't have a profile cache key yet, but we should invalidate list cache
    // since profile changes might affect list display.
    // TODO: Add profile cache key if needed
    // await _cacheManager.invalidateCache(_studentProfileCacheKey(code));

    return message;
  }
}

