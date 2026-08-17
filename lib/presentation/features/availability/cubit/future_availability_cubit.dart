import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/availability/entities/future_availability.dart';
import 'package:wowcare/domain/features/availability/repositories/availability_repository.dart';
import 'package:wowcare/domain/features/availability/usecases/get_future_availability_usecase.dart';

class FutureAvailabilityCubit extends Cubit<FutureAvailabilityState> {
  FutureAvailabilityCubit({
    required GetFutureAvailabilityUseCase getFutureAvailabilityUseCase,
    required AvailabilityRepository repository,
    required StorageService storageService,
  })  : _getFutureAvailabilityUseCase = getFutureAvailabilityUseCase,
        _repository = repository,
        _storageService = storageService,
        super(const FutureAvailabilityState.initial());

  final GetFutureAvailabilityUseCase _getFutureAvailabilityUseCase;
  final AvailabilityRepository _repository;
  final StorageService _storageService;

  Future<void> load({
    required DateTime date,
    required bool isTwoShifts,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    String schoolCode;
    try {
      schoolCode = await _resolveSchoolCode();
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        isRefreshing: false,
        selectedDate: normalizedDate,
        isTwoShifts: isTwoShifts,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
      return;
    }

    // Try cache first.
    final shift = isTwoShifts
        ? FutureAvailabilityShift.twoShifts
        : FutureAvailabilityShift.fullDay;

    final cached = await (_repository is AvailabilityRepositoryWithCache
        ? (_repository as AvailabilityRepositoryWithCache)
            .loadCachedFutureAvailability(
              schoolCode: schoolCode,
              startDate: normalizedDate,
              endDate: normalizedDate,
              shift: shift,
            )
        : Future.value(null));

    if (cached != null && !isClosed) {
      emit(FutureAvailabilityState.loaded(
        grid: cached,
        selectedDate: normalizedDate,
        isTwoShifts: isTwoShifts,
        isFromCache: true,
      ));
      return;
    }

    await refresh(date: normalizedDate, isTwoShifts: isTwoShifts);
  }

  Future<void> refresh({
    required DateTime date,
    required bool isTwoShifts,
  }) async {
    if (state.isRefreshing) return;

    final normalizedDate = DateTime(date.year, date.month, date.day);
    // isTwoShifts=true → TWO_SHIFTS; isTwoShifts=false → FULL_DAY
    final shift = isTwoShifts
        ? FutureAvailabilityShift.twoShifts
        : FutureAvailabilityShift.fullDay;

    emit(state.copyWith(isLoading: state.grid == null, isRefreshing: true, clearError: true));

    try {
      final schoolCode = await _resolveSchoolCode();
      if (_repository is AvailabilityRepositoryWithCache) {
        await (_repository as AvailabilityRepositoryWithCache)
            .invalidateAvailabilityCache(schoolCode: schoolCode);
      }

      // POST recompute first, then GET snapshots.
      await _repository.recomputeFutureAvailability(
        schoolCode: schoolCode,
        startDate: normalizedDate,
        endDate: normalizedDate,
      );

      final grid = await _getFutureAvailabilityUseCase(
        schoolCode: schoolCode,
        startDate: normalizedDate,
        endDate: normalizedDate,
        shift: shift,
      );
      if (isClosed) return;
      emit(FutureAvailabilityState.loaded(
        grid: grid,
        selectedDate: normalizedDate,
        isTwoShifts: isTwoShifts,
        isFromCache: false,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        isRefreshing: false,
        selectedDate: normalizedDate,
        isTwoShifts: isTwoShifts,
        errorMessage: ApiErrorHandler.extractErrorMessage(e),
      ));
    }
  }

  Future<String> _resolveSchoolCode() async {
    final schoolCode = (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();
    if (schoolCode.isEmpty) {
      throw Exception('School code is missing. Please re-login and try again.');
    }
    return schoolCode;
  }
}

class FutureAvailabilityState extends Equatable {
  const FutureAvailabilityState({
    required this.grid,
    required this.selectedDate,
    required this.isTwoShifts,
    required this.isLoading,
    required this.isRefreshing,
    required this.isFromCache,
    this.errorMessage,
  });

  const FutureAvailabilityState.initial()
      : grid = null,
        selectedDate = null,
        isTwoShifts = true,
        isLoading = false,
        isRefreshing = false,
        isFromCache = false,
        errorMessage = null;

  const FutureAvailabilityState.loaded({
    required FutureAvailabilityGrid grid,
    required DateTime selectedDate,
    required bool isTwoShifts,
    required bool isFromCache,
  })  : grid = grid,
        selectedDate = selectedDate,
        isTwoShifts = isTwoShifts,
        isLoading = false,
        isRefreshing = false,
        isFromCache = isFromCache,
        errorMessage = null;

  final FutureAvailabilityGrid? grid;
  final DateTime? selectedDate;
  final bool isTwoShifts;
  final bool isLoading;
  final bool isRefreshing;
  final bool isFromCache;
  final String? errorMessage;

  FutureAvailabilityState copyWith({
    FutureAvailabilityGrid? grid,
    DateTime? selectedDate,
    bool? isTwoShifts,
    bool? isLoading,
    bool? isRefreshing,
    bool? isFromCache,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FutureAvailabilityState(
      grid: grid ?? this.grid,
      selectedDate: selectedDate ?? this.selectedDate,
      isTwoShifts: isTwoShifts ?? this.isTwoShifts,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isFromCache: isFromCache ?? this.isFromCache,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        grid,
        selectedDate,
        isTwoShifts,
        isLoading,
        isRefreshing,
        isFromCache,
        errorMessage,
      ];
}
