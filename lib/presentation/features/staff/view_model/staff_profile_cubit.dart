import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';

import '../../../../domain/features/staff/entities/staff_profile.dart';
import '../../../../domain/features/staff/usecases/get_staff_profile_usecase.dart';
import '../../../../domain/features/staff/usecases/load_cached_staff_profile_usecase.dart';
import '../../../../domain/features/student/entities/student_settings.dart';
import '../../../../domain/features/student/usecases/get_student_settings_usecase.dart';

class StaffProfileCubit extends Cubit<StaffProfileState> {
  StaffProfileCubit({
    required GetStaffProfileUseCase getStaffProfileUseCase,
    required LoadCachedStaffProfileUseCase loadCachedStaffProfileUseCase,
    required GetStudentSettingsUseCase getStudentSettingsUseCase,
  }) : _getStaffProfileUseCase = getStaffProfileUseCase,
       _loadCachedStaffProfileUseCase = loadCachedStaffProfileUseCase,
       _getStudentSettingsUseCase = getStudentSettingsUseCase,
       super(const StaffProfileState.initial());

  final GetStaffProfileUseCase _getStaffProfileUseCase;
  final LoadCachedStaffProfileUseCase _loadCachedStaffProfileUseCase;
  final GetStudentSettingsUseCase _getStudentSettingsUseCase;

  /// School-level settings (`GET /api/v1/student/student-settings`) — despite
  /// living under the student domain, [StudentSettings.canStaffEditTheirOwnHealthRecords]
  /// is the school's "Allow Staff Upload Document" toggle, which must also
  /// let a staff member add/edit documents on THEIR OWN profile even without
  /// the generic STAFF module write permission. See [StudentSettings]'s doc.
  Future<StudentSettings> fetchSettings(String schoolCode) {
    return _getStudentSettingsUseCase(schoolCode: schoolCode);
  }

  /// Thin one-shot fetch of a staff profile ENTITY via the use case, for view
  /// call sites that previously read `StaffRepository.getStaffProfile(...)`
  /// directly. Does NOT emit state — it returns the entity for the caller to
  /// consume, preserving the original repository-read behavior exactly.
  /// [forEditStaff] mirrors the repository parameter (default `false`, matching
  /// `StaffRepository.getStaffProfile`).
  Future<StaffProfile> fetchProfile({
    required String staffCode,
    bool forEditStaff = false,
  }) {
    return _getStaffProfileUseCase(
      staffCode: staffCode,
      forEditStaff: forEditStaff,
    );
  }

  Future<void> loadInitial(String staffCode) async {
    // Try cache first
    final cached = await _loadCachedStaffProfileUseCase(
      staffCode,
      forEditStaff: true,
    );

    if (cached != null && !isClosed) {
      emit(StaffProfileState.loaded(profile: cached, isFromCache: true));
      // Stale-while-revalidate: show cached immediately, but still refresh from API
      // so UI fields stay in sync with backend shape changes.
      // ignore: unawaited_futures
      refresh(staffCode);
      return;
    }

    // No cache (or expired) – load from API.
    await refresh(staffCode);
  }

  Future<void> refresh(String staffCode) async {
    if (state.isRefreshing) return;

    emit(
      state.copyWith(
        isLoading: state.profile == null,
        isRefreshing: true,
        errorMessage: null,
      ),
    );

    try {
      // forceRefresh: true — without it, getStaffProfile() serves the same
      // cache entry loadInitial()'s cache-first read just populated (5-minute
      // TTL), so this "revalidate from API" step silently no-op'd instead of
      // picking up a value just changed on the backend.
      final profile = await _getStaffProfileUseCase(
        staffCode: staffCode,
        forceRefresh: true,
      );

      if (isClosed) return;

      emit(StaffProfileState.loaded(profile: profile, isFromCache: false));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }
}

class StaffProfileState extends Equatable {
  const StaffProfileState({
    required this.profile,
    required this.isLoading,
    required this.isRefreshing,
    required this.isFromCache,
    this.errorMessage,
  });

  const StaffProfileState.initial()
    : profile = null,
      isLoading = false,
      isRefreshing = false,
      isFromCache = false,
      errorMessage = null;

  const StaffProfileState.loaded({
    required StaffProfile profile,
    required bool isFromCache,
  }) : profile = profile,
       isLoading = false,
       isRefreshing = false,
       isFromCache = isFromCache,
       errorMessage = null;

  final StaffProfile? profile;
  final bool isLoading;
  final bool isRefreshing;
  final bool isFromCache;
  final String? errorMessage;

  StaffProfileState copyWith({
    StaffProfile? profile,
    bool? isLoading,
    bool? isRefreshing,
    bool? isFromCache,
    String? errorMessage,
  }) {
    return StaffProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isFromCache: isFromCache ?? this.isFromCache,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    profile,
    isLoading,
    isRefreshing,
    isFromCache,
    errorMessage,
  ];
}
