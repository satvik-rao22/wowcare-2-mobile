import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/cache_manager.dart';
import 'package:wowcare/data/features/availability/datasources/availability_remote_datasource.dart';
import 'package:wowcare/data/features/availability/models/future_availability_models.dart';
import 'package:wowcare/data/features/availability/models/individual_movement_models.dart';
import 'package:wowcare/domain/features/availability/entities/future_availability.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement_board.dart';
import 'package:wowcare/domain/features/availability/repositories/availability_repository.dart';

class AvailabilityRepositoryImpl
    implements AvailabilityRepository, AvailabilityRepositoryWithCache {
  AvailabilityRepositoryImpl(
    this._remoteDataSource,
    StorageService storageService,
  ) : _storageService = storageService,
      _cacheManager = CacheManager(storageService);

  final AvailabilityRemoteDataSource _remoteDataSource;
  final StorageService _storageService;
  final CacheManager _cacheManager;

  static String _cacheGenerationKey(String schoolCode) =>
      'availability_cache_generation_${schoolCode.trim()}';

  Future<int> _cacheGeneration(String schoolCode) async {
    return (await _storageService.getInt(_cacheGenerationKey(schoolCode))) ?? 0;
  }

  Future<void> _bumpCacheGeneration(String schoolCode) async {
    final next = (await _cacheGeneration(schoolCode)) + 1;
    await _storageService.saveInt(_cacheGenerationKey(schoolCode), next);
  }

  @override
  Future<IndividualMovementBoard> getIndividualMovements({
    required String schoolCode,
    List<String>? studentCodes,
    List<String>? fromClassroomCodes,
    List<String>? toClassroomCodes,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? status,
  }) async {
    final model = await _remoteDataSource.getIndividualMovements(
      schoolCode: schoolCode,
      studentCodes: studentCodes,
      fromClassroomCodes: fromClassroomCodes,
      toClassroomCodes: toClassroomCodes,
      dateFrom: dateFrom,
      dateTo: dateTo,
      status: status,
    );

    final gen = await _cacheGeneration(schoolCode);
    await _cacheManager.saveCache(
      _cacheKey(
        schoolCode: schoolCode,
        generation: gen,
        studentCodes: studentCodes,
        fromClassroomCodes: fromClassroomCodes,
        toClassroomCodes: toClassroomCodes,
        dateFrom: dateFrom,
        dateTo: dateTo,
        status: status,
      ),
      model.toJson(),
    );

    return model.toEntity();
  }

  @override
  Future<IndividualMovementBoard?> loadCachedIndividualMovements({
    required String schoolCode,
    List<String>? studentCodes,
    List<String>? fromClassroomCodes,
    List<String>? toClassroomCodes,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? status,
  }) async {
    final gen = await _cacheGeneration(schoolCode);
    final payload = await _cacheManager.loadCache(
      _cacheKey(
        schoolCode: schoolCode,
        generation: gen,
        studentCodes: studentCodes,
        fromClassroomCodes: fromClassroomCodes,
        toClassroomCodes: toClassroomCodes,
        dateFrom: dateFrom,
        dateTo: dateTo,
        status: status,
      ),
    );
    if (payload == null) return null;
    return IndividualMovementBoardModel.fromCacheJson(payload).toEntity();
  }

  @override
  Future<void> invalidateAvailabilityCache({required String schoolCode}) async {
    // Cache keys include this generation; bumping it effectively invalidates all
    // cached entries for this school without needing key enumeration.
    await _bumpCacheGeneration(schoolCode);
  }

  @override
  Future<String> transitionIndividualMovementStatus({
    required int id,
    required IndividualMovementWorkflowStatus status,
    String? comment,
    DateTime? newMovementDate,
  }) {
    return _remoteDataSource.transitionIndividualMovementStatus(
      id: id,
      status: _statusToApi(status),
      comment: comment,
      newMovementDate: newMovementDate,
    );
  }

  @override
  Future<String> createIndividualMovement({
    required String schoolCode,
    required String organizationCode,
    required String studentCode,
    required IndividualMovementType movementType,
    required String fromClassroomCode,
    required String toClassroomCode,
    required DateTime movementDate,
    String? comment,
  }) {
    return _remoteDataSource.createIndividualMovement(
      schoolCode: schoolCode,
      organizationCode: organizationCode,
      studentCode: studentCode,
      movementType: _movementTypeToApi(movementType),
      fromClassroomCode: fromClassroomCode,
      toClassroomCode: toClassroomCode,
      movementDate: movementDate,
      comment: comment,
    );
  }

  @override
  Future<IndividualMovement> getIndividualMovementById({
    required int id,
  }) async {
    final model = await _remoteDataSource.getIndividualMovementById(id: id);
    return model.toEntity();
  }

  @override
  Future<String> updateIndividualMovement({
    required int id,
    required IndividualMovementType movementType,
    required String fromClassroomCode,
    required String toClassroomCode,
    required DateTime movementDate,
    String? comment,
  }) {
    return _remoteDataSource.updateIndividualMovement(
      id: id,
      movementType: _movementTypeToApi(movementType),
      fromClassroomCode: fromClassroomCode,
      toClassroomCode: toClassroomCode,
      movementDate: movementDate,
      comment: comment,
    );
  }

  @override
  Future<String> deleteIndividualMovement({required int id}) {
    return _remoteDataSource.deleteIndividualMovement(id: id);
  }

  @override
  Future<FutureAvailabilityGrid> getFutureAvailability({
    required String schoolCode,
    required DateTime startDate,
    required DateTime endDate,
    required FutureAvailabilityShift shift,
  }) async {
    final model = await _remoteDataSource.getFutureAvailability(
      schoolCode: schoolCode,
      startDate: startDate,
      endDate: endDate,
      shift: _futureShiftToApi(shift),
    );

    final gen = await _cacheGeneration(schoolCode);
    await _cacheManager.saveCache(
      _futureAvailabilityCacheKey(
        schoolCode: schoolCode,
        generation: gen,
        startDate: startDate,
        endDate: endDate,
        shift: shift,
      ),
      model.toJson(),
    );

    return model.toEntity();
  }

  @override
  Future<void> recomputeFutureAvailability({
    required String schoolCode,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _remoteDataSource.recomputeFutureAvailability(
      schoolCode: schoolCode,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<FutureAvailabilityGrid?> loadCachedFutureAvailability({
    required String schoolCode,
    required DateTime startDate,
    required DateTime endDate,
    required FutureAvailabilityShift shift,
  }) async {
    final gen = await _cacheGeneration(schoolCode);
    final payload = await _cacheManager.loadCache(
      _futureAvailabilityCacheKey(
        schoolCode: schoolCode,
        generation: gen,
        startDate: startDate,
        endDate: endDate,
        shift: shift,
      ),
    );
    if (payload == null) return null;
    return FutureAvailabilityGridModel.fromCacheJson(payload).toEntity();
  }

  String _cacheKey({
    required String schoolCode,
    required int generation,
    List<String>? studentCodes,
    List<String>? fromClassroomCodes,
    List<String>? toClassroomCodes,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? status,
  }) {
    final identity = <String>[
      schoolCode.trim(),
      'gen:$generation',
      _normalizeList(studentCodes),
      _normalizeList(fromClassroomCodes),
      _normalizeList(toClassroomCodes),
      _dateValue(dateFrom),
      _dateValue(dateTo),
      _normalizeList(status),
    ].join('|');
    return CacheManager.buildCacheKey(
      feature: 'availability',
      resource: 'individual_movements',
      identifier: identity,
    );
  }

  String _futureAvailabilityCacheKey({
    required String schoolCode,
    required int generation,
    required DateTime startDate,
    required DateTime endDate,
    required FutureAvailabilityShift shift,
  }) {
    final identity = <String>[
      schoolCode.trim(),
      'gen:$generation',
      _dateValue(startDate),
      _dateValue(endDate),
      _futureShiftToApi(shift),
    ].join('|');
    return CacheManager.buildCacheKey(
      feature: 'availability',
      resource: 'future_availability',
      identifier: identity,
    );
  }

  @override
  Future<({int pendingCount, int overdueCount})> getMovementStatusCounts({
    required String schoolCode,
    required String fromDate,
    required String toDate,
  }) async {
    final model = await _remoteDataSource.getMovementStatusCounts(
      schoolCode: schoolCode,
      fromDate: fromDate,
      toDate: toDate,
    );
    return (pendingCount: model.pendingCount, overdueCount: model.overdueCount);
  }
}

String _statusToApi(IndividualMovementWorkflowStatus value) {
  switch (value) {
    case IndividualMovementWorkflowStatus.pending:
      return 'PENDING';
    case IndividualMovementWorkflowStatus.confirmed:
      return 'CONFIRMED';
    case IndividualMovementWorkflowStatus.rejected:
      return 'REJECTED';
  }
}

String _movementTypeToApi(IndividualMovementType value) {
  switch (value) {
    case IndividualMovementType.startSchool:
      return 'START_SCHOOL';
    case IndividualMovementType.leaveSchool:
      return 'LEAVE_SCHOOL';
    case IndividualMovementType.moveToNextClassroom:
      // Backend enum uses CLASSROOM_PROMOTION for "move to next classroom".
      return 'CLASSROOM_PROMOTION';
  }
}

String _normalizeList(List<String>? values) {
  if (values == null || values.isEmpty) return '-';
  final sorted = values.map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
    ..sort();
  if (sorted.isEmpty) return '-';
  return sorted.join(',');
}

String _dateValue(DateTime? date) {
  if (date == null) return '-';
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y$m$d';
}

String _futureShiftToApi(FutureAvailabilityShift shift) {
  switch (shift) {
    case FutureAvailabilityShift.fullDay:
      return 'FULL_DAY';
    case FutureAvailabilityShift.morning:
      return 'MORNING';
    case FutureAvailabilityShift.afternoon:
      return 'AFTERNOON';
    case FutureAvailabilityShift.all:
      return 'ALL';
    case FutureAvailabilityShift.twoShifts:
      return 'TWO_SHIFTS';
  }
}
