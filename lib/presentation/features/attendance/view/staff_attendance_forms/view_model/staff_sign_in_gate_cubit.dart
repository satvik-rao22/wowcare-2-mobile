import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/server_time_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_sign_in_form_list_usecase.dart';

import '../../../model/staff_entity.dart';
import 'staff_sign_in_gate_state.dart';

/// Outcome of [StaffSignInGateCubit.resolveExpectedToday] — the View uses it to
/// decide whether to show the unexpected-sign-in dialog. [superseded] is true
/// when a newer resolve started before this one finished (the token-cancellation
/// the widget used to do inline).
typedef GateResolveOutcome = ({
  bool superseded,
  bool needsDialog,
  List<String> unexpectedNames,
});

/// Owns the staff sign-in form's non-submit business logic (persona/admin flags,
/// current staff code, date/time, working staff list, and the unexpected-sign-in
/// gate DATA flow). The View keeps the dialog + navigation and passes the
/// RoleCubit-resolved [isStaffAdminPersona] in (it needs BuildContext); this
/// cubit never touches BuildContext.
class StaffSignInGateCubit extends Cubit<StaffSignInGateState> {
  StaffSignInGateCubit({
    required GetStaffSignInFormListUseCase getStaffSignInFormList,
    required StorageService storageService,
    required ApiClient apiClient,
  }) : _getStaffSignInFormList = getStaffSignInFormList,
       _storage = storageService,
       _apiClient = apiClient,
       super(
         StaffSignInGateState(
           selectedDate: ServerTimeService.instance.now(),
           selectedTime: ServerTimeService.instance.timeOfDayNow(),
         ),
       );

  final GetStaffSignInFormListUseCase _getStaffSignInFormList;
  final StorageService _storage;
  final ApiClient _apiClient;

  int _gateToken = 0;

  /// Step 1 of the widget's _initializeFormData: resolve the current staff code
  /// (kiosk staff code takes precedence, else storage).
  Future<void> loadCurrentStaffCode({
    required bool isKiosk,
    String? kioskStaffCode,
  }) async {
    final code = isKiosk && kioskStaffCode != null
        ? kioskStaffCode.trim()
        : (await _storage.getString(StorageKeys.staffCode))?.trim() ?? '';
    if (isClosed) return;
    emit(state.copyWith(currentStaffCode: code.isNotEmpty ? code : null));
  }

  /// Step 2: school zone + date/time + admin flags + selection restrictions.
  /// [isStaffAdminPersona] is resolved by the View (RoleCubit needs context).
  Future<void> initializeSchoolAndPersona({
    required bool isStaffAdminPersona,
    required StaffEntity? staff,
    required List<StaffEntity>? staffList,
  }) async {
    final z = await resolveFreshSchoolTimeZone();
    if (isClosed) return;
    emit(state.copyWith(schoolIana: z));
    setCurrentDateTime();

    final isAdminRole = await _checkIsAdminRole();
    if (isClosed) return;
    emit(
      state.copyWith(
        isStaffAdminPersona: isStaffAdminPersona,
        isAdminRole: isAdminRole,
      ),
    );

    _applyStaffSelectionRestrictions(
      isAdmin: isAdminRole,
      staff: staff,
      staffList: staffList,
    );
  }

  Future<bool> _checkIsAdminRole() async {
    final role = (await _storage.getString(StorageKeys.activeSchoolRole) ?? '')
        .trim()
        .toUpperCase();
    return role.contains('DIRECTOR') ||
        role.contains('ADMIN') ||
        role.contains('PRINCIPAL');
  }

  void _applyStaffSelectionRestrictions({
    required bool isAdmin,
    required StaffEntity? staff,
    required List<StaffEntity>? staffList,
  }) {
    if (isAdmin) {
      if (staffList != null && staffList.isNotEmpty) {
        emit(state.copyWith(selectedStaff: List<StaffEntity>.from(staffList)));
      } else if (staff != null) {
        emit(state.copyWith(selectedStaff: <StaffEntity>[staff]));
      }
    } else {
      final code = state.currentStaffCode;
      StaffEntity? currentStaff;
      if (code != null && code.isNotEmpty && staffList != null) {
        try {
          currentStaff = staffList.firstWhere(
            (s) => (s.staffCode ?? '').trim() == code,
          );
        } catch (_) {
          currentStaff = staff;
        }
      } else {
        currentStaff = staff;
      }
      if (currentStaff != null) {
        emit(state.copyWith(selectedStaff: <StaffEntity>[currentStaff]));
      }
    }
  }

  /// Step 3 of _initializeFormData (runs AFTER the gate, exactly as the widget
  /// did): non-admin / QR / forceSelf / kiosk with no selection yet → prefill self.
  Future<void> applyExtraSelfPrefill({
    required bool isKiosk,
    String? kioskStaffName,
    required bool forceSelf,
    required String qrToken,
  }) async {
    final isAdmin = state.isAdminRole ?? false;
    final isQrFlow = qrToken.isNotEmpty;
    final code = state.currentStaffCode;
    if (!((!isAdmin || isQrFlow || forceSelf || isKiosk) &&
        state.selectedStaff.isEmpty &&
        code != null)) {
      return;
    }
    final displayName = isKiosk
        ? (kioskStaffName?.trim() ?? 'Staff')
        : (await _storage.getString(StorageKeys.displayName))?.trim() ?? '';
    if (isClosed) return;
    AppLogger.d(
      '[StaffSignIn] Kiosk=$isKiosk, DisplayName=$displayName, StaffName=$kioskStaffName',
    );
    emit(
      state.copyWith(
        selectedStaff: [
          StaffEntity(
            id: 0,
            name: displayName,
            primaryRoomId: 0,
            classroomCode: '',
            classroomName: '',
            photoUuid: '',
            designation: 'Staff',
            staffCode: code,
            isExpectedToday: true,
          ),
        ],
      ),
    );
  }

  void setCurrentDateTime() {
    final now = ServerTimeService.instance.now();
    emit(
      state.copyWith(
        selectedDate: now,
        selectedTime: TimeOfDay(hour: now.hour, minute: now.minute),
      ),
    );
  }

  /// Fresh school-timezone resolution for the submit flow — re-syncs the
  /// server clock at the moment of submission, per
  /// [SchoolTimezoneResolver]'s own "fetch fresh on submit" contract. Unlike
  /// [initializeSchoolAndPersona], this does NOT touch state: the user's
  /// already-picked date/time must not be reset right before they submit.
  Future<String> resolveFreshSchoolTimeZone() {
    return SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: _storage,
      apiClient: _apiClient,
    );
  }

  void setSelectedDate(DateTime date) =>
      emit(state.copyWith(selectedDate: date));

  void setSelectedTime(TimeOfDay time) =>
      emit(state.copyWith(selectedTime: time));

  /// Removes [staff]; returns true when the list is now empty (View pops). When
  /// staff remain and none are unexpected, the gate is re-acknowledged.
  bool removeStaff(StaffEntity staff) {
    final updated = List<StaffEntity>.from(state.selectedStaff)..remove(staff);
    emit(state.copyWith(selectedStaff: updated));
    if (updated.isEmpty) return true;
    if (!hasUnexpectedAmongSelected()) {
      emit(
        state.copyWith(
          unexpectedSignInAcknowledged: true,
          notExpectedComment: '',
        ),
      );
    }
    return false;
  }

  bool hasUnexpectedAmongSelected() {
    for (final s in state.selectedStaff) {
      final code = (s.staffCode ?? '').trim();
      if (code.isEmpty) continue;
      final expected = state.expectedTodayFromApi[code] ?? s.isExpectedToday;
      if (!expected) return true;
    }
    return false;
  }

  List<String> unexpectedStaffFullNames() {
    final out = <String>[];
    for (final s in state.selectedStaff) {
      final code = (s.staffCode ?? '').trim();
      if (code.isEmpty) continue;
      final expected = state.expectedTodayFromApi[code] ?? s.isExpectedToday;
      if (!expected) out.add(s.name);
    }
    return out;
  }

  void acknowledgeUnexpected(String comment) {
    emit(
      state.copyWith(
        unexpectedSignInAcknowledged: true,
        notExpectedComment: comment,
      ),
    );
  }

  /// isExpectedToday for a single staff code (API value, else the selected
  /// entity's flag, else true). Used by the submit payload builder.
  bool isExpectedTodayForStaffCode(String code, Map<String, bool> fromApi) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return true;
    final apiValue = fromApi[trimmed];
    if (apiValue != null) return apiValue;
    for (final s in state.selectedStaff) {
      if ((s.staffCode ?? '').trim() == trimmed) return s.isExpectedToday;
    }
    return true;
  }

  /// Single isExpectedToday for the sign-in body: the common value if all agree,
  /// else true (the API can't express per-row flags).
  bool requestBodyIsExpectedToday({
    required List<String> staffCodes,
    required Map<String, bool> fromApi,
  }) {
    if (staffCodes.isEmpty) return true;
    final vals = staffCodes
        .map((c) => isExpectedTodayForStaffCode(c, fromApi))
        .toList();
    final first = vals.first;
    if (vals.every((v) => v == first)) return first;
    return true;
  }

  static String _naiveCalendarYyyyMmDd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Fresh `staffCode -> isExpectedToday` fetch for [attendanceDate]. The submit
  /// handler re-fetches at submit time (falling back to [state.expectedTodayFromApi]
  /// on error) exactly as the widget did.
  Future<Map<String, bool>> fetchExpectedToday({
    required String attendanceDate,
  }) => _fetchIsExpectedTodayFromSignInFormList(attendanceDate: attendanceDate);

  Future<Map<String, bool>> _fetchIsExpectedTodayFromSignInFormList({
    required String attendanceDate,
  }) async {
    final page = await _getStaffSignInFormList(
      fromAttendanceDate: attendanceDate,
      toAttendanceDate: attendanceDate,
      page: 0,
      size: 500,
    );
    return {
      for (final item in page.items) item.staffCode: item.isExpectedToday,
    };
  }

  /// Fetches expected-today for the selected day + updates gate state. Token
  /// cancellation preserved: a stale run reports [superseded] = true.
  Future<GateResolveOutcome> resolveExpectedToday() async {
    if (state.selectedStaff.isEmpty) {
      emit(
        state.copyWith(
          unexpectedGateLoading: false,
          unexpectedSignInAcknowledged: true,
        ),
      );
      return (
        superseded: false,
        needsDialog: false,
        unexpectedNames: const <String>[],
      );
    }

    final token = ++_gateToken;
    emit(state.copyWith(unexpectedGateLoading: true));

    final dateStr = _naiveCalendarYyyyMmDd(state.selectedDate);
    try {
      final map = await _fetchIsExpectedTodayFromSignInFormList(
        attendanceDate: dateStr,
      );
      if (isClosed || token != _gateToken) {
        return (
          superseded: true,
          needsDialog: false,
          unexpectedNames: const <String>[],
        );
      }
      emit(state.copyWith(expectedTodayFromApi: map));
    } catch (_) {
      if (isClosed || token != _gateToken) {
        return (
          superseded: true,
          needsDialog: false,
          unexpectedNames: const <String>[],
        );
      }
      emit(state.copyWith(expectedTodayFromApi: const {}));
    }

    if (isClosed || token != _gateToken) {
      return (
        superseded: true,
        needsDialog: false,
        unexpectedNames: const <String>[],
      );
    }

    if (!hasUnexpectedAmongSelected()) {
      emit(
        state.copyWith(
          unexpectedSignInAcknowledged: true,
          unexpectedGateLoading: false,
        ),
      );
      return (
        superseded: false,
        needsDialog: false,
        unexpectedNames: const <String>[],
      );
    }

    emit(
      state.copyWith(
        unexpectedSignInAcknowledged: false,
        unexpectedGateLoading: false,
      ),
    );
    return (
      superseded: false,
      needsDialog: true,
      unexpectedNames: unexpectedStaffFullNames(),
    );
  }
}
