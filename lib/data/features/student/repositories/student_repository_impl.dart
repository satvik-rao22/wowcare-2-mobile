import 'package:intl/intl.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_constants.dart';
import '../../../../core/util/cache_manager.dart';
import '../../../../domain/features/student/entities/student.dart';
import '../../../../domain/features/student/entities/student_document.dart';
import '../../../../domain/features/student/entities/student_documents_page.dart';
import '../../../../domain/features/student/entities/student_important_dates.dart';
import '../../../../domain/features/student/repositories/student_repository.dart';
import '../datasources/student_remote_datasource.dart';
import '../models/student_models.dart';
import '../models/student_document_models.dart';
import '../models/student_pickup_models.dart';
import '../models/student_physician_models.dart';

class StudentRepositoryImpl implements StudentRepository, StudentRepositoryWithCache {
  StudentRepositoryImpl(this._remoteDataSource, StorageService storageService)
      : _cacheManager = CacheManager(storageService);

  final StudentRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  // Cache key helpers - following the pattern: {feature}_{resource}_cache_{identifier}
  static String _studentListCacheKey(
    String schoolCode, {
    String? status,
    String? search,
    String? code,
    String? firstName,
    String? lastName,
  }) {
    String norm(String? v) => (v ?? '').trim();

    final statusKey = norm(status).isEmpty ? 'ACTIVE' : norm(status).toUpperCase();
    final searchKey = norm(search).toLowerCase();
    final codeKey = norm(code).toUpperCase();
    final firstNameKey = norm(firstName).toUpperCase();
    final lastNameKey = norm(lastName).toUpperCase();

    final identifier = [
      schoolCode,
      'status=$statusKey',
      if (searchKey.isNotEmpty) 'search=$searchKey',
      if (codeKey.isNotEmpty) 'code=$codeKey',
      if (firstNameKey.isNotEmpty) 'firstName=$firstNameKey',
      if (lastNameKey.isNotEmpty) 'lastName=$lastNameKey',
    ].join('|');

    return CacheManager.buildCacheKey(
      feature: 'student',
      resource: 'list',
      identifier: identifier,
    );
  }

  static String _studentGuardiansCacheKey(String studentCode) =>
      CacheManager.buildCacheKey(
        feature: 'student',
        resource: 'guardians',
        identifier: studentCode,
      );

  static String _studentPickupsCacheKey(String studentCode) =>
      CacheManager.buildCacheKey(
        feature: 'student',
        resource: 'pickups',
        identifier: studentCode,
      );

  static String _studentDocumentsCacheKey(String studentCode) =>
      CacheManager.buildCacheKey(
        feature: 'student',
        resource: 'documents',
        identifier: studentCode,
      );

  static String _studentPhysiciansCacheKey(String studentCode) =>
      CacheManager.buildCacheKey(
        feature: 'student',
        resource: 'physicians',
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

    // Cache only the first page for simplicity, keyed by filters.
    if (page == 0) {
      await _cacheManager.saveCache(
        _studentListCacheKey(
          schoolCode,
          status: status,
          search: search,
          code: code,
          firstName: firstName,
          lastName: lastName,
        ),
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
  Future<String> updateStudentDocument({
    required String documentUuid,
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

    final response = await _remoteDataSource.updateStudentDocument(
      code: documentUuid,
      request: request,
    );

    await _cacheManager.invalidateCache(_studentDocumentsCacheKey(studentCode));

    return response.message;
  }

  @override
  Future<String> deleteStudentDocument({
    required String documentUuid,
    required String studentCode,
  }) async {
    final message = await _remoteDataSource.deleteStudentDocument(
      code: documentUuid,
    );

    await _cacheManager.invalidateCache(_studentDocumentsCacheKey(studentCode));

    return message;
  }

  Future<List<StudentPickupModel>> getStudentPickups({
    required String studentCode,
  }) async {
    // Try cache first
    final cached =
        await _cacheManager.loadCache(_studentPickupsCacheKey(studentCode));
    if (cached != null) {
      final list = (cached['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(StudentPickupModel.fromJson)
          .toList(growable: false);
      if (list.isNotEmpty) return list;
    }

    // Fallback to API
    final models =
        await _remoteDataSource.getStudentPickups(studentCode: studentCode);

    // Cache simple list
    await _cacheManager.saveCache(
      _studentPickupsCacheKey(studentCode),
      {
        'items': models
            .map((e) => {
                  'studentCode': e.studentCode,
                  'firstName': e.firstName,
                  'lastName': e.lastName,
                  'email': e.email,
                  'phoneNumber': e.phoneNumber,
                  'relation': e.relation,
                })
            .toList(),
      },
    );

    return models;
  }

  Future<String> addPickup({
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String relation,
  }) async {
    final message = await _remoteDataSource.addPickup(
      studentCode: studentCode,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      relation: relation,
    );

    await _cacheManager.invalidateCache(_studentPickupsCacheKey(studentCode));

    return message;
  }

  Future<List<StudentPhysicianModel>> getStudentPhysicians({
    required String studentCode,
  }) async {
    // Try cache first
    final cached =
        await _cacheManager.loadCache(_studentPhysiciansCacheKey(studentCode));
    if (cached != null) {
      final list = (cached['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(StudentPhysicianModel.fromJson)
          .toList(growable: false);
      if (list.isNotEmpty) return list;
    }

    // Fallback to API
    final models =
        await _remoteDataSource.getPhysicians(studentCode: studentCode);

    // Cache simple list
    await _cacheManager.saveCache(
      _studentPhysiciansCacheKey(studentCode),
      {
        'items': models
            .map((e) => {
                  'code': e.code,
                  'firstName': e.firstName,
                  'lastName': e.lastName,
                  'email': e.email,
                  'phoneNumber': e.phoneNumber,
                  'address': e.address,
                  'specialty': e.specialty,
                  'notes': e.notes,
                  'status': e.status,
                })
            .toList(),
      },
    );

    return models;
  }

  Future<StudentPhysicianModel> addPhysician({
    required String schoolCode,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String address,
    String? specialty,
    String? notes,
  }) async {
    final model = await _remoteDataSource.addPhysician(
      schoolCode: schoolCode,
      studentCode: studentCode,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      address: address,
      specialty: specialty,
      notes: notes,
    );

    await _cacheManager.invalidateCache(
      _studentPhysiciansCacheKey(studentCode),
    );

    return model;
  }

  Future<StudentPhysicianModel> updatePhysician({
    required String code,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String address,
    String? specialty,
    String? notes,
  }) async {
    final model = await _remoteDataSource.updatePhysician(
      code: code,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      address: address,
      specialty: specialty,
      notes: notes,
    );

    await _cacheManager.invalidateCache(
      _studentPhysiciansCacheKey(studentCode),
    );

    return model;
  }

  Future<String> deletePhysician({
    required String code,
    required String studentCode,
  }) async {
    final message = await _remoteDataSource.deletePhysician(code);

    await _cacheManager.invalidateCache(
      _studentPhysiciansCacheKey(studentCode),
    );

    return message;
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

  Future<List<StudentGuardianModel>> getStudentGuardians({
    required String studentCode,
  }) async {
    // Try cache first
    final cached =
        await _cacheManager.loadCache(_studentGuardiansCacheKey(studentCode));
    if (cached != null) {
      final list = (cached['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(StudentGuardianModel.fromJson)
          .toList(growable: false);
      if (list.isNotEmpty) return list;
    }

    // Fallback to API
    final raw = await _remoteDataSource.getStudentGuardians(
      studentCode: studentCode,
    );
    final models = raw
        .map(StudentGuardianModel.fromJson)
        .toList(growable: false);

    // Cache simple list
    await _cacheManager.saveCache(
      _studentGuardiansCacheKey(studentCode),
      {
        'items': models.map((e) => e.toJson()).toList(),
      },
    );

    return models;
  }

  @override
  Future<StudentPage?> loadCachedStudentPage(
    String schoolCode, {
    String? status,
    String? search,
    String? code,
    String? firstName,
    String? lastName,
  }) async {
    final payload = await _cacheManager.loadCache(
      _studentListCacheKey(
        schoolCode,
        status: status,
        search: search,
        code: code,
        firstName: firstName,
        lastName: lastName,
      ),
    );
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

  @override
  Future<StudentImportantDates> getStudentImportantDates({
    required String studentCode,
  }) async {
    final model = await _remoteDataSource.getStudentImportantDates(
      code: studentCode,
    );

    DateTime? _parse(String? value) {
      if (value == null || value.isEmpty) return null;
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }

    return StudentImportantDates(
      enrollDate: _parse(model.enrollDate),
      schoolStartDate: _parse(model.schoolStartDate),
      currentClassroomStartDate: _parse(model.currentClassroomStartDate),
      upcomingMoveDate: _parse(model.upcomingMoveDate),
      schoolLeavingDate: _parse(model.schoolLeavingDate),
    );
  }

  @override
  Future<String> updateStudentImportantDates({
    required String studentCode,
    required StudentImportantDates dates,
  }) async {
    final dateFormatter = DateFormat('yyyy-MM-dd');

    String? _fmt(DateTime? value) =>
        value == null ? null : dateFormatter.format(value);

    final model = StudentImportantDatesModel(
      enrollDate: _fmt(dates.enrollDate),
      schoolStartDate: _fmt(dates.schoolStartDate),
      currentClassroomStartDate: _fmt(dates.currentClassroomStartDate),
      upcomingMoveDate: _fmt(dates.upcomingMoveDate),
      schoolLeavingDate: _fmt(dates.schoolLeavingDate),
    );

    final message = await _remoteDataSource.updateStudentImportantDates(
      code: studentCode,
      dates: model,
    );

    return message;
  }
}

