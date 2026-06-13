import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_card.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_summary.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_absent_card.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_shimmer.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
import 'package:wowcare/presentation/features/attendance/cubit/student_attendance_daily_cubit.dart';
import 'package:wowcare/presentation/features/attendance/cubit/student_attendance_absent_toggle_cubit.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_daily.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_absent_form.dart'
    hide StudentAttendanceTime;
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/attendance_attended_duration.dart';
import 'package:wowcare/core/util/attendance_classroom_scope.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_attendance_daily_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_attendance_expected_summary_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_attendance_absent_toggle_view_usecase.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_classroom_by_code_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_counts_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_edit_attendance_form.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_screen.dart'
    show FilterData;
import 'package:wowcare/presentation/features/students/view/student_filter_screen.dart';
import 'package:wowcare/presentation/features/students/view/student_screen.dart';
import 'package:wowcare/presentation/features/student/cubit/student_cubit.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:wowcare/presentation/features/attendance/view/daily_attendance_parent_refresh.dart';
import 'package:wowcare/shared/common/widgets/highlightable_card.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StudentAttendanceDailyViewScreen extends StatefulWidget {
  const StudentAttendanceDailyViewScreen({
    super.key,
    this.incomingFilter,
    this.contentOnly = false,
    this.classroomFilter,
    this.staffAllowedClassrooms,
    this.staffAllowedClassroomIds,
    this.highlightCode,
    this.onAttendanceMutated,
  });

  final String? incomingFilter;
  final bool contentOnly;
  final FilterData? classroomFilter;
  final List<String>? staffAllowedClassrooms;
  final List<int>? staffAllowedClassroomIds;

  /// Student code from a notification deep-link; the matching attendance card
  /// scrolls into view, expands, and flashes once.
  final String? highlightCode;

  /// Called by the tabbed shell after an attendance action so the whole page
  /// (all tabs) can reload, not just this Daily tab. When null, this screen
  /// just reloads itself.
  final VoidCallback? onAttendanceMutated;

  @override
  State<StudentAttendanceDailyViewScreen> createState() =>
      _StudentAttendanceDailyViewScreenState();
}

class _StudentAttendanceDailyViewScreenState
    extends State<StudentAttendanceDailyViewScreen>
    implements DailyAttendanceParentRefresh {
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _showAbsentOnly = false;
  String? _statusLegendFilter;
  String? _signInAtFilter;
  String? _signOutAtFilter;
  bool? _isExpectedNotMarkedFilter;
  FilterData? _studentFilters;
  int? _expandedStudentIndex;

  /// Notification deep-link target; applied once (scroll + expand + flash).
  String? _highlightStudentCode;
  bool _highlightApplied = false;
  final GlobalKey _highlightCardKey = GlobalKey();
  bool _isHighlightTarget(String? code) {
    final target = (_highlightStudentCode ?? '').trim();
    final c = (code ?? '').trim();
    return target.isNotEmpty && c.toUpperCase() == target.toUpperCase();
  }

  // Filter state
  // UI selections are NAME-based (because StudentFilterScreen is name-driven).
  // Before calling APIs we resolve name -> code.
  List<String> _selectedClassroomNames = [];
  List<String> _selectedTagNames = [];
  String? _sortColumn;
  bool _sortAscending = true;
  Map<String, String> _tagNameToCode = <String, String>{};
  bool _isLoadingTagMap = false;
  bool _isClassroomDataReady = false;
  String? _loggedInUserName;
  bool _isTeacherStaffPersona = false;

  // Enrolled summary: same API as StudentScreen "Total Students" (active + upcoming headline).
  int enrolled = 0;
  int active = 0;
  int upcoming = 0;
  int expected = 0;
  int present = 0;
  int absent = 0;
  int signedOut = 0;
  int notMarked = 0;

  late final StudentAttendanceDailyCubit _cubit;
  late final StudentAttendanceAbsentToggleCubit _absentToggleCubit;
  late final ClassroomCubit _classroomCubit;
  final GetClassroomByCodeUseCase _getClassroomByCode =
      serviceLocator<GetClassroomByCodeUseCase>();
  final Map<String, String> _absentToggleClassroomNameByCode = {};
  final Set<String> _absentToggleClassroomFetchInFlight = {};

  @override
  void initState() {
    super.initState();
    _highlightStudentCode = widget.highlightCode?.trim();
    // Note: after adding new GetIt registrations, Flutter hot-reload does NOT rerun `main()`
    // (and therefore doesn't rerun `configureDependencies()`), so the cubit may not be
    // registered in the current process yet. This fallback prevents a runtime crash.
    if (serviceLocator.isRegistered<StudentAttendanceDailyCubit>()) {
      _cubit = serviceLocator<StudentAttendanceDailyCubit>();
    } else {
      final repo = serviceLocator<AttendanceRepository>();

      _cubit = StudentAttendanceDailyCubit(
        getStudentAttendanceDailyUseCase: GetStudentAttendanceDailyUseCase(
          repo,
        ),
        getStudentAttendanceExpectedSummaryUseCase:
            GetStudentAttendanceExpectedSummaryUseCase(repo),
        repository: repo,
      );
    }

    if (serviceLocator.isRegistered<StudentAttendanceAbsentToggleCubit>()) {
      _absentToggleCubit = serviceLocator<StudentAttendanceAbsentToggleCubit>();
    } else {
      final repo = serviceLocator<AttendanceRepository>();

      _absentToggleCubit = StudentAttendanceAbsentToggleCubit(
        getStudentAttendanceAbsentToggleViewUseCase:
            GetStudentAttendanceAbsentToggleViewUseCase(repo),
      );
    }

    // ClassroomCubit is required by StudentFilterScreen to populate "Classroom".
    if (serviceLocator.isRegistered<ClassroomCubit>()) {
      _classroomCubit = serviceLocator<ClassroomCubit>();
    } else {
      _classroomCubit = ClassroomCubit(
        getActiveClassroomsUseCase: serviceLocator(),
        storageService: serviceLocator(),
      );
    }
    // Load classroom data and tag mapping
    _loadClassroomData();
    _loadTagNameCodeMap();
    _loadLoggedInUserName();
    _loadStaffPersonaFlags();
    _searchController.addListener(_onSearchChanged);

    // Handle incoming filter
    if (widget.incomingFilter != null) {
      final normalizedStatus = widget.incomingFilter!.trim().toUpperCase();
      if (normalizedStatus == 'ACTIVE' || normalizedStatus == 'UPCOMING') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _openStudentListWithIncomingFilter(normalizedStatus);
          }
        });
      } else {
        if (normalizedStatus == 'ABSENT') {
          // When routed in from dashboards (e.g. EnrollmentCard "Absent"),
          // open the Absent Toggle view inside the Daily tab.
          _showAbsentOnly = true;
          _statusLegendFilter = 'Absent';
        } else {
          _statusLegendFilter = widget.incomingFilter == 'Present'
              ? 'Signed-In'
              : widget.incomingFilter;
          _applyLegendApiFilters(_statusLegendFilter);
        }
      }
    }

    // Handle classroom filter
    if (widget.classroomFilter != null) {
      _studentFilters = widget.classroomFilter;
      // Extract classroom codes from filter if needed
      // _selectedClassrooms = widget.classroomFilter?.selectedValues ?? [];
    }

    // Load initial data using cache-aware cubit methods.
    _loadAttendanceData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadStudentCounts();
    });
  }

  @override
  void refreshAfterReturningFromAttendanceFlow() {
    if (!mounted) return;
    // Reload this Daily tab's list and counts...
    _loadAttendanceData(reset: true);
    unawaited(_loadStudentCounts());
    // ...and, when hosted in the tabbed shell, the sibling tabs (Custom,
    // Absent) so the whole page reflects the action.
    widget.onAttendanceMutated?.call();
  }

  Future<void> _loadStudentCounts() async {
    try {
      final storageService = serviceLocator<StorageService>();
      final schoolCode =
          await storageService.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) return;

      final useCase = serviceLocator<GetStudentCountsUseCase>();
      final counts = await useCase(schoolCode: schoolCode);
      if (!mounted) return;

      final activeC = counts['activeCount'] ?? 0;
      final upcomingC = counts['upcomingCount'] ?? 0;
      setState(() {
        active = activeC;
        upcoming = upcomingC;
        enrolled = activeC + upcomingC;
      });
    } catch (_) {
      // Non-critical; keep existing values (same tolerance as StudentScreen).
    }
  }

  Future<void> _loadClassroomData() async {
    // Transfers can involve non-CLASSROOM locations; load all types to maximize
    // classroomCode → name resolution across the app.
    _classroomCubit.loadActiveClassrooms(
      onlyTypeClassroom: false,
      applyAttendanceStaffScope: true,
    );

    // Check if data is already available
    if (!_classroomCubit.state.isLoading &&
        _classroomCubit.state.classrooms.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _isClassroomDataReady = true;
      });
      return;
    }

    // Wait for classroom data to be available (max 10 seconds)
    int attempts = 0;
    while (_classroomCubit.state.isLoading && attempts < 100) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!mounted) return;
    setState(() {
      _isClassroomDataReady =
          !_classroomCubit.state.isLoading &&
          _classroomCubit.state.classrooms.isNotEmpty;
    });
  }

  Future<void> _loadTagNameCodeMap() async {
    if (_isLoadingTagMap) return;
    setState(() {
      _isLoadingTagMap = true;
    });

    try {
      final storageService = serviceLocator<StorageService>();
      final schoolCode =
          await storageService.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoadingTagMap = false;
        });
        return;
      }

      final useCase = serviceLocator<GetTagNameCodeMapForSchoolUseCase>();
      final map = await useCase(schoolCode: schoolCode);
      if (!mounted) return;
      setState(() {
        _tagNameToCode = map;
        _isLoadingTagMap = false;
      });
    } catch (e) {
      // Non-critical for filters; log but don't block UI
      debugPrint('Failed to load tag name-to-code map: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingTagMap = false;
      });
    }
  }

  Future<void> _loadLoggedInUserName() async {
    try {
      final storage = serviceLocator<StorageService>();
      final displayName =
          (await storage.getString(StorageKeys.displayName) ?? '').trim();
      final username = (await storage.getString(StorageKeys.username) ?? '')
          .trim();
      final fallback = displayName.isNotEmpty
          ? displayName
          : (username.isNotEmpty ? username : '');
      if (!mounted || fallback.isEmpty) return;
      setState(() {
        _loggedInUserName = fallback;
      });
    } catch (_) {}
  }

  Future<void> _loadStaffPersonaFlags() async {
    try {
      final storage = serviceLocator<StorageService>();
      final staffCode = (await storage.getString(StorageKeys.staffCode) ?? '')
          .trim();
      final staffType = (await storage.getString(StorageKeys.staffType) ?? '')
          .trim()
          .toUpperCase();
      bool isStaffAdmin =
          staffType == 'SCHOOL_ADMIN' || staffType == 'ORGANIZATION_ADMIN';
      if (!isStaffAdmin) {
        final rolesJson = (await storage.getString(StorageKeys.roles) ?? '')
            .trim();
        if (rolesJson.isNotEmpty) {
          final roles = jsonDecode(rolesJson);
          if (roles is List) {
            isStaffAdmin = roles.any((r) {
              if (r is! Map) return false;
              final roleCode = (r['role'] ?? '')
                  .toString()
                  .trim()
                  .toUpperCase();
              return roleCode == 'SCHOOL_ADMIN' ||
                  roleCode == 'ORGANIZATION_ADMIN';
            });
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _isTeacherStaffPersona = staffCode.isNotEmpty && !isStaffAdmin;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isTeacherStaffPersona = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _cubit.close();
    _absentToggleCubit.close();
    super.dispose();
  }

  void _onSearchChanged() {
    // Search should use cache-first behaviour via loadInitial.
    _loadAttendanceData(reset: false);
  }

  List<String>? _resolveSelectedClassroomCodes() {
    if (_selectedClassroomNames.isNotEmpty) {
      final codes = resolveClassroomNamesToCodes(
        selectedNamesOrCodes: _selectedClassroomNames,
        classrooms: _classroomCubit.state.classrooms,
      );
      if (codes == null) {
        debugPrint('Warning: No classroom data available for code resolution');
      }
      return codes;
    }

    // Pre-seeded from navigation (e.g. classroom info): [FilterData.classrooms] are codes.
    final fromFilter = _studentFilters?.classrooms;
    if (fromFilter == null || fromFilter.isEmpty) return null;
    final codes = fromFilter
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return codes.isEmpty ? null : codes;
  }

  List<String>? _resolveSelectedTagCodes() {
    if (_selectedTagNames.isEmpty) return null;

    // Ensure tag mapping is loaded
    if (_tagNameToCode.isEmpty && !_isLoadingTagMap) {
      debugPrint(
        'Warning: Tag name-to-code map is empty. Attempting to reload...',
      );
      _loadTagNameCodeMap();
      return null; // Return null for now, will retry after map loads
    }

    final codes = _selectedTagNames
        .map((n) => _tagNameToCode[n])
        .whereType<String>()
        .toList();

    // Log if some names couldn't be resolved
    if (codes.length < _selectedTagNames.length) {
      final unresolved = _selectedTagNames
          .where((n) => !_tagNameToCode.containsKey(n))
          .toList();
      debugPrint('Warning: Could not resolve tag codes for: $unresolved');
    }

    return codes.isEmpty ? null : codes;
  }

  void _loadAttendanceData({bool reset = false}) {
    final classroomCodes = _resolveSelectedClassroomCodes();
    final tagCodes = _resolveSelectedTagCodes();
    final search = _searchController.text.trim().isNotEmpty
        ? _searchController.text.trim()
        : null;

    // Debug logging for filter application
    debugPrint('[StudentAttendanceDaily] Loading attendance data:');
    debugPrint('  - Date: $_selectedDate');
    debugPrint('  - Classroom Names: $_selectedClassroomNames');
    debugPrint('  - Classroom Codes: $classroomCodes');
    debugPrint('  - Tag Names: $_selectedTagNames');
    debugPrint('  - Tag Codes: $tagCodes');
    debugPrint('  - Search: $search');
    debugPrint('  - Show Absent Only: $_showAbsentOnly');
    debugPrint('  - signInAtFilter: $_signInAtFilter');
    debugPrint('  - signOutAtFilter: $_signOutAtFilter');
    debugPrint('  - Reset: $reset');

    if (_showAbsentOnly) {
      if (reset) {
        _absentToggleCubit.refresh(
          absenceDate: _selectedDate,
          classroomCodes: classroomCodes,
          tagCodes: tagCodes,
          search: search,
        );
      } else {
        _absentToggleCubit.loadInitial(
          absenceDate: _selectedDate,
          classroomCodes: classroomCodes,
          tagCodes: tagCodes,
          search: search,
        );
      }
      return;
    }

    if (reset) {
      _cubit.refresh(
        attendanceDate: _selectedDate,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        signInAtFilter: _signInAtFilter,
        signOutAtFilter: _signOutAtFilter,
        isExpectedNotMarked: _isExpectedNotMarkedFilter,
        search: search,
      );
    } else {
      _cubit.loadInitial(
        attendanceDate: _selectedDate,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        signInAtFilter: _signInAtFilter,
        signOutAtFilter: _signOutAtFilter,
        isExpectedNotMarked: _isExpectedNotMarkedFilter,
        search: search,
      );
    }
  }

  void _applyLegendApiFilters(String? legendStatus) {
    final normalized = legendStatus == 'Present' ? 'Signed-In' : legendStatus;
    switch (normalized) {
      case 'Signed-In':
        _signInAtFilter = 'NOT_NULL';
        _signOutAtFilter = 'NULL';
        _isExpectedNotMarkedFilter = null;
        _showAbsentOnly = false;
        break;
      case 'Signed Out':
        _signInAtFilter = 'NOT_NULL';
        _signOutAtFilter = 'NOT_NULL';
        _isExpectedNotMarkedFilter = null;
        _showAbsentOnly = false;
        break;
      case 'Not Marked':
        _signInAtFilter = null;
        _signOutAtFilter = null;
        _isExpectedNotMarkedFilter = true;
        _showAbsentOnly = false;
        break;
      case 'Absent':
        _signInAtFilter = null;
        _signOutAtFilter = null;
        _isExpectedNotMarkedFilter = null;
        _showAbsentOnly = true;
        break;
      default:
        _signInAtFilter = null;
        _signOutAtFilter = null;
        _isExpectedNotMarkedFilter = null;
        _showAbsentOnly = false;
    }
  }

  String _absentToggleClassroomDisplay(StudentAttendanceAbsentFormItem item) {
    final apiName = item.classroomName.trim();
    final code = item.classroomCode.trim();
    final apiNameLooksLikeCode =
        apiName.isNotEmpty && (apiName == code || apiName.startsWith('CLS_'));
    if (apiName.isNotEmpty && !apiNameLooksLikeCode) return apiName;
    if (code.isEmpty) return '';
    final fromCubit = _resolveClassroomNameByCode(code);
    if (fromCubit != null) return fromCubit;
    final cached = _absentToggleClassroomNameByCode[code]?.trim();
    if (cached != null && cached.isNotEmpty) return cached;
    if (!_absentToggleClassroomFetchInFlight.contains(code)) {
      _absentToggleClassroomFetchInFlight.add(code);
      unawaited(_fetchAbsentToggleClassroomName(code));
    }
    return code;
  }

  String _classroomDisplay({
    required String classroomCode,
    required String classroomName,
  }) {
    final apiName = classroomName.trim();
    final code = classroomCode.trim();
    final apiNameLooksLikeCode =
        apiName.isNotEmpty && (apiName == code || apiName.startsWith('CLS_'));
    if (apiName.isNotEmpty && !apiNameLooksLikeCode) return apiName;
    if (code.isEmpty) return '';

    final fromCubit = _resolveClassroomNameByCode(code);
    if (fromCubit != null && fromCubit.trim().isNotEmpty)
      return fromCubit.trim();

    final cached = _absentToggleClassroomNameByCode[code]?.trim();
    if (cached != null && cached.isNotEmpty) return cached;

    if (!_absentToggleClassroomFetchInFlight.contains(code)) {
      _absentToggleClassroomFetchInFlight.add(code);
      unawaited(_fetchAbsentToggleClassroomName(code));
    }

    return code;
  }

  void _prefetchAbsentToggleClassroomNames(
    List<StudentAttendanceAbsentFormItem> items,
  ) {
    for (final item in items) {
      final code = item.classroomCode.trim();
      if (code.isEmpty) continue;
      if (item.classroomName.trim().isNotEmpty) continue;
      if (_resolveClassroomNameByCode(code) != null) continue;
      if (_absentToggleClassroomNameByCode.containsKey(code)) continue;
      if (_absentToggleClassroomFetchInFlight.contains(code)) continue;
      _absentToggleClassroomFetchInFlight.add(code);
      unawaited(_fetchAbsentToggleClassroomName(code));
    }
  }

  Future<void> _fetchAbsentToggleClassroomName(String code) async {
    try {
      final details = await _getClassroomByCode(code: code);
      if (!mounted) return;
      final name = details.name.trim();
      if (name.isNotEmpty) {
        setState(() {
          _absentToggleClassroomNameByCode[code] = name;
        });
      }
    } catch (_) {
      // Keep showing classroom code when lookup fails.
    } finally {
      _absentToggleClassroomFetchInFlight.remove(code);
    }
  }

  StudentAbsentCardData _absentEntityToCard(
    StudentAttendanceAbsentFormItem item,
    int index,
  ) {
    final roomName = _absentToggleClassroomDisplay(item);

    final absenceDate = item.absenceDate.isNotEmpty
        ? item.absenceDate
        : DateTime.now().toIso8601String();

    final absentTime = item.markedAbsentTime?.formatted12h ?? '';

    return StudentAbsentCardData(
      id: item.studentCode,
      studentCode: item.studentCode,
      name: item.studentName,
      photoUuid: null,
      roomName: roomName,
      absentTime: absentTime,
      absentBy: item.markedAbsentByName ?? '',
      note: item.absenceNote,
      studentId: index,
      roomId: 0,
      schoolId: 0,
      startDate: absenceDate,
      endDate: absenceDate,
      hasSignIn: false,
      expectedToday: true,
      signInTime: null,
      signOutTime: null,
      markAbsentMethod: _mapAbsentMethodStringToEnum(item.markAbsentMethod),
    );
  }

  // Convert entity to card data
  StudentAttendanceCardData _entityToCardData(
    StudentAttendanceDailyItem item,
    int index,
  ) {
    // Compute effective sign-in / sign-out times based on transfer rules
    String? effectiveSignIn;
    String? effectiveSignOut;
    StudentAttendanceTime? effectiveSignInClock;
    StudentAttendanceTime? effectiveSignOutClock;
    bool transferSignIn = false;
    bool transferSignOut = false;

    final int seq = item.sequenceNumber ?? 1;
    final int totalSeq = item.totalSequenceCount ?? 1;

    // If no transfers exist
    if (totalSeq <= 1) {
      effectiveSignIn = item.formattedSignInTime;
      effectiveSignOut = item.formattedSignOutTime;
      effectiveSignInClock = item.signedInTime;
      effectiveSignOutClock = item.signedOutTime;
    } else {
      final isFirst = seq == 1;
      final isLast = seq == totalSeq;

      if (isFirst && !isLast) {
        // First entry with a subsequent transfer
        effectiveSignIn = item.formattedSignInTime;
        effectiveSignOut = item.nextActionTime?.formattedTime;
        effectiveSignInClock = item.signedInTime;
        effectiveSignOutClock = item.nextActionTime;
        transferSignOut = effectiveSignOut != null;
      } else if (!isFirst && !isLast) {
        // Intermediate transfer
        effectiveSignIn = item.transferTime?.formattedTime;
        effectiveSignOut = item.nextActionTime?.formattedTime;
        effectiveSignInClock = item.transferTime;
        effectiveSignOutClock = item.nextActionTime;
        transferSignIn = effectiveSignIn != null;
        transferSignOut = effectiveSignOut != null;
      } else if (isLast) {
        // Latest/last transfer
        effectiveSignIn = isFirst
            ? item.formattedSignInTime
            : item.transferTime?.formattedTime;
        // Actual sign-out time of the entry
        effectiveSignOut = item.formattedSignOutTime;
        effectiveSignInClock = isFirst ? item.signedInTime : item.transferTime;
        effectiveSignOutClock = item.signedOutTime;
        transferSignIn = !isFirst && effectiveSignIn != null;
        // signOut on last is not transfer-derived
      }
    }

    final day = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final startMoment = dateAtAttendanceClock(day, effectiveSignInClock);
    final endMoment = dateAtAttendanceClock(day, effectiveSignOutClock);
    final attendedTimeDisplay = attendedLabelFromMoments(
      startMoment,
      endMoment,
    );

    return StudentAttendanceCardData(
      id: '${item.studentName}_${item.classroomCode}_$index',
      attendanceRecordCode: item.attendanceRecordCode,
      studentCode: item.studentCode,
      studentName: item.studentName,
      studentPhotoUuid: null, // API doesn't provide this
      roomName: _classroomDisplay(
        // Transfer rows may populate `toClassroom*` instead of `classroom*`.
        classroomCode:
            (item.isTransfer == true &&
                (item.toClassroomCode ?? '').trim().isNotEmpty)
            ? item.toClassroomCode!
            : item.classroomCode,
        classroomName:
            (item.isTransfer == true &&
                (item.toClassroomName ?? '').trim().isNotEmpty)
            ? item.toClassroomName!
            : item.classroomName,
      ),
      classroomCode: item.classroomCode,
      expectedToday: item.isExpectedToday,
      hasSignIn: item.hasSignIn,
      signInTime: effectiveSignIn ?? item.formattedSignInTime,
      signOutTime: effectiveSignOut ?? item.formattedSignOutTime,
      signInBy: _normalizeByName(item.signedInBy),
      signOutBy:
          _normalizeByName(item.signedOutBy) ??
          (transferSignOut ? _loggedInUserName : null),
      // Map backend method codes (GPS, PIN, QR, APP, etc.) to UI enum.
      signInMethod: _resolveSignMethodForDisplay(
        method: item.signedInMethod,
        hasRecordedTime:
            (effectiveSignIn ?? item.formattedSignInTime)?.trim().isNotEmpty ==
                true,
      ),
      signOutMethod: _resolveSignMethodForDisplay(
        method: item.signedOutMethod,
        hasRecordedTime:
            (effectiveSignOut ?? item.formattedSignOutTime)?.trim().isNotEmpty ==
                true,
      ),
      tags: item.tagNames.isNotEmpty ? item.tagNames : null,
      studentId: index, // Use index as placeholder
      roomId: index, // Use index as placeholder
      schoolId: 1, // Use placeholder
      sequenceNumber: item.sequenceNumber,
      totalSequenceCount: item.totalSequenceCount,
      isTransferSignIn: transferSignIn,
      isTransferSignOut: transferSignOut,
      attendedTimeDisplay: attendedTimeDisplay,
    );
  }

  String? _resolveClassroomNameByCode(String? code) {
    final target = (code ?? '').trim();
    if (target.isEmpty) return null;
    final classrooms = _classroomCubit.state.classrooms;
    if (classrooms.isEmpty) return null;
    for (final c in classrooms) {
      if (c.code.trim() == target) {
        final name = c.name.trim();
        return name.isNotEmpty ? name : target;
      }
    }
    return null;
  }

  String? _normalizeByName(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  SignMethod? _mapMethodStringToEnum(String? method) {
    if (method == null) return null;
    final normalized = method.trim().toUpperCase();
    switch (normalized) {
      case 'GPS':
        return SignMethod.gps;
      case 'PIN':
      case 'KIOSK':
        // PIN entry is effectively via kiosk device.
        return SignMethod.kiosk;
      case 'QR':
        return SignMethod.qr;
      case 'APP':
      case 'MOBILE':
      case 'DIRECT':
      case 'MANUAL':
        return SignMethod.direct;
      case 'WEB':
        return SignMethod.web;
      default:
        return null;
    }
  }

  /// Maps API method codes; when a time is present but method is missing (common
  /// after edit-attendance), default to the mobile/APP icon.
  SignMethod? _resolveSignMethodForDisplay({
    required String? method,
    required bool hasRecordedTime,
  }) {
    final mapped = _mapMethodStringToEnum(method);
    if (mapped != null) return mapped;
    if (hasRecordedTime) return SignMethod.direct;
    return null;
  }

  AbsentMarkMethod? _mapAbsentMethodStringToEnum(String? method) {
    if (method == null) return null;
    switch (method.trim().toUpperCase()) {
      case 'GPS':
        return AbsentMarkMethod.gps;
      case 'PIN':
      case 'KIOSK':
        return AbsentMarkMethod.kiosk;
      case 'QR':
        return AbsentMarkMethod.qr;
      case 'APP':
        return AbsentMarkMethod.app;
      case 'WEB':
        return AbsentMarkMethod.web;
      default:
        return null;
    }
  }

  /// Student daily edit/delete APIs expect rowCode from daily list item `code`.
  String? _resolveStudentDeleteAttendanceRecordCode({
    required StudentAttendanceCardData card,
    required List<StudentAttendanceDailyItem> allItems,
  }) {
    final fromCard = card.attendanceRecordCode?.trim();
    if (fromCard == null || fromCard.isEmpty) return null;
    return fromCard;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.contentOnly) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _cubit),
          BlocProvider.value(value: _absentToggleCubit),
          BlocProvider.value(value: _classroomCubit),
        ],
        child: _buildContent(),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cubit),
        BlocProvider.value(value: _absentToggleCubit),
        BlocProvider.value(value: _classroomCubit),
      ],
      child: GlobalScaffold(
        hasBackButton: true,
        showCustomNavigationBar: true,
        body: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final responsive = ResponsiveHelper(context);
    final contentPadding = ResponsiveSizing.contentPadding(context);

    return BlocListener<
      StudentAttendanceAbsentToggleCubit,
      StudentAttendanceAbsentToggleState
    >(
      listenWhen: (prev, curr) => prev.items != curr.items,
      listener: (context, state) {
        _prefetchAbsentToggleClassroomNames(state.items);
      },
      child: BlocBuilder<StudentAttendanceAbsentToggleCubit, StudentAttendanceAbsentToggleState>(
        builder: (context, absentState) {
          return BlocBuilder<
            StudentAttendanceDailyCubit,
            StudentAttendanceDailyState
          >(
            builder: (context, state) {
              final isAbsentMode = _showAbsentOnly;
              final isLoading = isAbsentMode
                  ? absentState.isLoading
                  : state.isLoading;
              final isLoadingMore = isAbsentMode
                  ? absentState.isLoadingMore
                  : state.isLoadingMore;
              final hasMore = isAbsentMode
                  ? absentState.hasMore
                  : state.hasMore;
              final errorMessage = isAbsentMode
                  ? absentState.errorMessage
                  : state.errorMessage;

              final absentCards = absentState.items
                  .asMap()
                  .entries
                  .map((e) => _absentEntityToCard(e.value, e.key))
                  .toList();

              return CustomRefreshIndicator(
                onRefresh: () async {
                  await _loadStudentCounts();
                  _loadAttendanceData(reset: true);
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    // Only trigger on actual scroll updates
                    if (notification is ScrollUpdateNotification) {
                      if (notification.metrics.pixels >=
                          notification.metrics.maxScrollExtent - 200) {
                        if (!isLoading && !isLoadingMore && hasMore) {
                          if (isAbsentMode) {
                            _absentToggleCubit.loadNextPage();
                          } else {
                            _cubit.loadNextPage();
                          }
                        }
                      }
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: contentPadding.left,
                      vertical: responsive.verticalSpacing / 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: responsive.verticalSpacing / 4),
                        if (!_isTeacherStaffPersona) ...[
                          StudentAttendanceSummary(
                            enrolled: enrolled,
                            active: active,
                            upcoming: upcoming,
                            expected: state.expectedCount ?? expected,
                            present: state.presentCount ?? present,
                            absent: state.absentCount ?? absent,
                            signedOut: state.signedOutCount ?? signedOut,
                            notMarked: state.notMarkedCount ?? notMarked,
                            isLoading:
                                state.isLoading ||
                                state.isRefreshing ||
                                state.isSummaryLoading,
                            onLegendTap: (status) {
                              final normalizedStatus = status
                                  .trim()
                                  .toUpperCase();
                              if (normalizedStatus == 'ACTIVE' ||
                                  normalizedStatus == 'UPCOMING') {
                                _openStudentListWithIncomingFilter(
                                  normalizedStatus,
                                );
                                return;
                              }
                              final normalized = status == 'Present'
                                  ? 'Signed-In'
                                  : status;
                              final currentLegend =
                                  _statusLegendFilter == 'Present'
                                  ? 'Signed-In'
                                  : _statusLegendFilter;
                              setState(() {
                                if (currentLegend == normalized) {
                                  _statusLegendFilter = null;
                                  _applyLegendApiFilters(null);
                                } else {
                                  _statusLegendFilter = normalized;
                                  _applyLegendApiFilters(normalized);
                                }
                              });
                              _loadAttendanceData(reset: true);
                            },
                          ),
                          SizedBox(height: responsive.verticalSpacing),
                        ],
                        // Filters row styled similar to StaffScreen: search, filter, date, clear all, show absent toggle
                        _buildFilterCard(responsive),
                        SizedBox(height: responsive.verticalSpacing),
                        // Error handling
                        if (errorMessage != null)
                          CustomSectionCard(
                            margin: EdgeInsets.only(
                              bottom: responsive.verticalSpacing,
                            ),
                            padding: EdgeInsets.all(
                              responsive.horizontalSpacing,
                            ),
                            backgroundColor: AppColors.errorColor.withOpacity(
                              0.1,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: AppColors.errorColor,
                                  size: 24,
                                ),
                                SizedBox(
                                  width: responsive.horizontalSpacing / 2,
                                ),
                                Expanded(
                                  child: AppText.body(
                                    errorMessage,
                                    style: TextStyle(
                                      color: AppColors.errorColor,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: responsive.horizontalSpacing / 2,
                                ),
                                TextButton(
                                  onPressed: () {
                                    _loadAttendanceData(reset: true);
                                  },
                                  child: AppText.body('Retry'),
                                ),
                              ],
                            ),
                          ),
                        // Content based on toggle state
                        if (_showAbsentOnly) ...[
                          if ((absentState.isLoading ||
                                  absentState.isRefreshing) &&
                              absentCards.isEmpty)
                            ...List.generate(
                              6,
                              (index) => const StudentAbsentCardShimmer(),
                            )
                          else if (absentCards.isEmpty)
                            Center(
                              child: Padding(
                                padding: EdgeInsets.all(
                                  responsive.verticalSpacing,
                                ),
                                child: AppText.body(
                                  'No absent students found for the selected date',
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          else
                            ...absentCards.asMap().entries.map((entry) {
                              final index = entry.key;
                              final student = entry.value;
                              return StudentAbsentCard(
                                student: student,
                                index: index,
                                isExpanded: _expandedStudentIndex == index,
                                onTap: () {
                                  setState(() {
                                    if (_expandedStudentIndex == index) {
                                      _expandedStudentIndex = null;
                                    } else {
                                      _expandedStudentIndex = index;
                                    }
                                  });
                                },
                                onView: () {
                                  Navigator.push<void>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          StudentAttendanceProfile(
                                            studentCode: student.id,
                                            studentId: student.studentId,
                                            studentName: student.name,
                                            studentPhotoUuid: student.photoUuid,
                                            roomName: student.roomName,
                                            isSignedIn: false,
                                            isAbsent: true,
                                            isExpectedToday:
                                                student.expectedToday,
                                            isPresentToday: false,
                                            profileStatus: 'A',
                                            initialShowAbsentDays: true,
                                          ),
                                    ),
                                  ).then((_) {
                                    if (mounted) {
                                      refreshAfterReturningFromAttendanceFlow();
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          if (absentState.isLoadingMore)
                            Padding(
                              padding: EdgeInsets.all(
                                responsive.verticalSpacing,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        ] else ...[
                          // Show regular attendance data from API
                          if (state.isLoading && state.items.isEmpty)
                            ...List.generate(
                              6,
                              (index) => const StudentAttendanceCardShimmer(),
                            )
                          else if (state.items.isEmpty)
                            Center(
                              child: Padding(
                                padding: EdgeInsets.all(
                                  responsive.verticalSpacing,
                                ),
                                child: AppText.body(
                                  'No attendance records found for the selected date',
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          else
                            ..._getFilteredStudents(
                              state.items,
                            ).asMap().entries.map((entry) {
                              final index = entry.key;
                              final student = entry.value;
                              final isHighlightTarget =
                                  _isHighlightTarget(student.studentCode);
                              // Capture before mutating _highlightApplied so
                              // the key is only assigned on the very first
                              // build — removing it afterward prevents the
                              // GlobalKey duplicate when the SliverList
                              // deactivates/reactivates this item on fling.
                              final needsHighlightKey =
                                  isHighlightTarget && !_highlightApplied;
                              if (needsHighlightKey) {
                                _highlightApplied = true;
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (!mounted) return;
                                  setState(
                                      () => _expandedStudentIndex = index);
                                  final ctx =
                                      _highlightCardKey.currentContext;
                                  if (ctx != null) {
                                    Scrollable.ensureVisible(
                                      ctx,
                                      duration:
                                          const Duration(milliseconds: 400),
                                      alignment: 0.1,
                                      curve: Curves.easeOut,
                                    );
                                  }
                                });
                              }
                              return HighlightableCard(
                                key: needsHighlightKey
                                    ? _highlightCardKey
                                    : null,
                                code: student.studentCode,
                                highlightCode: _highlightStudentCode,
                                borderRadius: 12,
                                child: StudentAttendanceCard(
                                student: student,
                                index: index,
                                isExpanded: _expandedStudentIndex == index,
                                onTap: () {
                                  setState(() {
                                    if (_expandedStudentIndex == index) {
                                      _expandedStudentIndex = null;
                                    } else {
                                      _expandedStudentIndex = index;
                                    }
                                  });
                                },
                                onEdit: () async {
                                  await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StudentEditAttendanceForm(
                                        studentAttendance: student,
                                        attendanceDate: _selectedDate,
                                      ),
                                    ),
                                  );
                                  if (mounted) {
                                    refreshAfterReturningFromAttendanceFlow();
                                  }
                                },
                                onDelete: () {
                                  // Deletion validation: allow delete only if this is the last sequence entry
                                  if ((student.totalSequenceCount ?? 1) !=
                                      (student.sequenceNumber ?? 1)) {
                                    CoreUtils.showTopSnackBarFromSnackBar(
                                      context: context,
                                      snackBar: const SnackBar(
                                        content: Text(
                                          'Only the latest transfer entry can be deleted.',
                                        ),
                                        backgroundColor: AppColors.errorColor,
                                      ),
                                    );
                                    return;
                                  }
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (ctx) {
                                      return DeleteConfirmationBottomSheet(
                                        name: student.studentName,
                                        type: 'attendance',
                                        onDelete: () async {
                                          Navigator.of(ctx).pop();

                                          if (student.attendanceRecordCode ==
                                                  null ||
                                              student
                                                  .attendanceRecordCode!
                                                  .isEmpty) {
                                            CoreUtils.showTopSnackBarFromSnackBar(
                                              context: context,
                                              snackBar: const SnackBar(
                                                content: Text(
                                                  'Unable to delete: missing attendance record code.',
                                                ),
                                                backgroundColor:
                                                    AppColors.errorColor,
                                              ),
                                            );
                                            return;
                                          }

                                          try {
                                            final normalizedAttendanceCode =
                                                _resolveStudentDeleteAttendanceRecordCode(
                                                  card: student,
                                                  allItems: state.items,
                                                );
                                            if (normalizedAttendanceCode ==
                                                    null ||
                                                normalizedAttendanceCode
                                                    .isEmpty) {
                                              CoreUtils.showTopSnackBarFromSnackBar(
                                                context: context,
                                                snackBar: const SnackBar(
                                                  content: Text(
                                                    'Unable to delete: invalid attendance record code.',
                                                  ),
                                                  backgroundColor:
                                                      AppColors.errorColor,
                                                ),
                                              );
                                              return;
                                            }

                                            final storageService =
                                                serviceLocator<
                                                  StorageService
                                                >();
                                            final staffCode =
                                                (await storageService.getString(
                                                          StorageKeys.staffCode,
                                                        ) ??
                                                        '')
                                                    .trim();
                                            if (staffCode.isEmpty) {
                                              if (!context.mounted) return;
                                              CoreUtils.showTopSnackBarFromSnackBar(
                                                context: context,
                                                snackBar: const SnackBar(
                                                  content: Text(
                                                    'Unable to resolve staffCode. Please re-login.',
                                                  ),
                                                  backgroundColor:
                                                      AppColors.errorColor,
                                                ),
                                              );
                                              return;
                                            }

                                            await serviceLocator<
                                                  AttendanceRepository
                                                >()
                                                .deleteStudentAttendanceRecord(
                                                  attendanceRecordCode:
                                                      normalizedAttendanceCode,
                                                  staffCode: staffCode,
                                                );

                                            CoreUtils.showTopSnackBarFromSnackBar(
                                              context: context,
                                              snackBar: const SnackBar(
                                                content: Text(
                                                  'Attendance deleted',
                                                ),
                                                backgroundColor:
                                                    AppColors.successColor,
                                              ),
                                            );

                                            _loadAttendanceData(reset: true);
                                          } catch (e) {
                                            final message =
                                                ApiErrorHandler.extractErrorMessage(
                                                  e,
                                                );
                                            CoreUtils.showTopSnackBarFromSnackBar(
                                              context: context,
                                              snackBar: SnackBar(
                                                content: Text(message),
                                                backgroundColor:
                                                    AppColors.errorColor,
                                              ),
                                            );
                                          }
                                        },
                                        onCancel: () {
                                          Navigator.of(ctx).pop();
                                        },
                                      );
                                    },
                                  );
                                },
                                onView: () {
                                  Navigator.push<void>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          StudentAttendanceProfile(
                                            studentCode:
                                                student.studentCode ?? '',
                                            studentId: student.studentId,
                                            studentName: student.studentName,
                                            studentPhotoUuid:
                                                student.studentPhotoUuid,
                                            roomName: student.roomName,
                                            isSignedIn: student.hasSignIn,
                                            isAbsent:
                                                !student.hasSignIn &&
                                                student.expectedToday,
                                            isExpectedToday:
                                                student.expectedToday,
                                            isPresentToday: student.hasSignIn,
                                            profileStatus: 'A',
                                          ),
                                    ),
                                  ).then((_) {
                                    if (mounted) {
                                      refreshAfterReturningFromAttendanceFlow();
                                    }
                                  });
                                },
                              ),
                              );
                            }).toList(),
                          // Loading more indicator
                          if (state.isLoadingMore)
                            Padding(
                              padding: EdgeInsets.all(
                                responsive.verticalSpacing,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<StudentAttendanceCardData> _getFilteredStudents(
    List<StudentAttendanceDailyItem> items,
  ) {
    // Convert entities to card data
    var filtered = items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return _entityToCardData(item, index);
    }).toList();

    // Note: Search, classroom, and tag filters are handled by API
    // These filters below are for client-side filtering if needed (e.g., legend filters)

    // Apply sorting
    if (_sortColumn != null) {
      filtered.sort((a, b) {
        int comparison = 0;
        switch (_sortColumn) {
          case 'name':
            comparison = a.studentName.compareTo(b.studentName);
            break;
          case 'classroom':
            comparison = a.roomName.compareTo(b.roomName);
            break;
          case 'expected':
            comparison = a.expectedToday.toString().compareTo(
              b.expectedToday.toString(),
            );
            break;
          case 'signIn':
            comparison = (a.signInTime ?? '').compareTo(b.signInTime ?? '');
            break;
          case 'signOut':
            comparison = (a.signOutTime ?? '').compareTo(b.signOutTime ?? '');
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });
    }

    return filtered;
  }

  Widget _buildFilterCard(ResponsiveHelper responsive) {
    final hasActiveFilters =
        _statusLegendFilter != null ||
        _signInAtFilter != null ||
        _signOutAtFilter != null ||
        _isExpectedNotMarkedFilter == true ||
        _showAbsentOnly ||
        _studentFilters != null ||
        _selectedClassroomNames.isNotEmpty ||
        _selectedTagNames.isNotEmpty ||
        _searchController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorderColor),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.cardColor,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Search Students',
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _navigateToFilterScreen,
                  borderRadius: BorderRadius.circular(100),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset(
                          MediaRes.filterIcon,
                          height: 20,
                        ),
                      ),
                      if (hasActiveFilters)
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color.fromRGBO(179, 38, 30, 1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomDateTimeField(
                  hasLabel: false,
                  isRangePicker: false,
                  isTime: false,
                  fetchInitialTime: false,
                  initialDate: _selectedDate,
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                    // Date changes should still respect cache where available.
                    _loadAttendanceData(reset: false);
                  },
                ),
              ),
              const SizedBox(width: 8),
              CustomClearAllChip(
                onTap: hasActiveFilters
                    ? () {
                        setState(() {
                          _searchController.clear();
                          _selectedDate = DateTime.now();
                          _statusLegendFilter = null;
                          _studentFilters = null;
                          _selectedClassroomNames = [];
                          _selectedTagNames = [];
                          _showAbsentOnly = false;
                          _signInAtFilter = null;
                          _signOutAtFilter = null;
                          _isExpectedNotMarkedFilter = null;
                        });
                        _loadAttendanceData(reset: true);
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: CustomToggle(
              label: 'Show Absent',
              isToggled: _showAbsentOnly,
              onToggle: (value) {
                setState(() {
                  _showAbsentOnly = value;
                  if (value) {
                    _statusLegendFilter = 'Absent';
                    _signInAtFilter = null;
                    _signOutAtFilter = null;
                    _isExpectedNotMarkedFilter = null;
                  } else if (_statusLegendFilter == 'Absent') {
                    _statusLegendFilter = null;
                  }
                });
                _loadAttendanceData(reset: false);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToFilterScreen() async {
    // Ensure classroom data is loaded before opening filter screen
    if (!_isClassroomDataReady || _classroomCubit.state.classrooms.isEmpty) {
      // Show loading indicator and wait for data
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Reload classroom data if needed
        if (_classroomCubit.state.classrooms.isEmpty) {
          _classroomCubit.loadActiveClassrooms(
            force: true,
            applyAttendanceStaffScope: true,
          );
        }

        // Wait for classroom data to load (max 10 seconds)
        int attempts = 0;
        while (_classroomCubit.state.isLoading && attempts < 100) {
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
        }

        if (!mounted) return;
        Navigator.of(context).pop(); // Close loading dialog

        // Check if we have data now
        if (_classroomCubit.state.classrooms.isEmpty) {
          CoreUtils.showTopSnackBarFromSnackBar(
            context: context,
            snackBar: const SnackBar(
              content: Text('Failed to load classroom data. Please try again.'),
            ),
          );
          return;
        }

        setState(() {
          _isClassroomDataReady = true;
        });
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop(); // Close loading dialog
        final message = ApiErrorHandler.extractErrorMessage(e);
        CoreUtils.showTopSnackBarFromSnackBar(
          context: context,
          snackBar: SnackBar(content: Text(message)),
        );
        return;
      }
    }

    // Ensure tag mapping is loaded
    if (_tagNameToCode.isEmpty && !_isLoadingTagMap) {
      await _loadTagNameCodeMap();
    }

    // Wait for tag map if still loading
    if (_isLoadingTagMap) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Wait for tag map to finish loading (max 5 seconds)
      int attempts = 0;
      while (_isLoadingTagMap && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
    }

    final result = await Navigator.push<Map<String, List<String>>>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _classroomCubit,
          child: StudentFilterScreen(
            initialFilters: {
              'Classroom': List<String>.from(_selectedClassroomNames),
              'Tags': List<String>.from(_selectedTagNames),
            },
            sections: const [
              StudentFilterSection.classroom,
              StudentFilterSection.tags,
            ],
          ),
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _selectedClassroomNames = List<String>.from(
        result['Classroom'] ?? const [],
      );
      _selectedTagNames = List<String>.from(result['Tags'] ?? const []);
    });

    // Reload attendance data with new filters
    _loadAttendanceData(reset: true);
  }

  void _openStudentListWithIncomingFilter(String status) {
    final normalized = status.trim().toUpperCase();
    if (normalized != 'ACTIVE' && normalized != 'UPCOMING') return;
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<StudentCubit>(
              create: (_) => serviceLocator<StudentCubit>()..loadInitial(),
            ),
            BlocProvider<ClassroomCubit>(
              create: (_) =>
                  serviceLocator<ClassroomCubit>()
                    ..loadActiveClassrooms(applyAttendanceStaffScope: true),
            ),
          ],
          child: StudentScreen(incomingStatusFilter: normalized),
        ),
      ),
    );
  }
}
