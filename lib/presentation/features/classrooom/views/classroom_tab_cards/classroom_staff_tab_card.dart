import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_screen.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_action_panel.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/staff_classroom/entities/staff_classroom_item.dart';
import 'package:wowcare/presentation/features/classrooom/cubit/classroom_staff_cubit.dart';
import 'package:wowcare/presentation/features/classrooom/cubit/classroom_staff_state.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_entity.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_transfer_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_mark_absent_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_transfer_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_mark_absent_form.dart';

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
  late final ClassroomStaffCubit _cubit;
  bool isSelectAllChecked = false;
  Map<String, bool> staffSelections = {};
  List<String> _selectedDesignation = [];
  List<Staff> _filteredStaff = [];
  List<Staff> _allStaff = [];
  FilterData? _currentFilterData;
  List<String> _selectedStatusList = [];
  List<String> _selectedAttendanceStatusList = [];
  StaffPanelType _currentPanel = StaffPanelType.none;
  bool _isTeacherStaffPersona = false;
  String _loggedInStaffCode = '';

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
    final classroomCode = widget.selectedRoom?.code ?? '';
    if (classroomCode.trim().isEmpty) return;

    final search =
        _searchController.text.trim().isEmpty ? null : _searchController.text.trim();

    final designation =
        _selectedDesignation.isEmpty ? null : List<String>.from(_selectedDesignation);

    if (refresh) {
      _cubit.refresh(
        classroomCode: classroomCode,
        search: search,
        designation: designation,
      );
    } else {
      _cubit.loadInitial(
        classroomCode: classroomCode,
        search: search,
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
    _loadStaffPersonaFlags();
  }

  Future<void> _loadStaffPersonaFlags() async {
    try {
      final storage = serviceLocator<StorageService>();
      final staffCode =
          (await storage.getString(StorageKeys.staffCode) ?? '').trim();
      var staffType =
          (await storage.getString(StorageKeys.staffType) ?? '').trim().toUpperCase();

      bool isStaffAdmin =
          staffType == 'SCHOOL_ADMIN' || staffType == 'ORGANIZATION_ADMIN';

      if (!isStaffAdmin) {
        final rolesJson = await storage.getString(StorageKeys.roles);
        if (rolesJson != null && rolesJson.trim().isNotEmpty) {
          final List<dynamic> roles = jsonDecode(rolesJson) as List<dynamic>;
          isStaffAdmin = roles.any((r) {
            if (r is! Map<String, dynamic>) return false;
            final roleCode = (r['role'] ?? '').toString().toUpperCase();
            return roleCode == 'SCHOOL_ADMIN' ||
                roleCode == 'ORGANIZATION_ADMIN';
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _loggedInStaffCode = staffCode;
        _isTeacherStaffPersona = staffCode.isNotEmpty && !isStaffAdmin;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loggedInStaffCode = '';
        _isTeacherStaffPersona = false;
      });
    }
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
        _currentFilterData = null;
        _selectedStatusList = [];
        _selectedAttendanceStatusList = [];
      });
      _loadForSelectedRoom(refresh: false);
    }
  }

  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onSearchChanged() => _filterStaff();

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
      _filteredStaff = allStaff.where((staff) {
        bool matchesSearch = true;
        bool matchesDesignation = true;
        bool matchesStatus = true;
        bool matchesAttendanceStatus = true;
        bool isNotKiosk = staff.designation != 'Kiosk';

        if (_searchController.text.isNotEmpty) {
          matchesSearch = staff.name
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
        }

        if (_selectedDesignation.isNotEmpty) {
          matchesDesignation = _selectedDesignation.contains(staff.designation);
        }

        // Apply status filter (Active/Upcoming)
        if (_selectedStatusList.isNotEmpty) {
          matchesStatus = (_selectedStatusList.contains('Active') && staff.profileStatus == 'A') ||
              (_selectedStatusList.contains('Upcoming') && staff.profileStatus == 'Upcoming');
        }

        // Apply attendance status filter (Expected/Present/Absent)
        if (_selectedAttendanceStatusList.isNotEmpty) {
          matchesAttendanceStatus = 
              (_selectedAttendanceStatusList.contains('Expected') && staff.isExpectedToday) ||
              (_selectedAttendanceStatusList.contains('Present') && staff.isSignedIn) ||
              (_selectedAttendanceStatusList.contains('Absent') && staff.isAbsent);
        }

        return matchesSearch && matchesDesignation && matchesStatus && matchesAttendanceStatus && isNotKiosk;
      }).toList();
      setState(() {});
      return _filteredStaff;
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

  void _clearAllSelections() {
    setState(() {
      isSelectAllChecked = false;
      staffSelections.updateAll((key, val) => false);
      _searchController.clear();
      _selectedDesignation = [];
      _currentFilterData = null;
      _selectedStatusList = [];
      _selectedAttendanceStatusList = [];
      _filterStaff();
    });
  }

  Future<void> _openFilterScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaffFilterScreen(
          initialFilters: _currentFilterData,
        ),
      ),
    );

    if (!mounted) return;

    if (result is FilterData) {
      setState(() {
        _currentFilterData = result;
        _selectedDesignation = List.from(result.tags);
        _selectedStatusList = List.from(result.statuses);
        _selectedAttendanceStatusList = List.from(result.attendanceStatuses);
        _filterStaff();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<ClassroomStaffCubit, ClassroomStaffState>(
        listener: (context, state) {
          final apiItems = state.staff.map(_mapApiToUi).toList();
          setState(() {
            _allStaff = apiItems;
          });
          _filterStaff();
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
                                  constraints:
                                      const BoxConstraints(minHeight: 36),
                                  hintText: 'Search',
                                  hintStyle: const WidgetStatePropertyAll(
                                    TextStyle(
                                      fontFamily: 'Manrope',
                                      color: Color.fromRGBO(87, 51, 83, 0.7),
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
                                      color: Color.fromARGB(255, 188, 173, 186),
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
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color:
                                      const Color.fromRGBO(177, 175, 233, 0.3),
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
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {},
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      color: Color.fromRGBO(27, 35, 126, 1),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: AppColors.buildPrimaryGradient(),
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
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _clearAllSelections,
                                  child: const Text(
                                    'Clear All',
                                    style: TextStyle(fontFamily: 'Manrope', fontSize: 12),
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
                          child: CustomRefreshIndicator(
                            onRefresh: () async => _loadForSelectedRoom(refresh: true),
                                child: ListView.builder(
                              padding:
                                  const EdgeInsets.only(left: 16, right: 16),
                              itemCount: _getVisibleStaff().length,
                                  itemBuilder: (context, index) {
                                final staff = _getVisibleStaff()[index];
                                _initializeStaffSelections(_getVisibleStaff());
                                return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8.0),
                                  child: _StaffListItem(
                                          staff: staff,
                                          isSelected:
                                        staffSelections[staff.staffCode] ?? false,
                                          onSelectionChanged: (bool? value) {
                                      _toggleStaffSelection(staff.staffCode, value);
                                          },
                                      ),
                                    );
                                  },
                                ),
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
                  onSignIn: () {
                    final selectedCodes = _getSelectedStaffCodes();
                    if (_isTeacherStaffPersona && _loggedInStaffCode.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StaffSignInForm(
                            staff: StaffEntity(
                              id: 0,
                              name: 'Self',
                              primaryRoomId: 0,
                              staffCode: _loggedInStaffCode,
                            ),
                          ),
                        ),
                      );
                    } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StaffSelectionSignInForm(
                          initialStaffCodes: selectedCodes,
                        ),
                      ),
                    );
                    }
                  },
                  onSignOut: () {
                    final selectedCodes = _getSelectedStaffCodes();
                    if (_isTeacherStaffPersona && _loggedInStaffCode.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StaffSignOutForm(
                            staff: StaffEntity(
                              id: 0,
                              name: 'Self',
                              primaryRoomId: 0,
                              staffCode: _loggedInStaffCode,
                            ),
                          ),
                        ),
                      );
                    } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StaffSelectionSignOutForm(
                          initialStaffCodes: selectedCodes,
                        ),
                      ),
                    );
                    }
                  },
                  onTransfer: () {
                    final selectedCodes = _getSelectedStaffCodes();
                    if (_isTeacherStaffPersona && _loggedInStaffCode.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StaffTransferForm(
                            staff: StaffEntity(
                              id: 0,
                              name: 'Self',
                              primaryRoomId: 0,
                              staffCode: _loggedInStaffCode,
                            ),
                          ),
                        ),
                      );
                    } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StaffSelectionTransferForm(
                          initialStaffCodes: selectedCodes,
                        ),
                      ),
                    );
                    }
                  },
                  onAbsent: () {
                    final selectedCodes = _getSelectedStaffCodes();
                    if (_isTeacherStaffPersona && _loggedInStaffCode.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StaffMarkAbsentForm(
                            staff: StaffEntity(
                              id: 0,
                              name: 'Self',
                              primaryRoomId: 0,
                              staffCode: _loggedInStaffCode,
                            ),
                          ),
                        ),
                      );
                    } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StaffSelectionMarkAbsentForm(
                          initialStaffCodes: selectedCodes,
                        ),
                      ),
                    );
                    }
                  },
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
  });

  final Staff staff;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: 10,
        bottom: 10,
        left: 10,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: staff.isExpectedToday ? null : Colors.grey[100],
      ),
      child: Row(
        children: [
          Opacity(
            opacity: staff.isExpectedToday ? 1 : 0.5,
            child: AbsorbPointer(
              absorbing: !staff.isExpectedToday,
              child: GestureDetector(
                onTap: () => onSelectionChanged(!isSelected),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    DocumentImageWidget(
                      fileUuid: staff.photoUuid,
                      name: staff.name,
                        size: 50,
                      ),
                    if (staff.isSignedIn ||
                        staff.isAbsent ||
                        staff.profileStatus == 'Upcoming')
                      Positioned(
                        left: 35,
                        bottom: 35,
                        child: Container(
                          decoration: BoxDecoration(
                            color: staff.profileStatus == 'Upcoming'
                                ? const Color.fromARGB(255, 253, 205, 22)
                                : staff.isSignedIn
                                    ? const Color.fromRGBO(0, 177, 21, 1)
                                    : staff.isAbsent
                                        ? const Color.fromRGBO(200, 32, 32, 1)
                                        : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 15,
                            minHeight: 15,
                          ),
                        ),
                      ),
                  ],
                ),
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
                    staff.designation,
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
  State<_DesignationMultiSelectDropdown> createState() => _DesignationMultiSelectDropdownState();
}

class _DesignationMultiSelectDropdownState extends State<_DesignationMultiSelectDropdown> {
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
          fillColor: AppColors.primaryColor.withValues(alpha: 0.1),
          hintText: widget.hintText,
          contentPadding: const EdgeInsets.symmetric(horizontal: 5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Colors.transparent,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Colors.transparent,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Colors.transparent,
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
            color: _localSelectedItems.isEmpty ? Colors.grey[600] : const Color(0xff573353),
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
