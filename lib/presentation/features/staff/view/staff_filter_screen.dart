import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';

enum StaffFilterSection {
  /// Uses the "Allowed Classroom" list as the classroom multi-select.
  classroom,
  designation,
  status,
  sortBy,
  attendanceStatus,
  /// Legacy: show the old Primary Classroom dropdown.
  primaryClassroom,
  /// Legacy: show the old Allowed Classroom dropdown.
  allowedClassroom,
}

// Mock classes for now - replace with actual implementations
class FilterData {
  final List<int> classroomIds;
  final List<String> classrooms;
  /// Selected primary classroom names (for Primary Classroom dropdown).
  final List<String>? primaryClassrooms;
  /// Selected allowed classroom names (for Allowed Classroom dropdown).
  final List<String>? allowedClassrooms;
  final List<String> statuses;
  final List<String> tags;
  final List<String> attendanceStatuses;
  /// Sort direction: 'asc' or 'desc'.
  final String? sortBy;

  FilterData({
    required this.classroomIds,
    required this.classrooms,
    this.primaryClassrooms,
    this.allowedClassrooms,
    required this.statuses,
    required this.tags,
    this.attendanceStatuses = const [],
    this.sortBy,
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
  final List<StaffFilterSection> sections;
  
  const StaffFilterScreen({
    this.initialFilters, 
    this.selectedDate, 
    this.sections = const [
      StaffFilterSection.primaryClassroom,
      StaffFilterSection.allowedClassroom,
      StaffFilterSection.status,
      StaffFilterSection.designation,
      StaffFilterSection.sortBy,
      StaffFilterSection.attendanceStatus,
    ],
    super.key
  });

  static const String routeName = '/staff-filter';

  @override
  State<StaffFilterScreen> createState() => _StaffFilterScreenState();
}

class _StaffFilterScreenState extends State<StaffFilterScreen> {
  List<String> get _labelList {
    // If the screen is used in "attendance" mode with just Classroom + Designation,
    // show the simplified label.
    final onlySimple =
        widget.sections.length == 2 &&
            widget.sections.contains(StaffFilterSection.classroom) &&
            widget.sections.contains(StaffFilterSection.designation);

    return widget.sections.map((s) {
      switch (s) {
        case StaffFilterSection.classroom:
          return onlySimple ? 'Classroom' : 'Allowed Classroom';
        case StaffFilterSection.designation:
          return 'Designation';
        case StaffFilterSection.status:
          return 'Status';
        case StaffFilterSection.sortBy:
          return 'Sort by';
        case StaffFilterSection.attendanceStatus:
          return 'Attendance Status';
        case StaffFilterSection.primaryClassroom:
          return 'Primary Classroom';
        case StaffFilterSection.allowedClassroom:
          return 'Allowed Classroom';
      }
    }).toList();
  }
  final List<String> _labelList = [
    'Primary Classroom',
    'Allowed Classroom',
    'Status',
    'Designation',
    'Attendance Status',
  ];

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
      // Primary and Allowed are separate so UI shows the correct dropdown selection
      _selectedPrimaryClassroomList = List.from(
        widget.initialFilters!.primaryClassrooms ?? widget.initialFilters!.classrooms,
      );
      _selectedAllowedClassroomList = List.from(
        widget.initialFilters!.allowedClassrooms ?? const [],
      );
      _selectedStatusList = List.from(widget.initialFilters!.statuses);
      // Status is single-select in this screen.
      if (_selectedStatusList.length > 1) {
        _selectedStatusList = <String>[_selectedStatusList.first];
      }
      _selectedDesignationList = List.from(widget.initialFilters!.tags);
      _selectedAttendanceStatusList = List.from(widget.initialFilters!.attendanceStatuses);
    }
    _fetchFilterData();
  }

  void _fetchFilterData() {
    // Load classrooms from ClassroomCubit. For staff filters, we want the same
    // set as the staff screen itself, i.e. all ACTIVE locations without
    // restricting to type=CLASSROOM.
    context
        .read<ClassroomCubit>()
        .loadActiveClassrooms(onlyTypeClassroom: false);
    
    setState(() {
      // Status options: ACTIVE, UPCOMING
      _statusList = ['ACTIVE', 'UPCOMING'];

      // If initial filters had other statuses (e.g. INACTIVE/ARCHIVE),
      // drop them so UI + applied filters stay consistent.
      _selectedStatusList.removeWhere((s) => !_statusList.contains(s));

      // If nothing is selected for status, default to ACTIVE so the user
      // always sees some status filter applied when coming from this screen.
      if (_selectedStatusList.isEmpty && _statusList.contains('ACTIVE')) {
        _selectedStatusList.add('ACTIVE');
      }

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
    });
  }

  void _applyFilters() {
    _syncPrimaryClassroomIds();
    _syncAllowedClassroomIds();

    // Map selected classroom names to codes for the API
    final classroomState = context.read<ClassroomCubit>().state;
    final nameToCode = {
      for (final c in classroomState.classrooms) c.name: c.code,
    };
    final primaryCodes = _selectedPrimaryClassroomList
        .map((name) => nameToCode[name])
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toList();
    final allowedCodes = _selectedAllowedClassroomList
        .map((name) => nameToCode[name])
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toList();

    // Return Map format expected by staff_screen.dart
    final String? status = widget.sections.contains(StaffFilterSection.status) &&
            _selectedStatusList.isNotEmpty
        ? _selectedStatusList.first
        : null;
    final String? designation =
        widget.sections.contains(StaffFilterSection.designation) &&
                _selectedDesignationList.isNotEmpty
            ? _selectedDesignationList.first
            : null;
    final String sortBy = (widget.sections.contains(StaffFilterSection.sortBy) &&
                _selectedSortByList.isNotEmpty &&
                _selectedSortByList.first == 'Ascending')
        ? 'asc'
        : 'desc';

    Navigator.pop(context, {
      'status': status,
      'designation': designation,
      'primaryClassroomCodes': widget.sections.contains(StaffFilterSection.primaryClassroom)
          ? primaryCodes
          : const <String>[],
      // For the simplified "Classroom" filter we reuse AllowedClassroom codes.
      'classCodes': (widget.sections.contains(StaffFilterSection.classroom) ||
              widget.sections.contains(StaffFilterSection.allowedClassroom))
          ? allowedCodes
          : const <String>[],
      'sortBy': sortBy,
    Navigator.pop(context, {
      'status': status,
      'designation': designation,
      'primaryClassroomCodes': primaryCodes,
      'classCodes': allowedCodes,
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
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: safeAreaBottom,
      ),
      child: CustomButtonLayout(
        confirmButtonLabel: 'Apply Filters',
        onPressedConfirm: _applyFilters,
        showCancelButton: false,
        isForm: false,
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
        final hasClassrooms = _primaryClassroomList.isNotEmpty;
        final hasStatus = _statusList.isNotEmpty;
        final hasDesignation = _designationList.isNotEmpty;
        final hasAttendance = _attendanceStatusList.isNotEmpty;

        final canRender = (!widget.sections.contains(StaffFilterSection.primaryClassroom) ||
                hasClassrooms) &&
            (!widget.sections.contains(StaffFilterSection.allowedClassroom) ||
                hasClassrooms) &&
            (!widget.sections.contains(StaffFilterSection.classroom) || hasClassrooms) &&
            (!widget.sections.contains(StaffFilterSection.status) || hasStatus) &&
            (!widget.sections.contains(StaffFilterSection.designation) ||
                hasDesignation) &&
            (!widget.sections.contains(StaffFilterSection.attendanceStatus) ||
                hasAttendance);

        if (canRender) {
          List<String> _optionsFor(StaffFilterSection section) {
            switch (section) {
              case StaffFilterSection.primaryClassroom:
                return _primaryClassroomList;
              case StaffFilterSection.allowedClassroom:
                return _allowedClassroomList;
              case StaffFilterSection.classroom:
                return _allowedClassroomList;
              case StaffFilterSection.status:
                return _statusList;
              case StaffFilterSection.designation:
                return _designationList;
              case StaffFilterSection.sortBy:
                return _sortByOptions;
              case StaffFilterSection.attendanceStatus:
                return _attendanceStatusList;
            }
          }

          List<String> _selectedFor(StaffFilterSection section) {
            switch (section) {
              case StaffFilterSection.primaryClassroom:
                return _selectedPrimaryClassroomList;
              case StaffFilterSection.allowedClassroom:
                return _selectedAllowedClassroomList;
              case StaffFilterSection.classroom:
                return _selectedAllowedClassroomList;
              case StaffFilterSection.status:
                return _selectedStatusList;
              case StaffFilterSection.designation:
                return _selectedDesignationList;
              case StaffFilterSection.sortBy:
                return _selectedSortByList;
              case StaffFilterSection.attendanceStatus:
                return _selectedAttendanceStatusList;
            }
          }
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
            itemCount: widget.sections.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.6, // Further reduced to 1.6 to give more height
            ),
            itemBuilder: (context, index) {
              final section = widget.sections[index];
              final label = _labelList[index];
              final items = _optionsFor(section);
              final selected = _selectedFor(section);

              return CustomMultiSelectDropdown(
                label: label,
                hintText: 'Select',
                items: items,
                selectedItems: selected,
                onChanged: (selectedItems) {
                  setState(() {
                    selected
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
                  // Status: single selection only (last selected).
                  if (index == 2 && selectedItems.isNotEmpty) {
                    _selectedStatusList
                      ..clear()
                      ..addAll(selectedItems);

                    if (section == StaffFilterSection.primaryClassroom) {
                      _syncPrimaryClassroomIds();
                    }
                    if (section == StaffFilterSection.allowedClassroom ||
                        section == StaffFilterSection.classroom) {
                      _syncAllowedClassroomIds();
                    }

                    // Sort by: keep single selection (last selected)
                    if (section == StaffFilterSection.sortBy &&
                        selectedItems.isNotEmpty) {
                      _selectedSortByList
                        ..clear()
                        ..add(selectedItems.last);
                    }
                  });
                },
              );
            },
          );
        }
        
        // Show loading state
        return GridView.builder(
          padding: EdgeInsets.zero,
          itemCount: _labelList.length,
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


