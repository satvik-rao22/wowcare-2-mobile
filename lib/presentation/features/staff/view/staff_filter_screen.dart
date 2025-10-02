import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

// Mock classes for now - replace with actual implementations
class FilterData {
  final List<int> classroomIds;
  final List<String> classrooms;
  final List<String> statuses;
  final List<String> tags;

  FilterData({
    required this.classroomIds,
    required this.classrooms,
    required this.statuses,
    required this.tags,
  });

  static FilterData createWithTagMapping({
    required List<int> classroomIds,
    required List<String> classrooms,
    required List<String> statuses,
    required List<String> tags,
  }) {
    return FilterData(
      classroomIds: classroomIds,
      classrooms: classrooms,
      statuses: statuses,
      tags: tags,
    );
  }
}

class StaffFilterScreen extends StatefulWidget {
  final FilterData? initialFilters;
  final DateTime? selectedDate;
  
  const StaffFilterScreen({
    this.initialFilters, 
    this.selectedDate, 
    super.key
  });

  static const String routeName = '/staff-filter';

  @override
  State<StaffFilterScreen> createState() => _StaffFilterScreenState();
}

class _StaffFilterScreenState extends State<StaffFilterScreen> {
  final List<String> _labelList = ['Primary Classroom', 'Allowed Classroom', 'Status', 'Designation', 'Attendance Status'];
  
  // Filter lists
  List<int> _primaryClassroomIdList = [];
  List<String> _primaryClassroomList = [];
  List<int> _allowedClassroomIdList = [];
  List<String> _allowedClassroomList = [];
  List<String> _statusList = [];
  List<String> _designationList = [];
  List<String> _attendanceStatusList = [];
  
  // Selected values
  List<int> _selectedPrimaryClassroomIdList = [];
  List<String> _selectedPrimaryClassroomList = [];
  List<int> _selectedAllowedClassroomIdList = [];
  List<String> _selectedAllowedClassroomList = [];
  List<String> _selectedStatusList = [];
  List<String> _selectedDesignationList = [];
  List<String> _selectedAttendanceStatusList = [];

  void _syncPrimaryClassroomIds() {
    _selectedPrimaryClassroomIdList.clear();
    for (final classroomName in _selectedPrimaryClassroomList) {
      final index = _primaryClassroomList.indexOf(classroomName);
      if (index != -1 && index < _primaryClassroomIdList.length) {
        _selectedPrimaryClassroomIdList.add(_primaryClassroomIdList[index]);
      }
    }
  }

  void _syncAllowedClassroomIds() {
    _selectedAllowedClassroomIdList.clear();
    for (final classroomName in _selectedAllowedClassroomList) {
      final index = _allowedClassroomList.indexOf(classroomName);
      if (index != -1 && index < _allowedClassroomIdList.length) {
        _selectedAllowedClassroomIdList.add(_allowedClassroomIdList[index]);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialFilters != null) {
      _selectedPrimaryClassroomIdList = List.from(widget.initialFilters!.classroomIds);
      _selectedPrimaryClassroomList = List.from(widget.initialFilters!.classrooms);
      _selectedStatusList = List.from(widget.initialFilters!.statuses);
      _selectedDesignationList = List.from(widget.initialFilters!.tags);
    }
    _fetchFilterData();
  }

  void _fetchFilterData() {
    // Mock data - replace with actual API calls
    setState(() {
      _primaryClassroomIdList = List.generate(14, (index) => index + 1);
      _primaryClassroomList = [
        'Pre-K A', 'Pre-K B', 'Kindergarten A', 'Kindergarten B',
        'Grade 1 A', 'Grade 1 B', 'Grade 2 A', 'Grade 2 B',
        'Grade 3 A', 'Grade 3 B', 'Grade 4 A', 'Grade 4 B',
        'Grade 5 A', 'Grade 5 B'
      ];
      _allowedClassroomIdList = List.from(_primaryClassroomIdList);
      _allowedClassroomList = List.from(_primaryClassroomList);
      _statusList = ['Active', 'Upcoming'];
      _designationList = [
        'Principal', 'Vice Principal', 'Head Teacher', 'Teacher',
        'Assistant Teacher', 'Counselor', 'Librarian', 'PE Teacher',
        'Art Teacher', 'Music Teacher', 'Admin Staff', 'Support Staff'
      ];
      _attendanceStatusList = ['Expected', 'Present', 'Absent'];
      
      // Set default Active status if no status is pre-selected
      if (_selectedStatusList.isEmpty && _statusList.contains('Active')) {
        _selectedStatusList.add('Active');
      }
    });
  }

  void _applyFilters() {
    _syncPrimaryClassroomIds();
    _syncAllowedClassroomIds();
    final filterData = FilterData.createWithTagMapping(
      classroomIds: _selectedPrimaryClassroomIdList,
      classrooms: _selectedPrimaryClassroomList,
      statuses: _selectedStatusList,
      tags: _selectedDesignationList,
    );
    Navigator.pop(context, filterData);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return StaffFormLayout(
      title: 'Filter Staff',
      child: _buildFilterContent(),
      bottomBar: _buildBottomBar(context, responsive),
    );
  }

  Widget _buildBottomBar(BuildContext context, ResponsiveHelper responsive) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    return Container(
      padding: EdgeInsets.only(bottom: safeAreaBottom, left: 16, right: 16, top: 8),
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
      child: Container(
        height: responsive.buttonHeight,
        decoration: BoxDecoration(
          gradient: AppColors.buildPrimaryGradient(),
          borderRadius: BorderRadius.circular(responsive.isTablet ? 16.0 : 8.0),
        ),
        child: TextButton(
          onPressed: _applyFilters,
          child: Text(
            'Apply Filters',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: responsive.buttonFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterContent() {
    // Check if data is loaded
    if (_primaryClassroomList.isNotEmpty &&
        _statusList.isNotEmpty &&
        _designationList.isNotEmpty &&
        _attendanceStatusList.isNotEmpty) {
      final _dropdownLists = [
        _primaryClassroomList,
        _allowedClassroomList,
        _statusList,
        _designationList,
        _attendanceStatusList,
      ];
      final _selectedDropdownLists = [
        _selectedPrimaryClassroomList,
        _selectedAllowedClassroomList,
        _selectedStatusList,
        _selectedDesignationList,
        _selectedAttendanceStatusList,
      ];
      
      return GridView.builder(
        padding: EdgeInsets.zero,
        itemCount: _dropdownLists.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6, // Further reduced to 1.6 to give more height
        ),
        itemBuilder: (context, index) => CustomMultiSelectDropdown(
          label: _labelList[index],
          hintText: 'Select',
          items: _dropdownLists[index],
          selectedItems: _selectedDropdownLists[index],
          onChanged: (selectedItems) {
            setState(() {
              _selectedDropdownLists[index].clear();
              _selectedDropdownLists[index].addAll(selectedItems);
              if (index == 0) _syncPrimaryClassroomIds();
              if (index == 1) _syncAllowedClassroomIds();
            });
          },
        ),
      );
    }
    
    // Show loading state
    return GridView.builder(
      padding: EdgeInsets.zero,
      itemCount: 5,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6, // Further reduced to 1.6 to give more height
      ),
      itemBuilder: (context, index) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_labelList[index],
              style: TextStyle(
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w400)),
          const SizedBox(height: 8),
          const ShimmerLoader(height: 40),
        ],
      ),
    );
  }

}


