import '../../../../core/util/cache_manager.dart';
import '../../../../domain/features/scheduling/entities/classroom_forecast_block.dart';
import '../../../../domain/features/scheduling/entities/staff_shift.dart';
import '../../../../domain/features/scheduling/entities/staff_shift_hours_entry.dart';
import '../../../../domain/features/scheduling/repositories/staff_shift_repository.dart';
import '../datasources/staff_shift_remote_datasource.dart';
import '../models/classroom_forecast_models.dart';
import '../models/staff_shift_hours_models.dart';
import '../models/staff_shift_models.dart';

class StaffShiftRepositoryImpl
    implements StaffShiftRepository, StaffShiftRepositoryWithCache {
  StaffShiftRepositoryImpl(this._remote, this._cacheManager);

  final StaffShiftRemoteDataSource _remote;
  final CacheManager _cacheManager;

  /// In-flight dedup so a screen rebuild doesn't fire the same GET twice.
  final Map<String, Future<List<StaffShift>>> _inflight =
      <String, Future<List<StaffShift>>>{};

  /// Tracks every shift cache key per staffCode, so create/edit can wipe them.
  final Map<String, Set<String>> _registeredKeysByStaff =
      <String, Set<String>>{};

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _shiftsCacheKey({
    required String staffCode,
    required String schoolCode,
    required DateTime dateFrom,
    required DateTime dateTo,
  }) {
    final identifier =
        '$staffCode|$schoolCode|${_formatDate(dateFrom)}|${_formatDate(dateTo)}';
    return CacheManager.buildCacheKey(
      feature: 'scheduling',
      resource: 'staff_shifts',
      identifier: identifier,
    );
  }

  void _registerKey(String staffCode, String key) {
    _registeredKeysByStaff.putIfAbsent(staffCode, () => <String>{}).add(key);
  }

  @override
  Future<List<StaffShift>> getStaffShifts({
    required String staffCode,
    required String schoolCode,
    required String organizationCode,
    required DateTime dateFrom,
    required DateTime dateTo,
  }) {
    final key = _shiftsCacheKey(
      staffCode: staffCode,
      schoolCode: schoolCode,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    _registerKey(staffCode, key);

    final existing = _inflight[key];
    if (existing != null) return existing;

    final future = _fetchAndCache(
      key: key,
      staffCode: staffCode,
      schoolCode: schoolCode,
      organizationCode: organizationCode,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    _inflight[key] = future;
    future.whenComplete(() => _inflight.remove(key));
    return future;
  }

  Future<List<StaffShift>> _fetchAndCache({
    required String key,
    required String staffCode,
    required String schoolCode,
    required String organizationCode,
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    final models = await _remote.getStaffShifts(
      staffCode: staffCode,
      schoolCode: schoolCode,
      organizationCode: organizationCode,
      dateFrom: _formatDate(dateFrom),
      dateTo: _formatDate(dateTo),
    );
    await _cacheManager.saveCache(key, <String, dynamic>{
      'items': models.map((m) => m.toJson()).toList(),
    });
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<StaffShift>?> loadCachedStaffShifts({
    required String staffCode,
    required String schoolCode,
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    final key = _shiftsCacheKey(
      staffCode: staffCode,
      schoolCode: schoolCode,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    _registerKey(staffCode, key);
    final cached = await _cacheManager.loadCache(key);
    if (cached == null) return null;
    final items = cached['items'];
    if (items is! List) return const <StaffShift>[];
    return items
        .whereType<Map<String, dynamic>>()
        .map((json) {
          try {
            return StaffShiftModel.fromJson(json).toEntity();
          } catch (_) {
            return null;
          }
        })
        .whereType<StaffShift>()
        .toList(growable: false);
  }

  @override
  Future<void> invalidateCachedStaffShifts({
    required String staffCode,
    String? schoolCode,
  }) async {
    final keys = _registeredKeysByStaff[staffCode];
    if (keys == null || keys.isEmpty) return;
    await _cacheManager.invalidateCaches(keys.toList(growable: false));
    keys.clear();
  }

  @override
  Future<List<StaffShift>> getSchoolStaffShifts({
    required String schoolCode,
    required String organizationCode,
    required DateTime dateFrom,
    required DateTime dateTo,
    String? classroomCode,
    List<String> shiftStatus = const <String>[],
  }) async {
    final models = await _remote.getSchoolStaffShifts(
      schoolCode: schoolCode,
      organizationCode: organizationCode,
      dateFrom: _formatDate(dateFrom),
      dateTo: _formatDate(dateTo),
      classroomCode: classroomCode,
      shiftStatus: shiftStatus,
    );
    return models.map((m) => m.toEntity()).toList(growable: false);
  }

  @override
  Future<StaffShift> getStaffShiftByCode(String shiftCode) async {
    final model = await _remote.getStaffShiftByCode(shiftCode: shiftCode);
    return model.toEntity();
  }

  @override
  Future<List<ClassroomForecastBlock>> getClassroomForecast({
    required String schoolCode,
    required String organizationCode,
    required ClassroomForecastQuery query,
  }) async {
    final models = await _remote.getClassroomForecast(
      schoolCode: schoolCode,
      organizationCode: organizationCode,
      request: ClassroomForecastRequestModel(
        date: _formatDate(query.date),
        startTime: formatForecastClockTime(query.startTime),
        endTime: formatForecastClockTime(query.endTime),
        durationMinutes: query.durationMinutes,
        classroomCodes: query.classroomCodes,
      ),
    );
    return models.map((m) => m.toEntity()).toList(growable: false);
  }

  @override
  Future<List<ClassroomForecastBlock>> getClassroomForecastRange({
    required String schoolCode,
    required String organizationCode,
    required ClassroomForecastRangeQuery query,
  }) async {
    final models = await _remote.getClassroomForecastRange(
      schoolCode: schoolCode,
      organizationCode: organizationCode,
      request: ClassroomForecastRangeRequestModel(
        startDate: _formatDate(query.startDate),
        endDate: _formatDate(query.endDate),
        startTime: formatForecastClockTime(query.startTime),
        endTime: formatForecastClockTime(query.endTime),
        durationMinutes: query.durationMinutes,
        classroomCodes: query.classroomCodes,
      ),
    );
    return models.map((m) => m.toEntity()).toList(growable: false);
  }

  @override
  Future<List<StaffShiftHoursEntry>> getStaffShiftHoursRange({
    required String schoolCode,
    required String organizationCode,
    required DateTime startDate,
    required DateTime endDate,
    List<String> staffCodes = const <String>[],
  }) async {
    final models = await _remote.getStaffShiftHoursRange(
      request: StaffShiftHoursRangeRequestModel(
        startDate: _formatDate(startDate),
        endDate: _formatDate(endDate),
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        staffCodes: staffCodes,
      ),
    );
    return models.map((m) => m.toEntity()).toList(growable: false);
  }

  @override
  Future<StaffShiftCreateResult> createStaffShift(
    StaffShiftCreateRequest request,
  ) async {
    final body = StaffShiftRequestModel(request).toJson();
    final model = await _remote.createStaffShift(body: body);
    // Wipe cached shift lists for this staff so the next read is fresh.
    await invalidateCachedStaffShifts(staffCode: request.staffCode);
    return model.toEntity();
  }

  @override
  Future<List<DateTime>> getStaffAbsentDatesInRange({
    required String staffCode,
    required DateTime from,
    required DateTime to,
  }) async {
    return _remote.getStaffAbsentDatesInRange(
      staffCode: staffCode,
      fromAbsenceDate: _formatDate(from),
      toAbsenceDate: _formatDate(to),
    );
  }

  @override
  Future<StaffShift> updateStaffShift(StaffShiftUpdateRequest request) async {
    final body = StaffShiftUpdateRequestModel(request).toJson();
    final model = await _remote.updateStaffShift(
      shiftCode: request.shiftCode,
      body: body,
    );
    final staffCode = model.staffCode.trim();
    if (staffCode.isNotEmpty) {
      await invalidateCachedStaffShifts(staffCode: staffCode);
    }
    return model.toEntity();
  }

  @override
  Future<StaffShiftCreateResult> updateStaffShiftSeries(
    StaffShiftSeriesUpdateRequest request,
  ) async {
    final body = StaffShiftSeriesUpdateRequestModel(request).toJson();
    final model = await _remote.updateStaffShiftSeries(
      seriesCode: request.seriesCode,
      body: body,
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteStaffShift({
    required String shiftCode,
    String? staffCode,
  }) async {
    await _remote.deleteStaffShift(shiftCode: shiftCode);
    final code = staffCode?.trim();
    if (code != null && code.isNotEmpty) {
      await invalidateCachedStaffShifts(staffCode: code);
    }
  }

  @override
  Future<void> deleteStaffShiftSeries({
    required String seriesCode,
    String? staffCode,
  }) async {
    await _remote.deleteStaffShiftSeries(seriesCode: seriesCode);
    final code = staffCode?.trim();
    if (code != null && code.isNotEmpty) {
      await invalidateCachedStaffShifts(staffCode: code);
    }
  }

  @override
  Future<void> publishStaffShifts({
    required String schoolCode,
    required String organizationCode,
    required DateTime dateRangeStart,
    required bool publishAll,
    required bool publishAllStaff,
    DateTime? publishUntilDate,
    List<String> selectedStaffCodes = const <String>[],
  }) async {
    final body = <String, dynamic>{
      'schoolCode': schoolCode,
      'organizationCode': organizationCode,
      'publishAll': publishAll,
      'publishAllStaff': publishAllStaff,
      'dateRangeStart': _formatDate(dateRangeStart),
    };
    if (!publishAll && publishUntilDate != null) {
      body['publishUntilDate'] = _formatDate(publishUntilDate);
    }
    if (!publishAllStaff) {
      body['selectedStaffCodes'] = selectedStaffCodes;
    }
    await _remote.publishStaffShifts(body: body);

    // Publish changes the isPublished flag on shifts — drop every per-staff
    // cached list so the next read picks up the updated state.
    final allKeys = _registeredKeysByStaff.values
        .expand((s) => s)
        .toList(growable: false);
    if (allKeys.isNotEmpty) {
      await _cacheManager.invalidateCaches(allKeys);
      _registeredKeysByStaff.clear();
    }
  }

  @override
  Future<int> markStaffShiftAbsentDays({
    required String staffCode,
    required String schoolCode,
    required List<DateTime> absentDates,
  }) async {
    if (absentDates.isEmpty) return 0;
    final deleted = await _remote.markStaffShiftAbsentDays(
      staffCode: staffCode,
      schoolCode: schoolCode,
      absentDates: absentDates.map(_formatDate).toList(growable: false),
    );
    if (deleted > 0) {
      await invalidateCachedStaffShifts(staffCode: staffCode);
    }
    return deleted;
  }
}
