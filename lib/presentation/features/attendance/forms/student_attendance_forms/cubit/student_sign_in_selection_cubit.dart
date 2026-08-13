import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/attendance_classroom_scope.dart';
import 'package:wowcare/core/util/cache_manager.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_custom.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_in_form_list_usecase.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';

part 'student_sign_in_selection_state.dart';

/// ViewModel (Cubit) for [StudentSelectionSignInForm]. Owns filter metadata
/// (classroom/tag options, scoped like the Activities "mark activity" screen)
/// and the sign-in candidate list itself — the View keeps only UI-only state
/// (search text, current selections, which rows are checked).
///
/// Modeled directly on `ActivityStudentSelectionCubit`: fetch calls here are
/// deterministic and independently testable, instead of being driven by a
/// `BlocBuilder<ClassroomCubit, _>` rebuild race the View can't control.
class StudentSignInSelectionCubit extends Cubit<StudentSignInSelectionState> {
  StudentSignInSelectionCubit({
    required StorageService storageService,
    required CacheManager cacheManager,
    required GetActiveClassroomsUseCase getActiveClassroomsUseCase,
    required GetTagNameCodeMapForSchoolUseCase
    getTagNameCodeMapForSchoolUseCase,
    required GetStudentSignInFormListUseCase getStudentSignInFormListUseCase,
  }) : _storage = storageService,
       _cacheManager = cacheManager,
       _getActiveClassroomsUseCase = getActiveClassroomsUseCase,
       _getTagNameCodeMapForSchoolUseCase = getTagNameCodeMapForSchoolUseCase,
       _getStudentSignInFormListUseCase = getStudentSignInFormListUseCase,
       super(const StudentSignInSelectionState());

  final StorageService _storage;
  final CacheManager _cacheManager;
  final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  final GetTagNameCodeMapForSchoolUseCase _getTagNameCodeMapForSchoolUseCase;
  final GetStudentSignInFormListUseCase _getStudentSignInFormListUseCase;

  String _schoolCode = '';
  List<String> _allowedClassroomCodes = const [];
  String? _primaryClassroomCode;

  /// Emits only while open, so navigating away mid-fetch never throws "emit
  /// after close".
  void _safeEmit(StudentSignInSelectionState next) {
    if (!isClosed) emit(next);
  }

  /// Resolves school + staff scope, then loads classroom and tag metadata.
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

      // Relaxes to unscoped for admin/parent personas and for scoped
      // teachers when the school allows cross-class attendance — matches
      // the classroom filter's prior ClassroomCubit-based behavior exactly.
      _allowedClassroomCodes =
          await resolveStudentAttendanceAllowedClassroomCodes(
            storage: _storage,
          );
      // Null for admin/parent personas; a scoped teacher's home classroom
      // otherwise — used to pre-select the classroom filter below.
      _primaryClassroomCode = await resolveStaffPrimaryClassroomCode(
        storage: _storage,
      );

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

  Future<void> _loadClassrooms({bool forceRefresh = false}) async {
    if (_schoolCode.isEmpty) return;

    final cacheKey = CacheManager.buildCacheKey(
      feature: 'attendance_sign_in',
      resource: 'classrooms',
      identifier: _schoolCode,
    );

    if (!forceRefresh) {
      try {
        final cached = await _cacheManager.loadCache(cacheKey);
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
            _emitClassrooms(list);
          }
        }
      } catch (_) {
        // Fall through to the network fetch below.
      }
    }

    try {
      final classrooms = await _getActiveClassroomsUseCase(
        schoolCode: _schoolCode,
        onlyTypeClassroom: true,
      );
      final raw = classrooms
          .map((c) => {'name': c.name, 'code': c.code})
          .toList();
      _emitClassrooms(raw);
      await _cacheManager.saveCache(cacheKey, {'classrooms': raw});
    } catch (error) {
      _safeEmit(
        state.copyWith(
          filtersMessage: ApiErrorHandler.extractErrorMessage(error),
        ),
      );
    }
  }

  void _emitClassrooms(List<Map<String, String>> raw) {
    final scoped = _allowedClassroomCodes.isEmpty
        ? raw
        : raw
              .where((c) => _allowedClassroomCodes.contains((c['code'] ?? '')))
              .toList();
    final names = scoped.map((c) => c['name']!).toList();
    final primaryCode = (_primaryClassroomCode ?? '').trim();
    final primaryName = primaryCode.isEmpty
        ? null
        : scoped
              .where((c) => c['code'] == primaryCode)
              .map((c) => c['name'])
              .firstOrNull;
    _safeEmit(
      state.copyWith(
        classroomOptions: names,
        classroomCodeByName: {for (final c in scoped) c['name']!: c['code']!},
        classroomNameByCode: {for (final c in scoped) c['code']!: c['name']!},
        defaultClassroomName: primaryName,
      ),
    );
  }

  Future<void> _loadTags({bool forceRefresh = false}) async {
    if (_schoolCode.isEmpty) return;

    final cacheKey = CacheManager.buildCacheKey(
      feature: 'attendance_sign_in',
      resource: 'tag_name_code_map',
      identifier: _schoolCode,
    );

    if (!forceRefresh) {
      try {
        final cached = await _cacheManager.loadCache(
          cacheKey,
          validFor: StorageKeys.cacheValidDuration,
        );
        if (cached != null && cached['entries'] is List) {
          final out = <String, String>{};
          for (final raw in (cached['entries'] as List).whereType<Map>()) {
            final name = (raw['name'] ?? '').toString().trim();
            final code = (raw['code'] ?? '').toString().trim();
            if (name.isNotEmpty && code.isNotEmpty) out[name] = code;
          }
          if (out.isNotEmpty) {
            _safeEmit(
              state.copyWith(
                tagCodeByName: out,
                tagOptions: out.keys.toList()..sort(),
              ),
            );
          }
        }
      } catch (_) {
        // Fall through to the network fetch below.
      }
    }

    try {
      final map = await _getTagNameCodeMapForSchoolUseCase(
        schoolCode: _schoolCode,
      );
      _safeEmit(
        state.copyWith(
          tagCodeByName: Map<String, String>.from(map),
          tagOptions: map.keys.toList()..sort(),
        ),
      );
      await _cacheManager.saveCache(cacheKey, {
        'entries': map.entries
            .map((e) => {'name': e.key, 'code': e.value})
            .toList(),
      });
    } catch (error) {
      // Tags are non-critical; surface message once.
      _safeEmit(
        state.copyWith(
          filtersMessage: ApiErrorHandler.extractErrorMessage(error),
        ),
      );
    }
  }

  /// Loads the sign-in candidate list for the given date + filter selection.
  /// Selection is passed in by name (dropdown state stays in the View); this
  /// resolves names to codes using the metadata already loaded above.
  Future<void> loadStudents({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String> selectedClassroomNames = const [],
    List<String> selectedTagNames = const [],
    String? search,
  }) async {
    final classroomCodes = selectedClassroomNames
        .map((name) => state.classroomCodeByName[name])
        .whereType<String>()
        .toList();
    final tagCodes = selectedTagNames
        .map((name) => state.tagCodeByName[name])
        .whereType<String>()
        .toList();

    _safeEmit(
      state.copyWith(isLoadingStudents: true, clearStudentsError: true),
    );
    try {
      final page = await _getStudentSignInFormListUseCase(
        fromAttendanceDate: fromAttendanceDate,
        toAttendanceDate: toAttendanceDate,
        classroomCodes: classroomCodes.isEmpty ? null : classroomCodes,
        tagCodes: tagCodes.isEmpty ? null : tagCodes,
        search: (search != null && search.trim().isNotEmpty)
            ? search.trim()
            : null,
        page: 0,
        size: 200,
      );

      var items = page.items;
      // Safety net: enforce the classroom/tag filters client-side too, in
      // case the backend returns rows outside the requested scope.
      if (classroomCodes.isNotEmpty) {
        final allowed = classroomCodes.toSet();
        items = items.where((i) => allowed.contains(i.classroomCode)).toList();
      }
      if (tagCodes.isNotEmpty) {
        final allowed = tagCodes.toSet();
        items = items.where((i) => i.tagCodes.any(allowed.contains)).toList();
      }

      _safeEmit(
        state.copyWith(
          students: items,
          isLoadingStudents: false,
          clearStudentsError: true,
        ),
      );
    } catch (error) {
      _safeEmit(
        state.copyWith(
          isLoadingStudents: false,
          studentsError: ApiErrorHandler.extractErrorMessage(error),
        ),
      );
    }
  }
}
