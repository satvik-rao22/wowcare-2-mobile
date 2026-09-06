import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/attendance/usecases/get_staff_today_sign_in_status_map_usecase.dart';
import '../../../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import '../../../../domain/features/staff_classroom/entities/staff_classroom_item.dart';
import '../../../../domain/features/staff_classroom/usecases/get_manage_staff_list_usecase.dart';
import '../views/filters/designation_display_utils.dart';
import 'assign_staff_selection_state.dart';

/// Drives the roster-selection step of the "Assign staff to classroom" flow:
/// loads the Classroom/Designation filter options and the staff roster
/// (server-filtered by whichever of those is selected), today's sign-in
/// status (staff currently signed in can't be reassigned), free-text search,
/// and the in-progress selection set.
class AssignStaffSelectionCubit extends Cubit<AssignStaffSelectionState> {
  AssignStaffSelectionCubit({
    required GetActiveClassroomsUseCase getActiveClassroomsUseCase,
    required GetManageStaffListUseCase getManageStaffListUseCase,
    required GetStaffTodaySignInStatusMapUseCase
    getStaffTodaySignInStatusMapUseCase,
    required StorageService storageService,
  }) : _getActiveClassroomsUseCase = getActiveClassroomsUseCase,
       _getManageStaffListUseCase = getManageStaffListUseCase,
       _getStaffTodaySignInStatusMapUseCase =
           getStaffTodaySignInStatusMapUseCase,
       _storageService = storageService,
       super(const AssignStaffSelectionState());

  final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  final GetManageStaffListUseCase _getManageStaffListUseCase;
  final GetStaffTodaySignInStatusMapUseCase
  _getStaffTodaySignInStatusMapUseCase;
  final StorageService _storageService;

  /// Backend designation codes (API filter values) — same fixed set as
  /// `StaffFilterScreen`, not derived from whichever staff happen to be
  /// loaded, so every designation is always selectable regardless of who's
  /// currently in the roster.
  static const List<String> _designationCodes = [
    'OWNER',
    'DIRECTOR',
    'ADMIN',
    'ASSISTANT_DIRECTOR',
    'LEAD_TEACHER',
    'ASSOCIATE_TEACHER',
    'ASSISTANT_TEACHER',
    'FLOATER',
  ];

  static final Map<String, String> _labelToDesignationCode = {
    for (final code in _designationCodes)
      formatDesignationForDisplay(code): code,
  };

  String _excludeClassroomCode = '';

  /// Classroom display name -> code, so the (name-based) Classroom dropdown
  /// selection can be sent to the API as `primaryClassroomCodes`.
  Map<String, String> _classroomNameToCode = {};

  Timer? _searchDebounce;

  Future<void> init({required String classroomCode}) async {
    _excludeClassroomCode = classroomCode.trim();
    await _loadFilterOptions();
    await loadStaff();
  }

  /// Loads the full Classroom/Designation option lists once (every active
  /// classroom + the fixed designation set — not derived from a roster
  /// that's naturally incomplete, since this screen excludes staff already
  /// in the target classroom).
  Future<void> _loadFilterOptions() async {
    try {
      final schoolCode = (await _storageService.getString(
        StorageKeys.schoolCode,
      ))?.trim();
      final classrooms = await _getActiveClassroomsUseCase(
        schoolCode: schoolCode ?? '',
        onlyTypeClassroom: false,
      );
      _classroomNameToCode = {
        for (final c in classrooms)
          if (c.name.trim().isNotEmpty) c.name.trim(): c.code.trim(),
      };
      if (isClosed) return;
      emit(
        state.copyWith(
          rooms: _classroomNameToCode.keys.toList()..sort(),
          designations: _labelToDesignationCode.keys.toList()..sort(),
        ),
      );
    } catch (_) {
      // Filter options failing to load shouldn't block the staff fetch
      // below — the dropdowns just stay empty and the user can retry via
      // search.
    }
  }

  /// Fetches the roster with the current Classroom/Designation selections
  /// applied server-side (`primaryClassroomCodes` / `designation` query
  /// params) — re-run whenever either selection changes. Free-text search
  /// stays client-side over this already-filtered result (see
  /// [AssignStaffSelectionState.visibleStaff]).
  Future<void> loadStaff() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.trim().isEmpty) {
        throw 'Missing school code. Please sign in again.';
      }
      if (_excludeClassroomCode.isEmpty) {
        throw 'Missing classroom code.';
      }

      final selectedClassroom = (state.selectedClassroom ?? '').trim();
      final selectedClassroomCode = selectedClassroom.isNotEmpty
          ? _classroomNameToCode[selectedClassroom]
          : null;
      final designationCodes = state.selectedDesignations
          .map((label) => _labelToDesignationCode[label])
          .whereType<String>()
          .toList();

      final roster = await _getManageStaffListUseCase(
        schoolCode: schoolCode,
        excludeClassroomCode: _excludeClassroomCode,
        primaryClassroomCodes: selectedClassroomCode != null
            ? [selectedClassroomCode]
            : null,
        designation: designationCodes.isEmpty ? null : designationCodes,
      );

      final byStaffCode = <String, StaffClassroomItem>{};
      for (final item in roster) {
        final code = item.staffCode.trim();
        if (code.isEmpty) continue;
        byStaffCode[code] = item;
      }
      final rows = byStaffCode.values.toList()
        ..sort((a, b) => a.fullName.compareTo(b.fullName));

      if (isClosed) return;
      emit(state.copyWith(allStaff: rows, isLoading: false));
      unawaited(_loadTodaySignInStatuses(rows));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  /// Fetches today's sign-in status for every loaded staff member in one
  /// batch call — staff currently signed in can't be reassigned to another
  /// classroom.
  Future<void> _loadTodaySignInStatuses(List<StaffClassroomItem> staff) async {
    final codes = staff
        .map((s) => s.staffCode.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (codes.isEmpty) return;
    try {
      final map = await _getStaffTodaySignInStatusMapUseCase(
        staffCodes: codes,
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
    loadStaff();
  }

  void selectDesignations(List<String> labels) {
    emit(state.copyWith(selectedDesignations: labels));
    loadStaff();
  }

  void toggleSelectAll(bool value) {
    final visible = state.visibleStaff
        .where((s) => !state.isStaffSignedIn(s.staffCode))
        .toSet();
    final updated = Set<StaffClassroomItem>.from(state.selectedStaff);
    if (value) {
      updated.addAll(visible);
    } else {
      updated.removeAll(visible);
    }
    emit(state.copyWith(selectedStaff: updated));
  }

  void toggleStaff(StaffClassroomItem staff, bool value) {
    if (state.isStaffSignedIn(staff.staffCode)) return;
    final updated = Set<StaffClassroomItem>.from(state.selectedStaff);
    if (value) {
      updated.add(staff);
    } else {
      updated.remove(staff);
    }
    emit(state.copyWith(selectedStaff: updated));
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
