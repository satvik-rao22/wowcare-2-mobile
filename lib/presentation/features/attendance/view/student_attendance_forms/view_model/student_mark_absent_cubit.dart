import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/storage/storage_service.dart';
import '../../../../../../core/utils/logger_service.dart';
import '../../../../../../core/utils/school_timezone_resolver.dart';
import '../../../../../../core/utils/school_zone_datetime.dart';
import '../../../../../../core/utils/staff_code_resolver.dart';
import '../../../../../../domain/features/attendance/usecases/mark_students_absent_usecase.dart';
import 'package:wowcare/core/utils/server_time_service.dart';
export '../../../model/tag_entity.dart';
import '../../../model/student_entity.dart';
export '../../../model/student_entity.dart';
part 'student_mark_absent_state.dart';

/// Cubit for [StudentMarkAbsentForm].
///
/// Owns the absence form's business + async state: the date range (clamped to
/// the school calendar's "today"), the admin-persona flag that gates date
/// editing, the working student list (students can be removed from the form),
/// and the submission in-flight flag. The view keeps only the [TextField]
/// controllers (reason + per-student notes), which are intrinsically
/// widget-owned and disposed there.
class StudentMarkAbsentFormCubit extends Cubit<StudentMarkAbsentState> {
  StudentMarkAbsentFormCubit({
    required MarkStudentsAbsentUseCase markStudentsAbsentUseCase,
    required StorageService storageService,
    required ApiClient apiClient,
  }) : _markStudentsAbsentUseCase = markStudentsAbsentUseCase,
       _storageService = storageService,
       _apiClient = apiClient,
       super(StudentMarkAbsentState.initial());

  final MarkStudentsAbsentUseCase _markStudentsAbsentUseCase;
  final StorageService _storageService;
  final ApiClient _apiClient;

  /// Seeds the working student list and resolves the persona/timezone flags.
  void init(List<StudentEntity> students) {
    emit(state.copyWith(students: List<StudentEntity>.of(students)));
    // ignore: discarded_futures
    _loadPersonaFlags();
  }

  Future<void> _loadPersonaFlags() async {
    try {
      String? schoolIana;
      try {
        schoolIana = await SchoolTimezoneResolver.resolveForCurrentSchool(
          storage: _storageService,
          apiClient: _apiClient,
        );
      } catch (e) {
        AppLogger.d(
          'StudentMarkAbsentFormCubit: resolveForCurrentSchool failed: $e',
        );
      }

      final isAdmin = await resolveIsStaffAdminPersonaFromStorage();
      if (isClosed) return;
      final DateTime start = (schoolIana != null && schoolIana.isNotEmpty)
          ? SchoolZoneDateTime.schoolCalendarTodayOnly(schoolIana)
          : _localToday();
      emit(
        state.copyWith(
          schoolIana: schoolIana,
          isStaffAdminPersona: isAdmin,
          startDate: start,
          endDate: start,
        ),
      );
    } catch (e) {
      AppLogger.d('StudentMarkAbsentFormCubit: _loadPersonaFlags failed: $e');
    }
  }

  /// Removes [student] from the working list. The view disposes the matching
  /// notes controller; the screen pops itself once the list is empty.
  void removeStudent(StudentEntity student) {
    final updated = List<StudentEntity>.of(state.students)..remove(student);
    emit(state.copyWith(students: updated));
  }

  /// Picks the absence start date, keeping end date on/after the start date.
  void selectStartDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = state.endDate.isBefore(start) ? start : state.endDate;
    emit(state.copyWith(startDate: start, endDate: end));
  }

  /// Picks the absence end date, never before the start date.
  void selectEndDate(DateTime date) {
    var end = DateTime(date.year, date.month, date.day);
    if (end.isBefore(state.startDate)) end = state.startDate;
    emit(state.copyWith(endDate: end));
  }

  /// Submits the absence for every student still in the form.
  ///
  /// [reason] and [notes] (keyed by studentCode) come from the view's
  /// controllers. Returns an outcome the view turns into a snackbar +
  /// navigation; validation failures are returned as [MarkAbsentSubmitOutcome.failure].
  Future<MarkAbsentSubmitOutcome> submit({
    required String reason,
    required Map<String, String> notes,
  }) async {
    if (state.isSubmitting) {
      return const MarkAbsentSubmitOutcome.noop();
    }
    if (state.students.isEmpty) {
      return const MarkAbsentSubmitOutcome.failure(
        'Please select at least one student',
      );
    }

    final staffCode = await resolveStaffCodeForLoggedInUser();
    if (staffCode.isEmpty) {
      return const MarkAbsentSubmitOutcome.failure(
        'Unable to resolve staffCode. Please re-login.',
      );
    }

    // The API takes ONE classroomCode per request, so students from different
    // classes must be submitted in separate calls, each with its own class.
    // Students with no classroomCode fall back to the first known one.
    final fallbackClassroomCode = state.students
        .map((s) => s.classroomCode.trim())
        .firstWhere((c) => c.isNotEmpty, orElse: () => '');
    final studentCodesByClassroom = <String, List<String>>{};
    for (final student in state.students) {
      final code = student.studentCode.trim();
      if (code.isEmpty) continue;
      final classroom = student.classroomCode.trim().isNotEmpty
          ? student.classroomCode.trim()
          : fallbackClassroomCode;
      studentCodesByClassroom
          .putIfAbsent(classroom, () => <String>[])
          .add(code);
    }
    final studentCodes = [
      for (final codes in studentCodesByClassroom.values) ...codes,
    ];
    if (studentCodes.isEmpty) {
      return const MarkAbsentSubmitOutcome.failure(
        'Student code missing for selected students',
      );
    }

    final absenceReason = reason.trim().isNotEmpty
        ? reason.trim()
        : 'Marked Absent';
    final absenceNotes = <String, String>{};
    for (final code in studentCodes) {
      final note = (notes[code] ?? '').trim();
      if (note.isNotEmpty) absenceNotes[code] = note;
    }

    emit(state.copyWith(isSubmitting: true));
    try {
      var message = '';
      for (final entry in studentCodesByClassroom.entries) {
        final codes = entry.value;
        message = await _markStudentsAbsentUseCase(
          staffCode: staffCode,
          studentCodes: codes,
          absenceFromDate: _formatDate(state.startDate),
          absenceToDate: _formatDate(state.endDate),
          absenceReason: absenceReason,
          absenceNotes: {
            for (final c in codes)
              if (absenceNotes.containsKey(c)) c: absenceNotes[c]!,
          },
          classroomCode: entry.key,
          isExpectedTodayByStudentCode: {for (final c in codes) c: true},
          markAbsentMethod: 'APP',
        );
      }
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
      return MarkAbsentSubmitOutcome.success(
        message.isNotEmpty ? message : 'Marked Absent successfully',
      );
    } catch (e) {
      if (!isClosed) emit(state.copyWith(isSubmitting: false));
      return MarkAbsentSubmitOutcome.error(e);
    }
  }

  static DateTime _localToday() {
    final now = ServerTimeService.instance.now();
    return DateTime(now.year, now.month, now.day);
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

/// Result of [StudentMarkAbsentFormCubit.submit].
///
/// `success` carries the toast message. `failure` carries a ready-to-show
/// validation message. `error` carries the raw exception so the view can run
/// it through `ApiErrorHandler`. `noop` means a submit was already in flight.
class MarkAbsentSubmitOutcome {
  const MarkAbsentSubmitOutcome._({
    required this.success,
    this.message,
    this.error,
  });

  const MarkAbsentSubmitOutcome.success(String message)
    : this._(success: true, message: message);

  const MarkAbsentSubmitOutcome.failure(String message)
    : this._(success: false, message: message);

  const MarkAbsentSubmitOutcome.error(Object error)
    : this._(success: false, error: error);

  const MarkAbsentSubmitOutcome.noop() : this._(success: false);

  final bool success;

  /// Pre-formatted message for `success` and validation `failure` outcomes.
  final String? message;

  /// Raw exception for `error` outcomes; run through `ApiErrorHandler` to show.
  final Object? error;
}
