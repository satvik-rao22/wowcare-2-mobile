import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/cache_manager.dart';
import '../../../../domain/features/staff/entities/staff_member.dart';
import '../../../../domain/features/staff/entities/staff_document.dart';
import '../../../../domain/features/staff/entities/staff_documents_page.dart';
import '../../../../domain/features/staff/entities/staff_profile.dart';
import '../../../../domain/features/staff/entities/create_school_user_result.dart';
import '../../../../domain/features/staff/entities/staff_count.dart';
import '../../../../domain/features/staff/entities/school_user.dart';
import '../../../../domain/features/staff/entities/school_regular_schedule_day.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../datasources/staff_remote_datasource.dart';
import '../models/staff_models.dart';
import '../models/staff_document_models.dart';
import '../models/staff_important_dates_models.dart';
import '../models/school_user_models.dart';

class StaffRepositoryImpl implements StaffRepository, StaffRepositoryWithCache {
  StaffRepositoryImpl(this._remoteDataSource, StorageService storageService)
      : _cacheManager = CacheManager(storageService);

  final StaffRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  final Map<String, Future<StaffProfile>> _inflightStaffProfileByKey = {};
  final Map<String, Future<StaffPage>> _inflightStaffPageByKey = {};

  @override
  void clearSessionVolatileCaches() {
    _inflightStaffProfileByKey.clear();
    _inflightStaffPageByKey.clear();
  }

  // Cache key helpers - following the pattern: {feature}_{resource}_cache_{identifier}
  static String _staffListCacheKey(
    String schoolCode, {
    String? status,
    String? designation,
    String? search,
    List<String>? primaryClassroomCodes,
    List<String>? classCodes,
    String? sortBy,
  }) {
    // Make cached staff list depend on filters.
    String norm(String? v) => (v ?? '').trim().toUpperCase();

    final statusKey = norm(status).isEmpty ? 'ACTIVE' : norm(status);
    final designationKey = norm(designation);
    final searchKey = (search ?? '').trim().toLowerCase();
    final sortKey = (sortBy ?? 'desc').trim().toLowerCase();
    final primaryKey = (primaryClassroomCodes ?? [])
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList()
      ..sort();
    final classKey = (classCodes ?? [])
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList()
      ..sort();

    final identifier = [
      schoolCode,
      'status=$statusKey',
      if (designationKey.isNotEmpty) 'designation=$designationKey',
      if (searchKey.isNotEmpty) 'search=$searchKey',
      if (primaryKey.isNotEmpty) 'primaryClassrooms=${primaryKey.join(',')}',
      if (classKey.isNotEmpty) 'classCodes=${classKey.join(',')}',
      'sort=$sortKey',
    ].join('|');

    return CacheManager.buildCacheKey(
      feature: 'staff',
      resource: 'list',
      identifier: identifier,
    );
  }
  static String _staffDocumentsCacheKey(String staffCode) =>
      CacheManager.buildCacheKey(
        feature: 'staff',
        resource: 'documents',
        identifier: staffCode,
      );
  /// [forEditStaff] matches [getStaffProfile] — scoped vs `my-profile` payloads can differ.
  static String _staffProfileCacheKey(
    String staffCode, {
    required bool forEditStaff,
  }) =>
      CacheManager.buildCacheKey(
        feature: 'staff',
        resource: 'profile',
        identifier:
            '${staffCode.trim().isEmpty ? 'unknown' : staffCode.trim()}|${forEditStaff ? 'byCode' : 'my'}',
      );

  Future<void> _invalidateStaffProfileCaches(String staffCode) async {
    final c = staffCode.trim();
    if (c.isEmpty) return;
    await _cacheManager.invalidateCaches([
      _staffProfileCacheKey(c, forEditStaff: false),
      _staffProfileCacheKey(c, forEditStaff: true),
    ]);
  }
  static String _staffImportantDatesCacheKey(String staffCode) =>
      CacheManager.buildCacheKey(
        feature: 'staff',
        resource: 'important_dates',
        identifier: staffCode,
      );

  @override
  Future<StaffCount> getStaffCount({
    required String organizationCode,
    required String schoolCode,
  }) async {
    final model = await _remoteDataSource.getStaffCount(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
    );
    return StaffCount(
      total: model.total,
      active: model.active,
      upcoming: model.upcoming,
    );
  }

  @override
  Future<List<StaffMember>> getStaffListBySchool({
    required String schoolCode,
  }) async {
    final models = await _remoteDataSource.getStaffListBySchool(
      schoolCode: schoolCode,
    );
    return models
        .map((m) => StaffMember(
              code: m.staffCode,
              name: m.fullName,
              primaryClassroomCode: '',
              allowedClassroomCodes: const [],
              designation: '',
              phoneNumber: '',
              status: 'ACTIVE',
              email: '',
            ))
        .toList();
  }

  @override
  Future<StaffPage> getStaffPage({
    required String organizationCode,
    required String schoolCode,
    String? code,
    int page = 0,
    int size = 10,
    String? status,
    String? designation,
    String? search,
    List<String>? primaryClassroomCodes,
    List<String>? classCodes,
    String? sortBy,
  }) async {
    final listKey = _staffListCacheKey(
      schoolCode,
      status: status,
      designation: designation,
      search: search,
      primaryClassroomCodes: primaryClassroomCodes,
      classCodes: classCodes,
      sortBy: sortBy,
    );

    Future<StaffPage> fetchRemote() async {
      final staffPageModel = await _remoteDataSource.getStaffPage(
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        code: code,
        page: page,
        size: size,
        status: status,
        designation: designation,
        search: search,
        primaryClassroomCodes: primaryClassroomCodes,
        classCodes: classCodes,
        sortBy: sortBy,
      );

      if (page == 0) {
        await _cacheManager.saveCache(
          listKey,
          staffPageModel.toJson(),
        );
      }

      return _mapPageModelToEntity(staffPageModel);
    }

    if (page == 0 && (code ?? '').trim().isEmpty) {
      try {
        final cached = await loadCachedStaffPage(
          schoolCode,
          status: status,
          designation: designation,
          search: search,
          primaryClassroomCodes: primaryClassroomCodes,
          classCodes: classCodes,
          sortBy: sortBy,
        );
        if (cached != null) {
          return cached;
        }
      } catch (_) {}
    }

    final future = _inflightStaffPageByKey.putIfAbsent(listKey, () {
      final f = fetchRemote();
      f.whenComplete(() => _inflightStaffPageByKey.remove(listKey));
      return f;
    });
    return await future;
  }

  @override
  Future<StaffPage?> loadCachedStaffPage(
    String schoolCode, {
    String? status,
    String? designation,
    String? search,
    List<String>? primaryClassroomCodes,
    List<String>? classCodes,
    String? sortBy,
  }) async {
    final payload = await _cacheManager.loadCache(
      _staffListCacheKey(
        schoolCode,
        status: status,
        designation: designation,
        search: search,
        primaryClassroomCodes: primaryClassroomCodes,
        classCodes: classCodes,
        sortBy: sortBy,
      ),
    );
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
    String _formatTimeOfDay(int hour, int minute) {
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final displayMinute = minute.toString().padLeft(2, '0');
      return '$displayHour:$displayMinute$period';
    }

    String _formatRange(int startHour, int startMinute, int endHour, int endMinute) {
      final start = _formatTimeOfDay(startHour, startMinute);
      final end = _formatTimeOfDay(endHour, endMinute);
      return '$start - $end';
    }

    final items = model.items.map((m) {
      final workByDay = <String, String>{};
      for (final ws in m.workSchedules) {
        if (ws.dayOfWeek.isEmpty) continue;
        workByDay[ws.dayOfWeek] = _formatRange(
          ws.workStartTime.hour,
          ws.workStartTime.minute,
          ws.workEndTime.hour,
          ws.workEndTime.minute,
        );
      }

      final breakByDay = <String, String>{};
      for (final bs in m.breakSchedules) {
        if (bs.dayOfWeek.isEmpty) continue;
        breakByDay[bs.dayOfWeek] = _formatRange(
          bs.breakStartTime.hour,
          bs.breakStartTime.minute,
          bs.breakEndTime.hour,
          bs.breakEndTime.minute,
        );
      }

      return StaffMember(
        code: m.code,
        name: m.name,
        primaryClassroomCode: m.primaryClassroomCode,
        allowedClassroomCodes: m.allowedClassroomCodes,
        designation: m.designation,
        phoneNumber: m.phoneNumber,
        status: m.status,
        email: m.email,
        workScheduleByDay: workByDay,
        breakScheduleByDay: breakByDay,
      );
    }).toList();

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
      assetCode: document.assetCode,
      expiryDate: document.expiryDate ?? '',
      documentNotes: document.documentNotes,
      // Backend expects "updatedBy" in body; use staffCode as a stable identifier.
      updatedBy: staffCode,
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

  @override
  Future<String> updateStaffDocument({
    required String documentUuid,
    required StaffDocument document,
    required String staffCode, // Required for cache invalidation
  }) async {
    final request = StaffDocumentRequestModel(
      documentType: document.documentType,
      documentName: document.documentName,
      documentUrl: document.documentUrl,
      documentSizeKb: document.documentSizeKb,
      mimeType: document.mimeType,
      assetCode: document.assetCode,
      expiryDate: document.expiryDate ?? '',
      documentNotes: document.documentNotes,
      updatedBy: staffCode,
    );

    final response = await _remoteDataSource.updateStaffDocument(
      documentUuid: documentUuid,
      request: request,
    );

    // Invalidate cache after update
    await _cacheManager.invalidateCache(_staffDocumentsCacheKey(staffCode));

    return response.message;
  }

  @override
  Future<String> deleteStaffDocument({
    required String documentUuid,
    required String staffCode, // Required for cache invalidation
  }) async {
    final response = await _remoteDataSource.deleteStaffDocument(
      documentUuid: documentUuid,
    );

    // Invalidate cache after delete
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
            expiryDate: m.expiryDate.isEmpty ? null : m.expiryDate,
            documentNotes: m.documentNotes,
            expired: m.expired,
            createdAt: m.createdAt,
            uploadedBy: m.updatedBy,
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
    bool forEditStaff = false,
  }) async {
    final trimmed = staffCode.trim();
    final cacheKey = _staffProfileCacheKey(trimmed, forEditStaff: forEditStaff);

    Future<StaffProfile> fetchRemoteAndSave() async {
      final profileModel = await _remoteDataSource.getStaffProfile(
        staffCode: trimmed,
        forEditStaff: forEditStaff,
      );
      await _cacheManager.saveCache(cacheKey, profileModel.toJson());
      return _mapProfileModelToEntity(profileModel);
    }

    try {
      final payload = await _cacheManager.loadCache(cacheKey);
      if (payload != null) {
        final model = StaffProfileModel.fromCacheJson(payload);
        return _mapProfileModelToEntity(model);
      }
    } catch (_) {}

    final future = _inflightStaffProfileByKey.putIfAbsent(cacheKey, () {
      final f = fetchRemoteAndSave();
      f.whenComplete(() => _inflightStaffProfileByKey.remove(cacheKey));
      return f;
    });
    return await future;
  }

  @override
  Future<String> updateStaffProfile({
    required String staffCode,
    required Map<String, dynamic> fields,
  }) async {
    final message = await _remoteDataSource.updateStaffProfile(
      staffCode: staffCode,
      body: fields,
    );

    await _invalidateStaffProfileCaches(staffCode);

    return message;
  }

  @override
  Future<String> updateStaffAddress({
    required String staffCode,
    required Map<String, dynamic> fields,
  }) async {
    final message = await _remoteDataSource.updateStaffAddress(
      staffCode: staffCode,
      body: fields,
    );

    await _invalidateStaffProfileCaches(staffCode);

    return message;
  }

  @override
  Future<String> updateMyProfile({
    required String staffCode,
    required Map<String, dynamic> fields,
  }) async {
    // Call my-profile PATCH endpoint (updates name, phone, address together).
    final message = await _remoteDataSource.updateMyProfile(
      staffCode: staffCode,
      body: fields,
    );

    // Refresh the cached profile:
    // 1) Try to re-fetch the latest profile from the staff profile GET.
    // 2) If that fails, at least invalidate the cache so next load uses fresh data.
    try {
      final profileModel = await _remoteDataSource.getStaffProfile(
        staffCode: staffCode,
        forEditStaff: false,
      );
      await _cacheManager.saveCache(
        _staffProfileCacheKey(staffCode.trim(), forEditStaff: false),
        profileModel.toJson(),
      );
    } catch (_) {
      await _invalidateStaffProfileCaches(staffCode);
    }

    return message;
  }

  @override
  Future<String> changeUserEmail({
    required String userCode,
    required String oldEmail,
    required String newEmail,
    required String organizationCode,
    required String schoolCode,
  }) async {
    final message = await _remoteDataSource.changeUserEmail(
      userCode: userCode,
      oldEmail: oldEmail,
      newEmail: newEmail,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
    );
    return message;
  }

  @override
  Future<String> getStaffSignInPin({
    required String staffCode,
  }) async {
    return _remoteDataSource.getStaffSignInPin(
      staffCode: staffCode,
    );
  }

  @override
  Future<StaffProfile?> loadCachedStaffProfile(
    String staffCode, {
    bool forEditStaff = false,
  }) async {
    final payload = await _cacheManager.loadCache(
      _staffProfileCacheKey(staffCode.trim(), forEditStaff: forEditStaff),
    );
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
      allowedClassrooms: model.allowedClassrooms
          .map((m) => AllowedClassroom(code: m.code, name: m.name))
          .toList(),
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
  Future<String?> getStaffCodeForUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
  }) {
    return _remoteDataSource.getStaffCodeByUser(
      userCode: userCode,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
    );
  }

  @override
  Future<List<Map<String, String>>> getImportantDates({
    required String staffCode,
  }) async {
    final models = await _remoteDataSource.getImportantDates(
      staffCode: staffCode,
    );

    final result = models
        .map(
          (m) => <String, String>{
            'importantDateType': m.importantDateType,
            'dueDate': m.dueDate,
            if (m.completedDate != null) 'completedDate': m.completedDate!,
            if (m.status != null && m.status!.isNotEmpty) 'status': m.status!,
          },
        )
        .toList();

    // Cache the important dates
    await _cacheManager.saveCache(
      _staffImportantDatesCacheKey(staffCode),
      {
        'dates': result,
      },
    );

    return result;
  }

  @override
  Future<List<Map<String, String>>?> loadCachedImportantDates(String staffCode) async {
    final payload = await _cacheManager.loadCache(_staffImportantDatesCacheKey(staffCode));
    if (payload == null) return null;

    final dates = payload['dates'] as List<dynamic>?;
    if (dates == null) return null;

    return dates
        .map((d) => d as Map<String, dynamic>)
        .map((d) => <String, String>{
              'importantDateType': d['importantDateType']?.toString() ?? '',
              'dueDate': d['dueDate']?.toString() ?? '',
              if (d['completedDate'] != null) 'completedDate': d['completedDate']!.toString(),
              if (d['status'] != null) 'status': d['status']!.toString(),
            })
        .toList();
  }

  @override
  Future<String> updateImportantDates({
    required String staffCode,
    required List<Map<String, String>> dates,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Final safety guard: never allow PHYSICAL_CHECKUP Due/Scheduled in past
    // (reverse rule of Completed) even if any UI path misses validation.
    for (final date in dates) {
      final type = (date['importantDateType'] ?? '').trim().toUpperCase();
      if (type != 'PHYSICAL_CHECKUP') continue;

      final status = (date['status'] ?? '').trim().toUpperCase();
      final dueDate = (date['dueDate'] ?? '').trim();
      if (dueDate.isEmpty) continue;

      DateTime? parsed;
      try {
        parsed = DateTime.parse(dueDate);
      } catch (_) {
        parsed = null;
      }
      if (parsed == null) continue;
      final picked = DateTime(parsed.year, parsed.month, parsed.day);

      final isDueOrScheduled =
          status == 'DUE' || status == 'SCHEDULED' || status == 'OVERDUE';
      final isCompleted = status == 'COMPLETED';

      print(
        '[ImportantDates Guard] staffCode=$staffCode type=$type status=$status dueDate=$dueDate today=$today picked=$picked',
      );

      if (isDueOrScheduled && picked.isBefore(today)) {
        print(
          '[ImportantDates Guard] BLOCK: Due/Scheduled picked date is before today.',
        );
        throw Exception(
          'For Due/Scheduled status, Physical Checkup Date must be today or future',
        );
      }
      if (isCompleted && picked.isAfter(today)) {
        print(
          '[ImportantDates Guard] BLOCK: Completed picked date is after today.',
        );
        throw Exception(
          'For Completed status, Physical Checkup Date must be today or past',
        );
      }
    }

    final dateRequests = dates
        .map(
          (date) => ImportantDateRequestModel(
            importantDateType: date['importantDateType']!,
            dueDate: date['dueDate']!,
            completedDate: date['completedDate'],
            status: date['status'],
          ),
        )
        .toList();

    final response = await _remoteDataSource.updateImportantDates(
      staffCode: staffCode,
      dates: dateRequests,
    );

    // Invalidate cache after update
    await _cacheManager.invalidateCache(_staffImportantDatesCacheKey(staffCode));

    await _invalidateStaffProfileCaches(staffCode);

    return response.message;
  }

  @override
  Future<String> updateStaffSchedules({
    required String staffCode,
    required List<Map<String, dynamic>> workSchedules,
    required List<Map<String, dynamic>> breakSchedules,
  }) async {
    final body = <String, dynamic>{
      'workSchedules': workSchedules,
      'breakSchedules': breakSchedules,
    };

    final message = await _remoteDataSource.updateStaffSchedules(
      staffCode: staffCode,
      body: body,
    );

    await _invalidateStaffProfileCaches(staffCode);

    return message;
  }

  @override
  Future<List<SchoolRegularScheduleDay>> getSchoolRegularSchedules({
    required String schoolCode,
  }) async {
    final model = await _remoteDataSource.getSchoolRegularSchedules(
      schoolCode: schoolCode,
    );
    return model.days;
  }

  @override
  Future<CreateSchoolUserResult> createSchoolAdminUser({
    required String firstName,
    required String lastName,
    required String displayName,
    required String mobile,
    required String email,
    required String organizationCode,
    required String schoolCode,
    required String role,
    required String designation,
    String? userCode,
  }) async {
    final request = CreateSchoolUserRequestModel(
      userCode: userCode,
      firstName: firstName,
      lastName: lastName,
      displayName: displayName,
      mobile: mobile,
      email: email,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      role: role,
      designation: designation,
    );

    final response = await _remoteDataSource.createSchoolAdminUser(
      request: request,
    );

    // Invalidate staff list cache since staff/admin listing may depend on it.
    await _cacheManager.invalidateCaches([
      _staffListCacheKey(schoolCode, status: 'ACTIVE'),
      _staffListCacheKey(schoolCode, status: 'INACTIVE'),
      _staffListCacheKey(schoolCode, status: 'UPCOMING'),
      _staffListCacheKey(schoolCode, status: 'ARCHIVE'),
    ]);

    final model = response.data;
    if (model == null) {
      throw Exception(response.message.isNotEmpty
          ? response.message
          : 'Empty response from create school admin user API');
    }

    return CreateSchoolUserResult(
      message: response.message,
      user: _mapSchoolUserModelToEntity(model),
    );
  }

  @override
  Future<CreateSchoolUserResult> createStaffUser({
    required String firstName,
    required String lastName,
    required String displayName,
    required String mobile,
    required String email,
    required String organizationCode,
    required String schoolCode,
    required String role,
    required String designation,
    required String status,
    required String primaryClassroomCode,
    required List<String> allowedClassroomCodes,
    String? userCode,
  }) async {
    final request = CreateStaffUserRequestModel(
      userCode: userCode,
      firstName: firstName,
      lastName: lastName,
      displayName: displayName,
      mobile: mobile,
      email: email,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      role: role,
      designation: designation,
      status: status,
      primaryClassroomCode: primaryClassroomCode,
      allowedClassroomCodes: allowedClassroomCodes,
    );

    final response = await _remoteDataSource.createStaffUser(
      request: request,
    );

    await _cacheManager.invalidateCaches([
      _staffListCacheKey(schoolCode, status: 'ACTIVE'),
      _staffListCacheKey(schoolCode, status: 'INACTIVE'),
      _staffListCacheKey(schoolCode, status: 'UPCOMING'),
      _staffListCacheKey(schoolCode, status: 'ARCHIVE'),
    ]);

    final model = response.data;
    if (model == null) {
      throw Exception(response.message.isNotEmpty
          ? response.message
          : 'Empty response from create staff user API');
    }

    return CreateSchoolUserResult(
      message: response.message,
      user: _mapSchoolUserModelToEntity(model),
    );
  }

  @override
  Future<String> deactivateSchoolUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  }) async {
    final message = await _remoteDataSource.deactivateSchoolUser(
      userCode: userCode,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      role: role,
    );

    // Invalidate staff list cache since deactivation affects staff listing.
    await _cacheManager.invalidateCaches([
      _staffListCacheKey(schoolCode, status: 'ACTIVE'),
      _staffListCacheKey(schoolCode, status: 'INACTIVE'),
      _staffListCacheKey(schoolCode, status: 'UPCOMING'),
      _staffListCacheKey(schoolCode, status: 'ARCHIVE'),
    ]);

    return message;
  }

  @override
  Future<String> deactivateOrganizationAdmin({
    required String userCode,
    required String organizationCode,
  }) async {
    final message = await _remoteDataSource.deactivateOrganizationAdmin(
      userCode: userCode,
      organizationCode: organizationCode,
    );

    // For organization-admin deactivation we cannot reliably invalidate
    // school-scoped caches here because we don't have a `schoolCode` value.
    // Callers already refresh the visible staff list after the operation.
    return message;
  }

  @override
  Future<String> activateOrganizationAdmin({
    required String userCode,
    required String organizationCode,
  }) async {
    final message = await _remoteDataSource.activateOrganizationAdmin(
      userCode: userCode,
      organizationCode: organizationCode,
    );

    // For organization-admin activation we cannot reliably invalidate
    // school-scoped caches here because we don't have a `schoolCode` value.
    // Callers already refresh the visible staff list after the operation.
    return message;
  }

  @override
  Future<String> activateSchoolUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  }) async {
    final message = await _remoteDataSource.activateSchoolUser(
      userCode: userCode,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      role: role,
    );

    // Invalidate staff list cache since activation affects staff listing.
    await _cacheManager.invalidateCaches([
      _staffListCacheKey(schoolCode, status: 'ACTIVE'),
      _staffListCacheKey(schoolCode, status: 'INACTIVE'),
      _staffListCacheKey(schoolCode, status: 'UPCOMING'),
      _staffListCacheKey(schoolCode, status: 'ARCHIVE'),
    ]);

    return message;
  }

  SchoolUser _mapSchoolUserModelToEntity(SchoolUserModel model) {
    return SchoolUser(
      userCode: model.userCode,
      staffCode: model.staffCode,
      firstName: model.firstName,
      lastName: model.lastName,
      displayName: model.displayName,
      mobile: model.mobile,
      email: model.email,
      organizationCode: model.organizationCode,
      schoolCode: model.schoolCode,
      role: model.role,
      designation: model.designation,
      status: model.status,
      primaryClassroomCode: model.primaryClassroomCode,
      allowedClassroomCodes: model.allowedClassroomCodes,
    );
  }
}


