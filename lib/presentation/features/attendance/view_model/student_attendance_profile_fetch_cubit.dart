import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/attendance_classroom_scope.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/core/utils/server_time_service.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_profile_absent_toggle_query.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_profile_query.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_custom.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_profile_absent_toggle_response.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_profile_response.dart';
import 'package:wowcare/domain/features/attendance/usecases/fetch_student_attendance_profile_absent_toggle_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/fetch_student_attendance_profile_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_out_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_today_sign_in_status_usecase.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/domain/features/student/entities/student_profile.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_profile_usecase.dart';

part 'student_attendance_profile_state.dart';

/// Absent/attendance-record method enum shared by the profile screen's
/// records and absent-day rows.
enum ProfileAbsentMarkMethod { gps, qr, kiosk, app, web, system }

ProfileAbsentMarkMethod? mapAbsentMethodStringToEnum(String? method) {
  if (method == null) return null;
  switch (method.trim().toUpperCase()) {
    case 'GPS':
      return ProfileAbsentMarkMethod.gps;
    case 'PIN':
    case 'KIOSK':
      return ProfileAbsentMarkMethod.kiosk;
    case 'QR':
      return ProfileAbsentMarkMethod.qr;
    case 'APP':
      return ProfileAbsentMarkMethod.app;
    case 'WEB':
      return ProfileAbsentMarkMethod.web;
    case 'SYSTEM':
      return ProfileAbsentMarkMethod.system;
    default:
      return null;
  }
}

/// A single present-day attendance record row on the profile screen.
class StudentProfileAttendanceRecord {
  final DateTime date;
  final String signInTime;
  final String signOutTime;
  final String roomName;
  final String signInBy;
  final String signOutBy;
  final String attendedTime;
  final int attendedHours;
  final int attendedMinutes;
  final bool isTransferSignIn;
  final bool isTransferSignOut;
  final ProfileAbsentMarkMethod? signInMethod;
  final ProfileAbsentMarkMethod? signOutMethod;
  final String notExpectedComment;

  StudentProfileAttendanceRecord({
    required this.date,
    required this.signInTime,
    required this.signOutTime,
    required this.roomName,
    required this.signInBy,
    required this.signOutBy,
    this.attendedTime = '',
    this.attendedHours = 0,
    this.attendedMinutes = 0,
    this.isTransferSignIn = false,
    this.isTransferSignOut = false,
    this.signInMethod,
    this.signOutMethod,
    this.notExpectedComment = '',
  });
}

/// A single absent-day row on the profile screen's absent-days toggle list.
class StudentProfileAbsentDayRecord {
  final DateTime startDate;
  final DateTime endDate;
  final String absentTime;
  final String absentBy;
  final String note;
  final ProfileAbsentMarkMethod? markAbsentMethod;
  final String classroomName;

  StudentProfileAbsentDayRecord({
    required this.startDate,
    required this.endDate,
    required this.absentTime,
    required this.absentBy,
    required this.note,
    this.markAbsentMethod,
    this.classroomName = '',
  });
}

/// The header card's student identity + status fields.
class StudentProfileCardModel {
  final int id;
  final String name;
  final String? photoUuid;
  final String roomName;
  final bool isSignedIn;
  final bool isAbsent;
  final bool isExpectedToday;
  final bool isPresentToday;
  final String profileStatus;
  final bool isPhotoPermission;
  final String medications;
  final String note;
  final String allergies;
  final String dietRestriction;

  StudentProfileCardModel({
    required this.id,
    required this.name,
    this.photoUuid,
    required this.roomName,
    this.isSignedIn = false,
    this.isAbsent = false,
    this.isExpectedToday = true,
    this.isPresentToday = false,
    this.profileStatus = 'A',
    this.isPhotoPermission = true,
    this.medications = '',
    this.note = '',
    this.allergies = '',
    this.dietRestriction = '',
  });

  StudentProfileCardModel copyWith({
    String? name,
    String? roomName,
    String? photoUuid,
  }) {
    return StudentProfileCardModel(
      id: id,
      name: name ?? this.name,
      photoUuid: photoUuid ?? this.photoUuid,
      roomName: roomName ?? this.roomName,
      isSignedIn: isSignedIn,
      isAbsent: isAbsent,
      isExpectedToday: isExpectedToday,
      isPresentToday: isPresentToday,
      profileStatus: profileStatus,
      isPhotoPermission: isPhotoPermission,
      medications: medications,
      note: note,
      allergies: allergies,
      dietRestriction: dietRestriction,
    );
  }
}

/// Attended-days / attended-hours / absent-days summary shown in the stats row.
class StudentProfileAttendanceReportModel {
  final int attendedDays;
  final String totalAttendedHours;
  final int absentDays;

  StudentProfileAttendanceReportModel({
    required this.attendedDays,
    required this.totalAttendedHours,
    required this.absentDays,
  });
}

/// ViewModel for [StudentAttendanceProfile]. Owns every fetch call the View
/// makes (View -> Cubit -> UseCase -> Repository) AND the loaded/loading
/// state that used to live in the View's own setState fields — the load
/// orchestration methods below are the View's former `_loadData`,
/// `_loadTodayStatus`, `_ensureHeaderIdentityLoaded`,
/// `_applyParentChildSelection`'s data-loading half, and
/// `_onDateRangeSelected`'s state update, moved in verbatim (same
/// null-guards, same field derivations) with `emit(state.copyWith(...))`
/// replacing `setState(() { ... })`.
///
/// What stays in the View: anything that needs a [BuildContext]
/// (`AttendancePermissionService.hasPermissionToManageStudentAttendance`,
/// the `ParentChildCubit` stream subscription lifecycle) — a Cubit has no
/// context, so those remain View-level getters/lifecycle code that read
/// this cubit's `state`.
class StudentAttendanceProfileFetchCubit
    extends Cubit<StudentAttendanceProfileState> {
  StudentAttendanceProfileFetchCubit({
    required GetStudentProfileUseCase getStudentProfileUseCase,
    required GetStudentSignOutFormListUseCase getStudentSignOutFormListUseCase,
    required FetchStudentAttendanceProfileUseCase
    fetchStudentAttendanceProfileUseCase,
    required FetchStudentAttendanceProfileAbsentToggleUseCase
    fetchStudentAttendanceProfileAbsentToggleUseCase,
    required GetStudentTodaySignInStatusUseCase
    getStudentTodaySignInStatusUseCase,
    required GetActiveClassroomsUseCase getActiveClassroomsUseCase,
    required StorageService storageService,
  }) : _getStudentProfileUseCase = getStudentProfileUseCase,
       _getStudentSignOutFormListUseCase = getStudentSignOutFormListUseCase,
       _fetchStudentAttendanceProfileUseCase =
           fetchStudentAttendanceProfileUseCase,
       _fetchStudentAttendanceProfileAbsentToggleUseCase =
           fetchStudentAttendanceProfileAbsentToggleUseCase,
       _getStudentTodaySignInStatusUseCase = getStudentTodaySignInStatusUseCase,
       _getActiveClassroomsUseCase = getActiveClassroomsUseCase,
       _storageService = storageService,
       super(const StudentAttendanceProfileState());

  final GetStudentProfileUseCase _getStudentProfileUseCase;
  final GetStudentSignOutFormListUseCase _getStudentSignOutFormListUseCase;
  final FetchStudentAttendanceProfileUseCase
  _fetchStudentAttendanceProfileUseCase;
  final FetchStudentAttendanceProfileAbsentToggleUseCase
  _fetchStudentAttendanceProfileAbsentToggleUseCase;
  final GetStudentTodaySignInStatusUseCase _getStudentTodaySignInStatusUseCase;
  final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  final StorageService _storageService;

  // ── Thin fetch wrappers (unchanged from before) ──────────────────────────

  /// Used by [ensureHeaderIdentityLoaded] to fill the header when opened by
  /// code only (notification deep-link).
  Future<StudentProfile> fetchStudentProfile({required String code}) {
    return _getStudentProfileUseCase(code: code);
  }

  /// Used by [applyParentChildSelection] to resolve the selected child's
  /// current room/sign-in status for today.
  Future<StudentAttendanceCustomPage> fetchSignOutFormList({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    int page = 0,
    int size = 10,
  }) {
    return _getStudentSignOutFormListUseCase(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      page: page,
      size: size,
    );
  }

  Future<List<String>> resolveAllowedClassroomCodes() {
    return resolveStudentAttendanceAllowedClassroomCodes(
      storage: _storageService,
    );
  }

  /// Used by [_loadClassroomCodeToNameMap] (View) for the classroom
  /// name<->code resolution shown in the header/action forms.
  Future<Map<String, String>> fetchClassroomNameToCodeMap() async {
    final schoolCode =
        await _storageService.getString(StorageKeys.schoolCode) ?? '';
    if (schoolCode.trim().isEmpty) return const <String, String>{};

    final classrooms = await _getActiveClassroomsUseCase(
      schoolCode: schoolCode,
      onlyTypeClassroom: true,
    );
    return {
      for (final c in classrooms)
        if (c.name.trim().isNotEmpty && c.code.trim().isNotEmpty)
          c.name: c.code,
    };
  }

  // ── State-owning orchestration (moved from the View's setState methods) ──

  /// Seeds the initial header identity from the route args — the View's
  /// former initState() `student = _StudentModel(...)` assignment.
  void seedFromWidget({
    required int studentId,
    required String studentName,
    String? studentPhotoUuid,
    required String roomName,
    bool isSignedIn = false,
    bool isAbsent = false,
    bool isExpectedToday = true,
    bool isPresentToday = false,
    String profileStatus = 'A',
    required String activeStudentCode,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    emit(
      state.copyWith(
        activeStudentCode: activeStudentCode,
        startDate: startDate,
        endDate: endDate,
        student: StudentProfileCardModel(
          id: studentId,
          name: studentName,
          photoUuid: studentPhotoUuid,
          roomName: roomName,
          isSignedIn: isSignedIn,
          isAbsent: isAbsent,
          isExpectedToday: isExpectedToday,
          isPresentToday: isPresentToday,
          profileStatus: profileStatus,
          isPhotoPermission: true,
          medications: '',
          note: '',
          allergies: '',
          dietRestriction: '',
        ),
      ),
    );
  }

  /// Fills the header name + classroom when opened by code without them
  /// (notification deep-link). No-op for normal navigation that already
  /// supplied a student name.
  Future<void> ensureHeaderIdentityLoaded({
    required String studentName,
    required String activeStudentCode,
  }) async {
    if (studentName.trim().isNotEmpty) return;
    final code = activeStudentCode.trim();
    if (code.isEmpty) return;
    try {
      final profile = await fetchStudentProfile(code: code);
      if (isClosed) return;
      final current = state.student;
      if (current == null) return;
      final name = profile.fullName.trim();
      final classroom = (profile.classroomName ?? '').trim();
      emit(
        state.copyWith(
          student: current.copyWith(
            name: name.isNotEmpty ? name : current.name,
            roomName: classroom.isNotEmpty ? classroom : current.roomName,
          ),
        ),
      );
    } catch (_) {
      // Header stays as-is; attendance data still loads.
    }
  }

  Future<void> loadTodayStatus(String activeStudentCode) async {
    final code = activeStudentCode.trim();
    if (code.isEmpty) return;
    if (isClosed) return;
    emit(state.copyWith(isTodayStatusLoading: true));
    try {
      final status = await fetchTodayStatus(studentCode: code);
      if (isClosed) return;
      emit(state.copyWith(todayStatusRaw: status, isTodayStatusLoading: false));
    } catch (_) {
      if (isClosed) return;
      // On error, disable actions to avoid allowing invalid flows.
      emit(
        state.copyWith(clearTodayStatusRaw: true, isTodayStatusLoading: false),
      );
    }
  }

  Future<String?> fetchTodayStatus({required String studentCode}) {
    return _getStudentTodaySignInStatusUseCase(studentCode: studentCode);
  }

  /// Helper to format API time (either a string or {hour, minute, ...} map)
  /// into 'hh:mm:ss a' format for further formatting / calculations.
  String _formatApiTime(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      final hour = value['hour'] as int? ?? 0;
      final minute = value['minute'] as int? ?? 0;
      final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final period = hour >= 12 ? 'PM' : 'AM';
      final mm = minute.toString().padLeft(2, '0');
      return '$h12:$mm:00 $period';
    }
    return value.toString();
  }

  String _resolveClassroomNameByCode(
    String? classroomCode,
    Map<String, String> codeToNameMap,
    String fallback,
  ) {
    final code = (classroomCode ?? '').trim();
    if (code.isEmpty) return fallback;
    return codeToNameMap[code] ?? fallback;
  }

  /// Resolves the header classroom when it holds a **code** (common for
  /// guardian flows) using active classrooms from the API.
  void _applyResolvedClassroomHeaderName(Map<String, String> codeToNameMap) {
    final current = state.student;
    if (current == null || isClosed) return;
    final raw = current.roomName.trim();
    final resolved = _resolveClassroomNameByCode(
      raw.isEmpty ? null : raw,
      codeToNameMap,
      raw.isEmpty ? '—' : raw,
    );
    if (resolved == current.roomName) return;
    emit(state.copyWith(student: current.copyWith(roomName: resolved)));
  }

  Future<void> setDateRange(DateTime startDate, DateTime? endDate) async {
    // Use the exact dates the user picked. Snapping to start/end of month
    // here made every range collapse to the whole month, so a same-day
    // (10 Jun -> 10 Jun) or any custom range never filtered.
    final effectiveEnd = endDate ?? startDate;
    emit(state.copyWith(startDate: startDate, endDate: effectiveEnd));
    await loadData(fallbackRoomName: state.student?.roomName ?? '');
  }

  void toggleShowAbsentDays(bool value) {
    emit(state.copyWith(showAbsentDays: value));
  }

  Future<void> applyParentChildSelection({
    required String childCode,
    required String childName,
    required String childClassroom,
    required int studentId,
    required String defaultProfileStatus,
  }) async {
    String roomName = childClassroom.trim().isNotEmpty ? childClassroom : '—';
    var isSignedIn = false;

    try {
      final now = ServerTimeService.instance.now();
      final date =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final signedInPage = await fetchSignOutFormList(
        fromAttendanceDate: date,
        toAttendanceDate: date,
        page: 0,
        size: 200,
      );
      final selected = signedInPage.items.where(
        (i) => i.studentCode.trim() == childCode.trim(),
      );
      if (selected.isNotEmpty) {
        final row = selected.first;
        roomName = row.classroomName.trim().isNotEmpty
            ? row.classroomName
            : roomName;
        isSignedIn = row.hasSignIn && !row.hasSignOut;
      }
    } catch (_) {
      // Parents may not have sign-out form list access; keep classroom from child ref.
    }

    if (isClosed) return;
    final previousStudent = state.student;
    emit(
      state.copyWith(
        activeStudentCode: childCode.trim(),
        student: StudentProfileCardModel(
          id: studentId,
          name: childName,
          photoUuid: null,
          roomName: roomName,
          isSignedIn: isSignedIn,
          isAbsent: previousStudent?.isAbsent ?? false,
          isExpectedToday: previousStudent?.isExpectedToday ?? true,
          isPresentToday: previousStudent?.isPresentToday ?? false,
          profileStatus: previousStudent?.profileStatus ?? defaultProfileStatus,
          isPhotoPermission: previousStudent?.isPhotoPermission ?? true,
          medications: previousStudent?.medications ?? '',
          note: previousStudent?.note ?? '',
          allergies: previousStudent?.allergies ?? '',
          dietRestriction: previousStudent?.dietRestriction ?? '',
        ),
      ),
    );
    await loadData(fallbackRoomName: roomName);
  }

  Future<void> loadData({required String fallbackRoomName}) async {
    final activeStudentCode = state.activeStudentCode;
    if (activeStudentCode.isEmpty) {
      emit(
        state.copyWith(
          isAttendancesLoading: false,
          isAbsentDaysLoading: false,
          isStudentLoading: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isAttendancesLoading: true,
        isAbsentDaysLoading: true,
        isStudentLoading: true,
      ),
    );

    // Load today's status first so action menu enablement is correct.
    await loadTodayStatus(activeStudentCode);

    final from = state.startDate ?? ServerTimeService.instance.now();
    final to = state.endDate ?? from;

    final fromStr = DateFormat('yyyy-MM-dd').format(from);
    final toStr = DateFormat('yyyy-MM-dd').format(to);

    final allowedClassroomCodes = await resolveAllowedClassroomCodes();

    try {
      // fetchClassroomNameToCodeMap() returns {name: code} (its own name and
      // the View's transfer-form dropdown both rely on that orientation) —
      // invert it here since every lookup below in this method needs the
      // opposite direction (resolving a record's classroomCODE to its name).
      final nameToCodeMap = await fetchClassroomNameToCodeMap();
      final codeToNameMap = <String, String>{
        for (final entry in nameToCodeMap.entries) entry.value: entry.key,
      };
      _applyResolvedClassroomHeaderName(codeToNameMap);
      // --------- Load attendance (present days / summary) ----------
      final profileData = await fetchProfileData(
        query: AttendanceProfileQuery(
          studentCode: activeStudentCode,
          fromAttendanceDate: fromStr,
          toAttendanceDate: toStr,
          page: 0,
          size: 100,
          sort: const ['attendanceDate,desc'],
          allowedClassroomCodes: List<String>.from(allowedClassroomCodes),
        ),
      );
      if (profileData != null) {
        final attendedDays = profileData.attendedDays;
        final totalAttendedTime = profileData.totalAttendedTime;

        final List<StudentProfileAttendanceRecord> loadedAttendances = [];

        for (final record in profileData.records) {
          final dateStr = record.attendanceDate;
          final date = dateStr.isNotEmpty
              ? DateTime.tryParse(dateStr) ?? ServerTimeService.instance.now()
              : ServerTimeService.instance.now();

          final int sequenceNumber = record.sequenceNumber;
          final int totalSequenceCount = record.totalSequenceCount;

          final signedInDisplay = _formatApiTime(record.signedInTime);
          final signedOutDisplay = _formatApiTime(record.signedOutTime);
          final transferDisplay = _formatApiTime(record.transferTime);
          final nextActionDisplay = _formatApiTime(record.nextActionTime);

          String effectiveSignIn = signedInDisplay;
          String effectiveSignOut = signedOutDisplay;
          bool isTransferSignIn = false;
          bool isTransferSignOut = false;

          if (totalSequenceCount > 1) {
            final isFirst = sequenceNumber == 1;
            final isLast = sequenceNumber == totalSequenceCount;

            if (isFirst && !isLast) {
              effectiveSignIn = signedInDisplay;
              effectiveSignOut = nextActionDisplay;
              isTransferSignOut = effectiveSignOut.isNotEmpty;
            } else if (!isFirst && !isLast) {
              effectiveSignIn = transferDisplay;
              effectiveSignOut = nextActionDisplay;
              isTransferSignIn = effectiveSignIn.isNotEmpty;
              isTransferSignOut = effectiveSignOut.isNotEmpty;
            } else if (isLast) {
              effectiveSignIn = isFirst ? signedInDisplay : transferDisplay;
              effectiveSignOut = signedOutDisplay;
              isTransferSignIn = !isFirst && effectiveSignIn.isNotEmpty;
            }
          }

          final fallbackClassroom = record.classroomName ?? fallbackRoomName;
          final resolvedClassroomName = _resolveClassroomNameByCode(
            record.classroomCode,
            codeToNameMap,
            fallbackClassroom,
          );

          final signOutMethodEnum = mapAbsentMethodStringToEnum(
            record.signedOutMethod,
          );
          // On a classroom transfer the "sign in/out" for that segment is the
          // transfer itself, performed by `transferredBy`. The API leaves
          // signedInBy/signedOutBy empty on transfer records, so fall back to
          // transferredBy for the person's name.
          final transferredBy = record.transferredBy.trim();

          final rawSignedInBy = record.signedInBy.trim();
          final signInByText = rawSignedInBy.isNotEmpty
              ? rawSignedInBy
              : (isTransferSignIn ? transferredBy : '');

          // Auto sign-out has no person: the API sends signedOutMethod=SYSTEM
          // with an empty signedOutBy. Show "System" (web parity) so the row
          // isn't blank; keep the real name / transfer person when present.
          final rawSignedOutBy = record.signedOutBy.trim();
          final signOutByText = rawSignedOutBy.isNotEmpty
              ? rawSignedOutBy
              : (isTransferSignOut && transferredBy.isNotEmpty
                    ? transferredBy
                    : (signOutMethodEnum == ProfileAbsentMarkMethod.system
                          ? 'System'
                          : ''));

          loadedAttendances.add(
            StudentProfileAttendanceRecord(
              date: date,
              signInTime: effectiveSignIn,
              signOutTime: effectiveSignOut,
              roomName: resolvedClassroomName,
              signInBy: signInByText,
              signOutBy: signOutByText,
              attendedTime: record.attendedTime,
              attendedHours: record.attendedHours,
              attendedMinutes: record.attendedMinutes,
              isTransferSignIn: isTransferSignIn,
              isTransferSignOut: isTransferSignOut,
              signInMethod: mapAbsentMethodStringToEnum(record.signedInMethod),
              signOutMethod: signOutMethodEnum,
              notExpectedComment: record.notExpectedComment.trim(),
            ),
          );
        }

        if (isClosed) return;
        emit(
          state.copyWith(
            attendanceReport: StudentProfileAttendanceReportModel(
              attendedDays: attendedDays,
              totalAttendedHours: totalAttendedTime,
              // Absent days count will be updated from absent profile API below.
              absentDays: state.attendanceReport?.absentDays ?? 0,
            ),
            attendances: loadedAttendances,
            isAttendancesLoading: false,
          ),
        );
      } else {
        if (isClosed) return;
        emit(state.copyWith(isAttendancesLoading: false));
      }

      // --------- Load absent days for toggle list (profile/absent/toggle) ----------
      final absentData = await fetchAbsentToggleData(
        query: AttendanceProfileAbsentToggleQuery(
          studentCode: activeStudentCode,
          fromAbsenceDate: fromStr,
          toAbsenceDate: toStr,
          page: 0,
          size: 100,
          sort: const ['absenceDate,desc'],
          allowedClassroomCodes: List<String>.from(allowedClassroomCodes),
          // Swagger lists pageable as required for this endpoint.
          // Keep both styles to remain backward compatible across environments.
          includePageableAliasParams: true,
        ),
      );

      if (absentData != null) {
        final absentDaysCount = absentData.absentDays;

        final List<StudentProfileAbsentDayRecord> loadedAbsentDays = [];

        for (final record in absentData.records) {
          final dateStr = record.absenceDate;
          final date = dateStr.isNotEmpty
              ? DateTime.tryParse(dateStr) ?? ServerTimeService.instance.now()
              : ServerTimeService.instance.now();

          loadedAbsentDays.add(
            StudentProfileAbsentDayRecord(
              startDate: date,
              endDate: date,
              absentTime: _formatApiTime(record.markedAbsentTime),
              absentBy:
                  (record.markedAbsentByName ?? record.markedAbsentBy ?? '')
                      .toString(),
              note: record.absenceNote,
              markAbsentMethod: mapAbsentMethodStringToEnum(
                record.markAbsentMethod,
              ),
              classroomName: _resolveClassroomNameByCode(
                record.classroomCode,
                codeToNameMap,
                record.classroomName?.trim() ?? '',
                // render-time fallback uses student?.roomName
              ),
            ),
          );
        }

        if (isClosed) return;
        emit(
          state.copyWith(
            attendanceReport: StudentProfileAttendanceReportModel(
              attendedDays: state.attendanceReport?.attendedDays ?? 0,
              totalAttendedHours:
                  state.attendanceReport?.totalAttendedHours ?? '',
              absentDays: absentDaysCount,
            ),
            absentDays: loadedAbsentDays,
            isAbsentDaysLoading: false,
            isStudentLoading: false,
          ),
        );
      } else {
        if (isClosed) return;
        emit(
          state.copyWith(isAbsentDaysLoading: false, isStudentLoading: false),
        );
      }
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isAttendancesLoading: false,
          isAbsentDaysLoading: false,
          isStudentLoading: false,
        ),
      );
    }
  }

  Future<StudentAttendanceProfileResponse?> fetchProfileData({
    required AttendanceProfileQuery query,
  }) {
    return _fetchStudentAttendanceProfileUseCase(query: query);
  }

  Future<StudentAttendanceProfileAbsentToggleResponse?> fetchAbsentToggleData({
    required AttendanceProfileAbsentToggleQuery query,
  }) {
    return _fetchStudentAttendanceProfileAbsentToggleUseCase(query: query);
  }
}
