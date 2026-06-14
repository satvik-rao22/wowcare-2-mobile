import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/util/attendance_classroom_scope.dart';
import '../../../../core/util/cache_manager.dart';
import '../../../../core/util/classroom_visibility.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/classroom/entities/classroom.dart';
import '../../../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';

part 'classroom_state.dart';

class ClassroomCubit extends Cubit<ClassroomState> {
  ClassroomCubit({
    required GetActiveClassroomsUseCase getActiveClassroomsUseCase,
    required StorageService storageService,
  })  : _getActiveClassroomsUseCase = getActiveClassroomsUseCase,
        _storageService = storageService,
        _cacheManager = CacheManager(storageService),
        super(const ClassroomState.initial());

  final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  final StorageService _storageService;
  final CacheManager _cacheManager;

  String _activeClassroomsCacheKey(
    String schoolCode,
    bool onlyTypeClassroom,
    bool applyAttendanceStaffScope,
  ) {
    return CacheManager.buildCacheKey(
      feature: 'classroom',
      resource: 'active_classrooms_list',
      identifier:
          '${schoolCode.trim()}|onlyClass=$onlyTypeClassroom|staffScope=$applyAttendanceStaffScope',
    );
  }

  Map<String, dynamic> _encodeClassroomsForCache(List<Classroom> classrooms) => {
        'items': classrooms
            .map(
              (e) => <String, dynamic>{'code': e.code, 'name': e.name},
            )
            .toList(),
      };

  List<Classroom> _decodeClassroomsFromCache(Map<String, dynamic>? payload) {
    if (payload == null) return [];
    final raw = payload['items'];
    if (raw is! List) return [];
    final result = <Classroom>[];
    for (final it in raw) {
      if (it is! Map) continue;
      final m = Map<String, dynamic>.from(it);
      final code = (m['code'] ?? '').toString().trim();
      final name = (m['name'] ?? '').toString().trim();
      if (code.isEmpty) continue;
      result.add(Classroom(code: code, name: name.isEmpty ? code : name));
    }
    return result;
  }

  Future<void> loadActiveClassrooms({
    bool force = false,
    bool onlyTypeClassroom = true,
    bool applyAttendanceStaffScope = false,
  }) async {
    if (state.isLoading) return;
    if (!force &&
        state.classrooms.isNotEmpty &&
        state.onlyTypeClassroom == onlyTypeClassroom &&
        state.applyAttendanceStaffScope == applyAttendanceStaffScope) {
      return;
    }

    final schoolCode =
        await _storageService.getString(StorageKeys.schoolCode) ?? '';
    final cacheKey = _activeClassroomsCacheKey(
      schoolCode,
      onlyTypeClassroom,
      applyAttendanceStaffScope,
    );

    var hydratedClassrooms = <Classroom>[];
    if (!force && schoolCode.isNotEmpty) {
      final cached = await _cacheManager.loadCache(cacheKey);
      hydratedClassrooms = _decodeClassroomsFromCache(cached);
      if (hydratedClassrooms.isNotEmpty) {
        hydratedClassrooms.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        if (isClosed) return;
        emit(
          state.copyWith(
            classrooms: hydratedClassrooms,
            isLoading: false,
            errorMessage: null,
            onlyTypeClassroom: onlyTypeClassroom,
            applyAttendanceStaffScope: applyAttendanceStaffScope,
          ),
        );
      }
    }

    try {
      if (hydratedClassrooms.isEmpty && !isClosed) {
        emit(
          state.copyWith(
            isLoading: true,
            errorMessage: null,
            onlyTypeClassroom: onlyTypeClassroom,
            applyAttendanceStaffScope: applyAttendanceStaffScope,
          ),
        );
      }

      final classrooms = await _getActiveClassroomsUseCase(
        schoolCode: schoolCode,
        onlyTypeClassroom: onlyTypeClassroom,
      );
      // Keep legacy "hide Office" behavior only for strict classroom lists.
      // Staff flows call with onlyTypeClassroom=false and must include Office.
      var visibleClassrooms = onlyTypeClassroom
          ? filterSelectableClassrooms(classrooms)
          : classrooms.toList(growable: false);

      if (applyAttendanceStaffScope) {
        final shouldScope = await isAttendanceScopedStaffPersona(
          storage: _storageService,
        );
        if (shouldScope) {
          final allowedCodes = await resolveAttendanceAllowedClassroomCodes(
            storage: _storageService,
          );
          final allowedSet = allowedCodes.map((e) => e.trim()).toSet();
          visibleClassrooms = visibleClassrooms
              .where((c) => allowedSet.contains(c.code.trim()))
              .toList(growable: false);
        }
      }

      visibleClassrooms.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      if (schoolCode.isNotEmpty) {
        await _cacheManager.saveCache(
          cacheKey,
          _encodeClassroomsForCache(visibleClassrooms),
        );
      }

      if (isClosed) return;

      emit(
        state.copyWith(
          classrooms: visibleClassrooms,
          isLoading: false,
          errorMessage: null,
          onlyTypeClassroom: onlyTypeClassroom,
          applyAttendanceStaffScope: applyAttendanceStaffScope,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: hydratedClassrooms.isEmpty ? e.toString() : null,
        ),
      );
    }
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}

