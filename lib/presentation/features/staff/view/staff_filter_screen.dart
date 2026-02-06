import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';

// Mock classes for now - replace with actual implementations
class FilterData {
  final List<int> classroomIds;
  final List<String> classrooms;
  final List<String> statuses;
  final List<String> tags;
  final List<String> attendanceStatuses;

  FilterData({
    required this.classroomIds,
    required this.classrooms,
    required this.statuses,
    required this.tags,
    this.attendanceStatuses = const [],
  });

  static FilterData createWithTagMapping({
    required List<int> classroomIds,
    required List<String> classrooms,
    required List<String> statuses,
    required List<String> tags,
    List<String> attendanceStatuses = const [],
  }) {
    return FilterData(
      classroomIds: classroomIds,
      classrooms: classrooms,
      statuses: statuses,
      tags: tags,
      attendanceStatuses: attendanceStatuses,
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
      _selectedAttendanceStatusList = List.from(widget.initialFilters!.attendanceStatuses);
    }
    _fetchFilterData();
  }

  void _fetchFilterData() {
    // Load classrooms from ClassroomCubit
    context.read<ClassroomCubit>().loadActiveClassrooms();
    
    setState(() {
      // Status options: ACTIVE, INACTIVE, ARCHIVE, UPCOMING
      _statusList = ['ACTIVE', 'INACTIVE', 'ARCHIVE', 'UPCOMING'];
      
      // Designation options from the API
      _designationList = [
        'OWNER',
        'DIRECTOR',
        'ADMIN',
        'ASSISTANT_DIRECTOR',
        'LEAD_TEACHER',
        'ASSOCIATE_TEACHER',
        'ASSISTANT_TEACHER',
        'FLOATER',
        'KIOSK_USER',
      ];
      
      _attendanceStatusList = ['Expected', 'Present', 'Absent'];
      
      // Set default ACTIVE status if no status is pre-selected
      if (_selectedStatusList.isEmpty && _statusList.contains('ACTIVE')) {
        _selectedStatusList.add('ACTIVE');
      }
    });
  }

  void _applyFilters() {
    _syncPrimaryClassroomIds();
    _syncAllowedClassroomIds();
    
    // Return Map format expected by staff_screen.dart
    final String? status = _selectedStatusList.isNotEmpty ? _selectedStatusList.first : null;
    final String? designation = _selectedDesignationList.isNotEmpty ? _selectedDesignationList.first : null;
    
    Navigator.pop(context, {
      'status': status,
      'designation': designation,
    });
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
    return BlocBuilder<ClassroomCubit, ClassroomState>(
      builder: (context, classroomState) {
        // Load classrooms from cubit state
        final classroomNames = classroomState.classrooms.map((c) => c.name).toList();
        
        // Update classroom lists when cubit state changes
        if (classroomNames.isNotEmpty && _primaryClassroomList.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _primaryClassroomList = List.from(classroomNames);
              _allowedClassroomList = List.from(classroomNames);
              _primaryClassroomIdList = List.generate(classroomNames.length, (index) => index);
              _allowedClassroomIdList = List.generate(classroomNames.length, (index) => index);
            });
          });
        }
        
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
      },
    );
  }

}


