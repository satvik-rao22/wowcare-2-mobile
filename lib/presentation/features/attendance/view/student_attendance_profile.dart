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
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/presentation/features/attendance/widgets/student_attendance_vertical_pop_up.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_sign_in_form.dart'
    as student_sign_in;
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_sign_out_form.dart'
    as student_sign_out;
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_transfer_form.dart'
    as student_transfer;
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_mark_absent_form.dart'
    as student_absent;

// Simple field widget for displaying label and text
class _AttendanceField extends StatelessWidget {
  final String label;
  final String text;

  const _AttendanceField({
    required this.label,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: AppText.small(
            label,
            style: TextStyle(
              color: AppColors.primaryColor.withOpacity(0.5),
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppText.value(
            text,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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

  _AttendanceModel({
    required this.date,
    required this.signInTime,
    required this.signOutTime,
    required this.roomName,
    required this.signInBy,
    required this.signOutBy,
  });
}

class _AbsentDayModel {
  final DateTime startDate;
  final DateTime endDate;
  final String absentTime;
  final String absentBy;
  final String note;

  _AbsentDayModel({
    required this.startDate,
    required this.endDate,
    required this.absentTime,
    required this.absentBy,
    required this.note,
  });
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
  static const String routeName = '/student-attendance-profile';

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

  @override
  State<StudentAttendanceProfile> createState() => _StudentAttendanceProfileState();
}

class _StudentAttendanceProfileState extends State<StudentAttendanceProfile> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool isAttendancesLoading = false;
  bool isAbsentDaysLoading = false;
  bool isStudentLoading = false;
  bool showAbsentDays = false;
  int? expandedIndex;

  List<_AttendanceModel> attendances = [];
  List<_AbsentDayModel> absentDays = [];
  _StudentModel? student;
  _AttendanceReportModel? attendanceReport;

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
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
     _endDate = now;

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
    );

    // Load data from API
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.studentCode.isEmpty) {
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

    final from = _startDate ?? DateTime.now();
    final to = _endDate ?? from;

    final fromStr = DateFormat('yyyy-MM-dd').format(from);
    final toStr = DateFormat('yyyy-MM-dd').format(to);

    final client = serviceLocator<ApiClient>().client;
    final profileEndpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAttendanceProfile,
      ApiConstants.attendanceBaseUrl,
    );

    final queryParameters = <String, dynamic>{
      'studentCode': widget.studentCode,
      'fromAttendanceDate': fromStr,
      'toAttendanceDate': toStr,
      'page': 0,
      'size': 100,
      'sort': <String>['attendanceDate,desc'],
    };

    try {
      // --------- Load attendance (present days / summary) ----------
      final profileResponse = await client.get<dynamic>(
        profileEndpoint,
        queryParameters: queryParameters,
      );

      final profileData = profileResponse.data;
      if (profileData is Map<String, dynamic>) {
        final root = profileData['data'] as Map<String, dynamic>? ?? {};
        final agg = root['aggregations'] as Map<String, dynamic>? ?? {};
        final records = root['records'] as Map<String, dynamic>? ?? {};
        final content = records['content'] as List<dynamic>? ?? const [];

        final attendedDays = agg['attendedDays'] as int? ?? 0;
        final totalAttendedTime = agg['totalAttendedTime'] as String? ?? '';

        final List<_AttendanceModel> loadedAttendances = [];

        for (final e in content) {
          final m = e as Map<String, dynamic>;
          final dateStr = m['attendanceDate'] as String? ?? '';
          final date = dateStr.isNotEmpty
              ? DateTime.tryParse(dateStr) ?? DateTime.now()
              : DateTime.now();

          loadedAttendances.add(
            _AttendanceModel(
              date: date,
              signInTime: _formatApiTime(m['signedInTime']),
              signOutTime: _formatApiTime(m['signedOutTime']),
              roomName: m['classroomName'] as String? ?? widget.roomName,
              signInBy: m['signedInBy'] as String? ?? '',
              signOutBy: m['signedOutBy'] as String? ?? 'System Auto Signout',
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
      final absentEndpoint = ApiPaths.urlWithBase(
        ApiPaths.studentAttendanceProfileAbsentToggle,
        ApiConstants.attendanceBaseUrl,
      );

      final absentQueryParameters = <String, dynamic>{
        'studentCode': widget.studentCode,
        'fromAbsenceDate': fromStr,
        'toAbsenceDate': toStr,
        'page': 0,
        'size': 100,
        'sort': <String>['absenceDate,desc'],
      };

      final absentResponse = await client.get<dynamic>(
        absentEndpoint,
        queryParameters: absentQueryParameters,
      );

      final absentData = absentResponse.data;

      if (absentData is Map<String, dynamic>) {
        final root = absentData['data'] as Map<String, dynamic>? ?? {};
        final agg = root['aggregations'] as Map<String, dynamic>? ?? {};
        final records = root['records'] as Map<String, dynamic>? ?? {};
        final content = records['content'] as List<dynamic>? ?? const [];

        final absentDaysCount = agg['absentDays'] as int? ?? 0;

        final List<_AbsentDayModel> loadedAbsentDays = [];

        for (final e in content) {
          final m = e as Map<String, dynamic>;
          final dateStr = m['absenceDate'] as String? ?? '';
          final date = dateStr.isNotEmpty
              ? DateTime.tryParse(dateStr) ?? DateTime.now()
              : DateTime.now();

          loadedAbsentDays.add(
            _AbsentDayModel(
              startDate: date,
              endDate: date,
              absentTime: _formatApiTime(m['markedAbsentTime']),
              absentBy: m['markedAbsentBy'] as String? ?? '',
              note: m['absenceNote'] as String? ?? '',
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

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasSignedOutToday() {
    final now = DateTime.now();
    for (final item in attendances) {
      if (!_isSameDate(item.date, now)) continue;
      if (item.signOutTime.trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  bool _isCurrentlySignedIn() {
    final now = DateTime.now();
    for (final item in attendances) {
      if (!_isSameDate(item.date, now)) continue;
      final hasSignIn = item.signInTime.trim().isNotEmpty;
      final hasSignOut = item.signOutTime.trim().isNotEmpty;
      if (hasSignIn && !hasSignOut) return true;
    }
    return student?.isSignedIn ?? widget.isSignedIn;
  }

  bool get _isActiveProfile {
    final status = (student?.profileStatus ?? widget.profileStatus).toUpperCase();
    return status == 'A' || status == 'ACTIVE';
  }

  bool get _canSignIn => _isActiveProfile && !_isCurrentlySignedIn() && !_hasSignedOutToday();
  bool get _canSignOut => _isCurrentlySignedIn() && !_hasSignedOutToday();
  bool get _canTransfer => _isCurrentlySignedIn() && !_hasSignedOutToday();
  bool get _canMarkAbsent => _isActiveProfile && !_isCurrentlySignedIn();

  Future<Map<String, String>> _loadClassroomNameToCodeMap() async {
    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode = await storage.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.trim().isEmpty) return const <String, String>{};

      final classrooms = await serviceLocator<GetActiveClassroomsUseCase>()(
        schoolCode: schoolCode,
        onlyTypeClassroom: true,
      );
      return {
        for (final c in classrooms)
          if (c.name.trim().isNotEmpty && c.code.trim().isNotEmpty) c.name: c.code,
      };
    } catch (_) {
      return const <String, String>{};
    }
  }

  Future<void> _handleStudentAction(String actionLabel) async {
    final current = student;
    if (current == null) return;

    if ((actionLabel == 'Sign-in' && !_canSignIn) ||
        (actionLabel == 'Sign-Out' && !_canSignOut) ||
        (actionLabel == 'Transfer' && !_canTransfer) ||
        (actionLabel == 'Absent' && !_canMarkAbsent)) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('This action is not allowed for current attendance state'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    final classroomMap = await _loadClassroomNameToCodeMap();
    final classroomCode = (classroomMap[current.roomName] ?? '').trim();
    final commonArgs = (
      id: current.id,
      code: widget.studentCode,
      name: current.name,
      roomName: current.roomName,
      photoUuid: current.photoUuid ?? '',
      classroomCode: classroomCode,
    );

    Widget? target;
    if (actionLabel == 'Sign-in') {
      target = student_sign_in.StudentSignInForm(
        students: [
          student_sign_in.StudentEntity(
            id: commonArgs.id,
            studentCode: commonArgs.code,
            fullName: commonArgs.name,
            roomId: 0,
            roomName: commonArgs.roomName,
            classroomCode: commonArgs.classroomCode,
            photoUuid: commonArgs.photoUuid,
          ),
        ],
        refreshCallback: refreshData,
      );
    } else if (actionLabel == 'Sign-Out') {
      target = student_sign_out.StudentSignOutForm(
        students: [
          student_sign_out.StudentEntity(
            id: commonArgs.id,
            studentCode: commonArgs.code,
            fullName: commonArgs.name,
            roomId: 0,
            roomName: commonArgs.roomName,
            classroomCode: commonArgs.classroomCode,
            photoUuid: commonArgs.photoUuid,
          ),
        ],
        refreshCallback: refreshData,
      );
    } else if (actionLabel == 'Transfer') {
      target = student_transfer.StudentTransferForm(
        students: [
          student_transfer.StudentEntity(
            id: commonArgs.id,
            studentCode: commonArgs.code,
            fullName: commonArgs.name,
            roomId: 0,
            roomName: commonArgs.roomName,
            classroomCode: commonArgs.classroomCode,
            photoUuid: commonArgs.photoUuid,
          ),
        ],
        refreshCallback: refreshData,
        classroomNameToCode: classroomMap,
      );
    } else if (actionLabel == 'Absent') {
      target = student_absent.StudentMarkAbsentForm(
        students: [
          student_absent.StudentEntity(
            id: commonArgs.id,
            studentCode: commonArgs.code,
            fullName: commonArgs.name,
            roomId: 0,
            roomName: commonArgs.roomName,
            classroomCode: commonArgs.classroomCode,
            photoUuid: commonArgs.photoUuid,
          ),
        ],
        refreshCallback: refreshData,
      );
    }

    if (target == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => target!),
    );
    if (!mounted) return;
    await refreshData();
  }

  void _onDateRangeSelected(DateTime startDate, DateTime? endDate) {
    setState(() {
      _startDate = startDate;
      _endDate = endDate ?? startDate;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final contentPadding = ResponsiveSizing.contentPadding(context);

    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: true,
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
                  const SizedBox(width: 16),
                  _buildPopupMenu(),
                ],
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  return isStudentLoading && (isAttendancesLoading || isAbsentDaysLoading)
                      ? _buildAttendanceShimmer()
                      : Column(
                          children: [
                            _buildStudentCard(),
                            const SizedBox(height: 16),
                            // Toggle for showing absent days
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText.title(
                                  showAbsentDays ? 'Absent Days' : 'Present Days',
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
                            const SizedBox(height: 16),
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
    return StudentAttendanceVerticalPopUp(
      students: const [],
      refreshCallback: refreshData,
      disabledActions: <String>{
        if (!_canSignIn) 'Sign-in',
        if (!_canSignOut) 'Sign-Out',
        if (!_canTransfer) 'Transfer',
        if (!_canMarkAbsent) 'Absent',
      },
      onActionTap: _handleStudentAction,
    );
  }

  Widget _buildStudentCard() {
    if (student == null) return const SizedBox.shrink();

    final responsive = ResponsiveHelper(context);
    final currentStudent = student!;

    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.cardColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: AppColors.primaryColor.withOpacity(0.2),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 6,
      shadowColor: AppColors.primaryColor.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 5),
                DocumentImageWidget(
                  fileUuid: currentStudent.photoUuid ?? '',
                  size: 80,
                  name: currentStudent.name,
                  fontSize: 24,
                  // Drive status dot purely from attendance API using studentCode.
                  studentCode: widget.studentCode,
                ),
                const SizedBox(width: 16),
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          AppText.body(
                            currentStudent.roomName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 100),
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: AppText.title(
                                    'Details',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!currentStudent.isPhotoPermission)
                                        _buildIconDetail(
                                          MediaRes.cameraIcon,
                                          "No Photo Permission",
                                        ),
                                      if (currentStudent.medications.isNotEmpty)
                                        _buildIconDetail(
                                          MediaRes.healthIcon,
                                          currentStudent.medications,
                                        ),
                                      if (currentStudent.note.isNotEmpty)
                                        _buildIconDetail(
                                          MediaRes.docsIcon,
                                          currentStudent.note,
                                        ),
                                      if (currentStudent.allergies.isNotEmpty)
                                        _buildIconDetail(
                                          MediaRes.alertIcon,
                                          currentStudent.allergies,
                                        ),
                                      if (currentStudent.dietRestriction.isNotEmpty)
                                        _buildIconDetail(
                                          MediaRes.foodIcon2,
                                          currentStudent.dietRestriction,
                                        ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: AppText.body(
                                        'Close',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
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
                                  _buildIconItem(MediaRes.cameraIcon),
                                if (currentStudent.medications.isNotEmpty)
                                  _buildIconItem(MediaRes.healthIcon),
                                if (currentStudent.note.isNotEmpty)
                                  _buildIconItem(MediaRes.docsIcon),
                                if (currentStudent.allergies.isNotEmpty)
                                  _buildIconItem(MediaRes.alertIcon),
                                if (currentStudent.dietRestriction.isNotEmpty)
                                  _buildIconItem(MediaRes.foodIcon2),
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
            const SizedBox(height: 16),
            _buildStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildIconItem(String icon) {
    final bool isSvg = icon.toLowerCase().endsWith('.svg');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: isSvg
          ? SvgPicture.asset(icon, height: 20)
          : Image.asset(icon, height: 20),
    );
  }

  Widget _buildIconDetail(String iconPath, String detail) {
    final bool isSvg = iconPath.toLowerCase().endsWith('.svg');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          isSvg
              ? SvgPicture.asset(iconPath, height: 24)
              : Image.asset(iconPath, height: 24),
          const SizedBox(width: 16),
          Expanded(
            child: AppText.body(
              detail,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final report = attendanceReport;

    if (report == null) {
      return Column(
        children: [
          _buildStatItem(
            icon: MediaRes.calenderClockIcon,
            iconColor: const Color(0xFF4285F4),
            label: 'Attended Days',
            value: '',
            valueColor: const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 16),
          _buildAttendedHoursStat(
            report: null,
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            icon: MediaRes.calenderClockIcon,
            iconColor: const Color(0xFF4285F4),
            label: 'Absent Days',
            value: '',
            valueColor: Colors.red,
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildStatItem(
          icon: MediaRes.calenderClockIcon,
          iconColor: const Color(0xFF4285F4),
          label: 'Attended Days',
          value: '${report.attendedDays}',
          valueColor: const Color(0xFF4CAF50),
        ),
        const SizedBox(height: 16),
        _buildAttendedHoursStat(report: report),
        const SizedBox(height: 16),
        _buildStatItem(
          icon: MediaRes.calenderClockIcon,
          iconColor: const Color(0xFF4285F4),
          label: 'Absent Days',
          value: '${report.absentDays}',
          valueColor: Colors.red,
        ),
      ],
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SvgPicture.asset(icon, height: 22, colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn)),
          const SizedBox(width: 8),
          AppText.body(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: valueColor,
                width: 1.5,
              ),
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

  Widget _buildAttendedHoursStat({
    required _AttendanceReportModel? report,
  }) {
    int hours = 0;
    int minutes = 0;

    // Parse from raw string when available, expecting formats like "5 Hrs 30 Mins".
    if (report != null && report.totalAttendedHours.isNotEmpty) {
      final parts = report.totalAttendedHours.split(' ');
      if (parts.length >= 4) {
        hours = int.tryParse(parts[0]) ?? 0;
        minutes = int.tryParse(parts[2]) ?? 0;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            MediaRes.timerIcon,
            height: 22,
            colorFilter:
                const ColorFilter.mode(Color(0xFF4285F4), BlendMode.srcIn),
          ),
          const SizedBox(width: 8),
          const AppText.body(
            'Attended Hours',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _buildValueCircle(
                text: '${hours}h',
                color: const Color(0xFF4285F4),
              ),
              const SizedBox(width: 8),
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

  Widget _buildValueCircle({
    required String text,
    required Color color,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: 1.5,
        ),
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
          return const ShimmerLoaderCard(
            child: SizedBox(height: 50),
          );
        },
      );
    }

    if (attendances.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.2),
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
      children: List.generate(
        attendances.length,
        (index) {
          return _buildAttendanceItem(index);
        },
      ),
    );
  }

  Widget _buildAbsentDaysList() {
    if (isAbsentDaysLoading) {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: 5,
        itemBuilder: (context, index) {
          return const ShimmerLoaderCard(
            child: SizedBox(height: 50),
          );
        },
      );
    }

    if (absentDays.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.2),
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
      children: List.generate(
        absentDays.length,
        (index) {
          return _buildAbsentDayItem(index);
        },
      ),
    );
  }

  String calculateAttendedTime(String signInTime, String signOutTime) {
    if (signInTime.isEmpty || signOutTime.isEmpty) {
      return 'Not Yet Signed Out';
    }

    try {
      final format = DateFormat("hh:mm:ss a");
      final signIn = format.parse(signInTime);
      final signOut = format.parse(signOutTime);

      final duration = signOut.difference(signIn);

      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;

      if (hours < 1) {
        return "$minutes minutes";
      } else {
        return "$hours hours $minutes minutes";
      }
    } catch (e) {
      return 'Not Yet Signed Out';
    }
  }

  String getFirstName(String name) {
    if (name == 'System Auto Signout') return name;
    return name.split(' ').first;
  }

  String formatTime(String time) {
    if (time.isEmpty) {
      return 'Not Yet Signed Out';
    }
    try {
      return DateFormat("hh:mm a").format(DateFormat("hh:mm:ss a").parse(time));
    } catch (e) {
      return time;
    }
  }

  Widget _buildAttendanceItem(int index) {
    final attendance = attendances[index];
    final durationText =
        calculateAttendedTime(attendance.signInTime, attendance.signOutTime);
    final collapsedText =
        durationText == 'Not Yet Signed Out' && attendanceReport != null
            ? (attendanceReport!.totalAttendedHours.isNotEmpty
                ? attendanceReport!.totalAttendedHours
                : durationText)
            : durationText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ExpansionTile(
        title: AppText.body(
          DateFormat('MMM dd, yyyy').format(attendance.date),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: AppText.body(
          collapsedText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.cardColor,
        collapsedBackgroundColor: AppColors.cardColor,
        collapsedShape: RoundedRectangleBorder(
          side: BorderSide(
            color: AppColors.primaryColor.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: AppColors.primaryColor.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        onExpansionChanged: (expanded) {
          setState(() {
            expandedIndex = expanded ? index : null;
          });
        },
        children: [
          Divider(
            color: AppColors.primaryColor.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          _AttendanceField(
            label: 'Classroom',
            text: attendance.roomName,
          ),
          const SizedBox(height: 16),
          _AttendanceField(
            label: 'Sign In',
            text: formatTime(attendance.signInTime),
          ),
          const SizedBox(height: 16),
          _AttendanceField(
            label: 'Sign In By',
            text: getFirstName(attendance.signInBy),
          ),
          const SizedBox(height: 16),
          _AttendanceField(
            label: 'Sign Out',
            text: formatTime(attendance.signOutTime),
          ),
          const SizedBox(height: 16),
          _AttendanceField(
            label: 'Sign Out By',
            text: getFirstName(attendance.signOutBy),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsentDayItem(int index) {
    final absentDay = absentDays[index];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ExpansionTile(
        title: AppText.body(
          DateFormat('MMM dd, yyyy').format(absentDay.startDate),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.cardColor,
        collapsedBackgroundColor: AppColors.cardColor,
        collapsedShape: RoundedRectangleBorder(
          side: BorderSide(
            color: AppColors.primaryColor.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: AppColors.primaryColor.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        onExpansionChanged: (expanded) {
          setState(() {
            expandedIndex = expanded ? index + 1000 : null;
          });
        },
        children: [
          Divider(
            color: AppColors.primaryColor.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          _AttendanceField(
            label: 'Classroom',
            text: student?.roomName ?? '',
          ),
          const SizedBox(height: 16),
          _AttendanceField(
            label: 'Date',
            text: '${DateFormat('MMM dd, yyyy').format(absentDay.startDate)} - ${DateFormat('MMM dd, yyyy').format(absentDay.endDate)}',
          ),
          const SizedBox(height: 16),
          _AttendanceField(
            label: 'Marked By',
            text: getFirstName(absentDay.absentBy),
          ),
          const SizedBox(height: 16),
          _AttendanceField(
            label: 'Marked Absent Time',
            text: formatTime(absentDay.absentTime),
          ),
          const SizedBox(height: 16),
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
          child: Container(
            height: 300,
            width: double.infinity,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          itemCount: 3,
          itemBuilder: (context, index) {
            return const ShimmerLoaderCard(
              child: SizedBox(height: 50),
            );
          },
        ),
      ],
    );
  }
}
