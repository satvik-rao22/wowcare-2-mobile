import 'dart:async';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/presentation/features/students/model/student_sibling_info.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/filter_icon_button.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/presentation/features/classroom/view/widgets/classroom_student_list_item.dart';
import 'package:wowcare/presentation/features/students/widgets/student_action_panel.dart';
import 'package:wowcare/presentation/features/students/widgets/student_attendance_action_availability.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/geofencing/view_model/geofence_cubit.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_permission_service.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_absent_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_in_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_out_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_transfer_form_list_usecase.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/domain/features/student_classroom/entities/student_classroom_item.dart';
import 'package:wowcare/presentation/features/classroom/view_model/classroom_students_cubit.dart';
import 'package:wowcare/presentation/features/classroom/view_model/classroom_students_state.dart';
import 'package:wowcare/presentation/features/classroom/view_model/classroom_cubit.dart';
import 'package:wowcare/presentation/features/classroom/view/filters/classroom_student_filter_screen.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/student_sign_in_form.dart'
    as sign_in_form;
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/student_sign_out_form.dart'
    as sign_out_form;
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/student_transfer_form.dart'
    as transfer_form;
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/student_mark_absent_form.dart'
    as absent_form;
import 'package:wowcare/shared/common/widgets/highlightable_card.dart';
import 'package:wowcare/presentation/features/communication/bulk_messaging/utils/messaging_shortcut.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

/// Bumped by any screen/flow that mutates the classroom roster (e.g. the
/// "Assign Students to Classroom" sheet). The Students-tab card listens and
/// invalidates its cubit + attendance cache so the new student is visible
/// immediately, without the user having to switch tabs to force a rebuild.
final ValueNotifier<int> classroomStudentsRefreshTick = ValueNotifier<int>(0);

void notifyClassroomStudentsChanged() {
  classroomStudentsRefreshTick.value++;
}

/// Clears the process-wide today's-attendance cache shared by every Students
/// tab instance. Called on school switch so a newly selected school never
/// shows the previous school's cached attendance status.
void clearClassroomStudentsAttendanceCache() {
  ClassroomStudentsCubit.clearAttendanceStatusCache();
}

class ClassroomStudentsTabCard extends StatelessWidget {
  const ClassroomStudentsTabCard({
    required this.scrollController,
    required this.selectedRoom,
    this.highlightCode,
    super.key,
  });

  final ScrollController scrollController;
  final Classroom? selectedRoom;

  /// Student code from a notification deep-link; the matching row is scrolled
  /// into view and briefly flashed.
  final String? highlightCode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ClassroomStudentsCubit>(
      create: (_) => serviceLocator<ClassroomStudentsCubit>(),
      child: _ClassroomStudentsTabCardView(
        scrollController: scrollController,
        selectedRoom: selectedRoom,
        highlightCode: highlightCode,
      ),
    );
  }
}

class _ClassroomStudentsTabCardView extends StatefulWidget {
  const _ClassroomStudentsTabCardView({
    required this.scrollController,
    required this.selectedRoom,
    this.highlightCode,
  });

  final ScrollController scrollController;
  final Classroom? selectedRoom;
  final String? highlightCode;

  @override
  State<_ClassroomStudentsTabCardView> createState() =>
      _ClassroomStudentsTabCardViewState();
}

class _ClassroomStudentsTabCardViewState
    extends State<_ClassroomStudentsTabCardView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  /// Notification deep-link target row.
  final GlobalKey _highlightRowKey = GlobalKey();
  bool _isHighlightTarget(String code) {
    final target = (widget.highlightCode ?? '').trim();
    return target.isNotEmpty &&
        target.toUpperCase() == code.trim().toUpperCase();
  }

  late final ClassroomStudentsCubit _cubit;
  bool isSelectAllChecked = false;
  Map<String, bool> studentSelections = {};
  // ACTIVE is the permanent baseline status — always sent to the API.
  List<String> _selectedStatus = ['ACTIVE'];
  List<String> _selectedTagCodes = [];
  bool _isNappingFilter = false; // Toggle for napping students
  bool _isPresentFilter = false; // Toggle for present students
  StudentPanelType _currentPanel = StudentPanelType.none;
  bool _showActivitiesPanel = false;
  bool _isAttendanceActionLoading = false;
  bool _isPrefetchingAttendanceData = false;
  int _attendancePrefetchToken = 0;
  Map<String, sign_in_form.StudentEntity> _signInEntitiesByCode = {};
  Map<String, sign_out_form.StudentEntity> _signOutEntitiesByCode = {};
  Map<String, transfer_form.StudentEntity> _transferEntitiesByCode = {};
  Map<String, absent_form.StudentEntity> _absentEntitiesByCode = {};

  final List<String> statusDisplayValues = ['Active', 'Upcoming'];
  final List<String> statuses = ['ACTIVE', 'UPCOMING'];

  final List<String> tags = ['Tag 1', 'Tag 2', 'Tag 3'];

  @override
  void initState() {
    super.initState();
    _cubit = context.read<ClassroomStudentsCubit>();
    _searchController.addListener(_onSearchChanged);
    _loadForSelectedRoom(refresh: false);
    _loadNapStartStudentCodes(refresh: false);
    classroomStudentsRefreshTick.addListener(_handleExternalRefresh);
  }

  void _handleExternalRefresh() {
    if (!mounted) return;
    // Roster changed elsewhere (assign sheet, etc.) — drop the today's
    // attendance status cache for this room so the new student shows up
    // with fresh status, then refetch the student list.
    _cubit.invalidateAttendanceStatus();
    _loadForSelectedRoom(refresh: true);
    _loadNapStartStudentCodes(refresh: true);
  }

  /// Pull-to-refresh: re-run every API this tab uses (student roster, today's
  /// attendance status, nap-start codes), bypassing the repository and
  /// attendance caches.
  Future<void> _refreshAll() async {
    if (!mounted) return;
    _cubit.invalidateAttendanceStatus();
    // Refresh the shared classroom dropdown list too, so a pull refreshes the
    // whole page's data — not just this tab.
    await _reloadClassroomList();
    if (_isNappingFilter) {
      // Napping filter on: refresh nap-start codes + roster scoped to nappers.
      await _applyNappingFilter(refresh: true);
    } else {
      _loadForSelectedRoom(refresh: true);
      await _loadNapStartStudentCodes(refresh: true);
    }
  }

  /// Force-reloads the classroom dropdown list (bypassing its cache) via the
  /// shared [ClassroomCubit] provided by the Classroom screen. Non-fatal: if the
  /// provider isn't in scope the pull-to-refresh still refreshes this tab.
  Future<void> _reloadClassroomList() async {
    try {
      await context.read<ClassroomCubit>().loadActiveClassrooms(
        force: true,
        applyAttendanceStaffScope: true,
      );
    } catch (_) {
      // Provider missing or reload failed — ignore.
    }
  }

  /// Used as the `refreshCallback` for every sign-in / sign-out / transfer /
  /// mark-absent form. The form just told us a student's attendance just
  /// flipped — but the cubit's attendance-status cache still holds the
  /// pre-action status (it has a 10-minute TTL). Without dropping that cache,
  /// the next time
  /// the user selects the same student the attendance gate computes against
  /// stale data and "Sign In" stays disabled after a successful Sign Out
  /// (and vice versa). Wiping the room's cache here forces a fresh fetch.
  void _dismissSelectionPanel() {
    if (!mounted) return;
    setState(() {
      isSelectAllChecked = false;
      studentSelections.updateAll((key, val) => false);
      _showActivitiesPanel = false;
      _currentPanel = StudentPanelType.none;
    });
  }

  void _refreshAfterAttendanceAction() {
    _dismissSelectionPanel();
    _cubit.invalidateAttendanceStatus();
    _clearAttendanceEntityCaches();
    _loadForSelectedRoom(refresh: true);
  }

  /// Called after an activity is recorded from the Activities panel. A new
  /// activity can change a student's row state (nap, medication, notes, …),
  /// so drop the roster + attendance + nap-start caches and refetch the list.
  void _refreshAfterActivityRecorded() {
    if (!mounted) return;
    _dismissSelectionPanel();
    _cubit.invalidateAttendanceStatus();
    _clearAttendanceEntityCaches();
    _loadForSelectedRoom(refresh: true);
    _loadNapStartStudentCodes(refresh: true);
  }

  void _loadForSelectedRoom({
    required bool refresh,
    List<String>? studentCodes,
    // Bypasses the roster cache while still going through `loadInitial`'s
    // "clear immediately on a different request" UX (unlike `_cubit.refresh`,
    // which deliberately keeps the previous result on screen while
    // refreshing). Only meaningful when [refresh] is false.
    bool forceRefresh = false,
  }) {
    final classroomCode = widget.selectedRoom?.code ?? '';
    if (classroomCode.trim().isEmpty) return;

    final search = _searchController.text.trim().isEmpty
        ? null
        : _searchController.text.trim();

    final status = _selectedStatus.isEmpty
        ? null
        : List<String>.from(_selectedStatus);
    final tagCodes = _selectedTagCodes.isEmpty
        ? null
        : List<String>.from(_selectedTagCodes);

    if (refresh) {
      _cubit.refresh(
        classroomCode: classroomCode,
        search: search,
        studentCodes: studentCodes,
        status: status,
        tagCodes: tagCodes,
      );
    } else {
      _cubit.loadInitial(
        classroomCode: classroomCode,
        search: search,
        studentCodes: studentCodes,
        status: status,
        tagCodes: tagCodes,
        forceRefresh: forceRefresh,
      );
    }
  }

  Future<void> _loadNapStartStudentCodes({required bool refresh}) {
    final classroomCode = (widget.selectedRoom?.code ?? '').trim();
    if (classroomCode.isEmpty) return Future.value();
    return _cubit.loadNapStartStudentCodes(
      classroomCode: classroomCode,
      refresh: refresh,
    );
  }

  /// Refreshes nap-start codes (when [refresh]) and reloads the roster, optionally scoped to nappers.
  Future<void> _applyNappingFilter({required bool refresh}) async {
    final classroomCode = (widget.selectedRoom?.code ?? '').trim();
    if (classroomCode.isEmpty || !_isNappingFilter) return;

    await _loadNapStartStudentCodes(refresh: refresh);
    if (!mounted) return;

    final nappingCodes = _cubit.state.nappingStudentCodes;
    final codes = nappingCodes.isEmpty ? null : List<String>.from(nappingCodes);
    _loadForSelectedRoom(refresh: refresh, studentCodes: codes);
  }

  bool get _isLoadingNapStudents => _cubit.state.napCodesLoading;

  /// Nap-start returned no students while the napping filter is on (show empty / copy).
  bool get _napFilterEmptyResult =>
      _isNappingFilter &&
      !_cubit.state.napCodesLoading &&
      _cubit.state.nappingStudentCodes.isEmpty;

  @override
  void didUpdateWidget(_ClassroomStudentsTabCardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRoom != widget.selectedRoom) {
      setState(() {
        isSelectAllChecked = false;
        studentSelections.updateAll((key, val) => false);
        _searchController.clear();
        _selectedStatus = ['ACTIVE'];
        _selectedTagCodes = [];
        _isNappingFilter = false;
        _isPresentFilter = false;
      });
      // Force a fresh fetch (bypass the roster cache) on every classroom
      // switch — not just on pull-to-refresh. A student transferred into
      // this room moments ago (from elsewhere in the app) wouldn't appear
      // otherwise: without forcing, a cache entry up to 5 minutes old can
      // short-circuit the network call entirely, so switching to this room
      // via the dropdown could silently serve a pre-transfer roster until
      // the user manually pulls to refresh. Still routed through
      // `loadInitial` (refresh: false), not `_cubit.refresh`, so the OLD
      // room's roster is cleared immediately instead of staying on screen
      // under a loading spinner while the new room's fetch is in flight.
      _loadForSelectedRoom(refresh: false, forceRefresh: true);
      _loadNapStartStudentCodes(refresh: true);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    classroomStudentsRefreshTick.removeListener(_handleExternalRefresh);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    // No manual _cubit.close() — the ancestor BlocProvider in
    // ClassroomStudentsTabCard now owns the cubit's lifecycle.
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce so fast typing collapses into a single API call once the user
    // pauses, instead of firing (and dropping) a request per keystroke.
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (_isNappingFilter) {
        _applyNappingFilter(refresh: false);
      } else {
        _loadForSelectedRoom(refresh: false);
      }
    });
  }

  void _toggleSelectAll(
    bool? value,
    List<StudentClassroomItem> visibleStudents,
  ) {
    if (value == null) return;

    setState(() {
      isSelectAllChecked = value;
      for (final student in visibleStudents) {
        studentSelections[student.studentCode] = value;
      }
    });
    _prefetchAttendanceEntitiesForSelection(visibleStudents);
    _refreshAttendanceStatusForSelection(visibleStudents);
  }

  void _toggleStudentSelection(
    String studentCode,
    bool? value,
    List<StudentClassroomItem> visibleStudents,
  ) {
    if (value == null) return;

    setState(() {
      studentSelections[studentCode] = value;

      isSelectAllChecked = visibleStudents.every(
        (student) => studentSelections[student.studentCode] == true,
      );

      // Reset panel if no students are selected
      if (!hasSelectedStudents) {
        _currentPanel = StudentPanelType.none;
      }
    });
    _prefetchAttendanceEntitiesForSelection(visibleStudents);
    _refreshAttendanceStatusForSelection(visibleStudents);
  }

  bool get hasSelectedStudents {
    return studentSelections.values.any((selected) => selected);
  }

  /// Display label for an API status value (e.g. `ACTIVE` -> `Active`).
  String _statusChipLabel(String apiStatus) {
    switch (apiStatus.trim().toUpperCase()) {
      case 'ACTIVE':
        return 'Active';
      case 'UPCOMING':
        return 'Upcoming';
      default:
        return apiStatus;
    }
  }

  /// One chip per selected status (so both show when ACTIVE + UPCOMING are
  /// picked). Tapping a chip opens the filter screen to change the selection.
  Widget _buildStatusChip(String apiStatus) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: AppColors.classroomStatusChipBackgroundColor,
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.cardColor,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _openClassroomStudentFilter,
        child: Text(
          _statusChipLabel(apiStatus),
          style: const TextStyle(
            fontFamily: AppFonts.body,
            color: AppColors.secondaryColor,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  /// Whether the filter funnel has anything applied beyond the ACTIVE
  /// default, so the funnel icon can surface a red dot for it.
  bool get _isStudentFilterActive {
    final statusSet = _selectedStatus
        .map((e) => e.trim().toUpperCase())
        .toSet();
    final isDefaultStatus =
        statusSet.length == 1 && statusSet.first == 'ACTIVE';
    return !isDefaultStatus || _selectedTagCodes.isNotEmpty;
  }

  Future<void> _openClassroomStudentFilter() async {
    final result = await Navigator.push<ClassroomStudentFilterResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ClassroomStudentFilterScreen(
          initialStatus: _selectedStatus,
          initialTagCodes: _selectedTagCodes,
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      // Respect the explicit filter-screen choice exactly (e.g. UPCOMING only
      // drops ACTIVE). Only fall back to the ACTIVE default when nothing is
      // selected.
      final picked = result.status
          .map((e) => e.trim().toUpperCase())
          .where((e) => e.isNotEmpty)
          .toList();
      _selectedStatus = picked.isEmpty ? ['ACTIVE'] : picked;
      _selectedTagCodes = List<String>.from(result.tagCodes);
    });
    _loadForSelectedRoom(refresh: false);
  }

  void _clearAllSelections() {
    setState(() {
      isSelectAllChecked = false;
      studentSelections.updateAll((key, val) => false);
      _searchController.clear();
      _selectedStatus = ['ACTIVE'];
      _selectedTagCodes = [];
      _isNappingFilter = false;
      _isPresentFilter = false;
      _currentPanel = StudentPanelType.none;
    });
    _clearAttendanceEntityCaches();
    _cubit.invalidateAttendanceStatus();
    _loadForSelectedRoom(refresh: false);
  }

  int get _selectedCount {
    return studentSelections.values.where((selected) => selected).length;
  }

  List<StudentClassroomItem> _getSelectedStudents(
    List<StudentClassroomItem> visibleStudents,
  ) {
    return visibleStudents
        .where((student) => studentSelections[student.studentCode] == true)
        .toList();
  }

  /// Same shape as [ChooseActivity.selectedStudents] for class activity list + create flow.
  List<Map<String, dynamic>> _activityStudentMaps(
    List<StudentClassroomItem> selected,
  ) {
    final roomCode = widget.selectedRoom?.code.trim() ?? '';
    return selected.map((s) {
      final norm = s.studentCode.trim().toUpperCase();
      final napping = s.nap || _cubit.state.nappingStudentCodes.contains(norm);
      return <String, dynamic>{
        'name': s.fullName,
        'studentCode': s.studentCode,
        'classroomCode': s.classroomCode.trim().isNotEmpty
            ? s.classroomCode.trim()
            : roomCode,
        'nappingStatus': napping,
        'isNapping': napping,
      };
    }).toList();
  }

  Map<String, dynamic> _getStudentIcons(StudentClassroomItem student) {
    final icons = <String, dynamic>{};

    final normalized = student.studentCode.trim().toUpperCase();
    final isNapping =
        student.nap || _cubit.state.nappingStudentCodes.contains(normalized);
    if (isNapping) {
      icons["napping"] = {
        "icon": 'assets/images/icons/sleep.png',
        "info": 'Student is napping',
      };
    }
    if (!student.photoPermission) {
      icons["photo"] = {
        "icon": MediaRes.cameraIcon,
        "info": 'No Photo Permission',
      };
    }
    if (student.medication) {
      icons["medication"] = {"icon": MediaRes.healthIcon, "info": 'Medication'};
    }
    if (student.notes) {
      icons["note"] = {"icon": MediaRes.docsIcon, "info": 'Notes'};
    }
    if (student.allergies) {
      icons["allergies"] = {"icon": MediaRes.alertIcon, "info": 'Allergies'};
    }
    if (student.dietaryRestriction) {
      icons["dietRestriction"] = {
        "icon": MediaRes.foodIcon2,
        "info": 'Dietary Restrictions',
      };
    }

    return icons;
  }

  void _applyNappingToggle(bool enabled) {
    setState(() {
      _isNappingFilter = enabled;
    });
    if (enabled) {
      Future.microtask(() => _applyNappingFilter(refresh: false));
    } else {
      _loadForSelectedRoom(refresh: false);
    }
  }

  /// Mirrors [ClassroomStudentListItem]: activities only when green signed-in
  /// dot (today's status). Grey rows, absent (red), or missing/other status → off.
  bool _canShowActivitiesPanel(List<StudentClassroomItem> selectedStudents) {
    if (!hasSelectedStudents) return false;
    if (_cubit.state.attendanceStatusLoading ||
        _cubit.state.attendanceStatusError) {
      return false;
    }

    if (selectedStudents.length > 1) {
      final roomFallback = (widget.selectedRoom?.code ?? '').trim();
      final firstCc = selectedStudents.first.classroomCode.trim();
      final canonical = firstCc.isNotEmpty ? firstCc : roomFallback;
      if (canonical.isEmpty) return false;
      final sameRoom = selectedStudents.every((s) {
        final c = s.classroomCode.trim().isNotEmpty
            ? s.classroomCode.trim()
            : roomFallback;
        return c == canonical;
      });
      if (!sameRoom) return false;
    }

    return selectedStudents.every((s) {
      final raw = _todayStatusForStudentCode(s.studentCode);
      return (raw ?? '').trim().toUpperCase() == 'SIGNED_IN';
    });
  }

  String? _activitiesDisabledHint(List<StudentClassroomItem> selectedStudents) {
    if (!hasSelectedStudents) return null;
    if (_cubit.state.attendanceStatusLoading) {
      return 'Hang on—we are loading attendance. Try Activities again in a moment.';
    }
    if (_cubit.state.attendanceStatusError) {
      return "Today's attendance could not be loaded. Pull to refresh, then try again.";
    }
    if (selectedStudents.length > 1) {
      final roomFallback = (widget.selectedRoom?.code ?? '').trim();
      final firstCc = selectedStudents.first.classroomCode.trim();
      final canonical = firstCc.isNotEmpty ? firstCc : roomFallback;
      if (canonical.isEmpty) {
        return 'Select students in the same classroom to record activities together.';
      }
      final sameRoom = selectedStudents.every((s) {
        final c = s.classroomCode.trim().isNotEmpty
            ? s.classroomCode.trim()
            : roomFallback;
        return c == canonical;
      });
      if (!sameRoom) {
        return 'Select students in the same classroom to record activities together.';
      }
    }
    return 'Activities can be recorded only when all selected students are '
        'signed in.';
  }

  // Backend disabled
  // Future<List<GuardianEntity>> getGuardianInfoForStudent(String studentId) async { return []; }

  // Backend disabled
  // Future<List<Staff>> fetchAllStaffs() async { return []; }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _normalizeStudentCode(String code) => code.trim().toUpperCase();

  String? _todayStatusForStudentCode(String code) {
    final t = code.trim();
    if (t.isEmpty) return null;
    final statusByCode = _cubit.state.attendanceStatusByStudentCode;
    if (statusByCode.containsKey(t)) {
      return statusByCode[t];
    }
    final u = _normalizeStudentCode(t);
    for (final e in statusByCode.entries) {
      if (_normalizeStudentCode(e.key) == u) return e.value;
    }
    return null;
  }

  bool _isSignedInFromAttendanceStatus(StudentClassroomItem student) {
    final raw = _todayStatusForStudentCode(student.studentCode);
    final normalized = (raw ?? '').trim().toUpperCase();
    if (normalized == 'SIGNED_IN') return true;
    // Fallback to classroom list flag when map isn't loaded yet.
    return student.signedIn;
  }

  /// Re-checks the CURRENTLY SELECTED students' attendance status
  /// immediately after a selection change — always a live fetch (no TTL
  /// cache), matching [ClassroomStudentsCubit.refreshAttendanceStatusForSelection].
  Future<void> _refreshAttendanceStatusForSelection(
    List<StudentClassroomItem> visibleStudents,
  ) {
    final selected = _getSelectedStudents(visibleStudents);
    final codes = selected
        .map((s) => s.studentCode.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    return _cubit.refreshAttendanceStatusForSelection(codes);
  }

  StudentAttendanceActionAvailability _attendanceAvailabilityForSelection(
    List<StudentClassroomItem> selected,
  ) {
    if (selected.isEmpty) {
      return StudentAttendanceActionAvailability.allDisabled;
    }
    if (_cubit.state.attendanceStatusLoading ||
        _cubit.state.attendanceStatusError) {
      return StudentAttendanceActionAvailability.allDisabled;
    }
    if (!AttendancePermissionService.hasPermissionToManageStudentAttendance(
      context,
    )) {
      return StudentAttendanceActionAvailability.allDisabled;
    }
    final gates = selected.map((s) {
      // The roster `status` field is frequently omitted/varies in the
      // student-classroom API. An empty value must NOT be read as
      // "inactive" — a student present in the roster is an attendee, so
      // NOT_MARKED / SIGNED_OUT students must keep Sign-In enabled. Only an
      // explicit non-ACTIVE enrollment status (e.g. UPCOMING) blocks it.
      final rawStatus = s.status.trim().toUpperCase();
      final isActive = rawStatus.isEmpty || rawStatus == 'ACTIVE';
      return studentAttendanceGateFromTodayStatus(
        isActiveProfile: isActive,
        todayStatusRaw: _todayStatusForStudentCode(s.studentCode),
      );
    });

    return StudentAttendanceActionAvailability.fromGates(gates);
  }

  void _clearAttendanceEntityCaches() {
    _signInEntitiesByCode = {};
    _signOutEntitiesByCode = {};
    _transferEntitiesByCode = {};
    _absentEntitiesByCode = {};
  }

  /// Warms the row-icon details cache for every visible student whose list-API
  /// flags say they have a health-backed icon (allergies / medication / diet /
  /// photo). The details dialog reads from the same cache, so the first tap
  /// after the roster loads shows the actual text immediately, no loader.
  void _prefetchDetailsHealthForVisibleStudents(
    List<StudentClassroomItem> visibleStudents,
  ) {
    for (final s in visibleStudents) {
      final hasHealthIcon =
          s.allergies ||
          s.medication ||
          s.dietaryRestriction ||
          !s.photoPermission;
      if (!hasHealthIcon) continue;
      // Fire-and-forget; the helper dedupes in-flight + cached entries.
      // ignore: unawaited_futures
      prefetchStudentDetailsHealth(s.studentCode);
    }
  }

  Future<void> _prefetchAttendanceEntitiesForSelection(
    List<StudentClassroomItem> visibleStudents,
  ) async {
    final selectedStudents = _getSelectedStudents(visibleStudents);
    final selectedCodes = selectedStudents
        .map((s) => _normalizeStudentCode(s.studentCode))
        .where((c) => c.isNotEmpty)
        .toSet();
    if (selectedCodes.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isPrefetchingAttendanceData = false;
        _clearAttendanceEntityCaches();
      });
      return;
    }

    final date = _formatDate(AppTime.now());
    final token = ++_attendancePrefetchToken;
    final roomCode = (widget.selectedRoom?.code ?? '').trim();
    final classroomCodes = roomCode.isEmpty ? null : <String>[roomCode];

    if (mounted) {
      setState(() {
        _isPrefetchingAttendanceData = true;
      });
    }

    try {
      final signInUseCase = serviceLocator<GetStudentSignInFormListUseCase>();
      final signOutUseCase = serviceLocator<GetStudentSignOutFormListUseCase>();
      final transferUseCase =
          serviceLocator<GetStudentTransferFormListUseCase>();
      final absentUseCase = serviceLocator<GetStudentAbsentFormListUseCase>();

      final signInFuture = signInUseCase(
        fromAttendanceDate: date,
        toAttendanceDate: date,
        classroomCodes: classroomCodes,
        page: 0,
        size: 500,
      );
      final signOutFuture = signOutUseCase(
        fromAttendanceDate: date,
        toAttendanceDate: date,
        classroomCodes: classroomCodes,
        page: 0,
        size: 500,
      );
      final transferFuture = transferUseCase(
        fromAttendanceDate: date,
        toAttendanceDate: date,
        classroomCodes: classroomCodes,
        page: 0,
        size: 500,
      );
      final absentFuture = absentUseCase(
        fromAbsenceDate: date,
        toAbsenceDate: date,
        classroomCodes: classroomCodes,
        page: 0,
        size: 500,
      );

      // Attach listeners to all futures immediately so fast failures are caught.
      await Future.wait([
        signInFuture,
        signOutFuture,
        transferFuture,
        absentFuture,
      ]);
      final signInPage = await signInFuture;
      final signOutPage = await signOutFuture;
      final transferPage = await transferFuture;
      final absentPage = await absentFuture;
      if (!mounted || token != _attendancePrefetchToken) return;

      final signInMap = <String, sign_in_form.StudentEntity>{};
      for (final item in signInPage.items) {
        final normalized = _normalizeStudentCode(item.studentCode);
        if (!selectedCodes.contains(normalized)) continue;
        signInMap[normalized] = sign_in_form.StudentEntity(
          id: signInMap.length + 1,
          studentCode: item.studentCode,
          fullName: item.studentName,
          roomId: 0,
          roomName: item.classroomName,
          classroomCode: item.classroomCode,
          photoUuid: null,
          isExpectedToday: item.isExpectedToday,
        );
      }

      final signOutMap = <String, sign_out_form.StudentEntity>{};
      for (final item in signOutPage.items) {
        final normalized = _normalizeStudentCode(item.studentCode);
        if (!selectedCodes.contains(normalized)) continue;
        signOutMap[normalized] = sign_out_form.StudentEntity(
          id: signOutMap.length + 1,
          studentCode: item.studentCode,
          fullName: item.studentName,
          roomId: 0,
          roomName: item.classroomName,
          classroomCode: item.classroomCode,
        );
      }

      final transferMap = <String, transfer_form.StudentEntity>{};
      for (final item in transferPage.items) {
        final normalized = _normalizeStudentCode(item.studentCode);
        if (!selectedCodes.contains(normalized)) continue;
        transferMap[normalized] = transfer_form.StudentEntity(
          id: transferMap.length + 1,
          studentCode: item.studentCode,
          fullName: item.studentName,
          roomId: 0,
          roomName: item.classroomName,
          classroomCode: item.classroomCode,
          tags: item.tagNames
              .map((name) => transfer_form.TagEntity(name: name))
              .toList(),
        );
      }

      final absentMap = <String, absent_form.StudentEntity>{};
      for (final item in absentPage.items) {
        final normalized = _normalizeStudentCode(item.studentCode);
        if (!selectedCodes.contains(normalized)) continue;
        absentMap[normalized] = absent_form.StudentEntity(
          id: absentMap.length + 1,
          studentCode: item.studentCode,
          fullName: item.studentName,
          roomId: 0,
          roomName: item.classroomName,
          classroomCode: item.classroomCode,
        );
      }

      if (!mounted) return;
      setState(() {
        _signInEntitiesByCode = signInMap;
        _signOutEntitiesByCode = signOutMap;
        _transferEntitiesByCode = transferMap;
        _absentEntitiesByCode = absentMap;
      });
    } catch (_) {
      if (!mounted || token != _attendancePrefetchToken) return;
      setState(() {
        _clearAttendanceEntityCaches();
      });
    } finally {
      if (mounted && token == _attendancePrefetchToken) {
        setState(() {
          _isPrefetchingAttendanceData = false;
        });
      }
    }
  }

  /// Classroom code for a roster student, falling back to the open room.
  String _rosterClassroomCode(StudentClassroomItem s) {
    final cc = s.classroomCode.trim();
    return cc.isNotEmpty ? cc : (widget.selectedRoom?.code.trim() ?? '');
  }

  Future<void> _openAttendanceActionFlow({
    required List<StudentClassroomItem> allStudents,
    required String actionName,
  }) async {
    final selectedStudents = _getSelectedStudents(allStudents);
    if (selectedStudents.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Select at least one student',
        isError: true,
      );
      return;
    }

    final selectedCodes = selectedStudents
        .map((s) => _normalizeStudentCode(s.studentCode))
        .where((c) => c.isNotEmpty)
        .toSet();
    if (selectedCodes.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Selected students are missing codes',
        isError: true,
      );
      return;
    }

    if (_isPrefetchingAttendanceData) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Preparing selected students. Please wait...',
        isError: true,
      );
      return;
    }

    setState(() {
      _isAttendanceActionLoading = true;
    });
    try {
      if (actionName == 'sign_in') {
        // Eligibility was already gated by today's sign-in status in the
        // action panel. Prefer the prefetched form-list entity; fall back to
        // the selected roster student so a gate-enabled action is never
        // blocked by the form-list API not returning that student.
        if (selectedCodes.every((c) => _signInEntitiesByCode[c] == null)) {
          await _prefetchAttendanceEntitiesForSelection(allStudents);
        }
        final entities = <sign_in_form.StudentEntity>[];
        for (final s in selectedStudents) {
          final prefetched =
              _signInEntitiesByCode[_normalizeStudentCode(s.studentCode)];
          entities.add(
            prefetched ??
                sign_in_form.StudentEntity(
                  id: entities.length + 1,
                  studentCode: s.studentCode,
                  fullName: s.fullName,
                  roomId: 0,
                  roomName: widget.selectedRoom?.name ?? '',
                  classroomCode: _rosterClassroomCode(s),
                  isExpectedToday: s.expectedToday,
                ),
          );
        }
        if (entities.isEmpty) {
          throw Exception('No selected students are eligible for Sign-In');
        }

        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => sign_in_form.StudentSignInForm(
              students: entities,
              refreshCallback: _refreshAfterAttendanceAction,
              popOnSuccess: true,
            ),
          ),
        );
        return;
      }

      if (actionName == 'sign_out') {
        // Eligibility was already gated by today's sign-in status in the
        // action panel. Prefer the prefetched form-list entity; fall back to
        // the selected roster student so a gate-enabled action is never
        // blocked by the form-list API not returning that student.
        if (selectedCodes.every((c) => _signOutEntitiesByCode[c] == null)) {
          await _prefetchAttendanceEntitiesForSelection(allStudents);
        }
        final entities = <sign_out_form.StudentEntity>[];
        for (final s in selectedStudents) {
          final prefetched =
              _signOutEntitiesByCode[_normalizeStudentCode(s.studentCode)];
          entities.add(
            prefetched ??
                sign_out_form.StudentEntity(
                  id: entities.length + 1,
                  studentCode: s.studentCode,
                  fullName: s.fullName,
                  roomId: 0,
                  roomName: widget.selectedRoom?.name ?? '',
                  classroomCode: _rosterClassroomCode(s),
                ),
          );
        }
        if (entities.isEmpty) {
          throw Exception('No selected students are eligible for Sign-Out');
        }

        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => sign_out_form.StudentSignOutForm(
              students: entities,
              refreshCallback: _refreshAfterAttendanceAction,
              popOnSuccess: true,
            ),
          ),
        );
        return;
      }

      if (actionName == 'transfer') {
        // Eligibility was already gated by today's sign-in status in the
        // action panel. Prefer the prefetched form-list entity; fall back to
        // the selected roster student so a gate-enabled action is never
        // blocked by the form-list API not returning that student.
        if (selectedCodes.every((c) => _transferEntitiesByCode[c] == null)) {
          await _prefetchAttendanceEntitiesForSelection(allStudents);
        }
        final entities = <transfer_form.StudentEntity>[];
        for (final s in selectedStudents) {
          final prefetched =
              _transferEntitiesByCode[_normalizeStudentCode(s.studentCode)];
          entities.add(
            prefetched ??
                transfer_form.StudentEntity(
                  id: entities.length + 1,
                  studentCode: s.studentCode,
                  fullName: s.fullName,
                  roomId: 0,
                  roomName: widget.selectedRoom?.name ?? '',
                  classroomCode: _rosterClassroomCode(s),
                ),
          );
        }
        if (entities.isEmpty) {
          throw Exception('No selected students are eligible for Transfer');
        }

        ClassroomCubit? classroomCubit;
        try {
          classroomCubit = context.read<ClassroomCubit>();
        } catch (_) {
          classroomCubit = null;
        }
        final classroomNameToCode = <String, String>{
          for (final c in (classroomCubit?.state.classrooms ?? const []))
            c.name: c.code,
        };

        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => transfer_form.StudentTransferForm(
              students: entities,
              classroomNameToCode: classroomNameToCode,
              refreshCallback: _refreshAfterAttendanceAction,
              popOnSuccess: true,
              // The room being viewed is authoritative for "where the student is
              // now" — the student record still points at their enrolled room
              // after a transfer, which previously left this room selectable as
              // a transfer destination.
              currentClassroomCode: widget.selectedRoom?.code,
              currentClassroomName: widget.selectedRoom?.name,
            ),
          ),
        );
        return;
      }

      // Eligibility was already gated by today's sign-in status in the
      // action panel. Prefer the prefetched form-list entity; fall back to
      // the selected roster student so a gate-enabled action is never
      // blocked by the form-list API not returning that student.
      if (selectedCodes.every((c) => _absentEntitiesByCode[c] == null)) {
        await _prefetchAttendanceEntitiesForSelection(allStudents);
      }
      final entities = <absent_form.StudentEntity>[];
      for (final s in selectedStudents) {
        final prefetched =
            _absentEntitiesByCode[_normalizeStudentCode(s.studentCode)];
        entities.add(
          prefetched ??
              absent_form.StudentEntity(
                id: entities.length + 1,
                studentCode: s.studentCode,
                fullName: s.fullName,
                roomId: 0,
                roomName: widget.selectedRoom?.name ?? '',
                classroomCode: _rosterClassroomCode(s),
              ),
        );
      }
      if (entities.isEmpty) {
        throw Exception('No selected students are eligible for Mark Absent');
      }

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => absent_form.StudentMarkAbsentForm(
            students: entities,
            refreshCallback: _refreshAfterAttendanceAction,
            popOnSuccess: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAttendanceActionLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<GeofenceCubit>();
    return BlocBuilder<ClassroomStudentsCubit, ClassroomStudentsState>(
      builder: (context, state) {
        final q = _searchController.text.trim().toLowerCase();
        final visibleStudents = state.students.where((s) {
          if (_isPresentFilter && !_isSignedInFromAttendanceStatus(s)) {
            return false;
          }
          if (_isNappingFilter) {
            final code = s.studentCode.trim().toUpperCase();
            final isNapping =
                s.nap || _cubit.state.nappingStudentCodes.contains(code);
            if (!isNapping) return false;
          }
          if (q.isNotEmpty && !s.fullName.toLowerCase().contains(q)) {
            return false;
          }
          return true;
        }).toList()..sort((a, b) => a.fullName.compareTo(b.fullName));

        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Status is fetched for the full roster (not `visibleStudents`)
          // so the Sign-In filter has every student's status available.
          // ignore: discarded_futures
          _cubit.refreshAttendanceStatusForRoster(state.students);
          _prefetchDetailsHealthForVisibleStudents(visibleStudents);
        });

        final effectiveVisibleStudents =
            _isNappingFilter && _napFilterEmptyResult
            ? <StudentClassroomItem>[]
            : visibleStudents;

        final selectedStudents = _getSelectedStudents(effectiveVisibleStudents);
        final canStudentActivities = _canShowActivitiesPanel(selectedStudents);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (!canStudentActivities &&
              (_showActivitiesPanel ||
                  _currentPanel == StudentPanelType.activities)) {
            setState(() {
              _showActivitiesPanel = false;
              _currentPanel = StudentPanelType.none;
            });
          }
        });

        return Stack(
          children: [
            Card(
              elevation: 0,
              margin: const EdgeInsets.all(0),
              shape: const Border(
                left: BorderSide(color: AppColors.themeColor),
                top: BorderSide(color: AppColors.themeColor),
                right: BorderSide(color: AppColors.themeColor),
                bottom: BorderSide(color: AppColors.themeColor),
              ),
              color: AppColors.cardColor,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomSearchBar(
                            controller: _searchController,
                            hintText: 'Search',
                            density: SearchFieldDensity.compact,
                            radius: 10,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilterIconButton(
                          iconAsset: MediaRes.filterIcon,
                          isActive: _isStudentFilterActive,
                          onPressed: _openClassroomStudentFilter,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: CustomCheckbox(
                                borderColor: AppColors.primaryColor.withValues(
                                  alpha: 0.2,
                                ),
                                value: isSelectAllChecked,
                                onChanged: (val) => _toggleSelectAll(
                                  val,
                                  effectiveVisibleStudents,
                                ),
                              ),
                            ),
                            const Text(
                              'Select All',
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                color: AppColors.primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                for (final status in _selectedStatus) ...[
                                  _buildStatusChip(status),
                                  const SizedBox(width: 8),
                                ],
                                SkeuKeyBox(
                                  variant: KeyVariant.primary,
                                  radius: 6,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.cardColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 3,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: _clearAllSelections,
                                    child: const Text(
                                      'Clear All',
                                      style: TextStyle(
                                        fontFamily: AppFonts.body,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Information'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: details.entries.map((
                                              entry,
                                            ) {
                                              bool isSvg = entry.key.endsWith(
                                                '.svg',
                                              );
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4.0,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    isSvg
                                                        ? AppArtwork(
                                                            entry.key,
                                                            width: 24,
                                                            height: 24,
                                                          )
                                                        : Image.asset(
                                                            entry.key,
                                                            width: 24,
                                                            height: 24,
                                                          ),
                                                    const SizedBox(width: 20),
                                                    Expanded(
                                                      child: Text(
                                                        entry.value,
                                                        style: const TextStyle(
                                                          fontFamily:
                                                              AppFonts.body,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              child: const Text('Close'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.info_outline_rounded,
                                    color: AppColors.primaryColor,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CustomToggle(
                              label: 'Signed In',
                              isToggled: _isPresentFilter,
                              onToggle: (value) {
                                setState(() {
                                  _isPresentFilter = value;
                                });
                              },
                              labelStyle: const TextStyle(
                                fontFamily: AppFonts.body,
                                color: AppColors.primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 20),
                            CustomToggle(
                              label: 'Napping',
                              isToggled: _isNappingFilter,
                              onToggle: (value) {
                                _applyNappingToggle(value);
                              },
                              labelStyle: const TextStyle(
                                fontFamily: AppFonts.body,
                                color: AppColors.primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          if ((state.isLoading || _isLoadingNapStudents) &&
                              effectiveVisibleStudents.isEmpty) {
                            return const ClassroomStudentsListShimmer();
                          }

                          if (effectiveVisibleStudents.isEmpty) {
                            return CustomRefreshIndicator(
                              onRefresh: _refreshAll,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return ListView(
                                    children: [
                                      SizedBox(
                                        height: constraints.maxHeight,
                                        child: Center(
                                          child: Text(
                                            _isNappingFilter &&
                                                    _napFilterEmptyResult
                                                ? 'No students are currently napping.'
                                                : _isNappingFilter
                                                ? 'No students are napping.'
                                                : 'No students assigned.',
                                            style: TextStyle(
                                              fontFamily: AppFonts.body,
                                              fontSize: 16,
                                              color: AppColors.primaryColor
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          }

                          final upcomingOnlyFilter =
                              _selectedStatus.length == 1 &&
                              _selectedStatus.first.trim().toUpperCase() ==
                                  'UPCOMING';

                          return CustomRefreshIndicator(
                            onRefresh: _refreshAll,
                            child: ListView.builder(
                              // Always scrollable so a short roster (too few
                              // students to fill the viewport) can still be
                              // pulled to refresh.
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: effectiveVisibleStudents.length,
                              itemBuilder: (context, index) {
                                final student = effectiveVisibleStudents[index];
                                final isTarget = _isHighlightTarget(
                                  student.studentCode,
                                );
                                return HighlightableCard(
                                  key: isTarget ? _highlightRowKey : null,
                                  code: student.studentCode,
                                  highlightCode: widget.highlightCode,
                                  borderRadius: 12,
                                  onHighlighted: () {
                                    final ctx = _highlightRowKey.currentContext;
                                    if (ctx != null) {
                                      Scrollable.ensureVisible(
                                        ctx,
                                        duration: const Duration(
                                          milliseconds: 400,
                                        ),
                                        alignment: 0.1,
                                        curve: Curves.easeOut,
                                      );
                                    }
                                  },
                                  child: ClassroomStudentListItem(
                                    studentId: student.studentCode.hashCode,
                                    studentCode: student.studentCode,
                                    isSignedIn: student.signedIn,
                                    isAbsent: student.absent,
                                    isExpectedToday: student.expectedToday,
                                    studentStatus: student.status,
                                    todayAttendanceStatusRaw:
                                        _todayStatusForStudentCode(
                                          student.studentCode,
                                        ),
                                    name: student.fullName,
                                    imageUrl: student.profilePictureUrl ?? '',
                                    icons: _getStudentIcons(student),
                                    forceUpcomingProfileStatusDot:
                                        upcomingOnlyFilter,
                                    isSelected:
                                        studentSelections[student
                                            .studentCode] ??
                                        false,
                                    onSelectionChanged: (bool? value) {
                                      _toggleStudentSelection(
                                        student.studentCode,
                                        value,
                                        effectiveVisibleStudents,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // StudentActionPanel shown when students are selected
            if (hasSelectedStudents)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StudentActionPanel(
                        currentPanel: _currentPanel,
                        activityStudentMaps: canStudentActivities
                            ? _activityStudentMaps(selectedStudents)
                            : null,
                        onActivityRecorded: _refreshAfterActivityRecorded,
                        attendanceAvailability:
                            _attendanceAvailabilityForSelection(
                              selectedStudents,
                            ),
                        onAttendanceTap: () {
                          setState(() {
                            final open =
                                _currentPanel == StudentPanelType.attendance;
                            _currentPanel = open
                                ? StudentPanelType.none
                                : StudentPanelType.attendance;
                            _showActivitiesPanel = false;
                          });
                        },
                        onMessageTap: () {
                          final classroomCode = widget.selectedRoom?.code ?? '';
                          final selected = selectedStudents
                              .map(
                                (s) => SelectedRecipient(
                                  code: s.studentCode,
                                  name: s.fullName,
                                  isStaff: false,
                                  avatar: s.profilePictureUrl ?? '',
                                  classroomCode: classroomCode,
                                ),
                              )
                              .toList();
                          openMessagingShortcut(context, recipients: selected);
                        },
                        onActivitiesTap: canStudentActivities
                            ? () {
                                setState(() {
                                  _showActivitiesPanel = !_showActivitiesPanel;
                                  _currentPanel = _showActivitiesPanel
                                      ? StudentPanelType.activities
                                      : StudentPanelType.none;
                                });
                              }
                            : null,
                        onProfileTap: _selectedCount == 1
                            ? () async {
                                if (selectedStudents.isEmpty) return;
                                final student = selectedStudents.first;
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudentProfileScreen(
                                      name: student.fullName,
                                      classroom:
                                          widget.selectedRoom?.name ??
                                          'Unknown Class',
                                      tags: const [],
                                      schedule: const [
                                        'Monday',
                                        'Tuesday',
                                        'Wednesday',
                                        'Thursday',
                                        'Friday',
                                      ],
                                      sibling: const StudentSiblingInfo(),
                                      studentCode: student.studentCode,
                                      initialEnrollmentStatus: student.status,
                                    ),
                                  ),
                                );
                                if (!mounted) return;
                                // Profile screen may have mutated student data
                                // (status, schedule, photo, tags, health, ...).
                                // Refresh the roster + cached attendance so the
                                // list reflects the latest values, and drop the
                                // row-icon details dialog cache for this student
                                // so the next tap re-fetches their health.
                                invalidateStudentDetailsHealthCache(
                                  student.studentCode,
                                );
                                _refreshAfterAttendanceAction();
                                _loadNapStartStudentCodes(refresh: true);
                              }
                            : null,
                        onClearSelections: () {
                          setState(() {
                            isSelectAllChecked = false;
                            studentSelections.updateAll((key, val) => false);
                            _showActivitiesPanel = false;
                            _currentPanel = StudentPanelType.none;
                          });
                        },
                        isProfileEnabled: _selectedCount == 1,
                        activitiesEnabled: canStudentActivities,
                        activitiesDisabledHint: canStudentActivities
                            ? null
                            : _activitiesDisabledHint(selectedStudents),
                        showAttendanceActions:
                            _currentPanel == StudentPanelType.attendance,
                        isAttendanceActionLoading:
                            _isAttendanceActionLoading ||
                            _isPrefetchingAttendanceData,
                        onSignInTap: () => _openAttendanceActionFlow(
                          allStudents: state.students,
                          actionName: 'sign_in',
                        ),
                        onSignOutTap: () => _openAttendanceActionFlow(
                          allStudents: state.students,
                          actionName: 'sign_out',
                        ),
                        onTransferTap: () => _openAttendanceActionFlow(
                          allStudents: state.students,
                          actionName: 'transfer',
                        ),
                        onMarkAbsentTap: () => _openAttendanceActionFlow(
                          allStudents: state.students,
                          actionName: 'mark_absent',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class CustomMultiSelectDropdown extends StatefulWidget {
  final String hintText;
  final List<String> items;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;
  final bool isField;
  final double? width;

  const CustomMultiSelectDropdown({
    Key? key,
    required this.hintText,
    required this.items,
    required this.selectedItems,
    required this.onChanged,
    this.isField = false,
    this.width,
  }) : super(key: key);

  @override
  State<CustomMultiSelectDropdown> createState() =>
      _CustomMultiSelectDropdownState();
}

class _CustomMultiSelectDropdownState extends State<CustomMultiSelectDropdown> {
  late List<String> _localSelectedItems;

  @override
  void initState() {
    super.initState();
    _localSelectedItems = List.from(widget.selectedItems);
  }

  @override
  void didUpdateWidget(CustomMultiSelectDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.selectedItems, widget.selectedItems)) {
      _localSelectedItems = List.from(widget.selectedItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayText = _localSelectedItems.isEmpty
        ? widget.hintText
        : '${_localSelectedItems.length} selected';

    return Container(
      height: 32,
      width: widget.width,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.cardColor,
          hintText: widget.hintText,
          contentPadding: const EdgeInsets.symmetric(horizontal: 5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.classroomBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.classroomBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.classroomBorderColor),
          ),
        ),
        icon: const Icon(Icons.keyboard_arrow_down),
        iconSize: 24,
        elevation: 2,
        style: const TextStyle(
          fontFamily: AppFonts.body,
          color: AppColors.classroomTextColor,
          fontSize: 16,
        ),
        dropdownColor: AppColors.cardColor,
        items: widget.items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            enabled: false,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                final isSelected = _localSelectedItems.contains(item);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _localSelectedItems.remove(item);
                      } else {
                        _localSelectedItems.add(item);
                      }
                    });
                    widget.onChanged(_localSelectedItems);
                  },
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomCheckbox(
                          value: isSelected,
                          onChanged: (bool? checked) {
                            setState(() {
                              if (checked == true) {
                                _localSelectedItems.add(item);
                              } else {
                                _localSelectedItems.remove(item);
                              }
                            });
                            widget.onChanged(_localSelectedItems);
                          },
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 14,
                              color: AppColors.classroomTextColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
        onChanged: (_) {},
        isExpanded: true,
        hint: Text(
          displayText,
          style: TextStyle(
            fontFamily: AppFonts.body,
            color: _localSelectedItems.isEmpty
                ? AppColors.classroomPlaceholderTextColor
                : AppColors.classroomTextColor,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

Map<String, String> details = {
  'assets/images/icons/sleep.png': 'Student is napping',
  MediaRes.cameraIcon: 'No Photo',
  MediaRes.healthIcon: 'Medication',
  MediaRes.docsIcon: 'Notes',
  MediaRes.alertIcon: 'Allergies',
  MediaRes.foodIcon2: 'Dietary Restrictions',
};
