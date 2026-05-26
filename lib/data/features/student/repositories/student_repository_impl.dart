import 'package:intl/intl.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_constants.dart';
import '../../../../core/util/cache_manager.dart';
import '../../../../domain/features/student/entities/student.dart';
import '../../../../domain/features/student/entities/student_document.dart';
import '../../../../domain/features/student/entities/student_documents_page.dart';
import '../../../../domain/features/student/entities/student_important_dates.dart';
import '../../../../domain/features/student/entities/student_profile.dart';
import '../../../../domain/features/student/repositories/student_repository.dart';
import '../datasources/student_remote_datasource.dart';
import '../models/student_models.dart';
import '../models/student_document_models.dart';
import '../models/student_pickup_models.dart';
import '../models/student_physician_models.dart';

class StudentRepositoryImpl
    implements StudentRepository, StudentRepositoryWithCache {
  StudentRepositoryImpl(this._remoteDataSource, StorageService storageService)
    : _cacheManager = CacheManager(storageService);

  final StudentRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;
  final Map<String, Set<String>> _studentListCacheKeysBySchool = {};

  /// Raw guardians list for a school (includes email/mobile/code).
  /// Not part of the domain interface; used by UI flows that need full guardian details.
  Future<List<Map<String, dynamic>>> getGuardiansRawForSchool({
    required String schoolCode,
  }) {
    return _remoteDataSource.getGuardiansBySchool(schoolCode: schoolCode);
  }

  String _timeToLabel(dynamic raw) {
    if (raw == null) return '';
    if (raw is String) {
      final s = raw.trim();
      if (s.isEmpty) return '';
      // Common backend formats:
      // - "HH:mm:ss"
      // - "HH:mm"
      final parts = s.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final dt = DateTime(2000, 1, 1, h, m);
        final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final minute = dt.minute.toString().padLeft(2, '0');
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        return '$hour12:$minute $period';
      }
      return s;
    }
    if (raw is Map) {
      final h = int.tryParse('${raw['hour'] ?? 0}') ?? 0;
      final m = int.tryParse('${raw['minute'] ?? 0}') ?? 0;
      final dt = DateTime(2000, 1, 1, h, m);
      final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour12:$minute $period';
    }
    return '';
  }

  Map<String, String> _scheduleByDayFromRegularSchedules(
    List<dynamic> regularSchedules,
  ) {
    final scheduleByDay = <String, String>{};
    for (final item in regularSchedules) {
      if (item is! Map) continue;
      final dow = (item['dayOfWeek'] ?? '').toString().toUpperCase().trim();
      final startLabel = _timeToLabel(item['startTime']);
      final endLabel = _timeToLabel(item['endTime']);
      if (dow.isNotEmpty && startLabel.isNotEmpty && endLabel.isNotEmpty) {
        scheduleByDay[dow] = '$startLabel - $endLabel';
      }
    }
    return scheduleByDay;
  }

  @override
  Future<StudentProfile> getStudentProfile({required String code}) async {
    final model = await _remoteDataSource.getStudentProfile(code);
    return StudentProfile(
      code: model.code.trim(),
      schoolCode: model.schoolCode.trim(),
      fullName: model.fullName.trim().isNotEmpty
          ? model.fullName.trim()
          : model.code.trim(),
      classroomName: model.classroom?.trim(),
      scheduleByDay: _scheduleByDayFromRegularSchedules(model.regularSchedules),
    );
  }

  // Cache key helpers - following the pattern: {feature}_{resource}_cache_{identifier}
  static String _studentListCacheKey(
    String schoolCode, {
    String? status,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    String? search,
    String? code,
    String? firstName,
    String? lastName,
  }) {
    String norm(String? v) => (v ?? '').trim();
    List<String> normList(List<String>? values) {
      final items = (values ?? const <String>[])
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
      items.sort((a, b) => a.toUpperCase().compareTo(b.toUpperCase()));
      return items;
    }

    final statusKey = norm(status).isEmpty
        ? 'ACTIVE'
        : norm(status).toUpperCase();
    final searchKey = norm(search).toLowerCase();
    final codeKey = norm(code).toUpperCase();
    final firstNameKey = norm(firstName).toUpperCase();
    final lastNameKey = norm(lastName).toUpperCase();
    final classroomKey = normList(
      classroomCodes,
    ).map((e) => e.toUpperCase()).join(',');
    final tagKey = normList(tagCodes).map((e) => e.toUpperCase()).join(',');
    final guardianKey = normList(
      guardianCodes,
    ).map((e) => e.toUpperCase()).join(',');

    final identifier = [
      schoolCode,
      'status=$statusKey',
      if (classroomKey.isNotEmpty) 'classrooms=$classroomKey',
      if (tagKey.isNotEmpty) 'tags=$tagKey',
      if (guardianKey.isNotEmpty) 'guardians=$guardianKey',
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

  static String _studentHealthCacheKey(String studentCode) =>
      CacheManager.buildCacheKey(
        feature: 'student',
        resource: 'health',
        identifier: studentCode,
      );

  static String _studentImportantDatesCacheKey(String studentCode) =>
      CacheManager.buildCacheKey(
        feature: 'student',
        resource: 'important_dates',
        identifier: studentCode,
      );

  static String _studentTagsCacheKey(String studentCode) =>
      CacheManager.buildCacheKey(
        feature: 'student',
        resource: 'tags',
        identifier: studentCode,
      );

  static String _studentCountsCacheKey(String schoolCode) =>
      CacheManager.buildCacheKey(
        feature: 'student',
        resource: 'counts',
        identifier: schoolCode.trim(),
      );

  static String _studentTagNamesCacheKey(String schoolCode) =>
      CacheManager.buildCacheKey(
        feature: 'student',
        resource: 'tag_names',
        identifier: schoolCode.trim(),
      );

  static String _studentTagNameCodeMapCacheKey(String schoolCode) =>
      CacheManager.buildCacheKey(
        feature: 'student',
        resource: 'tag_name_code_map',
        identifier: schoolCode.trim(),
      );

  static String _studentGuardianNamesCacheKey(String schoolCode) =>
      CacheManager.buildCacheKey(
        feature: 'student',
        resource: 'guardian_names',
        identifier: schoolCode.trim(),
      );

  static String _studentGuardianNameCodeMapCacheKey(String schoolCode) =>
      CacheManager.buildCacheKey(
        feature: 'student',
        resource: 'guardian_name_code_map',
        identifier: schoolCode.trim(),
      );

  void _registerStudentListCacheKey(String schoolCode, String key) {
    _studentListCacheKeysBySchool
        .putIfAbsent(schoolCode.trim(), () => <String>{})
        .add(key);
  }

  Future<void> _invalidateStudentListAndSummaryCaches({
    required String schoolCode,
    bool includeFilterMetadata = false,
  }) async {
    final school = schoolCode.trim();
    final keys = <String>{
      ...(_studentListCacheKeysBySchool[school] ?? const <String>{}),
      _studentCountsCacheKey(school),
    };
    if (includeFilterMetadata) {
      keys.addAll(<String>{
        _studentTagNamesCacheKey(school),
        _studentTagNameCodeMapCacheKey(school),
        _studentGuardianNamesCacheKey(school),
        _studentGuardianNameCodeMapCacheKey(school),
      });
    }
    if (keys.isEmpty) return;
    await _cacheManager.invalidateCaches(keys.toList(growable: false));
  }

  Future<void> _invalidateAllStudentListAndSummaryCaches() async {
    final keys = <String>{};
    for (final entry in _studentListCacheKeysBySchool.entries) {
      keys.addAll(entry.value);
      keys.add(_studentCountsCacheKey(entry.key));
    }
    if (keys.isEmpty) return;
    await _cacheManager.invalidateCaches(keys.toList(growable: false));
  }

  @override
  Future<Map<String, int>> getStudentCounts({
    required String schoolCode,
  }) async {
    final key = _studentCountsCacheKey(schoolCode);
    final cached = await _cacheManager.loadCache(key);
    if (cached != null) {
      return <String, int>{
        'activeCount': (cached['activeCount'] as num?)?.toInt() ?? 0,
        'upcomingCount': (cached['upcomingCount'] as num?)?.toInt() ?? 0,
        'enrolledCount': (cached['enrolledCount'] as num?)?.toInt() ?? 0,
      };
    }
    final fresh = await _remoteDataSource.getStudentCounts(
      schoolCode: schoolCode,
    );
    await _cacheManager.saveCache(key, {
      'activeCount': fresh['activeCount'] ?? 0,
      'upcomingCount': fresh['upcomingCount'] ?? 0,
      'enrolledCount': fresh['enrolledCount'] ?? 0,
    });
    return fresh;
  }

  static String _studentImmunizationCacheKey(String studentCode) =>
      CacheManager.buildCacheKey(
        feature: 'student',
        resource: 'immunization',
        identifier: studentCode,
      );

  static String _studentPhysicalExamsCacheKey(String studentCode) =>
      CacheManager.buildCacheKey(
        feature: 'student',
        resource: 'physical_exams',
        identifier: studentCode,
      );

  @override
  Future<StudentPage> getStudentPage({
    required String schoolCode,
    String? code,
    String? firstName,
    String? lastName,
    String? status,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    // Backend expects upper-case enum values for StudentStatus (e.g. ACTIVE).
    final normalizedStatus = status?.trim().toUpperCase();

    final studentPageModel = await _remoteDataSource.getStudentPage(
      schoolCode: schoolCode,
      code: code,
      firstName: firstName,
      lastName: lastName,
      status: normalizedStatus,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      guardianCodes: guardianCodes,
      search: search,
      page: page,
      size: size,
    );

    // Cache only the first page for simplicity, keyed by filters.
    if (page == 0) {
      final cacheKey = _studentListCacheKey(
        schoolCode,
        status: status,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        guardianCodes: guardianCodes,
        search: search,
        code: code,
        firstName: firstName,
        lastName: lastName,
      );
      _registerStudentListCacheKey(schoolCode, cacheKey);
      await _cacheManager.saveCache(cacheKey, studentPageModel.toJson());
    }

    return _mapPageModelToEntity(studentPageModel);
  }

  @override
  Future<StudentDocumentsPage?> loadCachedStudentDocuments(
    String studentCode,
  ) async {
    final payload = await _cacheManager.loadCache(
      _studentDocumentsCacheKey(studentCode),
    );
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

  StudentDocumentsPage _mapDocumentsPageModelToEntity(
    StudentDocumentsPageModel model,
  ) {
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
        uploadedBy: m.uploadedBy,
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
    String? assetCode,
    String? uploadedBy,
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
      assetCode: assetCode,
      uploadedBy: uploadedBy,
      notes: notes,
    );

    final response = await _remoteDataSource.addStudentDocument(
      request: request,
    );

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
    String? assetCode,
    String? uploadedBy,
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
      assetCode: assetCode,
      uploadedBy: uploadedBy,
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
    bool forceRefresh = false,
  }) async {
    // Try cache first unless caller explicitly requests a fresh network fetch.
    if (!forceRefresh) {
      final cached = await _cacheManager.loadCache(
        _studentPickupsCacheKey(studentCode),
      );
      if (cached != null) {
        final list = (cached['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(StudentPickupModel.fromJson)
            .toList(growable: false);
        if (list.isNotEmpty) {
          // Older cached payloads may not include pickup code. If so, bypass cache
          // so edit flow can always call PATCH /pickup/{code}.
          final hasMissingCode = list.any((p) => (p.code ?? '').trim().isEmpty);
          if (!hasMissingCode) return list;
        }
      }
    }

    // Fallback to API
    final models = await _remoteDataSource.getStudentPickups(
      studentCode: studentCode,
    );

    // Cache simple list
    await _cacheManager.saveCache(_studentPickupsCacheKey(studentCode), {
      'items': models
          .map(
            (e) => {
              'code': e.code,
              'studentCode': e.studentCode,
              'firstName': e.firstName,
              'lastName': e.lastName,
              'email': e.email,
              'phoneNumber': e.phoneNumber,
              'relation': e.relation,
              'clockPin': e.clockPin,
              'relationshipDescription': e.relationshipDescription,
              'pickupType': e.pickupType,
              'carpoolId': e.carpoolId,
            },
          )
          .toList(),
    });

    return models;
  }

  Future<String> addPickup({
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String relation,
    String? relationshipDescription,
    required String pickupType,
    String? carpoolId,
  }) async {
    final message = await _remoteDataSource.addPickup(
      studentCode: studentCode,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      relation: relation,
      relationshipDescription: relationshipDescription,
      pickupType: pickupType,
      carpoolId: carpoolId,
    );

    await _cacheManager.invalidateCache(_studentPickupsCacheKey(studentCode));

    return message;
  }

  Future<String> updatePickup({
    required String code,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String relation,
    String? clockPin,
    String? relationshipDescription,
    String? pickupType,
    String? carpoolId,
  }) async {
    final body = <String, dynamic>{
      'studentCode': studentCode,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'relation': relation,
      'code': code,
      if (clockPin != null && clockPin.trim().isNotEmpty) 'clockPin': clockPin,
      if (relationshipDescription != null &&
          relationshipDescription.trim().isNotEmpty)
        'relationshipDescription': relationshipDescription.trim(),
      if (pickupType != null && pickupType.trim().isNotEmpty)
        'pickupType': pickupType.trim(),
      if (carpoolId != null && carpoolId.trim().isNotEmpty)
        'carpoolId': carpoolId.trim(),
    };

    final message = await _remoteDataSource.updatePickup(
      code: code,
      body: body,
    );

    await _cacheManager.invalidateCache(_studentPickupsCacheKey(studentCode));

    return message;
  }

  Future<String> deletePickup({
    required String code,
    required String studentCode,
  }) async {
    final message = await _remoteDataSource.deletePickup(code: code);

    await _cacheManager.invalidateCache(_studentPickupsCacheKey(studentCode));

    return message;
  }

  Future<List<StudentPhysicianModel>> getStudentPhysicians({
    required String studentCode,
  }) async {
    // Try cache first
    final cached = await _cacheManager.loadCache(
      _studentPhysiciansCacheKey(studentCode),
    );
    if (cached != null) {
      final list = (cached['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(StudentPhysicianModel.fromJson)
          .toList(growable: false);
      if (list.isNotEmpty) return list;
    }

    // Fallback to API
    final models = await _remoteDataSource.getPhysicians(
      studentCode: studentCode,
    );

    // Cache simple list
    await _cacheManager.saveCache(_studentPhysiciansCacheKey(studentCode), {
      'items': models
          .map(
            (e) => {
              'code': e.code,
              'firstName': e.firstName,
              'lastName': e.lastName,
              'email': e.email,
              'phoneNumber': e.phoneNumber,
              'address': e.address,
              'specialty': e.specialty,
              'notes': e.notes,
              'status': e.status,
            },
          )
          .toList(),
    });

    return models;
  }

  Future<StudentHealthModel> getStudentHealth({
    required String studentCode,
  }) async {
    final cached = await _cacheManager.loadCache(
      _studentHealthCacheKey(studentCode),
    );
    if (cached != null) {
      return StudentHealthModel.fromJson(cached);
    }

    final model = await _remoteDataSource.getStudentHealth(code: studentCode);

    await _cacheManager.saveCache(
      _studentHealthCacheKey(studentCode),
      model.toJson(),
    );

    return model;
  }

  Future<StudentHealthModel> updateStudentHealth({
    required String studentCode,
    required Map<String, dynamic> body,
  }) async {
    final model = await _remoteDataSource.updateStudentHealth(
      code: studentCode,
      body: body,
    );

    await _cacheManager.saveCache(
      _studentHealthCacheKey(studentCode),
      model.toJson(),
    );

    return model;
  }

  Future<List<StudentImmunizationModel>> getStudentImmunizations({
    required String studentCode,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _cacheManager.loadCache(
        _studentImmunizationCacheKey(studentCode),
      );
      if (cached != null) {
        final items = cached['items'];
        if (items is List) {
          return items
              .whereType<Map<String, dynamic>>()
              .map(StudentImmunizationModel.fromJson)
              .toList(growable: false);
        }
      }
    }

    final models = await _remoteDataSource.getStudentImmunizations(
      code: studentCode,
    );

    await _cacheManager.saveCache(_studentImmunizationCacheKey(studentCode), {
      'items': models.map((e) => e.toJson()).toList(),
    });

    return models;
  }

  Future<StudentImmunizationModel> updateStudentImmunizationRecord({
    required String studentCode,
    required StudentImmunizationModel record,
    required DateTime date,
    required String status,
    String? exemptionReason,
  }) async {
    final dateFormatter = DateFormat('yyyy-MM-dd');

    final body = <String, dynamic>{
      'code': record.code,
      'studentCode': record.studentCode,
      'vaccineName': record.vaccineName,
      'vaccineDoseCode': record.vaccineDoseCode,
      'doseNumber': record.doseNumber,
      // For COMPLETED we treat [date] as administeredDate,
      // otherwise as dueDate. Backend enforces detailed rules.
      if (status == 'COMPLETED')
        'administeredDate': dateFormatter.format(date)
      else
        'dueDate': dateFormatter.format(date),
      'status': status,
      if (exemptionReason != null && exemptionReason.trim().isNotEmpty)
        'exemptionReason': exemptionReason.trim(),
    };

    final model = await _remoteDataSource.updateStudentImmunizationRecord(
      studentCode: studentCode,
      recordCode: record.code,
      body: body,
    );

    await _cacheManager.invalidateCache(
      _studentImmunizationCacheKey(studentCode),
    );

    return model;
  }

  Future<List<StudentPhysicalExamModel>> getStudentPhysicalExams({
    required String studentCode,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _cacheManager.loadCache(
        _studentPhysicalExamsCacheKey(studentCode),
      );
      if (cached != null) {
        final items = cached['items'];
        if (items is List) {
          return items
              .whereType<Map<String, dynamic>>()
              .map(StudentPhysicalExamModel.fromJson)
              .toList(growable: false);
        }
      }
    }

    final models = await _remoteDataSource.getStudentPhysicalExams(
      code: studentCode,
    );

    await _cacheManager.saveCache(_studentPhysicalExamsCacheKey(studentCode), {
      'items': models.map((e) => e.toJson()).toList(),
    });

    return models;
  }

  Future<StudentPhysicalExamModel> addStudentPhysicalExam({
    required String studentCode,
    required DateTime examDate,
    required String status,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'examDate': DateFormat('yyyy-MM-dd').format(examDate),
      'status': status,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    final model = await _remoteDataSource.addStudentPhysicalExam(
      code: studentCode,
      body: body,
    );

    await _cacheManager.invalidateCache(
      _studentPhysicalExamsCacheKey(studentCode),
    );

    return model;
  }

  Future<StudentPhysicalExamModel> updateStudentPhysicalExam({
    required String studentCode,
    required String examCode,
    required DateTime examDate,
    required String status,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'examDate': DateFormat('yyyy-MM-dd').format(examDate),
      'status': status,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    final model = await _remoteDataSource.updateStudentPhysicalExam(
      studentCode: studentCode,
      examCode: examCode,
      body: body,
    );

    await _cacheManager.invalidateCache(
      _studentPhysicalExamsCacheKey(studentCode),
    );

    return model;
  }

  @override
  Future<Map<String, String>> getTagNameCodeMapForSchool({
    required String schoolCode,
  }) async {
    final key = _studentTagNameCodeMapCacheKey(schoolCode);
    final cached = await _cacheManager.loadCache(key);
    if (cached != null) {
      final raw = cached['map'] as Map<String, dynamic>?;
      if (raw != null && raw.isNotEmpty) {
        return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    }

    final raw = await _remoteDataSource.getTagsBySchool(schoolCode: schoolCode);

    final map = <String, String>{};

    for (final item in raw) {
      final name = (item['name'] ?? '').toString().trim();
      final code = (item['code'] ?? '').toString().trim();

      if (name.isNotEmpty && code.isNotEmpty) {
        map[name] = code;
      }
    }

    await _cacheManager.saveCache(key, {'map': map});
    return map;
  }

  @override
  Future<List<String>> getStudentCodesForActivityTagFilter({
    required String schoolCode,
    required String classroomCode,
    required List<String> tagCodes,
  }) {
    return _remoteDataSource.postStudentTagsActivityFilter(
      schoolCode: schoolCode,
      classroomCode: classroomCode,
      tagCodes: tagCodes,
    );
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
  }) async {
    final message = await _remoteDataSource.createGuardianUser(
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

    // New guardian added – invalidate guardians cache so next load is fresh.
    await _cacheManager.invalidateCache(_studentGuardiansCacheKey(studentCode));
    await _invalidateStudentListAndSummaryCaches(
      schoolCode: schoolCode,
      includeFilterMetadata: true,
    );

    return message;
  }

  @override
  Future<List<String>> getGuardianNamesForSchool({
    required String schoolCode,
  }) async {
    final key = _studentGuardianNamesCacheKey(schoolCode);
    final cached = await _cacheManager.loadCache(key);
    if (cached != null) {
      final values = (cached['names'] as List<dynamic>? ?? const [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
      if (values.isNotEmpty) return values;
    }

    final raw = await _remoteDataSource.getGuardiansBySchool(
      schoolCode: schoolCode,
    );

    final names = <String>{};

    for (final item in raw) {
      final first = (item['firstName'] ?? '').toString().trim();
      final last = (item['lastName'] ?? '').toString().trim();
      final email = (item['email'] ?? '').toString().trim();

      String display;
      if (first.isEmpty && last.isEmpty) {
        display = email.isNotEmpty ? email : (item['code'] ?? '').toString();
      } else {
        display = '$first $last'.trim();
      }

      if (display.isNotEmpty) {
        names.add(display);
      }
    }

    final sorted = names.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    await _cacheManager.saveCache(key, {'names': sorted});
    return sorted;
  }

  @override
  Future<Map<String, String>> getGuardianNameCodeMapForSchool({
    required String schoolCode,
  }) async {
    final key = _studentGuardianNameCodeMapCacheKey(schoolCode);
    final cached = await _cacheManager.loadCache(key);
    if (cached != null) {
      final raw = cached['map'] as Map<String, dynamic>?;
      if (raw != null && raw.isNotEmpty) {
        return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    }

    final raw = await _remoteDataSource.getGuardiansBySchool(
      schoolCode: schoolCode,
    );

    final map = <String, String>{};

    for (final item in raw) {
      final first = (item['firstName'] ?? '').toString().trim();
      final last = (item['lastName'] ?? '').toString().trim();
      final email = (item['email'] ?? '').toString().trim();
      final code = (item['guardianCode'] ?? item['code'] ?? '')
          .toString()
          .trim();

      String display;
      if (first.isEmpty && last.isEmpty) {
        display = email.isNotEmpty ? email : code;
      } else {
        display = '$first $last'.trim();
      }

      if (display.isNotEmpty && code.isNotEmpty) {
        map[display] = code;
      }
    }

    await _cacheManager.saveCache(key, {'map': map});
    return map;
  }

  @override
  Future<Map<String, dynamic>> getGuardianProfile({
    required String schoolCode,
    required String userCode,
  }) {
    return _remoteDataSource.getGuardianProfile(
      schoolCode: schoolCode,
      userCode: userCode,
    );
  }

  @override
  Future<String> linkExistingGuardian({
    required String guardianCode,
    required String studentCode,
    String? relation,
    String? relationDescription,
  }) async {
    final message = await _remoteDataSource.linkExistingGuardian(
      guardianCode: guardianCode,
      studentCode: studentCode,
      relation: relation,
      relationDescription: relationDescription,
    );

    // Existing guardian linked – invalidate guardians cache so next load is fresh.
    await _cacheManager.invalidateCache(_studentGuardiansCacheKey(studentCode));
    await _invalidateAllStudentListAndSummaryCaches();

    return message;
  }

  @override
  Future<String> updateGuardian({
    required String code,
    required String studentCode,
    required Map<String, dynamic> fields,
  }) async {
    final message = await _remoteDataSource.updateGuardian(
      code: code,
      body: fields,
    );

    await _cacheManager.invalidateCache(_studentGuardiansCacheKey(studentCode));
    await _invalidateAllStudentListAndSummaryCaches();

    return message;
  }

  @override
  Future<String> deleteGuardian({
    required String code,
    required String studentCode,
  }) async {
    final message = await _remoteDataSource.deleteGuardian(
      code: code,
      studentCode: studentCode,
    );

    await _cacheManager.invalidateCache(_studentGuardiansCacheKey(studentCode));
    await _invalidateAllStudentListAndSummaryCaches();

    return message;
  }

  @override
  Future<List<String>> getTagNamesForSchool({
    required String schoolCode,
  }) async {
    final key = _studentTagNamesCacheKey(schoolCode);
    final cached = await _cacheManager.loadCache(key);
    if (cached != null) {
      final values = (cached['names'] as List<dynamic>? ?? const [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
      if (values.isNotEmpty) return values;
    }

    final raw = await _remoteDataSource.getTagsBySchool(schoolCode: schoolCode);

    final names = <String>{};

    for (final item in raw) {
      final name = (item['name'] ?? '').toString().trim();
      if (name.isNotEmpty) {
        names.add(name);
      }
    }

    final sorted = names.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    await _cacheManager.saveCache(key, {'names': sorted});
    return sorted;
  }

  /// Returns tag display names for a specific student using
  /// `GET /api/v1/student-tags/{studentCode}`, with caching.
  Future<List<String>> getStudentTagNames({required String studentCode}) async {
    // Try cache first
    final cached = await _cacheManager.loadCache(
      _studentTagsCacheKey(studentCode),
    );
    if (cached != null) {
      final items = (cached['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>();
      final names = items
          .map((e) => (e['name'] ?? '').toString().trim())
          .where((n) => n.isNotEmpty)
          .toList();
      if (names.isNotEmpty) return names;
    }

    // Fallback to API
    final raw = await _remoteDataSource.getStudentTags(
      studentCode: studentCode,
    );
    final names = raw
        .map((e) => (e['name'] ?? '').toString().trim())
        .where((n) => n.isNotEmpty)
        .toList();

    // Cache raw items for subsequent loads
    await _cacheManager.saveCache(_studentTagsCacheKey(studentCode), {
      'items': raw,
    });

    return names;
  }

  Future<List<StudentGuardianModel>> getStudentGuardians({
    required String studentCode,
    bool forceRefresh = false,
  }) async {
    // Try cache first unless caller explicitly requests a fresh network fetch.
    if (!forceRefresh) {
      final cached = await _cacheManager.loadCache(
        _studentGuardiansCacheKey(studentCode),
      );
      if (cached != null) {
        final list = (cached['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(StudentGuardianModel.fromJson)
            .toList(growable: false);
        if (list.isNotEmpty) return list;
      }
    }

    // Fallback to API
    final raw = await _remoteDataSource.getStudentGuardians(
      studentCode: studentCode,
    );
    final models = raw
        .map(StudentGuardianModel.fromJson)
        .toList(growable: false);

    // Cache simple list
    await _cacheManager.saveCache(_studentGuardiansCacheKey(studentCode), {
      'items': models.map((e) => e.toJson()).toList(),
    });

    return models;
  }

  @override
  Future<StudentPage?> loadCachedStudentPage(
    String schoolCode, {
    String? status,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    String? search,
    String? code,
    String? firstName,
    String? lastName,
  }) async {
    final key = _studentListCacheKey(
      schoolCode,
      status: status,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      guardianCodes: guardianCodes,
      search: search,
      code: code,
      firstName: firstName,
      lastName: lastName,
    );
    _registerStudentListCacheKey(schoolCode, key);
    final payload = await _cacheManager.loadCache(key);
    if (payload == null) return null;

    final model = StudentPageModel.fromCacheJson(payload);
    return _mapPageModelToEntity(model);
  }

  @override
  Future<void> invalidateCachedStudentPage(
    String schoolCode, {
    String? status,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    String? search,
    String? code,
    String? firstName,
    String? lastName,
  }) async {
    await _cacheManager.invalidateCache(
      _studentListCacheKey(
        schoolCode,
        status: status,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        guardianCodes: guardianCodes,
        search: search,
        code: code,
        firstName: firstName,
        lastName: lastName,
      ),
    );
  }

  // Map model to entity
  StudentPage _mapPageModelToEntity(StudentPageModel model) {
    return StudentPage(
      items: model.items
          .map(
            (m) => Student(
              code: m.code,
              firstName: m.firstName,
              lastName: m.lastName,
              status: m.status,
              profileImage: m.profilePhotoUrl,
              profilePhotoAssetCode: m.profilePhotoAssetCode,
              classroom: m.classroom,
              dob: m.dob,
              movementDate: m.movementDate,
              tags: m.tags,
              schedule: m.schedule,
              scheduleByDay: m.scheduleByDay,
            ),
          )
          .toList(),
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
    await _invalidateStudentListAndSummaryCaches(schoolCode: schoolCode);
    return message;
  }

  @override
  Future<String> reactivateStudent({
    required String code,
    required String schoolCode,
  }) async {
    final message = await _remoteDataSource.reactivateStudent(code);
    await _invalidateStudentListAndSummaryCaches(schoolCode: schoolCode);
    return message;
  }

  @override
  Future<String> deleteStudent({
    required String code,
    required String schoolCode,
  }) async {
    final message = await _remoteDataSource.deleteStudent(code);
    await _invalidateStudentListAndSummaryCaches(
      schoolCode: schoolCode,
      includeFilterMetadata: true,
    );
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

    await _invalidateStudentListAndSummaryCaches(schoolCode: schoolCode);

    return Student(
      code: model.code,
      firstName: model.firstName,
      lastName: model.lastName,
      status: model.status,
      classroom: model.classroom,
      dob: model.dob,
      movementDate: model.movementDate,
      tags: model.tags,
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

    final schoolCode = (fields['schoolCode'] ?? '').toString().trim();
    if (schoolCode.isNotEmpty) {
      await _invalidateStudentListAndSummaryCaches(schoolCode: schoolCode);
    } else {
      await _invalidateAllStudentListAndSummaryCaches();
    }

    return message;
  }

  @override
  Future<String> updateStudentAddress({
    required String studentCode,
    required Map<String, dynamic> fields,
  }) async {
    final message = await _remoteDataSource.updateStudentAddress(
      studentCode: studentCode,
      body: fields,
    );

    final schoolCode = (fields['schoolCode'] ?? '').toString().trim();
    if (schoolCode.isNotEmpty) {
      await _invalidateStudentListAndSummaryCaches(schoolCode: schoolCode);
    } else {
      await _invalidateAllStudentListAndSummaryCaches();
    }

    return message;
  }

  @override
  Future<String> updateStudentSiblings({
    required String studentCode,
    required List<String> siblingCodes,
  }) async {
    final message = await _remoteDataSource.updateStudentSiblings(
      studentCode: studentCode,
      siblingCodes: siblingCodes,
    );

    await _invalidateAllStudentListAndSummaryCaches();

    return message;
  }

  @override
  Future<String> updateStudentTags({
    required String studentCode,
    required String schoolCode,
    required List<String> tagCodes,
  }) async {
    final message = await _remoteDataSource.updateStudentTags(
      studentCode: studentCode,
      schoolCode: schoolCode,
      tagCodes: tagCodes,
    );

    // Invalidate per-student tags cache and filter metadata caches.
    await _cacheManager.invalidateCache(_studentTagsCacheKey(studentCode));
    await _invalidateStudentListAndSummaryCaches(
      schoolCode: schoolCode,
      includeFilterMetadata: true,
    );

    return message;
  }

  @override
  Future<StudentImportantDates> getStudentImportantDates({
    required String studentCode,
  }) async {
    // Try cache first
    final cached = await _cacheManager.loadCache(
      _studentImportantDatesCacheKey(studentCode),
    );

    StudentImportantDatesModel model;

    if (cached != null) {
      final raw = cached['dates'] as Map<String, dynamic>?;
      model = StudentImportantDatesModel.fromJson(raw);
    } else {
      // Fallback to API
      model = await _remoteDataSource.getStudentImportantDates(
        code: studentCode,
      );

      // Cache the raw model for subsequent loads
      await _cacheManager.saveCache(
        _studentImportantDatesCacheKey(studentCode),
        {'dates': model.toJson()},
      );
    }

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

    // Invalidate cached important-dates so next load is fresh.
    await _cacheManager.invalidateCache(
      _studentImportantDatesCacheKey(studentCode),
    );

    return message;
  }
}
