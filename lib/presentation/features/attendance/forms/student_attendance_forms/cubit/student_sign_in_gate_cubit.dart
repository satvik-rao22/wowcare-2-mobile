import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/server_time_service.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_in_form_list_usecase.dart';

import '../student_sign_in_form.dart' show StudentEntity;
import 'student_sign_in_gate_state.dart';

/// Outcome of [StudentSignInGateCubit.resolveExpectedToday] — the View uses it
/// to decide whether to show the unexpected-sign-in dialog. [superseded] is true
/// when a newer resolve started before this one finished (the View must ignore
/// a superseded result — the token-cancellation the widget used to do inline).
typedef GateResolveOutcome = ({
  bool superseded,
  bool needsDialog,
  List<String> unexpectedNames,
});

/// Owns the student sign-in form's non-submit business logic (persona, date/time,
/// working student list, and the unexpected-sign-in gate DATA flow). The View
/// keeps the dialog + navigation — this cubit never touches BuildContext.
class StudentSignInGateCubit extends Cubit<StudentSignInGateState> {
  StudentSignInGateCubit({
    required GetStudentSignInFormListUseCase getStudentSignInFormList,
    required StorageService storageService,
    required ApiClient apiClient,
  }) : _getStudentSignInFormList = getStudentSignInFormList,
       _storage = storageService,
       _apiClient = apiClient,
       super(
         StudentSignInGateState(
           selectedDate: ServerTimeService.instance.now(),
           selectedTime: ServerTimeService.instance.timeOfDayNow(),
         ),
       );

  final GetStudentSignInFormListUseCase _getStudentSignInFormList;
  final StorageService _storage;
  final ApiClient _apiClient;

  int _gateToken = 0;

  void seedStudents(List<StudentEntity> students) {
    emit(state.copyWith(currentStudents: List<StudentEntity>.from(students)));
  }

  /// Resolves the staff/guardian persona and, for non-staff, resets date/time
  /// to "now". Mirrors the widget's _loadPersonaFlags.
  Future<void> loadPersonaFlags() async {
    final isStaff = await _resolveIsStaffPersona();
    if (isClosed) return;
    emit(state.copyWith(isStaffPersona: isStaff));
    if (!isStaff) setCurrentDateTime();
  }

  Future<bool> _resolveIsStaffPersona() async {
    try {
      return await resolveIsStaffPersonaFromStorage(_storage);
    } catch (_) {
      return false;
    }
  }

  /// Resolves the school timezone id, then re-seeds date/time. Mirrors the
  /// widget's _bootstrapSchoolZone (minus the gate, which the View orchestrates).
  Future<void> bootstrapSchoolZone() async {
    final z = await SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: _storage,
      apiClient: _apiClient,
    );
    if (isClosed) return;
    emit(state.copyWith(schoolIana: z));
    setCurrentDateTime();
  }

  void setCurrentDateTime() {
    final dt = ServerTimeService.instance.now();
    emit(
      state.copyWith(
        selectedDate: dt,
        selectedTime: TimeOfDay(hour: dt.hour, minute: dt.minute),
      ),
    );
  }

  void setSelectedDate(DateTime date) =>
      emit(state.copyWith(selectedDate: date));

  void setSelectedTime(TimeOfDay time) =>
      emit(state.copyWith(selectedTime: time));

  /// Removes [student] from the working list. Returns true when the list is now
  /// empty (the View pops). When students remain and none are unexpected, the
  /// gate is re-acknowledged (as the widget did).
  bool removeStudent(StudentEntity student) {
    final updated = List<StudentEntity>.from(state.currentStudents)
      ..remove(student);
    emit(state.copyWith(currentStudents: updated));
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
    for (final s in state.currentStudents) {
      final code = s.studentCode.trim();
      if (code.isEmpty) continue;
      final expected = state.expectedTodayFromApi[code] ?? s.isExpectedToday;
      if (!expected) return true;
    }
    return false;
  }

  List<String> unexpectedStudentFullNames() {
    final out = <String>[];
    for (final s in state.currentStudents) {
      final code = s.studentCode.trim();
      if (code.isEmpty) continue;
      final expected = state.expectedTodayFromApi[code] ?? s.isExpectedToday;
      if (!expected) out.add(s.fullName);
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

  static String _naiveCalendarYyyyMmDd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Fetches expected-today for the selected day and updates gate state.
  /// Token-cancellation preserved: a stale run reports [superseded] = true and
  /// emits nothing. The View reads [GateResolveOutcome.needsDialog] to decide
  /// whether to show the unexpected-sign-in dialog.
  Future<GateResolveOutcome> resolveExpectedToday() async {
    if (state.currentStudents.isEmpty) {
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
      final page = await _getStudentSignInFormList(
        fromAttendanceDate: dateStr,
        toAttendanceDate: dateStr,
        classroomCodes: null,
        tagCodes: null,
        search: null,
        page: 0,
        size: 500,
      );
      if (isClosed || token != _gateToken) {
        return (
          superseded: true,
          needsDialog: false,
          unexpectedNames: const <String>[],
        );
      }
      final m = <String, bool>{};
      for (final item in page.items) {
        m[item.studentCode.trim()] = item.isExpectedToday;
      }
      emit(state.copyWith(expectedTodayFromApi: m));
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

    final hasUnexpected = hasUnexpectedAmongSelected();
    if (!hasUnexpected) {
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
      unexpectedNames: unexpectedStudentFullNames(),
    );
  }
}
