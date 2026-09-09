import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/cache_manager.dart';
import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/staff_code_resolver.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/activity/usecases/get_mark_activity_student_list_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/get_nap_start_students_usecase.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_custom.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/presentation/features/activities/utils/activity_filter_metadata_cache.dart';

/// ViewModel (Cubit) for the activity student-selection screen. Owns ALL data
/// access that previously lived in the View: staff classroom scope, classroom
/// + tag metadata, and the mark-activity student list (+ nap-start students).
///
/// MVVM golden rule: no View/UI dependency. Failures are surfaced as state
/// ([filtersMessage] / [studentsError]); the View presents them. Filter
/// selection (classroom/tags/date) stays in the View and is passed into
/// [loadStudents], preserving the original reload choreography.
class ActivityStudentSelectionCubit
    extends Cubit<ActivityStudentSelectionState> {
  ActivityStudentSelectionCubit({
    required StorageService storageService,
    required ApiClient apiClient,
    required GetActiveClassroomsUseCase getActiveClassroomsUseCase,
    required GetTagNameCodeMapForSchoolUseCase
    getTagNameCodeMapForSchoolUseCase,
    required GetNapStartStudentsUseCase getNapStartStudentsUseCase,
    required GetMarkActivityStudentListUseCase
    getMarkActivityStudentListUseCase,
    required StaffRepository staffRepository,
  }) : _storage = storageService,
       _apiClient = apiClient,
       _cacheManager = CacheManager(storageService),
       _getActiveClassroomsUseCase = getActiveClassroomsUseCase,
       _getTagNameCodeMapForSchoolUseCase = getTagNameCodeMapForSchoolUseCase,
       _getNapStartStudentsUseCase = getNapStartStudentsUseCase,
       _getMarkActivityStudentListUseCase = getMarkActivityStudentListUseCase,
       _staffRepository = staffRepository,
       super(const ActivityStudentSelectionState());

  final StorageService _storage;
  final ApiClient _apiClient;
  final CacheManager _cacheManager;
  final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  final GetTagNameCodeMapForSchoolUseCase _getTagNameCodeMapForSchoolUseCase;
  final GetNapStartStudentsUseCase _getNapStartStudentsUseCase;
  final GetMarkActivityStudentListUseCase _getMarkActivityStudentListUseCase;
  final StaffRepository _staffRepository;

  String _schoolCode = '';
  List<String> _allowedClassroomCodes = const [];
  String? _primaryClassroomCode;

  String get primaryClassroomCode => _primaryClassroomCode ?? '';

  /// Emits only while open — mirrors the original `if (!mounted) return` guard,
  /// so navigating away mid-fetch never throws "emit after close".
  void _safeEmit(ActivityStudentSelectionState state) {
    if (!isClosed) emit(state);
  }

  /// Resolves school context + scope, then loads classroom and tag metadata.
  Future<void> initFilters() async {
    _safeEmit(
      state.copyWith(isLoadingFilters: true, clearFiltersMessage: true),
    );
    try {
      _schoolCode = (await _storage.getString(StorageKeys.schoolCode) ?? '')
          .trim();
      if (_schoolCode.isEmpty) {
        _safeEmit(
          state.copyWith(
            isLoadingFilters: false,
            filtersMessage:
                'School code is not set. Please ensure you are logged in and a school is selected.',
          ),
        );
        return;
      }

      final tz = await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: _storage,
        apiClient: _apiClient,
      );
      _safeEmit(state.copyWith(schoolTimeZone: tz));

      await _loadStaffClassroomScope();
      await Future.wait([_loadClassrooms(), _loadTags()]);

      _safeEmit(state.copyWith(isLoadingFilters: false, filtersReady: true));
    } catch (error) {
      _safeEmit(
        state.copyWith(
          isLoadingFilters: false,
          filtersMessage: ApiErrorHandler.extractErrorMessage(error),
        ),
      );
    }
  }

  Future<void> refreshFilters() async {
    if (_schoolCode.isEmpty) return;
    await Future.wait([
      _loadClassrooms(forceRefresh: true),
      _loadTags(forceRefresh: true),
    ]);
  }

  /// Whether the CURRENTLY ACTIVE persona is guardian/parent. Prefers the
  /// single active-persona value RoleCubit itself derives from — a dual-role
  /// account (e.g. STAFF + GUARDIAN in a different school) always has
  /// 'GUARDIAN' somewhere in the full cached roles list regardless of which
  /// persona is active right now, so that list is only a fallback for while
  /// no active persona has been resolved/persisted yet (mirrors
  /// RoleCubit._computeFallbackRole, which this Cubit can't call directly —
  /// no BuildContext here).
  Future<bool> _isActivePersonaGuardian() async {
    final active =
        (await _storage.getString(StorageKeys.activeSchoolRole) ?? '')
            .trim()
            .toUpperCase();
    if (active.isNotEmpty) {
      return active.contains('GUARDIAN') || active.contains('PARENT');
    }
    final roles = (await _storage.getString(StorageKeys.roles) ?? '')
        .toUpperCase();
    return roles.contains('GUARDIAN') || roles.contains('PARENT');
  }

  Future<void> _loadStaffClassroomScope() async {
    if (await _isActivePersonaGuardian()) {
      _allowedClassroomCodes = const [];
      _primaryClassroomCode = null;
      return;
    }

    final staffType = (await _storage.getString(StorageKeys.staffType) ?? '')
        .trim()
        .toUpperCase();
    if (staffType == 'SCHOOL_ADMIN' || staffType == 'ORGANIZATION_ADMIN') {
      _allowedClassroomCodes = const [];
      _primaryClassroomCode = null;
      return;
    }

    List<String> decodeCodes(String raw) {
      if (raw.trim().isEmpty) return <String>[];
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (_) {}
      return <String>[];
    }

    final cached =
        (await _storage.getString(StorageKeys.staffAllowedClassroomCodes) ?? '')
            .trim();
    var allowed = decodeCodes(cached);

    try {
      final staffCode = (await resolveStaffCodeForLoggedInUser()).trim();
      if (staffCode.isNotEmpty) {
        final profile = await _staffRepository.getStaffProfile(
          staffCode: staffCode,
          forEditStaff: true,
        );
        final primary = profile.primaryClassroomCode.trim();
        final profileAllowed = profile.allowedClassroomCodes
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        if (profileAllowed.isNotEmpty) {
          allowed = profileAllowed;
          await _storage.saveString(
            StorageKeys.staffAllowedClassroomCodes,
            jsonEncode(profileAllowed),
          );
        }
        _primaryClassroomCode = primary.isNotEmpty ? primary : null;
      }
    } catch (_) {
      // Non-blocking: fall back to cached allowed codes.
    }

    _allowedClassroomCodes = allowed;
  }

  Future<void> _loadClassrooms({bool forceRefresh = false}) async {
    if (_schoolCode.isEmpty) return;

    final classroomCacheKey = CacheManager.buildCacheKey(
      feature: 'activity',
      resource: 'classrooms',
      identifier: _schoolCode,
    );

    var hydratedFromCache = false;
    if (!forceRefresh) {
      try {
        final cached = await _cacheManager.loadCache(classroomCacheKey);
        if (cached != null && cached['classrooms'] is List) {
          final list = (cached['classrooms'] as List)
              .whereType<Map>()
              .map(
                (e) => <String, String>{
                  'name': (e['name'] ?? '').toString(),
                  'code': (e['code'] ?? '').toString(),
                },
              )
              .where(
                (e) =>
                    e['name']!.trim().isNotEmpty &&
                    e['code']!.trim().isNotEmpty,
              )
              .toList();
          if (list.isNotEmpty) {
            final scoped = _allowedClassroomCodes.isEmpty
                ? list
                : list
                      .where(
                        (c) => _allowedClassroomCodes.contains(
                          (c['code'] ?? '').trim(),
                        ),
                      )
                      .toList();
            _emitClassrooms(
              names: scoped.map((c) => c['name']!).toList(),
              codeByName: {for (final c in scoped) c['name']!: c['code']!},
              nameByCode: {for (final c in scoped) c['code']!: c['name']!},
            );
            hydratedFromCache = true;
          }
        }
      } catch (_) {}
    }

    if (hydratedFromCache &&
        !forceRefresh &&
        _allowedClassroomCodes.isNotEmpty) {
      return;
    }

    try {
      final classrooms = await _getActiveClassroomsUseCase(
        schoolCode: _schoolCode,
        onlyTypeClassroom: true,
      );
      final scoped = _allowedClassroomCodes.isEmpty
          ? classrooms
          : classrooms
                .where((c) => _allowedClassroomCodes.contains(c.code.trim()))
                .toList();

      _emitClassrooms(
        names: scoped.map((c) => c.name).toList(),
        codeByName: {for (final c in scoped) c.name: c.code},
        nameByCode: {for (final c in scoped) c.code: c.name},
      );

      await _cacheManager.saveCache(classroomCacheKey, {
        'classrooms': classrooms
            .map((c) => {'name': c.name, 'code': c.code})
            .toList(),
      });
    } catch (error) {
      _safeEmit(
        state.copyWith(
          filtersMessage: ApiErrorHandler.extractErrorMessage(error),
        ),
      );
    }
  }

  void _emitClassrooms({
    required List<String> names,
    required Map<String, String> codeByName,
    required Map<String, String> nameByCode,
  }) {
    // Default classroom: primary (if allowed and selectable), else top option.
    // If the primary classroom is Office (filtered out of the selectable list)
    // or otherwise unavailable, fall back to the top sorted classroom.
    final primaryCode = (_primaryClassroomCode ?? '').trim();
    final primaryName = primaryCode.isNotEmpty ? nameByCode[primaryCode] : null;
    final defaultName = (primaryName != null && names.contains(primaryName))
        ? primaryName
        : (names.isNotEmpty ? names.first : null);
    _safeEmit(
      state.copyWith(
        classroomOptions: names,
        classroomCodeByName: codeByName,
        classroomNameByCode: nameByCode,
        defaultClassroomName: defaultName,
      ),
    );
  }

  Future<void> _loadTags({bool forceRefresh = false}) async {
    if (_schoolCode.isEmpty) return;
    try {
      final nameCodeMap = await ActivityFilterMetadataCache.loadTagNameCodeMap(
        cacheManager: _cacheManager,
        useCase: _getTagNameCodeMapForSchoolUseCase,
        schoolCode: _schoolCode,
        forceRefresh: forceRefresh,
      );
      _safeEmit(
        state.copyWith(
          tagCodeByName: Map<String, String>.from(nameCodeMap),
          tagOptions: nameCodeMap.keys.toList()..sort(),
        ),
      );
    } catch (error) {
      // Tags are non-critical; surface message once.
      _safeEmit(
        state.copyWith(
          filtersMessage: ApiErrorHandler.extractErrorMessage(error),
        ),
      );
    }
  }

  /// Loads the mark-activity student list for the given filter selection.
  Future<void> loadStudents({
    required String? selectedClassroomName,
    required List<String> selectedTagNames,
    required DateTime date,
  }) async {
    if (_schoolCode.isEmpty) return;

    final selectedClassroomCode =
        (state.classroomCodeByName[selectedClassroomName]?.trim() ?? '');
    final classroomCodes = selectedClassroomCode.isEmpty
        ? (_primaryClassroomCode?.trim().isNotEmpty == true
              ? <String>[_primaryClassroomCode!.trim()]
              : null)
        : <String>[selectedClassroomCode];

    final tagCodes = selectedTagNames
        .map((name) => state.tagCodeByName[name])
        .whereType<String>()
        .toList();

    _safeEmit(
      state.copyWith(isLoadingStudents: true, clearStudentsError: true),
    );
    try {
      final selectedDate = _formatAttendanceDate(date);
      final students = await _getMarkActivityStudentListUseCase(
        attendanceDate: selectedDate,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        selectedClassroomCode: selectedClassroomCode,
      );
      var nappingCodes = <String>{};
      if (selectedClassroomCode.isNotEmpty) {
        try {
          final napStartStudents = await _getNapStartStudentsUseCase(
            classroomCode: selectedClassroomCode,
          );
          nappingCodes = napStartStudents
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toSet();
        } catch (_) {
          // Non-critical: leave napping set empty.
        }
      }

      _safeEmit(
        state.copyWith(
          students: students,
          nappingStudentCodes: nappingCodes,
          isLoadingStudents: false,
          clearStudentsError: true,
        ),
      );
    } catch (error) {
      final message = ApiErrorHandler.extractErrorMessage(error);
      _safeEmit(
        state.copyWith(
          isLoadingStudents: false,
          studentsError: message,
          filtersMessage: message,
        ),
      );
    }
  }

  String _formatAttendanceDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final yyyy = normalized.year.toString().padLeft(4, '0');
    final mm = normalized.month.toString().padLeft(2, '0');
    final dd = normalized.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }
}

class ActivityStudentSelectionState extends Equatable {
  const ActivityStudentSelectionState({
    this.isLoadingFilters = false,
    this.isLoadingStudents = false,
    this.filtersReady = false,
    this.studentsError,
    this.filtersMessage,
    this.classroomOptions = const <String>[],
    this.classroomCodeByName = const <String, String>{},
    this.classroomNameByCode = const <String, String>{},
    this.tagOptions = const <String>[],
    this.tagCodeByName = const <String, String>{},
    this.students = const <StudentAttendanceCustomItem>[],
    this.nappingStudentCodes = const <String>{},
    this.schoolTimeZone = SchoolTimezoneResolver.fallbackTimeZone,
    this.defaultClassroomName,
  });

  final bool isLoadingFilters;
  final bool isLoadingStudents;
  final bool filtersReady;
  final String? studentsError;

  /// One-shot user-facing message (warning snackbar) for load failures.
  final String? filtersMessage;

  final List<String> classroomOptions;
  final Map<String, String> classroomCodeByName;
  final Map<String, String> classroomNameByCode;
  final List<String> tagOptions;
  final Map<String, String> tagCodeByName;
  final List<StudentAttendanceCustomItem> students;
  final Set<String> nappingStudentCodes;
  final String schoolTimeZone;
  final String? defaultClassroomName;

  ActivityStudentSelectionState copyWith({
    bool? isLoadingFilters,
    bool? isLoadingStudents,
    bool? filtersReady,
    String? studentsError,
    bool clearStudentsError = false,
    String? filtersMessage,
    bool clearFiltersMessage = false,
    List<String>? classroomOptions,
    Map<String, String>? classroomCodeByName,
    Map<String, String>? classroomNameByCode,
    List<String>? tagOptions,
    Map<String, String>? tagCodeByName,
    List<StudentAttendanceCustomItem>? students,
    Set<String>? nappingStudentCodes,
    String? schoolTimeZone,
    String? defaultClassroomName,
  }) {
    return ActivityStudentSelectionState(
      isLoadingFilters: isLoadingFilters ?? this.isLoadingFilters,
      isLoadingStudents: isLoadingStudents ?? this.isLoadingStudents,
      filtersReady: filtersReady ?? this.filtersReady,
      studentsError: clearStudentsError
          ? null
          : (studentsError ?? this.studentsError),
      filtersMessage: clearFiltersMessage
          ? null
          : (filtersMessage ?? this.filtersMessage),
      classroomOptions: classroomOptions ?? this.classroomOptions,
      classroomCodeByName: classroomCodeByName ?? this.classroomCodeByName,
      classroomNameByCode: classroomNameByCode ?? this.classroomNameByCode,
      tagOptions: tagOptions ?? this.tagOptions,
      tagCodeByName: tagCodeByName ?? this.tagCodeByName,
      students: students ?? this.students,
      nappingStudentCodes: nappingStudentCodes ?? this.nappingStudentCodes,
      schoolTimeZone: schoolTimeZone ?? this.schoolTimeZone,
      defaultClassroomName: defaultClassroomName ?? this.defaultClassroomName,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    isLoadingFilters,
    isLoadingStudents,
    filtersReady,
    studentsError,
    filtersMessage,
    classroomOptions,
    classroomCodeByName,
    classroomNameByCode,
    tagOptions,
    tagCodeByName,
    students,
    nappingStudentCodes,
    schoolTimeZone,
    defaultClassroomName,
  ];
}
