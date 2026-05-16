import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/classrooom/views/filters/classroom_staff_filter_screen.dart';
import 'package:wowcare/presentation/features/classrooom/views/filters/designation_display_utils.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_action_panel.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_attendance_action_availability.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/domain/features/staff_classroom/entities/staff_classroom_item.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_sign_in_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_sign_out_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_transfer_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_absent_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_map_usecase.dart';
import 'package:wowcare/presentation/features/classrooom/cubit/classroom_staff_cubit.dart';
import 'package:wowcare/presentation/features/classrooom/cubit/classroom_staff_state.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_entity.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_transfer_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_mark_absent_form.dart';

/// Bumped by any screen/flow that mutates the classroom staff roster (e.g. the
/// "Assign Staff to Classroom" sheet). The Staff-tab card listens and
/// invalidates its cubit + attendance cache so the newly assigned staff is
/// visible immediately, without the user having to switch tabs to force a
/// rebuild.
final ValueNotifier<int> classroomStaffRefreshTick = ValueNotifier<int>(0);

void notifyClassroomStaffChanged() {
  classroomStaffRefreshTick.value++;
}

class _StaffAttendanceCacheEntry {
  const _StaffAttendanceCacheEntry({
    required this.fetchedAt,
    required this.statusByCode,
  });

  final DateTime fetchedAt;
  final Map<String, String> statusByCode;
}

class Staff {
  const Staff({
    required this.staffCode,
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

class ClassroomStaffTabCard extends StatefulWidget {
  const ClassroomStaffTabCard({
    required this.scrollController,
    required this.selectedRoom,
    super.key,
  });

  final ScrollController scrollController;
  final Classroom? selectedRoom;

  static const routeName = '/classroom-staff-screen';

  @override
  State<ClassroomStaffTabCard> createState() => _ClassroomStaffTabCardState();
}

class _ClassroomStaffTabCardState extends State<ClassroomStaffTabCard> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
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
  final Map<String, String> _attendanceStatusByStaffCode = <String, String>{};
  bool _attendanceStatusLoading = false;
  bool _attendanceStatusError = false;
  int _visibleAttendanceFetchToken = 0;
  Set<String> _lastVisibleAttendanceCodes = <String>{};

  static const Duration _attendanceCacheTtl = Duration(minutes: 10);
  static final Map<String, _StaffAttendanceCacheEntry> _attendanceCacheByKey =
      <String, _StaffAttendanceCacheEntry>{};

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
    _cubit = serviceLocator<ClassroomStaffCubit>();
    _searchController.addListener(_onSearchChanged);
    _loadForSelectedRoom(refresh: false);
    classroomStaffRefreshTick.addListener(_handleExternalRefresh);
  }

  void _handleExternalRefresh() {
    if (!mounted) return;
    // Staff roster changed elsewhere (assign sheet, etc.) — drop today's
    // attendance status cache for this room so the new staff shows up with
    // fresh status, then refetch the staff list bypassing the repo cache.
    _attendanceCacheByKey.remove(_attendanceCacheKeyForRoomToday());
    _attendanceStatusByStaffCode.clear();
    _lastVisibleAttendanceCodes = <String>{};
    _loadForSelectedRoom(refresh: true);
  }

  @override
  void didUpdateWidget(ClassroomStaffTabCard oldWidget) {
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
    _cubit.close();
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
    _refreshAttendanceStatusForSelection();
  }

  List<Staff> _getVisibleStaff() {
    if (_filteredStaff.isEmpty &&
        _searchController.text.isEmpty &&
        _selectedDesignation.isEmpty) {
      return _allStaff.where((staff) => staff.designation != 'Kiosk').toList();
    } else {
      return _filteredStaff;
    }
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

  String _attendanceCacheKeyForRoomToday() {
    final classroomCode = (widget.selectedRoom?.code ?? '').trim();
    final date = _formatDate(DateTime.now());
    return 'staff:$classroomCode:$date';
  }

  Future<void> _refreshAttendanceStatusForSelection() async {
    final codes = _getSelectedStaffCodes();
    if (codes.isEmpty) {
      if (!mounted) return;
      setState(() {
        _attendanceStatusByStaffCode.clear();
        _attendanceStatusLoading = false;
        _attendanceStatusError = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _attendanceStatusLoading = true;
      _attendanceStatusError = false;
    });

    try {
      final useCase = serviceLocator<GetStaffTodaySignInStatusMapUseCase>();
      final map = await useCase(staffCodes: codes.toList());
      if (!mounted) return;
      setState(() {
        _attendanceStatusByStaffCode
          ..clear()
          ..addAll(map);
        _attendanceStatusLoading = false;
        _attendanceStatusError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _attendanceStatusByStaffCode.clear();
        _attendanceStatusLoading = false;
        _attendanceStatusError = true;
      });
    }
  }

  Future<void> _refreshAttendanceStatusForVisibleStaff() async {
    final visible = _getVisibleStaff();
    final codes = visible
        .map((s) => s.staffCode.trim())
        .where((c) => c.isNotEmpty)
        .toSet();

    final cacheKey = _attendanceCacheKeyForRoomToday();
    final cached = _attendanceCacheByKey[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) <= _attendanceCacheTtl) {
      if (!mounted) return;
      setState(() {
        _attendanceStatusByStaffCode
          ..clear()
          ..addAll(cached.statusByCode);
        _attendanceStatusLoading = false;
        _attendanceStatusError = false;
      });
    }

    if (codes.isEmpty) {
      _lastVisibleAttendanceCodes = <String>{};
      if (!mounted) return;
      setState(() {
        _attendanceStatusByStaffCode.clear();
        _attendanceStatusLoading = false;
        _attendanceStatusError = false;
      });
      return;
    }

    if (setEquals(codes, _lastVisibleAttendanceCodes)) return;
    _lastVisibleAttendanceCodes = codes;

    final token = ++_visibleAttendanceFetchToken;
    if (!mounted) return;
    setState(() {
      _attendanceStatusLoading = true;
      _attendanceStatusError = false;
    });

    try {
      final useCase = serviceLocator<GetStaffTodaySignInStatusMapUseCase>();
      final map = await useCase(staffCodes: codes.toList());
      if (!mounted || token != _visibleAttendanceFetchToken) return;
      setState(() {
        _attendanceStatusByStaffCode
          ..clear()
          ..addAll(map);
        _attendanceStatusLoading = false;
        _attendanceStatusError = false;
      });
      _attendanceCacheByKey[cacheKey] = _StaffAttendanceCacheEntry(
        fetchedAt: DateTime.now(),
        statusByCode: Map<String, String>.from(map),
      );
    } catch (_) {
      if (!mounted || token != _visibleAttendanceFetchToken) return;
      setState(() {
        _attendanceStatusByStaffCode.clear();
        _attendanceStatusLoading = false;
        _attendanceStatusError = true;
      });
    }
  }

  /// Pull-to-refresh: re-run every API this tab uses (staff roster + today's
  /// attendance status), bypassing the repository and attendance caches.
  Future<void> _refreshAll() async {
    if (!mounted) return;
    // Drop attendance caches/guards so the status is fetched fresh.
    _attendanceCacheByKey.remove(_attendanceCacheKeyForRoomToday());
    _lastVisibleAttendanceCodes = <String>{};
    _attendanceStatusByStaffCode.clear();
    // Reload the staff roster (bypasses the repository cache).
    _loadForSelectedRoom(refresh: true);
    // Re-fetch today's attendance status.
    await _refreshAttendanceStatusForVisibleStaff();
  }

  StaffAttendanceActionAvailability _attendanceAvailabilityForSelection() {
    final codes = _getSelectedStaffCodes();
    if (codes.isEmpty) {
      return StaffAttendanceActionAvailability.allDisabled;
    }
    if (_attendanceStatusLoading || _attendanceStatusError) {
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
          todayStatusRaw: _attendanceStatusByStaffCode[code],
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

    final date = _formatDate(DateTime.now());
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
        color: const Color.fromRGBO(177, 175, 233, 0.3),
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _openFilterScreen,
        child: Text(
          _statusChipLabel(apiStatus),
          style: const TextStyle(
            fontFamily: 'Manrope',
            color: Color.fromRGBO(27, 35, 126, 1),
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
      _attendanceStatusByStaffCode.clear();
      _attendanceStatusLoading = false;
      _attendanceStatusError = false;
    });
    _loadForSelectedRoom(refresh: false);
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
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<ClassroomStaffCubit, ClassroomStaffState>(
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
            _refreshAttendanceStatusForVisibleStaff();
          });
        },
        child: Stack(
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
                    ),
                    color: Colors.white,
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
                                            Colors.white,
                                          ),
                                      surfaceTintColor:
                                          const WidgetStatePropertyAll<Color>(
                                            Colors.white,
                                          ),
                                      hintText: 'Search',
                                      hintStyle: const WidgetStatePropertyAll(
                                        TextStyle(
                                          fontFamily: 'Manrope',
                                          color: Color.fromRGBO(
                                            87,
                                            51,
                                            83,
                                            0.7,
                                          ),
                                          fontSize: 13,
                                        ),
                                      ),
                                      leading: const Icon(
                                        Icons.search,
                                        color: AppColors.primaryColor,
                                        size: 18,
                                      ),
                                      elevation: const WidgetStatePropertyAll(
                                        0,
                                      ),
                                      side: const WidgetStatePropertyAll(
                                        BorderSide(
                                          width: 1,
                                          color: Color.fromARGB(
                                            255,
                                            188,
                                            173,
                                            186,
                                          ),
                                        ),
                                      ),
                                      shape: WidgetStatePropertyAll(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: _openFilterScreen,
                                    icon: SvgPicture.asset(
                                      MediaRes.filterIcon,
                                      height: 22,
                                    ),
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
                                      gradient:
                                          AppColors.buildPrimaryGradient(),
                                    ),
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 3,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: _clearAllSelections,
                                      child: const Text(
                                        'Clear All',
                                        style: TextStyle(
                                          fontFamily: 'Manrope',
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.info_outline_rounded,
                                      color: AppColors.primaryColor,
                                      size: 20,
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
                                const Color.fromRGBO(222, 228, 253, 1),
                              ),
                              radius: const Radius.circular(20),
                            ),
                            child: Scrollbar(
                              controller: widget.scrollController,
                              child: BlocBuilder<ClassroomStaffCubit, ClassroomStaffState>(
                                builder: (context, state) {
                                  final visible = _getVisibleStaff();
                                  if (state.isLoading && visible.isEmpty) {
                                    return const Center(
                                      child: PrimaryCircularLoader(),
                                    );
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
                                                    height:
                                                        constraints.maxHeight,
                                                    child: Center(
                                                      child: Text(
                                                        'No staff assigned.',
                                                        style: TextStyle(
                                                          fontFamily: 'Manrope',
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
                                            padding: const EdgeInsets.only(
                                              left: 16,
                                              right: 16,
                                            ),
                                            itemCount: visible.length,
                                            itemBuilder: (context, index) {
                                              final staff = visible[index];
                                              _initializeStaffSelections(
                                                visible,
                                              );
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                    _refreshAttendanceStatusForVisibleStaff();
                                                  });
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8.0,
                                                ),
                                                child: _StaffListItem(
                                                  staff: staff,
                                                  isSelected:
                                                      staffSelections[staff
                                                          .staffCode] ??
                                                      false,
                                                  todayAttendanceStatusRaw:
                                                      _attendanceStatusByStaffCode[staff
                                                          .staffCode],
                                                  designationLabel:
                                                      formatDesignationForDisplay(
                                                        staff.designation,
                                                      ),
                                                  onSelectionChanged:
                                                      (bool? value) {
                                                        _toggleStaffSelection(
                                                          staff.staffCode,
                                                          value,
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
                  onMessageTap: () {},
                  onProfileTap: null,
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
                  isProfileEnabled: false,
                  activitiesEnabled: _getSelectedStaffCodes().isNotEmpty,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StaffListItem extends StatelessWidget {
  const _StaffListItem({
    required this.staff,
    required this.isSelected,
    required this.onSelectionChanged,
    this.todayAttendanceStatusRaw,
    required this.designationLabel,
  });

  final Staff staff;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
  final String? todayAttendanceStatusRaw;
  final String designationLabel;

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
        ? Colors.green
        : (normalizedAttendance == 'ABSENT' ? Colors.red : null);
    final String? attendanceTooltip = normalizedAttendance == 'SIGNED_IN'
        ? 'Staff is signed in'
        : (normalizedAttendance == 'ABSENT' ? 'Staff is absent' : null);

    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 10, left: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: shouldGreyOut ? Colors.grey[100] : null,
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
            child: Container(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    staff.name,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(87, 51, 83, 1),
                    ),
                  ),
                  Text(
                    designationLabel,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      color: Color(0xff573353),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            color: const Color.fromRGBO(44, 99, 226, 1),
            iconSize: 20,
            icon: const Icon(Icons.mail),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
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
          fillColor: Colors.white,
          hintText: widget.hintText,
          contentPadding: const EdgeInsets.symmetric(horizontal: 5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 188, 173, 186),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 188, 173, 186),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 188, 173, 186),
            ),
          ),
        ),
        icon: const Icon(Icons.keyboard_arrow_down),
        iconSize: 24,
        elevation: 2,
        style: const TextStyle(
          fontFamily: 'Manrope',
          color: Color(0xff573353),
          fontSize: 16,
        ),
        dropdownColor: Colors.white,
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
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            color: Color(0xff573353),
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
            fontFamily: 'Manrope',
            color: _localSelectedItems.isEmpty
                ? Colors.grey[600]
                : const Color(0xff573353),
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
