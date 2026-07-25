import 'dart:convert';
import 'package:wowcare/core/util/app_time.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/storage/storage_service.dart';
import '../../../../../../core/util/school_timezone_resolver.dart';
import '../../../../../../core/util/school_zone_datetime.dart';
import '../../../../../../core/util/staff_code_resolver.dart';
import '../../../../../../core/util/storage_keys.dart';
import '../../../../../../domain/features/attendance/usecases/mark_staff_absent_usecase.dart';
import '../staff_entity.dart';

part 'staff_mark_absent_state.dart';

/// Cubit for [StaffMarkAbsentForm].
///
/// Owns the mark-absent form's business + async state: the date range (clamped
/// to the school calendar's "today"), the admin-persona flag that gates date
/// editing and bulk marking, the working staff list, and the submission flag.
/// The view keeps only the reason/type/notes [TextField] controllers.
class StaffMarkAbsentFormCubit extends Cubit<StaffMarkAbsentState> {
  StaffMarkAbsentFormCubit({
    required MarkStaffAbsentUseCase markStaffAbsentUseCase,
    required StorageService storageService,
    required ApiClient apiClient,
  })  : _markStaffAbsentUseCase = markStaffAbsentUseCase,
        _storageService = storageService,
        _apiClient = apiClient,
        super(StaffMarkAbsentState.initial());

  final MarkStaffAbsentUseCase _markStaffAbsentUseCase;
  final StorageService _storageService;
  final ApiClient _apiClient;

  /// Seeds the working staff list (single staff or a pre-selected list) and
  /// resolves the persona/timezone flags.
  ///
  /// [isStaffAdminPersona], when provided, comes from `RoleCubit` — the
  /// canonical, persona-switch-aware signal the view reads (this cubit has
  /// no `BuildContext` per the MVVM rule, so it can't read `RoleCubit`
  /// itself). Falls back to the storage-based resolution only if the caller
  /// doesn't supply it.
  void init({
    StaffEntity? staff,
    List<StaffEntity>? staffList,
    bool? isStaffAdminPersona,
  }) {
    final List<StaffEntity> selected;
    if (staffList != null && staffList.isNotEmpty) {
      selected = List<StaffEntity>.of(staffList);
    } else if (staff != null) {
      selected = <StaffEntity>[staff];
    } else {
      selected = <StaffEntity>[];
    }
    emit(state.copyWith(selectedStaff: selected));
    // ignore: discarded_futures
    _loadPersonaFlags(isStaffAdminPersona);
  }

  Future<void> _loadPersonaFlags(bool? knownIsStaffAdminPersona) async {
    String? schoolIana;
    try {
      schoolIana = await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: _storageService,
        apiClient: _apiClient,
      );
    } catch (_) {}

    final isAdmin =
        knownIsStaffAdminPersona ?? await _resolveIsStaffAdminPersona();
    final currentStaffCode = (await resolveStaffCodeForLoggedInUser()).trim();
    if (isClosed) return;
    final start = (schoolIana != null && schoolIana.isNotEmpty)
        ? SchoolZoneDateTime.schoolCalendarTodayOnly(schoolIana)
        : _localToday();
    emit(state.copyWith(
      schoolIana: schoolIana,
      isStaffAdminPersona: isAdmin,
      currentStaffCode:
          currentStaffCode.isNotEmpty ? currentStaffCode : null,
      startDate: start,
      endDate: start,
    ));
  }

  Future<bool> _resolveIsStaffAdminPersona() async {
    final staffType =
        (await _storageService.getString(StorageKeys.staffType) ?? '')
            .trim()
            .toUpperCase();
    if (staffType == 'SCHOOL_ADMIN' || staffType == 'ORGANIZATION_ADMIN') {
      return true;
    }

    final rolesJson = await _storageService.getString(StorageKeys.roles);
    if (rolesJson == null || rolesJson.trim().isEmpty) return false;
    try {
      final List<dynamic> roles = jsonDecode(rolesJson) as List<dynamic>;
      return roles.any((r) {
        if (r is! Map<String, dynamic>) return false;
        final roleCode = (r['role'] ?? '').toString().toUpperCase();
        return roleCode == 'SCHOOL_ADMIN' || roleCode == 'ORGANIZATION_ADMIN';
      });
    } catch (_) {
      return false;
    }
  }

  /// Removes [staff] from the working list. The view pops once the list is
  /// empty.
  void removeStaff(StaffEntity staff) {
    final updated = List<StaffEntity>.of(state.selectedStaff)..remove(staff);
    emit(state.copyWith(selectedStaff: updated));
  }

  void selectStartDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = state.endDate.isBefore(start) ? start : state.endDate;
    emit(state.copyWith(startDate: start, endDate: end));
  }

  void selectEndDate(DateTime date) {
    var end = DateTime(date.year, date.month, date.day);
    if (end.isBefore(state.startDate)) end = state.startDate;
    emit(state.copyWith(endDate: end));
  }

  /// Marks the selected staff absent. [reason]/[type]/[notes] come from the
  /// view's controllers. Returns an outcome the view turns into a snackbar +
  /// navigation (admins return to the tabbed view; teachers just pop).
  Future<StaffMarkAbsentSubmitOutcome> submit({
    required String reason,
    required String type,
    required String notes,
  }) async {
    if (state.isSubmitting || state.selectedStaff.isEmpty) {
      return const StaffMarkAbsentSubmitOutcome.noop();
    }

    final markerStaffCode = await resolveStaffCodeForLoggedInUser();
    if (markerStaffCode.isEmpty) {
      return const StaffMarkAbsentSubmitOutcome.failure(
        'Unable to resolve staffCode. Please re-login.',
      );
    }

    final targetStaffCodes = state.selectedStaff
        .map((s) => (s.staffCode ?? '').trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (targetStaffCodes.isEmpty) {
      return const StaffMarkAbsentSubmitOutcome.failure(
        'Target staff code is missing. Please refresh list.',
      );
    }

    final isStaffAdmin =
        state.isStaffAdminPersona ?? await _resolveIsStaffAdminPersona();
    if (!isStaffAdmin &&
        (targetStaffCodes.length != 1 ||
            targetStaffCodes.first != markerStaffCode)) {
      return const StaffMarkAbsentSubmitOutcome.failure(
        'Teachers can only mark absent for themselves.',
      );
    }

    final absenceReason = reason.trim().isNotEmpty ? reason.trim() : 'FEVER';
    final absenceType = type.trim().isNotEmpty ? type.trim() : 'ABSENT';
    final trimmedNotes = notes.trim();
    final absenceNotes = <String, String>{};
    if (trimmedNotes.isNotEmpty) {
      for (final code in targetStaffCodes) {
        absenceNotes[code] = trimmedNotes;
      }
    }
    final isExpectedTodayByStaffCode = <String, bool>{
      for (final code in targetStaffCodes) code: true,
    };

    // Self attendance (even for an admin persona) is always "today" —
    // defense in depth alongside the UI's disabled date pickers.
    final isSelfTarget = targetStaffCodes.length == 1 &&
        targetStaffCodes.first == markerStaffCode;
    final iana = state.schoolIana;
    final today = (iana != null && iana.isNotEmpty)
        ? SchoolZoneDateTime.schoolCalendarTodayOnly(iana)
        : _localToday();
    final absenceFromDate = isSelfTarget ? today : state.startDate;
    final absenceToDate = isSelfTarget ? today : state.endDate;

    emit(state.copyWith(isSubmitting: true));
    try {
      final message = await _markStaffAbsentUseCase(
        staffCode: markerStaffCode,
        staffCodes: targetStaffCodes,
        absenceFromDate: _formatDate(absenceFromDate),
        absenceToDate: _formatDate(absenceToDate),
        absenceReason: absenceReason,
        absenceType: absenceType,
        absenceNotes: absenceNotes,
        isExpectedTodayByStaffCode: isExpectedTodayByStaffCode,
        markAbsentMethod: 'APP',
      );
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
      return StaffMarkAbsentSubmitOutcome.success(
        message: message.isNotEmpty ? message : 'Marked Absent successfully',
        returnToTabbedView: isStaffAdmin,
      );
    } catch (e) {
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
      return StaffMarkAbsentSubmitOutcome.error(e);
    }
  }

  static DateTime _localToday() {
    final now = AppTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

/// Result of [StaffMarkAbsentFormCubit.submit].
class StaffMarkAbsentSubmitOutcome {
  const StaffMarkAbsentSubmitOutcome._({
    required this.success,
    this.message,
    this.error,
    this.returnToTabbedView = false,
  });

  const StaffMarkAbsentSubmitOutcome.success({
    required String message,
    required bool returnToTabbedView,
  }) : this._(
          success: true,
          message: message,
          returnToTabbedView: returnToTabbedView,
        );

  const StaffMarkAbsentSubmitOutcome.failure(String message)
      : this._(success: false, message: message);

  const StaffMarkAbsentSubmitOutcome.error(Object error)
      : this._(success: false, error: error);

  const StaffMarkAbsentSubmitOutcome.noop() : this._(success: false);

  final bool success;

  /// Pre-formatted message for `success` and validation `failure` outcomes.
  final String? message;

  /// Raw exception for `error` outcomes; run through `ApiErrorHandler`.
  final Object? error;

  /// On success: admins return to the tabbed view; teachers just pop.
  final bool returnToTabbedView;
}
