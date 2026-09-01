import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/classroom/views/filters/designation_display_utils.dart';
import 'package:wowcare/presentation/features/staff/view/staff_filter_data.dart';

export 'package:wowcare/presentation/features/staff/view/staff_filter_data.dart';

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
      StaffFilterSection.attendanceStatus,
    ],
    super.key,
  });

  static const String routeName = '/staff-filter';

  @override
  State<StaffFilterScreen> createState() => _StaffFilterScreenState();
}

class _StaffFilterScreenState extends State<StaffFilterScreen> {
  /// Backend designation codes (API filter values).
  static const List<String> _designationCodes = [
    'OWNER',
    'DIRECTOR',
    'ADMIN',
    'ASSISTANT_DIRECTOR',
    'LEAD_TEACHER',
    'ASSOCIATE_TEACHER',
    'ASSISTANT_TEACHER',
    'FLOATER',
  ];

  Map<String, String> get _labelToDesignationCode => {
    for (final code in _designationCodes)
      formatDesignationForDisplay(code): code,
  };

  // API expects underscore codes, e.g. attendanceStatus=SIGNED_IN&attendanceStatus=ABSENT.
  static const Map<String, String> _labelToAttendanceCode = <String, String>{
    'Signed-In': 'SIGNED_IN',
    'Signed-Out': 'SIGNED_OUT',
    'Not-Marked': 'NOT_MARKED',
    'Absent': 'ABSENT',
  };

  static final Map<String, String> _attendanceCodeToLabel = <String, String>{
    for (final entry in _labelToAttendanceCode.entries) entry.value: entry.key,
  };

  List<String> get _designationLabels =>
      _labelToDesignationCode.keys.toList()..sort();

  List<String> _designationLabelsSelected() {
    return _selectedDesignationList
        .map(formatDesignationForDisplay)
        .where(_labelToDesignationCode.containsKey)
        .toList();
  }

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

  final List<String> _sortByOptions = const ['Ascending', 'Descending'];
  List<String> _selectedSortByList = ['Ascending'];

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
      _selectedPrimaryClassroomIdList = List.from(
        widget.initialFilters!.classroomIds,
      );
      // Primary and Allowed are separate so UI shows the correct dropdown selection
      _selectedPrimaryClassroomList = List.from(
        widget.initialFilters!.primaryClassrooms ??
            widget.initialFilters!.classrooms,
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
      // Incoming values are backend codes (e.g. SIGNED_IN); map back to the
      // display labels shown in the dropdown (e.g. Signed-In).
      _selectedAttendanceStatusList = widget.initialFilters!.attendanceStatuses
          .map((code) => _attendanceCodeToLabel[code.trim().toUpperCase()])
          .whereType<String>()
          .toList();
      final sb = widget.initialFilters!.sortBy?.trim().toLowerCase();
      if (sb == 'asc' || sb == 'desc') {
        _selectedSortByList = [sb == 'asc' ? 'Ascending' : 'Descending'];
      }
    }
    _fetchFilterData();
  }

  void _fetchFilterData() {
    // Load classrooms from ClassroomCubit. For staff filters, we want the same
    // set as the staff screen itself, i.e. all ACTIVE locations without
    // restricting to type=CLASSROOM.
    context.read<ClassroomCubit>().loadActiveClassrooms(
      onlyTypeClassroom: false,
    );

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

      // Designation options (backend codes; UI shows human-readable labels).
      _designationList = List<String>.from(_designationCodes);

      _attendanceStatusList = [
        'Signed-In',
        'Signed-Out',
        'Not-Marked',
        'Absent',
      ];
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
    final String? status =
        widget.sections.contains(StaffFilterSection.status) &&
            _selectedStatusList.isNotEmpty
        ? _selectedStatusList.first
        : null;
    final String? designation =
        widget.sections.contains(StaffFilterSection.designation) &&
            _selectedDesignationList.isNotEmpty
        ? _selectedDesignationList.first
        : null;
    final String sortBy =
        (widget.sections.contains(StaffFilterSection.sortBy) &&
            _selectedSortByList.isNotEmpty &&
            _selectedSortByList.first == 'Ascending')
        ? 'asc'
        : 'desc';

    final attendanceStatuses = _selectedAttendanceStatusList
        .map((label) => _labelToAttendanceCode[label])
        .whereType<String>()
        .toList();

    Navigator.pop(context, {
      'status': status,
      'designation': designation,

      /// All selected designations (backend codes), for screens that support multi-select.
      'designations': widget.sections.contains(StaffFilterSection.designation)
          ? List<String>.from(_selectedDesignationList)
          : const <String>[],
      'primaryClassroomCodes':
          widget.sections.contains(StaffFilterSection.primaryClassroom)
          ? primaryCodes
          : const <String>[],
      'classCodes':
          (widget.sections.contains(StaffFilterSection.classroom) ||
              widget.sections.contains(StaffFilterSection.allowedClassroom))
          ? allowedCodes
          : const <String>[],
      'sortBy': sortBy,
      'attendanceStatuses':
          widget.sections.contains(StaffFilterSection.attendanceStatus)
          ? attendanceStatuses
          : const <String>[],
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
        final classroomNames = classroomState.classrooms
            .map((c) => c.name)
            .toList();

        // Update classroom lists when cubit state changes
        if (classroomNames.isNotEmpty && _primaryClassroomList.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _primaryClassroomList = List.from(classroomNames);
              _allowedClassroomList = List.from(classroomNames);
              _primaryClassroomIdList = List.generate(
                classroomNames.length,
                (index) => index,
              );
              _allowedClassroomIdList = List.generate(
                classroomNames.length,
                (index) => index,
              );
            });
          });
        }

        // Check if data is loaded
        final hasClassrooms = _primaryClassroomList.isNotEmpty;
        final hasStatus = _statusList.isNotEmpty;
        final hasDesignation = _designationList.isNotEmpty;
        final hasAttendance = _attendanceStatusList.isNotEmpty;

        final canRender =
            (!widget.sections.contains(StaffFilterSection.primaryClassroom) ||
                hasClassrooms) &&
            (!widget.sections.contains(StaffFilterSection.allowedClassroom) ||
                hasClassrooms) &&
            (!widget.sections.contains(StaffFilterSection.classroom) ||
                hasClassrooms) &&
            (!widget.sections.contains(StaffFilterSection.status) ||
                hasStatus) &&
            (!widget.sections.contains(StaffFilterSection.designation) ||
                hasDesignation) &&
            (!widget.sections.contains(StaffFilterSection.attendanceStatus) ||
                hasAttendance);

        List<String> optionsFor(StaffFilterSection section) {
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

        List<String> selectedFor(StaffFilterSection section) {
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

        if (!canRender) {
          return GridView.builder(
            padding: EdgeInsets.zero,
            itemCount: widget.sections.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.6,
            ),
            itemBuilder: (context, index) {
              final label = index < _labelList.length ? _labelList[index] : '';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.primaryColor.withValues(alpha: 0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const ShimmerLoader(height: 40),
                ],
              );
            },
          );
        }

        return GridView.builder(
          padding: EdgeInsets.zero,
          itemCount: widget.sections.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, index) {
            final section = widget.sections[index];
            final label = _labelList[index];
            final items = optionsFor(section);
            final selected = selectedFor(section);

            final dropdownItems = section == StaffFilterSection.designation
                ? _designationLabels
                : items;
            final dropdownSelected = section == StaffFilterSection.designation
                ? _designationLabelsSelected()
                : selected;

            // Select All only for sections that are genuinely multi-select and
            // sent to the staff-list API as arrays. Status is single-select
            // (single `status` query param, coupled to the Show-Inactive
            // toggle) and Sort by is single, so they don't get Select All.
            final showSelectAll =
                section == StaffFilterSection.primaryClassroom ||
                section == StaffFilterSection.allowedClassroom ||
                section == StaffFilterSection.classroom ||
                section == StaffFilterSection.attendanceStatus;

            return CustomMultiSelectDropdown(
              label: label,
              hintText: 'Select',
              showSelectAll: showSelectAll,
              items: dropdownItems,
              selectedItems: dropdownSelected,
              onChanged: (selectedItems) {
                setState(() {
                  switch (section) {
                    case StaffFilterSection.primaryClassroom:
                      _selectedPrimaryClassroomList
                        ..clear()
                        ..addAll(selectedItems);
                      _syncPrimaryClassroomIds();
                      break;
                    case StaffFilterSection.allowedClassroom:
                    case StaffFilterSection.classroom:
                      _selectedAllowedClassroomList
                        ..clear()
                        ..addAll(selectedItems);
                      _syncAllowedClassroomIds();
                      break;
                    case StaffFilterSection.status:
                      _selectedStatusList.clear();
                      if (selectedItems.isNotEmpty) {
                        _selectedStatusList.add(selectedItems.last);
                      }
                      break;
                    case StaffFilterSection.designation:
                      final codes = <String>{};
                      for (final label in selectedItems) {
                        final code = _labelToDesignationCode[label];
                        if (code != null && code.trim().isNotEmpty) {
                          codes.add(code.trim());
                        }
                      }
                      _selectedDesignationList
                        ..clear()
                        ..addAll(codes);
                      break;
                    case StaffFilterSection.sortBy:
                      _selectedSortByList.clear();
                      if (selectedItems.isNotEmpty) {
                        _selectedSortByList.add(selectedItems.last);
                      }
                      break;
                    case StaffFilterSection.attendanceStatus:
                      _selectedAttendanceStatusList
                        ..clear()
                        ..addAll(selectedItems);
                      break;
                  }
                });
              },
            );
          },
        );
      },
    );
  }
}
