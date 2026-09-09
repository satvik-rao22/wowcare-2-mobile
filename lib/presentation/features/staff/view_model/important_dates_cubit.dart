import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/utils/school_timezone_resolver.dart';
import '../../../../domain/features/staff/entities/staff_important_date.dart';
import '../../../../domain/features/staff/usecases/load_cached_important_dates_usecase.dart';
import '../../../../domain/features/staff/usecases/get_important_dates_usecase.dart';
import '../../../../domain/features/staff/usecases/update_important_dates_usecase.dart';

class ImportantDatesCubit extends Cubit<ImportantDatesState> {
  ImportantDatesCubit({
    required GetImportantDatesUseCase getImportantDatesUseCase,
    required UpdateImportantDatesUseCase updateImportantDatesUseCase,
    required LoadCachedImportantDatesUseCase loadCachedImportantDatesUseCase,
    required StorageService storageService,
    required ApiClient apiClient,
  }) : _getImportantDatesUseCase = getImportantDatesUseCase,
       _updateImportantDatesUseCase = updateImportantDatesUseCase,
       _loadCachedImportantDatesUseCase = loadCachedImportantDatesUseCase,
       _storageService = storageService,
       _apiClient = apiClient,
       super(ImportantDatesState.initial());

  final GetImportantDatesUseCase _getImportantDatesUseCase;
  final UpdateImportantDatesUseCase _updateImportantDatesUseCase;
  final LoadCachedImportantDatesUseCase _loadCachedImportantDatesUseCase;
  final StorageService _storageService;
  final ApiClient _apiClient;

  /// Resolves (and caches) the current school's timezone so date
  /// constraints/validation match the school's calendar day rather than the
  /// device's. Keeps [ApiClient] out of the View per Mandate 5 — the View
  /// only needs to know the resolve finished, to re-read
  /// [SchoolTimezoneResolver.lastKnownTimeZone] and rebuild.
  Future<void> warmSchoolTimezone() async {
    try {
      await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: _storageService,
        apiClient: _apiClient,
      );
    } catch (_) {
      // Keep the last-known zone.
    }
  }

  /// Re-entrancy guard: a second [updateImportantDates] call while the first is
  /// still in flight (a double-tap) is ignored, so the cubit enforces
  /// single-flight independently of any UI button-disabling.
  bool _inFlight = false;

  /// Cache-first read of a staff member's important dates.
  ///
  /// Reproduces verbatim the cache-first logic the two important-dates widgets
  /// used to run inline against the repository: when [useCache] is true and a
  /// cached list exists, it is returned as-is (no API hit); otherwise the read
  /// falls through to
  /// the API via [GetImportantDatesUseCase]. On an API failure the [Failure] is
  /// thrown so callers can surface its message exactly as the old fold did.
  Future<List<StaffImportantDate>> fetchImportantDates(
    String staffCode, {
    bool useCache = true,
  }) async {
    if (useCache) {
      final cached = await _loadCachedImportantDatesUseCase(staffCode);
      if (cached != null) {
        return List<StaffImportantDate>.from(cached);
      }
    }

    final result = await _getImportantDatesUseCase(staffCode: staffCode);
    return result.fold(
      (Failure failure) => throw failure,
      (List<StaffImportantDate> dates) => dates,
    );
  }

  Future<void> updateImportantDates({
    required String staffCode,
    required List<StaffImportantDate> dates,
  }) async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      emit(ImportantDatesState.loading());

      final result = await _updateImportantDatesUseCase(
        staffCode: staffCode,
        dates: dates,
      );

      // The widget/route owning this cubit may have been torn down while the
      // update was in flight; skip the emit so we don't mutate a closed cubit.
      if (isClosed) return;

      result.fold(
        (Failure failure) {
          emit(
            ImportantDatesState.error(
              failure.message ?? 'Failed to update important dates',
            ),
          );
        },
        (String message) {
          emit(ImportantDatesState.success(message));
        },
      );
    } finally {
      _inFlight = false;
    }
  }

  void reset() {
    emit(ImportantDatesState.initial());
  }
}

class ImportantDatesState extends Equatable {
  const ImportantDatesState._();

  factory ImportantDatesState.initial() => const _InitialState();
  factory ImportantDatesState.loading() => const _LoadingState();
  factory ImportantDatesState.success(String message) => _SuccessState(message);
  factory ImportantDatesState.error(String message) => _ErrorState(message);

  bool get isLoading => this is _LoadingState;
  bool get isSuccess => this is _SuccessState;
  bool get isError => this is _ErrorState;

  String? get message => this is _SuccessState
      ? (this as _SuccessState).message
      : this is _ErrorState
      ? (this as _ErrorState).message
      : null;

  @override
  List<Object?> get props => [];
}

class _InitialState extends ImportantDatesState {
  const _InitialState() : super._();
}

class _LoadingState extends ImportantDatesState {
  const _LoadingState() : super._();
}

class _SuccessState extends ImportantDatesState {
  const _SuccessState(this.message) : super._();
  final String message;

  @override
  List<Object?> get props => [message];
}

class _ErrorState extends ImportantDatesState {
  const _ErrorState(this.message) : super._();
  final String message;

  @override
  List<Object?> get props => [message];
}
