import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/message_composition_bulk_messaging.dart';
import 'package:wowcare/shared/common/widgets/student_tile.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import '../../../../../../app/theme/colors.dart';
import '../../../../../../app/theme/media_res.dart';
import '../../../../../../shared/common/widgets/custom_checkbox.dart';
import '../../../../../../shared/common/widgets/custom_clear_all_chip.dart';
import '../../../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../../../shared/common/widgets/custom_multi_select_dropdown.dart';
import '../../../../../../shared/common/widgets/custom_search_bar.dart';

class StaffOrStudentSelectionBulkMessaging extends StatefulWidget {
  const StaffOrStudentSelectionBulkMessaging({
    super.key,
    this.isStaffSelection = true,
  });
  final bool showLoading = false;
  final bool isStaffSelection;

  @override
  State<StaffOrStudentSelectionBulkMessaging> createState() =>
      _StaffOrStudentSelectionBulkMessagingState();
}

class _StaffOrStudentSelectionBulkMessagingState
    extends State<StaffOrStudentSelectionBulkMessaging> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedClassrooms = [];
  String? _selectedStatus;
  bool _selectAll = false;
  List<String> _selectedDesignations = [];
  List<String> _selectedTags = [];
  final List<String> _statusOptions = ['Active', 'Upcoming'];
  final List<String> _classroomOptions = ['1-Blue D', '3-Orange-D', '2-Red A'];
  final List<Map<String, dynamic>> staffList = [
    {
      'name': 'Natasha White',
      'avatar': 'https://randomuser.me/api/portraits/women/44.jpg',
      'dateTime': DateTime(2026, 1, 20, 17, 30),
      'message': 'Oh, hello! All perfectly.',
      'isSigned': true,
      'isFavorite': true,
      'unreadCount': 1,
      'classroom': '1-Blue D',
      'designation': 'Lead Teacher',
      'status': 'Active',
    },
    {
      'name': 'Eddie Barnes',
      'avatar': 'https://randomuser.me/api/portraits/men/32.jpg',
      'dateTime': DateTime(2026, 1, 20, 17, 30),
      'message': 'Morning check-in done. All good here.',
      'isSigned': true,
      'isFavorite': false,
      'unreadCount': 0,
      'classroom': '2-Red A',
      'designation': 'Lead Teacher',
      'status': 'Active',
    },
    {
      'name': 'Lara Adams',
      'avatar': 'https://randomuser.me/api/portraits/women/68.jpg',
      'dateTime': DateTime(2026, 1, 19, 14, 45),
      'message': 'The activity report is ready for review.',
      'isSigned': false,
      'isFavorite': true,
      'unreadCount': 3,
      'classroom': '1-Blue D',
      'designation': 'Lead Teacher',
      'status': 'Active',
    },
    {
      'name': 'Michael Chen',
      'avatar': 'https://randomuser.me/api/portraits/men/45.jpg',
      'dateTime': DateTime(2026, 1, 18, 16, 15),
      'message': 'Need approval on tomorrow’s schedule.',
      'isSigned': true,
      'isFavorite': false,
      'unreadCount': 0,
      'classroom': '3-Orange-D',
      'designation': 'Admin',
      'status': 'Upcoming',
    },
    {
      'name': 'Sarah Johnson',
      'avatar': 'https://randomuser.me/api/portraits/women/22.jpg',
      'dateTime': DateTime(2026, 1, 15, 11, 20),
      'message': 'Parent meeting notes uploaded.',
      'isSigned': false,
      'isFavorite': false,
      'unreadCount': 7,
      'classroom': '3-Orange-D',
      'designation': 'Admin',
      'status': 'Upcoming',
    },
    {
      'name': 'Natasha White',
      'avatar': 'https://randomuser.me/api/portraits/women/44.jpg',
      'dateTime': DateTime(2026, 1, 20, 17, 30),
      'message': 'Oh, hello! All perfectly.',
      'isSigned': true,
      'isFavorite': true,
      'unreadCount': 1,
      'classroom': '3-Orange-D',
      'designation': 'Admin',
      'status': 'Upcoming',
    },
    {
      'name': 'Eddie Barnes',
      'avatar': 'https://randomuser.me/api/portraits/men/32.jpg',
      'dateTime': DateTime(2026, 1, 20, 17, 30),
      'message': 'Morning check-in done. All good here.',
      'isSigned': true,
      'isFavorite': false,
      'unreadCount': 0,
      'classroom': '3-Orange-D',
      'designation': 'Admin',
      'status': 'Upcoming',
    },
    {
      'name': 'Lara Adams',
      'avatar': 'https://randomuser.me/api/portraits/women/68.jpg',
      'dateTime': DateTime(2026, 1, 19, 14, 45),
      'message': 'The activity report is ready for review.',
      'isSigned': false,
      'isFavorite': true,
      'unreadCount': 3,
      'classroom': '3-Orange-D',
      'designation': 'Admin',
      'status': 'Upcoming',
    },
    {
      'name': 'Michael Chen',
      'avatar': 'https://randomuser.me/api/portraits/men/45.jpg',
      'dateTime': DateTime(2026, 1, 18, 16, 15),
      'message': 'Need approval on tomorrow’s schedule.',
      'isSigned': true,
      'isFavorite': false,
      'unreadCount': 0,
      'classroom': '3-Orange-D',
      'designation': 'Admin',
      'status': 'Upcoming',
    },
    {
      'name': 'Sarah Johnson',
      'avatar': 'https://randomuser.me/api/portraits/women/22.jpg',
      'dateTime': DateTime(2026, 1, 15, 11, 20),
      'message': 'Parent meeting notes uploaded.',
      'isSigned': false,
      'isFavorite': false,
      'unreadCount': 7,
      'classroom': '3-Orange-D',
      'designation': 'Admin',
      'status': 'Upcoming',
    },
  ];
  final List<Map<String, dynamic>> parentList = [
    {
      'name': 'Ajay Sundaram',
      'avatar': 'https://randomuser.me/api/portraits/boys/45.jpg',
      'dateTime': DateTime(2026, 2, 4, 13, 30),
      'message': 'Oh, hello! All perfectly.',
      'isSigned': true,
      'isFavorite': false,
      'unreadCount': 1,
      'classroom': '2-Green B',
      'status': 'Upcoming',
      'tags': ['5 Days', 'Full Day', 'Photo Permission', 'Boy'],
      'staffList': ['Eddie Barnes', 'John Doe', 'Priya Sharma', 'Mr. Kumar'],
      'parents': ['Nitin Sundaram', 'Radha Sundaram'],
      'privateModeParents': ['Nitin Sundaram', 'Radha Sundaram'],
    },
    {
      'name': 'Chaitanya Bhave',
      'avatar': 'https://randomuser.me/api/portraits/men/67.jpg',
      'dateTime': DateTime(2026, 2, 4, 13, 30),
      'message': 'Oh, hello! All perfectly.',
      'isSigned': true,
      'isFavorite': false,
      'unreadCount': 1,
      'classroom': '1-Yellow A',
      'status': 'Active',
      'tags': ['Full Day', 'Vegetarian', 'Boy'],
      'staffList': ['Eddie Barnes', 'Sarah Lee', 'Mr. Patel'],
      'parents': ['Vikas Bhave', 'Sneha Bhave'],
      'privateModeParents': [],
    },
    {
      'name': 'Riken Mehta',
      'avatar': 'https://randomuser.me/api/portraits/boys/12.jpg',
      'dateTime': DateTime(2026, 2, 4, 13, 30),
      'message': 'Oh, hello! All perfectly.',
      'isSigned': true,
      'isFavorite': false,
      'unreadCount': 1,
      'classroom': '3-Purple C',
      'status': 'Active',
      'tags': ['5 Days', 'Medication', 'Allergy', 'Boy'],
      'staffList': ['John Doe', 'Priya Sharma', 'Ms. Gupta'],
      'parents': ['Rakesh Mehta', 'Pooja Mehta'],
      'privateModeParents': ['Pooja Mehta'],
    },
    {
      'name': 'Thomas Edison',
      'avatar': 'https://randomuser.me/api/portraits/boys/88.jpg',
      'dateTime': DateTime(2026, 2, 4, 13, 30),
      'message': 'Oh, hello! All perfectly.',
      'isSigned': true,
      'isFavorite': true,
      'unreadCount': 0,
      'classroom': '4-Blue D',
      'status': 'Active',
      'tags': ['Half Day', 'Pickup Authorized', 'Boy'],
      'staffList': ['Eddie Barnes', 'Sarah Lee', 'Mr. Kumar'],
      'parents': ['James Edison', 'Mary Edison'],
      'privateModeParents': [],
    },
    {
      'name': 'Olivia Gonsalves',
      'avatar': 'https://randomuser.me/api/portraits/girls/23.jpg',
      'dateTime': DateTime(2026, 2, 4, 13, 30),
      'message': 'Oh, hello! All perfectly.',
      'isSigned': true,
      'isFavorite': false,
      'unreadCount': 0,
      'classroom': '2-Red A',
      'status': 'Active',
      'tags': ['5 Days', 'Full Day', 'Girl', 'First Aid'],
      'staffList': ['Priya Sharma', 'Ms. Gupta', 'Mr. Patel'],
      'parents': ['Antonio Gonsalves', 'Maria Gonsalves'],
      'privateModeParents': [],
    },
    {
      'name': 'Satya Vani Kanumuri',
      'avatar': 'https://randomuser.me/api/portraits/women/51.jpg',
      'dateTime': DateTime(2026, 2, 4, 13, 30),
      'message': 'Oh, hello! All perfectly.',
      'isSigned': true,
      'isFavorite': true,
      'unreadCount': 0,
      'classroom': '1-Blue D',
      'status': 'Active',
      'tags': ['Full Day', 'Photo Permission', 'Vegetarian', 'Girl'],
      'staffList': ['Eddie Barnes', 'John Doe', 'Sarah Lee'],
      'parents': ['Ravi Kanumuri', 'Lakshmi Kanumuri'],
      'privateModeParents': [],
    },
  ];
  final List<String> _designationOptions = [
    'Kiosk',
    'Director',
    'Assistant Director',
    'Admin',
    'Lead Teacher',
    'Associate Teacher',
    'Assistant Teacher',
    'Owner',
    'Floater',
  ];
  final List<String> _tagOptions = [
    '5 Days',
    'Full Day',
    'Photo Permission',
    'Vegetarian',
    'First Aid',
    'Allergy',
    'Pickup Authorized',
    'Medication',
    'Half Day',
    'Boy',
    'Girl',
  ];
  Set<Map<String, dynamic>> _selectedStaff = <Map<String, dynamic>>{};
  Set<Map<String, dynamic>> _selectedStudents = <Map<String, dynamic>>{};

  List<MapEntry<String, Map<String, dynamic>>> get _filteredList {
    final query = _searchController.text.trim().toLowerCase();
    var filtered = widget.isStaffSelection
        ? List<Map<String, dynamic>>.from(staffList)
        : List<Map<String, dynamic>>.from(parentList);

    if (_selectedStatus != null) {
      filtered = filtered.where((person) {
        final status = person['status'] as String?;
        return status != null && _selectedStatus == status;
      }).toList();
    }
    if (_selectedClassrooms.isNotEmpty) {
      filtered = filtered.where((person) {
        final classroom = person['classroom'] as String?;
        return classroom != null && _selectedClassrooms.contains(classroom);
      }).toList();
    }
    if (_selectedDesignations.isNotEmpty && widget.isStaffSelection) {
      filtered = filtered.where((person) {
        final designation = person['designation'] as String?;
        return designation != null &&
            _selectedDesignations.contains(designation);
      }).toList();
    }
    if (_selectedTags.isNotEmpty && !widget.isStaffSelection) {
      filtered = filtered.where((person) {
        final tags = List<String>.from(person['tags']);
        return tags.any((tag) => _selectedTags.contains(tag));
      }).toList();
    }

    if (query.isNotEmpty) {
      filtered = filtered.where((person) {
        final name = (person['name'] as String?)?.toLowerCase() ?? '';
        final message = (person['message'] as String?)?.toLowerCase() ?? '';
        return name.contains(query) || message.contains(query);
      }).toList();
    }

    return filtered.asMap().entries.map((entry) {
      return MapEntry(entry.key.toString(), entry.value);
    }).toList();
  }

  void _updateSelectAllState() {
    if (_filteredList.isEmpty) {
      _selectAll = false;
    } else {
      if (widget.isStaffSelection) {
        _selectAll = _filteredList.every(
          (entry) => _selectedStaff.contains(entry.value),
        );
      } else {
        _selectAll = _filteredList.every(
          (entry) => _selectedStudents.contains(entry.value),
        );
      }
    }
  }

  void _showWarningMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      final snackBar = SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade50,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.orange.shade100),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  @override
  void initState() {
    super.initState();
    //_applyFilters();
    _searchController.addListener(_applyFilters);
  }

  void _applyFilters() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(hasBackButton: true),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.buildScaffoldGradient(),
              ),
              child: Image.asset(
                MediaRes.wowcareMobileBg,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.horizontalSpacing,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'New Message',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: responsive.titleFontSize,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff573353),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: responsive.isTablet ? 32.0 : 20.0),
                      Container(
                        width: responsive.containerWidth,
                        margin: EdgeInsets.symmetric(
                          horizontal: responsive.horizontalSpacing,
                        ),
                        padding: EdgeInsets.all(
                          responsive.isTablet ? 32.0 : 16.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(
                            Radius.circular(responsive.isTablet ? 30.0 : 20.0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  widget.isStaffSelection
                                      ? 'Select Staff'
                                      : 'Select Students',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xff573353),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomSearchBar(
                                    controller: _searchController,
                                    hintText: widget.isStaffSelection
                                        ? 'Search Staff'
                                        : 'Search Students',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 38,
                                  child: CustomClearAllChip(
                                    onTap: () {
                                      setState(() {
                                        _selectedClassrooms = [];
                                        _selectedStaff.clear();
                                        _selectedStudents.clear();
                                        _selectedTags = [];
                                        _searchController.clear();
                                        _selectedDesignations = [];
                                        _selectedStatus = null;
                                        _updateSelectAllState();
                                      });
                                      //print(_filterTags);
                                    },
                                    label: 'Clear All',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCustomDropdown(
                                    'Status',
                                    _statusOptions,
                                    _selectedStatus,
                                    (v) => setState(() {
                                      _selectedStatus = v;
                                      _selectedStaff.clear();
                                      _selectAll = false;
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (widget.isStaffSelection)
                                  Expanded(
                                    child: CustomMultiSelectDropdown(
                                      hintText: 'Select Designation',
                                      items: _designationOptions,
                                      selectedItems: _selectedDesignations,
                                      gapHeight: 40,
                                      onChanged: (selectedItems) {
                                        setState(() {
                                          _selectedDesignations = selectedItems;
                                          _updateSelectAllState();
                                        });
                                      },
                                    ),
                                  )
                                else
                                  Expanded(
                                    child: CustomMultiSelectDropdown(
                                      hintText: 'Select Tags',
                                      items: _tagOptions,
                                      selectedItems: _selectedTags,
                                      gapHeight: 40,
                                      onChanged: (selectedItems) {
                                        setState(() {
                                          _selectedTags = selectedItems;
                                          _updateSelectAllState();
                                        });
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            CustomMultiSelectDropdown(
                              hintText: 'Select Classroom',
                              items: _classroomOptions,
                              selectedItems: _selectedClassrooms,
                              gapHeight: 40,
                              onChanged: (selectedItems) {
                                setState(() {
                                  _selectedClassrooms = selectedItems;
                                  _updateSelectAllState();
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            // Select All
                            Align(
                              alignment: Alignment.centerLeft,
                              child: CustomCheckbox(
                                label: 'Select All',
                                value: _selectAll,
                                borderColor: AppColors.themeColor,
                                onChanged: (v) {
                                  final newVal = v ?? false;
                                  setState(() {
                                    _selectAll = newVal;
                                    if (newVal) {
                                      if (widget.isStaffSelection) {
                                        _selectedStaff.addAll(
                                          _filteredList.map((e) => e.value),
                                        );
                                      } else {
                                        _selectedStudents.addAll(
                                          _filteredList.map((e) => e.value),
                                        );
                                      }
                                    } else {
                                      if (widget.isStaffSelection) {
                                        _selectedStaff.clear();
                                      } else {
                                        _selectedStudents.clear();
                                      }
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            _filteredList.isEmpty
                                ? Center(
                                    child: Text(
                                      widget.isStaffSelection
                                          ? 'No staff match the selected filters'
                                          : 'No student match the selected filters',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : GridView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.all(10),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: responsive.isTablet
                                              ? 3
                                              : 2,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                          //childAspectRatio: 3.8
                                          childAspectRatio: responsive.isTablet
                                              ? 3.8
                                              : 4.2,
                                        ),
                                    itemCount: _filteredList.length,
                                    itemBuilder: (context, index) {
                                      final entry = _filteredList[index];
                                      final person = entry.value;
                                      final String fullName = person['name'];
                                      final String firstName = fullName
                                          .trim()
                                          .split(' ')
                                          .first;

                                      final bool isSelected =
                                          widget.isStaffSelection
                                          ? _selectedStaff.contains(person)
                                          : _selectedStudents.contains(person);

                                      return StudentTile(
                                        name: firstName,
                                        isSelected: isSelected,
                                        onSelected: (bool? selected) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).removeCurrentSnackBar();
                                          setState(() {
                                            if (selected == true) {
                                              (widget.isStaffSelection
                                                      ? _selectedStaff
                                                      : _selectedStudents)
                                                  .add(person);
                                            } else {
                                              (widget.isStaffSelection
                                                      ? _selectedStaff
                                                      : _selectedStudents)
                                                  .remove(person);
                                            }
                                            _updateSelectAllState();
                                          });
                                        },
                                      );
                                    },
                                  ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, responsive),
    );
  }

  Widget _buildCustomDropdown(
    String hintText,
    List<String> items,
    String? selectedItem,
    ValueChanged<String?> onSelect, {
    bool isRequired = false,
    double? height = null,
  }) {
    final responsive = ResponsiveHelper(context);
    return CustomDropdown(
      label: null,
      hintText: hintText,
      items: items,
      height: height,
      selectedItem: selectedItem,
      onSelect: onSelect,
      showAsterisk: isRequired,
      labelStyle: TextStyle(
        fontSize: responsive.labelFontSize,
        fontFamily: "Manrope",
        fontWeight: FontWeight.w400,
        color: const Color(0xff573353),
      ),
      labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
      fieldHeight: 40,
      selectedTextStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: responsive.inputFontSize,
        fontWeight: selectedItem != null ? FontWeight.w600 : FontWeight.w500,
        color: selectedItem != null
            ? const Color(0xff573353)
            : Colors.grey[600],
        height: 19 / 14,
      ),
      popupItemTextStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: responsive.inputFontSize,
        fontWeight: FontWeight.w400,
        color: const Color(0xff573353),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ResponsiveHelper responsive) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    return Container(
      padding: EdgeInsets.only(
        bottom: safeAreaBottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
          topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Container(
              height: responsive.buttonHeight,
              decoration: BoxDecoration(
                gradient: AppColors.buildPrimaryGradient(),
                borderRadius: BorderRadius.circular(
                  responsive.isTablet ? 16.0 : 8.0,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(1),
                child: Container(
                  //alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      responsive.isTablet ? 16.0 : 8.0,
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      overlayColor: Colors.transparent,
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return AppColors.buildPrimaryGradient().createShader(
                          bounds,
                        );
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: responsive.buttonFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: responsive.buttonHeight,
              decoration: BoxDecoration(
                gradient: AppColors.buildPrimaryGradient(),
                borderRadius: BorderRadius.circular(
                  responsive.isTablet ? 16.0 : 8.0,
                ),
              ),
              child: TextButton(
                onPressed: () {
                  if (widget.isStaffSelection) {
                    if (_selectedStaff.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MessageCompositionBulkMessaging(
                            selectedRecipients: _selectedStaff.toList(),
                          ),
                        ),
                      );
                    } else {
                      _showWarningMessage('Select at least one staff.');
                    }
                  } else {
                    if (_selectedStudents.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MessageCompositionBulkMessaging(
                            selectedRecipients: _selectedStudents.toList(),
                          ),
                        ),
                      );
                    } else {
                      _showWarningMessage('Select at least one student.');
                    }
                  }
                },
                style: TextButton.styleFrom(overlayColor: Colors.transparent),
                child: Text(
                  'Next',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: responsive.buttonFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
