import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_error_handler.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import '../../../../domain/features/staff/entities/staff_member.dart';
import '../../../../domain/features/staff/entities/staff_shift.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../../../../domain/features/staff/usecases/get_staff_page_usecase.dart';
import '../../../../domain/features/staff/usecases/get_staff_shifts_usecase.dart';
import '../utils/classroom_name_resolver.dart';
import '../utils/school_hours_resolver.dart';

part 'staff_scheduling_state.dart';

class StaffSchedulingCubit extends Cubit<StaffSchedulingState> {
  StaffSchedulingCubit({
    required GetStaffPageUseCase getStaffPageUseCase,
    required GetStaffShiftsForDayUseCase getStaffShiftsUseCase,
    required GetActiveClassroomsUseCase getActiveClassroomsUseCase,
    required StaffRepository staffRepository,
    required StorageService storageService,
  })  : _getStaffPageUseCase = getStaffPageUseCase,
        _getStaffShiftsUseCase = getStaffShiftsUseCase,
        _getActiveClassroomsUseCase = getActiveClassroomsUseCase,
        _staffRepository = staffRepository,
        _storageService = storageService,
        super(StaffSchedulingState.initial());

  final GetStaffPageUseCase _getStaffPageUseCase;
  final GetStaffShiftsForDayUseCase _getStaffShiftsUseCase;
  final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  final StaffRepository _staffRepository;
  final StorageService _storageService;

  static const int _staffPageSize = 100;

  String? _schoolCode;
  String? _organizationCode;
  SchoolHoursResolver? _schoolHoursResolver;

  Future<String> _resolveSchoolCode() async {
    if (_schoolCode != null) return _schoolCode!;
    _schoolCode = await _storageService.getString(StorageKeys.schoolCode) ?? '';
    return _schoolCode!;
  }

  Future<String> _resolveOrganizationCode() async {
    if (_organizationCode != null) return _organizationCode!;
    _organizationCode =
        await _storageService.getString(StorageKeys.organizationCode) ?? '';
    return _organizationCode!;
  }

  Future<void> loadInitial() async {
    await Future.wait([
      _loadSchoolHours(),
      _loadClassroomNames(),
    ]);
    await _loadAllStaff(selectFirst: true);
  }

  Future<void> refresh() async {
    await Future.wait([
      _loadSchoolHours(),
      _loadClassroomNames(),
    ]);
    await _loadAllStaff(selectFirst: false);
    await _loadShiftsForSelection();
  }

  Future<void> _loadClassroomNames() async {
    try {
      final schoolCode = await _resolveSchoolCode();
      if (schoolCode.isEmpty) return;

      final classrooms = await _getActiveClassroomsUseCase(
        schoolCode: schoolCode,
        onlyTypeClassroom: false,
      );
      final map = <String, String>{};
      for (final c in classrooms) {
        final code = c.code.trim();
        if (code.isEmpty) continue;
        final name = c.name.trim();
        map[code] = name.isNotEmpty ? name : code;
      }
      if (isClosed) return;
      emit(state.copyWith(classroomNamesByCode: map));
      _reapplyShiftSummaryLabels();
    } catch (_) {
      // Non-fatal: fall back to staff API / codes when lookup fails.
    }
  }

  void _mergeClassroomNamesFromStaff(List<StaffMember> staff) {
    if (staff.isEmpty) return;
    final merged = Map<String, String>.from(state.classroomNamesByCode);
    for (final member in staff) {
      final primaryCode = member.primaryClassroomCode.trim();
      final primaryName = member.primaryClassroomName.trim();
      if (primaryCode.isNotEmpty && primaryName.isNotEmpty) {
        merged[primaryCode] = primaryName;
      }
      member.allowedClassroomNameByCode.forEach((code, name) {
        final c = code.trim();
        final n = name.trim();
        if (c.isNotEmpty && n.isNotEmpty) merged[c] = n;
      });
    }
    emit(state.copyWith(classroomNamesByCode: merged));
    _reapplyShiftSummaryLabels();
  }

  StaffShiftDaySummary _labelShiftSummary(
    StaffShiftDaySummary summary,
    StaffMember? staff,
  ) {
    final resolver = state.classroomResolver;
    final fallbackRoom =
        staff != null ? resolver.resolveForStaff(staff) : '';

    return StaffShiftDaySummary(
      availableHours: summary.availableHours,
      scheduledHours: summary.scheduledHours,
      unscheduledHours: summary.unscheduledHours,
      blocks: summary.blocks
          .map(
            (b) => StaffShiftTimelineBlock(
              room: b.isBreak
                  ? b.room
                  : (b.room.isNotEmpty
                      ? resolver.resolveShiftRoom(b.room)
                      : fallbackRoom),
              start: b.start,
              end: b.end,
              isBreak: b.isBreak,
            ),
          )
          .toList(),
    );
  }

  void _reapplyShiftSummaryLabels() {
    if (state.shiftSummary.blocks.isEmpty) return;
    final labeled = _labelShiftSummary(
      state.shiftSummary,
      state.selectedStaff,
    );
    emit(state.copyWith(shiftSummary: labeled));
  }

  Future<void> _loadSchoolHours() async {
    emit(state.copyWith(isLoadingSchoolHours: true, clearError: true));

    try {
      final schoolCode = await _resolveSchoolCode();
      if (schoolCode.isEmpty) {
        emit(
          state.copyWith(
            isLoadingSchoolHours: false,
            clearSchoolHours: true,
            hasSchoolHoursForDay: false,
          ),
        );
        _applySchoolHoursForSelectedDay();
        return;
      }

      final days =
          await _staffRepository.getSchoolRegularSchedules(
        schoolCode: schoolCode,
      );
      _schoolHoursResolver = SchoolHoursResolver.fromDays(days);
      if (isClosed) return;

      emit(state.copyWith(isLoadingSchoolHours: false));
      _applySchoolHoursForSelectedDay();
    } catch (e) {
      if (isClosed) return;
      _schoolHoursResolver = null;
      emit(
        state.copyWith(
          isLoadingSchoolHours: false,
          clearSchoolHours: true,
          hasSchoolHoursForDay: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  void _applySchoolHoursForSelectedDay() {
    final resolver = _schoolHoursResolver;
    final hours = resolver?.hoursFor(state.selectedDay);

    if (hours == null) {
      emit(
        state.copyWith(
          clearSchoolHours: true,
          hasSchoolHoursForDay: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        schoolStartTime: hours.startTime,
        schoolEndTime: hours.endTime,
        hasSchoolHoursForDay: true,
      ),
    );
  }

  Future<void> _loadAllStaff({required bool selectFirst}) async {
    emit(
      state.copyWith(
        isLoadingStaff: true,
        clearError: true,
      ),
    );

    try {
      final organizationCode = await _resolveOrganizationCode();
      final schoolCode = await _resolveSchoolCode();

      if (organizationCode.isEmpty || schoolCode.isEmpty) {
        emit(
          state.copyWith(
            isLoadingStaff: false,
            errorMessage: 'School context is missing. Please sign in again.',
          ),
        );
        return;
      }

      final allStaff = <StaffMember>[];
      var page = 0;
      var hasMore = true;

      while (hasMore) {
        final result = await _getStaffPageUseCase(
          organizationCode: organizationCode,
          schoolCode: schoolCode,
          page: page,
          size: _staffPageSize,
          status: 'ACTIVE',
        );
        allStaff.addAll(result.items);
        hasMore = result.hasMore;
        page++;
        if (isClosed) return;
      }

      allStaff.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      String? nextCode = state.selectedStaffCode;
      if (selectFirst && allStaff.isNotEmpty) {
        nextCode = allStaff.first.code;
      } else if (nextCode != null &&
          !allStaff.any((s) => s.code == nextCode)) {
        nextCode = allStaff.isNotEmpty ? allStaff.first.code : null;
      }

      emit(
        state.copyWith(
          staffList: allStaff,
          selectedStaffCode: nextCode,
          clearSelectedStaffCode: nextCode == null,
          isLoadingStaff: false,
        ),
      );

      _mergeClassroomNamesFromStaff(allStaff);

      if (nextCode != null) {
        await _loadShiftsForSelection();
      } else {
        emit(
          state.copyWith(
            shiftSummary: StaffShiftDaySummary.empty,
            isLoadingShifts: false,
          ),
        );
      }
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoadingStaff: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _loadShiftsForSelection() async {
    final staffCode = state.selectedStaffCode;
    if (staffCode == null || staffCode.isEmpty) {
      emit(
        state.copyWith(
          shiftSummary: StaffShiftDaySummary.empty,
          isLoadingShifts: false,
        ),
      );
      return;
    }

    emit(state.copyWith(isLoadingShifts: true, clearError: true));

    try {
      final organizationCode = await _resolveOrganizationCode();
      final schoolCode = await _resolveSchoolCode();
      final staff = state.selectedStaff;
      final classroomCode = staff?.primaryClassroomCode;

      final summary = await _getStaffShiftsUseCase(
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        staffCode: staffCode,
        date: state.selectedDay,
        classroomCode:
            classroomCode != null && classroomCode.isNotEmpty
                ? classroomCode
                : null,
        classroomNamesByCode: state.classroomNamesByCode,
      );

      if (isClosed) return;

      final enriched = _labelShiftSummary(summary, staff);

      emit(
        state.copyWith(
          shiftSummary: enriched,
          isLoadingShifts: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoadingShifts: false,
          shiftSummary: StaffShiftDaySummary.empty,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  void selectStaffByName(String? name) {
    if (name == null || name.isEmpty || name == 'Select Staff') {
      emit(
        state.copyWith(
          clearSelectedStaffCode: true,
          shiftSummary: StaffShiftDaySummary.empty,
        ),
      );
      return;
    }

    StaffMember? match;
    for (final s in state.staffList) {
      if (s.name == name) {
        match = s;
        break;
      }
    }
    if (match == null) return;

    emit(state.copyWith(selectedStaffCode: match.code));
    _loadShiftsForSelection();
  }

  void shiftSelectedDay(int deltaDays) {
    selectDay(state.selectedDay.add(Duration(days: deltaDays)));
  }

  void selectDay(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    emit(state.copyWith(selectedDay: normalized));
    _applySchoolHoursForSelectedDay();
    _loadShiftsForSelection();
  }
}
