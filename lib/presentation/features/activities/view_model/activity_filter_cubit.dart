import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/utils/cache_manager.dart';
import 'package:wowcare/domain/features/activity/entities/activity_type_summary.dart';
import 'package:wowcare/domain/features/activity/usecases/get_active_activity_types_for_school_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/data/features/activity/datasources/activity_filter_metadata_cache.dart';

enum ActivityFilterStatus { loading, loaded, error }

/// ViewModel (Cubit) for the activity-filter screen's metadata (tags +
/// activity types). Owns the data access that previously lived in the View's
/// `initState`/`setState`. MVVM golden rule: no View/UI dependency.
class ActivityFilterCubit extends Cubit<ActivityFilterState> {
  ActivityFilterCubit({
    required GetTagNameCodeMapForSchoolUseCase tagMapUseCase,
    required GetActiveActivityTypesForSchoolUseCase activityTypesUseCase,
    required CacheManager cacheManager,
  }) : _tagMapUseCase = tagMapUseCase,
       _activityTypesUseCase = activityTypesUseCase,
       _cacheManager = cacheManager,
       super(const ActivityFilterState.loading());

  final GetTagNameCodeMapForSchoolUseCase _tagMapUseCase;
  final GetActiveActivityTypesForSchoolUseCase _activityTypesUseCase;
  final CacheManager _cacheManager;

  /// Emits only while the cubit is open — mirrors the original View's
  /// `if (!mounted) return` guard, so navigating away mid-fetch is safe.
  void _safeEmit(ActivityFilterState state) {
    if (!isClosed) emit(state);
  }

  Future<void> loadMetadata({required String schoolCode}) async {
    _safeEmit(const ActivityFilterState.loading());
    try {
      // Run tag map + activity types APIs concurrently (as before).
      final tagMapFuture = ActivityFilterMetadataCache.loadTagNameCodeMap(
        cacheManager: _cacheManager,
        useCase: _tagMapUseCase,
        schoolCode: schoolCode,
      );
      final typesFuture =
          ActivityFilterMetadataCache.loadActiveActivityTypesForSchool(
            cacheManager: _cacheManager,
            useCase: _activityTypesUseCase,
            schoolCode: schoolCode,
          );
      final tagMap = await tagMapFuture;
      final types = await typesFuture;

      final tagNames = tagMap.keys.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      final typeNames =
          types
              .map((ActivityTypeSummary s) => s.name.trim())
              .where((n) => n.isNotEmpty)
              .toSet()
              .toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      _safeEmit(
        ActivityFilterState.loaded(
          tagOptions: tagNames,
          activityTypeOptions: typeNames,
        ),
      );
    } catch (e) {
      _safeEmit(ActivityFilterState.error(e.toString()));
    }
  }
}

class ActivityFilterState extends Equatable {
  const ActivityFilterState({
    required this.status,
    this.tagOptions = const <String>[],
    this.activityTypeOptions = const <String>[],
    this.errorMessage,
  });

  const ActivityFilterState.loading()
    : this(status: ActivityFilterStatus.loading);

  const ActivityFilterState.loaded({
    required List<String> tagOptions,
    required List<String> activityTypeOptions,
  }) : this(
         status: ActivityFilterStatus.loaded,
         tagOptions: tagOptions,
         activityTypeOptions: activityTypeOptions,
       );

  const ActivityFilterState.error(String message)
    : this(status: ActivityFilterStatus.error, errorMessage: message);

  final ActivityFilterStatus status;
  final List<String> tagOptions;
  final List<String> activityTypeOptions;
  final String? errorMessage;

  bool get isLoading => status == ActivityFilterStatus.loading;

  @override
  List<Object?> get props => <Object?>[
    status,
    tagOptions,
    activityTypeOptions,
    errorMessage,
  ];
}
