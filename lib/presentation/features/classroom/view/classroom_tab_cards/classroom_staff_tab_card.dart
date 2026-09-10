import 'dart:async';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/utils/app_time.dart';

import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/filter_icon_button.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/highlightable_card.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/classroom/view/filters/classroom_staff_filter_screen.dart';
import 'package:wowcare/presentation/features/classroom/view/filters/designation_display_utils.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_action_panel.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_attendance_action_availability.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/domain/features/staff_classroom/entities/staff_classroom_item.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_sign_in_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_sign_out_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_transfer_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_absent_form_list_usecase.dart';
import 'package:wowcare/presentation/features/classroom/view_model/classroom_staff_cubit.dart';
import 'package:wowcare/presentation/features/classroom/view_model/classroom_staff_state.dart';
import 'package:wowcare/presentation/features/classroom/view_model/classroom_cubit.dart';
import 'package:wowcare/presentation/features/attendance/model/staff_entity.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_forms/staff_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_forms/staff_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_forms/staff_transfer_form.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_forms/staff_mark_absent_form.dart';
import 'package:wowcare/presentation/features/staff/view/staff_profile_screen.dart';
import 'package:wowcare/presentation/features/communication/bulk_messaging/utils/messaging_shortcut.dart';
import 'package:wowcare/core/utils/staff_code_resolver.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';

/// Bumped by any screen/flow that mutates the classroom staff roster (e.g. the
/// "Assign Staff to Classroom" sheet). The Staff-tab card listens and
/// invalidates its cubit + attendance cache so the newly assigned staff is
/// visible immediately, without the user having to switch tabs to force a
/// rebuild.
final ValueNotifier<int> classroomStaffRefreshTick = ValueNotifier<int>(0);

void notifyClassroomStaffChanged() {
  classroomStaffRefreshTick.value++;
}

class Staff {
  const Staff({
    required this.staffCode,
    this.userCode = '',
    required this.name,
    required this.designation,
    required this.email,
    this.photoUuid = '',
    this.isExpectedToday = false,
    this.isSignedIn = false,
    this.isAbsent = false,
    this.profileStatus = 'A',
  });

  final String staffCode;
  final String userCode;
  final String name;
  final String designation;
  final String email;
  final String photoUuid;
  final bool isExpectedToday;
  final bool isSignedIn;
  final bool isAbsent;

  /// UI uses legacy values: 'A' | 'Upcoming'
  final String profileStatus;
}

class ClassroomStaffTabCard extends StatelessWidget {
  const ClassroomStaffTabCard({
    required this.scrollController,
    required this.selectedRoom,
    this.highlightCode,
    super.key,
  });

  final ScrollController scrollController;
  final Classroom? selectedRoom;

  /// Staff code from a notification deep-link; the matching row is scrolled
  /// into view and briefly flashed.
  final String? highlightCode;

  static const routeName = '/classroom-staff-screen';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ClassroomStaffCubit>(
      create: (_) => serviceLocator<ClassroomStaffCubit>(),
      child: _ClassroomStaffTabCardView(
        scrollController: scrollController,
        selectedRoom: selectedRoom,
        highlightCode: highlightCode,
      ),
    );
  }
}

class _ClassroomStaffTabCardView extends StatefulWidget {
  const _ClassroomStaffTabCardView({
    required this.scrollController,
    required this.selectedRoom,
    this.highlightCode,
  });

  final ScrollController scrollController;
  final Classroom? selectedRoom;
  final String? highlightCode;

  @override
  State<_ClassroomStaffTabCardView> createState() =>
      _ClassroomStaffTabCardViewState();
}

class _ClassroomStaffTabCardViewState
    extends State<_ClassroomStaffTabCardView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  /// Notification deep-link target row.
  final GlobalKey _highlightRowKey = GlobalKey();
  bool _isHighlightTarget(String code) {
    final target = (widget.highlightCode ?? '').trim();
    return target.isNotEmpty &&
        target.toUpperCase() == code.trim().toUpperCase();
  }

  late final ClassroomStaffCubit _cubit;
  bool isSelectAllChecked = false;
  Map<String, bool> staffSelections = {};
  List<String> _selectedDesignation = [];
  List<Staff> _filteredStaff = [];
  List<Staff> _allStaff = [];
  // ACTIVE is the default status — always sent unless the user picks others.
  List<String> _selectedStatusList = ['ACTIVE'];
  List<String> _selectedAttendanceStatusList = [];
  StaffPanelType _currentPanel = StaffPanelType.none;

  final List<String> designations = const [
    'Director',
    'Assistant Director',
    'Admin',
    'Lead Teacher',
    'Associate Teacher',
    'Assistant Teacher',
    'Owner',
    'Floater',
  ];

  void _loadForSelectedRoom({required bool refresh}) {
    final primaryClassroomCode = widget.selectedRoom?.code ?? '';
    if (primaryClassroomCode.trim().isEmpty) return;

    final search = _searchController.text.trim().isEmpty
        ? null
        : _searchController.text.trim();

    final designation = _selectedDesignation.isEmpty
        ? null
        : List<String>.from(_selectedDesignation);
    final status = _selectedStatusList.isEmpty
        ? null
        : List<String>.from(_selectedStatusList);

    if (refresh) {
      _cubit.refresh(
        classroomCode: primaryClassroomCode,
        search: search,
        status: status,
        designation: designation,
      );
    } else {
      _cubit.loadInitial(
        classroomCode: primaryClassroomCode,
        search: search,
        status: status,
        designation: designation,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _cubit = context.read<ClassroomStaffCubit>();
    _searchController.addListener(_onSearchChanged);
    _loadForSelectedRoom(refresh: false);
    classroomStaffRefreshTick.addListener(_handleExternalRefresh);
    _loadOwnStaffCodeIfStaff();
  }

  /// Logged-in user's own staffCode (resolved lazily, staff persona only) —
  /// used by [_openStaffProfile] to tell "my own card" apart from a
  /// colleague's.
  String? _ownStaffCode;

  Future<void> _loadOwnStaffCodeIfStaff() async {
    try {
      final code = await resolveStaffCodeForLoggedInUser();
      if (!mounted) return;
      setState(() => _ownStaffCode = code);
    } catch (_) {
      // Best-effort — falls back to treating every card as "not mine",
      // i.e. a staff persona gets routed to messaging even on their own
      // card if this fails, which is safe (never over-grants edit access).
    }
  }

  void _handleExternalRefresh() {
    if (!mounted) return;
    // Staff roster changed elsewhere (assign sheet, etc.) — drop today's
    // attendance status cache for this room so the new staff shows up with
    // fresh status, then refetch the staff list bypassing the repo cache.
    _cubit.invalidateAttendanceStatus();
    _loadForSelectedRoom(refresh: true);
  }

  @override
  void didUpdateWidget(_ClassroomStaffTabCardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRoom != widget.selectedRoom) {
      setState(() {
        isSelectAllChecked = false;
        staffSelections.clear();
        _searchController.clear();
        _selectedDesignation = [];
        _filteredStaff = [];
        _allStaff = [];
        _selectedStatusList = ['ACTIVE'];
        _selectedAttendanceStatusList = [];
      });
      _loadForSelectedRoom(refresh: false);
    }
  }

  void dispose() {
    _searchDebounce?.cancel();
    classroomStaffRefreshTick.removeListener(_handleExternalRefresh);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    // No manual _cubit.close() — the ancestor BlocProvider in
    // ClassroomStaffTabCard now owns the cubit's lifecycle and closes it
    // when that provider itself leaves the tree.
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce so the list filters once the user pauses typing, instead of
    // rebuilding on every keystroke.
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _filterStaff();
      });
    });
  }

  Staff _mapApiToUi(StaffClassroomItem item) {
    final statusUpper = item.status.trim().toUpperCase();
    final profileStatus = statusUpper == 'UPCOMING' ? 'Upcoming' : 'A';
    return Staff(
      staffCode: item.staffCode,
      userCode: item.userCode,
      name: item.fullName,
      designation: item.designation,
      email: '',
      photoUuid: item.profilePictureUrl ?? '',
      isExpectedToday: item.expectedToday,
      isSignedIn: item.signedIn,
      isAbsent: item.absent,
      profileStatus: profileStatus,
    );
  }

  List<Staff> _filterStaff() {
    final allStaff = _allStaff;
    final filtered = allStaff.where((staff) {
      bool matchesSearch = true;
      bool matchesDesignation = true;
      bool matchesStatus = true;
      bool matchesAttendanceStatus = true;
      final designationRaw = staff.designation.trim();
      final isNotKiosk = designationRaw.toUpperCase() != 'KIOSK';

      if (_searchController.text.isNotEmpty) {
        matchesSearch = staff.name.toLowerCase().contains(
          _searchController.text.toLowerCase(),
        );
      }

      if (_selectedDesignation.isNotEmpty) {
        final des = staff.designation.trim().toUpperCase();
        matchesDesignation = _selectedDesignation.any(
          (d) => d.trim().toUpperCase() == des,
        );
      }

      // Apply status filter (API: ACTIVE / UPCOMING)
      if (_selectedStatusList.isNotEmpty) {
        matchesStatus = _selectedStatusList.any((sel) {
          final u = sel.trim().toUpperCase();
          if (u == 'ACTIVE') return staff.profileStatus == 'A';
          if (u == 'UPCOMING') return staff.profileStatus == 'Upcoming';
          return false;
        });
      }

      // Apply attendance status filter (Expected/Present/Absent)
      if (_selectedAttendanceStatusList.isNotEmpty) {
        matchesAttendanceStatus =
            (_selectedAttendanceStatusList.contains('Expected') &&
                staff.isExpectedToday) ||
            (_selectedAttendanceStatusList.contains('Present') &&
                staff.isSignedIn) ||
            (_selectedAttendanceStatusList.contains('Absent') &&
                staff.isAbsent);
      }

      return matchesSearch &&
          matchesDesignation &&
          matchesStatus &&
          matchesAttendanceStatus &&
          isNotKiosk;
    }).toList();
    _filteredStaff = filtered;
    return filtered;
  }

  void _initializeStaffSelections(List<Staff> staff) {
    for (var member in staff) {
      if (!staffSelections.containsKey(member.staffCode)) {
        staffSelections[member.staffCode] = false;
      }
    }
  }

  void _toggleStaffSelection(String staffCode, bool? value) {
    if (value == null) return;

    setState(() {
      staffSelections[staffCode] = value;
      final List<Staff> visibleStaff = _getVisibleStaff();
      isSelectAllChecked = visibleStaff.every(
        (staff) => staffSelections[staff.staffCode] == true,
      );
    });
    _cubit.refreshAttendanceStatusForSelection(
      _getSelectedStaffCodes().toList(),
    );
  }

  List<Staff> _getVisibleStaff() {
    final List<Staff> base;
    if (_filteredStaff.isEmpty &&
        _searchController.text.isEmpty &&
        _selectedDesignation.isEmpty) {
      base = _allStaff.where((staff) => staff.designation != 'Kiosk').toList();
    } else {
      base = _filteredStaff;
    }
    return _floatHighlightTargetToTop(base);
  }

  /// When opened from an assign-to-classroom notification, the deep-linked
  /// staff must flash + scroll into view. The list is sorted by name, so the
  /// target can land far down the lazy [ListView.builder] and never get built —
  /// its [HighlightableCard] then never mounts, so no flash fires. Floating the
  /// target to the top guarantees the row renders, is visible, and highlights.
  List<Staff> _floatHighlightTargetToTop(List<Staff> staff) {
    final target = (widget.highlightCode ?? '').trim().toUpperCase();
    if (target.isEmpty) return staff;
    final idx = staff.indexWhere(
      (s) => s.staffCode.trim().toUpperCase() == target,
    );
    if (idx <= 0) return staff;
    final reordered = List<Staff>.of(staff);
    reordered.insert(0, reordered.removeAt(idx));
    return reordered;
  }

  Set<String> _getSelectedStaffCodes() {
    return staffSelections.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toSet();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Staff codes for the currently visible (post-filter) roster — passed to
  /// [ClassroomStaffCubit.refreshAttendanceStatusForVisible].
  List<String> _visibleStaffCodes() {
    return _getVisibleStaff()
        .map((s) => s.staffCode.trim())
        .where((c) => c.isNotEmpty)
        .toList();
  }

  /// Pull-to-refresh: re-run every API this tab uses (staff roster + today's
  /// attendance status), bypassing the repository and attendance caches.
  Future<void> _refreshAll() async {
    if (!mounted) return;
    // Drop attendance caches/guards so the status is fetched fresh.
    _cubit.invalidateAttendanceStatus();
    // Refresh the shared classroom dropdown list too, so a pull refreshes the
    // whole page's data — not just this tab.
    await _reloadClassroomList();
    // Reload the staff roster (bypasses the repository cache).
    _loadForSelectedRoom(refresh: true);
    // Re-fetch today's attendance status.
    await _cubit.refreshAttendanceStatusForVisible(_visibleStaffCodes());
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

  void _dismissSelectionPanel() {
    if (!mounted) return;
    setState(() {
      isSelectAllChecked = false;
      staffSelections.updateAll((key, val) => false);
      _currentPanel = StaffPanelType.none;
    });
  }

  void _refreshAfterAttendanceAction() {
    _dismissSelectionPanel();
    _cubit.invalidateAttendanceStatus();
    _loadForSelectedRoom(refresh: true);
    _cubit.refreshAttendanceStatusForVisible(_visibleStaffCodes());
  }

  StaffAttendanceActionAvailability _attendanceAvailabilityForSelection() {
    final codes = _getSelectedStaffCodes();
    if (codes.isEmpty) {
      return StaffAttendanceActionAvailability.allDisabled;
    }
    if (_cubit.state.attendanceStatusLoading ||
        _cubit.state.attendanceStatusError) {
      return StaffAttendanceActionAvailability.allDisabled;
    }

    final gates = <StaffAttendanceGate>[];
    for (final code in codes) {
      Staff? found;
      for (final s in _allStaff) {
        if (s.staffCode == code) {
          found = s;
          break;
        }
      }
      if (found == null) {
        return StaffAttendanceActionAvailability.allDisabled;
      }
      final isActive = found.profileStatus == 'A';
      gates.add(
        staffAttendanceGateFromTodayStatus(
          isActiveProfile: isActive,
          todayStatusRaw: _cubit.state.attendanceStatusByStaffCode[code],
          // Admin-only override: lets an admin sign in a staff member who
          // was marked absent for the day, clearing that absence record.
          allowAbsentSignInOverride: context.read<RoleCubit>().isTrueAdmin,
        ),
      );
    }
    return StaffAttendanceActionAvailability.fromGates(gates);
  }

  Future<void> _openAttendanceActionFlow(String actionName) async {
    final selectedCodes = _getSelectedStaffCodes()
        .where((c) => c.trim().isNotEmpty)
        .toSet();
    if (selectedCodes.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Select at least one staff',
        isError: true,
      );
      return;
    }

    final date = _formatDate(AppTime.now());
    final roomCode = (widget.selectedRoom?.code ?? '').trim();
    final classroomCodes = roomCode.isEmpty ? null : <String>[roomCode];
    try {
      StaffEntity? target;
      if (actionName == 'sign_in') {
        final useCase = serviceLocator<GetStaffSignInFormListUseCase>();
        final page = await useCase(
          fromAttendanceDate: date,
          toAttendanceDate: date,
          classroomCodes: classroomCodes,
          page: 0,
          size: 500,
        );
        final eligible = page.items
            .where((item) => selectedCodes.contains(item.staffCode))
            .toList();
        if (eligible.isNotEmpty) {
          final item = eligible.first;
          target = StaffEntity(
            id: 1,
            name: item.staffName,
            primaryRoomId: 0,
            classroomCode: item.classroomCode,
            designation: item.designation.isNotEmpty
                ? item.designation.first
                : 'Staff',
            staffCode: item.staffCode,
            isExpectedToday: item.isExpectedToday,
          );
        }
      } else if (actionName == 'sign_out') {
        final useCase = serviceLocator<GetStaffSignOutFormListUseCase>();
        final page = await useCase(
          fromAttendanceDate: date,
          toAttendanceDate: date,
          classroomCodes: classroomCodes,
          page: 0,
          size: 500,
        );
        final eligible = page.items
            .where((item) => selectedCodes.contains(item.staffCode))
            .toList();
        if (eligible.isNotEmpty) {
          final item = eligible.first;
          target = StaffEntity(
            id: 1,
            name: item.staffName,
            primaryRoomId: 0,
            designation: item.designation.isNotEmpty
                ? item.designation.first
                : 'Staff',
            staffCode: item.staffCode,
          );
        }
      } else if (actionName == 'transfer') {
        final useCase = serviceLocator<GetStaffTransferFormListUseCase>();
        final page = await useCase(
          fromAbsenceDate: date,
          toAbsenceDate: date,
          classroomCodes: classroomCodes,
          page: 0,
          size: 500,
        );
        final eligible = page.items
            .where((item) => selectedCodes.contains(item.staffCode))
            .toList();
        if (eligible.isNotEmpty) {
          final item = eligible.first;
          target = StaffEntity(
            id: 1,
            name: item.staffName,
            primaryRoomId: 0,
            designation: item.designation.isNotEmpty
                ? item.designation.first
                : 'Staff',
            staffCode: item.staffCode,
          );
        }
      } else {
        final useCase = serviceLocator<GetStaffAbsentFormListUseCase>();
        final page = await useCase(
          fromAbsenceDate: date,
          toAbsenceDate: date,
          classroomCodes: classroomCodes,
          page: 0,
          size: 500,
        );
        final eligible = page.items
            .where((item) => selectedCodes.contains(item.staffCode))
            .toList();
        if (eligible.isNotEmpty) {
          final item = eligible.first;
          target = StaffEntity(
            id: 1,
            name: item.staffName,
            primaryRoomId: 0,
            designation: 'Staff',
            staffCode: item.staffCode,
          );
        }
      }

      if (!mounted) return;
      if (target == null) {
        throw Exception('No selected staff is eligible for this action');
      }

      if (actionName == 'sign_in') {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StaffSignInForm(staff: target)),
        );
      } else if (actionName == 'sign_out') {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StaffSignOutForm(staff: target)),
        );
      } else if (actionName == 'transfer') {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StaffTransferForm(staff: target)),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StaffMarkAbsentForm(staff: target)),
        );
      }
      if (!mounted) return;
      _refreshAfterAttendanceAction();
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    }
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
        onPressed: _openFilterScreen,
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

  void _clearAllSelections() {
    setState(() {
      isSelectAllChecked = false;
      staffSelections.updateAll((key, val) => false);
      _searchController.clear();
      _selectedDesignation = [];
      _selectedStatusList = ['ACTIVE'];
      _selectedAttendanceStatusList = [];
    });
    _loadForSelectedRoom(refresh: false);
  }

  String _employmentStatusForProfile(Staff staff) {
    if (staff.profileStatus == 'Upcoming') return 'UPCOMING';
    return 'ACTIVE';
  }

  /// A plain staff persona tapping a colleague's card here opens a message
  /// instead of that colleague's profile. Their own card has no destination
  /// from the classroom roster: staff must not message themselves or open a
  /// duplicate profile from this context.
  Future<void> _openStaffProfile(Staff staff) async {
    if (staff.staffCode.trim().isEmpty) return;

    final role = context.read<RoleCubit>();
    final own = (_ownStaffCode ?? '').trim();
    final isOwnCard = own.isNotEmpty && own == staff.staffCode.trim();

    if (role.isStaff && own.isEmpty) return;
    if (role.isStaff && isOwnCard) return;

    if (role.isStaff && !isOwnCard) {
      openMessagingShortcut(
        context,
        recipients: [
          SelectedRecipient(
            code: staff.staffCode,
            name: staff.name,
            isStaff: true,
            userCode: staff.userCode,
            avatar: staff.photoUuid,
            designation: staff.designation,
          ),
        ],
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaffProfileScreen(
          staffCode: staff.staffCode.trim(),
          userCode: staff.userCode,
          name: staff.name,
          classroom: widget.selectedRoom?.name ?? '',
          designation: staff.designation,
          phoneNumber: '',
          employmentStatus: _employmentStatusForProfile(staff),
        ),
      ),
    );
    if (!mounted) return;
    _handleExternalRefresh();
  }

  /// Whether the filter funnel has anything applied beyond the ACTIVE
  /// default, so the funnel icon can surface a red dot for it.
  bool get _isStaffFilterActive {
    final statusSet = _selectedStatusList
        .map((e) => e.trim().toUpperCase())
        .toSet();
    final isDefaultStatus =
        statusSet.length == 1 && statusSet.first == 'ACTIVE';
    return !isDefaultStatus || _selectedDesignation.isNotEmpty;
  }

  Future<void> _openFilterScreen() async {
    final result = await Navigator.push<ClassroomStaffFilterResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ClassroomStaffFilterScreen(
          initialStatus: _selectedStatusList,
          initialDesignation: _selectedDesignation,
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      // Respect the explicit filter-screen choice exactly. Only fall back to
      // the ACTIVE default when nothing is selected.
      final picked = result.status
          .map((e) => e.trim().toUpperCase())
          .where((e) => e.isNotEmpty)
          .toList();
      _selectedStatusList = picked.isEmpty ? ['ACTIVE'] : picked;
      _selectedDesignation = List<String>.from(result.designation);
    });
    _loadForSelectedRoom(refresh: false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClassroomStaffCubit, ClassroomStaffState>(
      // Only the roster itself re-maps into local UI state; an
      // attendance-status-only update (which also changes `state`) must
      // not re-trigger the roster mapping + another attendance refetch.
      listenWhen: (previous, current) => previous.staff != current.staff,
      listener: (context, state) {
        final raw = state.staff.map(_mapApiToUi).toList();
        // De-duplicate by staffCode to avoid repeated cards.
        final byCode = <String, Staff>{};
        for (final s in raw) {
          final code = s.staffCode.trim();
          if (code.isEmpty) continue;
          byCode[code] = s;
        }
        final apiItems = byCode.values.toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        setState(() {
          _allStaff = apiItems;
          _filterStaff();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _cubit.refreshAttendanceStatusForVisible(_visibleStaffCodes());
        });
      },
      builder: (context, state) => Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Card(
                  elevation: 0,
                  margin: const EdgeInsets.all(0),
                  shape: const Border(
                    left: BorderSide(color: AppColors.themeColor),
                    top: BorderSide(color: AppColors.themeColor),
                    right: BorderSide(color: AppColors.themeColor),
                    bottom: BorderSide(color: AppColors.themeColor),
                  ),
                  color: AppColors.cardColor,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: SearchBar(
                                    controller: _searchController,
                                    constraints: const BoxConstraints(
                                      minHeight: 36,
                                    ),
                                    backgroundColor:
                                        const WidgetStatePropertyAll<Color>(
                                          AppColors.cardColor,
                                        ),
                                    surfaceTintColor:
                                        const WidgetStatePropertyAll<Color>(
                                          AppColors.cardColor,
                                        ),
                                    hintText: 'Search',
                                    hintStyle: WidgetStatePropertyAll(
                                      TextStyle(
                                        fontFamily: AppFonts.body,
                                        color: AppColors
                                            .classroomSearchHintTextColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                    leading: const Icon(
                                      Icons.search,
                                      color: AppColors.primaryColor,
                                      size: 18,
                                    ),
                                    elevation: const WidgetStatePropertyAll(0),
                                    side: const WidgetStatePropertyAll(
                                      BorderSide(
                                        width: 1,
                                        color: AppColors.classroomBorderColor,
                                      ),
                                    ),
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilterIconButton(
                                  iconAsset: MediaRes.filterIcon,
                                  isActive: _isStaffFilterActive,
                                  onPressed: _openFilterScreen,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                for (final status in _selectedStatusList) ...[
                                  _buildStatusChip(status),
                                  const SizedBox(width: 8),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    gradient: AppColors.buildPrimaryGradient(),
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
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ScrollbarTheme(
                          data: ScrollbarThemeData(
                            thumbColor: WidgetStateProperty.all(
                              AppColors.classroomScrollbarThumbColor,
                            ),
                            radius: const Radius.circular(20),
                          ),
                          child: Scrollbar(
                            controller: widget.scrollController,
                            child: BlocBuilder<ClassroomStaffCubit, ClassroomStaffState>(
                              builder: (context, state) {
                                final visible = _getVisibleStaff();
                                if (state.isLoading && visible.isEmpty) {
                                  return const ClassroomStaffListShimmer();
                                }
                                return CustomRefreshIndicator(
                                  onRefresh: _refreshAll,
                                  child: visible.isEmpty
                                      ? LayoutBuilder(
                                          builder: (context, constraints) {
                                            return ListView(
                                              physics:
                                                  const AlwaysScrollableScrollPhysics(),
                                              children: [
                                                SizedBox(
                                                  height: constraints.maxHeight,
                                                  child: Center(
                                                    child: Text(
                                                      'No staff assigned.',
                                                      style: TextStyle(
                                                        fontFamily: AppFonts.body,
                                                        fontSize: 16,
                                                        color: AppColors
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.6,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        )
                                      : ListView.builder(
                                          // Always scrollable so a short roster
                                          // (too few staff to fill the viewport)
                                          // can still be pulled to refresh.
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          padding: const EdgeInsets.only(
                                            left: 16,
                                            right: 16,
                                          ),
                                          itemCount: visible.length,
                                          itemBuilder: (context, index) {
                                            final staff = visible[index];
                                            _initializeStaffSelections(visible);
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                                  _cubit
                                                      .refreshAttendanceStatusForVisible(
                                                        _visibleStaffCodes(),
                                                      );
                                                });
                                            final isTarget = _isHighlightTarget(
                                              staff.staffCode,
                                            );
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8.0,
                                              ),
                                              child: HighlightableCard(
                                                key: isTarget
                                                    ? _highlightRowKey
                                                    : null,
                                                code: staff.staffCode,
                                                highlightCode:
                                                    widget.highlightCode,
                                                borderRadius: 12,
                                                onHighlighted: () {
                                                  final ctx = _highlightRowKey
                                                      .currentContext;
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
                                                child: _StaffListItem(
                                                  staff: staff,
                                                  showMessageIcon:
                                                      (_ownStaffCode ?? '')
                                                          .trim()
                                                          .isNotEmpty &&
                                                      (_ownStaffCode ?? '')
                                                              .trim() !=
                                                          staff.staffCode
                                                              .trim(),
                                                  isSelected:
                                                      staffSelections[staff
                                                          .staffCode] ??
                                                      false,
                                                  todayAttendanceStatusRaw:
                                                      state
                                                          .attendanceStatusByStaffCode[staff
                                                          .staffCode],
                                                  designationLabel:
                                                      formatDesignationForDisplay(
                                                        staff.designation,
                                                      ),
                                                  onNameTap: () =>
                                                      _openStaffProfile(staff),
                                                  onSelectionChanged:
                                                      (bool? value) {
                                                        _toggleStaffSelection(
                                                          staff.staffCode,
                                                          value,
                                                        );
                                                      },
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_getSelectedStaffCodes().isNotEmpty)
            Positioned(
              right: 16,
              bottom: 16,
              child: StaffActionPanel(
                currentPanel: _currentPanel,
                attendanceAvailability: _attendanceAvailabilityForSelection(),
                onAttendanceTap: () {
                  setState(() {
                    _currentPanel = _currentPanel == StaffPanelType.attendance
                        ? StaffPanelType.none
                        : StaffPanelType.attendance;
                  });
                },
                onActivitiesTap: () {
                  setState(() {
                    _currentPanel = _currentPanel == StaffPanelType.activities
                        ? StaffPanelType.none
                        : StaffPanelType.activities;
                  });
                },
                onMessageTap: () {
                  final codes = _getSelectedStaffCodes();
                  final selected = <SelectedRecipient>[];
                  for (final code in codes) {
                    final staff = _allStaff.firstWhere(
                      (s) => s.staffCode == code,
                      orElse: () =>
                          _filteredStaff.firstWhere((s) => s.staffCode == code),
                    );
                    selected.add(
                      SelectedRecipient(
                        code: staff.staffCode,
                        name: staff.name,
                        isStaff: true,
                        userCode: staff.userCode,
                        avatar: staff.photoUuid,
                        designation: staff.designation,
                      ),
                    );
                  }
                  openMessagingShortcut(context, recipients: selected);
                },
                showMessage:
                    (_ownStaffCode ?? '').trim().isNotEmpty &&
                    !_getSelectedStaffCodes().contains(
                      (_ownStaffCode ?? '').trim(),
                    ),
                onProfileTap: _getSelectedStaffCodes().length == 1
                    ? () {
                        final code = _getSelectedStaffCodes().first;
                        final staff = _allStaff.firstWhere(
                          (s) => s.staffCode == code,
                          orElse: () => _filteredStaff.firstWhere(
                            (s) => s.staffCode == code,
                          ),
                        );
                        _openStaffProfile(staff);
                      }
                    : null,
                onSignIn: () => _openAttendanceActionFlow('sign_in'),
                onSignOut: () => _openAttendanceActionFlow('sign_out'),
                onTransfer: () => _openAttendanceActionFlow('transfer'),
                onAbsent: () => _openAttendanceActionFlow('mark_absent'),
                onClearSelections: () {
                  setState(() {
                    isSelectAllChecked = false;
                    staffSelections.updateAll((key, val) => false);
                    _currentPanel = StaffPanelType.none;
                  });
                },
                isProfileEnabled:
                    (!context.read<RoleCubit>().isStaff ||
                        (_ownStaffCode ?? '').trim().isNotEmpty) &&
                    _getSelectedStaffCodes().length == 1 &&
                    _getSelectedStaffCodes().single !=
                        (_ownStaffCode ?? '').trim(),
                activitiesEnabled: _getSelectedStaffCodes().isNotEmpty,
              ),
            ),
        ],
      ),
    );
  }
}

class _StaffListItem extends StatelessWidget {
  const _StaffListItem({
    required this.staff,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.showMessageIcon,
    this.todayAttendanceStatusRaw,
    required this.designationLabel,
    this.onNameTap,
  });

  final Staff staff;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
  final bool showMessageIcon;
  final String? todayAttendanceStatusRaw;
  final String designationLabel;
  final VoidCallback? onNameTap;

  @override
  Widget build(BuildContext context) {
    final normalizedAttendance = (todayAttendanceStatusRaw ?? '')
        .trim()
        .toUpperCase();
    final hasAttendanceStatus =
        normalizedAttendance == 'SIGNED_IN' || normalizedAttendance == 'ABSENT';
    final shouldGreyOut =
        !staff.isExpectedToday &&
        !staff.isSignedIn &&
        !staff.isAbsent &&
        !hasAttendanceStatus;
    final Color? attendanceDotColor = normalizedAttendance == 'SIGNED_IN'
        ? AppColors.classroomPositiveStatusColor
        : (normalizedAttendance == 'ABSENT'
              ? AppColors.classroomNegativeStatusColor
              : null);
    final String? attendanceTooltip = normalizedAttendance == 'SIGNED_IN'
        ? 'Staff is signed in'
        : (normalizedAttendance == 'ABSENT' ? 'Staff is absent' : null);

    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 10, left: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.classroomRowBorderColor),
        borderRadius: BorderRadius.circular(12),
        color: shouldGreyOut
            ? AppColors.classroomRowGreyedBackgroundColor
            : null,
      ),
      child: Row(
        children: [
          Opacity(
            opacity: shouldGreyOut ? 0.5 : 1,
            child: AbsorbPointer(
              absorbing: shouldGreyOut,
              // Staff row is intentionally not tappable — the profile photo
              // must not select the staff or open the action panel.
              child: DocumentImageWidget(
                fileUuid: staff.staffCode.trim().isNotEmpty
                    ? staff.staffCode
                    : staff.name,
                imageUrl: (() {
                  final raw = staff.photoUuid.trim();
                  final looksLikeUrl =
                      raw.startsWith('http://') || raw.startsWith('https://');
                  return looksLikeUrl ? raw : null;
                })(),
                mediaAssetCode: (() {
                  final raw = staff.photoUuid.trim();
                  final looksLikeUrl =
                      raw.startsWith('http://') || raw.startsWith('https://');
                  return (!looksLikeUrl && raw.isNotEmpty) ? raw : null;
                })(),
                name: staff.name,
                staffCode: staff.staffCode.trim().isNotEmpty
                    ? staff.staffCode.trim()
                    : null,
                staffEmploymentStatus: staff.profileStatus,
                statusColor: attendanceDotColor,
                statusTooltip: attendanceTooltip,
                disableAttendanceStatusLookup: true,
                size: 50,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: onNameTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      staff.name,
                      style: const TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    Text(
                      designationLabel,
                      style: const TextStyle(
                        fontFamily: AppFonts.body,
                        color: AppColors.classroomTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showMessageIcon) ...[
            IconButton(
              color: AppColors.classroomMessageIconColor,
              iconSize: 20,
              icon: const Icon(Icons.mail),
              onPressed: () {},
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _DesignationMultiSelectDropdown extends StatefulWidget {
  final String hintText;
  final List<String> items;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;

  const _DesignationMultiSelectDropdown({
    Key? key,
    required this.hintText,
    required this.items,
    required this.selectedItems,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<_DesignationMultiSelectDropdown> createState() =>
      _DesignationMultiSelectDropdownState();
}

class _DesignationMultiSelectDropdownState
    extends State<_DesignationMultiSelectDropdown> {
  late List<String> _localSelectedItems;

  @override
  void initState() {
    super.initState();
    _localSelectedItems = List.from(widget.selectedItems);
  }

  @override
  void didUpdateWidget(_DesignationMultiSelectDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    _localSelectedItems = List.from(widget.selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    String displayText = _localSelectedItems.isEmpty
        ? widget.hintText
        : '${_localSelectedItems.length} selected';

    return SizedBox(
      height: 32,
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
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
