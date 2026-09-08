import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/domain/features/activity/entities/activity_setting.dart';
import 'package:wowcare/domain/features/activity/usecases/get_activity_type_details_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';

enum ChooseActivityStatus { loading, loaded }

/// ViewModel (Cubit) for the Choose-Activity screen. Owns the classroom
/// activity-settings fetch and the activity-type-details lookup that previously
/// lived in the View's `initState`/`setState`. MVVM golden rule: no View/UI
/// dependency (errors are surfaced as state for the View to present).
class ChooseActivityCubit extends Cubit<ChooseActivityState> {
  ChooseActivityCubit({
    required GetClassroomActivitySettingsUseCase settingsUseCase,
    required GetActivityTypeDetailsUseCase detailsUseCase,
    required this.knownActivityKeys,
  }) : _settingsUseCase = settingsUseCase,
       _detailsUseCase = detailsUseCase,
       super(const ChooseActivityState.loading());

  final GetClassroomActivitySettingsUseCase _settingsUseCase;
  final GetActivityTypeDetailsUseCase _detailsUseCase;

  /// Known UI activity keys (e.g. 'Nap', 'Bathroom') used to map API names to
  /// renderable tiles. Supplied by the View's static icon map.
  final Iterable<String> knownActivityKeys;

  /// Emits only while open — mirrors the original `if (!mounted) return` guard.
  void _safeEmit(ChooseActivityState state) {
    if (!isClosed) emit(state);
  }

  String? _knownKeyByNormalized(String normalizedName) {
    for (final key in knownActivityKeys) {
      if (key.toLowerCase() == normalizedName) return key;
    }
    return null;
  }

  Future<void> loadActivitySettings({required String? classroomCode}) async {
    if (classroomCode == null || classroomCode.trim().isEmpty) {
      _safeEmit(const ChooseActivityState.loaded());
      return;
    }

    _safeEmit(const ChooseActivityState.loading());
    try {
      final List<ActivitySetting> settings = await _settingsUseCase(
        classroomCode: classroomCode,
        refresh: true,
      );

      final enabled = <String>{};
      final multiAllowed = <String>{};
      final visibleKeys = <String>[];
      final seenKeys = <String>{};
      final codeByName = <String, String>{};
      final displayNameByKey = <String, String>{};

      for (final setting in settings) {
        final name = setting.activityTypeName.trim();
        if (name.isEmpty) continue;

        final normalized = name.toLowerCase();
        codeByName[normalized] = setting.activityTypeCode;
        final knownKey = _knownKeyByNormalized(normalized);
        if (knownKey != null) {
          displayNameByKey[knownKey] = name;
        }

        if (setting.isEnabled && knownKey != null) {
          enabled.add(normalized);
          if (!seenKeys.contains(knownKey)) {
            seenKeys.add(knownKey);
            visibleKeys.add(knownKey);
          }
        }
        if (setting.isMultiStudent) {
          multiAllowed.add(normalized);
        }
      }

      _safeEmit(
        ChooseActivityState.loaded(
          enabledActivities: enabled.isEmpty ? null : enabled,
          multiStudentAllowed: multiAllowed.isEmpty ? null : multiAllowed,
          visibleActivityKeys: visibleKeys,
          activityTypeCodeByName: codeByName,
          activityDisplayNameByKey: displayNameByKey,
        ),
      );
    } catch (error) {
      // Keep UI usable with empty list; surface message for the View to show.
      _safeEmit(
        ChooseActivityState.loaded(
          loadErrorMessage: ApiErrorHandler.extractErrorMessage(error),
        ),
      );
    }
  }

  /// Fetches activity-type details (incl. parameters) before navigation so the
  /// next screen can use them. Returns null on success, or an error message.
  Future<String?> fetchActivityTypeDetails(String code) async {
    try {
      await _detailsUseCase(code: code);
      return null;
    } catch (e) {
      return ApiErrorHandler.extractErrorMessage(e);
    }
  }
}

class ChooseActivityState extends Equatable {
  const ChooseActivityState({
    required this.status,
    this.enabledActivities,
    this.multiStudentAllowed,
    this.visibleActivityKeys = const <String>[],
    this.activityTypeCodeByName = const <String, String>{},
    this.activityDisplayNameByKey = const <String, String>{},
    this.loadErrorMessage,
  });

  const ChooseActivityState.loading()
    : this(status: ChooseActivityStatus.loading);

  const ChooseActivityState.loaded({
    Set<String>? enabledActivities,
    Set<String>? multiStudentAllowed,
    List<String> visibleActivityKeys = const <String>[],
    Map<String, String> activityTypeCodeByName = const <String, String>{},
    Map<String, String> activityDisplayNameByKey = const <String, String>{},
    String? loadErrorMessage,
  }) : this(
         status: ChooseActivityStatus.loaded,
         enabledActivities: enabledActivities,
         multiStudentAllowed: multiStudentAllowed,
         visibleActivityKeys: visibleActivityKeys,
         activityTypeCodeByName: activityTypeCodeByName,
         activityDisplayNameByKey: activityDisplayNameByKey,
         loadErrorMessage: loadErrorMessage,
       );

  final ChooseActivityStatus status;

  /// Normalized (lowercase) enabled activity names; null = no classroom-specific list.
  final Set<String>? enabledActivities;

  /// Normalized (lowercase) names allowed for multi-student; null = unspecified.
  final Set<String>? multiStudentAllowed;

  /// Known UI keys to render, in API order.
  final List<String> visibleActivityKeys;

  /// Normalized name -> activity type code.
  final Map<String, String> activityTypeCodeByName;

  /// Known key -> API display name.
  final Map<String, String> activityDisplayNameByKey;

  /// Non-null when settings failed to load (View shows a warning snackbar).
  final String? loadErrorMessage;

  bool get isLoading => status == ChooseActivityStatus.loading;

  @override
  List<Object?> get props => <Object?>[
    status,
    enabledActivities,
    multiStudentAllowed,
    visibleActivityKeys,
    activityTypeCodeByName,
    activityDisplayNameByKey,
    loadErrorMessage,
  ];
}
