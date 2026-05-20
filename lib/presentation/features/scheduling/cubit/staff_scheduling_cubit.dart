import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_error_handler.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/staff/entities/staff_member.dart';
import '../../../../domain/features/staff/entities/staff_shift.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../../../../domain/features/staff/usecases/get_staff_page_usecase.dart';
import '../../../../domain/features/staff/usecases/get_staff_shifts_usecase.dart';
import '../utils/school_hours_resolver.dart';

part 'staff_scheduling_state.dart';

class StaffSchedulingCubit extends Cubit<StaffSchedulingState> {
  StaffSchedulingCubit({
    required GetStaffPageUseCase getStaffPageUseCase,
    required GetStaffShiftsUseCase getStaffShiftsUseCase,
    required StaffRepository staffRepository,
    required StorageService storageService,
  })  : _getStaffPageUseCase = getStaffPageUseCase,
        _getStaffShiftsUseCase = getStaffShiftsUseCase,
        _staffRepository = staffRepository,
        _storageService = storageService,
        super(StaffSchedulingState.initial());

  final GetStaffPageUseCase _getStaffPageUseCase;
  final GetStaffShiftsUseCase _getStaffShiftsUseCase;
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
    await _loadSchoolHours();
    await _loadAllStaff(selectFirst: true);
  }

  Future<void> refresh() async {
    await _loadSchoolHours();
    await _loadAllStaff(selectFirst: false);
    await _loadShiftsForSelection();
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
      );

      if (isClosed) return;

      final fallbackRoom = staff?.displayClassroomName ?? '';
      final enriched = summary.blocks.isEmpty && fallbackRoom.isNotEmpty
          ? summary
          : StaffShiftDaySummary(
              availableHours: summary.availableHours,
              scheduledHours: summary.scheduledHours,
              unscheduledHours: summary.unscheduledHours,
              blocks: summary.blocks
                  .map(
                    (b) => StaffShiftTimelineBlock(
                      room: b.room.isNotEmpty ? b.room : fallbackRoom,
                      start: b.start,
                      end: b.end,
                      isBreak: b.isBreak,
                    ),
                  )
                  .toList(),
            );

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
    final next = state.selectedDay.add(Duration(days: deltaDays));
    emit(
      state.copyWith(
        selectedDay: DateTime(next.year, next.month, next.day),
      ),
    );
    _applySchoolHoursForSelectedDay();
    _loadShiftsForSelection();
  }
}

extension StaffMemberSchedulingDisplay on StaffMember {
  String get displayClassroomName {
    if (primaryClassroomName.trim().isNotEmpty) {
      return primaryClassroomName.trim();
    }
    final code = primaryClassroomOrFirstAllowed;
    if (code.isEmpty) return '';
    return allowedClassroomNameByCode[code] ?? code;
  }
}
