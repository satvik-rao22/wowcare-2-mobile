import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/app/theme/decorations.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/simmer_loader.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/custom_floating_action_button.dart';
import 'package:wowcare/presentation/features/classrooom/forms/assign_staff_to_classroom_form.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_screen.dart';

// UI-only lightweight models
class RoomDTO {
  final int id;
  final String name;
  const RoomDTO({required this.id, required this.name});
}

class Staff {
  final int id;
  final String name;
  final String designation;
  final String email;
  final String photoUuid;
  final bool isExpectedToday;
  final bool isSignedIn;
  final bool isAbsent;
  final String profileStatus; // 'A' | 'Upcoming'
  final int primaryRoomId;

  const Staff({
    required this.id,
    required this.name,
    required this.designation,
    required this.email,
    this.photoUuid = '',
    this.isExpectedToday = true,
    this.isSignedIn = false,
    this.isAbsent = false,
    this.profileStatus = 'A',
    required this.primaryRoomId,
  });
}

class ClassroomStaffTabCard extends StatefulWidget {
  const ClassroomStaffTabCard({
    required this.scrollController,
    required this.selectedRoom,
    super.key,
  });

  final ScrollController scrollController;
  final RoomDTO? selectedRoom;

  static const routeName = '/classroom-staff-screen';

  @override
  State<ClassroomStaffTabCard> createState() => _ClassroomStaffTabCardState();
}

class _ClassroomStaffTabCardState extends State<ClassroomStaffTabCard> {
  final TextEditingController _searchController = TextEditingController();
  bool isSelectAllChecked = false;
  Map<String, bool> staffSelections = {};
  List<String> _selectedDesignation = [];
  List<Staff> _filteredStaff = [];
  List<Staff> _allStaff = [];
  FilterData? _currentFilterData;
  List<String> _selectedStatusList = [];
  List<String> _selectedAttendanceStatusList = [];

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

  void _loadDummyStaff() {
    final roomId = widget.selectedRoom?.id ?? 0;
    _allStaff = const [
      Staff(
        id: 1,
        name: 'Ava Johnson',
        designation: 'Lead Teacher',
        email: 'ava@example.com',
        isSignedIn: true,
        primaryRoomId: 1,
      ),
      Staff(
        id: 2,
        name: 'Michael Chen',
        designation: 'Assistant Teacher',
        email: 'michael@example.com',
        isAbsent: false,
        isExpectedToday: true,
        primaryRoomId: 1,
      ),
      Staff(
        id: 3,
        name: 'Priya Patel',
        designation: 'Floater',
        email: 'priya@example.com',
        isExpectedToday: true,
        primaryRoomId: 2,
      ),
    ].map((s) => Staff(
          id: s.id,
          name: s.name,
          designation: s.designation,
          email: s.email,
          photoUuid: s.photoUuid,
          isExpectedToday: s.isExpectedToday,
          isSignedIn: s.isSignedIn,
          isAbsent: s.isAbsent,
          profileStatus: s.profileStatus,
          primaryRoomId: roomId == 0 ? s.primaryRoomId : roomId,
        ))
        .toList();
    _filterStaff();
  }

  @override
  void initState() {
    super.initState();
    _loadDummyStaff();
    _searchController.addListener(_onSearchChanged);
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
        _currentFilterData = null;
        _selectedStatusList = [];
        _selectedAttendanceStatusList = [];
      });
      _loadDummyStaff();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterStaff();
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
      if (!staffSelections.containsKey(member.name)) {
        staffSelections[member.name] = false;
      }
    }
  }

  void _toggleStaffSelection(String name, bool? value) {
    if (value == null) return;

    setState(() {
      staffSelections[name] = value;
      final List<Staff> visibleStaff = _getVisibleStaff();
      isSelectAllChecked = visibleStaff.every(
        (staff) => staffSelections[staff.name] == true,
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
    return Stack(
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
                            onRefresh: () async => _loadDummyStaff(),
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
                                        staffSelections[staff.name] ?? false,
                                          onSelectionChanged: (bool? value) {
                                      _toggleStaffSelection(staff.name, value);
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
        // FAB handled at screen level for tab-aware visibility
      ],
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
  final double? width;

  const _DesignationMultiSelectDropdown({
    Key? key,
    required this.hintText,
    required this.items,
    required this.selectedItems,
    required this.onChanged,
    this.width,
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
      width: widget.width,
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
