import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/attendance/usecases/get_student_today_sign_in_status_map_usecase.dart';
import '../../../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import '../../../../domain/features/student/entities/student.dart';
import '../../../../domain/features/student/usecases/get_student_page_usecase.dart';
import '../../../../domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'assign_student_selection_state.dart';

/// Drives the roster-selection step of the "Assign students to classroom"
/// flow: loads the Classroom/Tags filter options and the student roster
/// (server-filtered by whichever of those is selected, paginated), today's
/// sign-in status (students currently signed in can't be reassigned),
/// free-text search, and the in-progress selection set.
class AssignStudentSelectionCubit extends Cubit<AssignStudentSelectionState> {
  AssignStudentSelectionCubit({
    required GetActiveClassroomsUseCase getActiveClassroomsUseCase,
    required GetStudentPageUseCase getStudentPageUseCase,
    required GetTagNameCodeMapForSchoolUseCase
    getTagNameCodeMapForSchoolUseCase,
    required GetStudentTodaySignInStatusMapUseCase
    getStudentTodaySignInStatusMapUseCase,
    required StorageService storageService,
  }) : _getActiveClassroomsUseCase = getActiveClassroomsUseCase,
       _getStudentPageUseCase = getStudentPageUseCase,
       _getTagNameCodeMapForSchoolUseCase = getTagNameCodeMapForSchoolUseCase,
       _getStudentTodaySignInStatusMapUseCase =
           getStudentTodaySignInStatusMapUseCase,
       _storageService = storageService,
       super(const AssignStudentSelectionState());

  final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  final GetStudentPageUseCase _getStudentPageUseCase;
  final GetTagNameCodeMapForSchoolUseCase _getTagNameCodeMapForSchoolUseCase;
  final GetStudentTodaySignInStatusMapUseCase
  _getStudentTodaySignInStatusMapUseCase;
  final StorageService _storageService;

  static const int _pageSize = 200;

  String _targetClassroomCode = '';

  /// Classroom display name -> code, so the (name-based) Classroom dropdown
  /// selection can be sent to the API as `classroomCodes`.
  Map<String, String> _classroomNameToCode = {};

  /// Tag display name -> code, for the `tagCodes` query param.
  Map<String, String> _tagNameToCode = {};

  /// Every classroom code except the target — the default `classroomCodes`
  /// query when no specific Classroom filter is selected.
  List<String> _availableClassroomCodes = [];

  Timer? _searchDebounce;

  Future<void> init({required String classroomCode}) async {
    _targetClassroomCode = classroomCode.trim();
    emit(state.copyWith(excludeClassroomCode: _targetClassroomCode));
    await _loadFilterOptions();
    await loadStudents();
  }

  /// Loads the full Classroom/Tags option lists once (every active
  /// classroom except the target, and the school's full tag catalog — not
  /// derived from whichever students the first fetch happens to return),
  /// then does the first student fetch.
  Future<void> _loadFilterOptions() async {
    try {
      final schoolCode = (await _storageService.getString(
        StorageKeys.schoolCode,
      ))?.trim();

      final activeClassrooms = await _getActiveClassroomsUseCase(
        schoolCode: schoolCode ?? '',
        onlyTypeClassroom: true,
      );
      final availableClassrooms = activeClassrooms
          .where((classroom) => classroom.code != _targetClassroomCode)
          .toList();
      _classroomNameToCode = {
        for (final c in availableClassrooms)
          if (c.name.trim().isNotEmpty) c.name.trim(): c.code.trim(),
      };
      _availableClassroomCodes = availableClassrooms
          .map((c) => c.code)
          .toList();

      // Full school tag catalog — not just the tags present among the
      // currently loaded students, which would silently hide any tag no
      // student outside the target classroom happens to have right now.
      final tagCatalog = await _getTagNameCodeMapForSchoolUseCase(
        schoolCode: schoolCode ?? '',
      );
      _tagNameToCode = tagCatalog;

      if (isClosed) return;
      emit(
        state.copyWith(
          rooms: _classroomNameToCode.keys.toList()..sort(),
          tags: _tagNameToCode.keys.toList()..sort(),
        ),
      );
    } catch (_) {
      // Filter options failing to load shouldn't block the student fetch
      // below — the dropdowns just stay empty and the user can retry via
      // search.
    }
  }

  /// Fetches students with the current Classroom/Tags selections applied
  /// server-side (`classroomCodes` / `tagCodes` query params) — re-run
  /// whenever either selection changes. Free-text search stays client-side
  /// over this already-filtered result (see
  /// [AssignStudentSelectionState.visibleStudents]).
  Future<void> loadStudents() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.trim().isEmpty) {
        throw 'School code is not set. Please sign in and select a school.';
      }

      final selectedClassroom = (state.selectedClassroom ?? '').trim();
      final selectedClassroomCode = selectedClassroom.isNotEmpty
          ? _classroomNameToCode[selectedClassroom]
          : null;
      final classroomCodes = selectedClassroomCode != null
          ? [selectedClassroomCode]
          : _availableClassroomCodes;

      final tagCodes = state.selectedTags
          .map((label) => _tagNameToCode[label])
          .whereType<String>()
          .toList();

      final fetchedStudents = <Student>[];
      int page = 0;
      bool hasMore = true;
      while (hasMore) {
        final studentPage = await _getStudentPageUseCase(
          schoolCode: schoolCode,
          page: page,
          size: _pageSize,
          status: 'ACTIVE',
          classroomCodes: classroomCodes,
          tagCodes: tagCodes.isEmpty ? null : tagCodes,
        );
        fetchedStudents.addAll(studentPage.items);
        hasMore = studentPage.hasMore;
        page += 1;
      }

      if (isClosed) return;
      emit(state.copyWith(allStudents: fetchedStudents, isLoading: false));
      unawaited(_loadTodaySignInStatuses(fetchedStudents));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  /// Fetches today's sign-in status for every loaded student in one batch
  /// call — students currently signed in can't be reassigned to another
  /// classroom.
  Future<void> _loadTodaySignInStatuses(List<Student> students) async {
    final codes = students
        .map((s) => s.code.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (codes.isEmpty) return;
    try {
      final map = await _getStudentTodaySignInStatusMapUseCase(
        studentCodes: codes,
      );
      if (isClosed) return;
      emit(state.copyWith(todayStatusByCode: map));
    } catch (_) {
      // Non-critical: leave statuses empty so nothing is incorrectly
      // disabled if the status check itself fails.
    }
  }

  /// Debounced so the visible list only re-filters once the user pauses
  /// typing.
  void onSearchChanged(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (isClosed) return;
      emit(state.copyWith(searchText: text));
    });
  }

  void selectClassroom(String? name) {
    emit(state.copyWith(selectedClassroom: name ?? ''));
    loadStudents();
  }

  void selectTags(List<String> labels) {
    emit(state.copyWith(selectedTags: labels));
    loadStudents();
  }

  void toggleSelectAll(bool value) {
    final visible = state.visibleStudents
        .where((s) => !state.isStudentSignedIn(s.code))
        .toSet();
    final updated = Set<Student>.from(state.selectedStudents);
    if (value) {
      updated.addAll(visible);
    } else {
      updated.removeAll(visible);
    }
    emit(state.copyWith(selectedStudents: updated));
  }

  void toggleStudent(Student student, bool value) {
    if (state.isStudentSignedIn(student.code)) return;
    final updated = Set<Student>.from(state.selectedStudents);
    if (value) {
      updated.add(student);
    } else {
      updated.remove(student);
    }
    emit(state.copyWith(selectedStudents: updated));
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
