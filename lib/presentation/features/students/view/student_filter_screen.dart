import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/student/usecases/get_guardian_names_for_school_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_names_for_school_usecase.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

enum StudentFilterSection {
  classroom,
  status,
  tags,
  parents,
  attendance,
}

class StudentFilterScreen extends StatefulWidget {
  const StudentFilterScreen({
    super.key,
    this.initialFilters,
    this.sections = const [
      StudentFilterSection.classroom,
      StudentFilterSection.status,
      StudentFilterSection.tags,
      StudentFilterSection.parents,
      StudentFilterSection.attendance,
    ],
  });

  static const String routeName = '/student-filter';

  final Map<String, List<String>>? initialFilters;
  final List<StudentFilterSection> sections;

  @override
  State<StudentFilterScreen> createState() => _StudentFilterScreenState();
}

class _StudentFilterScreenState extends State<StudentFilterScreen> {
  List<String> get _labelList {
    return widget.sections.map((s) {
      switch (s) {
        case StudentFilterSection.classroom:
          return 'Classroom';
        case StudentFilterSection.status:
          return 'Status';
        case StudentFilterSection.tags:
          return 'Tags';
        case StudentFilterSection.parents:
          return 'Parents';
        case StudentFilterSection.attendance:
          return 'Attendance';
      }
    }).toList();
  }

  // Options
  List<String> _classroomList = [];
  final List<String> _statusList = const ['Active', 'Inactive', 'Upcoming'];
  List<String> _tagsList = const [];
  List<String> _parentsList = const [];
  final List<String> _attendanceList = const ['Expected', 'Present', 'Absent'];

  // Selected
  List<String> _selectedClassroomList = [];
  List<String> _selectedStatusList = [];
  List<String> _selectedTagsList = [];
  List<String> _selectedParentsList = [];
  List<String> _selectedAttendanceList = [];

  late final GetGuardianNamesForSchoolUseCase _getGuardianNamesForSchoolUseCase;
  late final GetTagNamesForSchoolUseCase _getTagNamesForSchoolUseCase;
  late final StorageService _storageService;

  @override
  void initState() {
    super.initState();

    _getGuardianNamesForSchoolUseCase =
        serviceLocator<GetGuardianNamesForSchoolUseCase>();
    _getTagNamesForSchoolUseCase =
        serviceLocator<GetTagNamesForSchoolUseCase>();
    _storageService = serviceLocator<StorageService>();

    final initial = widget.initialFilters ?? const {};
    _selectedClassroomList = List<String>.from(initial['Classroom'] ?? const []);
    _selectedStatusList = List<String>.from(initial['Status'] ?? const ['Active']);
    _selectedTagsList = List<String>.from(initial['Tags'] ?? const []);
    _selectedParentsList = List<String>.from(initial['Parents'] ?? const []);
    _selectedAttendanceList = List<String>.from(initial['Attendance'] ?? const []);

    if (widget.sections.contains(StudentFilterSection.status)) {
      if (_selectedStatusList.isEmpty) {
        _selectedStatusList = ['Active'];
      } else if (_selectedStatusList.length > 1) {
        _selectedStatusList = [_selectedStatusList.last];
      }
    }

    if (widget.sections.contains(StudentFilterSection.classroom)) {
      _fetchFilterData();
    }
    if (widget.sections.contains(StudentFilterSection.tags)) {
      _loadTags();
    }
    if (widget.sections.contains(StudentFilterSection.parents)) {
      _loadParents();
    }
  }

  void _fetchFilterData() {
    context.read<ClassroomCubit>().loadActiveClassrooms();
  }

  Future<void> _loadTags() async {
    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) return;

      final names =
          await _getTagNamesForSchoolUseCase(schoolCode: schoolCode);
      if (!mounted) return;

      // Names list is enough for UI; codes are resolved when applying filters
      // by using the same names and a separate codes lookup if needed.
      setState(() {
        _tagsList = names;
        _selectedTagsList
            .removeWhere((tag) => !_tagsList.contains(tag));
      });
    } catch (_) {
      // Non-critical for filters; ignore errors.
    }
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
    final result = <String, List<String>>{};
    if (widget.sections.contains(StudentFilterSection.classroom)) {
      result['Classroom'] = List<String>.from(_selectedClassroomList);
    }
    if (widget.sections.contains(StudentFilterSection.status)) {
      result['Status'] = List<String>.from(_selectedStatusList);
    }
    if (widget.sections.contains(StudentFilterSection.tags)) {
      result['Tags'] = List<String>.from(_selectedTagsList);
    }
    if (widget.sections.contains(StudentFilterSection.parents)) {
      result['Parents'] = List<String>.from(_selectedParentsList);
    }
    if (widget.sections.contains(StudentFilterSection.attendance)) {
      result['Attendance'] = List<String>.from(_selectedAttendanceList);
    }

    Navigator.pop<Map<String, List<String>>>(context, {
      ...result,
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

        List<String> _optionsFor(StudentFilterSection section) {
          switch (section) {
            case StudentFilterSection.classroom:
              return _classroomList;
            case StudentFilterSection.status:
              return _statusList;
            case StudentFilterSection.tags:
              return _tagsList;
            case StudentFilterSection.parents:
              return _parentsList;
            case StudentFilterSection.attendance:
              return _attendanceList;
          }
        }

        List<String> _selectedFor(StudentFilterSection section) {
          switch (section) {
            case StudentFilterSection.classroom:
              return _selectedClassroomList;
            case StudentFilterSection.status:
              return _selectedStatusList;
            case StudentFilterSection.tags:
              return _selectedTagsList;
            case StudentFilterSection.parents:
              return _selectedParentsList;
            case StudentFilterSection.attendance:
              return _selectedAttendanceList;
          }
        }

        // Consider API-driven data (classrooms, tags, parents) independently.
        // Even if one API fails, the others can still populate their dropdowns.
        final hasAnyApiData =
            (widget.sections.contains(StudentFilterSection.classroom) &&
                _classroomList.isNotEmpty) ||
            (widget.sections.contains(StudentFilterSection.tags) &&
                _tagsList.isNotEmpty) ||
            (widget.sections.contains(StudentFilterSection.parents) &&
                _parentsList.isNotEmpty);

        if (hasAnyApiData) {
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
              final items = _optionsFor(section);
              final selected = _selectedFor(section);

              return CustomMultiSelectDropdown(
                label: label,
                hintText: 'Select',
                items: items,
                selectedItems: selected,
                onChanged: (selectedItems) {
                  setState(() {
                    final isSingleSelect = section == StudentFilterSection.status ||
                        section == StudentFilterSection.attendance;

                    selected
                      ..clear()
                      ..addAll(
                        isSingleSelect
                            ? (selectedItems.isEmpty
                                ? const <String>[]
                                : <String>[selectedItems.last])
                            : selectedItems,
                      );

                    // Ensure status always has a default if enabled.
                    if (section == StudentFilterSection.status &&
                        _selectedStatusList.isEmpty) {
                      _selectedStatusList.add('Active');
                    }
                  });
                },
              );
            },
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
          itemBuilder: (context, index) {
            return Column(
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
            );
          },
        );
      },
    );
  }
}

