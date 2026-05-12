import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/debug_defaults.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement_board.dart';
import 'package:wowcare/domain/features/availability/repositories/availability_repository.dart';
import 'package:wowcare/domain/features/availability/usecases/create_individual_movement_usecase.dart';
import 'package:wowcare/domain/features/availability/usecases/delete_individual_movement_usecase.dart';
import 'package:wowcare/domain/features/availability/usecases/get_individual_movement_by_id_usecase.dart';
import 'package:wowcare/domain/features/availability/usecases/get_individual_movements_usecase.dart';
import 'package:wowcare/domain/features/availability/usecases/transition_individual_movement_status_usecase.dart';
import 'package:wowcare/domain/features/availability/usecases/update_individual_movement_usecase.dart';

class IndividualMovementsCubit extends Cubit<IndividualMovementsState> {
  IndividualMovementsCubit({
    required CreateIndividualMovementUseCase createIndividualMovementUseCase,
    required UpdateIndividualMovementUseCase updateIndividualMovementUseCase,
    required DeleteIndividualMovementUseCase deleteIndividualMovementUseCase,
    required GetIndividualMovementByIdUseCase getIndividualMovementByIdUseCase,
    required GetIndividualMovementsUseCase getIndividualMovementsUseCase,
    required TransitionIndividualMovementStatusUseCase transitionIndividualMovementStatusUseCase,
    required AvailabilityRepository repository,
    required StorageService storageService,
  })  : _createIndividualMovementUseCase = createIndividualMovementUseCase,
        _updateIndividualMovementUseCase = updateIndividualMovementUseCase,
        _deleteIndividualMovementUseCase = deleteIndividualMovementUseCase,
        _getIndividualMovementByIdUseCase = getIndividualMovementByIdUseCase,
        _getIndividualMovementsUseCase = getIndividualMovementsUseCase,
        _transitionIndividualMovementStatusUseCase = transitionIndividualMovementStatusUseCase,
        _repository = repository,
        _storageService = storageService,
        super(const IndividualMovementsState.initial());

  final CreateIndividualMovementUseCase _createIndividualMovementUseCase;
  final UpdateIndividualMovementUseCase _updateIndividualMovementUseCase;
  final DeleteIndividualMovementUseCase _deleteIndividualMovementUseCase;
  final GetIndividualMovementByIdUseCase _getIndividualMovementByIdUseCase;
  final GetIndividualMovementsUseCase _getIndividualMovementsUseCase;
  final TransitionIndividualMovementStatusUseCase _transitionIndividualMovementStatusUseCase;
  final AvailabilityRepository _repository;
  final StorageService _storageService;
  _MovementFilters _lastFilters = const _MovementFilters();

  Future<Set<String>> _resolveAllowedClassroomsForStaff() async {
    try {
      final raw =
          (await _storageService.getString(StorageKeys.staffAllowedClassroomCodes) ?? '')
              .trim();
      if (raw.isEmpty) return const <String>{};
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toSet();
      }
    } catch (_) {}
    return const <String>{};
  }

  IndividualMovementBoard _filterBoardForAllowedClassrooms(
    IndividualMovementBoard board,
    Set<String> allowed,
  ) {
    if (allowed.isEmpty) return board;

    bool touchesAllowed(IndividualMovement m) {
      final from = m.fromClassroomCode.trim();
      final to = m.toClassroomCode.trim();
      return (from.isNotEmpty && allowed.contains(from)) ||
          (to.isNotEmpty && allowed.contains(to));
    }

    return IndividualMovementBoard(
      overdue: board.overdue.where(touchesAllowed).toList(growable: false),
      upcoming: board.upcoming.where(touchesAllowed).toList(growable: false),
      confirmed: board.confirmed.where(touchesAllowed).toList(growable: false),
      rejected: board.rejected.where(touchesAllowed).toList(growable: false),
    );
  }

  Future<void> loadInitial({
    List<String>? studentCodes,
    List<String>? fromClassroomCodes,
    List<String>? toClassroomCodes,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? status,
  }) async {
    _lastFilters = _MovementFilters(
      studentCodes: studentCodes,
      fromClassroomCodes: fromClassroomCodes,
      toClassroomCodes: toClassroomCodes,
      dateFrom: dateFrom,
      dateTo: dateTo,
      status: status,
    );
    final schoolCode = await _resolveSchoolCode();
    final cached = await (_repository is AvailabilityRepositoryWithCache
        ? (_repository as AvailabilityRepositoryWithCache).loadCachedIndividualMovements(
            schoolCode: schoolCode,
            studentCodes: studentCodes,
            fromClassroomCodes: fromClassroomCodes,
            toClassroomCodes: toClassroomCodes,
            dateFrom: dateFrom,
            dateTo: dateTo,
            status: status,
          )
        : Future.value(null));

    if (cached != null && !isClosed) {
      final allowed = await _resolveAllowedClassroomsForStaff();
      emit(
        IndividualMovementsState.loaded(
          board: _filterBoardForAllowedClassrooms(cached, allowed),
          isFromCache: true,
        ),
      );
      return;
    }

    await refresh(
      studentCodes: studentCodes,
      fromClassroomCodes: fromClassroomCodes,
      toClassroomCodes: toClassroomCodes,
      dateFrom: dateFrom,
      dateTo: dateTo,
      status: status,
    );
  }

  Future<void> refresh({
    List<String>? studentCodes,
    List<String>? fromClassroomCodes,
    List<String>? toClassroomCodes,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? status,
  }) async {
    if (state.isRefreshing) return;
    _lastFilters = _MovementFilters(
      studentCodes: studentCodes,
      fromClassroomCodes: fromClassroomCodes,
      toClassroomCodes: toClassroomCodes,
      dateFrom: dateFrom,
      dateTo: dateTo,
      status: status,
    );

    emit(state.copyWith(isLoading: state.board == null, isRefreshing: true, clearError: true));

    try {
      final schoolCode = await _resolveSchoolCode();
      final board = await _getIndividualMovementsUseCase(
        schoolCode: schoolCode,
        studentCodes: studentCodes,
        fromClassroomCodes: fromClassroomCodes,
        toClassroomCodes: toClassroomCodes,
        dateFrom: dateFrom,
        dateTo: dateTo,
        status: status,
      );
      final allowed = await _resolveAllowedClassroomsForStaff();
      if (isClosed) return;
      emit(
        IndividualMovementsState.loaded(
          board: _filterBoardForAllowedClassrooms(board, allowed),
          isFromCache: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, isRefreshing: false, errorMessage: e.toString()));
    }
  }

  Future<String> transitionStatus({
    required int id,
    required IndividualMovementWorkflowStatus status,
    String? comment,
    DateTime? newMovementDate,
  }) async {
    if (state.isTransitioning) {
      throw 'Another movement transition is already in progress.';
    }
    emit(state.copyWith(isTransitioning: true, clearError: true));
    try {
      final schoolCode = await _resolveSchoolCode();
      if (_repository is AvailabilityRepositoryWithCache) {
        await (_repository as AvailabilityRepositoryWithCache).invalidateAvailabilityCache(
          schoolCode: schoolCode,
        );
      }
      final message = await _transitionIndividualMovementStatusUseCase(
        id: id,
        status: status,
        comment: comment,
        newMovementDate: newMovementDate,
      );
      await refresh(
        studentCodes: _lastFilters.studentCodes,
        fromClassroomCodes: _lastFilters.fromClassroomCodes,
        toClassroomCodes: _lastFilters.toClassroomCodes,
        dateFrom: _lastFilters.dateFrom,
        dateTo: _lastFilters.dateTo,
        status: _lastFilters.status,
      );
      if (!isClosed) {
        emit(state.copyWith(isTransitioning: false));
      }
      return message;
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(isTransitioning: false, errorMessage: e.toString()));
      }
      rethrow;
    }
  }

  Future<String> _resolveSchoolCode() async {
    final schoolCode =
        (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();
    if (schoolCode.isNotEmpty && schoolCode != '-') {
      return schoolCode;
    }

    // Recover a valid school from saved org/school selections when stale '-'
    // exists in storage.
    final organizationCode =
        (await _storageService.getString(StorageKeys.organizationCode) ?? '')
            .trim();
    final rawList =
        (await _storageService.getString(StorageKeys.organizationsAndSchools) ??
                '')
            .trim();
    if (organizationCode.isNotEmpty && rawList.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawList);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              final org = (item['organizationCode'] ?? '').toString().trim();
              final school = (item['schoolCode'] ?? '').toString().trim();
              if (org == organizationCode && school.isNotEmpty && school != '-') {
                return school;
              }
            }
          }
        }
      } catch (_) {
        // Non-blocking: continue with dev fallback / error.
      }
    }

    if (DebugDefaults.schoolCode.trim().isNotEmpty) {
      return DebugDefaults.schoolCode.trim();
    }

    if (schoolCode.isEmpty || schoolCode == '-') {
      throw Exception('School code is missing. Please re-login and try again.');
    }
    return schoolCode;
  }

  Future<String> _resolveOrganizationCode() async {
    final organizationCode =
        (await _storageService.getString(StorageKeys.organizationCode) ?? '').trim();
    if (organizationCode.isEmpty) {
      throw Exception('Organization code is missing. Please re-login and try again.');
    }
    return organizationCode;
  }

  Future<String> createMovement({
    required String studentCode,
    required String fromClassroomCode,
    required String toClassroomCode,
    required DateTime movementDate,
    String? comment,
    IndividualMovementType movementType = IndividualMovementType.moveToNextClassroom,
  }) async {
    if (state.isTransitioning) {
      throw 'Another movement operation is already in progress.';
    }

    emit(state.copyWith(isTransitioning: true, clearError: true));
    try {
      final schoolCode = await _resolveSchoolCode();
      final organizationCode = await _resolveOrganizationCode();
      if (_repository is AvailabilityRepositoryWithCache) {
        await (_repository as AvailabilityRepositoryWithCache).invalidateAvailabilityCache(
          schoolCode: schoolCode,
        );
      }
      final message = await _createIndividualMovementUseCase(
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        studentCode: studentCode,
        movementType: movementType,
        fromClassroomCode: fromClassroomCode,
        toClassroomCode: toClassroomCode,
        movementDate: movementDate,
        comment: comment,
      );
      await refresh(
        studentCodes: _lastFilters.studentCodes,
        fromClassroomCodes: _lastFilters.fromClassroomCodes,
        toClassroomCodes: _lastFilters.toClassroomCodes,
        dateFrom: _lastFilters.dateFrom,
        dateTo: _lastFilters.dateTo,
        status: _lastFilters.status,
      );
      if (!isClosed) {
        emit(state.copyWith(isTransitioning: false));
      }
      return message;
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(isTransitioning: false, errorMessage: e.toString()));
      }
      rethrow;
    }
  }

  Future<String> updateMovement({
    required int id,
    required IndividualMovementType movementType,
    required String fromClassroomCode,
    required String toClassroomCode,
    required DateTime movementDate,
    String? comment,
  }) async {
    if (state.isTransitioning) {
      throw 'Another movement operation is already in progress.';
    }

    emit(state.copyWith(isTransitioning: true, clearError: true));
    try {
      final schoolCode = await _resolveSchoolCode();
      if (_repository is AvailabilityRepositoryWithCache) {
        await (_repository as AvailabilityRepositoryWithCache).invalidateAvailabilityCache(
          schoolCode: schoolCode,
        );
      }
      final message = await _updateIndividualMovementUseCase(
        id: id,
        movementType: movementType,
        fromClassroomCode: fromClassroomCode,
        toClassroomCode: toClassroomCode,
        movementDate: movementDate,
        comment: comment,
      );
      await refresh(
        studentCodes: _lastFilters.studentCodes,
        fromClassroomCodes: _lastFilters.fromClassroomCodes,
        toClassroomCodes: _lastFilters.toClassroomCodes,
        dateFrom: _lastFilters.dateFrom,
        dateTo: _lastFilters.dateTo,
        status: _lastFilters.status,
      );
      if (!isClosed) {
        emit(state.copyWith(isTransitioning: false));
      }
      return message;
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(isTransitioning: false, errorMessage: e.toString()));
      }
      rethrow;
    }
  }

  Future<String> deleteMovement({
    required int id,
  }) async {
    if (state.isTransitioning) {
      throw 'Another movement operation is already in progress.';
    }

    emit(state.copyWith(isTransitioning: true, clearError: true));
    try {
      final schoolCode = await _resolveSchoolCode();
      if (_repository is AvailabilityRepositoryWithCache) {
        await (_repository as AvailabilityRepositoryWithCache).invalidateAvailabilityCache(
          schoolCode: schoolCode,
        );
      }
      final message = await _deleteIndividualMovementUseCase(id: id);
      await refresh(
        studentCodes: _lastFilters.studentCodes,
        fromClassroomCodes: _lastFilters.fromClassroomCodes,
        toClassroomCodes: _lastFilters.toClassroomCodes,
        dateFrom: _lastFilters.dateFrom,
        dateTo: _lastFilters.dateTo,
        status: _lastFilters.status,
      );
      if (!isClosed) {
        emit(state.copyWith(isTransitioning: false));
      }
      return message;
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(isTransitioning: false, errorMessage: e.toString()));
      }
      rethrow;
    }
  }

  Future<IndividualMovement> getMovementById(int id) {
    return _getIndividualMovementByIdUseCase(id: id);
  }
}

class IndividualMovementsState extends Equatable {
  const IndividualMovementsState({
    required this.board,
    required this.isLoading,
    required this.isRefreshing,
    required this.isFromCache,
    required this.isTransitioning,
    this.errorMessage,
  });

  const IndividualMovementsState.initial()
      : board = null,
        isLoading = false,
        isRefreshing = false,
        isFromCache = false,
        isTransitioning = false,
        errorMessage = null;

  const IndividualMovementsState.loaded({
    required IndividualMovementBoard board,
    required bool isFromCache,
  })  : board = board,
        isLoading = false,
        isRefreshing = false,
        isFromCache = isFromCache,
        isTransitioning = false,
        errorMessage = null;

  final IndividualMovementBoard? board;
  final bool isLoading;
  final bool isRefreshing;
  final bool isFromCache;
  final bool isTransitioning;
  final String? errorMessage;

  IndividualMovementsState copyWith({
    IndividualMovementBoard? board,
    bool? isLoading,
    bool? isRefreshing,
    bool? isFromCache,
    bool? isTransitioning,
    String? errorMessage,
    bool clearError = false,
  }) {
    return IndividualMovementsState(
      board: board ?? this.board,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isFromCache: isFromCache ?? this.isFromCache,
      isTransitioning: isTransitioning ?? this.isTransitioning,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [board, isLoading, isRefreshing, isFromCache, isTransitioning, errorMessage];
}

class _MovementFilters {
  const _MovementFilters({
    this.studentCodes,
    this.fromClassroomCodes,
    this.toClassroomCodes,
    this.dateFrom,
    this.dateTo,
    this.status,
  });

  final List<String>? studentCodes;
  final List<String>? fromClassroomCodes;
  final List<String>? toClassroomCodes;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final List<String>? status;
}
