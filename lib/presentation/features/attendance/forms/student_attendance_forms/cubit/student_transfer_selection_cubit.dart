import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/attendance_classroom_scope.dart';
import 'package:wowcare/core/util/cache_manager.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_custom.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_transfer_form_list_usecase.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';

part 'student_transfer_selection_state.dart';

/// ViewModel (Cubit) for [StudentSelectionTransferForm]. See
/// [StudentSignInSelectionCubit] (identical structure, sibling form) for the
/// rationale — deterministic fetches instead of a `BlocBuilder<ClassroomCubit, _>`
/// rebuild race the View can't control. Also replaces the old ad-hoc "derive
/// tag options from whatever the current unfiltered fetch happened to
/// return" with the same school-wide tag catalog the other forms use.
class StudentTransferSelectionCubit
    extends Cubit<StudentTransferSelectionState> {
  StudentTransferSelectionCubit({
    required StorageService storageService,
    required CacheManager cacheManager,
    required GetActiveClassroomsUseCase getActiveClassroomsUseCase,
    required GetTagNameCodeMapForSchoolUseCase
    getTagNameCodeMapForSchoolUseCase,
    required GetStudentTransferFormListUseCase
    getStudentTransferFormListUseCase,
  }) : _storage = storageService,
       _cacheManager = cacheManager,
       _getActiveClassroomsUseCase = getActiveClassroomsUseCase,
       _getTagNameCodeMapForSchoolUseCase = getTagNameCodeMapForSchoolUseCase,
       _getStudentTransferFormListUseCase = getStudentTransferFormListUseCase,
       super(const StudentTransferSelectionState());

  final StorageService _storage;
  final CacheManager _cacheManager;
  final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  final GetTagNameCodeMapForSchoolUseCase _getTagNameCodeMapForSchoolUseCase;
  final GetStudentTransferFormListUseCase _getStudentTransferFormListUseCase;

  String _schoolCode = '';
  List<String> _allowedClassroomCodes = const [];

  void _safeEmit(StudentTransferSelectionState next) {
    if (!isClosed) emit(next);
  }

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

      _allowedClassroomCodes =
          await resolveStudentAttendanceAllowedClassroomCodes(
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
      feature: 'attendance_transfer',
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
    _safeEmit(
      state.copyWith(
        classroomOptions: names,
        classroomCodeByName: {for (final c in scoped) c['name']!: c['code']!},
        classroomNameByCode: {for (final c in scoped) c['code']!: c['name']!},
      ),
    );
  }

  Future<void> _loadTags({bool forceRefresh = false}) async {
    if (_schoolCode.isEmpty) return;

    final cacheKey = CacheManager.buildCacheKey(
      feature: 'attendance_transfer',
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
      _safeEmit(
        state.copyWith(
          filtersMessage: ApiErrorHandler.extractErrorMessage(error),
        ),
      );
    }
  }

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
      final page = await _getStudentTransferFormListUseCase(
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
