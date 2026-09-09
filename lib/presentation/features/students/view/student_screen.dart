import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/presentation/features/students/model/student_sibling_info.dart';

import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/data/features/student/datasources/student_remote_datasource.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_absent_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_in_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_out_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_transfer_form_list_usecase.dart';
import 'package:wowcare/presentation/features/students/widgets/student_attendance_action_availability.dart';
import 'package:wowcare/presentation/features/classroom/view_model/classroom_cubit.dart';
import 'package:wowcare/presentation/features/students/view_model/student_cubit.dart';
import 'package:wowcare/presentation/features/students/view/student_filter_screen.dart';
import 'package:wowcare/presentation/features/students/view/edit_student_profile_details_screen.dart';
import 'package:wowcare/presentation/features/students/widgets/student_action_panel.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/student_sign_in_form.dart'
    as sign_in_form;
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/student_sign_out_form.dart'
    as sign_out_form;
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/student_transfer_form.dart'
    as transfer_form;
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/student_mark_absent_form.dart'
    as absent_form;
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/services/image_upload/profile_photo_upload_events.dart';
import 'package:wowcare/presentation/features/geofencing/view_model/geofence_cubit.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_permission_service.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_stat_bar_card.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/highlightable_card.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/presentation/features/students/module_access.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';
import 'package:wowcare/presentation/features/students/view/student_empty_state.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/post_add_student_bottom_sheet.dart';
import 'package:wowcare/presentation/features/students/widgets/student_card.dart';
import 'add_student_wizard_screen.dart';
import 'package:wowcare/presentation/features/communication/bulk_messaging/utils/messaging_shortcut.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({
    super.key,
    this.incomingStatusFilter,
    this.incomingClassroomSelections,
    this.incomingHighlightCode,
  });

  static const String routeName = '/dashboard/students';
  final String? incomingStatusFilter;

  /// Classroom names or codes (same as filter sheet / [StudentCubit] — both resolve).
  final List<String>? incomingClassroomSelections;

  /// Student code from a notification deep-link; the matching card is scrolled
  /// into view, pre-expanded, and briefly flashed. Null for normal navigation.
  final String? incomingHighlightCode;

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showActivitiesPanel = false;
  StudentPanelType _currentPanel = StudentPanelType.none;

  // Per-row selection is owned by StudentCubit (single source of truth).
  // "Select all" is DERIVED, never a competing field.
  List<bool> get _selectedDemo => context.read<StudentCubit>().state.selection;
  bool get _selectAll =>
      _selectedDemo.isNotEmpty && _selectedDemo.every((e) => e);

  // Filter SELECTION + Active/Inactive toggle are owned by StudentCubit (single
  // source of truth). These read-only views expose cubit state to the existing
  // build/read sites; all writes go through the cubit (see _applyFiltersToCubit
  // / setSelectedFilters). The widget keeps NO competing filter field.
  Map<String, List<String>> get _currentFilters =>
      context.read<StudentCubit>().state.selectedFilters;
  bool get _showInactive => context.read<StudentCubit>().state.showInactive;
  bool _isAttendanceActionLoading = false;

  /// Notification deep-link target; cleared after the card scrolls/flashes once
  /// so later rebuilds (search, pagination) don't re-trigger the highlight.
  String? _highlightStudentCode;
  final GlobalKey _highlightCardKey = GlobalKey();

  bool _isHighlightTarget(String code) {
    final target = (_highlightStudentCode ?? '').trim();
    return target.isNotEmpty &&
        target.toUpperCase() == code.trim().toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _highlightStudentCode = widget.incomingHighlightCode?.trim();
    _applyIncomingStatusFilter();
    _applyIncomingClassroomSelections();
    _searchController.addListener(_onSearchChanged);
    // Refresh the list when a background profile-photo upload finishes, so the
    // new photo shows — same refresh as after an add.
    ProfilePhotoUploadEvents.studentTick.addListener(_onProfilePhotoUploaded);
    // Load students from API via cubit after first frame to ensure BlocProvider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _bootstrapList();
    });
  }

  void _onProfilePhotoUploaded() {
    if (!mounted) return;
    context.read<StudentCubit>().refreshWithCacheReset();
  }

  Future<void> _bootstrapList() async {
    // If a deep-link highlights a student, resolve their status FIRST and set
    // the filter so the very first list load fetches the right bucket. Doing it
    // after loadInitial() caused a race where the default Active load finished
    // after the Inactive refetch and clobbered it (chip showed Inactive but the
    // Active list remained).
    await _applyHighlightStatusFilter();
    if (!mounted) return;
    final cubit = context.read<StudentCubit>();
    context.read<ClassroomCubit>().loadActiveClassrooms(
      onlyTypeClassroom: false,
      applyAttendanceStaffScope: true,
    );
    cubit.loadInitial();
    await _applyFiltersToCubit(_currentFilters);
    cubit.loadTagNameCodeMap();
    cubit.loadGuardianNameCodeMap();
    cubit.loadCounts();
    cubit.loadExpectedSummary();
  }

  void _applyIncomingStatusFilter() {
    final incoming = (widget.incomingStatusFilter ?? '').trim().toUpperCase();
    if (incoming != 'ACTIVE' &&
        incoming != 'UPCOMING' &&
        incoming != 'INACTIVE') {
      return;
    }
    final statusLabel = incoming[0] + incoming.substring(1).toLowerCase();
    context.read<StudentCubit>().setSelectedFilters({
      ..._currentFilters,
      'Status': [statusLabel],
    }, showInactive: _isInactiveStatus(statusLabel));
  }

  /// A notification deep-link (e.g. "student deactivated") only carries the
  /// studentCode and lands on the Active list. If that student is actually
  /// Inactive/Upcoming they won't appear here — so the highlight can't find
  /// them. Resolve the target's status and switch the Status filter to the
  /// matching bucket. Runs BEFORE the first list load (and sets the cubit's
  /// status filter too) so the single initial fetch uses the right bucket —
  /// avoiding a race where the default Active load clobbers an Inactive refetch.
  Future<void> _applyHighlightStatusFilter() async {
    final code = (_highlightStudentCode ?? '').trim();
    if (code.isEmpty) return;
    final current = (_currentFilters['Status']?.isNotEmpty == true)
        ? _currentFilters['Status']!.first.trim().toUpperCase()
        : 'ACTIVE';
    // A non-Active bucket was already chosen (deep-link status filter or user
    // filter) — respect it.
    if (current != 'ACTIVE') return;
    try {
      // MVVM holdout (documented): getStudentProfile here needs the rich StudentProfileModel (status/dob/address/tags/fte/...); the domain StudentProfile entity is a narrow projection, so this read stays on the datasource until the entity is enriched (S6 typed-models).
      final profile = await serviceLocator<StudentRemoteDataSource>()
          .getStudentProfile(code);
      if (!mounted) return;
      final status = profile.status.trim().toUpperCase();
      if (status.isEmpty || status == 'ACTIVE' || status == 'A') return;
      final label = (status == 'INACTIVE' || status == 'I')
          ? 'Inactive'
          : (status == 'UPCOMING')
          ? 'Upcoming'
          : status[0] + status.substring(1).toLowerCase();
      // Set the cubit's status filter + selection now so the upcoming
      // loadInitial() fetches this bucket (not Active), preventing the override
      // race. Pre-load: no chip rebuild needed yet.
      context.read<StudentCubit>().setSelectedFilters({
        ..._currentFilters,
        'Status': [label],
      }, showInactive: _isInactiveStatus(label));
      context.read<StudentCubit>().updateFilters(status: label);
    } catch (_) {
      // Couldn't resolve status — leave the default Active filter in place.
    }
  }

  void _applyIncomingClassroomSelections() {
    final raw = widget.incomingClassroomSelections;
    if (raw == null || raw.isEmpty) return;
    final cleaned = raw
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return;
    context.read<StudentCubit>().setSelectedFilters({
      ..._currentFilters,
      'Classroom': cleaned,
    });
  }

  @override
  void dispose() {
    ProfilePhotoUploadEvents.studentTick.removeListener(
      _onProfilePhotoUploaded,
    );
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    // Debounced in the cubit: the query updates immediately (superseding any
    // in-flight request via the generation guard) and the network refresh fires
    // once typing settles, instead of a full load per keystroke.
    context.read<StudentCubit>().onSearchChanged(query);
  }

  void _openStudentAttendanceWithLegendFilter(String status) {
    context.push(
      '/dashboard/student-attendance-tabbed-view',
      extra: <String, dynamic>{'filter': status, 'initialTabIndex': 0},
    );
  }

  Future<void> _refreshAllStudentApis() async {
    final studentCubit = context.read<StudentCubit>();
    await Future.wait([
      studentCubit.refreshWithCacheReset(),
      studentCubit.loadTagNameCodeMap(),
      studentCubit.loadGuardianNameCodeMap(),
      studentCubit.loadCounts(),
      studentCubit.loadExpectedSummary(),
    ]);
  }

  Future<void> _openEditStudentDetails(String studentCode) async {
    try {
      // MVVM holdout (documented): getStudentProfile here needs the rich StudentProfileModel (status/dob/address/tags/fte/...); the domain StudentProfile entity is a narrow projection, so this read stays on the datasource until the entity is enriched (S6 typed-models).
      final dataSource = serviceLocator<StudentRemoteDataSource>();
      final profile = await dataSource.getStudentProfile(studentCode);
      if (!mounted) return;

      // --- Map fields exactly like StudentAboutTabCard.onEdit ---

      // Map status from API format (ACTIVE) to display format (Active)
      String statusDisplay = 'Active';
      final upperStatus = profile.status.toUpperCase();
      if (upperStatus == 'ACTIVE' || profile.status == 'A') {
        statusDisplay = 'Active';
      } else if (upperStatus == 'INACTIVE' || profile.status == 'I') {
        statusDisplay = 'Inactive';
      } else if (upperStatus == 'UPCOMING' || profile.status == 'Upcoming') {
        statusDisplay = 'Upcoming';
      } else if (upperStatus == 'WAITLIST') {
        statusDisplay = 'Waitlist';
      } else if (upperStatus == 'GRADUATED') {
        statusDisplay = 'Graduated';
      }

      // Parse birth date
      DateTime? birthDate;
      if (profile.dob != null && profile.dob!.isNotEmpty) {
        try {
          birthDate = DateTime.parse(profile.dob!);
        } catch (_) {
          birthDate = null;
        }
      }

      // Extract address fields
      final address = profile.address;
      final street = address?['street']?.toString() ?? '';
      final city = address?['city']?.toString() ?? '';
      final state = address?['state']?.toString() ?? '';
      final country = address?['country']?.toString() ?? '';
      final zipCode =
          address?['zipCode']?.toString() ??
          address?['postalCode']?.toString() ??
          '';

      // Extract tags as display names from profile.tags[]
      final tags = <String>[];
      for (final raw in profile.tags) {
        if (raw is Map<String, dynamic>) {
          final name = (raw['name'] ?? '').toString().trim();
          if (name.isNotEmpty) tags.add(name);
        }
      }

      // Extract siblings as codes for edit screen (API returns list of objects).
      final siblings = <String>[];
      if (profile.siblings.isNotEmpty) {
        for (final s in profile.siblings) {
          if (s is Map<String, dynamic>) {
            final code = (s['code'] ?? '').toString().trim();
            if (code.isNotEmpty) {
              siblings.add(code);
            }
          }
        }
      }

      // Extract legal custodians using same display logic as guardian names API.
      final legalCustodians = <String>[];
      if (profile.legalCustodians.isNotEmpty) {
        for (final custodian in profile.legalCustodians) {
          if (custodian is String) {
            if (custodian.trim().isNotEmpty) {
              legalCustodians.add(custodian.trim());
            }
          } else if (custodian is Map<String, dynamic>) {
            final first = (custodian['firstName'] ?? '').toString().trim();
            final last = (custodian['lastName'] ?? '').toString().trim();
            final email = (custodian['email'] ?? '').toString().trim();
            final code = (custodian['code'] ?? '').toString().trim();

            String display;
            if (first.isEmpty && last.isEmpty) {
              display = email.isNotEmpty ? email : code;
            } else {
              display = '$first $last'.trim();
            }

            if (display.isNotEmpty) {
              legalCustodians.add(display);
            }
          }
        }
      }

      final edited = await context.push(
        EditStudentProfileDetailsScreen.routeName,
        extra: <String, dynamic>{
          'studentCode': profile.code,
          'initialFirstName': profile.firstName,
          'initialLastName': profile.lastName,
          'initialStatus': statusDisplay,
          'initialGender': profile.gender,
          'initialClassroom': profile.classroom ?? '',
          'initialBirthDate': birthDate,
          'initialNotes': profile.notes ?? '',
          'initialStreet': street,
          'initialCity': city,
          'initialState': state,
          'initialCountry': country,
          'initialZipCode': zipCode,
          'initialTags': tags,
          'initialSiblings': siblings,
          'initialLegalCustodians': legalCustodians,
          'initialSubsidy': profile.subsidy,
          'applyAttendanceStaffScope': true,
        },
      );
      // If student was edited, refresh + reset list cache.
      if (!mounted) return;
      if (edited == true) {
        await _refreshAllStudentApis();
      }
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    }
  }

  /// Resolve the display [selection] to backend codes and hand them to the
  /// StudentCubit, which becomes the single owner of BOTH the selection and the
  /// resolved code filters. Rebuilds the (non-BlocBuilder) filter chips, then
  /// refetches. Callers pass the NEW selection; nothing is stored on the widget.
  Future<void> _applyFiltersToCubit(
    Map<String, List<String>> selection, {
    bool? showInactive,
  }) async {
    final statusFilter = selection['Status']?.isNotEmpty == true
        ? selection['Status']!.first
        : 'Active';

    // Normalize selected classroom values to classroom codes for the API.
    // The UI may carry classroom names, but backend filters must use codes.
    final classroomState = context.read<ClassroomCubit>().state;
    final nameToCode = {
      for (final c in classroomState.classrooms) c.name: c.code,
    };
    final validCodes = {
      for (final c in classroomState.classrooms) c.code.trim(),
    }..removeWhere((code) => code.isEmpty);

    final selectedClassroomValues = selection['Classroom'] ?? const <String>[];
    final classroomCodes = selectedClassroomValues
        .map((value) {
          final trimmed = value.trim();
          if (trimmed.isEmpty) return null;
          if (validCodes.contains(trimmed)) return trimmed;
          // Accept a raw classroom code even before ClassroomCubit has loaded
          // (e.g. deep-linked from the classroom info screen) so the filter
          // applies automatically instead of waiting for the classroom list.
          if (trimmed.toUpperCase().startsWith('CLS_')) return trimmed;
          return nameToCode[trimmed]?.trim();
        })
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    // Name→code lookups now live on the cubit (single owner); resolve against
    // the current cubit state.
    final studentState = context.read<StudentCubit>().state;

    final selectedTagNames = selection['Tags'] ?? const <String>[];
    final tagCodes = selectedTagNames
        .map((name) => studentState.tagNameToCode[name])
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toList();

    final selectedGuardianNames = selection['Parents'] ?? const <String>[];
    final guardianCodes = selectedGuardianNames
        .map((name) => studentState.guardianNameToCode[name])
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toList();

    // API expects underscored codes, e.g. attendanceStatus=SIGNED_IN&attendanceStatus=ABSENT.
    const labelToAttendanceCode = <String, String>{
      'Signed-In': 'SIGNED_IN',
      'Signed-Out': 'SIGNED_OUT',
      'Not-Marked': 'NOT_MARKED',
      'Absent': 'ABSENT',
    };
    final selectedAttendanceLabels =
        selection['Attendance'] ?? const <String>[];
    final attendanceStatuses = selectedAttendanceLabels
        .map((label) => labelToAttendanceCode[label])
        .whereType<String>()
        .toList();

    final resolvedShowInactive =
        showInactive ?? (statusFilter.trim().toUpperCase() == 'INACTIVE');

    // Single write: stores the selection + resolved codes + toggle in one emit.
    context.read<StudentCubit>().updateFilters(
      status: statusFilter,
      classroomCodes: classroomCodes.isEmpty ? null : classroomCodes,
      tagCodes: tagCodes.isEmpty ? null : tagCodes,
      guardianCodes: guardianCodes.isEmpty ? null : guardianCodes,
      attendanceStatuses: attendanceStatuses.isEmpty
          ? null
          : attendanceStatuses,
      selection: selection,
      showInactive: resolvedShowInactive,
    );
    // Rebuild the filter chips/toggle (they read cubit state but live outside
    // the list's BlocBuilder). Pure rebuild trigger — data stays cubit-owned.
    if (mounted) setState(() {});
    await context.read<StudentCubit>().refreshWithCacheReset();
  }

  // Convert Student entity to map format for compatibility with existing UI
  Map<String, dynamic> _studentToMap(
    Student student, {
    required Map<String, String> classroomNameByCode,
  }) {
    return {
      'name': student.fullName,
      'profileImage': student.profileImage,
      'profilePhotoAssetCode': student.profilePhotoAssetCode,
      'Classroom': _classroomDisplayName(
        student.classroom,
        classroomNameByCode: classroomNameByCode,
      ),
      'Tags': student.tags,
      // Use schedule derived from regularSchedules if available; otherwise empty.
      'schedule': student.schedule,
      'scheduleByDay': student.scheduleByDay,
      // Keep raw DOB; card widget is responsible for display formatting
      'birthDate': student.dob,
      'movementDate': student.movementDate,
      'Status': student.status,
      'Attendance': 'Expected', // API doesn't provide attendance yet
      'Parents': <String>[], // API doesn't provide parents yet
      'sibling': const StudentSiblingInfo(), // API doesn't provide siblings yet
      'activities': <String>[], // API doesn't provide activities yet
      'code': student.code,
    };
  }

  Future<void> _clearAllFilters() async {
    await _applyFiltersToCubit({
      'Status': ['Active'],
    }, showInactive: false);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _normalizeStudentCode(String code) => code.trim().toUpperCase();

  String _classroomDisplayName(
    String rawCodeOrName, {
    required Map<String, String> classroomNameByCode,
  }) {
    final value = rawCodeOrName.trim();
    if (value.isEmpty) return '-';
    final mappedName = classroomNameByCode[value];
    if (mappedName != null && mappedName.trim().isNotEmpty) {
      return mappedName.trim();
    }
    // If API already sent a plain classroom name (not a code), keep showing it.
    if (!value.toUpperCase().startsWith('CLS_')) {
      return value;
    }
    // Avoid showing classroom code on cards when classroom name is unavailable.
    return '-';
  }

  Map<String, String> _mergedClassroomDisplayNames(
    Map<String, String> cubitNameByCode,
  ) {
    final merged = Map<String, String>.from(cubitNameByCode);
    final detailNames = context
        .read<StudentCubit>()
        .state
        .classroomNameByDetailApi;
    for (final e in detailNames.entries) {
      final n = e.value.trim();
      if (n.isNotEmpty) merged[e.key] = n;
    }
    return merged;
  }

  List<Student> _getSelectedStudents(List<Student> students) {
    final selected = <Student>[];
    for (int i = 0; i < _selectedDemo.length; i++) {
      if (_selectedDemo[i] && i < students.length) {
        selected.add(students[i]);
      }
    }
    return selected;
  }

  /// True when at least one selected student is inactive. Attendance and
  /// Activities cannot be performed on inactive students, so both actions are
  /// disabled for the whole selection when this is true.
  bool _hasInactiveSelected(List<Student> students) {
    return _getSelectedStudents(
      students,
    ).any((s) => s.status.trim().toUpperCase() != 'ACTIVE');
  }

  /// True when 2+ selected students span more than one classroom. Activities
  /// can only be recorded for one classroom at a time.
  bool _hasCrossClassroomSelection(List<Student> students) {
    final selected = _getSelectedStudents(students);
    if (selected.length < 2) return false;
    final firstClassroom = selected.first.classroom;
    return selected.any((s) => s.classroom != firstClassroom);
  }

  String _resolveClassroomCodeForStudent(
    Student student, {
    required Map<String, String> classroomCodeByName,
  }) {
    // The students-list API already returns the student's live/current
    // classroom code directly (see [Student.classroomCode]) — always prefer
    // it. A transferred student's current classroom can be outside this
    // staff member's scoped [classroomCodeByName] list, so falling back to a
    // name -> code lookup (or worse, the raw display name) for that case
    // silently sends activities to the wrong classroom.
    final liveCode = student.classroomCode.trim();
    if (liveCode.isNotEmpty) return liveCode;

    final raw = student.classroom.trim();
    if (raw.isEmpty) return '';
    if (raw.toUpperCase().startsWith('CLS_')) return raw;
    final mapped = classroomCodeByName[raw];
    if (mapped != null && mapped.trim().isNotEmpty) {
      return mapped.trim();
    }
    return raw;
  }

  /// Same shape as [ChooseActivity.selectedStudents] for class-scoped activity list + create flow.
  List<Map<String, dynamic>> _activityStudentMaps(
    List<Student> students, {
    required Map<String, String> classroomCodeByName,
  }) {
    return _getSelectedStudents(students)
        .map(
          (s) => <String, dynamic>{
            'name': s.fullName,
            'studentCode': s.code,
            'classroomCode': _resolveClassroomCodeForStudent(
              s,
              classroomCodeByName: classroomCodeByName,
            ),
          },
        )
        .toList();
  }

  String? _todayStatusForStudentCode(String code) {
    final t = code.trim();
    if (t.isEmpty) return null;
    final statusByCode = context
        .read<StudentCubit>()
        .state
        .attendanceStatusByStudentCode;
    if (statusByCode.containsKey(t)) {
      return statusByCode[t];
    }
    final u = _normalizeStudentCode(t);
    for (final e in statusByCode.entries) {
      if (_normalizeStudentCode(e.key) == u) return e.value;
    }
    return null;
  }

  /// Today's sign-in status for the selected rows is now owned by StudentCubit,
  /// which computes the selection from its own state — the widget just triggers
  /// the refresh.
  Future<void> _refreshAttendanceStatusForSelection() {
    return context.read<StudentCubit>().refreshAttendanceStatusForSelection();
  }

  StudentAttendanceActionAvailability _attendanceAvailabilityForSelection(
    List<Student> students,
  ) {
    if (!_selectedDemo.any((e) => e)) {
      return StudentAttendanceActionAvailability.allDisabled;
    }
    final attState = context.read<StudentCubit>().state;
    if (attState.attendanceStatusLoading || attState.attendanceStatusError) {
      return StudentAttendanceActionAvailability.allDisabled;
    }
    if (!AttendancePermissionService.hasPermissionToManageStudentAttendance(
      context,
    )) {
      return StudentAttendanceActionAvailability.allDisabled;
    }

    final selected = _getSelectedStudents(students);
    if (selected.isEmpty) {
      return StudentAttendanceActionAvailability.allDisabled;
    }

    final gates = selected.map((s) {
      return studentAttendanceGateFromTodayStatus(
        isActiveProfile: s.status.trim().toUpperCase() == 'ACTIVE',
        todayStatusRaw: _todayStatusForStudentCode(s.code),
      );
    });
    return StudentAttendanceActionAvailability.fromGates(gates);
  }

  Future<void> _openAttendanceActionFlow({
    required List<Student> students,
    required String actionName,
  }) async {
    final selectedStudents = _getSelectedStudents(students);
    if (selectedStudents.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.selectAtLeastOneStudent,
        isError: true,
      );
      return;
    }

    final selectedCodes = selectedStudents
        .map((s) => _normalizeStudentCode(s.code))
        .where((c) => c.isNotEmpty)
        .toSet();
    if (selectedCodes.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.selectedStudentsAreMissingCodes,
        isError: true,
      );
      return;
    }

    setState(() {
      _isAttendanceActionLoading = true;
    });
    try {
      final date = _formatDate(AppTime.now());

      if (actionName == 'sign_in') {
        final useCase = serviceLocator<GetStudentSignInFormListUseCase>();
        final page = await useCase(
          fromAttendanceDate: date,
          toAttendanceDate: date,
          page: 0,
          size: 500,
        );
        final entities = page.items
            .where(
              (item) => selectedCodes.contains(
                _normalizeStudentCode(item.studentCode),
              ),
            )
            .toList()
            .asMap()
            .entries
            .map((entry) {
              final item = entry.value;
              return sign_in_form.StudentEntity(
                id: entry.key + 1,
                studentCode: item.studentCode,
                fullName: item.studentName,
                roomId: 0,
                roomName: item.classroomName,
                classroomCode: item.classroomCode,
                photoUuid: null,
                isExpectedToday: item.isExpectedToday,
              );
            })
            .toList();
        if (entities.isEmpty) {
          throw Exception('No selected students are eligible for Sign-In');
        }

        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => sign_in_form.StudentSignInForm(
              students: entities,
              refreshCallback: () {
                context.read<StudentCubit>().refresh();
              },
            ),
          ),
        );
        return;
      }

      if (actionName == 'sign_out') {
        final useCase = serviceLocator<GetStudentSignOutFormListUseCase>();
        final page = await useCase(
          fromAttendanceDate: date,
          toAttendanceDate: date,
          page: 0,
          size: 500,
        );
        final entities = page.items
            .where(
              (item) => selectedCodes.contains(
                _normalizeStudentCode(item.studentCode),
              ),
            )
            .toList()
            .asMap()
            .entries
            .map((entry) {
              final item = entry.value;
              return sign_out_form.StudentEntity(
                id: entry.key + 1,
                studentCode: item.studentCode,
                fullName: item.studentName,
                roomId: 0,
                roomName: item.classroomName,
                classroomCode: item.classroomCode,
              );
            })
            .toList();
        if (entities.isEmpty) {
          throw Exception('No selected students are eligible for Sign-Out');
        }

        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => sign_out_form.StudentSignOutForm(
              students: entities,
              refreshCallback: () {
                context.read<StudentCubit>().refresh();
              },
            ),
          ),
        );
        return;
      }

      if (actionName == 'transfer') {
        final useCase = serviceLocator<GetStudentTransferFormListUseCase>();
        final page = await useCase(
          fromAttendanceDate: date,
          toAttendanceDate: date,
          page: 0,
          size: 500,
        );
        final entities = page.items
            .where(
              (item) => selectedCodes.contains(
                _normalizeStudentCode(item.studentCode),
              ),
            )
            .toList()
            .asMap()
            .entries
            .map((entry) {
              final item = entry.value;
              return transfer_form.StudentEntity(
                id: entry.key + 1,
                studentCode: item.studentCode,
                fullName: item.studentName,
                roomId: 0,
                roomName: item.classroomName,
                classroomCode: item.classroomCode,
                tags: item.tagNames
                    .map((name) => transfer_form.TagEntity(name: name))
                    .toList(),
              );
            })
            .toList();
        if (entities.isEmpty) {
          throw Exception('No selected students are eligible for Transfer');
        }

        final classroomState = context.read<ClassroomCubit>().state;
        final classroomNameToCode = <String, String>{
          for (final c in classroomState.classrooms) c.name: c.code,
        };

        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => transfer_form.StudentTransferForm(
              students: entities,
              classroomNameToCode: classroomNameToCode,
              refreshCallback: () {
                context.read<StudentCubit>().refresh();
              },
            ),
          ),
        );
        return;
      }

      final useCase = serviceLocator<GetStudentAbsentFormListUseCase>();
      final page = await useCase(
        fromAbsenceDate: date,
        toAbsenceDate: date,
        page: 0,
        size: 500,
      );
      final entities = page.items
          .where(
            (item) =>
                selectedCodes.contains(_normalizeStudentCode(item.studentCode)),
          )
          .toList()
          .asMap()
          .entries
          .map((entry) {
            final item = entry.value;
            return absent_form.StudentEntity(
              id: entry.key + 1,
              studentCode: item.studentCode,
              fullName: item.studentName,
              roomId: 0,
              roomName: item.classroomName,
              classroomCode: item.classroomCode,
            );
          })
          .toList();
      if (entities.isEmpty) {
        throw Exception('No selected students are eligible for Mark Absent');
      }

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => absent_form.StudentMarkAbsentForm(
            students: entities,
            refreshCallback: () {
              context.read<StudentCubit>().refresh();
            },
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

  String _statusChipLabel() {
    final statusList = _currentFilters['Status'];
    if (statusList != null && statusList.isNotEmpty) {
      return statusList.first;
    }
    return _showInactive ? 'Inactive' : 'Active';
  }

  bool _isInactiveStatus(String? status) =>
      (status ?? '').trim().toUpperCase() == 'INACTIVE';

  bool _canShowActivitiesButton(selectedCount, List<Student> students) {
    if (selectedCount == 0) return false;

    final selectedIndices = <int>[];
    for (int i = 0; i < _selectedDemo.length; i++) {
      if (_selectedDemo[i] && i < students.length) selectedIndices.add(i);
    }

    if (selectedIndices.isEmpty) return false;

    // Today's attendance must be loaded before we can decide.
    final attState = context.read<StudentCubit>().state;
    if (attState.attendanceStatusLoading || attState.attendanceStatusError) {
      return false;
    }

    // If more than one selected → must be in same classroom
    if (selectedCount > 1) {
      final firstClassroom = students[selectedIndices.first].classroom;
      final sameClassroom = selectedIndices.every(
        (i) => students[i].classroom == firstClassroom,
      );
      if (!sameClassroom) return false;
    }

    // Activities can only be recorded for students signed in today. A mixed
    // selection (one signed-in + one signed-out / not-marked / absent)
    // therefore disables the option.
    return selectedIndices.every((i) {
      final raw = _todayStatusForStudentCode(students[i].code);
      return (raw ?? '').trim().toUpperCase() == 'SIGNED_IN';
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<GeofenceCubit>();
    final double titleFontSize = ResponsiveSizing.titleFontSize(context);
    final double titleLineHeight = ResponsiveSizing.titleLineHeight(context);
    final classroomState = context.watch<ClassroomCubit>().state;
    final classroomNameByCode = <String, String>{
      for (final c in classroomState.classrooms) c.code.trim(): c.name.trim(),
    };
    // Persona-based gate for the two summary cards, read reactively so the very
    // first frame is already correct — a post-frame flag flip would briefly
    // expose the cards to a staff (teacher) persona before hiding them, a data
    // breach. RoleCubit resolves the ACTIVE school's role (roles are per-school,
    // so a global staffType/roles scan is wrong); hide for staff, keep for admin.
    final bool hideSummaryCards = context.watch<RoleCubit>().isStaff;

    return BlocBuilder<StudentCubit, StudentState>(
      builder: (context, state) {
        final studentCubit = context.read<StudentCubit>();
        final students = state.items;
        final mergedClassroomNames = _mergedClassroomDisplayNames(
          classroomNameByCode,
        );
        studentCubit.ensureClassroomDetailNames(students, classroomNameByCode);
        final bool anySelected = _selectedDemo.any((e) => e);
        final int selectedCount = _selectedDemo.where((e) => e).length;
        // Attendance + Activities are not allowed on inactive students.
        final bool hasInactiveSelected = _hasInactiveSelected(students);
        // Computed ONCE per frame (it scans _selectedDemo/students); it was
        // previously recomputed at three call sites below.
        final bool canShowActivities = _canShowActivitiesButton(
          selectedCount,
          students,
        );

        // Update selection list when students list changes
        if (_selectedDemo.length != students.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.read<StudentCubit>().resizeSelection();
            _refreshAttendanceStatusForSelection();
          });
        }

        final actionPanel = anySelected
            ? Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StudentActionPanel(
                        currentPanel: _currentPanel,
                        activityStudentMaps: canShowActivities
                            ? _activityStudentMaps(
                                students,
                                classroomCodeByName: {
                                  for (final c in classroomState.classrooms)
                                    c.name.trim(): c.code.trim(),
                                },
                              )
                            : null,
                        attendanceAvailability:
                            _attendanceAvailabilityForSelection(students),
                        attendanceEnabled: !hasInactiveSelected,
                        attendanceDisabledHint: hasInactiveSelected
                            ? StudentStrings
                                  .youCannotMarkAttendanceForInactiveStudent
                            : null,
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
                        onActivitiesTap:
                            (canShowActivities && !hasInactiveSelected)
                            ? () {
                                setState(() {
                                  _showActivitiesPanel = !_showActivitiesPanel;
                                  _currentPanel = _showActivitiesPanel
                                      ? StudentPanelType.activities
                                      : StudentPanelType.none;
                                });
                              }
                            : null,
                        onMessageTap: () {
                          final selected = <SelectedRecipient>[
                            for (
                              var i = 0;
                              i < _selectedDemo.length && i < students.length;
                              i++
                            )
                              if (_selectedDemo[i])
                                SelectedRecipient(
                                  code: students[i].code,
                                  name: students[i].fullName,
                                  isStaff: false,
                                  // Use the asset code (consistent with the
                                  // rest of the avatar resolution chain)
                                  // rather than the separately-cached
                                  // resolved URL in `profileImage`.
                                  avatar:
                                      students[i].profilePhotoAssetCode ?? '',
                                  // Straight from the student list API's own
                                  // `classroom.code` — see
                                  // Student.classroomCode.
                                  classroomCode: students[i].classroomCode,
                                ),
                          ];
                          openMessagingShortcut(context, recipients: selected);
                        },
                        onProfileTap: selectedCount == 1
                            ? () {
                                final idx = _selectedDemo.indexWhere((e) => e);
                                if (idx != -1 && idx < students.length) {
                                  final student = students[idx];
                                  final studentMap = _studentToMap(
                                    student,
                                    classroomNameByCode: mergedClassroomNames,
                                  );
                                  context.push(
                                    '/dashboard/student-profile',
                                    extra: <String, dynamic>{
                                      'name':
                                          studentMap['name'] as String? ??
                                          'Unknown Student',
                                      'sibling': studentMap['sibling'],
                                      'schedule':
                                          (studentMap['schedule']
                                                  as List<dynamic>?)
                                              ?.map((e) => e.toString())
                                              .toList() ??
                                          <String>[
                                            'Mon',
                                            'Tue',
                                            'Wed',
                                            'Thu',
                                            'Fri',
                                          ],
                                      'classroom':
                                          studentMap['Classroom'] as String? ??
                                          'Unknown Class',
                                      'tags':
                                          (studentMap['Tags'] as List<dynamic>?)
                                              ?.map((e) => e.toString())
                                              .toList() ??
                                          <String>[],
                                      'studentCode':
                                          studentMap['code'] as String?,
                                      'initialEnrollmentStatus':
                                          studentMap['Status'] as String?,
                                    },
                                  );
                                }
                              }
                            : null,
                        onClearSelections: () {
                          context.read<StudentCubit>().clearSelection();
                          setState(() {
                            _showActivitiesPanel = false;
                            _currentPanel = StudentPanelType.none;
                          });
                          _refreshAttendanceStatusForSelection();
                        },
                        isProfileEnabled: selectedCount == 1,
                        activitiesEnabled:
                            canShowActivities && !hasInactiveSelected,
                        activitiesDisabledHint: hasInactiveSelected
                            ? StudentStrings
                                  .youCannotRecordActivitiesForInactiveStudent
                            : (_hasCrossClassroomSelection(students)
                                  ? StudentStrings
                                        .pleaseSelectStudentsFromTheSameClassroom
                                  : null),
                        showAttendanceActions:
                            _currentPanel == StudentPanelType.attendance,
                        isAttendanceActionLoading: _isAttendanceActionLoading,
                        onSignInTap: () => _openAttendanceActionFlow(
                          students: students,
                          actionName: 'sign_in',
                        ),
                        onSignOutTap: () => _openAttendanceActionFlow(
                          students: students,
                          actionName: 'sign_out',
                        ),
                        onTransferTap: () => _openAttendanceActionFlow(
                          students: students,
                          actionName: 'transfer',
                        ),
                        onMarkAbsentTap: () => _openAttendanceActionFlow(
                          students: students,
                          actionName: 'mark_absent',
                        ),
                        onActivityRecorded: () {
                          context.read<StudentCubit>().clearSelection();
                          setState(() {
                            _showActivitiesPanel = false;
                            _currentPanel = StudentPanelType.none;
                          });
                          _refreshAttendanceStatusForSelection();
                          context.read<StudentCubit>().refresh();
                        },
                      ),
                    ],
                  ),
                ),
              )
            : null;

        final stackChildren = <Widget>[
          CustomRefreshIndicator(
            onRefresh: () async {
              // Re-attempt previously-failed classroom-detail lookups on refresh.
              studentCubit.clearClassroomDetailCache();
              await Future.wait([
                studentCubit.refresh(),
                context.read<ClassroomCubit>().loadActiveClassrooms(
                  force: true,
                  onlyTypeClassroom: false,
                  applyAttendanceStaffScope: true,
                ),
                // Keep these in sync on refresh as well (but DO NOT call tags API).
                studentCubit.loadGuardianNameCodeMap(),
                studentCubit.loadCounts(),
                studentCubit.loadExpectedSummary(),
              ]);
              if (mounted && _selectedDemo.any((e) => e)) {
                await _refreshAttendanceStatusForSelection();
              }
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 200) {
                  studentCubit.loadNextPage();
                }
                return false;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: ResponsiveSizing.contentPadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              StudentStrings.students,
                              style: TextStyle(
                                fontFamily: Fonts.manrope,
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                                height: titleLineHeight,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          if (ModuleAccess.mayWrite(
                            context.watch<RoleCubit>(),
                            AppAccessModules.student,
                          ))
                            GradientAddButton(
                              onTap: () async {
                                final result = await context.push(
                                  AddStudentWizardScreen.routeName,
                                );
                                if (!mounted) return;
                                AppLogger.d(
                                  '[StudentScreen] received AddStudentWizard result '
                                  '(present=${result != null})',
                                );
                                if (result is Map &&
                                    (result['showPostAddPrompt'] == true)) {
                                  final studentName =
                                      (result['studentName'] as String?) ?? '';
                                  final studentCode =
                                      (result['studentCode'] as String?) ?? '';
                                  // New student added successfully → reset cache + refresh list
                                  await _refreshAllStudentApis();
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: AppColors.whiteColor,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(24),
                                          topRight: Radius.circular(24),
                                        ),
                                      ),
                                      builder: (ctx) =>
                                          PostAddStudentBottomSheet(
                                            studentName: studentName,
                                            onLater: () =>
                                                Navigator.of(ctx).pop(),
                                            onYes: () {
                                              Navigator.of(ctx).pop();
                                              if (studentCode.isNotEmpty) {
                                                _openEditStudentDetails(
                                                  studentCode,
                                                );
                                              }
                                            },
                                          ),
                                    );
                                  });
                                }
                              },
                              isTablet: ResponsiveHelper(
                                context,
                              ).isTabletCompact,
                              isLargeTablet: ResponsiveHelper(context).isWide,
                            ),
                          SizedBox(width: AppSpacing.s10),
                        ],
                      ),
                      AppSpacing.gapVMd,
                      if (!hideSummaryCards) ...[
                        // Total Students stat card
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isTablet = constraints.maxWidth >= 600;
                            final sState = context.watch<StudentCubit>().state;
                            final double active = sState.activeCount.toDouble();
                            final double upcoming = sState.upcomingCount
                                .toDouble();
                            final int totalCount = (active + upcoming).toInt();
                            final String total = '$totalCount';
                            final items = [
                              ProgressItemHelper(
                                label: 'Active (${active.toInt()})',
                                value: active,
                                color: AppColors.lightBlueProgressBar,
                                filterValue: 'Active',
                              ),
                              ProgressItemHelper(
                                label: 'Upcoming (${upcoming.toInt()})',
                                value: upcoming,
                                color: AppColors.mustardProgressBar,
                                filterValue: 'Upcoming',
                              ),
                            ];
                            return Container(
                              margin: EdgeInsets.only(
                                top: isTablet ? AppSpacing.md : AppSpacing.sm,
                                bottom: isTablet
                                    ? AppSpacing.xs
                                    : AppSpacing.xs,
                              ),
                              child: CustomStatBarCard(
                                title: StudentStrings.totalNstudents,
                                number: total,
                                items: items,
                                fullWidthBar: false,
                                onLegendTap:
                                    (String label, String? filterValue) async {
                                      final current = _currentFilters['Status'];
                                      final next = {..._currentFilters};
                                      if (current != null &&
                                          current.length == 1 &&
                                          current.first == filterValue) {
                                        next.remove('Status');
                                      } else {
                                        next['Status'] = [filterValue!];
                                      }
                                      await _applyFiltersToCubit(next);
                                    },
                              ),
                            );
                          },
                        ),
                        AppSpacing.gapVMd,
                        // Expected Students (same breakdown as Student Attendance daily summary)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isTablet = constraints.maxWidth >= 600;
                            final sState = context.watch<StudentCubit>().state;
                            final present = sState.expectedSignedIn.toDouble();
                            final absent = sState.expectedAbsent.toDouble();
                            final signedOut = sState.expectedSignedOut
                                .toDouble();
                            final notMarked = sState.expectedNotMarked
                                .toDouble();
                            final items = [
                              ProgressItemHelper(
                                label: 'Signed-In (${present.toInt()})',
                                value: present,
                                color: AppColors.lightGreenProgressBar,
                                filterValue: 'Signed-In',
                              ),
                              ProgressItemHelper(
                                label: 'Absent (${absent.toInt()})',
                                value: absent,
                                color: AppColors.redProgressBar,
                                filterValue: 'Absent',
                              ),
                              ProgressItemHelper(
                                label: 'Signed Out (${signedOut.toInt()})',
                                value: signedOut,
                                color: AppColors.lightBlueProgressBar,
                                filterValue: 'Signed Out',
                              ),
                              ProgressItemHelper(
                                label: 'Not Marked (${notMarked.toInt()})',
                                value: notMarked,
                                color: AppColors.mustardProgressBar,
                                filterValue: 'Not Marked',
                              ),
                            ];
                            return Container(
                              margin: EdgeInsets.only(
                                top: isTablet ? AppSpacing.xs : AppSpacing.xs,
                                bottom: isTablet
                                    ? AppSpacing.xs
                                    : AppSpacing.xs,
                              ),
                              child: CustomStatBarCard(
                                title: StudentStrings.expectedNstudents,
                                number: '${sState.expectedTotal}',
                                items: items,
                                fullWidthBar: false,
                                normalizeBarByItemSum: true,
                                onLegendTap: (String label, String? filterValue) {
                                  final status = label.split(' ').first;
                                  if (status == 'Signed-In' ||
                                      status == 'Absent' ||
                                      status == 'Signed' ||
                                      status == 'Not') {
                                    if (status == 'Signed') {
                                      _openStudentAttendanceWithLegendFilter(
                                        'Signed Out',
                                      );
                                    } else if (status == 'Not') {
                                      _openStudentAttendanceWithLegendFilter(
                                        'Not Marked',
                                      );
                                    } else {
                                      _openStudentAttendanceWithLegendFilter(
                                        status,
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        ),
                        AppSpacing.gapVMd,
                      ],
                      // Filter/search card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.cardBorderColor),
                          borderRadius: AppRadius.allMd,
                          color: AppColors.cardColor,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: CustomSearchBar(
                                    controller: _searchController,
                                    hintText: StudentStrings.searchStudents,
                                  ),
                                ),
                                AppSpacing.gapHXs,
                                Material(
                                  color: AppColors.transparentColor,
                                  child: InkWell(
                                    onTap: () async {
                                      final result = await context.push(
                                        StudentFilterScreen.routeName,
                                        extra: <String, dynamic>{
                                          'initialFilters': _currentFilters,
                                        },
                                      );
                                      if (!mounted) return;
                                      if (result is Map) {
                                        final normalized =
                                            <String, List<String>>{};
                                        result.forEach((key, value) {
                                          final k = key.toString();
                                          if (value is List) {
                                            normalized[k] = value
                                                .map((e) => e.toString())
                                                .toList();
                                          } else if (value != null) {
                                            normalized[k] = [value.toString()];
                                          }
                                        });

                                        await _applyFiltersToCubit(normalized);
                                      }
                                    },
                                    borderRadius: AppRadius.allPill,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(
                                            AppSpacing.xs,
                                          ),
                                          child: SvgPicture.asset(
                                            MediaRes.filterIcon,
                                            height: 20,
                                          ),
                                        ),
                                        Builder(
                                          builder: (context) {
                                            final statusList =
                                                _currentFilters['Status'] ??
                                                const <String>[];
                                            final classroomList =
                                                _currentFilters['Classroom'] ??
                                                const <String>[];
                                            final tagsList =
                                                _currentFilters['Tags'] ??
                                                const <String>[];
                                            final parentsList =
                                                _currentFilters['Parents'] ??
                                                const <String>[];
                                            final attendanceList =
                                                _currentFilters['Attendance'] ??
                                                const <String>[];

                                            final String status =
                                                statusList.isNotEmpty
                                                ? statusList.first
                                                : '';
                                            final statusUpper = status
                                                .trim()
                                                .toUpperCase();

                                            // Treat empty or ACTIVE as default (no badge contribution).
                                            final bool hasNonDefaultStatus =
                                                statusUpper.isNotEmpty &&
                                                statusUpper != 'ACTIVE';
                                            final bool hasClassroomFilter =
                                                classroomList.isNotEmpty;
                                            final bool hasTagsFilter =
                                                tagsList.isNotEmpty;
                                            final bool hasParentsFilter =
                                                parentsList.isNotEmpty;
                                            final bool hasAttendanceFilter =
                                                attendanceList.isNotEmpty;

                                            final int badgeCount =
                                                (hasNonDefaultStatus ? 1 : 0) +
                                                (hasClassroomFilter ? 1 : 0) +
                                                (hasTagsFilter ? 1 : 0) +
                                                (hasParentsFilter ? 1 : 0) +
                                                (hasAttendanceFilter ? 1 : 0);

                                            if (badgeCount == 0) {
                                              return const SizedBox.shrink();
                                            }

                                            return Positioned(
                                              right: 2,
                                              top: 2,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: AppSpacing.s5,
                                                      vertical: AppSpacing.s2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors
                                                      .attendanceDangerAccentColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        AppRadius.r10,
                                                      ),
                                                ),
                                                child: Text(
                                                  badgeCount > 99
                                                      ? '99+'
                                                      : '$badgeCount',
                                                  style: const TextStyle(
                                                    color: AppColors.whiteColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.gapVMd,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Status chip matches the staff screen: a light
                                    // lavender pill (display-only) showing the active
                                    // status filter, next to the gradient Clear All.
                                    CustomChip(
                                      label: _statusChipLabel(),
                                      labelStyle: const TextStyle(
                                        color: AppColors.secondaryColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      color: AppColors.staffBadgeActiveBg,
                                    ),
                                    AppSpacing.gapHXs,
                                    CustomClearAllChip(
                                      onTap: () => _clearAllFilters(),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      StudentStrings.showInactive,
                                      style: TextStyle(
                                        fontFamily: Fonts.manrope,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                    AppSpacing.gapHXs,
                                    CustomToggle(
                                      label: '',
                                      isToggled: _showInactive,
                                      onToggle: (v) async {
                                        await _applyFiltersToCubit({
                                          ..._currentFilters,
                                          'Status': [v ? 'Inactive' : 'Active'],
                                        }, showInactive: v);

                                        if (!mounted) return;
                                        final err = context
                                            .read<StudentCubit>()
                                            .state
                                            .errorMessage;
                                        if (err != null && err.isNotEmpty) {
                                          CoreUtils.logApiError(err);
                                        } else {
                                          CoreUtils.showTopSnackBar(
                                            context: context,
                                            message: v
                                                ? StudentStrings
                                                      .showingInactiveStudents
                                                : StudentStrings
                                                      .showingActiveStudents,
                                            isSuccess: true,
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapVSm,
                      // Select All
                      Align(
                        alignment: Alignment.centerLeft,
                        child: CustomCheckbox(
                          label: StudentStrings.selectAll,
                          value: _selectAll,
                          onChanged: (v) {
                            final newVal = v ?? false;
                            context.read<StudentCubit>().setSelectAll(newVal);
                            _refreshAttendanceStatusForSelection();
                          },
                        ),
                      ),
                      AppSpacing.gapVMd,
                      // Student list from API
                      if (state.isLoading && students.isEmpty)
                        const StudentListShimmer()
                      else if (state.errorMessage != null && students.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Center(
                            child: Column(
                              children: [
                                Text(
                                  StudentStrings.errorLoadingStudents,
                                  style: TextStyle(color: AppColors.errorColor),
                                ),
                                AppSpacing.gapVXs,
                                ElevatedButton(
                                  onPressed: () =>
                                      context.read<StudentCubit>().refresh(),
                                  child: Text(StudentStrings.retry),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (students.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Center(
                            child: Text(studentListEmptyMessage(state)),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final student = students[index];
                            final studentMap = _studentToMap(
                              student,
                              classroomNameByCode: mergedClassroomNames,
                            );
                            final isActive =
                                (student.status).toUpperCase() == 'ACTIVE';
                            final studentCode = studentMap['code'] as String;
                            final isHighlightTarget = _isHighlightTarget(
                              studentCode,
                            );

                            return Column(
                              children: [
                                HighlightableCard(
                                  key: isHighlightTarget
                                      ? _highlightCardKey
                                      : null,
                                  code: studentCode,
                                  highlightCode: _highlightStudentCode,
                                  borderRadius: 12,
                                  onHighlighted: () {
                                    final ctx =
                                        _highlightCardKey.currentContext;
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
                                  child: StudentCard(
                                    initiallyExpanded: isHighlightTarget,
                                    studentCode: studentCode,
                                    name: studentMap['name'] as String,
                                    profileImage:
                                        studentMap['profileImage'] as String?,
                                    profilePhotoAssetCode:
                                        studentMap['profilePhotoAssetCode']
                                            as String?,
                                    classroom:
                                        studentMap['Classroom'] as String,
                                    tags: studentMap['Tags'] as List<String>,
                                    sibling:
                                        studentMap['sibling']
                                            as StudentSiblingInfo,
                                    schedule:
                                        studentMap['schedule'] as List<String>,
                                    scheduleByDay:
                                        studentMap['scheduleByDay']
                                            as Map<String, String>? ??
                                        const <String, String>{},
                                    birthDate:
                                        studentMap['birthDate'] as String,
                                    movementDate:
                                        studentMap['movementDate'] as String,
                                    status: studentMap['Status'] as String,
                                    isActive: isActive,
                                    isSelected: index < _selectedDemo.length
                                        ? _selectedDemo[index]
                                        : false,
                                    onSelected: (v) {
                                      context
                                          .read<StudentCubit>()
                                          .setRowSelected(index, v ?? false);
                                      // Panel state is local UI (H) — collapse it
                                      // when nothing is selected. _selectAll is
                                      // derived, so no assignment is needed.
                                      if (!context
                                          .read<StudentCubit>()
                                          .state
                                          .selection
                                          .any((e) => e)) {
                                        setState(() {
                                          _currentPanel = StudentPanelType.none;
                                          _showActivitiesPanel = false;
                                        });
                                      }
                                      _refreshAttendanceStatusForSelection();
                                    },
                                    onEdit: () =>
                                        _openEditStudentDetails(student.code),
                                    onPrimaryAction: () async {
                                      try {
                                        final message = isActive
                                            ? await studentCubit
                                                  .deactivateStudent(
                                                    student.code,
                                                  )
                                            : await studentCubit
                                                  .reactivateStudent(
                                                    student.code,
                                                  );
                                        if (!mounted) return;
                                        CoreUtils.showTopSnackBar(
                                          context: context,
                                          message: message,
                                          isSuccess: true,
                                        );
                                        await _refreshAllStudentApis();
                                        Navigator.of(context).maybePop();
                                      } catch (e) {
                                        if (!mounted) return;
                                        final msg =
                                            ApiErrorHandler.extractErrorMessage(
                                              e,
                                            );
                                        CoreUtils.showTopSnackBar(
                                          context: context,
                                          message: msg,
                                          isError: true,
                                        );
                                      }
                                    },
                                    onDeleteAction: () async {
                                      try {
                                        final message = await studentCubit
                                            .deleteStudent(student.code);
                                        if (!mounted) return;
                                        CoreUtils.showTopSnackBar(
                                          context: context,
                                          message: message,
                                          isSuccess: true,
                                        );
                                        await _refreshAllStudentApis();
                                        Navigator.of(context).maybePop();
                                      } catch (e) {
                                        if (!mounted) return;
                                        final msg =
                                            ApiErrorHandler.extractErrorMessage(
                                              e,
                                            );
                                        CoreUtils.showTopSnackBar(
                                          context: context,
                                          message: msg,
                                          isError: true,
                                        );
                                      }
                                    },
                                  ),
                                ),
                                if (index != students.length - 1)
                                  const SizedBox(height: AppSpacing.s10),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ];

        if (actionPanel != null) {
          stackChildren.add(actionPanel);
        }

        return GlobalScaffold(
          body: Stack(children: stackChildren),
          showCustomNavigationBar: true,
        );
      },
    );
  }
}
