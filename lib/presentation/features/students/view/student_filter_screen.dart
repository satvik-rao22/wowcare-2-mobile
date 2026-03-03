import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/student/usecases/get_guardian_names_for_school_usecase.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class StudentFilterScreen extends StatefulWidget {
  const StudentFilterScreen({
    super.key,
    this.initialFilters,
  });

  static const String routeName = '/student-filter';

  final Map<String, List<String>>? initialFilters;

  @override
  State<StudentFilterScreen> createState() => _StudentFilterScreenState();
}

class _StudentFilterScreenState extends State<StudentFilterScreen> {
  final List<String> _labelList = const [
    'Classroom',
    'Status',
    'Tags',
    'Parents',
    'Attendance',
  ];

  // Options
  List<String> _classroomList = [];
  final List<String> _statusList = const ['Active', 'Inactive', 'Upcoming'];
  final List<String> _tagsList = const [
    '5 Days',
    'Full Day',
    'Photo Permission',
    'Vegetarian',
    'First Aid',
    'Allergy',
    'Pickup Authorized',
  ];
  List<String> _parentsList = const [];
  final List<String> _attendanceList = const ['Expected', 'Present', 'Absent'];

  // Selected
  List<String> _selectedClassroomList = [];
  List<String> _selectedStatusList = [];
  List<String> _selectedTagsList = [];
  List<String> _selectedParentsList = [];
  List<String> _selectedAttendanceList = [];

  late final GetGuardianNamesForSchoolUseCase _getGuardianNamesForSchoolUseCase;
  late final StorageService _storageService;

  @override
  void initState() {
    super.initState();

    _getGuardianNamesForSchoolUseCase =
        serviceLocator<GetGuardianNamesForSchoolUseCase>();
    _storageService = serviceLocator<StorageService>();

    final initial = widget.initialFilters ?? const {};
    _selectedClassroomList = List<String>.from(initial['Classroom'] ?? const []);
    _selectedStatusList = List<String>.from(initial['Status'] ?? const ['Active']);
    _selectedTagsList = List<String>.from(initial['Tags'] ?? const []);
    _selectedParentsList = List<String>.from(initial['Parents'] ?? const []);
    _selectedAttendanceList = List<String>.from(initial['Attendance'] ?? const []);

    if (_selectedStatusList.isEmpty) {
      _selectedStatusList = ['Active'];
    } else if (_selectedStatusList.length > 1) {
      _selectedStatusList = [_selectedStatusList.last];
    }

    _fetchFilterData();
    _loadParents();
  }

  void _fetchFilterData() {
    context.read<ClassroomCubit>().loadActiveClassrooms();
  }

  Future<void> _loadParents() async {
    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) return;

      final names =
          await _getGuardianNamesForSchoolUseCase(schoolCode: schoolCode);
      if (!mounted) return;

      setState(() {
        _parentsList = names;
        _selectedParentsList
            .removeWhere((parent) => !_parentsList.contains(parent));
      });
    } catch (_) {
      // For filter dropdowns this is non-critical; ignore errors silently.
    }
  }

  void _applyFilters() {
    Navigator.pop<Map<String, List<String>>>(context, {
      'Classroom': List<String>.from(_selectedClassroomList),
      'Status': List<String>.from(_selectedStatusList),
      'Tags': List<String>.from(_selectedTagsList),
      'Parents': List<String>.from(_selectedParentsList),
      'Attendance': List<String>.from(_selectedAttendanceList),
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return StaffFormLayout(
      title: 'Filter Students',
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
        final classroomNames = classroomState.classrooms.map((c) => c.name).toList();

        // Update classroom list once we have data.
        if (classroomNames.isNotEmpty && _classroomList.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _classroomList = List<String>.from(classroomNames);
              _selectedClassroomList
                  .removeWhere((item) => !_classroomList.contains(item));
            });
          });
        }

        final dropdownLists = <List<String>>[
          _classroomList,
          _statusList,
          _tagsList,
          _parentsList,
          _attendanceList,
        ];

        final selectedDropdownLists = <List<String>>[
          _selectedClassroomList,
          _selectedStatusList,
          _selectedTagsList,
          _selectedParentsList,
          _selectedAttendanceList,
        ];

        final isReady = _classroomList.isNotEmpty;

        if (isReady) {
          return GridView.builder(
            padding: EdgeInsets.zero,
            itemCount: dropdownLists.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.6,
            ),
            itemBuilder: (context, index) => CustomMultiSelectDropdown(
              label: _labelList[index],
              hintText: 'Select',
              items: dropdownLists[index],
              selectedItems: selectedDropdownLists[index],
              onChanged: (selectedItems) {
                setState(() {
                  if (index == 1 || index == 4) {
                    // Status + Attendance: keep single selection (last picked).
                    selectedDropdownLists[index]
                      ..clear()
                      ..addAll(
                        selectedItems.isEmpty ? const <String>[] : <String>[selectedItems.last],
                      );
                  } else {
                    selectedDropdownLists[index]
                      ..clear()
                      ..addAll(selectedItems);
                  }

                  // Ensure status always has a default.
                  if (index == 1 && _selectedStatusList.isEmpty) {
                    _selectedStatusList.add('Active');
                  }
                });
              },
            ),
          );
        }

        // Loading state
        return GridView.builder(
          padding: EdgeInsets.zero,
          itemCount: _labelList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, index) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _labelList[index],
                style: TextStyle(
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              const ShimmerLoader(height: 40),
            ],
          ),
        );
      },
    );
  }
}

