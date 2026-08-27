import 'package:flutter/material.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/shared/common/app/cubit/bottom_navigation_item.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/simmer_loader.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/core/util/attendance_classroom_scope.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/attendance_attended_duration.dart';
import 'package:wowcare/presentation/features/attendance/widgets/staff_attendance_vertical_popup.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_usecase.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_attendance_action_availability.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_transfer_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_mark_absent_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_entity.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_school_time.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/core/util/server_time_service.dart';

// enum StaffProfileAbsentMarkMethod { gps, qr, kiosk, app, web }
enum StaffProfileAbsentMarkMethod {
  app,
  gps,
  qr,
  kiosk,
  web,
  pin,
  transfer,
  nfc,
  biometric,
  system,
}

// Simple field widget for displaying label and text
class _AttendanceField extends StatelessWidget {
  final String label;
  final String text;
  final bool showTransferIcon;
  final StaffProfileAbsentMarkMethod? markMethod;

  const _AttendanceField({
    required this.label,
    required this.text,
    this.showTransferIcon = false,
    this.markMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xff573353),
              height: 16 / 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (showTransferIcon) ...[
                Tooltip(
                  message: 'Transfer',
                  child: SvgPicture.asset(
                    MediaRes.transfer,
                    width: 16,
                    height: 16,
                    colorFilter: const ColorFilter.mode(
                      AppColors.themeColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s6),
              ],
              if (markMethod != null) ...[
                _methodIcon(markMethod!),
                const SizedBox(width: AppSpacing.s6),
              ],
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff573353),
                    height: 19 / 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _methodIcon(StaffProfileAbsentMarkMethod method) {
    const double size = 16;
    switch (method) {
      case StaffProfileAbsentMarkMethod.gps:
        return Tooltip(
          message: 'GPS',
          child: SvgPicture.asset(
            MediaRes.gpsMethodIcon,
            width: size,
            height: size,
          ),
        );
      case StaffProfileAbsentMarkMethod.qr:
        return Tooltip(
          message: 'QR',
          child: SvgPicture.asset(
            MediaRes.qrAttendanceIcon,
            width: size,
            height: size,
          ),
        );
      case StaffProfileAbsentMarkMethod.kiosk:
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
      case StaffProfileAbsentMarkMethod.app:
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
      case StaffProfileAbsentMarkMethod.web:
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

      case StaffProfileAbsentMarkMethod.pin:
        // TODO: Handle this case.
        return Tooltip(
          message: 'PIN',
          child: SvgPicture.asset(
            MediaRes.pinMethodIcon,
            width: size,
            height: size,
            colorFilter: const ColorFilter.mode(
              AppColors.themeColor,
              BlendMode.srcIn,
            ),
          ),
        );
      case StaffProfileAbsentMarkMethod.transfer:
        // TODO: Handle this case.
        return Tooltip(
          message: 'Transfer',
          child: SvgPicture.asset(
            MediaRes.transferMethodIcon,
            width: size,
            height: size,
            colorFilter: const ColorFilter.mode(
              AppColors.themeColor,
              BlendMode.srcIn,
            ),
          ),
        );
      case StaffProfileAbsentMarkMethod.nfc:
        // TODO: Handle this case.
        return Tooltip(
          message: 'NFC',
          child: SvgPicture.asset(
            MediaRes.nfcMethodIcon,
            width: size,
            height: size,
            colorFilter: const ColorFilter.mode(
              AppColors.themeColor,
              BlendMode.srcIn,
            ),
          ),
        );
      case StaffProfileAbsentMarkMethod.biometric:
        // TODO: Handle this case.
        return Tooltip(
          message: 'Biometric',
          child: SvgPicture.asset(
            MediaRes.biometricMethodIcon,
            width: size,
            height: size,
            colorFilter: const ColorFilter.mode(
              AppColors.themeColor,
              BlendMode.srcIn,
            ),
          ),
        );
      case StaffProfileAbsentMarkMethod.system:
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
  final StaffProfileAbsentMarkMethod? signInMethod;
  final StaffProfileAbsentMarkMethod? signOutMethod;
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
  final StaffProfileAbsentMarkMethod? markAbsentMethod;
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

class _StaffModel {
  final int id;
  final String name;
  final String? photoUuid;
  final String? designationName;
  final String roomName;
  final bool isSignedIn;
  final bool isAbsent;
  final bool isExpectedToday;
  final bool isPresentToday;
  final String profileStatus;

  _StaffModel({
    required this.id,
    required this.name,
    this.photoUuid,
    this.designationName,
    required this.roomName,
    this.isSignedIn = false,
    this.isAbsent = false,
    this.isExpectedToday = true,
    this.isPresentToday = false,
    this.profileStatus = 'A',
  });

  _StaffModel copyWith({
    String? name,
    String? designationName,
    String? roomName,
    String? photoUuid,
  }) {
    return _StaffModel(
      id: id,
      name: name ?? this.name,
      photoUuid: photoUuid ?? this.photoUuid,
      designationName: designationName ?? this.designationName,
      roomName: roomName ?? this.roomName,
      isSignedIn: isSignedIn,
      isAbsent: isAbsent,
      isExpectedToday: isExpectedToday,
      isPresentToday: isPresentToday,
      profileStatus: profileStatus,
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

class StaffAttendanceProfile extends StatefulWidget {
  static const String routeName = '/dashboard/staff-attendance-profile';

  const StaffAttendanceProfile({
    super.key,
    required this.staffCode,
    required this.staffId,
    required this.staffName,
    this.staffPhotoUuid,
    this.designationName,
    required this.roomName,
    this.isSignedIn = false,
    this.isAbsent = false,
    this.isExpectedToday = true,
    this.isPresentToday = false,
    this.profileStatus = 'A',
    this.initialShowAbsentDays = false,
  });

  final String staffCode;
  final int staffId;
  final String staffName;
  final String? staffPhotoUuid;
  final String? designationName;
  final String roomName;
  final bool isSignedIn;
  final bool isAbsent;
  final bool isExpectedToday;
  final bool isPresentToday;
  final String profileStatus;

  /// When true, opens the profile with the absent-days list visible (e.g. Absent tab).
  final bool initialShowAbsentDays;

  @override
  State<StaffAttendanceProfile> createState() => _StaffAttendanceProfileState();
}

class _StaffAttendanceProfileState extends State<StaffAttendanceProfile> {
  DateTime _startOfMonth(DateTime date) => DateTime(date.year, date.month, 1);

  DateTime _endOfMonth(DateTime date) => DateTime(date.year, date.month + 1, 0);

  StaffProfileAbsentMarkMethod? _mapAbsentMethodStringToEnum(String? method) {
    if (method == null) return null;
    switch (method.trim().toUpperCase()) {
      case 'GPS':
        return StaffProfileAbsentMarkMethod.gps;
      case 'PIN':
      case 'KIOSK':
        return StaffProfileAbsentMarkMethod.kiosk;
      case 'QR':
        return StaffProfileAbsentMarkMethod.qr;
      case 'APP':
        return StaffProfileAbsentMarkMethod.app;
      case 'WEB':
        return StaffProfileAbsentMarkMethod.web;
      case 'SYSTEM':
        return StaffProfileAbsentMarkMethod.system;
      default:
        return null;
    }
  }

  DateTime? _startDate;
  DateTime? _endDate;
  bool isAttendancesLoading = false;
  bool isAbsentDaysLoading = false;
  bool isStaffLoading = false;
  bool showAbsentDays = false;
  int? expandedIndex;

  List<_AttendanceModel> attendances = [];
  List<_AbsentDayModel> absentDays = [];
  _StaffModel? staff;
  _AttendanceReportModel? attendanceReport;
  String? _todayStatusRaw;
  // Starts true (rather than false) so Sign-In/Sign-Out/Transfer/Mark-Absent
  // render disabled until the real today-status has been fetched — defaulting
  // to false let the gate fall back to its "not signed in" assumption during
  // the fetch window, wrongly enabling Sign-In/Mark-Absent for staff who were
  // already signed in.
  bool _isTodayStatusLoading = true;

  /// Helper to format API time (either a string or {hour, minute, ...} map)
  /// into 'hh:mm:ss a' which works with the existing `formatTime` helper.
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

  @override
  void initState() {
    super.initState();
    showAbsentDays = widget.initialShowAbsentDays;
    final now = ServerTimeService.instance.now();
    _startDate = _startOfMonth(now);
    _endDate = _endOfMonth(now);

    // Initialize staff model
    staff = _StaffModel(
      id: widget.staffId,
      name: widget.staffName,
      photoUuid: widget.staffPhotoUuid,
      designationName: widget.designationName,
      roomName: widget.roomName,
      isSignedIn: widget.isSignedIn,
      isAbsent: widget.isAbsent,
      isExpectedToday: widget.isExpectedToday,
      isPresentToday: widget.isPresentToday,
      profileStatus: widget.profileStatus,
    );

    _loadData();
    // Deep-link (e.g. ATTENDANCE_NOT_MARKED for staff) opens this with only a
    // staffCode — the attendance API doesn't return the staff's name/classroom,
    // so fetch the identity by code to fill the header.
    _ensureHeaderIdentityLoaded();
  }

  /// Fills the header name + designation + classroom when opened by code
  /// without them (notification deep-link). No-op for normal navigation that
  /// already supplied [staffName].
  Future<void> _ensureHeaderIdentityLoaded() async {
    final hasName =
        widget.staffName.trim().isNotEmpty && widget.staffName.trim() != '-';
    final _classroomVal = (staff?.roomName ?? widget.roomName).trim();
    final hasClassroom =
        _classroomVal.isNotEmpty &&
        _classroomVal != '-' &&
        _classroomVal != '—';
    // Skip the fetch only when both the name and a real primary classroom name
    // (not a placeholder) are already available.
    if (hasName && hasClassroom) return;
    final code = widget.staffCode.trim();
    if (code.isEmpty) return;
    try {
      // forEditStaff:true hits /staff/{code}/profile, which carries name,
      // designation and primaryClassroom name.
      final profile = await serviceLocator<StaffRepository>().getStaffProfile(
        staffCode: code,
        forEditStaff: true,
      );
      if (!mounted) return;
      final current = staff;
      if (current == null) return;
      final name = profile.fullName.trim();
      final designation = profile.designation.trim();
      final classroom = profile.primaryClassroomName.trim();
      setState(() {
        staff = current.copyWith(
          name: name.isNotEmpty ? name : current.name,
          designationName: designation.isNotEmpty
              ? designation
              : current.designationName,
          roomName: classroom.isNotEmpty ? classroom : current.roomName,
        );
      });
    } catch (_) {
      // Header stays as-is; attendance data still loads.
    }
  }

  Future<void> _loadData() async {
    if (widget.staffCode.isEmpty) {
      setState(() {
        isAttendancesLoading = false;
        isAbsentDaysLoading = false;
        isStaffLoading = false;
      });
      return;
    }

    final from = _startDate ?? ServerTimeService.instance.now();
    final to = _endDate ?? from;

    setState(() {
      isAttendancesLoading = true;
      isAbsentDaysLoading = true;
      isStaffLoading = true;
    });

    await _loadTodayStatus();

    final fromStr = DateFormat('yyyy-MM-dd').format(from);
    final toStr = DateFormat('yyyy-MM-dd').format(to);

    final queryParameters = <String, dynamic>{
      'staffCode': widget.staffCode,
      'fromAttendanceDate': fromStr,
      'toAttendanceDate': toStr,
      'page': 0,
      'size': 10,
      'sort': <String>['attendanceDate,desc'],
    };

    final allowedClassroomCodes = await resolveAttendanceAllowedClassroomCodes(
      storage: serviceLocator<StorageService>(),
    );
    queryParameters['allowedClassroomCodes'] = List<String>.from(
      allowedClassroomCodes,
    );

    try {
      // ---------- Load staff attendance profile (present days / summary) ----------
      final data = await serviceLocator<AttendanceRepository>()
          .fetchStaffAttendanceProfile(queryParameters: queryParameters);
      if (data is Map<String, dynamic>) {
        final root = data['data'] as Map<String, dynamic>? ?? {};
        final aggJson = root['aggregations'] as Map<String, dynamic>? ?? {};
        final recordsJson = root['records'] as Map<String, dynamic>? ?? {};
        final content = recordsJson['content'] as List<dynamic>? ?? const [];

        // Aggregations
        final attendedDays = (aggJson['attendedDays'] as int?) ?? 0;
        final totalAttendedHours =
            (aggJson['totalAttendedTime'] as String?) ?? '';
        final initialAbsentDays = (aggJson['absentDays'] as int?) ?? 0;

        // Records
        final loadedAttendances = content.map<_AttendanceModel>((e) {
          final m = e as Map<String, dynamic>;

          final dateStr = m['attendanceDate'] as String? ?? '';
          final parsedDate = dateStr.isNotEmpty
              ? DateTime.tryParse(dateStr) ?? ServerTimeService.instance.now()
              : ServerTimeService.instance.now();

          final int sequenceNumber = m['sequenceNumber'] as int? ?? 1;
          final int totalSequenceCount = m['totalSequenceCount'] as int? ?? 1;

          // Keep raw times in 'hh:mm:ss a' format so existing duration parsing works.
          final signedInRaw = _formatApiTime(m['signedInTime']);
          final signedOutRaw = _formatApiTime(m['signedOutTime']);
          final transferRaw = _formatApiTime(m['transferTime']);
          final nextActionRaw = _formatApiTime(m['nextActionTime']);

          String effectiveSignIn = signedInRaw;
          String effectiveSignOut = signedOutRaw;
          bool isTransferSignIn = false;
          bool isTransferSignOut = false;

          if (totalSequenceCount > 1) {
            final isFirst = sequenceNumber == 1;
            final isLast = sequenceNumber == totalSequenceCount;

            if (isFirst && !isLast) {
              effectiveSignIn = signedInRaw;
              effectiveSignOut = nextActionRaw;
              isTransferSignOut = effectiveSignOut.trim().isNotEmpty;
            } else if (!isFirst && !isLast) {
              effectiveSignIn = transferRaw;
              effectiveSignOut = nextActionRaw;
              isTransferSignIn = effectiveSignIn.trim().isNotEmpty;
              isTransferSignOut = effectiveSignOut.trim().isNotEmpty;
            } else if (isLast) {
              effectiveSignIn = isFirst ? signedInRaw : transferRaw;
              effectiveSignOut = signedOutRaw;
              isTransferSignIn = !isFirst && effectiveSignIn.trim().isNotEmpty;
            }
          }

          final signOutMethodEnum = _mapAbsentMethodStringToEnum(
            m['signedOutMethod'] as String?,
          );
          // On a classroom transfer the "sign in/out" for that segment is the
          // transfer itself, performed by `transferredBy`. The API leaves
          // signedInBy/signedOutBy empty on transfer records, so fall back to
          // transferredBy for the person's name.
          final transferredBy = ((m['transferredBy'] as String?) ?? '').trim();

          final rawSignedInBy = ((m['signedInBy'] as String?) ?? '').trim();
          final signInByText = rawSignedInBy.isNotEmpty
              ? rawSignedInBy
              : (isTransferSignIn ? transferredBy : '');

          // Auto sign-out has no person: the API sends signedOutMethod=SYSTEM
          // with an empty signedOutBy. Show "System" (web parity) so the row
          // isn't blank; keep the real name / transfer person when present.
          final rawSignedOutBy = ((m['signedOutBy'] as String?) ?? '').trim();
          final signOutByText = rawSignedOutBy.isNotEmpty
              ? rawSignedOutBy
              : (isTransferSignOut && transferredBy.isNotEmpty
                  ? transferredBy
                  : (signOutMethodEnum == StaffProfileAbsentMarkMethod.system
                      ? 'System'
                      : ''));

          return _AttendanceModel(
            date: parsedDate,
            signInTime: effectiveSignIn,
            signOutTime: effectiveSignOut,
            roomName: (m['classroomName'] as String?) ?? widget.roomName,
            signInBy: signInByText,
            signOutBy: signOutByText,
            attendedTime: (m['attendedTime'] as String?) ?? '',
            attendedHours: (m['attendedHours'] as int?) ?? 0,
            attendedMinutes: (m['attendedMinutes'] as int?) ?? 0,
            isTransferSignIn: isTransferSignIn,
            isTransferSignOut: isTransferSignOut,
            signInMethod: _mapAbsentMethodStringToEnum(
              m['signedInMethod'] as String?,
            ),
            signOutMethod: signOutMethodEnum,
            notExpectedComment: ((m['notExpectedComment'] as String?) ?? '')
                .trim(),
          );
        }).toList();

        if (mounted) {
          setState(() {
            attendanceReport = _AttendanceReportModel(
              attendedDays: attendedDays,
              totalAttendedHours: totalAttendedHours,
              absentDays: initialAbsentDays,
            );
            attendances = loadedAttendances;
            isAttendancesLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isAttendancesLoading = false;
          });
        }
      }

      // ---------- Load staff absent profile for toggle list ----------
      final absentQueryParameters = <String, dynamic>{
        'staffCode': widget.staffCode,
        'fromAbsenceDate': fromStr,
        'toAbsenceDate': toStr,
        'page': 0,
        'size': 10,
        'sort': <String>['absenceDate,desc'],
        // Swagger lists pageable as required for this endpoint.
        // Keep both styles to remain backward compatible across environments.
        'pageable.page': 0,
        'pageable.size': 10,
        'pageable.sort': <String>['absenceDate,desc'],
      };

      absentQueryParameters['allowedClassroomCodes'] = List<String>.from(
        allowedClassroomCodes,
      );

      final absentData = await serviceLocator<AttendanceRepository>()
          .fetchStaffAttendanceProfileAbsentToggle(
            queryParameters: absentQueryParameters,
          );
      if (absentData is Map<String, dynamic>) {
        final root = absentData['data'] as Map<String, dynamic>? ?? {};
        final agg = root['aggregations'] as Map<String, dynamic>? ?? {};
        final records = root['records'] as Map<String, dynamic>? ?? {};
        final content = records['content'] as List<dynamic>? ?? const [];

        final absentDaysCount = agg['absentDays'] as int? ?? 0;

        final loadedAbsentDays = content.map<_AbsentDayModel>((e) {
          final m = e as Map<String, dynamic>;
          final dateStr = m['absenceDate'] as String? ?? '';
          final date = dateStr.isNotEmpty
              ? DateTime.tryParse(dateStr) ?? ServerTimeService.instance.now()
              : ServerTimeService.instance.now();

          return _AbsentDayModel(
            startDate: date,
            endDate: date,
            absentTime: _formatApiTime(m['markedAbsentTime']),
            absentBy: (m['markedAbsentByName'] ?? m['markedAbsentBy'] ?? '')
                .toString(),
            note: m['absenceNote'] as String? ?? '',
            markAbsentMethod: _mapAbsentMethodStringToEnum(
              m['markAbsentMethod'] as String?,
            ),
            classroomName: () {
              final name = (m['classroomName'] as String?)?.trim() ?? '';
              if (name.isNotEmpty) return name;
              final code = (m['classroomCode'] as String?)?.trim() ?? '';
              return code; // render-time fallback uses staff?.roomName
            }(),
          );
        }).toList();

        if (mounted) {
          setState(() {
            attendanceReport = _AttendanceReportModel(
              attendedDays: attendanceReport?.attendedDays ?? 0,
              totalAttendedHours: attendanceReport?.totalAttendedHours ?? '',
              absentDays: absentDaysCount,
            );
            absentDays = loadedAbsentDays;
            isAbsentDaysLoading = false;
            isStaffLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isAbsentDaysLoading = false;
            isStaffLoading = false;
          });
        }
      }
    } catch (error, stack) {
      AppLogger.d('StaffAttendanceProfile API error: $error');
      AppLogger.d('$stack');
      if (!mounted) return;
      setState(() {
        isAttendancesLoading = false;
        isAbsentDaysLoading = false;
        isStaffLoading = false;
      });
    }
  }

  Future<void> refreshData() async {
    await _loadData();
  }

  Future<void> _loadTodayStatus() async {
    final code = widget.staffCode.trim();
    if (code.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _isTodayStatusLoading = true;
    });
    try {
      final useCase = serviceLocator<GetStaffTodaySignInStatusUseCase>();
      final status = await useCase(staffCode: code);
      if (!mounted) return;
      setState(() {
        _todayStatusRaw = status;
        _isTodayStatusLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _todayStatusRaw = null;
        _isTodayStatusLoading = false;
      });
    }
  }

  bool get _isActiveProfile {
    final status = (staff?.profileStatus ?? widget.profileStatus).toUpperCase();
    return status == 'A' || status == 'ACTIVE';
  }

  StaffAttendanceGate get _todayGate => staffAttendanceGateFromTodayStatus(
    isActiveProfile: _isActiveProfile,
    todayStatusRaw: _todayStatusRaw,
    // Admin-only override: an admin viewing another staff member's profile
    // can sign them in even after they were marked absent for the day,
    // which clears that absence record. The staff persona's own "My
    // Attendance" view (self) never gets this — no self-service recovery.
    allowAbsentSignInOverride: !_isSelfStaffPersona,
  );

  /// This screen doubles as the staff persona's own "My Attendance" profile
  /// (opened via the drawer, `staffId == 0`) and as the admin's read-only
  /// view of another staff member's attendance. Geofencing only applies to
  /// the former — an admin managing someone else's record isn't expected to
  /// be standing at that staff member's location.
  bool get _isSelfStaffPersona => context.read<RoleCubit>().isStaff;

  bool get _isWithinGeofence {
    if (!_isSelfStaffPersona) return true;
    return context.read<GeofenceCubit>().state.isWithinGeofence;
  }

  StaffAttendanceActionAvailability get _availability =>
      _todayGate.availabilityWithGeofence(_isWithinGeofence);

  bool get _canSignIn => !_isTodayStatusLoading && _availability.signInEnabled;
  bool get _canSignOut =>
      !_isTodayStatusLoading && _availability.signOutEnabled;
  bool get _canTransfer =>
      !_isTodayStatusLoading && _availability.transferEnabled;
  bool get _canMarkAbsent =>
      !_isTodayStatusLoading && _availability.absentEnabled;

  Future<void> _handleStaffAction(String actionLabel) async {
    final current = staff;
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

    final entity = StaffEntity(
      id: current.id,
      name: current.name,
      primaryRoomId: 0,
      photoUuid: current.photoUuid,
      designation: current.designationName ?? 'Staff',
      staffCode: widget.staffCode,
      isExpectedToday: widget.isExpectedToday,
    );

    Widget? target;
    if (actionLabel == 'Sign-in') {
      target = StaffSignInForm(staff: entity);
    } else if (actionLabel == 'Sign-Out') {
      target = StaffSignOutForm(staff: entity);
    } else if (actionLabel == 'Transfer') {
      target = StaffTransferForm(staff: entity);
    } else if (actionLabel == 'Absent') {
      target = StaffMarkAbsentForm(staff: entity);
    }

    if (target == null || !mounted) return;
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
    final contentPadding = ResponsiveSizing.contentPadding(context);

    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: true,
      // This is an Attendance screen opened from the Attendance nav popup and is
      // pushed on the root navigator (no shell in context), so the nav bar would
      // otherwise default to highlighting Dashboard. Pin the highlight to the
      // Attendance slot (index 1) — mirrors StudentAttendanceProfile.
      activeItemOverride: BottomNavigationItem.attendance,
      body: CustomRefreshIndicator(
        onRefresh: () async => refreshData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: contentPadding.left,
            vertical: ResponsiveHelper(context).verticalSpacing / 2,
          ),
          child: Column(
            children: [
              SizedBox(height: ResponsiveHelper(context).verticalSpacing),
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
                  const SizedBox(width: AppSpacing.md),
                  _buildPopupMenu(),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Builder(
                builder: (context) {
                  return isStaffLoading &&
                          (isAttendancesLoading || isAbsentDaysLoading)
                      ? _buildAttendanceShimmer()
                      : Column(
                          children: [
                            _buildStaffCard(),
                            const SizedBox(height: AppSpacing.md),
                            // Toggle for showing absent days
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText.title(
                                  showAbsentDays
                                      ? 'Absent Days'
                                      : 'Present Days',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                            _buildAttendanceList(),
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

  Widget _buildPopupMenu() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isLargeTablet = screenWidth >= 900;

    return GradientAddButton(
      onTap: () {
        _showActionMenu(context);
      },
      isTablet: isTablet,
      isLargeTablet: isLargeTablet,
      isRectangle: true,
    );
  }

  void _showActionMenu(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final contentPadding = ResponsiveSizing.contentPadding(context);
    final safeAreaTop = mediaQuery.padding.top;
    final appBarHeight = AppBar().preferredSize.height;
    final double screenWidth = mediaQuery.size.width;
    final bool isTablet = screenWidth >= 600;
    final bool isLargeTablet = screenWidth >= 900;
    final double floatingButtonSize = isLargeTablet
        ? 72.0
        : (isTablet ? 56.0 : 40.0);
    final floatingButtonTop =
        safeAreaTop +
        appBarHeight +
        (kTextTabBarHeight - floatingButtonSize) / 2;
    final floatingButtonRight = contentPadding.right;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          // Pin the menu flush below the + button (top-right) and give it the
          // full height beneath the button. A large `bottom` inset here used to
          // squeeze the centered band so short it cropped the last action
          // ("Absent"); topRight alignment + no bottom inset lets all 4 fit.
          alignment: Alignment.topRight,
          insetPadding: EdgeInsets.only(
            top: floatingButtonTop + floatingButtonSize + 8,
            left: mediaQuery.size.width * 0.75,
            right: floatingButtonRight,
          ),
          child: StaffAttendanceVerticalPopupOnly(
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
                : staffAttendanceDisabledReasonsWithGeofence(
                    _todayGate,
                    isWithinGeofence: _isWithinGeofence,
                  ),
            onActionTap: _handleStaffAction,
          ),
        );
      },
    );
  }

  /// Cleans an enum-style designation from the API into a human label, e.g.
  /// "ASSISTANT_TEACHER" -> "Assistant Teacher", "DIRECTOR" -> "Director".
  String _formatDesignation(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return '-';
    return raw
        .split(RegExp(r'[_\s]+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }

  Widget _buildStaffCard() {
    if (staff == null) return const SizedBox.shrink();

    final currentStaff = staff!;

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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: AppSpacing.s5),
                DocumentImageWidget(
                  fileUuid: currentStaff.photoUuid ?? '',
                  size: 80,
                  name: currentStaff.name,
                  fontSize: 24,
                  // Drive status dot purely from attendance API using staffCode.
                  staffCode: widget.staffCode,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.title(
                        currentStaff.name,
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).isTablet
                              ? 23
                              : 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      // Staff persona: show the primary classroom name.
                      // Admin persona: show the designation, cleaned up
                      // (e.g. ASSISTANT_TEACHER -> Assistant Teacher) instead
                      // of the raw enum value from the API.
                      if (context.read<RoleCubit>().isStaff)
                        AppText.body(
                          currentStaff.roomName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        )
                      else
                        AppText.body(
                          _formatDesignation(currentStaff.designationName),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildStats(),
          ],
        ),
      ),
    );
  }

  /// Attended/Absent Days cards navigate to [StaffAttendanceTabbedView], which
  /// lists ALL staff — an admin-only surface. A staff persona viewing their
  /// own "My Attendance" profile must never be able to reach it, so those
  /// cards are non-tappable for that persona (self-service view only).
  bool get _canOpenStaffTabbedViewFromStats => !_isSelfStaffPersona;

  Widget _buildStats() {
    if (attendanceReport == null) {
      return Column(
        children: [
          InkWell(
            onTap: _canOpenStaffTabbedViewFromStats
                ? () {
                    context.push(
                      StaffAttendanceTabbedView.routeName,
                      extra: {'filter': 'Present'},
                    );
                  }
                : null,
            child: _buildStatItem(
              icon: MediaRes.calenderClockIcon,
              iconColor: const Color(0xFF4285F4),
              label: 'Attended Days',
              value: '',
              valueColor: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildAttendedHoursStat(report: null),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: _canOpenStaffTabbedViewFromStats
                ? () {
                    context.push(
                      StaffAttendanceTabbedView.routeName,
                      extra: {'filter': 'Absent'},
                    );
                  }
                : null,
            child: _buildStatItem(
              icon: MediaRes.calenderClockIcon,
              iconColor: const Color(0xFF4285F4),
              label: 'Absent Days',
              value: '',
              valueColor: Colors.red,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        InkWell(
          onTap: _canOpenStaffTabbedViewFromStats
              ? () {
                  context.push(
                    StaffAttendanceTabbedView.routeName,
                    extra: {'filter': 'Present'},
                  );
                }
              : null,
          child: _buildStatItem(
            icon: MediaRes.calenderClockIcon,
            iconColor: const Color(0xFF4285F4),
            label: 'Attended Days',
            value: '${attendanceReport!.attendedDays}',
            valueColor: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildAttendedHoursStat(report: attendanceReport),
        const SizedBox(height: AppSpacing.md),
        InkWell(
          onTap: _canOpenStaffTabbedViewFromStats
              ? () {
                  context.push(
                    StaffAttendanceTabbedView.routeName,
                    extra: {'filter': 'Absent'},
                  );
                }
              : null,
          child: _buildStatItem(
            icon: MediaRes.calenderClockIcon,
            iconColor: const Color(0xFF4285F4),
            label: 'Absent Days',
            value: '${attendanceReport!.absentDays}',
            valueColor: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendedHoursStat({required _AttendanceReportModel? report}) {
    int hours = 0;
    int minutes = 0;

    // Parse strings like "5 Hrs 30 Mins".
    if (report != null && report.totalAttendedHours.isNotEmpty) {
      final parts = report.totalAttendedHours.split(' ');
      if (parts.length >= 4) {
        hours = int.tryParse(parts[0]) ?? 0;
        minutes = int.tryParse(parts[2]) ?? 0;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10, horizontal: 15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12, width: 1),
        borderRadius: AppRadius.allMd,
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            MediaRes.timerIcon,
            height: 22,
            colorFilter: const ColorFilter.mode(
              Color(0xFF4285F4),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const AppText.body(
            'Attended Hours',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Row(
            children: [
              _buildValueCircle(
                text: '${hours}h',
                color: const Color(0xFF4285F4),
              ),
              const SizedBox(width: AppSpacing.xs),
              _buildValueCircle(
                text: '${minutes}m',
                color: const Color(0xFF4285F4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueCircle({required String text, required Color color}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: AppText.body(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10, horizontal: 15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12, width: 1),
        borderRadius: AppRadius.allMd,
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            icon,
            height: 22,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppText.body(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: valueColor, width: 1.5),
            ),
            child: Center(
              child: AppText.body(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    if (showAbsentDays) {
      return _buildAbsentDaysList();
    } else {
      return _buildPresentDaysList();
    }
  }

  Widget _buildPresentDaysList() {
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
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: List.generate(attendances.length, (index) {
        return _buildAttendanceItem(index);
      }),
    );
  }

  Widget _buildAbsentDaysList() {
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
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: List.generate(absentDays.length, (index) {
        return _buildAbsentDayItem(index);
      }),
    );
  }

  String getFirstName(String name) {
    // Show the full name (first + last), not just the first word.
    return name.trim();
  }

  String formatTime(String time) {
    if (time.trim().isEmpty) return 'Not Yet Signed Out';
    return _formatTime12h(time);
  }

  bool _isKioskOrPinMethodEnum(StaffProfileAbsentMarkMethod? method) {
    return method == StaffProfileAbsentMarkMethod.kiosk ||
        method == StaffProfileAbsentMarkMethod.pin;
  }

  String _resolveSignInByDisplay(String signInBy, StaffProfileAbsentMarkMethod? method) {
    final name = signInBy.trim();
    if (name.isNotEmpty) return name;
    if (_isKioskOrPinMethodEnum(method)) return 'Kiosk';
    return '';
  }

  String _resolveSignOutByDisplay(String signOutBy, StaffProfileAbsentMarkMethod? method) {
    final name = signOutBy.trim();
    if (name.isNotEmpty) return name;
    if (_isKioskOrPinMethodEnum(method)) return 'Kiosk';
    return '';
  }

  Widget _buildAttendanceItem(int index) {
    final attendance = attendances[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExpansionTile(
        title: AppText.body(
          DateFormat('MMM dd, yyyy').format(attendance.date),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: AppText.body(
          _formatAttendedTimeForCard(attendance),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.none, AppSpacing.md, AppSpacing.md),
        onExpansionChanged: (expanded) {
          setState(() {
            expandedIndex = expanded ? index : null;
          });
        },
        children: [
          Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),
          const SizedBox(height: AppSpacing.md),
          _AttendanceField(label: 'Classroom', text: attendance.roomName),
          const SizedBox(height: AppSpacing.md),
          _AttendanceField(
            label: 'Sign In',
            text: formatTime(attendance.signInTime),
            showTransferIcon: attendance.isTransferSignIn,
            markMethod: attendance.signInMethod,
          ),
          const SizedBox(height: AppSpacing.md),
          _AttendanceField(
            label: 'Sign In By',
            text: _resolveSignInByDisplay(attendance.signInBy, attendance.signInMethod),
          ),
          const SizedBox(height: AppSpacing.md),
          _AttendanceField(
            label: 'Sign Out',
            text: formatTime(attendance.signOutTime),
            showTransferIcon: attendance.isTransferSignOut,
            markMethod: attendance.signOutMethod,
          ),
          const SizedBox(height: AppSpacing.md),
          _AttendanceField(
            label: 'Sign Out By',
            text: _resolveSignOutByDisplay(attendance.signOutBy, attendance.signOutMethod),
          ),
          if (_formatAttendedTimeForCard(attendance).trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _AttendanceField(
              label: 'Attended Time',
              text: _formatAttendedTimeForCard(attendance),
            ),
          ],
          if (attendance.notExpectedComment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _AttendanceField(
              label: 'Comment',
              text: attendance.notExpectedComment,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAbsentDayItem(int index) {
    final absentDay = absentDays[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExpansionTile(
        title: AppText.body(
          DateFormat('MMM dd, yyyy').format(absentDay.startDate),
          style: const TextStyle(fontWeight: FontWeight.w500),
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
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.none, AppSpacing.md, AppSpacing.md),
        onExpansionChanged: (expanded) {
          setState(() {
            expandedIndex = expanded ? index + 1000 : null;
          });
        },
        children: [
          Divider(color: AppColors.primaryColor.withValues(alpha: 0.1)),
          const SizedBox(height: AppSpacing.md),
          _AttendanceField(
            label: 'Classroom',
            text: () {
              if (absentDay.classroomName.isNotEmpty) {
                return absentDay.classroomName;
              }
              final fallback = staff?.roomName ?? widget.roomName;
              return (fallback.trim().isNotEmpty &&
                      fallback != '-' &&
                      fallback != '—')
                  ? fallback
                  : '';
            }(),
          ),
          const SizedBox(height: AppSpacing.md),
          _AttendanceField(
            label: 'Date',
            text:
                '${DateFormat('MMM dd, yyyy').format(absentDay.startDate)} - ${DateFormat('MMM dd, yyyy').format(absentDay.endDate)}',
          ),
          const SizedBox(height: AppSpacing.md),
          _AttendanceField(
            label: 'Marked By',
            text: getFirstName(absentDay.absentBy),
          ),
          const SizedBox(height: AppSpacing.md),
          _AttendanceField(
            label: 'Marked Absent Time',
            text: formatTime(absentDay.absentTime),
            markMethod: absentDay.markAbsentMethod,
          ),
          const SizedBox(height: AppSpacing.md),
          _AttendanceField(
            label: 'Absent Note',
            text: absentDay.note.isNotEmpty ? absentDay.note : '-',
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceShimmer() {
    return Column(
      children: [
        ShimmerLoaderCard(
          child: Container(height: 300, width: double.infinity),
        ),
        ListView.builder(
          shrinkWrap: true,
          itemCount: 3,
          itemBuilder: (context, index) {
            return const ShimmerLoaderCard(child: SizedBox(height: 50));
          },
        ),
      ],
    );
  }
}
