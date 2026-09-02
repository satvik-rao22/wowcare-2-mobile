import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/simmer_loader.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_profile_field.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_profile_stat_widgets.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_profile_query.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_profile_absent_toggle_query.dart';
import 'package:wowcare/core/util/attendance_attended_duration.dart';
import 'package:wowcare/presentation/features/attendance/view_model/student_attendance_profile_fetch_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/bottom_navigation_item.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/attendance/widgets/student_attendance_vertical_pop_up.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_permission_service.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_school_time.dart';
import 'package:wowcare/presentation/features/students/widgets/student_attendance_action_availability.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_entity.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_sign_in_form.dart'
    as student_sign_in;
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_sign_out_form.dart'
    as student_sign_out;
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_transfer_form.dart'
    as student_transfer;
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_mark_absent_form.dart'
    as student_absent;
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/core/util/server_time_service.dart';

enum ProfileAbsentMarkMethod { gps, qr, kiosk, app, web, system }

/// Builds the small method-tooltip icon for [AttendanceProfileField]'s
/// [AttendanceProfileField.methodIcon] slot. Kept local (rather than shared
/// with the staff profile screen) because the two personas' method sets
/// genuinely differ — staff adds pin/transfer/nfc/biometric.
Widget _absentMethodIcon(ProfileAbsentMarkMethod method) {
  const double size = 16;
  switch (method) {
    case ProfileAbsentMarkMethod.gps:
      return Tooltip(
        message: 'GPS',
        child: SvgPicture.asset(
          MediaRes.gpsMethodIcon,
          width: size,
          height: size,
          colorFilter: const ColorFilter.mode(
            AppColors.themeColor,
            BlendMode.srcIn,
          ),
        ),
      );
    case ProfileAbsentMarkMethod.qr:
      return Tooltip(
        message: 'QR',
        child: SvgPicture.asset(
          MediaRes.qrAttendanceIcon,
          width: size,
          height: size,
          colorFilter: const ColorFilter.mode(
            AppColors.themeColor,
            BlendMode.srcIn,
          ),
        ),
      );
    case ProfileAbsentMarkMethod.kiosk:
      return Tooltip(
        message: 'Kiosk',
        child: SvgPicture.asset(
          MediaRes.kioskAttendenceIcons,
          width: size,
          height: size,
          colorFilter: const ColorFilter.mode(
            AppColors.themeColor,
            BlendMode.srcIn,
          ),
        ),
      );
    case ProfileAbsentMarkMethod.app:
      return Tooltip(
        message: 'APP',
        child: SvgPicture.asset(
          MediaRes.appMethodIcon,
          width: size,
          height: size,
          colorFilter: const ColorFilter.mode(
            AppColors.themeColor,
            BlendMode.srcIn,
          ),
        ),
      );
    case ProfileAbsentMarkMethod.web:
      return Tooltip(
        message: 'WEB',
        child: SvgPicture.asset(
          MediaRes.webMethodIcon,
          width: size,
          height: size,
          colorFilter: const ColorFilter.mode(
            AppColors.themeColor,
            BlendMode.srcIn,
          ),
        ),
      );
    case ProfileAbsentMarkMethod.system:
      // Auto sign-out performed by the system (no person). Matches web's
      // gear/"System" indicator.
      return Tooltip(
        message: 'System',
        child: SvgPicture.asset(
          MediaRes.systemMethodIcon,
          width: size,
          height: size,
          colorFilter: const ColorFilter.mode(
            AppColors.themeColor,
            BlendMode.srcIn,
          ),
        ),
      );
  }
}

// Dummy data models for UI-only implementation
class _AttendanceModel {
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

  _AttendanceModel({
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

class _AbsentDayModel {
  final DateTime startDate;
  final DateTime endDate;
  final String absentTime;
  final String absentBy;
  final String note;
  final ProfileAbsentMarkMethod? markAbsentMethod;
  final String classroomName;

  _AbsentDayModel({
    required this.startDate,
    required this.endDate,
    required this.absentTime,
    required this.absentBy,
    required this.note,
    this.markAbsentMethod,
    this.classroomName = '',
  });
}

/// Formats many possible API time shapes into a clean 12-hour display ("hh:mm a").
/// Supports:
/// - Map: {hour, minute, second?, nano?}
/// - "HH:mm", "HH:mm:ss", "HH:mm:ss.SSSSSS"
/// - "h:mm:ss AM", "hh:mm:ss a"
/// - ISO datetime strings (e.g. "2026-04-07T13:05:00.000Z")
String _formatTime12h(dynamic value) {
  if (value == null) return '';
  final s = value.toString().trim();
  if (s.isEmpty) return '';

  try {
    if (value is Map<String, dynamic>) {
      final hour = value['hour'] as int? ?? 0;
      final minute = value['minute'] as int? ?? 0;
      final dt = DateTime(2000, 1, 1, hour, minute);
      return DateFormat('hh:mm a').format(dt);
    }

    // Render ISO instants in the school's zone (not the device zone) so
    // sign-in/out times match the backend regardless of where the user is.
    final schoolDt = attendanceDisplayDateTimeFromIso(s);
    if (schoolDt != null) {
      return DateFormat('hh:mm a').format(schoolDt);
    }

    final amPmMatch = RegExp(
      r'^\s*(\d{1,2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?\s*([aApP][mM])\s*$',
    ).firstMatch(s);
    if (amPmMatch != null) {
      final hour = int.parse(amPmMatch.group(1)!);
      final minute = int.parse(amPmMatch.group(2)!);
      final period = amPmMatch.group(4)!.toUpperCase();
      int h24 = hour % 12;
      if (period == 'PM') h24 += 12;
      final dt = DateTime(2000, 1, 1, h24, minute);
      return DateFormat('hh:mm a').format(dt);
    }

    final hms = s.split('.')[0];
    final parts = hms.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final dt = DateTime(2000, 1, 1, hour, minute);
      return DateFormat('hh:mm a').format(dt);
    }
  } catch (_) {
    // fall-through to raw string
  }

  return s;
}

String _formatAttendedTimeForCard(_AttendanceModel attendance) {
  final inStr = attendance.signInTime.trim();
  final outStr = attendance.signOutTime.trim();

  if (inStr.isNotEmpty && outStr.isEmpty) {
    return 'Not Yet Signed Out';
  }

  final day = DateTime(
    attendance.date.year,
    attendance.date.month,
    attendance.date.day,
  );
  final start = parseFlexibleAttendanceMoment(day, inStr);
  final end = parseFlexibleAttendanceMoment(day, outStr);
  final label = attendedLabelFromMoments(start, end);
  if (label != null && label.isNotEmpty) {
    return label;
  }
  return '';
}

String formatTime(String time) {
  if (time.trim().isEmpty) return 'Not Yet Signed Out';
  return _formatTime12h(time);
}

bool _isKioskOrPinMethodEnum(ProfileAbsentMarkMethod? method) {
  return method == ProfileAbsentMarkMethod.kiosk;
}

String _resolveSignInByDisplay(
  String signInBy,
  ProfileAbsentMarkMethod? method,
) {
  final name = signInBy.trim();
  if (name.isNotEmpty) return name;
  if (_isKioskOrPinMethodEnum(method)) return 'Kiosk';
  return '';
}

String _resolveSignOutByDisplay(
  String signOutBy,
  ProfileAbsentMarkMethod? method,
) {
  final name = signOutBy.trim();
  if (name.isNotEmpty) return name;
  if (_isKioskOrPinMethodEnum(method)) return 'Kiosk';
  return '';
}

/// Shows the full name (first + last), not just the first word.
String getFirstName(String name) {
  return name.trim();
}

class _StudentModel {
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

  _StudentModel({
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

  _StudentModel copyWith({String? name, String? roomName, String? photoUuid}) {
    return _StudentModel(
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

class _AttendanceReportModel {
  final int attendedDays;
  final String totalAttendedHours;
  final int absentDays;

  _AttendanceReportModel({
    required this.attendedDays,
    required this.totalAttendedHours,
    required this.absentDays,
  });
}

class StudentAttendanceProfile extends StatefulWidget {
  static const String routeName = '/dashboard/student-attendance-profile';

  const StudentAttendanceProfile({
    super.key,
    required this.studentCode,
    required this.studentId,
    required this.studentName,
    this.studentPhotoUuid,
    required this.roomName,
    this.isSignedIn = false,
    this.isAbsent = false,
    this.isExpectedToday = true,
    this.isPresentToday = false,
    this.profileStatus = 'A',
    this.syncWithParentChildSelection = false,
    this.initialShowAbsentDays = false,
  });

  final int studentId;
  final String studentCode;
  final String studentName;
  final String? studentPhotoUuid;
  final String roomName;
  final bool isSignedIn;
  final bool isAbsent;
  final bool isExpectedToday;
  final bool isPresentToday;
  final String profileStatus;

  /// When true (e.g. parent drawer / popup), reloads when the global child dropdown changes.
  final bool syncWithParentChildSelection;

  /// When true, opens the profile with the absent-days list visible (e.g. Absent tab).
  final bool initialShowAbsentDays;

  @override
  State<StudentAttendanceProfile> createState() =>
      _StudentAttendanceProfileState();
}

class _StudentAttendanceProfileState extends State<StudentAttendanceProfile> {
  DateTime _startOfMonth(DateTime date) => DateTime(date.year, date.month, 1);

  DateTime _endOfMonth(DateTime date) => DateTime(date.year, date.month + 1, 0);

  ProfileAbsentMarkMethod? _mapAbsentMethodStringToEnum(String? method) {
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

  DateTime? _startDate;
  DateTime? _endDate;
  bool isAttendancesLoading = false;
  bool isAbsentDaysLoading = false;
  bool isStudentLoading = false;
  bool showAbsentDays = false;

  List<_AttendanceModel> attendances = [];
  List<_AbsentDayModel> absentDays = [];
  _StudentModel? student;
  _AttendanceReportModel? attendanceReport;

  late String _activeStudentCode;
  ParentChildCubit? _parentChildProvider;
  StreamSubscription<ParentChildState>? _parentChildSub;
  String? _todayStatusRaw;
  bool _isTodayStatusLoading = false;

  /// Owns every raw fetch call this screen makes (View -> Cubit -> UseCase ->
  /// Repository); see the cubit's doc comment for why this is a thin
  /// fetch-wrapping seam rather than a full state-owning cubit.
  final StudentAttendanceProfileFetchCubit _profileCubit =
      serviceLocator<StudentAttendanceProfileFetchCubit>();

  String _resolveClassroomNameByCode(
    String? classroomCode,
    Map<String, String> codeToNameMap,
    String fallback,
  ) {
    final code = (classroomCode ?? '').trim();
    if (code.isEmpty) return fallback;
    return codeToNameMap[code] ?? fallback;
  }

  /// Resolves [student] header classroom when it holds a **code** (common for
  /// guardian flows: [ParentChildRef.classroom] / [Student.classroom]) using
  /// active classrooms from the API ([_loadClassroomCodeToNameMap]).
  void _applyResolvedClassroomHeaderName(Map<String, String> codeToNameMap) {
    final current = student;
    if (current == null || !mounted) return;
    final raw = current.roomName.trim();
    final resolved = _resolveClassroomNameByCode(
      raw.isEmpty ? null : raw,
      codeToNameMap,
      raw.isEmpty ? '—' : raw,
    );
    if (resolved == current.roomName) return;
    setState(() {
      student = _StudentModel(
        id: current.id,
        name: current.name,
        photoUuid: current.photoUuid,
        roomName: resolved,
        isSignedIn: current.isSignedIn,
        isAbsent: current.isAbsent,
        isExpectedToday: current.isExpectedToday,
        isPresentToday: current.isPresentToday,
        profileStatus: current.profileStatus,
        isPhotoPermission: current.isPhotoPermission,
        medications: current.medications,
        note: current.note,
        allergies: current.allergies,
        dietRestriction: current.dietRestriction,
      );
    });
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

  @override
  void initState() {
    super.initState();
    showAbsentDays = widget.initialShowAbsentDays;
    _activeStudentCode = widget.studentCode.trim();
    final now = ServerTimeService.instance.now();
    _startDate = _startOfMonth(now);
    _endDate = _endOfMonth(now);

    // Initialize student model
    student = _StudentModel(
      id: widget.studentId,
      name: widget.studentName,
      photoUuid: widget.studentPhotoUuid,
      roomName: widget.roomName,
      isSignedIn: widget.isSignedIn,
      isAbsent: widget.isAbsent,
      isExpectedToday: widget.isExpectedToday,
      isPresentToday: widget.isPresentToday,
      profileStatus: widget.profileStatus,
      isPhotoPermission: true,
      medications: '',
      note: '',
      allergies: '',
      dietRestriction: '',
    );

    // Load data from API
    _loadData();
    // Deep-link (e.g. ATTENDANCE_NOT_MARKED) opens this screen with only a
    // studentCode — the attendance API doesn't return the student's name, so
    // the header would show empty. Fetch the student's identity by code.
    _ensureHeaderIdentityLoaded();
  }

  /// Fills the header name + classroom when opened by code without them
  /// (notification deep-link). No-op for normal navigation that already
  /// supplied [studentName].
  Future<void> _ensureHeaderIdentityLoaded() async {
    if (widget.studentName.trim().isNotEmpty) return;
    final code = _activeStudentCode.trim();
    if (code.isEmpty) return;
    try {
      final profile = await _profileCubit.fetchStudentProfile(code: code);
      if (!mounted) return;
      final current = student;
      if (current == null) return;
      final name = profile.fullName.trim();
      final classroom = (profile.classroomName ?? '').trim();
      setState(() {
        student = current.copyWith(
          name: name.isNotEmpty ? name : current.name,
          roomName: classroom.isNotEmpty ? classroom : current.roomName,
        );
      });
    } catch (_) {
      // Header stays as-is; attendance data still loads.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.syncWithParentChildSelection || _parentChildProvider != null) {
      return;
    }
    final p = context.read<ParentChildCubit>();
    _parentChildProvider = p;
    _parentChildSub = p.stream.listen((_) => _onParentChildSelectionChanged());
  }

  @override
  void dispose() {
    _parentChildSub?.cancel();
    super.dispose();
  }

  void _onParentChildSelectionChanged() {
    if (!widget.syncWithParentChildSelection) return;
    final child = _parentChildProvider?.selectedChild;
    final code = child?.code.trim() ?? '';
    if (code.isEmpty || code == _activeStudentCode) return;
    _applyParentChildSelection(child!);
  }

  Future<void> _applyParentChildSelection(ParentChildRef child) async {
    String roomName = child.classroom.trim().isNotEmpty ? child.classroom : '—';
    var isSignedIn = false;

    try {
      final now = ServerTimeService.instance.now();
      final date =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final signedInPage = await _profileCubit.fetchSignOutFormList(
        fromAttendanceDate: date,
        toAttendanceDate: date,
        page: 0,
        size: 200,
      );
      final selected = signedInPage.items.where(
        (i) => i.studentCode.trim() == child.code.trim(),
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

    if (!mounted) return;
    setState(() {
      _activeStudentCode = child.code.trim();
      student = _StudentModel(
        id: widget.studentId,
        name: child.name,
        photoUuid: null,
        roomName: roomName,
        isSignedIn: isSignedIn,
        isAbsent: student?.isAbsent ?? false,
        isExpectedToday: student?.isExpectedToday ?? true,
        isPresentToday: student?.isPresentToday ?? false,
        profileStatus: student?.profileStatus ?? widget.profileStatus,
        isPhotoPermission: student?.isPhotoPermission ?? true,
        medications: student?.medications ?? '',
        note: student?.note ?? '',
        allergies: student?.allergies ?? '',
        dietRestriction: student?.dietRestriction ?? '',
      );
    });
    await _loadData();
  }

  Future<void> _loadData() async {
    if (_activeStudentCode.isEmpty) {
      setState(() {
        isAttendancesLoading = false;
        isAbsentDaysLoading = false;
        isStudentLoading = false;
      });
      return;
    }

    setState(() {
      isAttendancesLoading = true;
      isAbsentDaysLoading = true;
      isStudentLoading = true;
    });

    // Load today's status first so action menu enablement is correct.
    await _loadTodayStatus();

    final from = _startDate ?? ServerTimeService.instance.now();
    final to = _endDate ?? from;

    final fromStr = DateFormat('yyyy-MM-dd').format(from);
    final toStr = DateFormat('yyyy-MM-dd').format(to);

    final allowedClassroomCodes = await _profileCubit
        .resolveAllowedClassroomCodes();

    try {
      final codeToNameMap = await _loadClassroomCodeToNameMap();
      _applyResolvedClassroomHeaderName(codeToNameMap);
      // --------- Load attendance (present days / summary) ----------
      final profileData = await _profileCubit.fetchProfileData(
        query: AttendanceProfileQuery(
          studentCode: _activeStudentCode,
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

        final List<_AttendanceModel> loadedAttendances = [];

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

          final fallbackClassroom = record.classroomName ?? widget.roomName;
          final resolvedClassroomName = _resolveClassroomNameByCode(
            record.classroomCode,
            codeToNameMap,
            fallbackClassroom,
          );

          final signOutMethodEnum = _mapAbsentMethodStringToEnum(
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
            _AttendanceModel(
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
              signInMethod: _mapAbsentMethodStringToEnum(record.signedInMethod),
              signOutMethod: signOutMethodEnum,
              notExpectedComment: record.notExpectedComment.trim(),
            ),
          );
        }

        setState(() {
          attendanceReport = _AttendanceReportModel(
            attendedDays: attendedDays,
            totalAttendedHours: totalAttendedTime,
            // Absent days count will be updated from absent profile API below.
            absentDays: attendanceReport?.absentDays ?? 0,
          );
          attendances = loadedAttendances;
          isAttendancesLoading = false;
        });
      } else {
        setState(() {
          isAttendancesLoading = false;
        });
      }

      // --------- Load absent days for toggle list (profile/absent/toggle) ----------
      final absentData = await _profileCubit.fetchAbsentToggleData(
        query: AttendanceProfileAbsentToggleQuery(
          studentCode: _activeStudentCode,
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

        final List<_AbsentDayModel> loadedAbsentDays = [];

        for (final record in absentData.records) {
          final dateStr = record.absenceDate;
          final date = dateStr.isNotEmpty
              ? DateTime.tryParse(dateStr) ?? ServerTimeService.instance.now()
              : ServerTimeService.instance.now();

          loadedAbsentDays.add(
            _AbsentDayModel(
              startDate: date,
              endDate: date,
              absentTime: _formatApiTime(record.markedAbsentTime),
              absentBy:
                  (record.markedAbsentByName ?? record.markedAbsentBy ?? '')
                      .toString(),
              note: record.absenceNote,
              markAbsentMethod: _mapAbsentMethodStringToEnum(
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

        if (!mounted) return;
        setState(() {
          attendanceReport = _AttendanceReportModel(
            attendedDays: attendanceReport?.attendedDays ?? 0,
            totalAttendedHours: attendanceReport?.totalAttendedHours ?? '',
            absentDays: absentDaysCount,
          );
          absentDays = loadedAbsentDays;
          isAbsentDaysLoading = false;
          isStudentLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          isAbsentDaysLoading = false;
          isStudentLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isAttendancesLoading = false;
        isAbsentDaysLoading = false;
        isStudentLoading = false;
      });
    }
  }

  Future<void> refreshData() async {
    await _loadData();
  }

  Future<void> _loadTodayStatus() async {
    final code = _activeStudentCode.trim();
    if (code.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _isTodayStatusLoading = true;
    });
    try {
      final status = await _profileCubit.fetchTodayStatus(studentCode: code);
      if (!mounted) return;
      setState(() {
        _todayStatusRaw = status;
        _isTodayStatusLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      // On error, disable actions to avoid allowing invalid flows.
      setState(() {
        _todayStatusRaw = null;
        _isTodayStatusLoading = false;
      });
    }
  }

  bool get _isActiveProfile {
    final status = (student?.profileStatus ?? widget.profileStatus)
        .toUpperCase();
    return status == 'A' || status == 'ACTIVE';
  }

  StudentAttendanceGate get _todayGate => studentAttendanceGateFromTodayStatus(
    isActiveProfile: _isActiveProfile,
    todayStatusRaw: _todayStatusRaw,
  );

  bool get _canSignIn =>
      !_isTodayStatusLoading &&
      _todayGate.canSignIn &&
      AttendancePermissionService.hasPermissionToManageStudentAttendance(
        context,
      );
  bool get _canSignOut =>
      !_isTodayStatusLoading &&
      _todayGate.canSignOut &&
      AttendancePermissionService.hasPermissionToManageStudentAttendance(
        context,
      );
  bool get _canTransfer =>
      !_isTodayStatusLoading &&
      _todayGate.canTransfer &&
      AttendancePermissionService.hasPermissionToManageStudentAttendance(
        context,
      );
  bool get _canMarkAbsent =>
      !_isTodayStatusLoading &&
      _todayGate.canMarkAbsent &&
      AttendancePermissionService.hasPermissionToManageStudentAttendance(
        context,
      );

  Future<Map<String, String>> _loadClassroomNameToCodeMap() async {
    try {
      return await _profileCubit.fetchClassroomNameToCodeMap();
    } catch (_) {
      return const <String, String>{};
    }
  }

  Future<Map<String, String>> _loadClassroomCodeToNameMap() async {
    final nameToCode = await _loadClassroomNameToCodeMap();
    return {for (final entry in nameToCode.entries) entry.value: entry.key};
  }

  Future<void> _handleStudentAction(String actionLabel) async {
    final current = student;
    if (current == null) return;

    // Disabled actions are already non-tappable in the pop-up and explain
    // themselves via the per-action tooltip, so just no-op here instead of
    // showing a generic snackbar.
    if ((actionLabel == 'Sign-in' && !_canSignIn) ||
        (actionLabel == 'Sign-Out' && !_canSignOut) ||
        (actionLabel == 'Transfer' && !_canTransfer) ||
        (actionLabel == 'Absent' && !_canMarkAbsent)) {
      return;
    }

    final classroomMap = await _loadClassroomNameToCodeMap();
    final classroomCode = (classroomMap[current.roomName] ?? '').trim();
    final entity = StudentEntity(
      id: current.id,
      studentCode: _activeStudentCode,
      fullName: current.name,
      roomId: 0,
      roomName: current.roomName,
      classroomCode: classroomCode,
      photoUuid: current.photoUuid ?? '',
      isExpectedToday: current.isExpectedToday,
    );

    Widget? target;
    if (actionLabel == 'Sign-in') {
      target = student_sign_in.StudentSignInForm(
        students: [entity],
        refreshCallback: refreshData,
      );
    } else if (actionLabel == 'Sign-Out') {
      target = student_sign_out.StudentSignOutForm(
        students: [entity],
        refreshCallback: refreshData,
      );
    } else if (actionLabel == 'Transfer') {
      target = student_transfer.StudentTransferForm(
        students: [entity],
        refreshCallback: refreshData,
        classroomNameToCode: classroomMap,
      );
    } else if (actionLabel == 'Absent') {
      target = student_absent.StudentMarkAbsentForm(
        students: [entity],
        refreshCallback: refreshData,
      );
    }

    if (target == null || !mounted) return;
    // GoRouter holdout (documented): carries a refreshCallback closure and a form-local StudentEntity list, which don't fit GoRouter's URL/extra model — kept as an imperative Navigator.push.
    await Navigator.push(context, MaterialPageRoute(builder: (_) => target!));
    if (!mounted) return;
    await refreshData();
  }

  void _onDateRangeSelected(DateTime startDate, DateTime? endDate) {
    // Use the exact dates the user picked. Snapping to start/end of month
    // here made every range collapse to the whole month, so a same-day
    // (10 Jun → 10 Jun) or any custom range never filtered.
    final effectiveEnd = endDate ?? startDate;
    setState(() {
      _startDate = startDate;
      _endDate = effectiveEnd;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final contentPadding = ResponsiveHelper(context).contentPadding;
    final isParentPersona = context.watch<RoleCubit>().isParent;

    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: true,
      // Highlight the Attendance tab while a parent views their child's profile.
      activeItemOverride: isParentPersona
          ? BottomNavigationItem.attendance
          : null,
      body: CustomRefreshIndicator(
        onRefresh: () async => refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: contentPadding.left,
            vertical: responsive.verticalSpacing / 2,
          ),
          child: Column(
            children: [
              SizedBox(height: responsive.verticalSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CustomDateTimeField(
                      hasLabel: false,
                      isRangePicker: true,
                      initialDate: _startDate,
                      label: 'Date Range',
                      onRangeSelected: (start, end) {
                        _onDateRangeSelected(start, end);
                      },
                    ),
                  ),
                  if (!isParentPersona) ...[
                    const SizedBox(width: AppSpacing.md),
                    StudentAttendanceVerticalPopUp(
                      students: const [],
                      refreshCallback: refreshData,
                      disabledActions: <String>{
                        if (!_canSignIn) 'Sign-in',
                        if (!_canSignOut) 'Sign-Out',
                        if (!_canTransfer) 'Transfer',
                        if (!_canMarkAbsent) 'Absent',
                      },
                      disabledReasons: _isTodayStatusLoading
                          ? const <String, String>{}
                          : studentAttendanceDisabledReasons(_todayGate),
                      onActionTap: _handleStudentAction,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Builder(
                builder: (context) {
                  return isStudentLoading &&
                          (isAttendancesLoading || isAbsentDaysLoading)
                      ? const AttendanceProfileShimmer()
                      : Column(
                          children: [
                            _StudentCard(
                              student: student,
                              activeStudentCode: _activeStudentCode,
                              isParentPersona: isParentPersona,
                              attendanceReport: attendanceReport,
                              onPresentTap: () {
                                context.push(
                                  StudentAttendanceTabbedView.routeName,
                                  extra: {'filter': 'Present'},
                                );
                              },
                              onAbsentTap: () {
                                context.push(
                                  StudentAttendanceTabbedView.routeName,
                                  extra: {'filter': 'Absent'},
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Toggle for showing absent days
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText.title(
                                  showAbsentDays
                                      ? 'Absent Days'
                                      : 'Present Days',
                                  style: AppTextStyles.heading18,
                                ),
                                CustomToggle(
                                  label: 'Show Absent',
                                  isToggled: showAbsentDays,
                                  onToggle: (value) {
                                    setState(() {
                                      showAbsentDays = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _StudentAttendanceListSection(
                              showAbsentDays: showAbsentDays,
                              isAttendancesLoading: isAttendancesLoading,
                              attendances: attendances,
                              isAbsentDaysLoading: isAbsentDaysLoading,
                              absentDays: absentDays,
                              fallbackRoomName:
                                  student?.roomName ?? widget.roomName,
                            ),
                          ],
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.activeStudentCode,
    required this.isParentPersona,
    required this.attendanceReport,
    required this.onPresentTap,
    required this.onAbsentTap,
  });

  final _StudentModel? student;
  final String activeStudentCode;
  final bool isParentPersona;
  final _AttendanceReportModel? attendanceReport;
  final VoidCallback onPresentTap;
  final VoidCallback onAbsentTap;

  @override
  Widget build(BuildContext context) {
    if (student == null) return const SizedBox.shrink();

    final responsive = ResponsiveHelper(context);
    final currentStudent = student!;

    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.cardColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: AppColors.primaryColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
        borderRadius: AppRadius.allLg,
      ),
      elevation: 6,
      shadowColor: AppColors.primaryColor.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: AppSpacing.s5),
                DocumentImageWidget(
                  fileUuid: currentStudent.photoUuid ?? '',
                  size: 80,
                  name: currentStudent.name,
                  fontSize: 24,
                  // Drive status dot purely from attendance API using studentCode.
                  studentCode: activeStudentCode,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.title(
                        currentStudent.name,
                        style: TextStyle(
                          fontSize: responsive.isTablet ? 23 : 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          AppText.body(
                            currentStudent.roomName,
                            style: AppTextStyles.mediumWeight,
                          ),
                          const SizedBox(width: 100),
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: AppText.title(
                                    'Details',
                                    style: AppTextStyles.heading18,
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!currentStudent.isPhotoPermission)
                                        _StudentIconDetail(
                                          MediaRes.cameraIcon,
                                          "No Photo Permission",
                                        ),
                                      if (currentStudent.medications.isNotEmpty)
                                        _StudentIconDetail(
                                          MediaRes.healthIcon,
                                          currentStudent.medications,
                                        ),
                                      if (currentStudent.note.isNotEmpty)
                                        _StudentIconDetail(
                                          MediaRes.docsIcon,
                                          currentStudent.note,
                                        ),
                                      if (currentStudent.allergies.isNotEmpty)
                                        _StudentIconDetail(
                                          MediaRes.alertIcon,
                                          currentStudent.allergies,
                                        ),
                                      if (currentStudent
                                          .dietRestriction
                                          .isNotEmpty)
                                        _StudentIconDetail(
                                          MediaRes.foodIcon2,
                                          currentStudent.dietRestriction,
                                        ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: AppText.body(
                                        'Close',
                                        style: AppTextStyles.mediumWeight,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                if (!currentStudent.isPhotoPermission)
                                  _StudentIconItem(MediaRes.cameraIcon),
                                if (currentStudent.medications.isNotEmpty)
                                  _StudentIconItem(MediaRes.healthIcon),
                                if (currentStudent.note.isNotEmpty)
                                  _StudentIconItem(MediaRes.docsIcon),
                                if (currentStudent.allergies.isNotEmpty)
                                  _StudentIconItem(MediaRes.alertIcon),
                                if (currentStudent.dietRestriction.isNotEmpty)
                                  _StudentIconItem(MediaRes.foodIcon2),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _StudentStatsSection(
              isParentPersona: isParentPersona,
              attendedDays: attendanceReport?.attendedDays,
              absentDays: attendanceReport?.absentDays,
              totalAttendedHours: attendanceReport?.totalAttendedHours,
              onPresentTap: onPresentTap,
              onAbsentTap: onAbsentTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentStatsSection extends StatelessWidget {
  const _StudentStatsSection({
    required this.isParentPersona,
    required this.attendedDays,
    required this.absentDays,
    required this.totalAttendedHours,
    required this.onPresentTap,
    required this.onAbsentTap,
  });

  final bool isParentPersona;
  final int? attendedDays;
  final int? absentDays;
  final String? totalAttendedHours;
  final VoidCallback onPresentTap;
  final VoidCallback onAbsentTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: isParentPersona ? null : onPresentTap,
          child: AttendanceProfileStatItem(
            icon: MediaRes.calenderClockIcon,
            iconColor: AppColors.attendanceStatBlueColor,
            label: 'Attended Days',
            value: attendedDays != null ? '$attendedDays' : '',
            valueColor: AppColors.attendanceStatGreenColor,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AttendanceProfileAttendedHoursStat(
          totalAttendedHours: totalAttendedHours,
        ),
        const SizedBox(height: AppSpacing.md),
        InkWell(
          onTap: isParentPersona ? null : onAbsentTap,
          child: AttendanceProfileStatItem(
            icon: MediaRes.calenderClockIcon,
            iconColor: AppColors.attendanceStatBlueColor,
            label: 'Absent Days',
            value: absentDays != null ? '$absentDays' : '',
            valueColor: AppColors.errorColor,
          ),
        ),
      ],
    );
  }
}

class _StudentAttendanceListSection extends StatelessWidget {
  const _StudentAttendanceListSection({
    required this.showAbsentDays,
    required this.isAttendancesLoading,
    required this.attendances,
    required this.isAbsentDaysLoading,
    required this.absentDays,
    required this.fallbackRoomName,
  });

  final bool showAbsentDays;
  final bool isAttendancesLoading;
  final List<_AttendanceModel> attendances;
  final bool isAbsentDaysLoading;
  final List<_AbsentDayModel> absentDays;
  final String fallbackRoomName;

  @override
  Widget build(BuildContext context) {
    if (showAbsentDays) {
      return _absentDaysList();
    }
    return _presentDaysList();
  }

  Widget _presentDaysList() {
    if (isAttendancesLoading) {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: 5,
        itemBuilder: (context, index) {
          return const ShimmerLoaderCard(child: SizedBox(height: 50));
        },
      );
    }

    if (attendances.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.r14),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: AppText.body(
            'No attendance records found for selected date range',
            style: AppTextStyles.size16,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: List.generate(attendances.length, (index) {
        return _StudentAttendanceItemCard(attendance: attendances[index]);
      }),
    );
  }

  Widget _absentDaysList() {
    if (isAbsentDaysLoading) {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: 5,
        itemBuilder: (context, index) {
          return const ShimmerLoaderCard(child: SizedBox(height: 50));
        },
      );
    }

    if (absentDays.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.r14),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: AppText.body(
            'No absent days found for selected date range',
            style: AppTextStyles.size16,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: List.generate(absentDays.length, (index) {
        return _StudentAbsentDayItemCard(
          absentDay: absentDays[index],
          fallbackRoomName: fallbackRoomName,
        );
      }),
    );
  }
}

class _StudentAttendanceItemCard extends StatelessWidget {
  const _StudentAttendanceItemCard({required this.attendance});

  final _AttendanceModel attendance;

  @override
  Widget build(BuildContext context) {
    final collapsedText = _formatAttendedTimeForCard(attendance);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExpansionTile(
        title: AppText.body(
          DateFormat('MMM dd, yyyy').format(attendance.date),
          style: AppTextStyles.mediumWeight,
        ),
        trailing: AppText.body(collapsedText, style: AppTextStyles.valueLarge),
        backgroundColor: AppColors.cardColor,
        collapsedBackgroundColor: AppColors.cardColor,
        collapsedShape: RoundedRectangleBorder(
          side: BorderSide(
            color: AppColors.primaryColor.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(AppRadius.r14),
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: AppColors.primaryColor.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(AppRadius.r14),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.none,
          AppSpacing.md,
          AppSpacing.md,
        ),
        children: [
          Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),
          const SizedBox(height: AppSpacing.md),
          AttendanceProfileField(label: 'Classroom', text: attendance.roomName),
          const SizedBox(height: AppSpacing.md),
          AttendanceProfileField(
            label: 'Sign In',
            text: formatTime(attendance.signInTime),
            showTransferIcon: attendance.isTransferSignIn,
            methodIcon: attendance.signInMethod != null
                ? _absentMethodIcon(attendance.signInMethod!)
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AttendanceProfileField(
            label: 'Sign In By',
            text: _resolveSignInByDisplay(
              attendance.signInBy,
              attendance.signInMethod,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AttendanceProfileField(
            label: 'Sign Out',
            text: formatTime(attendance.signOutTime),
            showTransferIcon: attendance.isTransferSignOut,
            methodIcon: attendance.signOutMethod != null
                ? _absentMethodIcon(attendance.signOutMethod!)
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AttendanceProfileField(
            label: 'Sign Out By',
            text: _resolveSignOutByDisplay(
              attendance.signOutBy,
              attendance.signOutMethod,
            ),
          ),
          if (_formatAttendedTimeForCard(attendance).trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            AttendanceProfileField(
              label: 'Attended Time',
              text: _formatAttendedTimeForCard(attendance),
            ),
          ],
          if (attendance.notExpectedComment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            AttendanceProfileField(
              label: 'Comment',
              text: attendance.notExpectedComment,
            ),
          ],
        ],
      ),
    );
  }
}

class _StudentAbsentDayItemCard extends StatelessWidget {
  const _StudentAbsentDayItemCard({
    required this.absentDay,
    required this.fallbackRoomName,
  });

  final _AbsentDayModel absentDay;
  final String fallbackRoomName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExpansionTile(
        title: AppText.body(
          DateFormat('MMM dd, yyyy').format(absentDay.startDate),
          style: AppTextStyles.mediumWeight,
        ),
        backgroundColor: AppColors.cardColor,
        collapsedBackgroundColor: AppColors.cardColor,
        collapsedShape: RoundedRectangleBorder(
          side: BorderSide(
            color: AppColors.primaryColor.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(AppRadius.r14),
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: AppColors.primaryColor.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(AppRadius.r14),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.none,
          AppSpacing.md,
          AppSpacing.md,
        ),
        children: [
          Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),
          const SizedBox(height: AppSpacing.md),
          AttendanceProfileField(
            label: 'Classroom',
            text: () {
              if (absentDay.classroomName.isNotEmpty) {
                return absentDay.classroomName;
              }
              final fallback = fallbackRoomName;
              return (fallback.trim().isNotEmpty &&
                      fallback != '-' &&
                      fallback != '—')
                  ? fallback
                  : '';
            }(),
          ),
          const SizedBox(height: AppSpacing.md),
          AttendanceProfileField(
            label: 'Date',
            text:
                '${DateFormat('MMM dd, yyyy').format(absentDay.startDate)} - ${DateFormat('MMM dd, yyyy').format(absentDay.endDate)}',
          ),
          const SizedBox(height: AppSpacing.md),
          AttendanceProfileField(
            label: 'Marked By',
            text: getFirstName(absentDay.absentBy),
          ),
          const SizedBox(height: AppSpacing.md),
          AttendanceProfileField(
            label: 'Marked Absent Time',
            text: formatTime(absentDay.absentTime),
            methodIcon: absentDay.markAbsentMethod != null
                ? _absentMethodIcon(absentDay.markAbsentMethod!)
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AttendanceProfileField(
            label: 'Absent Note',
            text: absentDay.note.isNotEmpty ? absentDay.note : '-',
          ),
        ],
      ),
    );
  }
}

class _StudentIconItem extends StatelessWidget {
  const _StudentIconItem(this.icon);

  final String icon;

  @override
  Widget build(BuildContext context) {
    final bool isSvg = icon.toLowerCase().endsWith('.svg');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
      child: isSvg
          ? SvgPicture.asset(icon, height: 20)
          : Image.asset(icon, height: 20),
    );
  }
}

class _StudentIconDetail extends StatelessWidget {
  const _StudentIconDetail(this.iconPath, this.detail);

  final String iconPath;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final bool isSvg = iconPath.toLowerCase().endsWith('.svg');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          isSvg
              ? SvgPicture.asset(iconPath, height: 24)
              : Image.asset(iconPath, height: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppText.body(
              detail,
              style: AppTextStyles.body.copyWith(
                color: AppColors.attendanceBodyText87Color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
